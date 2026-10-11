import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/features/jood_writer/domain/flow_paginator.dart';
import 'package:joodcraft/features/jood_writer/domain/jood_writer_block.dart';
import 'package:joodcraft/features/jood_writer/domain/jood_writer_document.dart';
import 'package:joodcraft/features/jood_writer/presentation/jood_writer_text_styles.dart';
import 'package:joodcraft/features/jood_writer/presentation/text_painter_measurer.dart';
import 'package:joodcraft/features/jood_writer/presentation/writer_document_controller.dart';
import 'package:joodcraft/features/jood_writer/presentation/writer_text_scale.dart';
import 'package:joodcraft/features/jood_writer/presentation/widgets/writer_canvas.dart';
import 'package:joodcraft/features/jood_writer/presentation/widgets/writer_pages_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// **توحيد `TextScaler` عبر كل المسارات.**
///
/// العقد: مصدر واحد (`context.writerTextScaler` → `MediaQuery.textScalerOf`)
/// يُقرأ عند البناء ويُثبَّت، ثم يُمرَّر إلى كل مسارات القياس — اللوحة
/// (البناء، الشطر الآلي، التمرير) وصفحات العرض/الطباعة. والقيمة التي ترسم
/// بها الودجات ضمناً هي بعينها التي يُقاس بها النصّ.
///
/// ما تثبته هذه الاختبارات:
///
/// 1. المُقاس ينقل المقياس إلى `TextPainter` حرفياً (`linesOf` = `TextPainter`).
/// 2. في اللوحة: كل سطر مقيس يُرسم ولا سطر زائد — بعدده ورستها — عند كل
///    مقاييس التكبير، والورقة تبقى A4 بلا أي فيض.
/// 3. النصّ ثابت على كل الأجهزة: نفس المستند ونفس المقياس يعطيان نفس الصفحات
///    ونفس الأسطر على مقاسات شاشة مختلفة (سطح مكتب، محمول، لوح، هاتف).
/// 4. تغيّر مقياس النظام يُعاد تثبيته عند البناء فوراً.
/// 5. صفحات العرض/الطباعة تأخذ المقياس من المصدر نفسه، فما تُقاس هو ما يُرسم.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // مزوّد تفضيلات وهمي: كل اختبار يبدأ بتخزين نظيف.
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  const Key field0 = ValueKey<String>('writer-field-0');
  const String sample = 'سطر الاختبار الطويل ';
  const double pxPerMm = JoodWriterTextStyles.pxPerMm;
  const JoodWriterPageSize a4 = JoodWriterPageSize.a4;
  const JoodWriterMargins margins = JoodWriterMargins.standard;

  // هندسة لوحة التحرير: A4 بالهوامش القياسية عند 96dpi — تماماً كما تحسبها
  // `WriterCanvas`، فالمتوقّع هنا هو المرسوم هناك بالضبط.
  final double canvasContentWidth = margins.contentWidthMm(a4) * pxPerMm;
  final double canvasContentHeight = margins.contentHeightMm(a4) * pxPerMm;

  final RegExp pageKeyPattern = RegExp(r'^writer-page-\d+$');

  /// مُقام بنفس هندسة اللوحة وبالمقياس المطلوب — يقف حيث يقف المُقاس الذي
  /// تبني اللوحة عند كل بناء، فيكون الفرق بينهما صفراً لا تقريباً.
  TextPainterBlockMeasurer canvasMeasurer(TextScaler scaler) =>
      TextPainterBlockMeasurer(
        contentWidth: canvasContentWidth,
        scale: 1.0,
        textScaler: scaler,
      );

  List<JoodPage> canvasPages(JoodWriterDocument doc, TextScaler scaler) =>
      FlowPaginator.paginate(
        blocks: doc.blocks,
        contentHeight: canvasContentHeight,
        measurer: canvasMeasurer(scaler),
      );

  WriterDocumentController makeController({
    JoodWriterDocument? initialDocument,
  }) {
    final WriterDocumentController controller = WriterDocumentController(
      initialDocument: initialDocument,
    );
    controller.setAutosaveEnabled(false);
    addTearDown(controller.dispose);
    return controller;
  }

  /// مستند للاختبار: فقرات ساكنة (تُرسم سطراً سطراً) وتنتهي بكتلة نشطة، بلا
  /// تذييل مرقّم وبلا إزاحات — أرض بسيطة يقيسها الجميع بالقيمة نفسها.
  JoodWriterDocument makeDocument({
    int staticParagraphs = 2,
    int unitRepeat = 4,
  }) => JoodWriterDocument(
    title: 'توحيد المقياس',
    pageNumbering: const PageNumberingConfig(enabled: false),
    blocks: <JoodWriterBlock>[
      for (int i = 0; i < staticParagraphs; i++)
        JoodWriterBlock(text: sample * unitRepeat),
      const JoodWriterBlock(text: 'كتلة نشطة قصيرة.'),
    ],
  );

  /// يبني اللوحة تحت مقياس تكبير معيّن — يحاكي تكبير نظام التشغيل الذي به
  /// يُقاس النصّ أصغر ممّا يُرسم إن أُهمل المقياس في القياس.
  Future<void> pumpCanvasScaled(
    WidgetTester tester,
    WriterDocumentController controller,
    double scale,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: WriterCanvas(controller: controller),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> pumpPagesView(
    WidgetTester tester,
    JoodWriterDocument doc,
    double scale, {
    Size surface = const Size(900, 1400),
    EdgeInsets padding = const EdgeInsets.all(16),
  }) async {
    await tester.binding.setSurfaceSize(surface);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(scale)),
          child: Scaffold(
            body: JoodWriterPagesView(document: doc, padding: padding),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  /// نصوص كل ودجة `Text` تحت [parent] — هي أسطر الكتل المرسومة وحدها:
  ///
  /// * تُستبعد نصوص داخل `TextField` — نصّ المساعدة (`اكتب...`) جزء من
  ///   المحرّر لا من أسطر الصفحة، ولو عُدَّ لزاد العدد دائماً واحداً.
  /// * ويُستبعد مفتاح تذييل الترقيم (`صفحة X من Y`) إن كان مفعّلاً.
  List<String> textsUnder(WidgetTester tester, Finder parent) {
    final List<String> texts = <String>[];
    for (final Element element in find
        .descendant(of: parent, matching: find.byType(Text))
        .evaluate()) {
      final Text text = element.widget as Text;
      if (text.key == const ValueKey<String>('writer-page-number-label')) {
        continue;
      }
      bool insideEditor = false;
      element.visitAncestorElements((Element ancestor) {
        if (ancestor.widget is TextField) {
          insideEditor = true;
          return false;
        }
        return true;
      });
      if (!insideEditor) texts.add(text.data ?? '');
    }
    return texts;
  }

  /// فهارس الكتل التي تُرسم **محرّراً** فعلياً تحت [parent] — تُشتقّ من
  /// الشجرة لا من مؤشّر النشاط: بعد الشطر الآلي يُستبدل المؤشّر دون أن
  /// تُستأنف إشارة النشاط، فيبقى المحرّر في موضعه القديم، والشجرة وحدها
  /// تقول أي كتلة تُعرض محرّراً.
  Set<int> editorBlocksUnder(WidgetTester tester, Finder parent) => tester
      .widgetList<TextField>(
        find.descendant(of: parent, matching: find.byType(TextField)),
      )
      .map(
        (TextField field) =>
            int.parse((field.key! as ValueKey<String>).value.split('-').last),
      )
      .toSet();

  /// الأسطر التي **يجب** أن ترسمها [page]: كل الأسطر المقيسة في شرائحها، ما
  /// عدا شريحة بداية كل كتلة معروضة محرّراً (تُعرض في الحقل لا `Text`اً).
  List<String> expectedStaticLines(
    JoodPage page,
    TextScaler scaler,
    Set<int> editorBlocks,
  ) {
    final List<String> lines = <String>[];
    final TextPainterBlockMeasurer measurer = canvasMeasurer(scaler);
    for (final JoodPageSlice slice in page.slices) {
      if (slice.isBlockStart && editorBlocks.contains(slice.blockIndex)) {
        continue;
      }
      final List<String> blockLines = measurer.linesOf(slice.block);
      for (
        int i = slice.lineStart;
        i < slice.lineEnd && i < blockLines.length;
        i++
      ) {
        lines.add(blockLines[i]);
      }
    }
    return lines;
  }

  /// أعلى رقم صفحة بُنيت فعلاً بعد القفز إلى آخر القائمة — يكشف العدد الكلي
  /// للصفحات، فالقائمة تبني المرئيَّ منها فقط.
  ///
  /// القفز يتعدّى الامتداد أحياناً: تقدير `SliverList` للامتداد قبل بناء
  /// أبنائه البعيدة يكبر عن الواقع، فيقفز إلى موضعٍ ما بعد المحتوى فتُبنى
  /// صفر بطاقة. التكرار يعيد القفز إلى الامتداد المصحَّح حتى يستقرّ الموضع
  /// داخل المدى.
  Future<int> totalBuiltPages(WidgetTester tester) async {
    final ListView list = tester.widget<ListView>(
      find.byWidgetPredicate(
        (Widget w) => w is ListView && w.controller != null,
      ),
    );
    for (int i = 0; i < 6; i++) {
      final ScrollPosition position = list.controller!.position;
      list.controller!.jumpTo(position.maxScrollExtent);
      await tester.pump();
      final ScrollPosition after = list.controller!.position;
      // استقرّ الموضع عند نهاية المحتوى حرفياً (لا ما بعده ولا قبله).
      if ((after.pixels - after.maxScrollExtent).abs() <= 0.5) break;
    }
    int maxPage = 0;
    for (final Element element in find
        .byWidgetPredicate(
          (Widget w) =>
              w.key is ValueKey<String> &&
              pageKeyPattern.hasMatch((w.key as ValueKey<String>).value),
        )
        .evaluate()) {
      final String value = (element.widget.key as ValueKey<String>).value;
      maxPage = math.max(maxPage, int.parse(value.split('-').last));
    }
    return maxPage;
  }

  /// نفس حساب `JoodWriterPagesView`: الورقة تتقلّص لتتّسع للشاشة الضيقة.
  ({double contentWidth, double contentHeight, double scale}) previewGeometry(
    Size surface,
    EdgeInsets padding,
  ) {
    const double reference = 96 / 25.4;
    final double available = math.max(
      120,
      surface.width - padding.horizontal,
    );
    final double px = math.min(reference, available / a4.widthMm);
    return (
      contentWidth: margins.contentWidthMm(a4) * px,
      contentHeight: margins.contentHeightMm(a4) * px,
      scale: px / reference,
    );
  }

  group('المصدر الوحيد لمقياس النصّ', () {
    testWidgets('context.writerTextScaler يعيد مقياس MediaQuery نفسه حرفياً', (
      WidgetTester tester,
    ) async {
      late TextScaler viaResolver;
      late TextScaler viaMediaQuery;
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: Builder(
              builder: (BuildContext context) {
                viaResolver = context.writerTextScaler;
                viaMediaQuery = MediaQuery.textScalerOf(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
      // لا وسيط ولا قيمة موازية: المُشتق نفسه هو مقياس الودجات.
      expect(identical(viaResolver, viaMediaQuery), isTrue);
      expect(viaResolver.scale(10), closeTo(15, 1e-9));
    });
  });

  group('المُقاس: المقياس يصل إلى TextPainter', () {
    final JoodWriterBlock block = JoodWriterBlock(text: sample * 60);

    test('مقياس أكبر ⇒ أسطر أكثر للنصّ نفسه', () {
      final int at1 = canvasMeasurer(TextScaler.noScaling).linesOf(block).length;
      final int at2 = canvasMeasurer(TextScaler.linear(2)).linesOf(block).length;
      expect(at2, greaterThan(at1));
    });

    test('linesOf يطابق TextPainter الخام بنفس المقياس ونفس العرض', () {
      final TextScaler scaler = TextScaler.linear(1.5);
      final TextPainterBlockMeasurer measurer = canvasMeasurer(scaler);
      final TextPainter painter = TextPainter(
        text: TextSpan(
          text: block.text,
          style: JoodWriterTextStyles.of(block),
        ),
        textDirection: TextDirection.rtl,
        textAlign: JoodWriterTextStyles.textAlign(block.align),
        textScaler: scaler,
      )..layout(maxWidth: measurer.widthOfFirstLine(block));
      expect(painter.computeLineMetrics().length, measurer.linesOf(block).length);
      painter.dispose();
    });

    test('ارتفاع السطر يتبع المقياس', () {
      final double h1 = canvasMeasurer(TextScaler.noScaling).lineHeightOf(block);
      final double h2 = canvasMeasurer(TextScaler.linear(2)).lineHeightOf(block);
      expect(h2, closeTo(h1 * 2, h1 * 0.05));
    });
  });

  group('اللوحة: ما يُقاس هو ما يُرسم', () {
    for (final double scale in <double>[1.0, 1.3, 1.5, 2.0, 3.0]) {
      testWidgets('تكبير $scale×: كل سطر مقيس يُرسم، ولا فيض، والورقة A4', (
        WidgetTester tester,
      ) async {
        final WriterDocumentController controller = makeController(
          initialDocument: makeDocument(),
        );
        await pumpCanvasScaled(tester, controller, scale);
        // المحرّر على الكتلة الأخيرة: البقية تُرسم سطراً سطراً كنصّ ثابت.
        controller.setActiveBlock(2);
        await tester.pump();

        final TextScaler scaler = TextScaler.linear(scale);
        final JoodPage firstPage = canvasPages(controller.document, scaler).first;
        final Finder page1 = find.byKey(
          const ValueKey<String>('writer-page-1'),
        );
        expect(page1, findsOneWidget);
        final Set<int> editors = editorBlocksUnder(tester, page1);
        final List<String> expected = expectedStaticLines(
          firstPage,
          scaler,
          editors,
        );

        // العدد أوّلاً: لا سطر مقيس مفقود، ولا سطر مرسوم زائد.
        final List<String> rendered = textsUnder(tester, page1);
        expect(rendered.length, expected.length);
        for (final String line in expected) {
          expect(rendered, contains(line));
        }

        // الارتفاع ثانياً: السطر المرسوم بارتفاع المقيس بالمقياس نفسه.
        if (expected.isNotEmpty) {
          final JoodPageSlice staticSlice = firstPage.slices.firstWhere(
            (JoodPageSlice s) =>
                !editors.contains(s.blockIndex) || !s.isBlockStart,
          );
          final double height = tester
              .getSize(
                find.descendant(
                  of: page1,
                  matching: find.text(expected.first),
                ).first,
              )
              .height;
          expect(
            height,
            closeTo(canvasMeasurer(scaler).lineHeightOf(staticSlice.block), 0.75),
          );
        }

        // الورقة تبقى بمقاسها الورقي مهما علا المقياس، بلا أي فيض.
        final Size pageSize = tester.getSize(page1);
        expect(pageSize.width, closeTo(210 * pxPerMm, 0.01));
        expect(pageSize.height, closeTo(297 * pxPerMm, 0.01));
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('النصّ ثابت على كل الأجهزة', () {
    const List<Size> surfaces = <Size>[
      Size(1920, 1080), // شاشة مكتب
      Size(1280, 900), // حاسوب محمول
      Size(834, 1112), // لوح
      Size(412, 915), // هاتف
    ];
    for (final Size surface in surfaces) {
      testWidgets(
        'شاشة ${surface.width.toInt()}×${surface.height.toInt()}: '
        'نفس الصفحات ونفس الأسطر',
        (WidgetTester tester) async {
          final WriterDocumentController controller = makeController(
            initialDocument: makeDocument(staticParagraphs: 8, unitRepeat: 12),
          );
          await pumpCanvasScaled(tester, controller, 1.5);
          controller.setActiveBlock(8);
          await tester.pump();

          final TextScaler scaler = TextScaler.linear(1.5);
          final int expectedPages = canvasPages(controller.document, scaler).length;

          // مقاس سطح الجهاز: تخطيط الورقة لا يتحرّك — الطلاء وحده يتقلّص.
          await tester.binding.setSurfaceSize(surface);
          await tester.pump();

          final Finder page1 = find.byKey(
            const ValueKey<String>('writer-page-1'),
          );
          expect(page1, findsOneWidget);
          final Size pageSize = tester.getSize(page1);
          expect(pageSize.width, closeTo(210 * pxPerMm, 0.01));
          expect(pageSize.height, closeTo(297 * pxPerMm, 0.01));

          final List<String> expectedFirst = expectedStaticLines(
            canvasPages(controller.document, scaler).first,
            scaler,
            editorBlocksUnder(tester, page1),
          );
          final List<String> rendered = textsUnder(tester, page1);
          expect(rendered.length, expectedFirst.length);
          for (final String line in expectedFirst) {
            expect(rendered, contains(line));
          }

          // العدد الكلي للصفحات هو نفسه على كل المقاسات.
          expect(await totalBuiltPages(tester), expectedPages);
          expect(tester.takeException(), isNull);
        },
      );
    }
  });

  group('التثبيت عند البناء', () {
    testWidgets('تغيّر مقياس النظام أثناء الجلسة يُعاد تثبيته فوراً', (
      WidgetTester tester,
    ) async {
      final WriterDocumentController controller = makeController(
        initialDocument: makeDocument(),
      );
      await pumpCanvasScaled(tester, controller, 1.0);
      controller.setActiveBlock(2);
      await tester.pump();

      final Finder page1 = find.byKey(
        const ValueKey<String>('writer-page-1'),
      );
      TextScaler scaler = TextScaler.linear(1.0);
      List<String> rendered = textsUnder(tester, page1);
      List<String> expected = expectedStaticLines(
        canvasPages(controller.document, scaler).first,
        scaler,
        editorBlocksUnder(tester, page1),
      );
      expect(rendered.length, expected.length);
      for (final String line in expected) {
        expect(rendered, contains(line));
      }

      // نظام التشغيل يكبّر النصّ إلى 2.5× ⇒ إعادة بناء ⇒ تثبيت جديد للإطار.
      await pumpCanvasScaled(tester, controller, 2.5);
      scaler = TextScaler.linear(2.5);
      rendered = textsUnder(tester, page1);
      expected = expectedStaticLines(
        canvasPages(controller.document, scaler).first,
        scaler,
        editorBlocksUnder(tester, page1),
      );
      expect(rendered.length, expected.length);
      for (final String line in expected) {
        expect(rendered, contains(line));
      }
      // المقياس فعلاً تغيّر: نفس الكتلة تُقاس بأسطر أكثر عند 2.5× — والتعادل
      // أعلاه يثبت أنّ ما رُسم هو ما قاس مقياس الإطار الجديد لا القديم.
      final JoodWriterBlock firstBlock = controller.document.blocks.first;
      expect(
        canvasMeasurer(TextScaler.linear(2.5)).linesOf(firstBlock).length,
        greaterThan(
          canvasMeasurer(TextScaler.linear(1.0)).linesOf(firstBlock).length,
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('المحرّر النشط يرسم بارتفاع أسطره المقيسة', (
      WidgetTester tester,
    ) async {
      final WriterDocumentController controller = makeController(
        initialDocument: makeDocument(staticParagraphs: 0),
      );
      await pumpCanvasScaled(tester, controller, 1.5);
      // الكتلة الأولى نشطة افتراضياً: تحريرها يكتب نصّاً متعدد الأسطر.
      controller.controllers[0].text = sample * 8;
      await tester.pump();

      final TextScaler scaler = TextScaler.linear(1.5);
      final JoodWriterBlock block = controller.document.blocks.first;
      final TextPainterBlockMeasurer measurer = canvasMeasurer(scaler);
      final double expectedHeight =
          measurer.linesOf(block).length * measurer.lineHeightOf(block);
      final double editorHeight = tester.getSize(find.byKey(field0)).height;
      expect(editorHeight, closeTo(expectedHeight, expectedHeight * 0.12));
      expect(tester.takeException(), isNull);
    });
  });

  group('صفحات العرض: المقياس موحّد مع المحرّر', () {
    const EdgeInsets padding = EdgeInsets.all(16);
    const Size surface = Size(900, 1400);

    testWidgets('نفس المقياس ⇒ أسطر المعاينة هي أسطر المُقاس، بلا فيض', (
      WidgetTester tester,
    ) async {
      final JoodWriterDocument doc = makeDocument(
        staticParagraphs: 4,
        unitRepeat: 20,
      );
      await pumpPagesView(tester, doc, 1.5, surface: surface, padding: padding);

      final ({double contentWidth, double contentHeight, double scale}) geo =
          previewGeometry(surface, padding);
      final TextScaler scaler = TextScaler.linear(1.5);
      final TextPainterBlockMeasurer measurer = TextPainterBlockMeasurer(
        contentWidth: geo.contentWidth,
        scale: geo.scale,
        textScaler: scaler,
      );
      final List<JoodPage> pages = FlowPaginator.paginate(
        blocks: doc.blocks,
        contentHeight: geo.contentHeight,
        measurer: measurer,
      );
      expect(pages.length, greaterThan(1), reason: 'المستند يمتدّ لعدة صفحات');

      final Finder page1 = find.byKey(
        const ValueKey<String>('writer-page-1'),
      );
      expect(page1, findsOneWidget);
      final List<String> rendered = textsUnder(tester, page1);

      final List<String> expected = <String>[];
      for (final JoodPageSlice slice in pages.first.slices) {
        final List<String> lines = measurer.linesOf(slice.block);
        for (
          int i = slice.lineStart;
          i < slice.lineEnd && i < lines.length;
          i++
        ) {
          expected.add(lines[i]);
        }
      }

      // العدد والنصّ: المعاينة ترسم ما قاسه مُقاسها بنفس المقياس.
      expect(rendered.length, expected.length);
      for (final String line in expected) {
        expect(rendered, contains(line));
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('تكبير أكبر في المعاينة ⇒ أسطر أقلّ في الصفحة وأعلى منها', (
      WidgetTester tester,
    ) async {
      final JoodWriterDocument doc = makeDocument(
        staticParagraphs: 4,
        unitRepeat: 20,
      );
      final Finder page1 = find.byKey(
        const ValueKey<String>('writer-page-1'),
      );

      await pumpPagesView(tester, doc, 1.0, surface: surface, padding: padding);
      final ({double contentWidth, double contentHeight, double scale}) geo =
          previewGeometry(surface, padding);
      final TextPainterBlockMeasurer at1 = TextPainterBlockMeasurer(
        contentWidth: geo.contentWidth,
        scale: geo.scale,
        textScaler: TextScaler.linear(1.0),
      );
      final double heightAt1 = tester
          .getSize(find.text(at1.linesOf(doc.blocks.first).first).first)
          .height;
      final int linesAt1 = textsUnder(tester, page1).length;
      expect(linesAt1, greaterThan(0));

      await pumpPagesView(tester, doc, 2.0, surface: surface, padding: padding);
      final TextPainterBlockMeasurer at2 = TextPainterBlockMeasurer(
        contentWidth: geo.contentWidth,
        scale: geo.scale,
        textScaler: TextScaler.linear(2.0),
      );
      final double heightAt2 = tester
          .getSize(find.text(at2.linesOf(doc.blocks.first).first).first)
          .height;
      final int linesAt2 = textsUnder(tester, page1).length;

      // المقياس يصل إلى المعاينة: السطر أعلى، والصفحة تتّسع لأسطر أقلّ.
      expect(heightAt2, closeTo(heightAt1 * 2, heightAt1 * 0.08));
      expect(linesAt2, lessThan(linesAt1));
      expect(tester.takeException(), isNull);
    });
  });

  group('حتى في الضغط الأقصى', () {
    testWidgets('لصق ضخم بتكبير 3×: الشطر يجري، والقياس = الرسم، بلا فيض', (
      WidgetTester tester,
    ) async {
      final WriterDocumentController controller = makeController();
      await pumpCanvasScaled(tester, controller, 3.0);
      await tester.enterText(find.byKey(field0), sample * 300);
      await tester.pump();

      // الشطر الآلي يقسم الكتلة الضخمة قبل أن يُقاس أي فيض.
      expect(controller.document.blocks.length, greaterThan(1));

      final TextScaler scaler = TextScaler.linear(3.0);
      final Finder page1 = find.byKey(
        const ValueKey<String>('writer-page-1'),
      );
      expect(page1, findsOneWidget);

      // الشطر يترك الكتلة الأولى محرّراً في صفحتها (إشارة النشاط لا تتبع
      // الشطر) — أو يعيدها سطراً ثابتاً إن تُبدلت الإشارة؛ فالشكل يُقرأ من
      // الشجرة في الحالتين، ويتحقق الاختبار من المسار الظاهر وحده.
      final Set<int> editors = editorBlocksUnder(tester, page1);
      final JoodPage firstPage = canvasPages(controller.document, scaler).first;
      final List<String> expected = expectedStaticLines(
        firstPage,
        scaler,
        editors,
      );
      final List<String> rendered = textsUnder(tester, page1);
      expect(rendered.length, expected.length);
      for (final String line in expected) {
        expect(rendered, contains(line));
      }

      // المسار الآخر: المحرّر يرسم نصّه بارتفاع أسطره المقيسة بالمقياس نفسه.
      if (editors.contains(0)) {
        final TextPainterBlockMeasurer measurer = canvasMeasurer(scaler);
        final JoodWriterBlock edited = controller.document.blocks.first;
        final double measuredHeight =
            measurer.linesOf(edited).length * measurer.lineHeightOf(edited);
        final double editorHeight = tester.getSize(find.byKey(field0)).height;
        expect(editorHeight, closeTo(measuredHeight, measuredHeight * 0.12));
      }

      final Size pageSize = tester.getSize(page1);
      expect(pageSize.width, closeTo(210 * pxPerMm, 0.01));
      expect(pageSize.height, closeTo(297 * pxPerMm, 0.01));
      expect(tester.takeException(), isNull);
    });
  });
}
