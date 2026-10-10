import 'dart:typed_data';

import '../../../core/constants/dynamic_fields.dart';
import '../../../core/errors/app_error_code.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/gender/arabic_gender.dart';
import '../../../core/models/template_document.dart';
import '../../../core/services/batch_output_service.dart';
import '../../../core/services/pdf_generator_service.dart';
import 'column_mapping.dart';
import 'output_file_name.dart';
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

/// نمط حفظ مخرجات التوليد الجماعي على القرص.
///
/// * [combined] ملف PDF واحد مجمع يُكتب مباشرة في المجلد المختار.
/// * [individual] ملف مستقل لكل سجل داخل **مجلد فرعي مخصص** يُنشأ داخل
///   المجلد المختار، فلا تُبعثَر الملفات في المجلد الأصل.
enum BulkOutputMode {
  combined('combined', 'ملف واحد مجمع'),
  individual('individual', 'ملفات منفصلة لكل شخص');

  const BulkOutputMode(this.jsonValue, this.labelAr);

  /// القيمة المخزّنة في JSON (للتوافق لاحقاً مع أي حفظ للتفضيلات).
  final String jsonValue;

  /// التسمية العربية الظاهرة في واجهة الوجهة.
  final String labelAr;

  static BulkOutputMode fromJson(String? value) {
    final String needle = value?.trim().toLowerCase() ?? '';
    return values.firstWhere(
      (BulkOutputMode mode) => mode.jsonValue == needle,
      orElse: () => combined,
    );
  }
}

/// ملف PDF مستقل ناتج في الوضع المنفصل (ملف لكل شخص).
class BulkIndividualPdf {
  const BulkIndividualPdf({
    required this.rowNumber,
    required this.fileName,
    required this.bytes,
    this.name,
  });

  /// رقم الصف المُصدر كما في جدول المراجعة.
  final int rowNumber;

  /// اسم الملف النهائي داخل المجلد الفرعي (مثل `شهادة_عبدالله_بن_أحمد.pdf`).
  final String fileName;

  /// الاسم الذي طُبع داخل الشهادة (إن وُجد) — لربط الملف بصفّه.
  final String? name;

  /// بايتات ملف الـ PDF (صفحة واحدة).
  final Uint8List bytes;

  int get byteSize => bytes.lengthInBytes;
}

/// نتيجة معالجة صف واحد.
class BulkRowResult {
  const BulkRowResult({
    required this.rowNumber,
    required this.status,
    required this.missingFields,
    this.name,
    this.gender = Gender.male,
    this.skipReasonAr,
  });

  /// رقم الصف كما يراه المستخدم في Excel.
  final int rowNumber;

  final BulkRowStatus status;

  /// مفاتيح الحقول التي جاءت قيمتها فارغة في هذا الصف.
  final List<String> missingFields;

  /// اسم المستفيد الفعلي لهذا الصف — قيمة الملف أو تصحيح المستخدم من جدول
  /// المراجعة، وهو ما طُبع فعلاً.
  final String? name;

