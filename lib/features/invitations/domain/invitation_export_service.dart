import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:printing/printing.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/dynamic_fields.dart';
import '../../../../core/models/template_document.dart';
import '../../../../core/pdf/pdf_export_type.dart';
import '../../../../core/services/pdf_generator_service.dart';
import 'invitation_name_file.dart';

/// صيغة المخرجات المطلوبة.
enum InvitationExportFormat {
  png('png', 'PNG (للسوشيال ميديا)', 'invExportFormatPNG'),
  pdf('pdf', 'PDF (للطباعة)', 'invExportFormatPDF'),
  both('both', 'PNG + PDF', 'invExportFormatBoth');

  const InvitationExportFormat(this.jsonValue, this.labelAr, this.labelKey);

  final String jsonValue;
  final String labelAr;
  final String labelKey;

  bool get wantsPng => this == InvitationExportFormat.png || this == InvitationExportFormat.both;
  bool get wantsPdf => this == InvitationExportFormat.pdf || this == InvitationExportFormat.both;

  static InvitationExportFormat fromJson(String? value) {
    final String needle = (value ?? '').trim().toLowerCase();
    for (final InvitationExportFormat format in values) {
      if (format.jsonValue == needle) return format;
    }
    return InvitationExportFormat.png;
  }
}

/// محرّك رسم ملف الـ PDF.
///
/// يُستعمل في مسار الدعوات فقط: ‏[images] نقطةٌ تُطابق المحرر بصرياً 100%
/// (وهو الافتراضي منذ كانت الصيغة الوحيدة)، و[vector] أوامر مسار فتخرج
/// الحروف نصّاً حقيقياً قابلاً للنسخ والبحث بحجم أصغر.
///
/// سُجِّلت التسميات عبر مفاتيح l10n (لا نصّ صلب) تبعاً لنمط [InvitationExportFormat]
/// نفسه، فتُترجم مع بقية الواجهة.
enum InvitationPdfEngine {
  images('images', 'invPdfEngineImages'),
  vector('vector', 'invPdfEngineVector');

  const InvitationPdfEngine(this.jsonValue, this.labelKey);

  final String jsonValue;
  final String labelKey;

  /// المحرّك المقابل في طبقة الخدمة.
  PdfExportType get exportType => switch (this) {
        InvitationPdfEngine.images => PdfExportType.images,
        InvitationPdfEngine.vector => PdfExportType.vector,
      };

  static InvitationPdfEngine fromJson(String? value) {
    final String needle = (value ?? '').trim().toLowerCase();
    for (final InvitationPdfEngine engine in values) {
      if (engine.jsonValue == needle) return engine;
    }
    return InvitationPdfEngine.images;
  }
}

/// صيغة ملف الإخراج الفردي.
enum InvitationFileFormat { png, pdf }

/// ملف فردي واحد جاهز للحفظ.
class InvitationOutputFile {
  const InvitationOutputFile({
    required this.fileName,
    required this.name,
    required this.bytes,
    required this.format,
  });

  final String fileName;
  final String name;
  final Uint8List bytes;
  final InvitationFileFormat format;

  int get byteSize => bytes.lengthInBytes;
}

/// نتيجة التشغيل: كل الملفات + ZIP + فهرس CSV + إحصاءات.
class InvitationExportReport {
  const InvitationExportReport({
    required this.files,
    required this.elapsed,
    required this.duplicateCount,
    required this.emptyCount,
    required this.failedCount,
    required this.cancelled,
    this.zipBytes,
    this.csvBytes,
    this.warnings = const <String>[],
  });

  final List<InvitationOutputFile> files;
  final Uint8List? zipBytes;
  final Uint8List? csvBytes;
  final Duration elapsed;
  final int duplicateCount;
  final int emptyCount;
  final int failedCount;
  final bool cancelled;
  final List<String> warnings;

  int get fileCount => files.length;

  int get pngCount =>
      files.where((InvitationOutputFile f) => f.format == InvitationFileFormat.png).length;

  int get pdfCount =>
      files.where((InvitationOutputFile f) => f.format == InvitationFileFormat.pdf).length;

  int get byteSize =>
      files.fold<int>(0, (int sum, InvitationOutputFile f) => sum + f.byteSize);

  bool get hasZip => zipBytes != null;

  bool get hasCsv => csvBytes != null;
}

/// يحوّل صفحة PDF إلى صورة PNG (حقن للاختبارات؛ الافتراضي عبر `printing`).
typedef InvitationPdfRasterizer = Future<Uint8List> Function(
  Uint8List pdfBytes,
  int dpi,
);

/// المحرّك: ملف واحد لكل اسم — PDF و/أو PNG — بأسماء نظيفة، مع ZIP وفهرس CSV.
///
/// يبني كل نسخة عبر [PdfGeneratorService] نفسه (نفس محرّك التوليد الجماعي)
/// فيبقى المخرج متطابقاً مع معاينة المحرّر بلا أي تكرار لمنطق الرسم.
class InvitationExportService {
  InvitationExportService({
    required PdfGeneratorService generator,
    InvitationPdfRasterizer? rasterizer,
  })  : _generator = generator,
        _rasterizer = rasterizer ?? _rasterizeWithPrinting;

