import 'dart:convert';

import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/constants/app_assets.dart';
import 'package:joodcraft/core/constants/app_constants.dart';
import 'package:joodcraft/core/models/template_document.dart';
import 'package:joodcraft/core/models/template_element.dart';
import 'package:joodcraft/core/pdf/pdf_font_catalog.dart';
import 'package:joodcraft/core/templates/local_template_store.dart';
import 'package:joodcraft/core/templates/template_record.dart';
import 'package:joodcraft/core/services/pdf_generator_service.dart';
import 'package:joodcraft/core/theme/app_theme.dart';
import 'package:joodcraft/features/batch_processor/domain/bulk_generation.dart';
import 'package:joodcraft/features/batch_processor/presentation/providers/batch_processor_controller.dart';
import 'package:joodcraft/features/batch_processor/presentation/screens/batch_processor_screen.dart';

import '../support/fake_template_repository.dart';

/// ملف CSV تجريبي فيه صف ناقص عمداً.
final Uint8List _csv = Uint8List.fromList(
  utf8.encode(
    'اسم المتدرب,رقم الشهادة,التاريخ\n'
    'أحمد الشمري,JC-0001,1447/03/12\n'
    'سارة العتيبي,,1447/03/13\n'
    'خالد القحطاني,JC-0003,1447/03/14\n',
  ),
);

/// مصنّف Excel فيه سطران تعريفيان قبل صف العناوين — لاختبار منتقي صف العناوين.
Uint8List _titledWorkbook() {
  final Excel excel = Excel.createExcel();
  final String sheet = excel.getDefaultSheet() ?? 'Sheet1';
  excel[sheet].appendRow(<CellValue?>[TextCellValue('كشف المتدربين')]);
  excel[sheet].appendRow(<CellValue?>[TextCellValue('تاريخ الإصدار')]);
  excel[sheet].appendRow(<CellValue?>[
    TextCellValue('اسم المتدرب'),
    TextCellValue('رقم الشهادة'),
  ]);
  excel[sheet].appendRow(<CellValue?>[
    TextCellValue('أحمد'),
    TextCellValue('JC-1'),
  ]);
  return Uint8List.fromList(excel.encode()!);
}

