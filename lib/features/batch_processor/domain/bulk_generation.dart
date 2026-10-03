import 'dart:typed_data';

import '../../../core/constants/dynamic_fields.dart';
import '../../../core/errors/app_error_code.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/models/template_document.dart';
import '../../../core/services/pdf_generator_service.dart';
import 'column_mapping.dart';
import 'sheet_data.dart';

/// سياسة التعامل مع خلية فارغة أو بيانات صف غير مكتملة.
enum MissingCellPolicy {
  /// تُكتب القيمة التجريبية للحقل من مكتبة الحقول الديناميكية (الافتراضي).
  useSample(
    'use_sample',
    'استخدم القيمة التجريبية للحقل',
    'مناسب للاختبار: أي خلية فارغة تُستبدل بقيمة نموذجية بدل الفراغ.',
  ),

  /// تُترك فارغة تماماً — بلا رجوع للقيمة التجريبية في القالب.
  leaveEmpty(
    'leave_empty',
    'اتركها فارغة',
    'تخرج الشهادة بخانة بيضاء في مكان البيانات الناقصة.',
  ),

  /// يُتخطّى الصف كاملاً ويُذكر السبب في التقرير.
  skipRow(
    'skip_row',
    'تخطَّ الصف الناقص',
    'الأكثر أماناً للطباعة الرسمية: لا تُصدر شهادة ببيانات ناقصة إطلاقاً.',
  );

  const MissingCellPolicy(this.jsonValue, this.labelAr, this.descriptionAr);

  final String jsonValue;
  final String labelAr;
  final String descriptionAr;

  static MissingCellPolicy fromJson(String? value) {
    final String needle = value?.trim().toLowerCase() ?? '';
    return values.firstWhere(
      (MissingCellPolicy p) => p.jsonValue == needle,
      orElse: () => useSample,
    );
  }
}

/// حالة صف واحد بعد المعالجة.
enum BulkRowStatus { generated, skipped }

/// نتيجة معالجة صف واحد.
class BulkRowResult {
  const BulkRowResult({
    required this.rowNumber,
    required this.status,
    required this.missingFields,
    this.skipReasonAr,
  });

  /// رقم الصف كما يراه المستخدم في Excel.
  final int rowNumber;

  final BulkRowStatus status;

  /// مفاتيح الحقول التي جاءت قيمتها فارغة في هذا الصف.
  final List<String> missingFields;

  final String? skipReasonAr;

  bool get isGenerated => status == BulkRowStatus.generated;

  @override
  String toString() =>
      'BulkRowResult($rowNumber, ${status.name}, ${missingFields.length} ناقص)';
}

/// تقرير التوليد الجماعي — كل ما تحتاجه الواجهة لعرض نتيجة مفهومة.
class BulkGenerationReport {
  const BulkGenerationReport({
    required this.combinedPdf,
    required this.rows,
    required this.warnings,
    required this.elapsed,
    required this.totalRows,
  });

  /// ملف PDF واحد فيه صفحة لكل صف مُصدر (`null` إن لم يُصدر أي صف).
  final Uint8List? combinedPdf;

  final List<BulkRowResult> rows;

  /// تحذيرات عامة (صور مفقودة، صيغ غير محسوبة، صفوف بلا قيم تجريبية…).
  final List<String> warnings;

  final Duration elapsed;

  /// عدد صفوف البيانات في الملف قبل أي تصفية.
  final int totalRows;

  List<BulkRowResult> get generated =>
      rows.where((BulkRowResult r) => r.isGenerated).toList(growable: false);

  List<BulkRowResult> get skipped =>
      rows.where((BulkRowResult r) => !r.isGenerated).toList(growable: false);

  int get generatedCount => generated.length;
  int get skippedCount => skipped.length;

  /// عدد الصفحات = عدد الصفوف المُصدرة (صفحة لكل سجل).
  int get pageCount => generatedCount;

  bool get hasOutput => combinedPdf != null && combinedPdf!.isNotEmpty;

  int get byteSize => combinedPdf?.lengthInBytes ?? 0;

  double get successRate =>
      totalRows == 0 ? 0 : generatedCount / totalRows;

  /// صفوف بها بيانات ناقصة (بغضّ النظر عن كونها أُصدرت أو تُخطّيت).
  int get incompleteRowCount =>
      rows.where((BulkRowResult r) => r.missingFields.isNotEmpty).length;
}

/// محرّك التوليد الجماعي: بيانات ورقة + ربط أعمدة ← ملف PDF لكل السجلات.
///
/// فصلناه عن `PdfGeneratorService` لأن مسؤوليته مختلفة تماماً: الـ service
/// يرسم، وهذا **يقرّر ماذا يُرسم ولمن** — وهو منطق العمل الذي تستحق قواعده
/// (الخلايا الفارغة، تخطي الصفوف، التقارير) اختبارات مستقلة.
class BulkGenerationService {
  const BulkGenerationService({required this.generator});