  final PdfGeneratorService _generator;
  final InvitationPdfRasterizer _rasterizer;

  /// دقّة التحويل: مساحة التصميم بالبكسل للرقمي (96)، ودقّة الطباعة للمطبوعة.
  static int rasterDpi(TemplateDocument document) {
    final CustomPageSize? custom = document.customPageSize;
    final bool digital = custom != null && custom.unit == MeasurementUnit.px;
    return (digital ? TemplateDocument.designDpi : document.dpi).round();
  }

  /// يولّد ملفاً لكل صف — كل ملف باسم صاحبه.
  Future<InvitationExportReport> run({
    required TemplateDocument document,
    required List<InvitationRowPlan> plans,
    required InvitationExportFormat format,
    required int emptyCount,
    bool makeZip = false,
    bool makeCsv = false,
    InvitationPdfEngine engine = InvitationPdfEngine.images,
    void Function(int done, int total)? onProgress,
    Future<void> Function()? waitWhilePaused,
    bool Function()? isCancelled,
  }) async {
    final Stopwatch stopwatch = Stopwatch()..start();
    final List<InvitationOutputFile> files = <InvitationOutputFile>[];
    final List<String> warnings = <String>[];
    final int dpi = rasterDpi(document);
    int duplicates = 0;
    int failed = 0;
    bool cancelled = false;

    for (int i = 0; i < plans.length; i++) {
      final InvitationRowPlan plan = plans[i];
      if (isCancelled != null && isCancelled()) {
        cancelled = true;
        break;
      }
      if (waitWhilePaused != null) await waitWhilePaused();
      if (plan.isDuplicate) duplicates++;

      try {
        final PdfGenerationReport report = await _generator.generate(
          document: document,
          data: <String, String>{DynamicFields.nameKey: plan.name},
          type: engine.exportType,
        );

        if (format.wantsPdf) {
          files.add(InvitationOutputFile(
            fileName: '${plan.fileNameBase}.pdf',
            name: plan.name,
            bytes: report.bytes,
            format: InvitationFileFormat.pdf,
          ));
        }
        if (format.wantsPng) {
          final Uint8List png = await _rasterizer(report.bytes, dpi);
          files.add(InvitationOutputFile(
            fileName: '${plan.fileNameBase}.png',
            name: plan.name,
            bytes: png,
            format: InvitationFileFormat.png,
          ));
        }
      } catch (error) {
        failed++;
        warnings.add('${plan.name}: $error');
      }
      onProgress?.call(i + 1, plans.length);
    }

    Uint8List? zipBytes;
    if (makeZip && files.isNotEmpty) {
      zipBytes = _zipFiles(files);
    }
    Uint8List? csvBytes;
    if (makeCsv && files.isNotEmpty) {
      csvBytes = _csvIndex(files);
    }

    stopwatch.stop();
    return InvitationExportReport(
      files: files,
      zipBytes: zipBytes,
      csvBytes: csvBytes,
      elapsed: stopwatch.elapsed,
      duplicateCount: duplicates,
      emptyCount: emptyCount,
      failedCount: failed,
      cancelled: cancelled,
      warnings: warnings,
    );
  }

  /// أرشيف ZIP يحوي كل الملفات في مجلد واحد.
  static Uint8List _zipFiles(List<InvitationOutputFile> files) {
    final Archive archive = Archive();
    for (final InvitationOutputFile file in files) {
      archive.addFile(ArchiveFile(
        'invitations/${file.fileName}',
        file.bytes.length,
        file.bytes,
      ));
    }
    final List<int>? encoded = ZipEncoder().encode(archive);
    if (encoded == null) {
      throw StateError('فشل ضغط الملفات في الأرشيف');
    }
    return Uint8List.fromList(encoded);
  }

  /// فهرس CSV: اسم الملف ↔ الاسم الكامل (بـBOM ليفتحه Excel بالعربية).
  static Uint8List _csvIndex(List<InvitationOutputFile> files) {
    final StringBuffer buffer = StringBuffer('file_name,name\n');
    for (final InvitationOutputFile file in files) {
      buffer.writeln('${_csvCell(file.fileName)},${_csvCell(file.name)}');
    }
    return Uint8List.fromList(utf8.encode('\uFEFF$buffer'));
  }

  static String _csvCell(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}

/// التحويل الافتراضي عبر `Printing.raster` (يعمل على سطح المكتب والويب).
Future<Uint8List> _rasterizeWithPrinting(Uint8List pdfBytes, int dpi) async {
  final List<PdfRaster> pages =
      await Printing.raster(pdfBytes, pages: <int>[0], dpi: dpi.toDouble())
          .toList();
  if (pages.isEmpty) {
    throw StateError('لم يُنتج التحويل أي صفحة');
  }
  return pages.first.toPng();
}
