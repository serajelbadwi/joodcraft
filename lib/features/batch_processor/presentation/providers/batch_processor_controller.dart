import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/dynamic_fields.dart';
import '../../domain/field_aliases.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/models/template_document.dart';
import '../../../../core/services/pdf_generator_service.dart';
import '../../domain/bulk_generation.dart';
import '../../domain/column_mapping.dart';
import '../../domain/sheet_data.dart';
import '../../domain/sheet_reader.dart';

/// القالب الأساسي الذي تُبنى عليه الشهادات الجماعية.
enum BatchTemplateKind {
  certificate('شهادة', AppAssets.sampleCertificateTemplate),
  contract('عقد', AppAssets.sampleContractTemplate);

  const BatchTemplateKind(this.labelAr, this.assetPath);

  final String labelAr;
  final String assetPath;
}

/// منطق شاشة التوليد الجماعي: استيراد ← ربط ← توليد.
///
/// لا يلمس الواجهة إطلاقاً: كل حالة قابلة للقراءة هنا، والشاشة ترسم فقط. هذا
/// ما يجعل مسار «ملف ← شهادات» قابلاً للاختبار بلا أي ودجت.
class BatchProcessorController extends ChangeNotifier {
  BatchProcessorController({
    AssetBundle? bundle,
    PdfGeneratorService? generator,
    BulkGenerationService? bulkService,
  })  : _bundle = bundle ?? rootBundle,
        _generator = generator,
        _bulkService = bulkService;

  final AssetBundle _bundle;
  PdfGeneratorService? _generator;
  BulkGenerationService? _bulkService;

  // --------------------------------------------------------------------------
  //  الحالة
  // --------------------------------------------------------------------------
  BatchTemplateKind _kind = BatchTemplateKind.certificate;
  BatchTemplateKind get kind => _kind;

  TemplateDocument? _document;
  TemplateDocument? get document => _document;

  SheetData _sheet = SheetData.empty;
  SheetData get sheet => _sheet;

  String? _fileName;
  String? get fileName => _fileName;

  ColumnMapping _mapping = ColumnMapping.empty;
  ColumnMapping get mapping => _mapping;

  MissingCellPolicy _policy = MissingCellPolicy.skipRow;
  MissingCellPolicy get policy => _policy;

  bool _busy = false;
  bool get busy => _busy;

  int _done = 0;
  int _total = 0;
  double get progress => _total == 0 ? 0 : _done / _total;
  String get progressLabelAr => _total == 0 ? '' : '$_done / $_total';

  BulkGenerationReport? _report;
  BulkGenerationReport? get report => _report;

  /// آخر رسالة خطأ عربية (تُعرض في الواجهة).
  String? _errorAr;
  String? get errorAr => _errorAr;

  /// المفاتيح المتاحة للربط: ما يستخدمه القالب فعلاً في نصوصه.
  ///
  /// عند عدم وجود قالب مُحمَّل نعرض مكتبة الحقول كلها حتى لا تفرغ الواجهة.
  List<String> get availableFields {
    final TemplateDocument? document = _document;
    if (document == null || document.fieldKeys.isEmpty) {
      return DynamicFields.all
          .map((DynamicField field) => field.key)
          .toList(growable: false);
    }
    return document.fieldKeys.toList(growable: false)..sort();
  }

  /// القيمة التجريبية لحقل — كما ستُستخدم عند اختيار «استخدم القيمة التجريبية».
  String sampleOf(String field) {
    final String? fromTemplate = _document?.sampleData[field];
    if (fromTemplate != null && fromTemplate.trim().isNotEmpty) {
      return fromTemplate;
    }
    return DynamicFields.byKey(field)?.sample ?? '';
  }

  /// الأعمدة المعروضة في جدول الربط (نتجاهل أعمدة Excel الفارغة تماماً).
  List<int> get visibleColumns =>
      _sheet.isEmpty ? const <int>[] : _sheet.dataColumns;

  int get unmappedColumnCount => visibleColumns
      .where((int column) => _mapping.fieldFor(column) == null)
      .length;

  bool get canGenerate =>
      !_busy && _sheet.isNotEmpty && _mapping.isNotEmpty && !_mapping.hasDuplicates;

  // --------------------------------------------------------------------------
  //  القالب
  // --------------------------------------------------------------------------

  /// تحميل القالب النموذجي المطلوب من الأصول المحزومة.
  Future<void> selectTemplate(BatchTemplateKind kind) async {
    _kind = kind;
    _errorAr = null;
    notifyListeners();
    try {
      final String source = await _bundle.loadString(kind.assetPath);
      _document = TemplateDocument.fromJsonString(source);
      _autoMap();
    } on AppException catch (error) {
      _errorAr = error.message;
    } catch (error) {
      _errorAr = 'تعذّر تحميل القالب النموذجي: $error';
    }
    notifyListeners();
  }

