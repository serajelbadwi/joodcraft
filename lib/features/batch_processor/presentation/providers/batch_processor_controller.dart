import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/dynamic_fields.dart';
import '../../domain/field_aliases.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/models/template_document.dart';
import '../../../../core/models/template_element.dart';
import '../../../../core/services/pdf_generator_service.dart';
import '../../data/sheet_parse_isolate.dart';
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
    this.parseInIsolate = true,
    this.isolateByteThreshold = defaultIsolateByteThreshold,
  })  : _bundle = bundle ?? rootBundle,
        _generator = generator,
        _bulkService = bulkService;

  /// أصغر حجم ملف (بالبايت) يستحق نقل تفكيكه إلى isolate خلفي.
  static const int defaultIsolateByteThreshold = 48 * 1024;

  final AssetBundle _bundle;
  PdfGeneratorService? _generator;
  BulkGenerationService? _bulkService;

  /// هل يُسمح بتفكيك Excel في isolate خلفي؟ (يُعطَّل في اختبارات الودجات التي
  /// تعمل بمؤقّت مزيف لا يقود isolate حقيقياً، وعلى الويب.)
  final bool parseInIsolate;

  /// عند بلوغ حجم الملف هذا الحد يُستخدم الـ isolate (لتفادي زمن بدء الـ isolate
  /// في الملفات الصغيرة).
  final int isolateByteThreshold;

  /// بايتات آخر ملف مُختار — تُحفظ لإعادة القراءة عند تغيير الورقة أو صف
  /// العناوين.
  Uint8List? _bytes;

  /// صف العناوين الذي اختاره المستخدم يدوياً (يبدأ من صفر)، أو `null` للاكتشاف
  /// التلقائي. يُصفَّر عند تحميل ملف جديد.
  int? _headerRowIndex;

  // --------------------------------------------------------------------------
  //  الحالة
  // --------------------------------------------------------------------------
  BatchTemplateKind _kind = BatchTemplateKind.certificate;
  BatchTemplateKind get kind => _kind;

  TemplateDocument? _document;
  TemplateDocument? get document => _document;

  /// عنوان القالب النشط للعرض (قالب جاهز في المكتبة أو قالب المستخدم) —
  /// يُميّز في الواجهة أيّ قالب سيُبنى منه التوليد.
  String? _templateTitle;
  String? get templateTitle => _templateTitle;

  SheetData _sheet = SheetData.empty;
  SheetData get sheet => _sheet;

  String? _fileName;
  String? get fileName => _fileName;

  List<String> _sheetNames = const <String>[];

  /// أسماء أوراق مصنّف Excel الحالي (فارغة للملفات النصية).
  List<String> get sheetNames => _sheetNames;

  /// هل يحتوي الملف أكثر من ورقة ⇒ يُعرض منتقي الأوراق في الواجهة؟
  bool get hasSheetChoice => _sheetNames.length > 1;

  bool _loadingFile = false;

  /// هل يجري تفكيك الملف الآن في الخلفية؟ (لعرض مؤشّر تحميل.)
  bool get loadingFile => _loadingFile;

  /// صف العناوين المختار يدوياً (`null` = تلقائي) — لقيمة منتقي الواجهة.
  int? get headerRowIndex => _headerRowIndex;

  /// فهرس صف العناوين المستخدم فعلاً بعد القراءة (يبدأ من صفر).
  int get effectiveHeaderRowIndex => _sheet.headerRowIndex;

  /// رقم صف العناوين كما يراه المستخدم في Excel (يبدأ من 1).
  int get headerRowNumber => _sheet.headerRowIndex + 1;

  /// الصفوف الأولية الخام لعرضها في منتقي صف العناوين.
  List<List<String>> get rowSamples => _sheet.rowSamples;

  /// هل يمكن للمستخدم اختيار صف العناوين؟ (وجود أكثر من صف مرشّح.)
  bool get canChooseHeaderRow => _sheet.rowSamples.length > 1;

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
  /// **مصدر الحقيقة هو القالب نفسه** لا مكتبة الحقول العامة: القالب المخصّص
  /// الذي صمّمه المستخدم يستخدم مفاتيحه العربية (`{{اسم_المتدرب}}`)، وربط عمود
  /// بمفتاح لا يظهر في القالب لن يُستبدل عند الطباعة. لذلك إذا كان القالب
  /// مُحمَّلاً ومفاتيحه فارغة فلا حقول للربط — والواجهة تنبّه المستخدم بدل أن
  /// توهمه بربطٍ لن يظهر أثره. أما قبل تحميل أي قالب فتُعرض المكتبة كاملة حتى
  /// لا تفرغ الواجهة.
  List<String> get availableFields {
    final TemplateDocument? document = _document;
    if (document == null) {
      return DynamicFields.all
          .map((DynamicField field) => field.key)
          .toList(growable: false);
    }
    return document.fieldKeys.toList(growable: false)..sort();
  }

  /// هل يحتوي القالب النشط على حقول ديناميكية `{{...}}`؟
  ///
  /// عند `false` لن يتغيّر أي نص بين السجلات — وهي الحالة التي يظنّ فيها
  /// المستخدم أن القالب «مربوط» بينما هو نص ثابت لا حقول فيه.
  bool get templateHasDynamicFields => _document?.hasDynamicFields ?? false;

  /// هل يحوي القالب النشط حقل **اسم** (شخص/جهة) على الأقل؟
  ///
  /// عند `false` ومع وجود حقول أخرى (تاريخ/رقم) يُدفع المستخدم لربط عمود
  /// الاسم بحقل خطأ فيظهر الاسم مكان التاريخ — وهي الحالة الحرجة التي
  /// يشرحها [templateWarningAr].
  bool get hasNameField =>
      availableFields.any(FieldAliases.isNameToken);

  /// تحذير عربي واضح عن القالب النشط — أو `null` إن كان سليماً.
  ///
  /// الأولوية: «بلا حقول ديناميكية إطلاقاً»، ثم «فيه حقول لكن بلا حقل اسم».
  String? get templateWarningAr {
    final TemplateDocument? document = _document;
    if (document == null) return null;
    if (!templateHasDynamicFields) {
      return 'هذا القالب بلا حقول ديناميكية — لن تتغيّر البيانات بين '
          'السجلات. أضف حقل «اسم المتدرب» من شريط المحرّر (حقل ديناميكي) '
          'ثم احفظ القالب.';
    }
    if (!hasNameField) {
      return 'هذا القالب لا يحتوي على حقل اسم ديناميكي {{اسم_المتدرب}} — '
          'قد يربط عمود الاسم بحقل تاريخ أو رقم إشعار فيظهر الاسم في مكانه '
          'الخطأ. حوّل نص الاسم الثابت إلى حقل أو أعد تصميم القالب.';
    }
    return null;
  }

  /// نصوص ثابتة في القالب تبدو أسماءً ويمكن تحويلها إلى حقل بضغطة واحدة.
  ///
  /// تُعرض في خطوة الربط كاقتراح صريح يتقدّم على [templateWarningAr]: بدل أن
  /// يعلق المستخدم بلا حقل اسم يستقبل عمود ملفه، يحوّل النص المرئي أمامه إلى
  /// `{{اسم_المتدرب}}` فيُعاد الربط التلقائي فوراً.
  List<NameTextFieldCandidate> get nameFieldCandidates {
    final TemplateDocument? document = _document;
    if (document == null) return const <NameTextFieldCandidate>[];
    final List<NameTextFieldCandidate> candidates = <NameTextFieldCandidate>[];
    for (int i = 0; i < document.elements.length; i++) {
      final TemplateElement element = document.elements[i];
      if (element is! TextElement || element.hasDynamicFields) continue;
      if (!FieldAliases.looksLikePersonName(
        element.text,
        fontSize: element.fontSize,
      )) {
        continue;
      }
      candidates.add(
        NameTextFieldCandidate(index: i, preview: element.text.trim()),
      );
    }
    return candidates;
  }

  /// يحوّل نصاً ثابتاً (بفهرسه في عناصر القالب) إلى حقل ديناميكي `{{fieldKey}}`.
  ///
  /// التعديل يخصّ **نسخة التوليد الحالية** في الذاكرة فقط ولا يُحفظ على القرص،
  /// ثم يُعاد الربط التلقائي حتى يرتبط عمود الاسم بالحقل الجديد فوراً. يعيد
  /// `false` إن كان الفهرس غير صالح أو العنصر ليس نصاً.
  bool convertTextToField(int index, {String fieldKey = 'اسم_المتدرب'}) {
    final TemplateDocument? document = _document;
    if (document == null) return false;
    if (index < 0 || index >= document.elements.length) return false;
    final TemplateElement element = document.elements[index];
    if (element is! TextElement) return false;
    final List<TemplateElement> elements =
        List<TemplateElement>.from(document.elements);
    elements[index] = element.copyWith(text: DynamicFields.token(fieldKey));
    _document = document.copyWith(elements: elements);
    _autoMap();
    notifyListeners();
    return true;
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
    _templateTitle = kind.labelAr;
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
  void useDocument(
    TemplateDocument document, {
    BatchTemplateKind? kind,
    String? title,
  }) {
    if (kind != null) _kind = kind;
    _document = document;
    if (title != null && title.trim().isNotEmpty) _templateTitle = title.trim();
    _autoMap();
    notifyListeners();
  }

  // --------------------------------------------------------------------------
  //  الملف
  // --------------------------------------------------------------------------

  /// قراءة ملف البيانات محلياً ثم ربط الأعمدة تلقائياً.
  ///
  /// الملفات الصغيرة (والنصية) تُقرأ على الخيط الرئيسي مباشرةً فتُحدَّث الحالة
  /// بشكل متزامن؛ أما ملفات Excel الكبيرة فتُفكَّك في isolate خلفي. كل الفشل
  /// يُختصر في [errorAr] بدل رمي استثناء إلى الواجهة.
  Future<void> loadBytes({
    required String fileName,
    required Uint8List bytes,
  }) async {
    _bytes = bytes;
    _headerRowIndex = null;
    _errorAr = null;
    _report = null;

    if (_shouldUseIsolate(fileName, bytes)) {
      _loadingFile = true;
      notifyListeners();
      try {
        final SheetReadResult result = await parseSheetInBackground(
          SheetParseRequest(fileName: fileName, bytes: bytes),
        );
        _applyResult(fileName, result);
      } on AppException catch (error) {
        _applyFailure(error.message);
      } catch (error, stackTrace) {
        debugPrint('[التوليد الجماعي] تعذّر قراءة الملف: $error\n$stackTrace');
        _applyFailure('تعذّر قراءة الملف: $error');
      } finally {
        _loadingFile = false;
        notifyListeners();
      }
      return;
    }

    _readSync(fileName: fileName, bytes: bytes);
    notifyListeners();
  }

  /// إعادة قراءة الملف نفسه بورقة عمل أخرى اختارها المستخدم.
  Future<void> selectSheet(String sheetName) async {
    final Uint8List? bytes = _bytes;
    final String? fileName = _fileName;
    if (bytes == null || fileName == null) return;
    if (sheetName == _sheet.sheetName) return;

    _errorAr = null;
    _report = null;
    if (_shouldUseIsolate(fileName, bytes)) {
      _loadingFile = true;
      notifyListeners();
      try {
        final SheetReadResult result = await parseSheetInBackground(
          SheetParseRequest(
            fileName: fileName,
            bytes: bytes,
            sheetName: sheetName,
            headerRowIndex: _headerRowIndex,
          ),
        );
        _applyResult(fileName, result);
      } on AppException catch (error) {
        _applyFailure(error.message);
      } catch (error, stackTrace) {
        debugPrint('[التوليد الجماعي] تعذّر قراءة الورقة: $error\n$stackTrace');
        _applyFailure('تعذّر قراءة الورقة: $error');
      } finally {
        _loadingFile = false;
        notifyListeners();
      }
      return;
    }

    _readSync(
      fileName: fileName,
      bytes: bytes,
      sheetName: sheetName,
      headerRowIndex: _headerRowIndex,
    );
    notifyListeners();
  }

  /// تغيير صف العناوين (أو إعادته للتلقائي عند تمرير `null`) وإعادة القراءة.
  ///
  /// يُستخدم عندما يحتوي الملف أسطراً تعريفية أو عنواناً قبل صف العناوين
  /// الحقيقي. يعمل بنفس مسارَي الورقة: isolate للملفات الكبيرة والمزامن للصغيرة.
  Future<void> setHeaderRowIndex(int? headerRowIndex) async {
    if (headerRowIndex == _headerRowIndex) return;
    final Uint8List? bytes = _bytes;
    final String? fileName = _fileName;
    if (bytes == null || fileName == null) {
      _headerRowIndex = headerRowIndex;
      notifyListeners();
      return;
    }

    _headerRowIndex = headerRowIndex;
    _errorAr = null;
    _report = null;
    final String? sheetName = _sheet.sheetName.isEmpty ? null : _sheet.sheetName;
    if (_shouldUseIsolate(fileName, bytes)) {
      _loadingFile = true;
      notifyListeners();
      try {
        final SheetReadResult result = await parseSheetInBackground(
          SheetParseRequest(
            fileName: fileName,
            bytes: bytes,
            sheetName: sheetName,
            headerRowIndex: headerRowIndex,
          ),
        );
        _applyResult(fileName, result);
      } on AppException catch (error) {
        _applyFailure(error.message);
      } catch (error, stackTrace) {
        debugPrint('[التوليد الجماعي] تعذّر تحديث صف العناوين: $error\n$stackTrace');
        _applyFailure('تعذّر تحديث صف العناوين: $error');
      } finally {
        _loadingFile = false;
        notifyListeners();
      }
      return;
    }

    _readSync(
      fileName: fileName,
      bytes: bytes,
      sheetName: sheetName,
      headerRowIndex: headerRowIndex,
    );
    notifyListeners();
  }

  /// قراءة متزامنة (المسار السريع للملفات الصغيرة والنصية).
  void _readSync({
    required String fileName,
    required Uint8List bytes,
    String? sheetName,
    int? headerRowIndex,
  }) {
    try {
      _applyResult(
        fileName,
        SheetReaders.readResult(
          bytes,
          fileName: fileName,
          sheetName: sheetName,
          headerRowIndex: headerRowIndex,
        ),
      );
    } on AppException catch (error) {
      _applyFailure(error.message);
    } catch (error, stackTrace) {
      debugPrint('[التوليد الجماعي] تعذّر قراءة الملف: $error\n$stackTrace');
      _applyFailure('تعذّر قراءة الملف: $error');
    }
  }

  /// هل يُفكَّك هذا الملف في isolate خلفي؟ (ملفات Excel الكبيرة فقط.)
  bool _shouldUseIsolate(String fileName, Uint8List bytes) =>
      parseInIsolate &&
      !kIsWeb &&
      SheetReaders.isWorkbook(fileName) &&
      bytes.lengthInBytes >= isolateByteThreshold;

  void _applyResult(String fileName, SheetReadResult result) {
    _sheet = result.sheet;
    _fileName = fileName;
    _sheetNames = result.sheetNames;
    _autoMap();
  }

  void _applyFailure(String message) {
    _sheet = SheetData.empty;
    _fileName = null;
    _sheetNames = const <String>[];
    _bytes = null;
    _mapping = ColumnMapping.empty;
    _errorAr = message;
  }

  void clearFile() {
    _sheet = SheetData.empty;
    _fileName = null;
    _sheetNames = const <String>[];
    _bytes = null;
    _headerRowIndex = null;
    _loadingFile = false;
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
      allowMatch: _allowsAutoMatch,
    );
  }

  /// حاجز الربط الدلالي: يمنع ربط عمود اسم (Name/الاسم) بحقل تاريخ أو رقم
  /// إشعار تلقائياً — الأصل هو ألا يطبع الاسم في مكان التاريخ. الربط اليدوي
  /// من القائمة يبقى متاحاً كما هو.
  bool _allowsAutoMatch(int column, String field) {
    final String header =
        column < _sheet.headers.length ? _sheet.headers[column] : '';
    if (FieldAliases.looksLikeNameHeader(header) &&
        FieldAliases.isTemporalOrCodeToken(field)) {
      return false;
    }
    return true;
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
    _sheetNames = const <String>[];
    _bytes = null;
    _headerRowIndex = null;
    _loadingFile = false;
    _mapping = ColumnMapping.empty;
    _report = null;
    _errorAr = null;
    _done = 0;
    _total = 0;
    notifyListeners();
  }
}

/// نصّ ثابت في القالب يبدو اسمَ شخص ويمكن تحويله إلى حقل ديناميكي بضغطة.
class NameTextFieldCandidate {
  const NameTextFieldCandidate({required this.index, required this.preview});

  /// موضع العنصر في `document.elements` (يُمرَّر إلى
  /// `BatchProcessorController.convertTextToField`).
  final int index;

  /// النص الثابت كما يظهر في القالب (للعرض في الزر).
  final String preview;
}
