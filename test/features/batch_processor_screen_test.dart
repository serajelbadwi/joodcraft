import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/constants/app_assets.dart';
import 'package:joodcraft/core/models/template_document.dart';
import 'package:joodcraft/core/pdf/pdf_font_catalog.dart';
import 'package:joodcraft/core/services/pdf_generator_service.dart';
import 'package:joodcraft/core/theme/app_theme.dart';
import 'package:joodcraft/features/batch_processor/domain/bulk_generation.dart';
import 'package:joodcraft/features/batch_processor/presentation/providers/batch_processor_controller.dart';
import 'package:joodcraft/features/batch_processor/presentation/screens/batch_processor_screen.dart';

/// ملف CSV تجريبي فيه صف ناقص عمداً.
final Uint8List _csv = Uint8List.fromList(
  utf8.encode(
    'اسم المتدرب,رقم الشهادة,التاريخ\n'
    'أحمد الشمري,JC-0001,1447/03/12\n'
    'سارة العتيبي,,1447/03/13\n'
    'خالد القحطاني,JC-0003,1447/03/14\n',
  ),
);

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
          child: Scaffold(body: BatchProcessorScreen(controller: controller)),
        ),
      ),
    );
    await tester.pumpAndSettle();
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
    expect(find.text('المعاينة تظهر هنا'), findsOneWidget);
    expect(find.text('لم يُختَر ملف بعد — الصيغ المدعومة: xlsx, csv, tsv'),
        findsOneWidget);

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