  /// استخدام قالب جاهز (من محرر القوالب أو من مكتبة القوالب).
  ///
  /// [kind] يضبط وسم التوليد (شهادة/عقد) ليطابق تصنيف القالب المُختار.
  void useDocument(TemplateDocument document, {BatchTemplateKind? kind}) {
    if (kind != null) _kind = kind;
    _document = document;
    _autoMap();
    notifyListeners();
  }

  // --------------------------------------------------------------------------
  //  الملف
  // --------------------------------------------------------------------------

  /// قراءة ملف البيانات محلياً ثم ربط الأعمدة تلقائياً.
  ///
  /// كل الفشل يُختصر في [errorAr] بدل رمي استثناء إلى الواجهة.
  void loadBytes({required String fileName, required Uint8List bytes}) {
    _errorAr = null;
    _report = null;
    try {
      _sheet = SheetReaders.read(bytes, fileName: fileName);
      _fileName = fileName;
      _autoMap();
    } on AppException catch (error) {
      _sheet = SheetData.empty;
      _fileName = null;
      _mapping = ColumnMapping.empty;
      _errorAr = error.message;
    } catch (error, stackTrace) {
      debugPrint('[التوليد الجماعي] تعذّر قراءة الملف: $error\n$stackTrace');
      _sheet = SheetData.empty;
      _fileName = null;
      _mapping = ColumnMapping.empty;
      _errorAr = 'تعذّر قراءة الملف: $error';
    }
    notifyListeners();
  }

  void clearFile() {
    _sheet = SheetData.empty;
    _fileName = null;
    _mapping = ColumnMapping.empty;
    _report = null;
    _errorAr = null;
    notifyListeners();
  }

  // --------------------------------------------------------------------------
  //  الربط
  // --------------------------------------------------------------------------

  /// ربط عمود بحقل — مع منع تكرار الحقل تلقائياً.
  ///
  /// الحقل نفسه لا يُربط بعمودين (النتيجة ستكون غامضة)، لذلك ربطه بعمود جديد
  /// يفكّ ارتباطه بالعمود السابق. هذا أبسط للمستخدم من رسالة خطأ.
  void setMapping(int column, String? field) {
    ColumnMapping next = _mapping.withColumn(column, field);
    if (field != null && field.trim().isNotEmpty) {
      final int? previous = _mapping.columnFor(field.trim());
      if (previous != null && previous != column) {
        next = next.withColumn(previous, null);
      }
    }
    _mapping = next;
    notifyListeners();
  }

  void autoMap() {
    _autoMap();
    notifyListeners();
  }

  void clearMapping() {
    _mapping = ColumnMapping.empty;
    notifyListeners();
  }

  void _autoMap() {
    if (_sheet.isEmpty) return;
    _mapping = ColumnMapping.autoDetect(
      columns: visibleColumns,
      headers: _sheet.headers,
      fieldKeys: availableFields,
      aliases: FieldAliases.byToken,
    );
  }

  void setPolicy(MissingCellPolicy policy) {
    _policy = policy;
    notifyListeners();
  }

  // --------------------------------------------------------------------------
  //  التوليد
  // --------------------------------------------------------------------------

  Future<void> generate() async {
    final TemplateDocument? document = _document;
    if (document == null) {
      _errorAr = 'اختر قالباً (شهادة أو عقد) قبل التوليد.';
      notifyListeners();
      return;
    }

    _busy = true;
    _errorAr = null;
    _report = null;
    _done = 0;
    _total = _sheet.rowCount;
    notifyListeners();

    try {
      final PdfGeneratorService generator =
          _generator ??= await PdfGeneratorService.create();
      final BulkGenerationService service =
          _bulkService ??= BulkGenerationService(generator: generator);

      final BulkGenerationReport report = await service.run(
        document: document,
        sheet: _sheet,
        mapping: _mapping,
        policy: _policy,
        samples: document.sampleData,
        metadata: PdfDocumentMetadata(
          title: '${_kind.labelAr} جماعية — JoodCraft',
          subject: _fileName ?? '',
        ),
        onProgress: (int done, int total) {
          _done = done;
          _total = total;
          notifyListeners();
        },
      );
      _report = report;
    } on AppException catch (error) {
      _errorAr = error.message;
    } catch (error) {
      _errorAr = 'تعذّر التوليد الجماعي: $error';
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// إعادة كل شيء إلى البداية (ملف جديد).
  void reset() {
    _sheet = SheetData.empty;
    _fileName = null;
    _mapping = ColumnMapping.empty;
    _report = null;
    _errorAr = null;
    _done = 0;
    _total = 0;
    notifyListeners();
  }
}