/// مصنّف Excel فيه ورقتان ببيانات مختلفة — لاختبار منتقي الأوراق.
Uint8List _twoSheetWorkbook() {
  final Excel excel = Excel.createExcel();
  final String first = excel.getDefaultSheet() ?? 'Sheet1';
  excel[first].appendRow(<CellValue?>[TextCellValue('اسم المتدرب')]);
  excel[first].appendRow(<CellValue?>[TextCellValue('أحمد')]);
  excel['الثانية'].appendRow(<CellValue?>[TextCellValue('اسم المتدرب')]);
  excel['الثانية'].appendRow(<CellValue?>[TextCellValue('سارة')]);
  return Uint8List.fromList(excel.encode()!);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late BatchProcessorController controller;

  // القالب النموذجي يُحمَّل من الأصول مرّة واحدة في نطاق زمني حقيقي (خارج
  // fake-async للاختبارات)، ثم يُحقَن في المتحكّم لتفادي تقلّب توقيت
  // `rootBundle` داخل اختبارات الودجات.
  late TemplateDocument certificateTemplate;

  // محرّك اختباري بلا isolate: اختبارات الودجات تعمل بمؤقّت مزيف لا يقود
  // isolate حقيقياً، فنعطّل المسار الخلفي هنا (وهو مسار الإنتاج فقط).
  late PdfGeneratorService testGenerator;

  setUpAll(() async {
    certificateTemplate = TemplateDocument.fromJsonString(
      await rootBundle.loadString(AppAssets.sampleCertificateTemplate),
    );
    testGenerator = await PdfGeneratorService.create(useIsolate: false);
  });

  Future<void> pumpScreen(
    WidgetTester tester, {
    Size size = const Size(1400, 1000),
    FakeTemplateRepository? repository,
    LocalTemplateStore? localStore,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    if (controller.document == null) {
      controller.useDocument(certificateTemplate);
    }

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: BatchProcessorScreen(
              controller: controller,
              repository: repository,
              localStore: localStore,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// قالب مستخدم مخصّص فيه حقلا `{{اسم_المتدرب}}` و`{{رقم_الشهادة}}`.
  TemplateRecord customTemplate({
    String id = 'cloud-custom-1',
    String title = 'شهادتي المخصّصة',
  }) {
    final TemplateDocument document = TemplateDocument(
      orientation: PageOrientation.landscape,
      elements: const <TemplateElement>[
        TextElement(
          id: 'text-1',
          box: ElementBox(x: 100, y: 100, width: 520, height: 80),
          text: 'تشهد المؤسسة بأن {{اسم_المتدرب}} أتمّ الدورة '
              'برقم {{رقم_الشهادة}}.',
        ),
      ],
    );
    return TemplateRecord(
      id: id,
      userId: 'user-1',
      title: title,
      category: TemplateCategory.certificate,
      orientation: PageOrientation.landscape,
      layoutData: document.toJson(),
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 2, 1),
    );
  }

  setUp(() {
    controller = BatchProcessorController(generator: testGenerator);
  });

  tearDown(() => controller.dispose());

  testWidgets('يعرض خطوات العمل كاملة قبل اختيار أي ملف', (WidgetTester tester) async {
    await pumpScreen(tester);

    expect(find.text('التوليد الجماعي من Excel'), findsOneWidget);
    expect(find.text('1) القالب'), findsOneWidget);
    expect(find.text('2) ملف البيانات'), findsOneWidget);
    expect(find.text('3) ربط الأعمدة بالحقول'), findsOneWidget);
    expect(find.text('4) الخلايا الفارغة والبيانات الناقصة'), findsOneWidget);
    expect(find.text('5) التوليد'), findsOneWidget);
    // قبل اختيار ملف: لوحة «تعيين الحقول بالنقر» بدل معاينة PDF.
    expect(find.text('تعيين الحقول بالنقر'), findsOneWidget);
    expect(
      find.text('لم يُختَر ملف بعد — الصيغ المدعومة: xlsx, xlsm, csv, tsv, txt'),
      findsOneWidget,
    );

    // القالب النموذجي (الشهادة) محمَّل وحقوله ظاهرة للربط.
    expect(controller.document, isNotNull);
    expect(controller.availableFields, isNotEmpty);
  });

  testWidgets('اختيار ملف يُظهر جدول الربط ومقترحاته', (WidgetTester tester) async {
    await pumpScreen(tester);

    controller.loadBytes(fileName: 'students.csv', bytes: _csv);
    await tester.pumpAndSettle();

    expect(controller.sheet.rowCount, 3);
    // ربط تلقائي من العناوين العربية.
    expect(controller.mapping.mappedCount, greaterThanOrEqualTo(2));
    expect(find.textContaining('مرتبط'), findsWidgets);
    expect(find.text('أحمد الشمري'), findsOneWidget);
  });

  testWidgets('التوليد يُنتج تقريراً ويُظهر معاينة الملف',
      (WidgetTester tester) async {
    // سطّح أعلى حتى يظهر زر التوليد أسفل العمود الأيسر دون تمرير.
    await pumpScreen(tester, size: const Size(1400, 1500));

    controller.loadBytes(fileName: 'students.csv', bytes: _csv);
    await tester.pumpAndSettle();

    // سياسة «تخطَّ الصف الناقص» (الافتراضية) تُسقط سارة بلا رقم شهادة.
    // `runAsync` يسمح بالعمل الحقيقي (تحميل الخطوط + توليد الملف) قبل أن يرتجع
    // المزيف الزمني لـ pumpAndSettle.
    await tester.tap(find.text('توليد الشهادات'));
    // نرسم إطاراً واحداً فقط بعد الضغط: شريط التقدّم غير محدّد المدة فلا ينتهي
    // أبداً، لذا لا نستعمل `pumpAndSettle` أثناء التوليد.
    await tester.pump();
    await tester.runAsync(() async {
      while (controller.busy) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
    });
    // لا نستعمل `pumpAndSettle`: بعد التوليد تُعرض معاينة PDF بمؤشّر تحميل
    // غير محدّد المدة لا يستقرّ أبداً. نرسم إطارات محدودة تكفي لتحديث الواجهة.
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    final BulkGenerationReport? report = controller.report;
    expect(report, isNotNull);
    expect(report!.totalRows, 3);
    expect(report.generatedCount, 2);
    // الصف ذو البيانات الناقصة (سارة) أُسقط
    expect(report.skippedCount, 1);
    // القراءة نفسها بلا ملاحظات (لا صيغ معطوبة ولا أعمدة غريبة).
    expect(controller.sheet.notes, isEmpty);
    expect(report.hasOutput, isTrue);

    expect(find.text('مُصدرة'), findsOneWidget);
    expect(find.text('صفوف لم تُصدر:'), findsOneWidget);
    // المعاينة استُبدلت بمشغّل PDF.
    expect(find.text('المعاينة تظهر هنا'), findsNothing);
  }, timeout: const Timeout(Duration(minutes: 2)));

  testWidgets('يُظهر رسالة عربية واضحة عند ملف غير مدعوم',
      (WidgetTester tester) async {
    await pumpScreen(tester);

    controller.loadBytes(
      fileName: 'logo.png',
      bytes: Uint8List.fromList(<int>[0x89, 0x50, 0x4E, 0x47]),
    );
    await tester.pumpAndSettle();

    expect(controller.errorAr, isNotNull);
    expect(find.textContaining('صيغة الملف غير مدعومة'), findsOneWidget);
    expect(controller.sheet.isEmpty, isTrue);
  });

  testWidgets('يُظهر تنبيهاً لطيفاً لملف Excel القديم .xls',
      (WidgetTester tester) async {
    await pumpScreen(tester);

    controller.loadBytes(
      fileName: 'قديم.xls',
      bytes: Uint8List.fromList(<int>[0xD0, 0xCF, 0x11, 0xE0]),
    );
    await tester.pumpAndSettle();

    expect(controller.errorAr, isNotNull);
    expect(controller.errorAr, contains('.xlsx'));
    expect(find.textContaining('Excel قديم'), findsOneWidget);
    expect(controller.sheet.isEmpty, isTrue);
  });

  testWidgets('يعرض منتقي الأوراق للمصنّف متعدد الأوراق ويقرأ الورقة المختارة',
      (WidgetTester tester) async {
    await pumpScreen(tester);

    await controller.loadBytes(
      fileName: 'multi.xlsx',
      bytes: _twoSheetWorkbook(),
    );
    await tester.pumpAndSettle();

    expect(controller.errorAr, isNull);
    expect(controller.hasSheetChoice, isTrue);
    expect(controller.sheetNames.length, greaterThanOrEqualTo(2));
    expect(controller.sheet.rowAt(0).cellAt(0), 'أحمد');
    expect(find.text('ورقة العمل'), findsOneWidget);

    await controller.selectSheet('الثانية');
    await tester.pumpAndSettle();

    expect(controller.sheet.sheetName, 'الثانية');
    expect(controller.sheet.rowAt(0).cellAt(0), 'سارة');
  });

  testWidgets('يعرض منتقي صف العناوين ويُعيد القراءة عند اختياره',
      (WidgetTester tester) async {
    await pumpScreen(tester);

    await controller.loadBytes(
      fileName: 'titled.xlsx',
      bytes: _titledWorkbook(),
    );
    await tester.pumpAndSettle();

    expect(controller.errorAr, isNull);
    expect(controller.canChooseHeaderRow, isTrue);
    expect(find.text('صف العناوين'), findsOneWidget);
    // الكشف الذكي يتخطى سطري العنوان ويجد صف العناوين الحقيقي تلقائياً.
    expect(controller.effectiveHeaderRowIndex, 2);
    expect(controller.sheet.headers.first, 'اسم المتدرب');

    // ويمكن للمستخدم فرض صفٍ بعينه يدوياً (هنا الصف الأول).
    await controller.setHeaderRowIndex(0);
    await tester.pumpAndSettle();

    expect(controller.headerRowIndex, 0);
    expect(controller.sheet.headers.first, 'كشف المتدربين');
  });

  testWidgets('يُتيح اختيار قالب المستخدم ويستخرج حقوله الديناميكية',
      (WidgetTester tester) async {
    final FakeTemplateRepository repository = FakeTemplateRepository();
    repository.records.add(customTemplate());

    await pumpScreen(
      tester,
      repository: repository,
      localStore: InMemoryLocalTemplateStore(),
    );

    expect(find.text('قالب من قوالبي'), findsOneWidget);

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    // الخيارات ظاهرة بعد فتح القائمة (قبل الفتح تكون offstage داخل الزر).
    expect(find.textContaining('شهادتي المخصّصة'), findsWidgets);
    await tester.tap(find.textContaining('شهادتي المخصّصة').last);
    await tester.pumpAndSettle();
    expect(controller.templateTitle, 'شهادتي المخصّصة');

    // الحقول استُخرجت ديناميكياً من نصّ القالب المختار.
    expect(
      controller.availableFields,
      containsAll(<String>['اسم_المتدرب', 'رقم_الشهادة']),
    );

    // الربط التلقائي مع ملف الإكسل المرفوع.
    await controller.loadBytes(fileName: 'students.csv', bytes: _csv);
    await tester.pumpAndSettle();

    expect(controller.mapping.mappedCount, greaterThanOrEqualTo(2));
    expect(controller.canGenerate, isTrue);
  });

  testWidgets('يُظهر قالب المستخدم المحلي ويسمح بالعودة للنموذجي',
      (WidgetTester tester) async {
    await pumpScreen(
      tester,
      localStore: InMemoryLocalTemplateStore(<TemplateRecord>[
        customTemplate(id: 'local-1', title: 'قالبي المحلي'),
      ]),
    );

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    expect(find.textContaining('قالبي المحلي'), findsWidgets);
    await tester.tap(find.textContaining('قالبي المحلي').last);
    await tester.pumpAndSettle();

    expect(controller.templateTitle, 'قالبي المحلي');

    // العودة إلى القوالب النموذجية المدمجة.
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('القوالب النموذجية').last);
    await tester.pumpAndSettle();

    expect(controller.templateTitle, isNot('قالبي المحلي'));
  });

  testWidgets('بلا قوالب مستخدم تظهر ملاحظة إرشادية',
      (WidgetTester tester) async {
    await pumpScreen(tester, localStore: InMemoryLocalTemplateStore());

    expect(find.textContaining('لا توجد قوالب محفوظة'), findsOneWidget);
  });

  testWidgets('قالب مستخدم: عنوان مرادف في الملف يُربط ويُستبدل فعلاً',
      (WidgetTester tester) async {
    // ملف بعنوان مرادف («اسم الطالب») لا يطابق مفتاح القالب حرفياً — وهو
    // الحال الأشيع في ملفات Excel العربية.
    final Uint8List csv = Uint8List.fromList(
      utf8.encode(
        'اسم الطالب,رقم التحقق\n'
        'أحمد الشمري,JC-0001\n'
        'سارة العتيبي,JC-0002\n',
      ),
    );

    final FakeTemplateRepository repository = FakeTemplateRepository();
    repository.records.add(customTemplate());

    await pumpScreen(
      tester,
      repository: repository,
      localStore: InMemoryLocalTemplateStore(),
    );

    // اختيار قالب المستخدم المخصّص.
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('شهادتي المخصّصة').last);
    await tester.pumpAndSettle();

    await controller.loadBytes(fileName: 'students.csv', bytes: csv);
    await tester.pumpAndSettle();

    // الربط التلقائي يطابق العناوين المرادفة بمفاتيح القالب العربية.
    expect(controller.mapping.fieldFor(0), 'اسم_المتدرب');
    expect(controller.mapping.fieldFor(1), 'رقم_الشهادة');
    expect(controller.canGenerate, isTrue);

    // والاستبدال الفعلي يُنتج اسم الصف لا القيمة التجريبية.
    final TemplateDocument document = controller.document!;
    final Map<String, String> row = controller.mapping.apply(
      controller.sheet.rowAt(0),
    );
    expect(row['اسم_المتدرب'], 'أحمد الشمري');
    expect(
      document.resolveFields(
        (document.elements.single as TextElement).text,
        row,
      ),
      contains('أحمد الشمري'),
    );
  });

  testWidgets('قالب مستخدم بلا حقول ديناميكية يظهر له تنبيه واضح',
      (WidgetTester tester) async {
    final TemplateDocument plain = TemplateDocument(
      orientation: PageOrientation.landscape,
      elements: const <TemplateElement>[
        TextElement(
          id: 'static',
          box: ElementBox(x: 100, y: 100, width: 520, height: 80),
          text: 'شهادة ثابتة بلا حقول',
        ),
      ],
    );
    final FakeTemplateRepository repository = FakeTemplateRepository();
    repository.records.add(
      TemplateRecord(
        id: 'plain-1',
        userId: 'user-1',
        title: 'قالب ثابت',
        category: TemplateCategory.certificate,
        orientation: PageOrientation.landscape,
        layoutData: plain.toJson(),
      ),
    );

    await pumpScreen(
      tester,
      repository: repository,
      localStore: InMemoryLocalTemplateStore(),
    );

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('قالب ثابت').last);
    await tester.pumpAndSettle();

    expect(controller.templateHasDynamicFields, isFalse);
    expect(controller.availableFields, isEmpty);
    expect(find.textContaining('بلا حقول ديناميكية'), findsWidgets);
  });

  testWidgets('قالب بلا حقل اسم: يظهر التنبيه وزر التحويل السريع يعمل',
      (WidgetTester tester) async {
    // قالب فيه حقل تاريخ فقط ونصّ ثابت يشبه اسم المتدرب — أصل الخلل.
    final TemplateDocument dateOnly = TemplateDocument(
      orientation: PageOrientation.landscape,
      elements: const <TemplateElement>[
        TextElement(
          id: 'name',
          box: ElementBox(x: 100, y: 260, width: 480, height: 70),
          text: 'محمد بن عبد الله الشمري',
          fontSize: 22,
        ),
        TextElement(
          id: 'date',
          box: ElementBox(x: 100, y: 120, width: 300, height: 40),
          text: 'بتاريخ {{التاريخ}}',
        ),
      ],
    );
    final FakeTemplateRepository repository = FakeTemplateRepository();
    repository.records.add(
      TemplateRecord(
        id: 'date-only-1',
        userId: 'user-1',
        title: 'قالب بلا اسم',
        category: TemplateCategory.certificate,
        orientation: PageOrientation.landscape,
        layoutData: dateOnly.toJson(),
      ),
    );

    await pumpScreen(
      tester,
      size: const Size(1400, 1600),
      repository: repository,
      localStore: InMemoryLocalTemplateStore(),
    );

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('قالب بلا اسم').last);
    await tester.pumpAndSettle();

    expect(controller.hasNameField, isFalse);

    // ملف عموداه الاسم والتاريخ.
    final Uint8List csv = Uint8List.fromList(
      utf8.encode('الاسم,التاريخ\nأحمد الشمري,1447/03/12\n'),
    );
    await controller.loadBytes(fileName: 'data.csv', bytes: csv);
    await tester.pumpAndSettle();

    // الحاجز: عمود الاسم لم يُربط بحقل التاريخ.
    expect(controller.mapping.fieldFor(0), isNull);
    expect(controller.mapping.fieldFor(1), 'التاريخ');
    expect(
      find.textContaining('لا يحتوي على حقل اسم ديناميكي'),
      findsWidgets,
    );

    // زر التحويل السريع يحوّل النص الثابت ويربط عمود الاسم فوراً.
    expect(find.textContaining('محمد بن عبد الله الشمري'), findsWidgets);
    await tester.tap(find.text('حوّله إلى حقل {{اسم_المتدرب}}'));
    await tester.pumpAndSettle();

    expect(controller.hasNameField, isTrue);
    expect(controller.mapping.fieldFor(0), 'اسم_المتدرب');

    // التعديل ثُبّت في القالب الأصلي على "الخادم" لا في الذاكرة فقط.
    expect(repository.updateCalls, greaterThanOrEqualTo(1));
    final TemplateDocument saved = repository.records.single.toDocument();
    expect(saved.fieldKeys, contains('اسم_المتدرب'));
    expect(
      saved.elements.whereType<TextElement>().map((TextElement e) => e.text),
      isNot(contains('محمد بن عبد الله الشمري')),
    );

    // زر «تراجع» في الإشعار يُعيد النص ويثبّت الاستعادة في القالب.
    expect(find.text('تراجع'), findsOneWidget);
    await tester.tap(find.text('تراجع'));
    await tester.pumpAndSettle();

    expect(controller.hasNameField, isFalse);
    expect(controller.mapping.fieldFor(0), isNull);
    final TemplateDocument afterUndo = repository.records.single.toDocument();
    expect(afterUndo.fieldKeys, isNot(contains('اسم_المتدرب')));
    expect(
      afterUndo.elements
          .whereType<TextElement>()
          .map((TextElement e) => e.text),
      contains('محمد بن عبد الله الشمري'),
    );
  });

  testWidgets('التعيين بالنقر يمسّ العنصر المحدَّد وحده ويثبّت التعديل',
      (WidgetTester tester) async {
    // قالب بعنصرين ثابتين: اسم تاريخ — لاختبار أن التعيين لا يمسّ غيره.
    const String nameText = 'محمد بن عبد الله الشمري';
    const String dateText = 'صدر بتاريخ ١٤٤٧/٠٣/١٢';
    final TemplateDocument document = TemplateDocument(
      orientation: PageOrientation.landscape,
      elements: const <TemplateElement>[
        TextElement(
          id: 'name',
          box: ElementBox(x: 100, y: 100, width: 480, height: 70),
          text: nameText,
          fontSize: 22,
        ),
        TextElement(
          id: 'date',
          box: ElementBox(x: 100, y: 200, width: 360, height: 40),
          text: dateText,
        ),
      ],
    );
    final FakeTemplateRepository repository = FakeTemplateRepository();
    repository.records.add(
      TemplateRecord(
        id: 'pick-1',
        userId: 'user-1',
        title: 'قالب النقر',
        category: TemplateCategory.certificate,
        orientation: PageOrientation.landscape,
        layoutData: document.toJson(),
      ),
    );

    await pumpScreen(
      tester,
      size: const Size(1400, 1400),
      repository: repository,
      localStore: InMemoryLocalTemplateStore(),
    );

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('قالب النقر').last);
    await tester.pumpAndSettle();

    // لوحة التعيين تعرض العناصر غير المربوطة قابلة للنقر.
    expect(find.textContaining(nameText), findsWidgets);
    await tester.tap(find.textContaining(nameText).first);
    await tester.pumpAndSettle();

    // منتقي الحقول يظهر مع تأكيد عدم المساس بغيره.
    expect(find.text('تعيين حقل ديناميكي لهذا العنصر'), findsOneWidget);
    await tester.tap(find.textContaining('اسم_المتدرب').last);
    await tester.pumpAndSettle();

    // العنصر المحدَّد صار حقلاً، والعنصر الآخر (التاريخ) لم يُمسّ.
    final TemplateDocument after = controller.document!;
    expect((after.elements[0] as TextElement).text, '{{اسم_المتدرب}}');
    expect((after.elements[1] as TextElement).text, dateText);
    expect(after.fieldKeys, <String>{'اسم_المتدرب'});

    // والتعديل ثُبّت في القالب المحفوظ.
    final TemplateDocument saved = repository.records.single.toDocument();
    expect(saved.fieldKeys, contains('اسم_المتدرب'));
    expect((saved.elements[1] as TextElement).text, dateText);
  });

  testWidgets('تبديل القالب إلى العقد يغيّر الحقول المتاحة',
      (WidgetTester tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('عقد'));
    await tester.pumpAndSettle();

    expect(controller.kind, BatchTemplateKind.contract);
    // القالب النموذجي المدمج يستخدم مفاتيح إنجليزية، والمُحقِّقات العربية
    // تُستخدم للمطابقة فقط ولا تُكتب في الحقول المتاحة.
    expect(
      controller.availableFields,
      containsAll(<String>['party_1', 'party_2']),
    );
    expect(controller.availableFields, isNot(contains('اسم_الطرف_الأول')));
  });

  testWidgets('محرّك الـ PDF يُبنى مرة واحدة عند أول توليد',
      (WidgetTester tester) async {
    // نُصفّر المخزون المؤقت كي تُحمّل الخطوط في النطاق الزمني الحقيقي للاختبار
    // بدل الاعتماد على مستقبل حُجز أثناء النطاق المزيّف لاختبار ودجة سابق.
    PdfFontSet.resetCache();
    final PdfGeneratorService? service =
        await tester.runAsync(() => PdfGeneratorService.create());
    expect(service!.fonts.loadedCount, greaterThan(0));
  });
}