  /// الجنس المحلول لهذا الصف (صراحةً أو بكشف الاسم) — يُستخدم في التقرير
  /// وفي الصياغة الشرطية `{{الجنس: ذكر | أنثى}}`.
  final Gender gender;

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
    required this.fileName,
    this.mode = BulkOutputMode.combined,
    this.individualPdfs = const <BulkIndividualPdf>[],
    this.savedFilePath,
    this.savedDirectory,
  });

  /// ملف PDF واحد فيه صفحة لكل صف مُصدر (`null` إن لم يُصدر أي صف).
  ///
  /// يُولَّد في النمطين معاً — فهو مصدر المعاينة والطباعة حتى في الوضع
  /// المنفصل.
  final Uint8List? combinedPdf;

  /// اسم الملف النهائي الذي يُحفظ به الملف المدمج (منقّى وبامتداد).
  final String fileName;

  /// النمط الذي صُدِّر به هذا التقرير.
  final BulkOutputMode mode;

  /// ملفات الوضع المنفصل — فارغة في النمط المجمع.
  final List<BulkIndividualPdf> individualPdfs;

  /// المسار الكامل للملف المدمج المحفوظ فعلاً (النمط المجمع)، أو `null` إن
  /// لم يُحفظ (ويب/فشل/وضع منفصل).
  final String? savedFilePath;

  /// المسار الكامل للمجلد الفرعي الذي حُفظت فيه الملفات المنفصلة (النمط
  /// المنفصل)، أو `null` في النمط المجمع أو عند تعذّر إنشاء المجلد.
  final String? savedDirectory;

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

  /// عدد الملفات المنفصلة المحفوظة/المُولَّدة في الوضع المنفصل.
  int get individualCount => individualPdfs.length;

  bool get hasIndividualFiles => individualPdfs.isNotEmpty;

  /// ما حُفظ فعلاً على القرص: ملف مدمج (مجمع) أو مجلد الملفات المنفصلة.
  bool get hasSavedOutput => savedFilePath != null || savedDirectory != null;

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
  ///
  /// [genderOverrides] تصحيحات يدوية للجنس من جدول المراجعة المسبقة: المفتاح هو
  /// رقم الصف كما يراه المستخدم (‏[SheetRow.displayNumber]‏)، والقيمة هي الجنس
  /// الذي أكّده المستخدم بعد كشفه تلقائياً.
  ///
  /// [nameOverrides] تصحيحات يدوية للأسماء من الجدول نفسه: المفتاح رقم الصف،
  /// والقيمة الاسم الصحيح. يُحقن الاسم **قبل** كشف الجنس فتُشتقّ الصيغة الشرطية
  /// من الاسم المُصحَّح، ويصل الاسم الصحيح إلى المخرجات المطبوعة.
  ///
  /// [fileName] اسم ملف التصدير الذي كتبه المستخدم — يُنقّى من المحارف الممنوعة
  /// ويُضاف له الامتداد (`‎.pdf` افتراضياً) إن لزم، ويُكشف في [BulkGenerationReport.fileName].
  /// في الوضع المنفصل يصبح اسم المجلد الفرعي الذي تُحفظ داخله الملفات.
  ///
  /// [mode] نمط الحفظ: مجمع (ملف واحد) أو منفصل (ملف لكل شخص داخل مجلد فرعي).
  ///
  /// [outputDirectory] المجلد الذي اختاره المستخدم + [output] عقدة الكتابة
  /// عليه: معاً يُفعِّلان الحفظ داخل المحرّك (ينشئ [output] المجلد الفرعي
  /// للوضع المنفصل قبل كتابة الملفات فيه). بلا مجلد (الويب) يبقى التقرير
  /// في الذاكرة ولا يُمسّ نظام الملفات.
  Future<BulkGenerationReport> run({
    required TemplateDocument document,
    required SheetData sheet,
    required ColumnMapping mapping,
    MissingCellPolicy policy = MissingCellPolicy.useSample,
    Map<String, String> samples = const <String, String>{},
    Map<int, Gender> genderOverrides = const <int, Gender>{},
    Map<int, String> nameOverrides = const <int, String>{},
    String? fileName,
    PdfDocumentMetadata? metadata,
    BulkOutputMode mode = BulkOutputMode.combined,
    String? outputDirectory,
    BatchOutputService? output,
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
      final int rowNumber = row.displayNumber;
      // الاسم المُصحَّح يدوياً يحلّ محل قيمة الملف قبل كل شيء: قبل حساب النواقص
      // وقبل كشف الجنس، فيُطبع الاسم الصحيح وتُشتقّ منه الصيغة الشرطية معاً.
      final Map<String, String> raw = GenderResolver.withName(
        mapping.apply(row),
        nameOverrides[rowNumber],
      );
      final List<String> missing = <String>[
        for (final MapEntry<String, String> entry in raw.entries)
          if (entry.value.isEmpty) entry.key,
      ];

      // الجنس يُحلّ لكل صف: تصحيح يدوي ← عمود الجنس الصريح ← كشف الاسم ← ذكر.
      final Gender gender = GenderResolver.resolve(
        raw,
        override: genderOverrides[rowNumber],
        fallback: samples,
      );
      final String? name = GenderResolver.nameIn(raw);

      if (missing.isNotEmpty && policy == MissingCellPolicy.skipRow) {
        results.add(
          BulkRowResult(
            rowNumber: rowNumber,
            status: BulkRowStatus.skipped,
            missingFields: missing,
            name: name,
            gender: gender,
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

      // حقن الجنس بالقيمة العربية ليحلّ محرّك الطباعة الصيغ الشرطية في العزل
      // الخلفي بلا تمرير كائنات — ويمكن للقالب أيضاً استخدام `{{الجنس}}`.
      effective[GenderGrammar.maleKey] = gender.labelAr;

      effectiveRows.add(effective);
      results.add(
        BulkRowResult(
          rowNumber: rowNumber,
          status: BulkRowStatus.generated,
          missingFields: missing,
          name: name,
          gender: gender,
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

    // هل الحفظ على القرص ممكن أصلاً؟ (الويب بلا نظام ملفات يتجاوز الحفظ.)
    final bool canSave = output != null && outputDirectory != null;
    // الوضع المنفصل يمرّ بمرحلتين: الملف المدمج (المعاينة/الطباعة) ثم ملف
    // مستقل لكل صف — فيُبلَغ التقدّم على مرحلتين حتى يكتمل الشريط عند 100%.
    final bool savesIndividual = canSave &&
        mode == BulkOutputMode.individual &&
        effectiveRows.isNotEmpty;
    final int phaseTotal = effectiveRows.length * 2;

    Uint8List? combinedPdf;
    if (effectiveRows.isNotEmpty) {
      final PdfGenerationReport pdfReport = await generator.generateBatch(
        document: document,
        rows: effectiveRows,
        metadata: metadata,
        onProgress: savesIndividual && onProgress != null
            ? (int done, int total) => onProgress(done, phaseTotal)
            : onProgress,
      );
      combinedPdf = pdfReport.bytes;
      warnings.addAll(pdfReport.warnings);
    }

    // -------------------------------------------------------------------------
    //  الحفظ على القرص — البنية المنسّقة داخل المحرّك نفسه:
    //  * مجمع: الملف مباشرة في المجلد المختار.
    //  * منفصل: مجلد فرعي باسم التصدير أولاً، ثم ملف لكل شخص **داخله**.
    // -------------------------------------------------------------------------
    String? savedFilePath;
    String? savedDirectory;
    List<BulkIndividualPdf> individualPdfs = const <BulkIndividualPdf>[];
    final String resolvedFileName = OutputFileName.resolve(fileName ?? '');

    if (canSave && mode == BulkOutputMode.combined && combinedPdf != null) {
      savedFilePath = await output.savePdf(
        directory: outputDirectory,
        fileName: resolvedFileName,
        bytes: combinedPdf,
      );
    } else if (savesIndividual) {
      // اسم المجلد = اسم التصدير بلا امتداد (أو الاسم الافتراضي) — مثل
      // «شهادات_دفعة_أغسطس» — فلا تُبعثَر ملفات الأشخاص في المجلد الأصل.
      final String folderName = OutputFileName.baseName(fileName ?? '');
      savedDirectory = await output.createSubdirectory(
        directory: outputDirectory,
        name: folderName,
      );
      if (savedDirectory == null) {
        warnings.add(
          'تعذّر إنشاء مجلد الملفات المنفصلة «$folderName» — لم يُحفظ أي ملف.',
        );
      } else {
        // الصفوف المُصدرة بنفس ترتيب effectiveRows (كُتِبت في الحلقة نفسها).
        final List<BulkRowResult> generatedRows = <BulkRowResult>[
          for (final BulkRowResult row in results)
            if (row.isGenerated) row,
        ];
        final Set<String> usedNames = <String>{};
        final List<BulkIndividualPdf> files = <BulkIndividualPdf>[];
        for (int i = 0; i < effectiveRows.length; i++) {
          final PdfGenerationReport pdf = await generator.generate(
            document: document,
            data: effectiveRows[i],
            metadata: metadata,
          );
          final BulkRowResult row = generatedRows[i];
          files.add(
            BulkIndividualPdf(
              rowNumber: row.rowNumber,
              name: row.name,
              fileName: _individualFileName(
                name: row.name,
                rowNumber: row.rowNumber,
                usedNames: usedNames,
              ),
              bytes: pdf.bytes,
            ),
          );
          onProgress?.call(effectiveRows.length + i + 1, phaseTotal);
        }
        individualPdfs = files;
        for (final BulkIndividualPdf file in files) {
          final String? path = await output.savePdf(
            directory: savedDirectory,
            fileName: file.fileName,
            bytes: file.bytes,
          );
          if (path == null) {
            warnings.add('تعذّر حفظ الملف «${file.fileName}».');
          }
        }
      }
    }

    stopwatch.stop();
    return BulkGenerationReport(
      combinedPdf: combinedPdf,
      rows: results,
      warnings: warnings,
      elapsed: stopwatch.elapsed,
      totalRows: sheet.rowCount,
      fileName: resolvedFileName,
      mode: mode,
      individualPdfs: individualPdfs,
      savedFilePath: savedFilePath,
      savedDirectory: savedDirectory,
    );
  }

  /// اسم ملف مستقل في الوضع المنفصل: `شهادة_<الاسم>.pdf` — مسافات محوّلة إلى
  /// `_` (مثل `شهادة_عبدالله_بن_أحمد.pdf`)، وتكرار الأسماء يُميَّز بلاحقة
  /// `_2`/`_3`… (بلا مراعاة حالة الأحرف كي لا يتراكب ملفان على Windows)، واسم
  /// من رقم الصف إن غاب الاسم.
  static String _individualFileName({
    required String? name,
    required int rowNumber,
    required Set<String> usedNames,
  }) {
    String base = OutputFileName.sanitize(name ?? '')
        .replaceAll(RegExp(r'\s+'), '_');
    base = String.fromCharCodes(base.runes.take(60));
    if (base.isEmpty) base = 'صف_$rowNumber';

    String candidate = 'شهادة_$base';
    String key = candidate.toLowerCase();
    for (int copy = 2; usedNames.contains(key); copy++) {
      candidate = 'شهادة_${base}_$copy';
      key = candidate.toLowerCase();
    }
    usedNames.add(key);
    return OutputFileName.withExtension(candidate);
  }
}