  final PdfGeneratorService generator;

  /// القيمة التجريبية لحقل: ما مرّره المستدعي (بيانات القالب النموذجية) أولاً،
  /// ثم مكتبة الحقول الديناميكية، وإلا الفراغ.
  static String _sampleFor(String field, Map<String, String> samples) {
    final String? explicit = samples[field];
    if (explicit != null && explicit.trim().isNotEmpty) return explicit;
    return DynamicFields.byKey(field)?.sample ?? '';
  }

  /// حالة الرسم النهائية → تقرير كامل.
  Future<BulkGenerationReport> run({
    required TemplateDocument document,
    required SheetData sheet,
    required ColumnMapping mapping,
    MissingCellPolicy policy = MissingCellPolicy.useSample,
    Map<String, String> samples = const <String, String>{},
    PdfDocumentMetadata? metadata,
    void Function(int done, int total)? onProgress,
  }) async {
    if (sheet.isEmpty) {
      throw const AppException(
        AppErrorCode.excelImport,
        message: 'لا توجد بيانات في الملف. اختر ملفاً يحتوي صف عناوين وصفوفاً.',
      );
    }
    if (mapping.isEmpty) {
      throw const AppException(
        AppErrorCode.dataMapping,
        message: 'اربط عموداً واحداً على الأقل بحقل من حقول القالب قبل التوليد.',
      );
    }
    if (mapping.hasDuplicates) {
      throw AppException(
        AppErrorCode.dataMapping,
        message: 'الحقل «${mapping.duplicateFields.first}» مرتبط بأكثر من عمود. '
            'اجعل كل حقل مرتبطاً بعمود واحد.',
      );
    }

    final Stopwatch stopwatch = Stopwatch()..start();
    final List<String> warnings = <String>[...sheet.notes];

    final List<BulkRowResult> results = <BulkRowResult>[];
    final List<Map<String, String>> effectiveRows = <Map<String, String>>[];
    final Set<String> fieldsWithoutSample = <String>{};

    for (final SheetRow row in sheet.sheetRows) {
      final Map<String, String> raw = mapping.apply(row);
      final List<String> missing = <String>[
        for (final MapEntry<String, String> entry in raw.entries)
          if (entry.value.isEmpty) entry.key,
      ];

      if (missing.isNotEmpty && policy == MissingCellPolicy.skipRow) {
        results.add(
          BulkRowResult(
            rowNumber: row.displayNumber,
            status: BulkRowStatus.skipped,
            missingFields: missing,
            skipReasonAr: 'بيانات ناقصة: ${missing.join('، ')}',
          ),
        );
        continue;
      }

      if (missing.isNotEmpty && policy == MissingCellPolicy.useSample) {
        for (final String field in missing) {
          if (_sampleFor(field, samples).trim().isEmpty) {
            fieldsWithoutSample.add(field);
          }
        }
      }

      final Map<String, String> effective = <String, String>{};
      for (final MapEntry<String, String> entry in raw.entries) {
        if (entry.value.isNotEmpty) {
          effective[entry.key] = entry.value;
          continue;
        }
        effective[entry.key] = policy == MissingCellPolicy.useSample
            ? _sampleFor(entry.key, samples)
            : '';
      }

      effectiveRows.add(effective);
      results.add(
        BulkRowResult(
          rowNumber: row.displayNumber,
          status: BulkRowStatus.generated,
          missingFields: missing,
        ),
      );
    }

    if (fieldsWithoutSample.isNotEmpty) {
      warnings.add(
        'حقول بلا قيمة تجريبية ستظهر فارغة: ${fieldsWithoutSample.join('، ')}. '
        'أضف لها قيمة تجريبية في القالب أو اختر سياسة أخرى.',
      );
    }
    final int skipped = results.length - effectiveRows.length;
    if (skipped > 0) {
      warnings.add('تُخطّي $skipped صف/صفوف لبيانات ناقصة.');
    }

    Uint8List? combinedPdf;
    if (effectiveRows.isNotEmpty) {
      final PdfGenerationReport pdfReport = await generator.generateBatch(
        document: document,
        rows: effectiveRows,
        metadata: metadata,
        onProgress: onProgress,
      );
      combinedPdf = pdfReport.bytes;
      warnings.addAll(pdfReport.warnings);
    }

    stopwatch.stop();
    return BulkGenerationReport(
      combinedPdf: combinedPdf,
      rows: results,
      warnings: warnings,
      elapsed: stopwatch.elapsed,
      totalRows: sheet.rowCount,
    );
  }
}
