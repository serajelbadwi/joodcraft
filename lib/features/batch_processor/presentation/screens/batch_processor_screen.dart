import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/dynamic_fields.dart';
import '../../../../core/editor/widgets/editor_controls.dart';
import '../../../../core/gender/arabic_gender.dart';
import '../../../../core/l10n/app_l10n.dart';
import '../../../../core/models/template_document.dart';
import '../../../../core/models/template_element.dart';
import '../../../../core/services/batch_output_backend.dart';
import '../../../../core/services/batch_output_service.dart';
import '../../../../core/templates/local_template_store.dart';
import '../../../../core/templates/template_library_controller.dart';
import '../../../../core/templates/template_library_entry.dart';
import '../../../../core/templates/template_record.dart';
import '../../../../core/templates/template_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/ui_feedback.dart';
import '../../domain/bulk_generation.dart';
import '../../domain/output_file_name.dart';
import '../../domain/sheet_data.dart';
import '../../domain/sheet_reader.dart';
import '../../../invitations/domain/invitation_export_service.dart';
import '../../../invitations/presentation/providers/invitations_controller.dart';
import '../../../invitations/presentation/screens/invitations_screen.dart';
import '../providers/batch_processor_controller.dart';

/// وضع العمل في شاشة «التوليد الجماعي» الموحّدة.
///
/// صارت الشاشة **محركاً واحداً** يضمّ ثلاثة مسارات:
///
/// | الوضع      | المسار                                                        |
/// |-------------|----------------------------------------------------------------|
/// | شهادة       | توليد الشهادات من Excel (مسار الشاشة الأصلي كاملاً)             |
/// | عقد         | توليد العقود من Excel                                          |
/// | دعوة        | توليد الدعوات الشخصية — كان شاشة مستقلة على `/invitations`،    |
/// |             | ويُضمَّن محتواها هنا **كما هو** بلا إعادة كتابة                 |
///
/// التبديل **لا يمسّ الموجّه**: لا يُحذف مسار ولا وجهة ولا فرع. شاشة الدعوات
/// تبقى على `/invitations` (وتظهر في لوحة التنقّل على الجوال) وتُستدعى هنا
/// بوضع `embedded` بديل عن Scaffoldها.
enum BatchWorkType {
  certificate('certificate'),
  contract('contract'),
  invitation('invitation');

  const BatchWorkType(this.jsonValue);

  final String jsonValue;

  /// نوع المستند الموافق في المتحكّم — أو `null` لوضع «دعوة» لأن له محرّكه
  /// ومساره الخاص لا علاقة له بـ`BatchProcessorController`.
  BatchTemplateKind? get documentKind => switch (this) {
        BatchWorkType.certificate => BatchTemplateKind.certificate,
        BatchWorkType.contract => BatchTemplateKind.contract,
        BatchWorkType.invitation => null,
      };
}

/// شاشة «التوليد الجماعي» (المرحلة 4).
///
/// المسار كامل بلا شبكة: ملف `.xlsx`/`.csv` من جهاز المستخدم ← قراءة محلية ←
/// ربط الأعمدة بحقول القالب ← ملف PDF واحد بصفحة لكل سجل.
class BatchProcessorScreen extends StatefulWidget {
  const BatchProcessorScreen({
    super.key,
    this.controller,
    this.record,
    this.repository,
    this.localStore,
    this.libraryController,
    this.output,
  });

  /// محرّك الشاشة — يُمرَّر في الاختبارات أو عند استئناف جلسة سابقة.
  final BatchProcessorController? controller;

  /// قالب مختار من مكتبة القوالب — يُحمَّل مباشرةً بدل القالب النموذجي.
  final TemplateRecord? record;

  /// مستودع القوالب السحابية — لجلب قوالب المستخدم في منتقي القالب.
  final TemplateRepository? repository;

  /// مخزن القوالب المحلية — يُحقن في الاختبارات (مخزن في الذاكرة).
  final LocalTemplateStore? localStore;

  /// متحكّم مكتبة القوالب جاهز — يُحقن في الاختبارات (يتقدّم على الافتراضي).
  final TemplateLibraryController? libraryController;

  /// خدمة مخرجات التوليد (اختيار المجلد/الكتابة/الفتح) — تُحقن وهمية في
  /// الاختبارات، وتُترك فارغة لاختيار تنفيذ المنصة تلقائياً.
  final BatchOutputService? output;

  /// امتدادات ملفات البيانات المقبولة في منتقي الملفات.
  ///
  /// **مأخوذة من المصدر الوحيد للحقيقة** في [SheetReaders] — فلا تتباعد قائمة
  /// المنتقي عن قائمة القارئ أبداً (كان يُقبل هنا `txt` هناك ولا يُعرض العكس).
  static const List<String> acceptedExtensions =
      SheetReaders.supportedExtensions;

  @override
  State<BatchProcessorScreen> createState() => _BatchProcessorScreenState();
}

class _BatchProcessorScreenState extends State<BatchProcessorScreen> {
  late final BatchProcessorController _controller =
      widget.controller ?? BatchProcessorController();

  /// مكتبة القوالب — تُوفّر قوالب المستخدم (المحلية والسحابية) للاختيار هنا.
  late final TemplateLibraryController _library = widget.libraryController ??
      TemplateLibraryController(
        widget.repository,
        localStore: widget.localStore,
      );
  late final bool _ownsLibrary = widget.libraryController == null;

  /// القالب الخاصّ المختار حالياً (للتمييز في القائمة والتسمية).
  String? _selectedTemplateId;
  String? _selectedTemplateTitle;

  /// خدمة مخرجات التوليد — الوهمية في الاختبارات، والمنصّية افتراضياً.
  late final BatchOutputService _output =
      widget.output ?? createBatchOutputService();

  /// مجلد الحفظ الذي اختاره المستخدم — يبقى خلال الجلسة لإعادة الفتح لاحقاً.
  String? _outputDirectory;

  /// آخر اسم ملف تصدير كتبه المستخدم — يُعاد عرضه عند فتح النافذة ثانية.
  /// `null` = لم يُعدّل المستخدم الافتراضي المشتقّ من عنوان القالب.
  String? _outputFileNameInput;

  /// المسار الكامل لآخر ملف PDF حُفظ فعلاً عليه (للعرض وفتح المجلد).
  String? _savedFilePath;

  /// المسار الكامل للمجلد الفرعي الذي حُفظت فيه ملفات الوضع المنفصل — يُفتح
  /// مكانه زر «فتح المجلد» مباشرةً بدل المجلد الأصل.
  String? _savedFolderPath;

  /// آخر نمط حفظ اختاره المستخدم — يُعاد عرضه عند فتح النافذة ثانية.
  BulkOutputMode _outputMode = BulkOutputMode.combined;

  // --------------------------------------------------------------------------
  //  الوضع الموحّد: نوع القالب + صيغة التصدير (شريط أعلى الخطوات)
  // --------------------------------------------------------------------------

  /// وضع الشاشة الحالي — يبدّل المسار كاملاً بين مسارَي التوليد.
  BatchWorkType _workType = BatchWorkType.certificate;

  /// صيغة الملفات المحفوظة في مسار الشهادات/العقود.
  ///
  /// مسار الدعوات لا نخزّن صيغته هنا: له [InvitationsController.format]
  /// بخياراته الثلاثة (‏PNG / PDF / الاثنان معاً) فلا نكرّر مصدر حقّ.
  BatchExportFormat _exportFormat = BatchExportFormat.pdf;

  /// محرّك الدعوات المضمَّن — يُنشأ أول مرة يختار فيها المستخدم «دعوة»
  /// ويُبقى أثناء تبديل الأنواع كي لا تضيع اختياراته (ملف الأسماء، القالب،
  /// الصيغة، خيارا ZIP وCSV).
  InvitationsController? _invitations;

  /// هل أنشأناه نحن (نحن من نُتلفه)؟ أم محقون من الخارج.
  bool _ownsInvitations = false;

  /// هل يوجد مصدر حقيقي لقوالب المستخدم (سحابة/محلي/متحكّم محقون)؟
  ///
  /// نتجنّب تحميلاً لا معنى له (ومؤقّتاً معلّقاً) عندما لا يوجد مصدر — كما في
  /// اختبارات الودجات وواجهة التهيئة بلا Supabase.
  bool get _hasLibrarySource =>
      widget.libraryController != null ||
      widget.repository != null ||
      widget.localStore != null;

  @override
  void initState() {
    super.initState();
    if (_hasLibrarySource) unawaited(_library.refresh());

    final TemplateRecord? record = widget.record;
    if (record != null) {
      _selectedTemplateId = record.id;
      _selectedTemplateTitle = record.title;
      _controller.useDocument(
        record.toDocument(),
        kind: _kindFor(record.category),
        title: record.title,
      );
    } else if (_controller.document == null) {
      unawaited(_controller.selectTemplate(_controller.kind));
    }

    // الوضع المبدئي يتبع نوع المستند المفتوح — فالشريط يعكس ما هو فعلاً
    // على الشاشة لا قيمةً مفروضة.
    _workType = _controller.kind == BatchTemplateKind.contract
        ? BatchWorkType.contract
        : BatchWorkType.certificate;
  }

  @override
  void dispose() {
    // لا نُتلف محرّكات يملكها المستدعي.
    if (_ownsLibrary) _library.dispose();
    if (widget.controller == null) _controller.dispose();
    if (_ownsInvitations) _invitations?.dispose();
    super.dispose();
  }

  static BatchTemplateKind _kindFor(TemplateCategory category) =>
      category == TemplateCategory.contract
          ? BatchTemplateKind.contract
          : BatchTemplateKind.certificate;

  /// تسمية نوع التوليد (شهادة/عقد) — نص محلي مع احتياط من المتحكّم.
  String _kindLabel(BatchTemplateKind kind) =>
      kind == BatchTemplateKind.certificate
          ? context.l10n?.bpKindCertificate ?? kind.labelAr
          : context.l10n?.bpKindContract ?? kind.labelAr;

