import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/constants/dynamic_fields.dart';
import 'package:joodcraft/core/gender/arabic_gender.dart';
import 'package:joodcraft/core/errors/app_exception.dart';
import 'package:joodcraft/core/models/template_document.dart';
import 'package:joodcraft/core/models/template_element.dart';
import 'package:joodcraft/core/services/batch_output_backend_io.dart';
import 'package:joodcraft/core/services/pdf_generator_service.dart';
import 'package:joodcraft/features/batch_processor/domain/bulk_generation.dart';
import 'package:joodcraft/features/batch_processor/domain/column_mapping.dart';
import 'package:joodcraft/features/batch_processor/domain/field_aliases.dart';
import 'package:joodcraft/features/batch_processor/domain/output_file_name.dart';
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

  group('محرّك الجنس لكل صف', () {
    /// قالب بحقل جنس شرطي وحقل جنس صريح — لاختبار الحلّ والحقن معاً.
    TemplateDocument genderDocument() => TemplateDocument.fromJson(
          <String, dynamic>{
            'schema_version': 1,
            'elements': <Map<String, dynamic>>[
              <String, dynamic>{
                'type': 'text',
                'x': 30,
                'y': 30,
                'w': 500,
                'h': 40,
                'text': 'قد {{الجنس: اجتاز | اجازت}} الاختبار',
                'size': 20,
              },
              <String, dynamic>{
                'type': 'text',
                'x': 30,
                'y': 90,
                'w': 500,
                'h': 40,
                'text': 'الجنس: {{الجنس}}',
                'size': 16,
              },
            ],
          },
        );

    const ColumnMapping nameOnly = ColumnMapping(<int, String>{
      0: 'اسم_المتدرب',
    });

    test('الجنس يُستنتج من الاسم لكل صف على حدة', () async {
      final BulkGenerationReport report = await service.run(
        document: genderDocument(),
        sheet: _sheet,
        mapping: _mapping,
      );

      expect(
        report.rows.map((BulkRowResult r) => r.gender).toList(),
        <Gender>[Gender.male, Gender.female, Gender.male],
      );
      expect(report.generatedCount, 3);
    });

    test('عمود الجنس الصريح يتقدّم على كشف الاسم', () async {
      const SheetData sheet = SheetData(
        headers: <String>['اسم المتدرب', 'الجنس'],
        rows: <List<String>>[
          <String>['أحمد الشمري', 'أنثى'],
          <String>['سارة العتيبي', 'ذكر'],
        ],
      );
      const ColumnMapping mapping = ColumnMapping(<int, String>{
        0: 'اسم_المتدرب',
        1: 'الجنس',
      });

      final BulkGenerationReport report = await service.run(
        document: genderDocument(),
        sheet: sheet,
        mapping: mapping,
      );

      expect(
        report.rows.map((BulkRowResult r) => r.gender).toList(),
        <Gender>[Gender.female, Gender.male],
      );
    });

    test('تصحيح المراجعة المسبقة يتقدّم على كل شيء', () async {
      final BulkGenerationReport report = await service.run(
        document: genderDocument(),
        sheet: _sheet,
        mapping: nameOnly,
        genderOverrides: const <int, Gender>{2: Gender.female},
      );

      expect(report.rows.first.gender, Gender.female);
      expect(report.rows[1].gender, Gender.female);
      expect(report.rows.last.gender, Gender.male);
    });

    test('الاسم المُصحَّح من جدول المراجعة يصل إلى الرسم والنتيجة', () async {
      final BulkGenerationReport base = await service.run(
        document: _document(),
        sheet: _sheet,
        mapping: nameOnly,
      );
      final BulkGenerationReport edited = await service.run(
        document: _document(),
        sheet: _sheet,
        mapping: nameOnly,
        nameOverrides: const <int, String>{3: 'منى'},
      );

      // الصف 3 كان «سارة العتيبي» ← صُحّح، والاسم الجديد وصل إلى النتيجة.
      expect(edited.rows[1].name, 'منى');
      expect(edited.rows[1].gender, Gender.female);
      // والقيمة الجديدة حلّت في الرسم فعلاً: حجم الملف يختلف.
      expect(edited.byteSize, isNot(base.byteSize));
    });

    test('إعادة كشف الجنس تتبع الاسم المُصحَّح', () async {
      final BulkGenerationReport report = await service.run(
        document: genderDocument(),
        sheet: _sheet,
        mapping: nameOnly,
        nameOverrides: const <int, String>{3: 'خالد القحطاني'},
      );

      // الصف 3 كان «سارة العتيبي» (أنثى) ← الاسم الجديد مذكّر.
      expect(report.rows[1].name, 'خالد القحطاني');
      expect(report.rows[1].gender, Gender.male);
    });

    test('تصحيح الجنس اليدوي يتقدّم على الاسم المُصحَّح', () async {
      final BulkGenerationReport report = await service.run(
        document: genderDocument(),
        sheet: _sheet,
        mapping: nameOnly,
        genderOverrides: const <int, Gender>{2: Gender.female},
        nameOverrides: const <int, String>{2: 'خالد القحطاني'},
      );

      expect(report.rows.first.name, 'خالد القحطاني');
      expect(
        report.rows.first.gender,
        Gender.female,
        reason: 'التصحيح اليدوي للجنس هو الحاكم',
      );
    });
  });

  group('اسم ملف التصدير', () {
    test('التنقية تحذف المحارف الممنوعة وتُضيف الامتداد', () {
      // كل المحارف الممنوعة على الأنظمة: \ / : * ? " < > |
      expect(
        OutputFileName.sanitize('تقرير/2026:نهائي*?"<>|'),
        'تقرير2026نهائي',
      );
      expect(OutputFileName.resolve('كشف'), 'كشف.pdf');
      expect(OutputFileName.resolve('أرشيف.zip'), 'أرشيف.zip');
      // إدخال فارغ أو مسافات فقط ← الاسم الاحتياطي.
      expect(OutputFileName.resolve(''), 'شهادات_المتدربين.pdf');
      expect(OutputFileName.resolve('   '), 'شهادات_المتدربين.pdf');
      // الافتراضي مشتقّ من عنوان القالب ومُنقّى أيضاً.
      expect(
        OutputFileName.defaultBaseName(templateTitle: 'قالب/خاص'),
        'قالبخاص',
      );
      expect(
        OutputFileName.defaultBaseName(templateTitle: '  '),
        OutputFileName.fallback,
      );
    });

    test('الاسم المخصّص يُنقّى ويُحفظ في تقرير التوليد بامتداده', () async {
      final BulkGenerationReport report = await service.run(
        document: _document(),
        sheet: _sheet,
        mapping: _mapping,
        fileName: 'كشف/المتدربين',
      );
      expect(report.fileName, 'كشفالمتدربين.pdf');
    });

    test('بلا اسم مخصّص يُستخدم الاسم الاحتياطي', () async {
      final BulkGenerationReport report = await service.run(
        document: _document(),
        sheet: _sheet,
        mapping: _mapping,
      );
      expect(report.fileName, 'شهادات_المتدربين.pdf');
    });

    test('امتداد المُستخدم المعروف (.zip) يُحترم كما هو', () async {
      final BulkGenerationReport report = await service.run(
        document: _document(),
        sheet: _sheet,
        mapping: _mapping,
        fileName: 'أرشيف.zip',
      );
      expect(report.fileName, 'أرشيف.zip');
    });

    test('اسم مجلد الوضع المنفصل: اسم التصدير بلا امتداد أو الاسم الاحتياطي', () {
      expect(OutputFileName.baseName('شهادات_دفعة_أغسطس.pdf'), 'شهادات_دفعة_أغسطس');
      expect(OutputFileName.baseName('دفعة_أغسطس'), 'دفعة_أغسطس');
      expect(OutputFileName.baseName('  '), OutputFileName.fallback);
      expect(OutputFileName.baseName(''), OutputFileName.fallback);
    });
  });

  group('البنية المنسّقة للحفظ على القرص', () {
    /// مجلد مؤقت يمثّل وجهة المستخدم المختارة — يُحذف بعد كل اختبار.
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('joodcraft_bulk_');
    });

    tearDown(() async {
      if (tempDir.existsSync()) await tempDir.delete(recursive: true);
    });

    /// آخر مكوّن في المسار — بلا اعتماد على فاصل المنصة.
    String baseNameOf(String path) => path.split(RegExp(r'[\\/]')).last;

    test('الوضع المنفصل: يُنشئ مجلداً فرعياً باسم التصدير ويحفظ الملفات داخله', () async {
      final List<String> progress = <String>[];
      final BulkGenerationReport report = await service.run(
        document: _document(),
        sheet: _sheet,
        mapping: _mapping,
        mode: BulkOutputMode.individual,
        outputDirectory: tempDir.path,
        output: createBatchOutputService(),
        fileName: 'شهادات_دفعة_أغسطس',
        onProgress: (int done, int total) => progress.add('$done/$total'),
      );

      // البنية: مجلد فرعي باسم التصدير (بلا امتداد) داخل المجلد المختار.
      expect(report.mode, BulkOutputMode.individual);
      expect(report.savedDirectory, isNotNull);
      expect(report.savedFilePath, isNull);
      expect(baseNameOf(report.savedDirectory!), 'شهادات_دفعة_أغسطس');
      expect(Directory(report.savedDirectory!).existsSync(), isTrue);

      // المجلد الأصل لم يزحمه شيء: مجلد واحد فقط ولا ملف فيه.
      expect(tempDir.listSync().whereType<Directory>(), hasLength(1));
      expect(tempDir.listSync().whereType<File>(), isEmpty);

      // ملف لكل شخص داخل المجلد الفرعي حصراً، بأسماء مقروءة وبالترتيب.
      expect(report.individualCount, 3);
      expect(
        report.individualPdfs.map((BulkIndividualPdf f) => f.fileName),
        <String>[
          'شهادة_أحمد_الشمري.pdf',
          'شهادة_سارة_العتيبي.pdf',
          'شهادة_خالد_القحطاني.pdf',
        ],
      );
      final List<File> savedFiles = Directory(report.savedDirectory!)
          .listSync()
          .whereType<File>()
          .toList();
      expect(savedFiles, hasLength(3));
      for (final File file in savedFiles) {
        expect(
          file.readAsBytesSync().sublist(0, 4),
          <int>[0x25, 0x50, 0x44, 0x46], // '%PDF'
          reason: 'يجب أن يكون كل ملف PDF حقيقياً: ${file.path}',
        );
      }

      // التقدّم يعبر المرحلتين حتى ١٠٠٪: المدمج (١..٣ من ٦) ثم الملفات (٤..٦).
      expect(progress.first, '1/6');
      expect(progress.last, '6/6');
    });

    test('الوضع المجمع: يُحفظ الملف مباشرة في المجلد المختار بلا مجلد فرعي', () async {
      final BulkGenerationReport report = await service.run(
        document: _document(),
        sheet: _sheet,
        mapping: _mapping,
        outputDirectory: tempDir.path,
        output: createBatchOutputService(),
        fileName: 'دفعة_سبتمبر',
      );

      expect(report.mode, BulkOutputMode.combined);
      expect(report.savedFilePath, isNotNull);
      expect(report.savedDirectory, isNull);
      expect(report.individualCount, 0);
      expect(baseNameOf(report.savedFilePath!), 'دفعة_سبتمبر.pdf');
      expect(report.savedFilePath!.startsWith(tempDir.path), isTrue);

      // الملف وحده في المجلد الأصل — لا مجلد فرعي ولا فوضى.
      expect(tempDir.listSync().whereType<File>(), hasLength(1));
      expect(tempDir.listSync().whereType<Directory>(), isEmpty);
    });

    test('تكرار الأسماء يُميَّز بلاحقة فلا يتراكب ملفان في المجلد الفرعي', () async {
      final BulkGenerationReport report = await service.run(
        document: _document(),
        sheet: _sheet,
        mapping: _mapping,
        mode: BulkOutputMode.individual,
        outputDirectory: tempDir.path,
        output: createBatchOutputService(),
        // صفّان بنفس الاسم بعد التصحيح اليدوي (رقم الصف أسلوب Excel:
        // صف العناوين = 1، فالصف الثاني للبيانات = 3).
        nameOverrides: <int, String>{3: 'أحمد الشمري'},
      );

      final List<String> names = report.individualPdfs
          .map((BulkIndividualPdf f) => f.fileName)
          .toList();
      expect(names, <String>[
        'شهادة_أحمد_الشمري.pdf',
        'شهادة_أحمد_الشمري_2.pdf',
        'شهادة_خالد_القحطاني.pdf',
      ]);

      final List<String> onDisk = Directory(report.savedDirectory!)
          .listSync()
          .whereType<File>()
          .map((File f) => baseNameOf(f.path))
          .toList();
      expect(onDisk, unorderedEquals(names));
    });
  });
}
