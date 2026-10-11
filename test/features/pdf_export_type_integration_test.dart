import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/models/template_document.dart';
import 'package:joodcraft/core/pdf/pdf_export_type.dart';
import 'package:joodcraft/core/services/pdf_generator_service.dart';
import 'package:joodcraft/features/batch_processor/domain/bulk_generation.dart';
import 'package:joodcraft/features/batch_processor/domain/column_mapping.dart';
import 'package:joodcraft/features/batch_processor/domain/sheet_data.dart';

/// تحقّق من أنّ **كل نقطة دخول تصدّر** تمرّر [PdfExportType] فعلياً إلى محرّك
/// الرسم، لا أن تُهمَل وتُصدَّر نقطي دائماً (سبب المشكلة الأولى في
/// report/pdf_export_diagnosis.md).
///
/// التمييز بين المحرّكين معتمد على بنية الملف نفسه: النقطي صفحةٌ صورة كاملة
/// بلا موارد خطوط مضمّنة، والمتجهي أوامر نصّ مع خط مضمّن (`/Font`). فلو خرج
/// المتجهي بنقاطيّة لظهر `/Font` غائباً، وهو فشل صريح لا شكّ بصري.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  TemplateDocument document() => TemplateDocument.fromJson(<String, dynamic>{
        'schema_version': 1,
        'orientation': 'portrait',
        'elements': <Map<String, dynamic>>[
          <String, dynamic>{
            'type': 'text',
            'x': 30,
            'y': 30,
            'w': 500,
            'h': 40,
            'text': 'شهادة إتمام',
            'size': 20,
          },
          <String, dynamic>{
            'type': 'text',
            'x': 30,
            'y': 90,
            'w': 500,
            'h': 40,
            'text': 'المتدرب: {{اسم_المتدرب}}',
            'size': 16,
          },
        ],
      });

  const SheetData sheet = SheetData(
    headers: <String>['اسم المتدرب'],
    rows: <List<String>>[
      <String>['أحمد الشمري'],
      <String>['سارة العتيبي'],
    ],
  );

  const ColumnMapping mapping = ColumnMapping(<int, String>{0: 'اسم_المتدرب'});

  /// هل تحوي البايتات أثراً لخط مضمّن؟ الافتراضي `false` في المسار النقطي.
  bool embedsFonts(List<int> bytes) {
    final String ascii = String.fromCharCodes(
      bytes.map((int b) => (b >= 32 && b < 127) ? b : 32),
    );
    return ascii.contains('/Font') || ascii.contains('/FontFile');
  }

  group('المحرّر — service.generate', () {
    late PdfGeneratorService generator;

    setUpAll(() async {
      generator = await PdfGeneratorService.create(compress: false);
    });

    test('النوع المُمرَّر «متجهي» يخرج بخط مضمّن (نصّ حقيقي)', () async {
      final PdfGenerationReport report = await generator.generate(
        document: document(),
        type: PdfExportType.vector,
      );

      expect(embedsFonts(report.bytes), isTrue);
    });

    test('النوع المُمرَّر «صور» يخرج بلا خط مضمّن (صفحة صورة)', () async {
      final PdfGenerationReport report = await generator.generate(
        document: document(),
        type: PdfExportType.images,
      );

      expect(embedsFonts(report.bytes), isFalse);
    });

    test('الافتراضي هو «صور» — توثيق للسلوك الأصلي', () async {
      final PdfGenerationReport report = await generator.generate(
        document: document(),
      );

      expect(embedsFonts(report.bytes), isFalse);
    });
  });

  group('التوليد الجماعي — BulkGenerationService.run', () {
    late PdfGeneratorService generator;
    late BulkGenerationService service;

    setUpAll(() async {
      generator = await PdfGeneratorService.create(compress: false);
      service = BulkGenerationService(generator: generator);
    });

    test('exportType متجهي يصل إلى محرّك الرسم في المسار المجمّع', () async {
      final BulkGenerationReport report = await service.run(
        document: document(),
        sheet: sheet,
        mapping: mapping,
        exportType: PdfExportType.vector,
      );

      expect(report.generatedCount, 2);
      expect(embedsFonts(report.combinedPdf!), isTrue);
    });

    test('exportType نقطي يصل إلى محرّك الرسم في المسار المجمّع', () async {
      final BulkGenerationReport report = await service.run(
        document: document(),
        sheet: sheet,
        mapping: mapping,
        exportType: PdfExportType.images,
      );

      expect(report.generatedCount, 2);
      expect(embedsFonts(report.combinedPdf!), isFalse);
    });

    test('الافتراضي في التوليد الجماعي هو «صور» — توثيق للسلوك الأصلي', () async {
      final BulkGenerationReport report = await service.run(
        document: document(),
        sheet: sheet,
        mapping: mapping,
      );

      expect(embedsFonts(report.combinedPdf!), isFalse);
    });
  });
}