  /// تحذير القالب النشط — نص محلي مع احتياط عربي من المتحكّم.
  String? _templateWarning() {
    if (_controller.document == null) return null;
    if (!_controller.templateHasDynamicFields) {
      return context.l10n?.bpWarnNoDynamicFields ??
          _controller.templateWarningAr;
    }
    if (!_controller.hasNameField) {
      return context.l10n?.bpWarnNoNameField ?? _controller.templateWarningAr;
    }
    return null;
  }

  /// رسالة آخر خطأ من المتحكّم — معرّبة حسب رمزه مع احتياط عربي.
  String? _errorText() {
    final String? fallback = _controller.errorAr;
    if (fallback == null) return null;
    final l10n = context.l10n;
    if (l10n == null) return fallback;
    final Object detail = _controller.errorDetail ?? '';
    switch (_controller.errorCode) {
      case BatchErrorCode.loadSample:
        return l10n.bpLoadSampleError(detail);
      case BatchErrorCode.readFile:
        return l10n.bpReadFileError(detail);
      case BatchErrorCode.readSheet:
        return l10n.bpReadSheetError(detail);
      case BatchErrorCode.updateHeaderRow:
        return l10n.bpUpdateHeaderRowError(detail);
      case BatchErrorCode.chooseTemplateFirst:
        return l10n.bpChooseTemplateFirst;
      case BatchErrorCode.generate:
        return l10n.bpGenerateError(detail);
      case BatchErrorCode.message:
      case null:
        return fallback;
    }
  }

  /// قوالب المستخدم (المحلية والسحابية) — بلا القوالب الجاهزة المحزومة.
  List<TemplateLibraryEntry> _userTemplates() {
    final List<TemplateLibraryEntry> mine = _library.entries
        .where((TemplateLibraryEntry entry) => !entry.isPreset)
        .toList();
    mine.sort((TemplateLibraryEntry a, TemplateLibraryEntry b) =>
        a.title.compareTo(b.title));
    return mine;
  }

  /// اعتماد قالب خاصّ للمستخدم في عملية التوليد.
  void _applyUserTemplate(TemplateLibraryEntry entry) {
    setState(() {
      _selectedTemplateId = entry.id;
      _selectedTemplateTitle = entry.title;
    });
    _controller.useDocument(
      entry.toDocument(),
      kind: _kindFor(entry.category),
      title: entry.title,
    );
  }

  /// العودة إلى القوالب النموذجية المدمجة.
  void _applyDefaultTemplate(BatchTemplateKind kind) {
    setState(() {
      _selectedTemplateId = null;
      _selectedTemplateTitle = null;
    });
    unawaited(_controller.selectTemplate(kind));
  }

  // --------------------------------------------------------------------------
  //  التبديل بين مسارات الشاشة الموحّدة
  // --------------------------------------------------------------------------

  /// محرّك الدعوات المضمَّن — يُنشأ عند أول اختيار لوضع «دعوة» فقط (فلا
  /// يتحمّل التطبيق محرّكاً لا يستعمله أصلاً).
  InvitationsController _ensureInvitations() {
    if (_invitations == null) {
      _invitations = InvitationsController();
      _ownsInvitations = true;
    }
    return _invitations!;
  }

  /// تبديل وضع الشاشة: «شهادة»/«عقد» ينقل إلى مسار التوليد الموافق ويلقّم
  /// المتحكّم بنفسه، و«دعوة» يفتح المسار المضمَّن مع إبقاء محرّك الشهادات
  /// كما هو — فيعود المستخدم إليه بحالته لم يضِع.
  void _setWorkType(BatchWorkType type) {
    if (type == _workType) return;
    setState(() {
      _workType = type;
      if (type == BatchWorkType.invitation) _ensureInvitations();
    });
    final BatchTemplateKind? kind = type.documentKind;
    if (kind != null && kind != _controller.kind) {
      _applyDefaultTemplate(kind);
    }
  }

  /// القالب المستخدم المختار حالياً (محلي/سحابي) — أو `null` للقوالب الجاهزة.
  TemplateLibraryEntry? _selectedUserEntry() {
    final String? id = _selectedTemplateId;
    if (id == null) return null;
    for (final TemplateLibraryEntry entry in _library.entries) {
      if (entry.id == id && !entry.isPreset) return entry;
    }
    return null;
  }

  /// يحوّل نصاً ثابتاً يشبه الاسم إلى حقل `{{اسم_المتدرب}}` **ثم يحفظ التعديل**
  /// في القالب الأصلي إن كان قالب مستخدم (محلي/سحابي).
  ///
  /// التعديل الفوري يجري في [BatchProcessorController] ليُعاد الربط فوراً،
  /// ثم يُثبَّت في السجل عبر [TemplateLibraryController.updateDocument] حتى لا
  /// يضيع عند إعادة التحميل. للقوالب الجاهزة غير القابلة للتعديل نكتفي
  /// بالتوليد الحالي مع إرشاد المستخدم.
  Future<void> _convertTextToField(
    int index, {
    String fieldKey = 'اسم_المتدرب',
  }) async {
    // نلتقط النص الأصلي **قبل** التحويل لنمنح المستخدم تراجعاً كاملاً (في
    // الذاكرة وفي القالب المحفوظ معاً).
    final TemplateDocument? before = _controller.document;
    if (before == null || index < 0 || index >= before.elements.length) return;
    final TemplateElement element = before.elements[index];
    if (element is! TextElement) return;
    final String originalText = element.text;
    final String token = '{{$fieldKey}}';

    // التحويل يمسّ هذا العنصر وحده — لا يُلمس أي عنصر آخر في القالب.
    if (!_controller.convertTextToField(index, fieldKey: fieldKey)) return;
    final TemplateDocument? document = _controller.document;
    final TemplateLibraryEntry? entry = _selectedUserEntry();
    if (!mounted || document == null) return;

    void undo() =>
        unawaited(_revertTextToField(index, originalText, entry));

    if (entry == null) {
      // قالب جاهز غير قابل للتعديل: التحويل للتوليد الحالي فقط، والتراجع
      // يُلغي أثره في الذاكرة.
      context.showSuccessAction(
        context.l10n?.bpAssignedTemp(token) ??
            'عُيّن هذا العنصر إلى $token للتوليد الحالي — بقية العناصر لم تُمسّ. '
                'احفظ القالب لتثبيت التعديل دائماً.',
        actionLabel: context.l10n?.commonUndo ?? 'تراجع',
        onAction: undo,
      );
      return;
    }

    try {
      await _library.updateDocument(entry: entry, document: document);
      if (!mounted) return;
      context.showSuccessAction(
        context.l10n?.bpAssignedSaved(token) ??
            'عُيّن هذا العنصر إلى $token وحُفظ التعديل في القالب. '
                'بقية العناصر لم تُمسّ.',
        actionLabel: context.l10n?.commonUndo ?? 'تراجع',
        onAction: undo,
      );
    } catch (error) {
      if (!mounted) return;
      context.showError(
        context.l10n?.bpSaveError(error) ?? 'تعذّر حفظ التعديل في القالب: $error',
      );
    }
  }

