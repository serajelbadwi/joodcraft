import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/features/jood_writer/domain/jood_writer_block.dart';
import 'package:joodcraft/features/jood_writer/domain/jood_writer_document.dart';
import 'package:joodcraft/features/jood_writer/presentation/widgets/writer_canvas.dart';
import 'package:joodcraft/features/jood_writer/presentation/writer_document_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// اختبارات ميزات «جود كاتب» الجديدة: الترقيم الذكي، دمج الكتل بالمسح
/// للخلف، والحفظ المحلي مع الحفظ التلقائي.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // مزوّد تفضيلات وهمي: كل اختبار يبدأ بتخزين نظيف.
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  const Key field0 = ValueKey<String>('writer-field-0');
  const String longLine = 'سطر الاختبار الطويل ';

  /// متحكّم بلا حفظ تلقائي: اختبارات الترقيم والدمج لا يهمّها المؤقّت.
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

  Future<void> setSurface(WidgetTester tester, Size size) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  Future<WriterDocumentController> pumpCanvas(
    WidgetTester tester,
    WriterDocumentController controller,
  ) async {
    await setSurface(tester, const Size(1280, 900));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: WriterCanvas(controller: controller)),
      ),
    );
    await tester.pump();
    return controller;
  }

  /// مهلة كافية لإنهاء حركة التمرير: إطار واحد لا يكفي لعدّاد الحركة.
  Future<void> settleScroll(WidgetTester tester) async {
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// مزاح التمرير اللحظي لمساحة العمل (تُقرأ من الـ ListView المُتحكَّم به).
  double canvasScrollOffset(WidgetTester tester) {
    final ListView list = tester.widget<ListView>(
      find.byWidgetPredicate(
        (Widget w) => w is ListView && w.controller != null,
      ),
    );
    return list.controller!.offset;
  }

  group('ترقيم الصفحات الذكي', () {
    test('قواعد الترقيم: الاستثناء، استئناف العدّ، والإجمالي المرقّم', () {
      const PageNumberingConfig all = PageNumberingConfig();
      expect(all.enabled, isTrue);
      expect(all.shouldNumberPage(0), isTrue);
      expect(all.displayNumber(0), 1);
      expect(all.numberedTotal(3), 3);

      // استثناء الغلاف: صفحته بلا رقم، والتالي تُعرض «صفحة 1».
      const PageNumberingConfig cover = PageNumberingConfig(excludeFirstN: 1);
      expect(cover.shouldNumberPage(0), isFalse);
      expect(cover.shouldNumberPage(1), isTrue);
      expect(cover.displayNumber(1), 1);
      expect(cover.numberedTotal(4), 3);

      // الترقيم معطّل: لا تذييل أبداً.
      const PageNumberingConfig off = PageNumberingConfig(enabled: false);
      expect(off.shouldNumberPage(0), isFalse);
    });

    test('الإعدادات تنجو من الترميز وتعود كما هي', () {
      const PageNumberingConfig config = PageNumberingConfig(
        enabled: true,
        startPage: 3,
        excludeFirstN: 2,
      );
      expect(PageNumberingConfig.fromJson(config.toJson()), config);
      // مستندات قديمة بلا مفتاح الترقيم تُرقّم افتراضياً (لا فقدان سلوك).
      expect(PageNumberingConfig.fromJson(null).enabled, isTrue);
    });

    testWidgets('المتحكّم يفعّل الترقيم ويستثني أول صفحات ويقيّد القيم', (
      WidgetTester tester,
    ) async {
      final WriterDocumentController controller = makeController();

      expect(controller.document.pageNumbering.enabled, isTrue);

      controller.setPageNumberingEnabled(false);
      expect(controller.document.pageNumbering.enabled, isFalse);

      controller.setPageNumberingExcludeFirst(2);
      expect(controller.document.pageNumbering.excludeFirstN, 2);
      expect(controller.isDirty, isTrue);

      // قيم خارج المدى تُحدّ إلى الحدّ الأقصى.
      controller.setPageNumberingExcludeFirst(999);
      expect(controller.document.pageNumbering.excludeFirstN, 20);
    });

    testWidgets('اللوحة تعرض الترقيم في تذييل الصفحة وتختفي عند التعطيل', (
      WidgetTester tester,
    ) async {
      final WriterDocumentController controller = makeController();
      await pumpCanvas(tester, controller);

      // مستند بصفحة واحدة: «صفحة 1 من 1».
      expect(find.text('صفحة 1 من 1'), findsOneWidget);

      controller.setPageNumberingEnabled(false);
      await tester.pump();
      expect(find.textContaining('صفحة'), findsNothing);

      controller.setPageNumberingEnabled(true);
      controller.setPageNumberingExcludeFirst(1);
      await tester.pump();
      // الصفحة الوحيدة مستثناة الآن ⇒ لا تذييل إطلاقاً.
      expect(find.textContaining('صفحة'), findsNothing);
    });

    testWidgets('مع مستند متعدد الصفحات: المستثناة بلا رقم والباقي مرقّم', (
      WidgetTester tester,
    ) async {
      final WriterDocumentController controller = makeController();
      await pumpCanvas(tester, controller);

      await tester.enterText(find.byKey(field0), longLine * 400);
      await tester.pump();
      await settleScroll(tester);
      // الشطر الآلي ضاعف الكتل (= الصفحات) ومرّرت المساحة إلى صفحة لاحقة.
      expect(controller.document.blocks.length, greaterThan(1));
      expect(canvasScrollOffset(tester), greaterThan(0));

      // الترقيم مفعّل ⇒ تذييل ظاهر على الصفحات المرئية.
      expect(find.textContaining('صفحة '), findsWidgets);

      // استثناء كل الصفحات ⇒ لا تذييل إطلاقاً.
      controller.setPageNumberingExcludeFirst(20);
      await tester.pump();
      expect(find.textContaining('صفحة '), findsNothing);

      // إرجاع الاستثناء ⇒ الترقيم يعود.
      controller.setPageNumberingExcludeFirst(0);
      await tester.pump();
      expect(find.textContaining('صفحة '), findsWidgets);
    });
  });

  group('دمج الكتل بالمسح للخلف (Backspace)', () {
    test('splitBlockAt ثم merge يعيدان الحالة كما كانتا', () async {
      final WriterDocumentController controller = makeController(
        initialDocument: const JoodWriterDocument(
          title: 't',
          blocks: <JoodWriterBlock>[JoodWriterBlock(text: 'abcdef')],
        ),
      );

      controller.splitBlockAt(0, 'abc', 'def');
      expect(controller.document.blocks.length, 2);

      controller.mergeWithPreviousBlock(1);
      expect(controller.document.blocks.length, 1);
      expect(controller.controllers.length, 1);
      expect(controller.focusNodes.length, 1);
      // لا فقدانحرف واحد.
      expect(controller.controllers[0].text, 'abcdef');
      expect(controller.activeBlockIndex, 0);
    });

    testWidgets('Backspace في بداية كتلة صفحة جديدة يدمجها ويُلغي صفحتها', (
      WidgetTester tester,
    ) async {
      final WriterDocumentController controller = makeController();
      await pumpCanvas(tester, controller);

      // لصق ضخم ⇒ شطر آلي إلى صفحات متعددة.
      await tester.enterText(find.byKey(field0), longLine * 400);
      await tester.pump();
      await settleScroll(tester);

      final int splitBlocks = controller.document.blocks.length;
      expect(splitBlocks, greaterThan(1));
      expect(canvasScrollOffset(tester), greaterThan(0));

      // المستخدم مسح محتوى صفحته حتى صارت فارغة تماماً.
      final int last = splitBlocks - 1;
      controller.controllers[last].value = const TextEditingValue(text: '');
      await tester.pump();
      await settleScroll(tester);

      // ثم ضغط Backspace في مطلع أول سطر من صفحته الجديدة.
      final String keptText = controller.controllers[last - 1].text;
      controller.setActiveBlock(last);
      controller.focusNodes[last].requestFocus();
      controller.controllers[last].selection = const TextSelection.collapsed(
        offset: 0,
      );
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pump();
      await settleScroll(tester);

      // الدمج تمّ: كتلة أقل (= صفحة فارغة أُلغيت)، وحقل أقل، ولا نصّ ضاع.
      expect(tester.takeException(), isNull);
      expect(controller.document.blocks.length, splitBlocks - 1);
      expect(controller.controllers.length, splitBlocks - 1);
      expect(controller.focusNodes.length, splitBlocks - 1);
      // نصّ الصفحة السابقة بقي كما كان حرفاً بحرف، والكتلة الفارغة اندمجت فيه.
      expect(controller.controllers[splitBlocks - 2].text, keptText);
      expect(controller.activeBlockIndex, splitBlocks - 2);
    });
  });

  group('الحفظ المحلي والحفظ التلقائي', () {
    testWidgets('الحفظ الفوري يُنظّف حالة isDirty ويحفظ الجسم والوصف', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final WriterDocumentController controller = WriterDocumentController();
      addTearDown(controller.dispose);

      controller.renameDocument('تقرير الأداء');
      controller.controllers[0].value = const TextEditingValue(text: 'محتوى');
      expect(controller.isDirty, isTrue);

      await controller.saveDocument();

      expect(controller.isDirty, isFalse);
      final String id = controller.documentId!;
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('jood_writer_$id'), isNotNull);
      expect(prefs.getString('jood_writer_meta_$id'), contains('تقرير الأداء'));
      // آخر مستند مفتوح يُوثَّق لاستئناف الجلسة.
      expect(prefs.getString('jood_writer_last_document'), id);
    });

    testWidgets('الحفظ التلقائي ينتظر استقرار الكتابة ثم يحفظ وحده', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final WriterDocumentController controller = WriterDocumentController();
      addTearDown(controller.dispose);
      // شجرة تستمع للمتحكّم حتى تعمل أوزان الإطار والتايمر.
      await tester.pumpWidget(
        ListenableBuilder(
          listenable: controller,
          builder: (BuildContext context, _) => const SizedBox.shrink(),
        ),
      );
      await tester.pump();

      controller.controllers[0].value = const TextEditingValue(text: 'نص');
      expect(controller.isDirty, isTrue);
      expect(controller.documentId, isNull);

      // قبل انقضاء المهلة: لا حفظ بعد.
      await tester.pump(const Duration(milliseconds: 400));
      expect(controller.documentId, isNull);

      // انقضت المهلة ⇒ الحفظ يتم وحده.
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
      expect(controller.documentId, isNotNull);
      expect(controller.isDirty, isFalse);

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString('jood_writer_${controller.documentId}'),
        isNotNull,
      );

      // تعديل جديد يعيد جدولة الحفظ ولا يُسقط الحالة.
      controller.controllers[0].value = const TextEditingValue(
        text: 'نص موسّع',
      );
      expect(controller.isDirty, isTrue);
      await controller.saveDocument();
      expect(controller.isDirty, isFalse);
    });

    testWidgets(
      'تعطيل الحفظ التلقائي يوقف المؤقّت ويُبقي التغييرات غير محفوظة',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues(<String, Object>{});
        final WriterDocumentController controller = WriterDocumentController();
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          ListenableBuilder(
            listenable: controller,
            builder: (BuildContext context, _) => const SizedBox.shrink(),
          ),
        );
        await tester.pump();

        controller.setAutosaveEnabled(false);
        controller.controllers[0].value = const TextEditingValue(text: 'مسودة');
        await tester.pump(const Duration(seconds: 2));

        expect(controller.isDirty, isTrue);
        expect(controller.documentId, isNull);
      },
    );

    testWidgets('القائمة والفتح وإعادة التسمية والحذف والتنشيط', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final WriterDocumentController controller = WriterDocumentController();
      addTearDown(controller.dispose);

      // حفظ مستندين.
      controller.renameDocument('الأول');
      controller.controllers[0].value = const TextEditingValue(
        text: 'محتوى الأول',
      );
      await controller.saveDocument();
      final String firstId = controller.documentId!;

      controller.createNewDocument();
      expect(controller.documentId, isNull);
      expect(controller.document.title, 'مستند جديد');

      controller.renameDocument('الثاني');
      await controller.saveDocument();
      final String secondId = controller.documentId!;
      expect(secondId, isNot(firstId));

      // القائمة تحمل المستندين، الأحدث أولاً.
      final List<WriterDocumentSummary> items = await controller
          .listSavedDocuments();
      expect(items.length, 2);
      expect(items.first.id, secondId);
      expect(
        items.map((WriterDocumentSummary i) => i.title),
        containsAll(<String>['الأول', 'الثاني']),
      );

      // فتح المستند الأول يستعيد نصّه وعنوانه.
      expect(await controller.loadSavedDocument(firstId), isTrue);
      expect(controller.document.title, 'الأول');
      expect(controller.controllers[0].text, 'محتوى الأول');
      expect(controller.isDirty, isFalse);

      // إعادة التسمية تُعلّم التغيير ويحفظها الحفظ التلقائي/الفوري.
      controller.renameDocument('الأول (معاد تسميته)');
      expect(controller.isDirty, isTrue);
      await controller.saveDocument();
      final List<WriterDocumentSummary> renamed = await controller
          .listSavedDocuments();
      expect(
        renamed.firstWhere((WriterDocumentSummary i) => i.id == firstId).title,
        'الأول (معاد تسميته)',
      );

      // الحذف النهائي يزيله من القائمة والتخزين.
      await controller.deleteSavedDocument(firstId);
      final List<WriterDocumentSummary> afterDelete = await controller
          .listSavedDocuments();
      expect(afterDelete.length, 1);
      expect(afterDelete.single.id, secondId);

      // استئناف آخر مستند مفتوح: نحفظ المستند الحالي أولاً ليصبح هو الأخير.
      await controller.saveDocument();
      final String lastId = controller.documentId!;
      expect(await controller.restoreLastDocument(), isTrue);
      expect(controller.documentId, lastId);
    });

    testWidgets('الشاشة تستأنف آخر مستند عند الإقلاع', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final WriterDocumentController seed = WriterDocumentController();
      seed.renameDocument('مستند محفوظ مسبقاً');
      seed.controllers[0].value = const TextEditingValue(text: 'نصّ محفوظ');
      await seed.saveDocument();
      seed.dispose();

      final WriterDocumentController controller = WriterDocumentController();
      addTearDown(controller.dispose);
      expect(await controller.restoreLastDocument(), isTrue);
      expect(controller.document.title, 'مستند محفوظ مسبقاً');
      expect(controller.controllers[0].text, 'نصّ محفوظ');
    });
  });

  group('حسم فيض الصفحة نهائيًا (بلا شريط أصفر/أسود)', () {
    /// يبني اللوحة تحت تكبير نصّ معيّن — يحاكي تكبير نظام التشغيل (ويندوز)
    /// الذي به تُقاس النصوص أصغر ممّا تُرسم إن أُهمل المقياس في القياس.
    Future<void> pumpCanvasScaled(
      WidgetTester tester,
      WriterDocumentController controller,
      double scaler,
    ) async {
      await setSurface(tester, const Size(1280, 900));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(scaler)),
              child: WriterCanvas(controller: controller),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('تكبير 1.5× مع لصق طويل: الشطر يسبق الفيض ولا يظهر شريط', (
      WidgetTester tester,
    ) async {
      final WriterDocumentController controller = makeController();
      await pumpCanvasScaled(tester, controller, 1.5);

      await tester.enterText(find.byKey(field0), longLine * 300);
      await tester.pump();
      await settleScroll(tester);

      // القياس يجري بنفس مقياس الرسم ⇒ الشطر وقع فعلاً قبل أي إطار.
      expect(controller.document.blocks.length, greaterThan(1));
      expect(tester.takeException(), isNull);

      // استكمال الكتابة بعد الشطر في الحقل المرئي: بعدُ لا فيض ولا أي خطأ.
      final int last = controller.controllers.length - 1;
      await tester.enterText(
        find.byKey(ValueKey<String>('writer-field-$last')),
        '${controller.controllers[last].text} نص إضافي بعد الشطر',
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'حتى بتكبير 2× ومحتوى ضخم: الورقة تبقى بمقاسها والمحتوى مقتصّ',
      (WidgetTester tester) async {
        final WriterDocumentController controller = makeController();
        await pumpCanvasScaled(tester, controller, 2.0);

        await tester.enterText(find.byKey(field0), longLine * 120);
        await tester.pump();

        // صندوق الصفحة لا يتجاوز مقاسها الورقي أبداً مهما علا المحتوى.
        final Size pageSize = tester.getSize(
          find.byKey(const ValueKey<String>('writer-page-1')),
        );
        expect(pageSize.height, closeTo(297 * WriterCanvas.pxPerMm, 0.01));
        expect(pageSize.width, closeTo(210 * WriterCanvas.pxPerMm, 0.01));

        // لا أي استثناء فيض في أي إطار — ولا شريط أصفر/أسود يُرسم أصلاً.
        expect(tester.takeException(), isNull);

        // الهيكل يحمل قناع الحدود عند محتوى الصفحة (ClipRect داخل OverflowBox).
        expect(
          find.descendant(
            of: find.byKey(const ValueKey<String>('writer-page-1')),
            matching: find.byType(ClipRect),
          ),
          findsWidgets,
        );
        expect(
          find.descendant(
            of: find.byKey(const ValueKey<String>('writer-page-1')),
            matching: find.byType(OverflowBox),
          ),
          findsWidgets,
        );
      },
    );
  });
}
