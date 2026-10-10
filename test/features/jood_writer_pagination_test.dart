import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/features/jood_writer/domain/flow_paginator.dart';
import 'package:joodcraft/features/jood_writer/domain/jood_writer_block.dart';
import 'package:joodcraft/features/jood_writer/domain/jood_writer_document.dart';
import 'package:joodcraft/features/jood_writer/presentation/text_painter_measurer.dart';
import 'package:joodcraft/features/jood_writer/presentation/widgets/writer_canvas.dart';
import 'package:joodcraft/features/jood_writer/presentation/writer_document_controller.dart';

/// اختبارات الترقية الخامسة لـ«جود كاتب»: فاصل الصفحات اليدوي، تدفّق الفقرة
/// بين صفحتين، تخصيص أرقام الصفحات، طي الكتاب، وإزاحة السطر الأول وحده.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const Key field0 = ValueKey<String>('writer-field-0');
  const String longLine = 'سطر الاختبار الطويل ';

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

  Future<void> pumpCanvas(
    WidgetTester tester,
    WriterDocumentController controller,
  ) async {
    // ارتفاع كافٍ ليبقى الصف الثاني داخل مدى البناء (المصحف الافتراضي).
    await tester.binding.setSurfaceSize(const Size(1280, 1300));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          // التطبيق عربي (RTL) افتراضياً — نحاكي اتجاه الإنتاج.
          textDirection: TextDirection.rtl,
          child: Scaffold(body: WriterCanvas(controller: controller)),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> settleScroll(WidgetTester tester) async {
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// مزاح التمرير اللحظي لمساحة العمل.
  ScrollController canvasScroll(WidgetTester tester) {
    final ListView list = tester.widget<ListView>(
      find.byWidgetPredicate(
        (Widget w) => w is ListView && w.controller != null,
      ),
    );
    return list.controller!;
  }

  /// حواف النصوص اليمنى (بترتيب الظهور): في النص العربي تُقاس الإزاحة من
  /// الحافة اليمنى لأن السطر يبدأ عندها، والإزاحة البادئة تزيحه يساراً.
  List<double> lineRightEdges(WidgetTester tester, Key pageKey) {
    final Iterable<Element> elements = find
        .descendant(of: find.byKey(pageKey), matching: find.byType(Text))
        .evaluate()
        .where((Element e) {
          final Widget w = e.widget;
          return w is Text && w.data != null && w.data!.isNotEmpty;
        });
    return elements.map<double>((Element e) {
      final RenderBox box = e.renderObject! as RenderBox;
      final Offset bottomRight = box.localToGlobal(
        box.size.bottomRight(Offset.zero),
      );
      return bottomRight.dx;
    }).toList();
  }

  group('1) فاصل الصفحات اليدوي', () {
    test('المحوّل يُدرج فاصلًا عند المؤشر ويحفظ نصّي الجزأين', () {
      final WriterDocumentController controller = makeController(
        initialDocument: const JoodWriterDocument(
          title: 't',
          blocks: <JoodWriterBlock>[JoodWriterBlock(text: 'abcdef')],
        ),
      );

      controller.controllers[0].selection = const TextSelection.collapsed(
        offset: 2,
      );
      controller.insertPageBreakAtCaret();

      expect(controller.document.blocks.length, 2);
      expect(controller.document.blocks[0].text, 'ab');
      expect(controller.document.blocks[1].text, 'cdef');
      // الجزء اللاحق يحمل الفاصل ⇒ صفحته الجديدة ثابتة.
      expect(controller.document.blocks[1].pageBreakBefore, isTrue);
      expect(controller.document.blocks[0].pageBreakBefore, isFalse);
      // الحقول موازنة للكتل، والمؤشر عند مطلع الجزء الجديد.
      expect(controller.controllers.length, 2);
      expect(controller.controllers[0].text, 'ab');
      expect(controller.controllers[1].text, 'cdef');
    });

    test(
      'المحرّك يفتح صفحة جديدة للكتلة ذات الفاصل ولو كان المحتوى قصيراً',
      () {
        final List<JoodPage> pages = FlowPaginator.paginate(
          blocks: const <JoodWriterBlock>[
            JoodWriterBlock(text: 'سطر'),
            JoodWriterBlock(text: 'سطر', pageBreakBefore: true),
          ],
          contentHeight: 297 * WriterCanvas.pxPerMm - 50,
          measurer: TextPainterBlockMeasurer(
            contentWidth: 210 * WriterCanvas.pxPerMm - 50,
          ),
        );
        expect(pages.length, 2);
        expect(pages[1].slices.first.blockIndex, 1);
      },
    );

    testWidgets('اللوحة ترسم صفحة ثانية فور الإدراج حتى مع محتوى قصير', (
      WidgetTester tester,
    ) async {
      final WriterDocumentController controller = makeController();
      await pumpCanvas(tester, controller);
      expect(find.byKey(const ValueKey<String>('writer-page-2')), findsNothing);

      await tester.enterText(find.byKey(field0), 'نص قصير جداً');
      await tester.pump();
      controller.controllers[0].selection = const TextSelection.collapsed(
        offset: 4,
      );
      controller.insertPageBreakAtCaret();
      await tester.pump();

      // الصفحة الثانية وُلدت فوراً حتى لا يملأ النص صفحة واحدة.
      expect(
        find.byKey(const ValueKey<String>('writer-page-2')),
        findsOneWidget,
      );
      expect(controller.document.blocks[1].pageBreakBefore, isTrue);
      expect(tester.takeException(), isNull);
    });
  });

  group('2) تدفّق الفقرة بين صفحتين', () {
    testWidgets(
      'الجزء المنقول يستأنف في قمة الصفحة التالية بلا إزاحة ولا فراغ',
      (WidgetTester tester) async {
        final WriterDocumentController controller = makeController(
          initialDocument: const JoodWriterDocument(
            title: 't',
            blocks: <JoodWriterBlock>[
              JoodWriterBlock(
                text: 'فقرة طويلة جداً لتنشطر بين صفحتين',
                firstLineIndentCm: 1.0,
                spaceBefore: 12,
              ),
            ],
          ),
        );
        await pumpCanvas(tester, controller);

        await tester.enterText(find.byKey(field0), longLine * 400);
        await tester.pump();
        await settleScroll(tester);

        final List<JoodWriterBlock> blocks = controller.document.blocks;
        expect(blocks.length, greaterThan(1));
        // كل جزء بعد الشطر يستأنف الفقرة: بلا إزاحة سطر أول (ليس مطلع فقرة)
        // وبلا مسافة قبله ⇒ يلامس قمة صفحته تماماً كبقية سطور الفقرة.
        for (int i = 1; i < blocks.length; i++) {
          expect(blocks[i].firstLineIndentCm, 0);
          expect(blocks[i].spaceBefore, 0);
        }
        // والأجزاء تحمل نصّها بلا فقد حرف واحد (فقرة واحدة منشطرة طبيعياً).
        final String rejoined = blocks
            .map((JoodWriterBlock b) => b.text)
            .join();
        expect(rejoined, longLine * 400);
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('3) تخصيص أرقام الصفحات بالكامل', () {
    test('الإعدادات الجديدة تنجو من الترميز وتعود كما هي', () {
      const PageNumberingConfig config = PageNumberingConfig(
        fontSize: 16,
        color: 0xFFC62828,
        align: PageNumberAlign.left,
        pattern: PageNumberPattern.slash,
      );
      expect(PageNumberingConfig.fromJson(config.toJson()), config);
      // مستندات قديمة تحمل القيم الافتراضية بلا فقد أي سلوك.
      final PageNumberingConfig legacy = PageNumberingConfig.fromJson(
        const <String, dynamic>{'enabled': true},
      );
      expect(legacy.fontSize, 10);
      expect(legacy.color, isNull);
      expect(legacy.align, PageNumberAlign.center);
      expect(legacy.pattern, PageNumberPattern.pageOfTotal);
    });

    test('أنماط العرض تُنتج النصوص المتوقعة', () {
      const PageNumberingConfig base = PageNumberingConfig();
      expect(base.labelFor(0, 3), 'صفحة 1 من 3');
      expect(
        base.copyWith(pattern: PageNumberPattern.pageOnly).labelFor(1, 3),
        'صفحة 2',
      );
      expect(
        base.copyWith(pattern: PageNumberPattern.plain).labelFor(2, 3),
        '3',
      );
      expect(
        base.copyWith(pattern: PageNumberPattern.slash).labelFor(1, 3),
        '2 / 3',
      );
    });

    testWidgets('اللوحة ترسم الرقم بالحجم واللون والمحاذاة المختارة', (
      WidgetTester tester,
    ) async {
      final WriterDocumentController controller = makeController();
      await pumpCanvas(tester, controller);

      // افتراضياً: «صفحة 1 من 1» وسطاً بلون رمادي صغير.
      expect(find.text('صفحة 1 من 1'), findsOneWidget);

      controller.setPageNumbering(
        controller.document.pageNumbering.copyWith(
          pattern: PageNumberPattern.plain,
          align: PageNumberAlign.left,
          fontSize: 16,
          color: const Color(0xFFC62828).toARGB32(),
        ),
      );
      await tester.pump();

      final Finder labelFinder = find.byKey(
        const ValueKey<String>('writer-page-number-label'),
      );
      final Text label = tester.widget<Text>(labelFinder);
      expect(label.data, '1');
      expect(label.style?.fontSize, 16);
      expect(label.style?.color, const Color(0xFFC62828));

      // المحاذاة يساراً فعلياً: التسمية قرب حافة المحتوى اليسرى لا في الوسط.
      expect(
        tester.getTopLeft(labelFinder).dx,
        lessThan(WriterCanvas.pxPerMm * 100),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('4) طي الكتاب (صفحتان متقابلتان)', () {
    test('المتحكّم يبدّل بين الوضعَين', () {
      final WriterDocumentController controller = makeController();
      expect(controller.viewMode, WriterViewMode.single);
      controller.toggleViewMode();
      expect(controller.viewMode, WriterViewMode.spread);
      controller.toggleViewMode();
      expect(controller.viewMode, WriterViewMode.single);
    });

    testWidgets('الصفحتان المتقابلتان تُرسمان جنباً إلى جنب والفردية يميناً', (
      WidgetTester tester,
    ) async {
      final WriterDocumentController controller = makeController();
      await pumpCanvas(tester, controller);

      await tester.enterText(find.byKey(field0), longLine * 400);
      await tester.pump();
      await settleScroll(tester);
      expect(controller.document.blocks.length, greaterThan(1));

      controller.toggleViewMode();
      await tester.pump();
      // العودة إلى أول صفّ متقابل لفحص الصفحتين الأوليين.
      canvasScroll(tester).jumpTo(0);
      await settleScroll(tester);

      final Finder page1 = find.byKey(const ValueKey<String>('writer-page-1'));
      final Finder page2 = find.byKey(const ValueKey<String>('writer-page-2'));
      expect(page1, findsOneWidget);
      expect(page2, findsOneWidget);

      // في الكتاب العربي: الصفحة الفردية (الأولى) يمين والزوجية إلى يسارها.
      expect(
        tester.getTopLeft(page1).dx,
        greaterThan(tester.getTopLeft(page2).dx),
      );
      // الاثنتان على ارتفاع واحد — صفّ واحد متقابل كالكتاب المطبوع.
      expect(
        tester.getTopLeft(page1).dy,
        closeTo(tester.getTopLeft(page2).dy, 1),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('5) إزاحة السطر الأول وحده', () {
    testWidgets('السطر الأول فقط منزاح وبقية الأسطر على الهامش نفسه', (
      WidgetTester tester,
    ) async {
      final WriterDocumentController controller = makeController(
        initialDocument: JoodWriterDocument(
          title: 't',
          blocks: <JoodWriterBlock>[
            JoodWriterBlock(text: longLine * 8, firstLineIndentCm: 1.0),
            const JoodWriterBlock(text: ''),
          ],
        ),
      );
      await pumpCanvas(tester, controller);
      // جعل الكتلة الثانية نشطة ⇒ الأولى تُرسم نصاً ثابتاً سطراً سطراً.
      controller.setActiveBlock(1);
      await tester.pump();

      final List<double> edges = lineRightEdges(
        tester,
        const ValueKey<String>('writer-page-1'),
      );
      expect(edges.length, greaterThanOrEqualTo(3));

      final double indent = 1.0 * 10 * WriterCanvas.pxPerMm;
      // في النص العربي يبدأ السطر من حافته اليمنى: السطر الأول منزاح
      // بمقدار الإزاحة **بالضبط** يساراً عن باقي الأسطر…
      expect(edges[1] - edges[0], closeTo(indent, 1.0));
      // …وبقية الأسطر تبدأ من الهامش نفسه تماماً (صفر إزاحة).
      expect(edges[2] - edges[1], closeTo(0, 0.5));
      expect(tester.takeException(), isNull);
    });
  });
}