  /// يفتح منتقي الحقل لعنصر نصي محدَّد بالنقر (تعيين صريح بلا تخمين).
  Future<void> _assignFieldToElement(int index) async {
    final TemplateDocument? document = _controller.document;
    if (document == null || index < 0 || index >= document.elements.length) {
      return;
    }
    final TemplateElement element = document.elements[index];
    if (element is! TextElement) return;

    // الحقول المقترحة: ما يستخدمه القالب فعلاً + مكتبة الحقول العامة.
    final List<String> fields = <String>[
      ..._controller.availableFields,
      ...DynamicFields.all.map((DynamicField f) => f.key),
    ];
    final List<String> unique = <String>[];
    for (final String field in fields) {
      if (!unique.contains(field)) unique.add(field);
    }

    final String? picked = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => SimpleDialog(
        title: Text(context.l10n?.bpMapFieldTitle ?? 'تعيين حقل ديناميكي لهذا العنصر'),
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            child: Text(
              context.l10n?.bpMapFieldBody ?? 'سيُستبدل نص هذا العنصر وحده بحقل، ولن يُمسّ أي عنصر آخر.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          for (final String field in unique)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(field),
              child: Row(
                children: <Widget>[
                  const Icon(Icons.data_object_rounded, size: 16),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '$field  •  ${_controller.sampleOf(field)}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );

    if (picked == null || picked.isEmpty || !mounted) return;
    await _convertTextToField(index, fieldKey: picked);
  }

  /// تراجع: يُعيد النص الثابت مكان الحقل، ويُزيل الربط التلقائي، ويُثبّت
  /// الاستعادة في القالب المحفوظ إن كان قالب مستخدم.
  Future<void> _revertTextToField(
    int index,
    String originalText,
    TemplateLibraryEntry? entry,
  ) async {
    if (!_controller.revertTextToField(index, originalText)) return;
    final TemplateDocument? document = _controller.document;
    if (!mounted || document == null) return;

    if (entry == null) {
      context.showSuccess(context.l10n?.bpUndoConvert ?? 'تم التراجع عن التحويل.');
      return;
    }

    try {
      await _library.updateDocument(entry: entry, document: document);
      if (!mounted) return;
      context.showSuccess(context.l10n?.bpUndoConvertSaved ?? 'تم التراجع عن التحويل واستعادة النص في القالب.');
    } catch (error) {
      if (!mounted) return;
      context.showError(
        context.l10n?.bpRestoreError(error) ??
            'تعذّر استعادة النص في القالب: $error',
      );
    }
  }

  // --------------------------------------------------------------------------
  //  اختيار الملف
  // --------------------------------------------------------------------------
  Future<void> _pickFile() async {
    final List<PlatformFile> picked;
    try {
      picked = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: BatchProcessorScreen.acceptedExtensions,
        dialogTitle: context.l10n?.bpPickDataFile ?? 'اختر ملف البيانات (Excel أو CSV)',
      );
    } catch (error) {
      if (!mounted) return;
      context.showError(
        context.l10n?.cfpPickerError(error) ?? 'تعذّر فتح منتقي الملفات: $error',
      );
      return;
    }
    if (picked.isEmpty) return;

    final PlatformFile file = picked.first;
    try {
      // قراءة آمنة للبايتات أولاً ثم تمريرها للقارئ داخل try-catch.
      final Uint8List bytes = await file.readAsBytes();
      await _controller.loadBytes(fileName: file.name, bytes: bytes);
    } catch (error, stackTrace) {
      debugPrint('[استيراد الملف] تعذّرت قراءة الملف: $error\n$stackTrace');
      if (!mounted) return;
      context.showError(
        context.l10n?.bpReadFileError(error) ?? 'تعذّر قراءة الملف: $error',
      );
      return;
    }

    if (!mounted) return;
    final String? error = _errorText();
    if (error != null) {
      context.showError(error);
    } else {
      context.showSuccess(
        context.l10n?.bpFileReadRows(
              _controller.sheet.rowCount,
              _controller.sheet.columnCount,
            ) ??
            'قُرئ الملف محلياً: ${_controller.sheet.rowCount} صفاً '
                'و${_controller.sheet.columnCount} عموداً.',
      );
    }
  }

  /// اسم ملف الإخراج الافتراضي — مشتقّ من عنوان القالب النشط، وإلا فالاسم
  /// الاحتياطي العام.
  String _defaultOutputFileName() =>
      OutputFileName.defaultBaseName(templateTitle: _controller.templateTitle);

  /// يفتح نافذة وجهة الحفظ (المجلد + اسم الملف) ويعيد الخيارات المؤكَّدة.
  ///
  /// `null` = ألغى المستخدم الحوار. المجلد قد يكون `null` على الويب (بلا نظام
  /// ملفات) فيُتابع التوليد بلا حفظ على القرص.
  Future<_OutputOptions?> _chooseOutputOptions() async {
    final String? initialDirectory =
        _outputDirectory ?? await _output.defaultDirectory();
    if (!mounted) return null;
    return showDialog<_OutputOptions>(
      context: context,
      builder: (BuildContext dialogContext) => _OutputOptionsDialog(
        initialDirectory: initialDirectory,
        initialFileName: _outputFileNameInput ?? _defaultOutputFileName(),
        initialMode: _outputMode,
        onPickDirectory: _pickOutputDirectory,
      ),
    );
  }

  /// يفتح منتقي المجلدات الأصلي ويعيد المسار المختار (أو `null` إن أُلغي).
  Future<String?> _pickOutputDirectory() => _output.pickDirectory(
        dialogTitle: context.l10n?.bpOutputTitle ?? 'وجهة حفظ الشهادات',
      );

  /// يفتح مجلد المخرجات في مستكشف ملفات النظام — مجلد الملفات المنفصلة
  /// نفسه إن حُفظت في الوضع المنفصل، وإلا المجلد المختار.
  Future<void> _openOutputFolder() async {
    final String? directory = _savedFolderPath ?? _outputDirectory;
    if (directory == null) return;
    final bool opened = await _output.openDirectory(directory);
    if (!mounted || opened) return;
    context.showError(context.l10n?.bpOpenFolderFailed ?? 'تعذّر فتح المجلد.');
  }

  /// يطلب وجهة الحفظ واسم الملف **أولاً** ثم يولّد ويحفظ الملف باسمه المختار.
  ///
  /// طلب الوجهة قبل التوليد مقصود: يعرف المستخدم أين سيُكتب الملف وبأي اسم قبل
  /// الانتظار، ويبقى المجلد محفوظاً في الجلسة لإعادة فتحه من الشريط الثابت.
  Future<void> _generate() async {
    final _OutputOptions? options = await _chooseOutputOptions();
    if (options == null) return; // ألغى المستخدم نافذة الوجهة.
    final String? directory = options.directory;
    final String typedName = options.fileName.trim();
    if (!mounted) return;
    setState(() {
      _outputDirectory = directory;
      _outputFileNameInput = typedName.isEmpty ? null : typedName;
      _outputMode = options.mode;
      _savedFilePath = null;
      _savedFolderPath = null;
    });

    // الحفظ يجري **داخل المحرّك** بالبنية المنسّقة: المجمّع مباشرة في المجلد
    // المختار، والمنفصل داخل مجلد فرعي باسم التصدير لا يزحم المجلد الأصل.
    // فشل الحفظ أو غياب نظام الملفات (الويب) يمرّ بهدوء وتبقى الطباعة/التصدير
    // متاحة.
    await _controller.generate(
      outputFileName: typedName.isEmpty ? null : typedName,
      outputDirectory: directory,
      mode: options.mode,
      format: _exportFormat,
      output: _output,
    );
    if (!mounted) return;
    final String? error = _errorText();
    if (error != null) {
      context.showError(error);
      return;
    }
    final BulkGenerationReport? report = _controller.report;
    if (report == null) return;

    if (report.hasSavedOutput) {
      setState(() {
        _savedFilePath = report.savedFilePath;
        _savedFolderPath = report.savedDirectory;
      });
    }

    if (!mounted) return;
    final String generated =
        context.l10n?.bpGeneratedReport(report.generatedCount) ??
            'تم توليد ${report.generatedCount} سجل';
    final String skippedSuffix = report.skippedCount > 0
        ? context.l10n?.bpSkippedSuffix(report.skippedCount) ??
            ' وتخطّي ${report.skippedCount}'
        : '';
    context.showSuccess('$generated$skippedSuffix.');
  }

  Future<void> _print() async {
    final BulkGenerationReport? report = _controller.report;
    final Uint8List? bytes = report?.combinedPdf;
    if (bytes == null) return;
    try {
      await Printing.layoutPdf(
        name: report?.fileName ?? 'joodcraft-batch.pdf',
        onLayout: (PdfPageFormat format) async => bytes,
      );
    } on Object {
      if (!mounted) return;
      context.showError(context.l10n?.commonPrintFailed ?? 'تعذّر إرسال الملف إلى الطابعة.');
    }
  }

  Future<void> _export() async {
    final BulkGenerationReport? report = _controller.report;
    final Uint8List? bytes = report?.combinedPdf;
    if (bytes == null) return;
    try {
      await Printing.sharePdf(
        bytes: bytes,
        filename: report?.fileName ?? 'joodcraft-batch.pdf',
      );
      if (!mounted) return;
      context.showSuccess(context.l10n?.bpReadyToSave ?? 'تم تجهيز الملف للحفظ.');
    } on Object {
      if (!mounted) return;
      context.showError(context.l10n?.commonExportFailed ?? 'تعذّر تصدير ملف PDF.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? _) {
        return ColoredBox(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _hero(),
              // شريط الاختيار الموحّد: نوع القالب (شهادة/عقد/دعوة) ثم نوع
              // التصدير (PDF/PNG) — يبقى فوق الخطوات في الوضعين.
              _workTypeBar(),
              // شريط ثابت يعرض مجلد المخرجات وزرّ فتحه — يبقى ظاهراً بعد التوليد
              // حتى لا يفقد المستخدم مكان الملفات إن نسي أو تنقّل بعيداً.
              if (_outputDirectory != null) _outputBanner(),
              Expanded(
                // وضع «دعوة»: محتوى شاشة الدعوات نفسه (مضمَّن بلا Scaffold)
                // يشغل المنطقة كاملة — لا خطوات ولا معاينة لهذا المسار.
                child: _workType == BatchWorkType.invitation
                    ? _invitationsFlow()
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          SizedBox(
                            width: 430,
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(AppTheme.space16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: <Widget>[
                                  _templateStep(),
                                  const SizedBox(height: AppTheme.space12),
                                  _fileStep(),
                                  const SizedBox(height: AppTheme.space12),
                                  _mappingStep(),
                                  const SizedBox(height: AppTheme.space12),
                                  _optionsStep(),
                                  const SizedBox(height: AppTheme.space12),
                                  // مراجعة الجنس المسبقة: تظهر فقط إن كان القالب يستخدم
                                  // صيغاً شرطية أو رُبط حقل اسم، فلا تزحم المسار السليم.
                                  if (_controller.hasGenderReview) ...<Widget>[
                                    _genderReviewStep(),
                                    const SizedBox(height: AppTheme.space12),
                                  ],
                                  _generateStep(),
                                ],
                              ),
                            ),
                          ),
                          VerticalDivider(
                            width: 1,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          Expanded(child: _previewArea()),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================================================
  //  الترويسة
  // ==========================================================================
  Widget _hero() {
    final TextTheme text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space20,
        vertical: AppTheme.space12,
      ),        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            bottom: BorderSide(color: Theme.of(context).colorScheme.outline),
          ),
        ),
        child: Row(
          children: <Widget>[
            Icon(
              Icons.table_view_rounded,
              color: Theme.of(context).colorScheme.primary,
              size: 22,
            ),
          const SizedBox(width: AppTheme.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(context.l10n?.bpTitle ?? 'التوليد الجماعي من Excel', style: text.titleMedium),
                Text(
                  context.l10n?.bpSubtitle ??
                      'استورد ملف .xlsx أو .csv، اربط أعمدته بحقول القالب، ثم ولّد '
                          'ملف PDF بصفحة لكل سجل — كل ذلك على جهازك بلا إنترنت.',
                  style: text.bodySmall,
                ),
              ],
            ),
          ),
          if (_controller.fileName != null || _controller.document != null)
            TextButton.icon(
              onPressed: () {
                _controller.reset();
                setState(() {
                  _outputDirectory = null;
                  _outputFileNameInput = null;
                  _savedFilePath = null;
                  _savedFolderPath = null;
                  _selectedTemplateId = null;
                  _selectedTemplateTitle = null;
                });
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('إغلاق وبدء مشروع جديد'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
            ),
        ],
      ),
    );
  }

  // ==========================================================================
  //  شريط الاختيار الموحّد — نوع القالب ونوع التصدير
  // ==========================================================================

  /// مسار الدعوات المضمَّن: محتوى شاشة `/invitations` نفسه بلا Scaffold،
  /// بمحرّكه المحقون (أو المنشأ الآن لأول اختيار).
  Widget _invitationsFlow() {
    return InvitationsScreen(
      key: const ValueKey<String>('bp-invitations-flow'),
      controller: _ensureInvitations(),
      embedded: true,
    );
  }

  /// شريط فوق خطوات التوليد يحدّد **نوع القالب** (شهادة/عقد/دعوة) و**نوع
  /// التصدير** (PDF/PNG) — وهو ما جعلتَ به الشاشة واحدة تخدم ثلاثة مسارات.
  ///
  /// `Wrap` لا `Row`: على عرض ضيّق يلتفّ الشريطان إلى سطرين بدل قصّ أيّهما.
  Widget _workTypeBar() {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool invitationsMode = _workType == BatchWorkType.invitation;

    return Container(
      key: const ValueKey<String>('bp-work-type-bar'),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space20,
        vertical: AppTheme.space8,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(bottom: BorderSide(color: scheme.outline)),
      ),
      child: Wrap(
        spacing: AppTheme.space16,
        runSpacing: AppTheme.space8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          _barLabel(context.l10n?.bpWorkTypeLabel ?? 'نوع القالب'),
          SegmentedButton<BatchWorkType>(
            showSelectedIcon: false,
            style: const ButtonStyle(visualDensity: VisualDensity.compact),
            segments: <ButtonSegment<BatchWorkType>>[
              ButtonSegment<BatchWorkType>(
                value: BatchWorkType.certificate,
                label: Text(_kindLabel(BatchTemplateKind.certificate)),
                icon: const Icon(Icons.workspace_premium_outlined, size: 15),
              ),
              ButtonSegment<BatchWorkType>(
                value: BatchWorkType.contract,
                label: Text(_kindLabel(BatchTemplateKind.contract)),
                icon: const Icon(Icons.handshake_outlined, size: 15),
              ),
              ButtonSegment<BatchWorkType>(
                value: BatchWorkType.invitation,
                label: Text(context.l10n?.bpKindInvitation ?? 'دعوة'),
                icon: const Icon(Icons.redeem_rounded, size: 15),
              ),
            ],
            selected: <BatchWorkType>{_workType},
            onSelectionChanged: (Set<BatchWorkType> selection) {
              if (selection.isEmpty) return;
              _setWorkType(selection.first);
            },
          ),
          _barLabel(context.l10n?.bpExportFormatLabel ?? 'نوع التصدير'),
          // لكل مسار مفتاح صيغته هو: الشهادات/العقود بمحرّكها، والدعوات
          // بخياراتها الثلاثة الأصلية فلا نُجرّدها إلى خيارين.
          if (invitationsMode)
            _invitationFormatButton()
          else
            _documentFormatButton(),
        ],
      ),
    );
  }

  /// تسمية صغيرة تسبق كل مفتاح في الشريط.
  Widget _barLabel(String label) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Text(
      label,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
    );
  }

  /// مفتاح الصيغة في مسار الشهادات/العقود: ‏PDF (الأصل) أو PNG بترميز
  /// الصفحات — يُمرَّر إلى `BulkGenerationService` عند التوليد.
  Widget _documentFormatButton() {
    return SegmentedButton<BatchExportFormat>(
      showSelectedIcon: false,
      style: const ButtonStyle(visualDensity: VisualDensity.compact),
      segments: <ButtonSegment<BatchExportFormat>>[
        for (final BatchExportFormat format in BatchExportFormat.values)
          ButtonSegment<BatchExportFormat>(
            value: format,
            label: Text(format.labelAr),
          ),
      ],
      selected: <BatchExportFormat>{_exportFormat},
      onSelectionChanged: (Set<BatchExportFormat> selection) {
        if (selection.isEmpty) return;
        setState(() => _exportFormat = selection.first);
      },
    );
  }

  /// مفتاح الصيغة في مسار الدعوات: خياراته الأصلية الثلاثة كاملة، متحقّقة
  /// من محرّك الدعوات نفسه.
  Widget _invitationFormatButton() {
    final InvitationsController invitations = _ensureInvitations();
    return SegmentedButton<InvitationExportFormat>(
      showSelectedIcon: false,
      style: const ButtonStyle(visualDensity: VisualDensity.compact),
      segments: <ButtonSegment<InvitationExportFormat>>[
        for (final InvitationExportFormat format
            in InvitationExportFormat.values)
          ButtonSegment<InvitationExportFormat>(
            value: format,
            label: Text(switch (format) {
              InvitationExportFormat.png => 'PNG',
              InvitationExportFormat.pdf => 'PDF',
              InvitationExportFormat.both => 'PDF + PNG',
            }),
          ),
      ],
      selected: <InvitationExportFormat>{invitations.format},
      onSelectionChanged: (Set<InvitationExportFormat> selection) {
        if (selection.isEmpty) return;
        invitations.setFormat(selection.first);
        // الشريط لا يستمع إلى محرّك الدعوات، فنُحدّث أنفسنا ليعكس القيمة،
        // ومحتوى المضمر يستمع إلى محرّكه فيتحدّث من ذات الإشعار.
        setState(() {});
      },
    );
  }

  // ==========================================================================
  //  الخطوات
  // ==========================================================================
  Widget _templateStep() {
    return AnimatedBuilder(
      animation: _library,
      builder: (BuildContext context, Widget? _) {
        final String activeTemplate = _selectedTemplateTitle ??
            _controller.templateTitle ??
            _kindLabel(_controller.kind);
        return _Card(
          icon: Icons.school_outlined,
          title: context.l10n?.bpStepTemplate ?? '1) القالب',
          subtitle: _controller.document == null
              ? context.l10n?.bpLoadingSampleTemplate ?? 'جارٍ تحميل القالب النموذجي…'
              : '${context.l10n?.bpTemplateInfo(activeTemplate) ?? 'القالب: $activeTemplate • الحقول المطلوبة:'} '
                  '${_controller.availableFields.length}',
          // تحذير صريح: إمّا قالب بلا حقول `{{...}}` إطلاقاً، أو قالب فيه حقول
          // لكن بلا حقل اسم (فيُربط عمود الاسم بحقل تاريخ/رقم خطأً).
          warning: _templateWarning(),
          // ملاحظة: مفتاح «شهادة/عقد/دعوة» صار في شريط الاختيار أعلى الخطوات،
          // فبقيت هذه البطاقة لما هي من اختياراته: القالب نفسه ومنتصف قوالب
          // المستخدم.
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _userTemplatePicker(),
            ],
          ),
        );
      },
    );
  }

  /// منتقي قوالب المستخدم (المحلية والسحابية) بجانب القوالب النموذجية.
  ///
  /// اختيار قالب هنا يستدعي [BatchProcessorController.useDocument] فيُستخرج
  /// نطاق حقوله (`{{...}}`) تلقائياً وتُربط أعمدته بذكاء كما في القوالب النموذجية.
  Widget _userTemplatePicker() {
    final List<TemplateLibraryEntry> mine = _userTemplates();
    final bool hasSelected = _selectedTemplateId != null &&
        mine.any((TemplateLibraryEntry e) => e.id == _selectedTemplateId);
    final Color hintColor = Theme.of(context).colorScheme.onSurfaceVariant;

    if (mine.isEmpty) {
      return Row(
        children: <Widget>[
          Icon(Icons.bookmark_border_rounded, size: 15, color: hintColor),
          const SizedBox(width: AppTheme.space8),
          Expanded(
            child: Text(
              _library.isBusy
                  ? context.l10n?.bpLoadingTemplates ?? 'جارٍ تحميل قوالبك…'
                  : context.l10n?.bpNoTemplates ??
                      'لا توجد قوالب محفوظة بعد — أنشئ قالباً في المحرّر أو '
                          'استورده من مكتبة القوالب ليظهر هنا.',
              style: TextStyle(fontSize: 11.5, color: hintColor),
            ),
          ),
        ],
      );
    }

    return Row(
      children: <Widget>[
        Icon(
          Icons.bookmark_rounded,
          size: 16,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: AppTheme.space8),
        Expanded(
          child: DropdownButtonFormField<String>(
            // مفتاح يعتمد على الاختيار: يُعيد تهيئة الحقل عند تغيّر القالب.
            key: ValueKey<String>(
              'batch-user-template-${_selectedTemplateId ?? ''}-${mine.length}',
            ),
            initialValue: hasSelected ? _selectedTemplateId : '',
            isDense: true,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: context.l10n?.bpTemplateFromMine ?? 'قالب من قوالبي',
              isDense: true,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            ),
            items: <DropdownMenuItem<String>>[
              DropdownMenuItem<String>(
                value: '',
                child: Text(
                  context.l10n?.bpSampleTemplatesHeader ?? '— القوالب النموذجية —',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              for (final TemplateLibraryEntry entry in mine)
                DropdownMenuItem<String>(
                  value: entry.id,
                  child: Text(
                    context.l10n?.bpTemplateEntry(
                          entry.title,
                          entry.isCloud
                              ? context.l10n?.bpSourceCloud ?? 'سحابي'
                              : context.l10n?.bpSourceLocal ?? 'محلي',
                        ) ??
                        '${entry.title}  •  ${entry.isCloud ? 'سحابي' : 'محلي'}',
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (String? value) {
              if (value == null) return;
              if (value.isEmpty) {
                _applyDefaultTemplate(_controller.kind);
                return;
              }
              final TemplateLibraryEntry entry = mine.firstWhere(
                (TemplateLibraryEntry e) => e.id == value,
              );
              _applyUserTemplate(entry);
            },
          ),
        ),
      ],
    );
  }

  Widget _fileStep() {
    final SheetData sheet = _controller.sheet;
    final String? fileName = _controller.fileName;

    return _Card(
      icon: Icons.upload_file_outlined,
      title: context.l10n?.bpStepDataFile ?? '2) ملف البيانات',
      subtitle: _controller.loadingFile
          ? context.l10n?.bpReadingFile ?? 'جارٍ قراءة الملف…'
          : fileName == null
              ? '${context.l10n?.bpNoFileChosen ?? 'لم يُختَر ملف بعد — الصيغ المدعومة:'} '
                  '${SheetReaders.supportedLabel}'
              : '${context.l10n?.bpFileSummary(fileName, sheet.rowCount, sheet.columnCount) ?? '$fileName — ${sheet.rowCount} صفاً، ${sheet.columnCount} عموداً'}'
                  '${sheet.sheetName.isEmpty ? '' : context.l10n?.bpSheetSuffix(sheet.sheetName) ?? ' (ورقة: ${sheet.sheetName})'}',
      // الأزرار داخل صف/التفاف تحتاج `minimumSize` منتهياً: الثيم العام يضبط
      // العرض الأدنى على ما لا نهاية (Size.fromHeight)، وهو صحيح داخل عمود
      // ممتدّ لكنه غير صالح داخل صف.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Wrap(
            spacing: AppTheme.space8,
            runSpacing: AppTheme.space8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              FilledButton.icon(
                onPressed: _controller.loadingFile ? null : _pickFile,
                icon: const Icon(Icons.folder_open_rounded, size: 18),
                label: Text(context.l10n?.bpChooseFile ?? 'اختيار ملف'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(150, 44),
                ),
              ),
              if (fileName != null)
                OutlinedButton.icon(
                  onPressed: _controller.clearFile,
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: Text(context.l10n?.bpRemove ?? 'إزالة'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(100, 44),
                  ),
                ),
            ],
          ),
          if (_controller.loadingFile) ...<Widget>[
            const SizedBox(height: AppTheme.space12),
            const LinearProgressIndicator(),
          ],
          if (_controller.hasSheetChoice) ...<Widget>[
            const SizedBox(height: AppTheme.space12),
            _sheetPicker(),
          ],
          if (_controller.canChooseHeaderRow && sheet.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppTheme.space12),
            _headerRowPicker(),
          ],
        ],
      ),
    );
  }

  /// منتقي «صف العناوين» — يسمح بتحديد الصف الذي تبدأ منه العناوين عندما
  /// يحوي الملف عنواناً أو أسطراً تعريفية قبلها.
  Widget _headerRowPicker() {
    final List<List<String>> samples = _controller.rowSamples;
    // قيمة حارسة للمدخل «تلقائي» لأن `null` في القائمة يتعارض مع «بلا اختيار».
    const int autoValue = -1;
    final int selected = _controller.headerRowIndex ?? autoValue;

    return Row(
      children: <Widget>[
        Icon(
          Icons.format_list_numbered_rounded,
          size: 16,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: AppTheme.space8),
        Expanded(
          child: DropdownButtonFormField<int>(
            // مفتاح يعتمد على الاختيار: يُعيد تهيئة الحقل عند تغيّر القيمة
            // (FormField يحتفظ بحالته ولا يتحدّث بتغيّر initialValue وحده).
            key: ValueKey<int>(selected),
            initialValue: selected,
            isDense: true,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: context.l10n?.bpHeaderRow ?? 'صف العناوين',
              isDense: true,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            ),
            selectedItemBuilder: (BuildContext context) => <Widget>[
              DropdownMenuItem<int>(
                value: autoValue,
                child: Text(
                  context.l10n?.bpAutoRow(
                        _controller.effectiveHeaderRowIndex + 1,
                      ) ??
                      'تلقائي (الصف ${_controller.effectiveHeaderRowIndex + 1})',
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              for (int i = 0; i < samples.length; i++)
                DropdownMenuItem<int>(
                  value: i,
                  child: Text(
                    context.l10n?.bpRow(i + 1) ?? 'الصف ${i + 1}',
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            items: <DropdownMenuItem<int>>[
              DropdownMenuItem<int>(
                value: autoValue,
                child: Text(
                  context.l10n?.bpAutoRowLong(
                        _controller.effectiveHeaderRowIndex + 1,
                      ) ??
                      'تلقائي — الصف ${_controller.effectiveHeaderRowIndex + 1}',
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              for (int i = 0; i < samples.length; i++)
                if (samples[i].any((String cell) => cell.isNotEmpty))
                  DropdownMenuItem<int>(
                    value: i,
                    child: Text(
                      context.l10n?.bpRowPreview(
                            i + 1,
                            _rowPreview(samples[i]),
                          ) ??
                          'الصف ${i + 1}: ${_rowPreview(samples[i])}',
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
            ],
            onChanged: _controller.loadingFile
                ? null
                : (int? value) {
                    if (value == null) return;
                    unawaited(_controller.setHeaderRowIndex(
                      value == autoValue ? null : value,
                    ));
                  },
          ),
        ),
      ],
    );
  }

  /// وصف مختصر لمحتوى صف مرشّح ليكون صف العناوين.
  String _rowPreview(List<String> row) {
    final List<String> filled =
        row.where((String cell) => cell.isNotEmpty).toList(growable: false);
    if (filled.isEmpty) return context.l10n?.bpEmptyRow ?? '(صف فارغ)';
    final String text = filled.take(4).join(' • ');
    return text.length > 48 ? '${text.substring(0, 48)}…' : text;
  }

  /// منتقي ورقة العمل — يظهر فقط عندما يحتوي المصنّف أكثر من ورقة.
  Widget _sheetPicker() {
    final List<String> sheets = _controller.sheetNames;
    final String current = _controller.sheet.sheetName;
    final String selected =
        sheets.contains(current) ? current : sheets.first;

    return Row(
      children: <Widget>[
        Icon(
          Icons.layers_outlined,
          size: 16,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: AppTheme.space8),
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: selected,
            isDense: true,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: context.l10n?.bpWorksheet ?? 'ورقة العمل',
              isDense: true,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            ),
            items: <DropdownMenuItem<String>>[
              for (final String name in sheets)
                DropdownMenuItem<String>(
                  value: name,
                  child: Text(
                    name,
                    style: const TextStyle(fontSize: 12.5),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: _controller.loadingFile
                ? null
                : (String? value) {
                    if (value != null) {
                      unawaited(_controller.selectSheet(value));
                    }
                  },
          ),
        ),
      ],
    );
  }

  Widget _mappingStep() {
    final SheetData sheet = _controller.sheet;
    final TextTheme text = Theme.of(context).textTheme;

    return _Card(
      icon: Icons.alt_route_rounded,
      title: context.l10n?.bpStepMapping ?? '3) ربط الأعمدة بالحقول',
      subtitle: sheet.isEmpty
          ? context.l10n?.bpChooseFileFirst ?? 'اختر ملفاً أولاً ليظهر جدول الربط.'
          : _controller.availableFields.isEmpty
                  && _controller.document != null
              ? context.l10n?.bpNoDynamicFields ?? 'لا حقول ديناميكية في القالب الحالي.'
              : context.l10n?.bpMappedCount(
                    _controller.mapping.mappedCount,
                    _controller.visibleColumns.length,
                  ) ??
                  'مرتبط ${_controller.mapping.mappedCount} من '
                      '${_controller.visibleColumns.length} عموداً',
      child: sheet.isEmpty
          ? Text(
              context.l10n?.bpAutoMapHint ?? 'بعد اختيار الملف سيُقترح ربط تلقائي ذكي، ويمكنك تعديل كل عمود.',
              style: text.bodySmall,
            )
          : _controller.availableFields.isEmpty
              ? Text(
                  context.l10n?.bpNoFieldsHelp ??
                      'القالب المختار لا يحتوي حقولاً ديناميكية `{{...}}`، فلا شيء '
                          'ليُربط بأعمدة الملف. افتح القالب في المحرّر وأدرج حقل '
                          '«حقل ديناميكي» في خانة الاسم (مثل `{{اسم_المتدرب}}`) ثم '
                          'احفظ القالب ثم أعد المحاولة.',
                  style: text.bodySmall,
                )
              : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Wrap(
                  spacing: AppTheme.space8,
                  runSpacing: AppTheme.space4,
                  children: <Widget>[
                    TextButton.icon(
                      onPressed: _controller.autoMap,
                      icon: const Icon(Icons.auto_fix_high_rounded, size: 16),
                      label: Text(context.l10n?.bpAutoMap ?? 'ربط تلقائي'),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(130, 40),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _controller.clearMapping,
                      icon: const Icon(Icons.link_off_rounded, size: 16),
                      label: Text(context.l10n?.bpClearMapping ?? 'مسح الربط'),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(120, 40),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.space4),
                if (!_controller.hasNameField &&
                    _controller.templateHasDynamicFields)
                  _Note(
                    color: AppColors.warning,
                    soft: AppColors.warningSoft,
                    icon: Icons.person_search_rounded,
                    text: context.l10n?.bpNameFieldWarning ??
                        'هذا القالب لا يحتوي على حقل اسم ديناميكي '
                            '{{اسم_المتدرب}} — لا تربط عمود الاسم بحقل تاريخ أو رقم '
                            'إشعار، فقد يُطبع الاسم في مكانه الخطأ.\n'
                            'اختر المفتاح {{اسم_المتدرب}} من قائمة العمود، أو '
                            'حوّل نص الاسم الثابت من المحرّر إلى حقل ديناميكي.',
                  ),
                // ربط سريع بضغطة واحدة: النصوص الثابتة التي تبدو أسماءً — هذه
                // هي اللحظة التي كان المستخدم يعلق فيها بلا حقل اسم فيُجبر على
                // ربط عمود الاسم بحقل تاريخ. الضغطة هنا تحوّل النص إلى
                // `{{اسم_المتدرب}}` وتعيد الربط التلقائي فوراً.
                if (!_controller.hasNameField)
                  for (final NameTextFieldCandidate candidate
                      in _controller.nameFieldCandidates) ...<Widget>[
                  const SizedBox(height: AppTheme.space4),
                  Text(
                    context.l10n?.bpStaticNameHints(candidate.preview) ??
                        'نصّ ثابت يشبه الاسم: «${candidate.preview}» — لا يستبدله أي '
                            'حقل ديناميكي.',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  OutlinedButton.icon(
                    onPressed: () =>
                        unawaited(_convertTextToField(candidate.index)),
                    icon: const Icon(Icons.add_link_rounded, size: 16),
                    label: Text(
                      context.l10n?.bpConvertToNameField ??
                          'حوّله إلى حقل {{اسم_المتدرب}}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 38),
                    ),
                  ),
                ],
                const SizedBox(height: AppTheme.space4),
                for (final int column in _controller.visibleColumns)
                  _mappingRow(column),
                if (_controller.mapping.hasDuplicates)
                  _Note(
                    color: AppColors.danger,
                    soft: AppColors.dangerSoft,
                    icon: Icons.error_outline_rounded,
                    text: context.l10n?.bpDuplicateField(
                          _controller.mapping.duplicateFields.first,
                        ) ??
                        'الحقل «${_controller.mapping.duplicateFields.first}» '
                            'مرتبط بأكثر من عمود. اجعل كل حقل بعمود واحد.',
                  ),
                if (_controller.unmappedColumnCount > 0)
                  _Note(
                    color: AppColors.warning,
                    soft: AppColors.warningSoft,
                    icon: Icons.info_outline_rounded,
                    text: context.l10n?.bpUnmappedColumns(
                          _controller.unmappedColumnCount,
                        ) ??
                        '${_controller.unmappedColumnCount} عموداً بلا ربط — '
                            'لن تُستخدم بياناته في الشهادات.',
                  ),
              ],
            ),
    );
  }

  Widget _mappingRow(int column) {
    final SheetData sheet = _controller.sheet;
    final String header = column < sheet.headers.length
        ? sheet.headers[column]
        : context.l10n?.bpColumn(column + 1) ?? 'عمود ${column + 1}';
    final String preview = sheet.rowCount == 0
        ? ''
        : sheet.rowAt(0).cellAt(column);
    final String? field = _controller.mapping.fieldFor(column);
    final List<String> fields = <String>[
      '',
      ..._controller.availableFields,
      if (field != null && !_controller.availableFields.contains(field)) field,
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space8),
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  header,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  preview.isEmpty
                      ? context.l10n?.bpEmptyCell ?? '(فارغ)'
                      : preview,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_back_rounded,
              size: 16, color: AppColors.inkDisabled),
          const SizedBox(width: AppTheme.space8),
          Expanded(
            flex: 4,
            child: DropdownButtonFormField<String>(
              initialValue: field ?? '',
              isDense: true,
              isExpanded: true,
              style: TextStyle(
                fontSize: 12.5,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              ),
              // القائمة تعرض الحقل مع قيمته التجريبية، والزر المغلق يعرض الحقل
              // وحده حتى لا يتمدّد الصف خارج العرض المتاح.
              selectedItemBuilder: (BuildContext context) => <Widget>[
                for (final String key in fields)
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      key.isEmpty
                          ? context.l10n?.bpUnmapped ?? '— غير مربوط —'
                          : key,
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              items: <DropdownMenuItem<String>>[
                for (final String key in fields)
                  DropdownMenuItem<String>(
                    value: key,
                    child: Text(
                      key.isEmpty
                          ? context.l10n?.bpUnmapped ?? '— غير مربوط —'
                          : '$key  •  ${_controller.sampleOf(key)}',
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (String? value) =>
                  _controller.setMapping(column, value),
            ),
          ),
        ],
      ),
    );
  }

  Widget _optionsStep() {
    final SheetData sheet = _controller.sheet;
    final TextTheme text = Theme.of(context).textTheme;

    return _Card(
      icon: Icons.rule_folder_outlined,
      title: context.l10n?.bpStepMissing ?? '4) الخلايا الفارغة والبيانات الناقصة',
      subtitle: _controller.policy.descriptionAr,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          RadioGroup<MissingCellPolicy>(
            groupValue: _controller.policy,
            onChanged: (MissingCellPolicy? value) {
              if (value != null) _controller.setPolicy(value);
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                for (final MissingCellPolicy policy
                    in MissingCellPolicy.values)
                  RadioListTile<MissingCellPolicy>(
                    value: policy,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      policy.labelAr,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
              ],
            ),
          ),
          if (sheet.notes.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppTheme.space8),
            for (final String note in sheet.notes)
              _Note(
                color: AppColors.warning,
                soft: AppColors.warningSoft,
                icon: Icons.report_gmailerrorred_rounded,
                text: note,
              ),
          ],
          if (sheet.isEmpty)
            Text(context.l10n?.bpNoNotes ?? 'لا ملاحظات قبل اختيار الملف.', style: text.bodySmall),
        ],
      ),
    );
  }

  /// تسمية الجنس المعروضة في قائمة الاختيار اليدوي.
  String _genderLabel(Gender gender) => gender.isFemale
      ? (context.l10n?.genderFemale ?? 'أنثى')
      : (context.l10n?.genderMale ?? 'ذكر');

  /// يفتح مربّع حوار لتعديل اسم صف في جدول المراجعة المسبقة.
  ///
  /// الاسم المُصحَّح يُحفظ كتصحيح للصف ([BatchProcessorController.setRowName])،
  /// فيُعاد كشف الجنس منه ويُطبع في المخرجات بدل قيمة الملف الأصلية. الفراغ
  /// يلغي التصحيح ويعود لاسم الملف.
  Future<void> _editRowName(int rowNumber, String? current) async {
    final String? result = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) => _NameEditDialog(
        rowNumber: rowNumber,
        initialName: current ?? '',
      ),
    );
    if (result == null) return;
    _controller.setRowName(rowNumber, result);
  }

  /// جدول المراجعة المسبقة للتذكير/التأنيث.
  ///
  /// يعرض صفوف الملف بأسمائها وبالجنس المكتشَف تلقائياً، مع قائمة اختيار يدوية
  /// لكل صف للحالات الحدّية (أسماء غامضة أو أجنبية) — قبل الطباعة لا بعدها.
  /// والنقر على الاسم يفتح تعديلاً مباشراً يعيد كشف الجنس من الاسم الجديد.
  Widget _genderReviewStep() {
    final List<GenderReviewRow> rows = _controller.genderReviewRows;
    final TextTheme text = Theme.of(context).textTheme;
    final String unknown = context.l10n?.bpGenderUnknownName ?? '—';

    return _Card(
      icon: Icons.people_alt_outlined,
      title: context.l10n?.bpGenderReviewTitle ?? 'مراجعة الجنس (تذكير/تأنيث)',
      subtitle: context.l10n?.bpGenderReviewSubtitle ??
          'الجنس مُكتشف من الاسم أو من عمود «الجنس» — صحّح أي حالة حدّية قبل الطباعة.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              SizedBox(
                width: 44,
                child: Text(
                  context.l10n?.bpGenderRow ?? 'الصف',
                  style: text.labelSmall,
                ),
              ),
              Expanded(
                child: Text(
                  context.l10n?.bpGenderNameColumn ?? 'الاسم',
                  style: text.labelSmall,
                ),
              ),
              SizedBox(
                width: 110,
                child: Text(
                  context.l10n?.bpGenderEffective ?? 'المطبَّق',
                  style: text.labelSmall,
                  textAlign: TextAlign.center,
                ),
              ),
              if (_controller.hasReviewOverrides)
                Tooltip(
                  message:
                      context.l10n?.bpGenderClearOverrides ?? 'إلغاء التصحيحات',
                  child: IconButton(
                    key: const ValueKey<String>('bp-gender-clear'),
                    iconSize: 18,
                    visualDensity: VisualDensity.compact,
                    onPressed: _controller.clearReviewOverrides,
                    icon: const Icon(Icons.restart_alt_rounded),
                  ),
                )
              else
                const SizedBox(width: 40),
            ],
          ),
          const SizedBox(height: AppTheme.space4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 260),
            child: ListView(
              shrinkWrap: true,
              children: <Widget>[
                for (final GenderReviewRow row in rows)
                  Padding(
                    key: ValueKey<String>('bp-gender-row-${row.rowNumber}'),
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: <Widget>[
                        SizedBox(
                          width: 44,
                          child: Text('${row.rowNumber}', style: text.bodySmall),
                        ),
                        Expanded(
                          child: Row(
                            children: <Widget>[
                              Flexible(
                                child: Tooltip(
                                  message: context.l10n?.bpGenderEditName ??
                                      'تعديل الاسم',
                                  child: InkWell(
                                    key: ValueKey<String>(
                                      'bp-gender-name-${row.rowNumber}',
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                    onTap: () =>
                                        _editRowName(row.rowNumber, row.name),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 4,
                                        horizontal: 2,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: <Widget>[
                                          Flexible(
                                            child: Text(
                                              row.name?.trim().isNotEmpty ==
                                                      true
                                                  ? row.name!
                                                  : unknown,
                                              style: text.bodySmall,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              textDirection: TextDirection.rtl,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(
                                            Icons.edit_outlined,
                                            size: 13,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .outline,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              if (row.overridden) ...<Widget>[
                                const SizedBox(width: 2),
                                Tooltip(
                                  message: context.l10n?.bpGenderOverridden ??
                                      'مُصحَّح يدوياً',
                                  child: Icon(
                                    Icons.edit_rounded,
                                    size: 13,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 110,
                          child: DropdownButton<Gender>(
                            key: ValueKey<String>(
                              'bp-gender-select-${row.rowNumber}',
                            ),
                            value: row.effective,
                            isExpanded: true,
                            isDense: true,
                            underline: const SizedBox.shrink(),
                            style: text.bodySmall,
                            items: <DropdownMenuItem<Gender>>[
                              for (final Gender gender in Gender.values)
                                DropdownMenuItem<Gender>(
                                  value: gender,
                                  child: Text(_genderLabel(gender)),
                                ),
                            ],
                            onChanged: (Gender? gender) =>
                                _controller.setRowGender(row.rowNumber, gender),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// شريط ثابت أسفل الترويسة يعرض مجلد المخرجات وزرّ فتحه.
  Widget _outputBanner() {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    final String directory = _outputDirectory!;
    return Container(
      key: const ValueKey<String>('bp-output-banner'),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space20,
        vertical: AppTheme.space8,
      ),
      color: scheme.success.withValues(alpha: 0.12),
      child: Row(
        children: <Widget>[
          Icon(Icons.folder_outlined, size: 16, color: scheme.success),
          const SizedBox(width: 8),
          Text(
            context.l10n?.bpOutputPathLabel ?? 'المجلد المختار',
            style: text.labelSmall,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              directory,
              textDirection: TextDirection.ltr,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.bodySmall,
            ),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            key: const ValueKey<String>('bp-open-folder-banner'),
            onPressed: _openOutputFolder,
            icon: const Icon(Icons.folder_open_rounded, size: 16),
            label: Text(context.l10n?.bpOpenFolder ?? 'فتح المجلد'),
          ),
        ],
      ),
    );
  }

  /// بطاقة «أين حُفظ الملف» مع زرّ فتح المجلد — تظهر بعد التوليد وتبقى ما دام
  /// المجلد معروفاً.
  Widget _outputCard({required bool saved}) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    // في الوضع المنفصل يُعرض مجلد الملفات الفرعي هو «المحفوظ» — وهو ما يفتحه
    // زر فتح المجلد أيضاً.
    final String path =
        _savedFilePath ?? _savedFolderPath ?? _outputDirectory ?? '';
    return Container(
      key: const ValueKey<String>('bp-output-saved-card'),
      padding: const EdgeInsets.all(AppTheme.space12),
      decoration: BoxDecoration(
        color: scheme.success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.success),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                saved
                    ? Icons.check_circle_outline_rounded
                    : Icons.folder_outlined,
                size: 18,
                color: scheme.success,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  saved
                      ? (_savedFolderPath != null
                            ? (context.l10n?.bpOutputSavedFolderTitle ??
                                'حُفظت الملفات في مجلد مخصص')
                            : (context.l10n?.bpOutputSavedTitle ??
                                'تم حفظ ملف الـ PDF'))
                      : (context.l10n?.bpOutputPathLabel ?? 'المجلد المختار'),
                  style: text.titleSmall?.copyWith(color: scheme.success),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space4),
          SelectableText(
            path,
            key: const ValueKey<String>('bp-output-saved-path'),
            textDirection: TextDirection.ltr,
            style: text.bodySmall,
          ),
          const SizedBox(height: AppTheme.space8),
          FilledButton.icon(
            key: const ValueKey<String>('bp-open-folder'),
            onPressed: _openOutputFolder,
            icon: const Icon(Icons.folder_open_rounded, size: 18),
            label: Text(context.l10n?.bpOpenFolder ?? 'فتح المجلد'),
          ),
        ],
      ),
    );
  }

  Widget _generateStep() {
    final BulkGenerationReport? report = _controller.report;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    final String? errorText = _errorText();

    return _Card(
      icon: Icons.play_circle_outline_rounded,
      title: context.l10n?.bpStepGenerate ?? '5) التوليد',
      subtitle: _controller.busy
          ? context.l10n?.bpGenerating(_controller.progressLabelAr) ??
              'جارٍ التوليد… ${_controller.progressLabelAr}'
          : context.l10n?.bpGenerateHint ?? 'ملف PDF واحد، صفحة لكل سجل مُصدر.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (_controller.busy) ...<Widget>[
            LinearProgressIndicator(value: _controller.progress),
            const SizedBox(height: AppTheme.space8),
          ],
          if (errorText != null)
            _Note(
              color: AppColors.danger,
              soft: AppColors.dangerSoft,
              icon: Icons.error_outline_rounded,
              text: errorText,
            ),
          // شرح سبب تعطيل الزر: الغموض هنا هو ما دفع المستخدم لربط عمود
          // الاسم بحقل تاريخ «ليتفعّل الزر».
          if (!_controller.canGenerate && !_controller.busy)
            _Note(
              color: AppColors.warning,
              soft: AppColors.warningSoft,
              icon: Icons.info_outline_rounded,
              text: _controller.sheet.isEmpty
                  ? context.l10n?.bpGeneratePickFile ?? 'اختر ملف بيانات أولاً ليُفعَّل التوليد.'
                  : _controller.mapping.isNotEmpty
                      ? context.l10n?.bpMappingInvalid ?? 'الربط غير صالح — لا تُربط الحقول الحقل نفسه بعمودين.'
                      : context.l10n?.bpMapAtLeastOne ??
                          'اربط عموداً واحداً على الأقل بحقل من القالب ليُفعَّل '
                              'التوليد.',
            ),
          FilledButton.icon(
            onPressed: _controller.canGenerate ? _generate : null,
            icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
            label: Text(
              report == null ? context.l10n?.bpGenerateCertificates ?? 'توليد الشهادات' : context.l10n?.bpRegenerate ?? 'إعادة التوليد',
            ),
          ),
          if (report != null) ...<Widget>[
            const SizedBox(height: AppTheme.space12),
            Wrap(
              spacing: AppTheme.space8,
              runSpacing: AppTheme.space8,
              children: <Widget>[
                _Stat(
                  label: context.l10n?.bpStatGenerated ?? 'مُصدرة',
                  value: '${report.generatedCount}',
                  color: scheme.success,
                ),
                _Stat(
                  label: context.l10n?.bpStatSkipped ?? 'متخطّاة',
                  value: '${report.skippedCount}',
                  color: report.skippedCount == 0
                      ? scheme.onSurfaceVariant
                      : scheme.warning,
                ),
                _Stat(
                  label: context.l10n?.bpStatPages ?? 'صفحات',
                  value: '${report.pageCount}',
                  color: scheme.primary,
                ),
                _Stat(
                  label: context.l10n?.bpStatSize ?? 'الحجم',
                  value: context.l10n?.bpKilobytes(
                        (report.byteSize / 1024).toStringAsFixed(0),
                      ) ??
                      '${(report.byteSize / 1024).toStringAsFixed(0)} ك.ب',
                  color: scheme.onSurfaceVariant,
                ),
                _Stat(
                  label: context.l10n?.bpStatTime ?? 'الزمن',
                  value: context.l10n?.bpMilliseconds(
                        report.elapsed.inMilliseconds,
                      ) ??
                      '${report.elapsed.inMilliseconds} م.ث',
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
            const SizedBox(height: AppTheme.space8),
            Text(
              context.l10n?.bpCompletion(
                    (report.successRate * 100).round(),
                    report.totalRows,
                  ) ??
                  'اكتمال ${(report.successRate * 100).round()}% من '
                      '${report.totalRows} صفاً.',
              style: text.bodySmall,
            ),
            if (_outputDirectory != null) ...<Widget>[
              const SizedBox(height: AppTheme.space12),
              _outputCard(
                saved: _savedFilePath != null || _savedFolderPath != null,
              ),
            ],
            const SizedBox(height: AppTheme.space8),
            Row(
              children: <Widget>[
                OutlinedButton.icon(
                  onPressed: report.hasOutput ? _print : null,
                  icon: const Icon(Icons.print_outlined, size: 18),
                  label: Text(context.l10n?.commonPrint ?? 'طباعة'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(120, 44),
                  ),
                ),
                const SizedBox(width: AppTheme.space8),
                FilledButton.icon(
                  onPressed: report.hasOutput ? _export : null,
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: Text(context.l10n?.commonExportPdf ?? 'تصدير PDF'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(150, 44),
                  ),
                ),
              ],
            ),
            if (report.warnings.isNotEmpty) ...<Widget>[
              const SizedBox(height: AppTheme.space8),
              for (final String warning in report.warnings)
                _Note(
                  color: AppColors.warning,
                  soft: AppColors.warningSoft,
                  icon: Icons.warning_amber_rounded,
                  text: warning,
                ),
            ],
            if (report.skipped.isNotEmpty) ...<Widget>[
              const SizedBox(height: AppTheme.space8),
              Text(context.l10n?.bpSkippedRows ?? 'صفوف لم تُصدر:', style: text.titleSmall),
              for (final BulkRowResult row in report.skipped)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    context.l10n?.bpRowSkipReason(
                          row.rowNumber,
                          row.skipReasonAr ?? '',
                        ) ??
                        'صف ${row.rowNumber}: ${row.skipReasonAr ?? ''}',
                    style: text.bodySmall?.copyWith(color: scheme.danger),
                  ),
                ),
            ],
          ],
        ],
      ),
    );
  }

  // ==========================================================================
  //  المعاينة
  // ==========================================================================
  Widget _previewArea() {
    final Uint8List? bytes = _controller.report?.combinedPdf;
    if (bytes != null) {
      return PdfPreview(
        build: (PdfPageFormat format) async => bytes,
        allowPrinting: false,
        allowSharing: false,
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
      );
    }

    // قبل التوليد: لوحة تعيين بالنقر على عناصر القالب (تعيين صريح لا تخميني).
    final TemplateDocument? document = _controller.document;
    if (document != null) return _interactiveTemplatePanel(document);

    return _previewPlaceholder();
  }

  Widget _previewPlaceholder() {
    final TextTheme text = Theme.of(context).textTheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.picture_as_pdf_outlined,
                size: 40, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: AppTheme.space12),
            Text(context.l10n?.bpPreviewHere ?? 'المعاينة تظهر هنا', style: text.titleMedium),
            const SizedBox(height: AppTheme.space8),
            Text(
              context.l10n?.bpPreviewHint ??
                  'اختر ملف البيانات، اضبط الربط، ثم اضغط «توليد الشهادات» — '
                      'سترى أول صفحة من الملف الناتج هنا مباشرة.',
              style: text.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// لوحة تعيين تفاعلية: كل عنصر نصي في القالب صف قابل للنقر.
  ///
  /// النقر يفتح منتقي حقل ديناميكي يحوّل **هذا العنصر وحده** — وهو جوهر
  /// «التعيين الصريح» بدل التخمين التلقائي الذي قد يبدّل التاريخ أو اسم المدير.
  /// بقية العناصر تبقى مقفلة ولا تُمسّ إطلاقاً.
  Widget _interactiveTemplatePanel(TemplateDocument document) {
    final TextTheme text = Theme.of(context).textTheme;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final List<MapEntry<int, TextElement>> texts = <MapEntry<int, TextElement>>[
      for (int i = 0; i < document.elements.length; i++)
        if (document.elements[i] is TextElement)
          MapEntry<int, TextElement>(i, document.elements[i] as TextElement),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.touch_app_outlined, size: 20, color: scheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(context.l10n?.bpAssignByTapTitle ?? 'تعيين الحقول بالنقر', style: text.titleMedium),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n?.bpAssignByTapBody ??
                'انقر أي نص في القالب لتعيينه إلى حقل ديناميكي بنفسك. لن يُمسّ أي '
                    'عنصر آخر — لا التاريخ ولا اسم المدير ولا أي نص ثابت.',
            style: text.bodySmall,
          ),
          const SizedBox(height: AppTheme.space12),
          if (texts.isEmpty)
            Text(context.l10n?.bpNoTexts ?? 'لا نصوص في هذا القالب.', style: text.bodySmall)
          else
            for (final MapEntry<int, TextElement> entry in texts)
              _assignableElementRow(entry.key, entry.value),
        ],
      ),
    );
  }

  /// صفّ عنصر نصي واحد قابل للتعيين بالنقر.
  Widget _assignableElementRow(int index, TextElement element) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool hasField = element.hasDynamicFields;
    final String preview = element.text.trim().isEmpty
        ? context.l10n?.bpEmptyText ?? '(نص فارغ)'
        : element.text.trim();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space8),
      child: Material(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: InkWell(
          onTap: () => unawaited(_assignFieldToElement(index)),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: Container(
            padding: const EdgeInsets.all(AppTheme.space12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: scheme.outline),
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  hasField
                      ? Icons.data_object_rounded
                      : Icons.text_fields_rounded,
                  size: 18,
                  color: hasField ? scheme.primary : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        preview,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12.5),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasField
                            ? context.l10n?.bpDynamicFieldTap ??
                                'حقل ديناميكي — انقر لتغييره'
                            : context.l10n?.bpStaticTextTap ??
                                'نص ثابت — انقر للتعيين',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => unawaited(_assignFieldToElement(index)),
                  child: Text(
                    context.l10n?.bpAssignField ?? 'تعيين حقل',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
//  عناصر واجهة صغيرة
// ============================================================================

/// خيارات التصدير المؤكَّدة من [_OutputOptionsDialog]: المجلد واسم الملف.
class _OutputOptions {
  const _OutputOptions({
    required this.directory,
    required this.fileName,
    required this.mode,
  });

  /// المجلد المختار (قد يكون `null` على الويب حيث لا نظام ملفات).
  final String? directory;

  /// اسم الملف الذي كتبه المستخدم — منقّى من المحارف الممنوعة (بلا امتداد).
  final String fileName;

  /// نمط الحفظ: ملف مجمع مباشرة، أو مجلد فرعي بملف لكل شخص.
  final BulkOutputMode mode;
}

/// حوار وجهة حفظ الشهادات قبل التوليد: المجلد **واسم الملف**.
///
/// يعرض المجلد الحالي (الافتراضي أو المختار سابقاً) واسم الملف المقترح، ويسمح
/// بتغييرهما. إغلاق منتقي المجلدات بلا اختيار يُبقي المجلد الحالي — وهو البديل
/// المطلوب (التنزيلات/المستندات).
class _OutputOptionsDialog extends StatefulWidget {
  const _OutputOptionsDialog({
    required this.initialDirectory,
    required this.initialFileName,
    required this.initialMode,
    required this.onPickDirectory,
  });

  /// المجلد المعروض ابتداءً (قد يكون `null` على منصة بلا نظام ملفات).
  final String? initialDirectory;

  /// اسم الملف المعروض ابتداءً (الافتراضي المشتقّ من القالب أو آخر إدخال).
  final String initialFileName;

  /// النمط المعروض ابتداءً (آخر اختيار للمستخدم أو «ملف مجمع»).
  final BulkOutputMode initialMode;

  /// يفتح منتقي المجلدات الأصلي ويعيد المسار المختار (أو `null`).
  final Future<String?> Function() onPickDirectory;

  @override
  State<_OutputOptionsDialog> createState() => _OutputOptionsDialogState();
}

class _OutputOptionsDialogState extends State<_OutputOptionsDialog> {
  String? _directory;
  bool _picking = false;
  late BulkOutputMode _mode = widget.initialMode;
  late final TextEditingController _name =
      TextEditingController(text: widget.initialFileName);

  @override
  void initState() {
    super.initState();
    _directory = widget.initialDirectory;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    setState(() => _picking = true);
    final String? picked = await widget.onPickDirectory();
    if (!mounted) return;
    setState(() {
      _picking = false;
      if (picked != null && picked.trim().isNotEmpty) {
        _directory = picked.trim();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final String? directory = _directory;
    return AlertDialog(
      key: const ValueKey<String>('bp-output-dialog'),
      title: Text(context.l10n?.bpOutputTitle ?? 'وجهة حفظ الشهادات'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            context.l10n?.bpOutputHint ??
                'اختر المجلد الذي يُحفظ فيه ملف الـ PDF، أو ابدأ بالموقع الافتراضي.',
            style: text.bodySmall,
          ),
          const SizedBox(height: AppTheme.space12),
          Text(
            context.l10n?.bpOutputNameLabel ?? 'اسم ملف التصدير',
            style: text.labelSmall,
          ),
          const SizedBox(height: AppTheme.space4),
          TextField(
            key: const ValueKey<String>('bp-output-name'),
            controller: _name,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.deny(OutputFileName.invalidCharacters),
            ],
            decoration: InputDecoration(
              hintText: context.l10n?.bpOutputNameHint ??
                  'اكتب اسماً للملف بلا امتداد',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppTheme.space4),
          Text(
            '${context.l10n?.bpOutputNamePreviewLabel ?? 'سيُحفظ باسم'}: '
            '${OutputFileName.resolve(_name.text)}',
            key: const ValueKey<String>('bp-output-name-preview'),
            style: text.bodySmall,
            textDirection: TextDirection.rtl,
          ),
          // النمط لا معنى له بلا مجلد (الويب بلا نظام ملفات) — يظهر فقط إن
          // حُدد وجهة للحفظ.
          if (directory != null) ...<Widget>[
            const SizedBox(height: AppTheme.space12),
            SegmentedField<BulkOutputMode>(
              label: context.l10n?.bpOutputModeLabel ?? 'نمط الحفظ',
              value: _mode,
              options: BulkOutputMode.values,
              labelOf: (BulkOutputMode mode) => switch (mode) {
                BulkOutputMode.combined =>
                  context.l10n?.bpOutputModeCombined ?? mode.labelAr,
                BulkOutputMode.individual =>
                  context.l10n?.bpOutputModeIndividual ?? mode.labelAr,
              },
              // بلا أيقونة كي يظهر النص كاملاً في الخانة الضيّقة للحوار.
              onChanged: (BulkOutputMode mode) => setState(() => _mode = mode),
            ),
          ],
          const SizedBox(height: AppTheme.space12),
          Text(
            context.l10n?.bpOutputPathLabel ?? 'المجلد المختار',
            style: text.labelSmall,
          ),
          const SizedBox(height: AppTheme.space4),
          Container(
            key: const ValueKey<String>('bp-output-path'),
            padding: const EdgeInsets.all(AppTheme.space8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              directory ??
                  (context.l10n?.bpOutputNoFolder ??
                      'لم يُختَر مجلد — الطباعة والتصدير فقط.'),
              textDirection: directory == null
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              style: text.bodySmall,
            ),
          ),
          const SizedBox(height: AppTheme.space12),
          OutlinedButton.icon(
            key: const ValueKey<String>('bp-output-pick'),
            onPressed: _picking ? null : _pick,
            icon: const Icon(Icons.folder_open_rounded, size: 18),
            label: Text(context.l10n?.bpOutputPickFolder ?? 'اختيار مجلد…'),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          key: const ValueKey<String>('bp-output-cancel'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n?.editorCancel ?? 'إلغاء'),
        ),
        FilledButton(
          key: const ValueKey<String>('bp-output-confirm'),
          // المجلد قد يكون `null` (الويب) فيُتابع التوليد بلا حفظ على القرص،
          // وإغلاق الحوار نفسه يعيد `null` = إلغاء.
          onPressed: () => Navigator.of(context).pop(
            _OutputOptions(
              directory: _directory,
              fileName: OutputFileName.sanitize(_name.text),
              mode: _mode,
            ),
          ),
          child: Text(context.l10n?.bpOutputStart ?? 'بدء التوليد'),
        ),
      ],
    );
  }
}

/// حوار تعديل اسم صف واحد في جدول المراجعة المسبقة.
///
/// يملك `TextEditingController` الخاص به ويحرّره في [State.dispose]، فلا يُحرَّر
/// والودجة ما زالت مركّبة أثناء حركة إغلاق الحوار.
class _NameEditDialog extends StatefulWidget {
  const _NameEditDialog({required this.rowNumber, required this.initialName});

  final int rowNumber;
  final String initialName;

  @override
  State<_NameEditDialog> createState() => _NameEditDialogState();
}

class _NameEditDialogState extends State<_NameEditDialog> {
  late final TextEditingController _text = TextEditingController(
    text: widget.initialName,
  );

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const ValueKey<String>('bp-gender-name-dialog'),
      title: Text(
        '${context.l10n?.bpGenderEditName ?? 'تعديل الاسم'} '
        '(${context.l10n?.bpGenderRow ?? 'الصف'} ${widget.rowNumber})',
      ),
      content: TextField(
        key: ValueKey<String>('bp-gender-name-field-${widget.rowNumber}'),
        controller: _text,
        autofocus: true,
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(
          hintText: context.l10n?.bpGenderNameHint ?? 'اكتب الاسم الصحيح',
        ),
        onSubmitted: (String value) => Navigator.of(context).pop(value),
      ),
      actions: <Widget>[
        TextButton(
          key: ValueKey<String>('bp-gender-name-cancel-${widget.rowNumber}'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n?.editorCancel ?? 'إلغاء'),
        ),
        FilledButton(
          key: ValueKey<String>('bp-gender-name-save-${widget.rowNumber}'),
          onPressed: () => Navigator.of(context).pop(_text.text),
          child: Text(context.l10n?.commonSave ?? 'حفظ'),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
    this.warning,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  /// تنبيه اختياري يظهر أسفل الوصف (مثل: قالب بلا حقول ديناميكية).
  final String? warning;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppTheme.space12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: AppTheme.space8),
              Expanded(child: Text(title, style: text.titleSmall)),
            ],
          ),
          const SizedBox(height: 2),
          Text(subtitle, style: text.bodySmall),
          if (warning != null) ...<Widget>[
            const SizedBox(height: AppTheme.space8),
            _Note(
              color: AppColors.warning,
              soft: AppColors.warningSoft,
              icon: Icons.info_outline_rounded,
              text: warning!,
            ),
          ],
          const SizedBox(height: AppTheme.space12),
          child,
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({
    required this.color,
    required this.soft,
    required this.icon,
    required this.text,
  });

  final Color color;
  final Color soft;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: soft,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 11.5, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
