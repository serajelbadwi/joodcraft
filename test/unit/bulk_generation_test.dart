import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/constants/dynamic_fields.dart';
import 'package:joodcraft/core/errors/app_exception.dart';
import 'package:joodcraft/core/models/template_document.dart';
import 'package:joodcraft/core/models/template_element.dart';
import 'package:joodcraft/core/services/pdf_generator_service.dart';
import 'package:joodcraft/features/batch_processor/domain/bulk_generation.dart';
import 'package:joodcraft/features/batch_processor/domain/column_mapping.dart';
import 'package:joodcraft/features/batch_processor/domain/field_aliases.dart';
import 'package:joodcraft/features/batch_processor/domain/sheet_data.dart';

const SheetData _sheet = SheetData(
  headers: <String>['اسم المتدرب', 'رقم الشهادة'],
  rows: <List<String>>[
    <String>['أحمد الشمري', 'JC-0001'],
    <String>['سارة العتيبي', ''],
    <String>['خالد القحطاني', 'JC-0003'],
  ],
);

const ColumnMapping _mapping = ColumnMapping(<int, String>{
  0: 'اسم_المتدرب',
  1: 'رقم_الشهادة',
});

/// قالب مصغّر يستخدم نفس مفاتيح الحقول الديناميكية — فيظهر أثر السياسة في
/// مخرجات الـ PDF مباشرة.
TemplateDocument _document() => TemplateDocument.fromJson(<String, dynamic>{
      'schema_version': 1,
      'orientation': 'portrait',
      'elements': <Map<String, dynamic>>[
        <String, dynamic>{
          'type': 'text',
          'x': 30,
          'y': 30,
          'w': 500,
          'h': 40,
          'text': 'المتدرب: {{اسم_المتدرب}}',
          'size': 20,
        },
        <String, dynamic>{
          'type': 'text',
          'x': 30,
          'y': 90,
          'w': 500,
          'h': 40,
          'text': 'الشهادة: {{رقم_الشهادة}}',
          'size': 16,
        },
      ],
    });

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PdfGeneratorService generator;
  late BulkGenerationService service;

  setUpAll(() async {
    generator = await PdfGeneratorService.create(compress: false);
    service = BulkGenerationService(generator: generator);
  });

  test('يولّد صفحة لكل صف مع الإبلاغ عن التقدّم', () async {
    final List<int> progress = <int>[];
    final BulkGenerationReport report = await service.run(
      document: _document(),
      sheet: _sheet,
      mapping: _mapping,
      onProgress: (int done, int total) => progress.add(done),
    );

    expect(report.totalRows, 3);
    expect(report.generatedCount, 3);
    expect(report.pageCount, 3);
    expect(report.hasOutput, isTrue);
    expect(progress, <int>[1, 2, 3]);
    expect(report.skippedCount, 0);
  });

  test('سجل بلا رقم شهادة: «تخطَّ الصف» يُسقطه من الإخراج ويذكر السبب', () async {
    final BulkGenerationReport report = await service.run(
      document: _document(),
      sheet: _sheet,
      mapping: _mapping,
      policy: MissingCellPolicy.skipRow,
    );

    expect(report.generatedCount, 2);
    expect(report.pageCount, 2);
    expect(report.skippedCount, 1);

    final BulkRowResult skipped = report.skipped.single;
    expect(skipped.rowNumber, 3);
    expect(skipped.missingFields, <String>['رقم_الشهادة']);
    expect(skipped.skipReasonAr, contains('رقم_الشهادة'));
    expect(report.incompleteRowCount, 1);
    expect(report.warnings.join(' '), contains('تُخطّي'));
  });

  test('«اتركها فارغة» و«استخدم القيمة التجريبية» يختلفان فعلاً في المخرجات', () async {
    final BulkGenerationReport sample = await service.run(
      document: _document(),
      sheet: _sheet,
      mapping: _mapping,
      policy: MissingCellPolicy.useSample,
    );
    final BulkGenerationReport empty = await service.run(
      document: _document(),
      sheet: _sheet,
      mapping: _mapping,
      policy: MissingCellPolicy.leaveEmpty,
    );

    expect(sample.generatedCount, 3);
    expect(empty.generatedCount, 3);
    // القيمة التجريبية أطول من الفراغ ⇒ حجم الملف يختلف حتماً.
    expect(
      sample.byteSize,
      isNot(empty.byteSize),
      reason: 'يجب أن تظهر القيمة التجريبية في الملف',
    );
  });

  test('ينبّه على الحقول التي لا تملك قيمة تجريبية', () async {
    const SheetData sheet = SheetData(
      headers: <String>['حقل مخصص'],
      rows: <List<String>>[
        <String>[''],
      ],
    );
    final BulkGenerationReport report = await service.run(
      document: _document(),
      sheet: sheet,
      mapping: const ColumnMapping(<int, String>{0: 'مفتاح_غير_معروف'}),
    );

    expect(report.generatedCount, 1);
    expect(report.warnings.join(' '), contains('بلا قيمة تجريبية'));
  });

  test('يرفض التوليد بلا ربط أو بربط غامض أو بملف بلا بيانات', () async {
    await expectLater(
      service.run(
        document: _document(),
        sheet: _sheet,
        mapping: ColumnMapping.empty,
      ),
      throwsA(isA<AppException>()),
    );

    await expectLater(
      service.run(
        document: _document(),
        sheet: _sheet,
        mapping: const ColumnMapping(<int, String>{
          0: 'اسم_المتدرب',
          1: 'اسم_المتدرب',
        }),
      ),
      throwsA(isA<AppException>()),
    );

    await expectLater(
      service.run(
        document: _document(),
        sheet: SheetData.empty,
        mapping: _mapping,
      ),
      throwsA(isA<AppException>()),
    );
  });

  test('ينقل ملاحظات الاستيراد وتحذيرات الـ PDF إلى التقرير', () async {
    final SheetData sheet = SheetData.fromMatrix(
      <List<String>>[
        <String>['اسم المتدرب'],
        <String>['أحمد'],
        <String>[''],
        <String>['سارة'],
      ],
      sourceName: 'students.csv',
    );

    final BulkGenerationReport report = await service.run(
      document: _document(),
      sheet: sheet,
      mapping: const ColumnMapping(<int, String>{0: 'اسم_المتدرب'}),
    );

    expect(sheet.notes, isNotEmpty);
    expect(report.warnings, containsAll(sheet.notes));
  });

  test('قالب مستخدم بمفاتيح عربية: عنوان مرادف في الملف يُستبدل فعلاً', () async {
    // قالب صمّمه المستخدم في المحرّر: مفاتيح عربية داخل `{{...}}`.
    final TemplateDocument custom =
        TemplateDocument.fromJson(<String, dynamic>{
      'schema_version': 1,
      'orientation': 'portrait',
      'elements': <Map<String, dynamic>>[
        <String, dynamic>{
          'type': 'text',
          'x': 30,
          'y': 30,
          'w': 500,
          'h': 40,
          'text': 'المتدرب: {{اسم_المتدرب}}',
          'size': 20,
        },
      ],
    });

    // ملف Excel بعنوان مرادف («اسم الطالب») لا يطابق المفتاح حرفياً.
    const SheetData sheet = SheetData(
      headers: <String>['اسم الطالب'],
      rows: <List<String>>[
        <String>['أحمد الشمري'],
        <String>['سارة العتيبي'],
      ],
    );

    final ColumnMapping mapping = ColumnMapping.autoDetect(
      columns: <int>[0],
      headers: sheet.headers,
      fieldKeys: custom.fieldKeys.toList(growable: false),
      aliases: FieldAliases.byToken,
    );
    // الربط يكتب مفتاح القالب نفسه، فيستبدل resolveFields القيمة فعلاً.
    expect(mapping.fieldFor(0), 'اسم_المتدرب');
    expect(
      custom.resolveFields(
        (custom.elements.single as TextElement).text,
        mapping.apply(sheet.rowAt(0)),
      ),
      'المتدرب: أحمد الشمري',
    );

    final BulkGenerationReport report = await service.run(
      document: custom,
      sheet: sheet,
      mapping: mapping,
    );
    expect(report.generatedCount, 2);
    expect(report.pageCount, 2);
    expect(report.hasOutput, isTrue);
  });

  test('الربط التلقائي يعمل من العناوين حتى التوليد الكامل', () async {
    final ColumnMapping mapping = ColumnMapping.autoDetect(
      columns: <int>[0, 1],
      headers: _sheet.headers,
      fieldKeys:
          DynamicFields.certificate.map((DynamicField f) => f.key).toList(),
    );
    expect(mapping.mappedCount, 2);

    final BulkGenerationReport report = await service.run(
      document: _document(),
      sheet: _sheet,
      mapping: mapping,
      policy: MissingCellPolicy.skipRow,
    );
    expect(report.generatedCount, 2);
  });
}
