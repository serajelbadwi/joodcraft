import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/features/jood_writer/domain/jood_writer_block.dart';
import 'package:joodcraft/features/jood_writer/domain/jood_writer_document.dart';
import 'package:joodcraft/features/jood_writer/presentation/jood_writer_text_styles.dart';
import 'package:joodcraft/features/jood_writer/presentation/screens/jood_writer_screen.dart';
import 'package:joodcraft/features/jood_writer/presentation/text_painter_measurer.dart';
import 'package:joodcraft/features/jood_writer/presentation/widgets/writer_canvas.dart';
import 'package:joodcraft/features/jood_writer/presentation/writer_document_controller.dart';

/// اختبارات «جود كاتب»: ألوان النص والتحديد، الانشطار الآلي للصفحات،
/// والمسافة البادئة للسطر الأول.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const Key field0 = ValueKey<String>('writer-field-0');

  Future<void> setSurface(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  Future<void> pumpScreen(WidgetTester tester) async {
    await setSurface(tester);
    await tester.pumpWidget(const MaterialApp(home: JoodWriterScreen()));
    await tester.pump();
  }

  /// تبني اللوحة وحدها بمتحكّم نملكه — لنتحقّق من قرارات الشطر بأنفسنا.
  Future<WriterDocumentController> pumpCanvas(
    WidgetTester tester,
    WriterDocumentController controller,
  ) async {
    await setSurface(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: WriterCanvas(controller: controller)),
      ),
    );
    await tester.pump();
    return controller;
  }

  ScrollController canvasScroll(WidgetTester tester) {
    final ListView list = tester.widget<ListView>(
      find.byWidgetPredicate(
        (Widget w) => w is ListView && w.controller != null,
      ),
    );
    return list.controller!;
  }

  /// متحكّم بلا حفظ تلقائي: هذه الاختبارات تختبر الشطر والتنسيق، فيُعطَّل
  /// المؤقّت لئلا يبقى معلّقاً عند نهاية الإطار الوهمي.
  WriterDocumentController makeController({
    JoodWriterDocument? initialDocument,
  }) {
    final WriterDocumentController controller = WriterDocumentController(
      initialDocument: initialDocument,
    );
    controller.setAutosaveEnabled(false);
    return controller;
  }

  /// مرور زمني كافٍ لإنهاء حركة التمرير: إطارٌ واحد لا يكفي لأن عدّاد الحركة
  /// يبدأ عدّه من إطاره الأول.
  Future<void> settleScroll(WidgetTester tester) async {
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  group('ألوان النص والتحديد', () {
    testWidgets('نص الكتلة أسود ناصع بلا خلفية رمادية، والتحديد أزرق شفاف', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester);

      final TextField field = tester.widget<TextField>(find.byKey(field0));

      // 1) لون الكتابة أسود (#000000) لكل الفقرات والعناوين.
      final EditableText editable = tester.widget<EditableText>(
        find.descendant(
          of: find.byKey(field0),
          matching: find.byType(EditableText),
        ),
      );
      expect(editable.style.color, Colors.black);
      expect(
        JoodWriterTextStyles.of(const JoodWriterBlock(text: 'x')).color,
        Colors.black,
      );
      expect(
        JoodWriterTextStyles.of(
          const JoodWriterBlock(text: 'x', kind: JoodWriterBlockKind.heading1),
        ).color,
        Colors.black,
      );

      // 2) لا خلفية رمادية/داكنة حول الكتلة النشطة، والورقة بيضاء.
      expect(field.decoration?.filled, isFalse);
      expect(field.decoration?.fillColor, isNull);

      // 3) التحديد والمؤشر أزرق ناعم شفاف (20%) — النص يبقى مقروءاً.
      expect(field.cursorColor, WriterCanvas.selectionBlue);
      final Color? selectionColor = tester
          .widgetList<Theme>(find.byType(Theme))
          .map((Theme t) => t.data.textSelectionTheme.selectionColor)
          .firstWhere((Color? c) => c != null, orElse: () => null);
      expect(selectionColor, Colors.blue.withValues(alpha: 0.2));
    });
  });

  group('الانشطار الآلي للصفحات', () {
    testWidgets(
      'لصق نص أطول من الصفحة ينشئ صفحات جديدة بلا RenderFlex Overflow',
      (WidgetTester tester) async {
        final WriterDocumentController controller = makeController();
        addTearDown(controller.dispose);
        await pumpCanvas(tester, controller);

        expect(controller.document.blocks.length, 1);

        // لصق ضخم يتجاوز الصفحة الواحدة بعدة صفحات دفعةً واحدة.
        await tester.enterText(
          find.byKey(field0),
          'سطر الاختبار الطويل ' * 400,
        );
        await tester.pump();
        await settleScroll(tester);

        // لا فيض أبداً: أي RenderFlex كان سيُبلَّغ كاستثناء في الاختبار.
        expect(tester.takeException(), isNull);

        // النص الزائد انتقل إلى كتل جديدة — كل كتلة تبدأ صفحة جديدة.
        expect(controller.document.blocks.length, greaterThan(1));
        expect(
          controller.controllers.length,
          controller.document.blocks.length,
        );
        expect(controller.focusNodes.length, controller.document.blocks.length);

        // الحقول موازية لكتلها تماماً: لا اختلال في التماثل.
        for (int i = 0; i < controller.document.blocks.length; i++) {
          expect(
            controller.controllers[i].text,
            controller.document.blocks[i].text,
          );
        }
      },
    );

    testWidgets('كتابة تدريجية تُشطر تلقائياً بلا فيض ولا شريط أصفر', (
      WidgetTester tester,
    ) async {
      final WriterDocumentController controller = makeController();
      addTearDown(controller.dispose);
      await pumpCanvas(tester, controller);

      // إدخال متتابع في آخر حقل ظاهر — يحاكي الكتابة الحقيقية حرف الحرف.
      // بعد كل شطر نُمهل حركة التمرير حتى تظهر الصفحة الجديدة ومحلّها.
      for (int round = 1; round <= 6; round++) {
        await tester.enterText(
          find.byType(TextField).last,
          'سطر الاختبار الطويل ' * 40 * round,
        );
        await tester.pump();
        await settleScroll(tester);
        expect(tester.takeException(), isNull);
      }
      await settleScroll(tester);

      expect(tester.takeException(), isNull);
      expect(controller.document.blocks.length, greaterThan(1));
    });

    testWidgets('بعد الشطر تُمرَّر مساحة العمل إلى صفحتها الجديدة', (
      WidgetTester tester,
    ) async {
      final WriterDocumentController controller = makeController();
      addTearDown(controller.dispose);
      await pumpCanvas(tester, controller);

      expect(canvasScroll(tester).offset, 0);

      await tester.enterText(find.byKey(field0), 'سطر الاختبار الطويل ' * 400);
      await tester.pump();
      await settleScroll(tester);

      final ScrollController scroll = canvasScroll(tester);
      expect(scroll.hasClients, isTrue);
      // غادر موضع البداية ليُظهر الصفحة الجديدة، ولا يتجاوز آخر موضع ممكن.
      expect(scroll.offset, greaterThan(0));
      expect(scroll.offset, lessThanOrEqualTo(scroll.position.maxScrollExtent));
    });

    testWidgets('الشطر الآلي مربوط بمستمع تغيير النص في المتحكّم', (
      WidgetTester tester,
    ) async {
      final WriterDocumentController controller = makeController();
      addTearDown(controller.dispose);

      // المتحكّم لا يفرض الشطر؛ طبقة العرض تسجّله عند البناء.
      expect(controller.onEdited, isNull);

      bool called = false;
      controller.onEdited = () => called = true;
      // أي تغيير نصّي يستدعي المستمع فوراً (قبل رسم الإطار).
      controller.controllers[0].value = const TextEditingValue(text: 'abcdeff');
      expect(called, isTrue);
      expect(controller.document.blocks.single.text, 'abcdeff');
    });

    testWidgets('splitBlockAt يُبقي الحقول موازية للكتل وينقل المؤشر', (
      WidgetTester tester,
    ) async {
      final WriterDocumentController controller = makeController(
        initialDocument: const JoodWriterDocument(
          title: 't',
          blocks: <JoodWriterBlock>[JoodWriterBlock(text: 'abcdef')],
        ),
      );
      addTearDown(controller.dispose);

      // شجرة تستمع للمتحكّم حتى تُنجز أوزانها المؤجّلة ما بعد الإطار.
      await tester.pumpWidget(
        ListenableBuilder(
          listenable: controller,
          builder: (BuildContext context, _) => const SizedBox.shrink(),
        ),
      );
      await tester.pump();

      controller.splitBlockAt(0, 'abc', 'def');

      expect(controller.document.blocks.length, 2);
      expect(controller.controllers.length, 2);
      expect(controller.focusNodes.length, 2);
      // كل حقل يحمل نصّ كتلته بالضبط.
      expect(controller.controllers[0].text, 'abc');
      expect(controller.controllers[1].text, 'def');
      expect(controller.activeBlockIndex, 1);

      await tester.pump();
      // المؤشر عند نهاية الجزء المنقول لتكملة الكتابة مباشرة.
      expect(controller.controllers[1].selection.baseOffset, 3);
    });

    testWidgets('إضافة كتلة تحفظ تماثل الحقول والكتل', (
      WidgetTester tester,
    ) async {
      final WriterDocumentController controller = makeController();
      addTearDown(controller.dispose);

      controller.addBlockAfterActive();
      controller.addBlockAfterActive();

      expect(controller.document.blocks.length, 3);
      expect(controller.controllers.length, 3);
      expect(controller.activeBlockIndex, 2);

      // الكتابة في الحقل الأوسط تُكتب في كتلته هي لا غيرها.
      controller.controllers[1].value = const TextEditingValue(text: 'وسط');
      expect(controller.document.blocks[1].text, 'وسط');
      expect(controller.document.blocks[0].text, '');
      expect(controller.document.blocks[2].text, '');
    });
  });

  group('المسافة البادئة للسطر الأول', () {
    test('الفقرة الابتدائية والفقرات الجديدة بها مسافة سطر أول', () {
      expect(
        JoodWriterDocument.empty().blocks.single.firstLineIndentCm,
        JoodWriterBlock.defaultFirstLineIndentCm,
      );

      final WriterDocumentController controller = makeController();
      addTearDown(controller.dispose);
      controller.addBlockAfterActive();
      expect(
        controller.document.blocks[1].firstLineIndentCm,
        JoodWriterBlock.defaultFirstLineIndentCm,
      );
    });

    testWidgets('إزاحة السطر الأول تأخذها السطر الأول وحده', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester);

      final TextField field = tester.widget<TextField>(find.byKey(field0));
      // لم يبقَ أي `prefix`: كان يُضيّق نطاق الالتفاف فتزحح كل الأسطر لا أولها.
      expect(field.decoration?.prefix, isNull);

      // الإزاحة صارت جزءاً من تدفّق النص: `WidgetSpan` واحد في أوله.
      final double expected =
          JoodWriterBlock.defaultFirstLineIndentCm * 10 * WriterCanvas.pxPerMm;
      final TextEditingController controller = field.controller!;
      final TextSpan span = controller.buildTextSpan(
        context: tester.element(find.byKey(field0)),
        style: const TextStyle(),
        withComposing: false,
      );

      final List<InlineSpan> children = span.children ?? const <InlineSpan>[];
      expect(children.length, 2, reason: 'فراغ الإزاحة + نصّ الحقل');
      expect(children.first, isA<WidgetSpan>());
      expect((children.first as WidgetSpan).child, isA<SizedBox>());
      expect(((children.first as WidgetSpan).child as SizedBox).width, expected);
      expect(children.last, isA<TextSpan>());
    });

    testWidgets('الكتابة فوق الإزاحة تبقى نصّاً خالصاً بلا فراغ زائد', (
      WidgetTester tester,
    ) async {
      final WriterDocumentController controller = makeController();
      addTearDown(controller.dispose);
      await pumpCanvas(tester, controller);

      await tester.enterText(find.byKey(field0), 'فقرة تجربة');
      await tester.pump();

      // فراغ الإزاحة ليس حرفاً في النصّ: ما يُكتب يُخزَّن كما هو.
      expect(controller.document.blocks.first.text, 'فقرة تجربة');
      expect(controller.controllers.first.text, 'فقرة تجربة');
    });

    test('القياس يخصم إزاحة السطر الأول فتختصر أسطر الفقرة', () {
      const String sample = 'كلمات كثيره جدا لعرض السطر الاول وباقي الاقسام';
      final TextPainterBlockMeasurer measurer = TextPainterBlockMeasurer(
        contentWidth: 200,
      );

      final List<String> plain = measurer.linesOf(
        const JoodWriterBlock(text: sample),
      );
      final List<String> indented = measurer.linesOf(
        const JoodWriterBlock(text: sample, firstLineIndentCm: 2),
      );

      // النص كامل بلا فقد، لكن السطر يختصر لفسح مكان الإزاحة — وهذا الضمان
      // الذي يمنع تجاوز ارتفاع الكتلة المحسوب.
      expect(plain.join(''), sample);
      expect(indented.join(''), sample);
      expect(indented.first.length, lessThan(plain.first.length));
      expect(indented.length, greaterThanOrEqualTo(plain.length));
    });

    test('الإزاحة الكاملة وعرض مقدمة القائمة يُخصمان من عرض القياس', () {
      const String sample = 'كلمات كثيره جدا لعرض السطر الاول وباقي الاقسام';
      final TextPainterBlockMeasurer measurer = TextPainterBlockMeasurer(
        contentWidth: 200,
      );

      final List<String> plain = measurer.linesOf(
        const JoodWriterBlock(text: sample),
      );
      final List<String> fullIndent = measurer.linesOf(
        const JoodWriterBlock(text: sample, indentCm: 1),
      );
      final List<String> bullet = measurer.linesOf(
        const JoodWriterBlock(text: sample, kind: JoodWriterBlockKind.bullet),
      );

      expect(fullIndent.join(''), sample);
      expect(fullIndent.first.length, lessThanOrEqualTo(plain.first.length));
      expect(bullet.join(''), sample);
      expect(bullet.first.length, lessThanOrEqualTo(plain.first.length));
    });
  });

  group('الحجم الحقيقي للورقة', () {
    test('A4 يُحسب بمقاسه الورقي الفعلي (96dpi) لا بتقريب', () {
      // A4 = 210×297 مم، والمنطقية 96dpi ⇒ 793.70 × 1122.52 بكسل.
      expect(WriterCanvas.pxPerMm, closeTo(96 / 25.4, 1e-9));
      expect(210 * WriterCanvas.pxPerMm, closeTo(793.7, 0.01));
      expect(297 * WriterCanvas.pxPerMm, closeTo(1122.52, 0.02));
    });

    testWidgets('نافذة أضيق من الورقة لا تنكمش الورقة — يُصغَّر الطلاء فقط', (
      WidgetTester tester,
    ) async {
      final WriterDocumentController controller = makeController();
      addTearDown(controller.dispose);
      // نافذة أضيق من عرض A4 (600 < 793.7).
      await tester.binding.setSurfaceSize(const Size(600, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: WriterCanvas(controller: controller)),
        ),
      );
      await tester.pump();

      final Size laidOut = tester.getSize(
        find.byKey(const ValueKey<String>('writer-page-1')),
      );
      // الورقة تُخطَّط بمقاسها الحقيقي مهما ضاقت النافذة — فلا يختلّ التفاف
      // النص عن القياس، ولا يتغيّر موضع الشطر.
      expect(laidOut.width, closeTo(210 * WriterCanvas.pxPerMm, 0.01));
      expect(laidOut.height, closeTo(297 * WriterCanvas.pxPerMm, 0.01));
      expect(tester.takeException(), isNull);
    });

    testWidgets('نافذة واسعة تعرض الورقة بالحجم الحقيقي كاملاً', (
      WidgetTester tester,
    ) async {
      final WriterDocumentController controller = makeController();
      addTearDown(controller.dispose);
      await pumpCanvas(tester, controller);

      final Size laidOut = tester.getSize(
        find.byKey(const ValueKey<String>('writer-page-1')),
      );
      expect(laidOut.width, closeTo(210 * WriterCanvas.pxPerMm, 0.01));
      expect(laidOut.height, closeTo(297 * WriterCanvas.pxPerMm, 0.01));

      // حشو مساحة العمل موحّد — ومنه يُحسب معامل التصغير عند الضيق.
      final ListView list = tester.widget<ListView>(
        find.byWidgetPredicate(
          (Widget w) => w is ListView && w.controller != null,
        ),
      );
      expect(list.padding, WriterCanvas.canvasPadding);
    });
  });
}
