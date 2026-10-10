import 'dart:async';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../assets/asset_image_cache.dart';
import '../../audit/export_audit_log.dart';
import '../../assets/assets_controller.dart';
import '../../assets/embedded_assets.dart';
import '../../assets/user_asset.dart';
import '../../constants/app_constants.dart';
import '../../errors/app_exception.dart';
import '../../fonts/custom_font_controller.dart';
import '../../gender/arabic_gender.dart';
import '../../l10n/app_l10n.dart';
import '../../models/template_document.dart';
import '../../models/template_element.dart';
import '../../projects/jood/jood_archive.dart';
import '../../projects/jood/jood_autosave_service.dart';
import '../../projects/jood/jood_autosave_store.dart';
import '../../projects/jood/jood_project.dart';
import '../../projects/jood/jood_project_exporter.dart';
import '../../projects/jood/jood_project_importer.dart';
import '../../projects/project_thumbnails.dart';
import '../../projects/projects_controller.dart';
import '../../services/pdf_generator_service.dart';
import '../../templates/local_template_store.dart';
import '../../templates/template_library_controller.dart';
import '../../templates/template_record.dart';
import '../../templates/template_repository.dart';
import '../../templates/unsaved_changes_guard.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../utils/ui_feedback.dart';
import '../../widgets/pdf_template_preview.dart';
import '../dock/dock_controller.dart';
import '../dock/dock_layout.dart';
import '../element_factory.dart';
import '../template_editor_controller.dart';
import 'accordion.dart';
import 'asset_library_picker.dart';
import 'brand_presets_panel.dart';
import 'dock_overflow_bar.dart';
import 'dockable_toolbar.dart';
import 'editor_controls.dart';
import 'layers_panel.dart';
import 'property_toolbar.dart';
import 'template_canvas.dart';
import 'tool_palette.dart';

/// وضع العرض في المحرر.
enum EditorViewMode {
  /// اللوحة التفاعلية (السحب/التحجيم/شريط الخصائص).
  editor,

  /// معاينة الـ PDF الحقيقي للقالب الحالي.
  preview,
}

/// المحرر البصري الكامل — يُستخدم للشهادات (أفقي) والعقود (رأسي).
///
/// الطبقات: لوحة A4 تفاعلية + شريط خصائص عائم + شريط إضافة عناصر، مع حفظ
/// القالب في Supabase واسترجاعه في أي وقت.
class TemplateEditorView extends StatefulWidget {
  const TemplateEditorView({
    super.key,
    required this.category,
    required this.initialTemplateAsset,
    required this.exportFileName,
    this.repository,
    this.title,
    this.document,
    this.initialSelectionId,
    this.initialRecordId,
    this.onNewDocument,
    this.autosaveStore,
    this.autosaveDebounce = const Duration(seconds: 3),
  });

  final TemplateCategory category;

  /// قالب ابتدائي من أصول التطبيق (يُحمَّل عند أول فتح).
  final String initialTemplateAsset;

  final String exportFileName;

  /// `null` يعني أن الحفظ غير متاح (التطبيق غير مربوط بـ Supabase).
  final TemplateRepository? repository;

  /// عنوان القالب الابتدائي — `null` يعني العنوان الافتراضي المترجم.
  final String? title;

  /// مستند ابتدائي جاهز (للفتح من المكتبة أو للاختبارات) — يتقدّم على الأصل.
  final TemplateDocument? document;

  /// معرّف عنصر يُحدَّد تلقائياً عند فتح الشاشة.
  ///
  /// يُستخدم عند الوفود من المكتبة (فتح القالب على العنصر الذي كان المستخدم
  /// يعدّله) — يُطبَّق بعد اكتمال تحميل المستند لا قبله.
  final String? initialSelectionId;

  /// معرّف سجل القالب المحفوظ عند فتحه من مكتبة القوالب.
  ///
  /// ضروري ليُحدَّث السجل نفسه عند الحفظ التالي بدل إنشاء نسخة مكرّرة.
  final String? initialRecordId;

  /// فتح «مستند جديد» عند الضغط على «قالب جديد» — تمرّره شاشة الميزة فتُفتح
  /// نافذة عائمة تفتح على مجموعة مقاسات هذه الوحدة (شهادات/عقود).
  ///
  /// `null` يعني السلوك التقليدي: البدء من التصميم الافتراضي. الدالّة يمرّرها
  /// المالك لأن **النواة لا تستورد الميزات** (قاعدة معمارية في هذا المشروع).
  final Future<void> Function()? onNewDocument;

  /// مخزن الحفظ التلقائي — يُحقَن في الاختبارات (مخزن في الذاكرة)؛ `null` يعني
  /// الملف الافتراضي في مجلد بيانات التطبيق (وسلوك بلا حفظ على الويب).
  final JoodAutosaveStore? autosaveStore;

  /// مهلة التمهيد قبل كتابة المسودّة — تُقصَّر في الاختبارات.
  final Duration autosaveDebounce;

  @override
  State<TemplateEditorView> createState() => _TemplateEditorViewState();
}

class _TemplateEditorViewState extends State<TemplateEditorView> {
  late final TemplateEditorController _controller;
  late final TemplateLibraryController _library;
  final FocusNode _textFocusNode = FocusNode(debugLabel: 'editor-text-field');

  /// عقدة تركيز اللوحة: يُطلب التركيز عليها عند النقر على أي عنصر أو على
  /// مساحة فارغة داخل اللوحة، فتعمل اختصارات لوحة المفاتيح فوراً بعد النقر
  /// حتى لو كان المؤشر كان في حقل نصي قبل ذلك.
  final FocusNode _canvasFocusNode = FocusNode(debugLabel: 'editor-canvas');

  /// هل جلسة نقل الأسهم مفتوحة؟ — تجمع ضغطات التكرار (استمرار الضغط) في
  /// خطوة تراجع واحدة بدل أن تملأ المكدّس بحركة لكل تكرار مفتاح.
  bool _nudging = false;

  /// مؤقّت أمان يُغلق جلسة النقل إن فُقد حدث إفلات المفتاح (انتقال التركيز
  /// أثناء الضغط مثلاً) حتى لا يبقى التفاعل مفتوحاً ويمنع تسجيل التعديلات
  /// التالية في سجل التراجع.
  Timer? _nudgeSettleTimer;

  /// مدة التوقف التي تفصل بين ضغطتين مستقلتين في سجل التراجع.
  static const Duration _nudgeSettleDelay = Duration(milliseconds: 350);

  /// عنوان قالب جديد الاحتياطي — يُستبدل بالترجمة بعد `initState` في
  /// [didChangeDependencies] لأن قراءة الترجمة قبل اكتماله غير مسموحة.
  static const String defaultTitleFallback = 'قالب جديد';

  /// متحكّم الإرساء: موضع لوحة الأدوات (ملتصقة/عائمة)، طيّها، حجمها، والسحب.
  final DockController _dock = DockController();

  /// أكورديون أقسام اللوحة الجانبية: قسم واحد مفتوح في كل لحظة.
  final AccordionController _accordion = AccordionController();

  /// نوع العنصر المحدَّد سابقاً — يُقارَن عند كل تغيير لإعادة ضبط الأكورديون
  /// حين يتبدّل السياق (نصّ ← صورة ← بلا تحديد).
  Object? _selectionSignature;

  /// مرجع مساحة العمل — تُحسب داخله إحداثيات السحب والالتقاط المغناطيسي.
  final GlobalKey _canvasViewportKey = GlobalKey(debugLabel: 'editor-viewport');

  /// مرجع **ورقة التصميم** نفسها — يُلتقط منه بديل المشروع (صورة مصغّرة)
  /// ويُخزَّن في العمود `thumbnail_path` عند كل حفظ ناجح.
  final GlobalKey _paperCaptureKey = GlobalKey(debugLabel: 'editor-paper');

  /// معالج المغادرة المسجَّل في [UnsavedChangesGuard] — نحتفظ به كحقل لضمان
  /// أن إزالته عند التخلّص تُطابق نسخة التسجيل نفسها.
  late final Future<bool> Function() _leaveHandler = _confirmLeave;

  /// علم مؤقّت يسمح بالخروج البرمجي بعد تأكيد المستخدم (يتجاوز `PopScope`).
  bool _allowPop = false;

  double _zoom = 1;
  Offset _panOffset = Offset.zero;
  bool _isPanningWithCtrl = false;
  bool _showScrollbars = false;
  Timer? _scrollbarsHideTimer;
  Size _canvasViewportSize = Size.zero;
  bool _showGrid = true;
  bool _snapToGuides = true;

  void _showScrollbarsTemporarily() {
    _scrollbarsHideTimer?.cancel();
    if (!_showScrollbars) {
      setState(() => _showScrollbars = true);
    }
    _scrollbarsHideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _showScrollbars = false);
      }
    });
  }

  /// طيّ اللوحة الجانبية — يمنح مساحة التصميم أقصى عرض ممكن بنقرة واحدة.
  bool _panelCollapsed = false;
  EditorViewMode _mode = EditorViewMode.editor;
  int _previewRevision = 0;
  bool _isExporting = false;

  /// حفظ تلقائي مسودّة ‎.jood‎ خلفياً + التعافي من الإغلاق المفاجئ.
  late final JoodAutosaveService _autosave;

  /// هل تُصدَّر ملفات ‎.jood‎ الآن؟ (يمنع الضغط المتكرر)
  bool _isExportingJood = false;
  bool _isImportingJood = false;

  /// هل طُبّق عنوان «قالب جديد» المترجم مرة واحدة؟ (يُقرأ السياق بعد تهيئة
  /// الحالة فقط، لا في `initState`.)
  bool _titleLocalized = false;

  @override
  void initState() {
    super.initState();
    _controller = TemplateEditorController(
      document: widget.document ??
          TemplateDocument(
            elements: const <TemplateElement>[],
            orientation: widget.category.defaultOrientation,
          ),
      category: widget.category,
      repository: widget.repository,
      title: widget.title ?? defaultTitleFallback,
      recordId: widget.initialRecordId,
    );
    _controller.addListener(_onControllerChanged);
    // يمنح المحرّر فرصة اعتراض التنقّل (اللوحة الجانبية/رجوع النظام) عند
    // وجود تعديلات غير محفوظة.
    UnsavedChangesGuard.instance.register(_leaveHandler);
    // نافذة «قوالبي» داخل المحرّر تقرأ من المستودع المحلي المحقون نفسه، فتبقى
    // المخزن الاحتياطي في الذاكرة بلا لمس أي منصة (ولا يُعرض أي قالب مرّتين).
    _library = TemplateLibraryController(
      widget.repository,
      localStore: InMemoryLocalTemplateStore(),
    );

    // الحفظ التلقائي: كل تعديل يجدول كتابة ملف ‎.jood‎ كامل (بلا حجب الواجهة).
    _autosave = JoodAutosaveService(
      build: () => const JoodProjectExporter().export(
        document: _controller.document,
        title: _controller.title,
        assets: AssetsController.instance,
        fonts: CustomFontController.instance,
      ),
      store: widget.autosaveStore,
      debounce: widget.autosaveDebounce,
    );
    _controller.attachAutosave(_autosave);

    if (widget.document == null) {
      // جلسة جديدة: نحاول استعادة مسودة سابقة أولاً، وإلا نُحمّل القالب النموذجي.
      unawaited(_startFreshSession());
    } else {
      _applyInitialSelection();
      // إعادة تسخين ذاكرة الصور من الكاش القرصي (بلا انتظار).
      unawaited(warmDocumentImageCache(widget.document!));
    }
  }

  /// بداية جلسة جديدة: مسودة غير محفوظة ← إن وُجدت واختار المستخدم الاستعادة؛
  /// وإلا القالب النموذجي المحزوم.
  Future<void> _startFreshSession() async {
    final bool restored = await _maybeRecoverAutosave();
    if (restored || !mounted) return;
    await _bootstrapFromAsset();
  }

  /// يفحص وجود مسودة ‎.jood‎ غير محفوظة ويسأل المستخدم عن استعادتها.
  ///
  /// يُستدعى مرة واحدة عند فتح محرّر جديد. لا يعرض شيئاً إن لم تكن هناك مسودة
  /// (الويب/أول تشغيل/مسودة حُذفت بعد حفظ صريح)، فيمرّ التدفق للقالب النموذجي.
  Future<bool> _maybeRecoverAutosave() async {
    final Uint8List? draft = await _autosave.recover();
    if (draft == null || !mounted) return false;
    // محرّر مفتوح على مستند محمّل صراحةً لا يعتريه حوار استعادة المسودة.
    if (widget.document != null) return false;

    final bool? restore = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(context.l10n?.joodRecoveryTitle ?? 'مسودة غير محفوظة'),
        content: Text(
          context.l10n?.joodRecoveryMessage ??
              'توجد مسودة غير محفوظة من جلسة سابقة. هل ترغب في استعادتها؟',
        ),
        actions: <Widget>[
          TextButton(
            key: const ValueKey<String>('jood-recovery-discard'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.l10n?.joodRecoveryDiscard ?? 'إهمال'),
          ),
          FilledButton(
            key: const ValueKey<String>('jood-recovery-restore'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(context.l10n?.joodRecoveryRestore ?? 'استعادة'),
          ),
        ],
      ),
    );
    if (!mounted) return false;

    if (restore != true) {
      await _autosave.discard();
      return false;
    }

    try {
      final JoodProject project =
          await const JoodProjectImporter().readAndRestore(
        draft,
        assets: AssetsController.instance,
        fonts: CustomFontController.instance,
      );
      AssetImageCache.instance.clear();
      _controller.loadDocument(
        project.document,
        asClean: true,
        title: project.title,
      );
      unawaited(warmDocumentImageCache(project.document));
      if (mounted) {
        context.showSuccess(
          context.l10n?.joodRecoveryRestored ?? 'تم استعادة المسودة.',
        );
      }
      return true;
    } on JoodArchiveException catch (error) {
      await _autosave.discard();
      if (mounted) context.showWarning(error.message);
      return false;
    } on Object catch (error) {
      await _autosave.discard();
      if (mounted) {
        context.showWarning(
          context.l10n?.joodImportFailed ?? 'تعذّر فتح ملف المشروع.',
        );
      }
      debugPrint('[مشروع Jood] تعذّرت استعادة المسودة: $error');
      return false;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_titleLocalized) return;
    _titleLocalized = true;
    // لا يمكن قراءة التوطين في `initState` (قبل اكتماله)، فنُطبّق العنوان
    // الافتراضي المترجم هنا مرة واحدة بعد توفّر مندوبي الترجمة — بلا وسم
    // المستند كمتغيّر.
    if (widget.title != null) return;
    final String? localized = context.l10n?.tevNewTemplateTitle;
    if (localized != null) {
      _controller.localizeDefaultTitle(
        localized,
        defaultTitle: defaultTitleFallback,
      );
    }
  }

  Future<void> _bootstrapFromAsset() async {
    await _controller.loadTemplateAsset(
      widget.initialTemplateAsset,
      asClean: true,
    );
    _applyInitialSelection();
    unawaited(warmDocumentImageCache(_controller.document));
  }

  void _applyInitialSelection() {
    final String? id = widget.initialSelectionId;
    if (id == null) return;
    _controller.select(id);
  }

  @override
  void dispose() {
    UnsavedChangesGuard.instance.unregister(_leaveHandler);
    _nudgeSettleTimer?.cancel();
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _library.dispose();
    _dock.dispose();
    _accordion.dispose();
    _textFocusNode.dispose();
    _canvasFocusNode.dispose();
    // تحرير البايتات المفكوكة عند إغلاق المحرّر حتى لا تتراكم صور الإطار
    // والخلفيات عالية الدقة في الذاكرة مع الاستخدام المطوّل.
    AssetImageCache.instance.clear();
    super.dispose();
  }

  /// إظهار رسالة نجاح الحفظ مرة واحدة، وإعادة ضبط الأكورديون عند تغيّر **نوع**
  /// العنصر المحدَّد حتى لا يبقى قسمٌ مفتوحٌ لا يخصّ السياق الجديد.
  void _onControllerChanged() {
    final Object? selectionSignature = _controller.selected?.runtimeType;
    if (selectionSignature != _selectionSignature) {
      _selectionSignature = selectionSignature;
      _accordion.reset();
    }
    final String? message = _controller.statusMessage;
    if (message == null || !mounted) return;
    context.showSuccess(message);
    _controller.clearStatusMessage();
  }

  // ==========================================================================
  //  البناء
  // ==========================================================================
  @override
  Widget build(BuildContext context) {
    // الشجرة تُعاد أيضاً عند تغيّر تخطيط الإرساء (نقل اللوحة، طيّها، سحبها)
    // فموضعها وموضع لوحة الأدوات يتبعانه مباشرةً بلا خطوة يدوية.
    //
    // ونطاق **الأكورديون** يلفّ المحرّر: كل أقسام الشريط الجانبي القابلة للطيّ
    // (شريط الخصائص، الطبقات، عناصر الهوية) تتشارك متحكّماً واحداً، فيُغلق
    // المفتوحُ سواه تلقائياً ويبقى الشريط مضغوطاً ومركّزاً على الأداة النشطة.
    return AccordionScope(
      controller: _accordion,
      child: ListenableBuilder(
        listenable: _dock,
        builder: (BuildContext context, Widget? child) => _buildEditor(context),
      ),
    );
  }

  Widget _buildEditor(BuildContext context) {
    return PopScope<Object?>(
      // يُعترض دائماً، ويُقرَّر في المعالج حسب وجود تعديلات غير محفوظة — فلا
      // نحتاج إعادة بناء الشجرة كلها عند كل تعديل فقط لتحديث `canPop`.
      canPop: _allowPop,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;
        final bool leave = await _confirmLeave();
        if (!context.mounted || !leave) return;
        setState(() => _allowPop = true);
        Navigator.of(context).maybePop();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _header(context),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.space12),
              child: _mode == EditorViewMode.preview
                  ? _previewPanel()
                  : _editorPanel(),
            ),
          ),
          if (_mode == EditorViewMode.editor) _bottomBar(context),
        ],
      ),
    );
  }

  /// يُسأل قبل مغادرة المحرّر: `true` يعني السماح بالمغادرة.
  ///
  /// بلا تعديلات غير محفوظة يعود `true` فوراً (بلا أي نافذة). وإلا يعرض
  /// خياراً بين الحفظ والمغادرة دون حفظ والإلغاء، ويعود `false` إن اختار
  /// المستخدم الإلغاء أو فشل الحفظ (فيبقى عمله محفوظاً في الشاشة).
  Future<bool> _confirmLeave() async {
    if (!mounted) return true;
    if (!_controller.hasUnsavedChanges) return true;

    final _LeaveChoice? choice = await showDialog<_LeaveChoice>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(context.l10n?.tevUnsavedTitle ?? 'تعديلات غير محفوظة'),
        content: Text(
          context.l10n?.tevUnsavedMessage(_controller.title) ??
              'لديك تعديلات على «${_controller.title}» لم تُحفَظ بعد. '
                  'هل تريد حفظها قبل المغادرة؟',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(_LeaveChoice.cancel),
            child: Text(context.l10n?.editorCancel ?? 'إلغاء'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(_LeaveChoice.discard),
            child: Text(context.l10n?.tevLeaveWithoutSaving ?? 'المغادرة دون حفظ'),
          ),
          if (_controller.canPersist)
            FilledButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(_LeaveChoice.save),
              child: Text(context.l10n?.tevSaveAndLeave ?? 'حفظ والمغادرة'),
            ),
        ],
      ),
    );

    if (choice == null || choice == _LeaveChoice.cancel) return false;
    if (choice == _LeaveChoice.discard) return true;
    // «حفظ والمغادرة»: يُتابع فقط إن نجح الحفظ فعلاً (لا يُغلق عنوانٌ ملغى
    // أو فشلُ شبكة الطريقَ ويُفقد العمل).
    await _save();
    return !_controller.hasUnsavedChanges;
  }

  // ==========================================================================
  //  الترويسة
  // ==========================================================================
  /// **الشريط السياقي الموحّد (Ribbon)** — صفّ واحد أعلى اللوحة الممتدة.
  ///
  /// جُمِعت فيه كل أدوات العمل في صفٍّ واحد بدل صفوفٍ متعدّدة: طريقة العرض،
  /// التراجع/الإعادة، الشبكة وخطوط الإرشاد، التكبير والملاءمة، خصائص المستند
  /// (في قائمة منسدلة واحدة)، حالة القالب، ثم إجراءات الحفظ/التصدير.
  /// العرض يُدار بـ [DockOverflowBar]: ما لا يتّسع من المجموعات الأدنى أولوية
  /// ينتقل إلى **قائمة منسدلة أعلى الشريط** (انظر [RibbonMenu]) — لا إلى اللوحة
  /// الجانبية — فلا يُقتطع أي زرّ عند ضيق النافذة، ويبقى الارتفاع صفّاً ثابتاً.
  Widget _header(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? _) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.space12,
            vertical: AppTheme.space8,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              bottom: BorderSide(color: Theme.of(context).colorScheme.outline),
            ),
          ),
          // الشريط يرتّب المجموعات حسب الأولوية وما يتّسع فعلاً، ويجمع ما لا
          // يتّسع في **قائمة منسدلة أعلى الشريط** — لا في اللوحة الجانبية —
          // فيبقى كل شيء في سياقه المكاني الصحيح بلا انتقالات مفاجئة.
          child: DockOverflowBar(
            items: _ribbonItems(context),
            overflowLabel: context.l10n?.editorMoreTools ?? 'أدوات أخرى',
          ),
        );
      },
    );
  }

  /// مجموعات الشريط العلوي مرتّبةً بأولوياتها — يقيس [DockOverflowBar] عرض كل
  /// مجموعة فعلياً ويُخلي الأدنى أولوية (بلا اقتطاع).
  ///
  /// المجموعة المثبّتة عنوان القالب (لا تُخفى أبداً)، ثم الحفظ والتصدير (أهمّ
  /// إجراءين)، ثم أدوات التراجع/العرض، ثم الثانوية (ملفّ، جنس المعاينة، طريقة
  /// العرض، خصائص المستند، حالة القالب) بالترتيب.
  ///
  /// ونُبقي كل مجموعة **صغيرة ومستقلة** (لا حزمة عريضة واحدة) حتى يُخلى الأدنى
  /// أولوية وحده، فيبقى الشريط ممتلئاً بما يهمّ فعلاً عند ضيقه.
  List<DockOverflowItem> _ribbonItems(BuildContext context) {
    final List<DockOverflowItem> items = <DockOverflowItem>[
      DockOverflowItem(
        id: 'title',
        pinned: true,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[_titleChip(context), _toolbarDivider(context)],
        ),
      ),
      DockOverflowItem(
        id: 'save',
        priority: 99,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[_saveAction(context), _toolbarDivider(context)],
        ),
      ),
      DockOverflowItem(
        id: 'export',
        priority: 97,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[_exportAction(context), _toolbarDivider(context)],
        ),
      ),
      DockOverflowItem(
        id: 'file',
        priority: 88,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _fileActionsRow(context),
            _toolbarDivider(context),
          ],
        ),
      ),
      DockOverflowItem(
        id: 'jood',
        priority: 86,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _joodActionsRow(context),
            _toolbarDivider(context),
          ],
        ),
      ),
      DockOverflowItem(
        id: 'view',
        priority: 95,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ..._viewControls(context),
            _toolbarDivider(context),
          ],
        ),
      ),
      DockOverflowItem(
        id: 'gender',
        priority: 90,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // مبدّل جنس المعاينة الحيّة: يعرض الصيغ الشرطية `{{الجنس: ذكر | أنثى}}`
            // مؤنّثةً/مذكّرةً على اللوحة فوراً — بلا أي أثر على المستند أو الطباعة.
            _genderPreviewToggle(context),
            _toolbarDivider(context),
          ],
        ),
      ),
      if (_dock.tools.slot == DockSlot.topBar)
        DockOverflowItem(
          id: 'dock-tools',
          priority: 80,
          child: _dockedToolPalette(context, axis: Axis.horizontal),
        ),
      DockOverflowItem(
        id: 'mode',
        priority: 70,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // طريقة العرض: المحرّر أو معاينة PDF.
            SegmentedField<EditorViewMode>(
              label: context.l10n?.tevViewMode ?? 'طريقة العرض',
              value: _mode,
              options: EditorViewMode.values,
              labelOf: (EditorViewMode mode) =>
                  mode == EditorViewMode.editor
                      ? context.l10n?.tevModeEditor ?? 'المحرر'
                      : context.l10n?.tevModePreview ?? 'معاينة PDF',
              iconOf: (EditorViewMode mode) => mode == EditorViewMode.editor
                  ? Icons.design_services_rounded
                  : Icons.picture_as_pdf_rounded,
              onChanged: _setMode,
            ),
            _toolbarDivider(context),
          ],
        ),
      ),
      DockOverflowItem(
        id: 'document',
        priority: 60,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // خصائص المستند (الاتجاه/المقاس/الخلفية/الإطار) مجموعةً في قائمة
            // منسدلة واحدة بدل نثرها في مجموعتين عريضتين على الشريط.
            _documentPropertiesMenu(context),
            _toolbarDivider(context),
          ],
        ),
      ),
      DockOverflowItem(
        id: 'status',
        priority: 30,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // حالة الحفظ التلقائي (شارة صغيرة لا تظهر قبل أول حفظ).
            _autosaveBadge(context),
            // حالة القالب (عدد العناصر/الحقول/التعديلات غير المحفوظة).
            Text(
              '${context.l10n?.evElementCount(_controller.document.drawableElementCount) ?? '${_controller.document.drawableElementCount} عنصراً'}'
              '${_controller.hasDynamicFields ? (context.l10n?.evStatusDynamicFields ?? ' • حقول ديناميكية') : ''}'
              '${_controller.hasUnsavedChanges ? (context.l10n?.evStatusUnsaved ?? ' • تعديلات غير محفوظة') : ''}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            _toolbarDivider(context),
          ],
        ),
      ),
    ];
    return items;
  }

  /// خصائص المستند (الاتجاه/المقاس/الخلفية/الإطار) في قائمة منسدلة واحدة.
  ///
  /// خصائص المستند كلّية لا تخصّ عنصراً بعينه، فتجميعها في منيوّ أعلى الشريط
  /// يُبقيه صفّاً واحداً نظيفاً ويضع كل ما يخصّ الورقة في مكان واحد.
  Widget _documentPropertiesMenu(BuildContext context) {
    return RibbonMenu(
      key: const ValueKey<String>('editor-document-menu'),
      icon: Icons.tune_rounded,
      label: context.l10n?.editorDocumentProperties ?? 'خصائص المستند',
      children: <Widget>[
        SegmentedField<PageOrientation>(
          label: context.l10n?.tevPaperDirection ?? 'اتجاه الورقة',
          value: _controller.document.orientation,
          options: PageOrientation.values,
          labelOf: (PageOrientation orientation) =>
              orientation.isLandscape
                  ? context.l10n?.tplOrientationLandscape ?? 'أفقي'
                  : context.l10n?.tplOrientationPortrait ?? 'رأسي',
          iconOf: (PageOrientation orientation) =>
              orientation.isLandscape
                  ? Icons.crop_landscape_rounded
                  : Icons.crop_portrait_rounded,
          onChanged: _controller.setOrientation,
        ),
        const SizedBox(height: AppTheme.space12),
        _paperSizeControls(context),
        const SizedBox(height: AppTheme.space12),
        ColorField(
          label: context.l10n?.tevDocumentBackground ?? 'خلفية المستند',
          hex: _controller.document.backgroundHex,
          width: 200,
          onChanged: _controller.setBackgroundHex,
        ),
        const SizedBox(height: AppTheme.space8),
        OutlinedButton.icon(
          key: const ValueKey<String>('document-background-library'),
          onPressed: _pickBackgroundFromLibrary,
          icon: const Icon(Icons.collections_bookmark_rounded, size: 16),
          label: Text(
            context.l10n?.tevFrameFromLibrary ?? 'إطار من مكتبة أصولي',
          ),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 44),
            padding: const EdgeInsets.symmetric(horizontal: 14),
          ),
        ),
      ],
    );
  }

  /// لوحة الأدوات القابلة للإرساء (طيّ/حجم/سحب والتقاط مغناطيسي).
  Widget _dockedToolPalette(BuildContext context, {required Axis axis}) {
    return DockableToolbar(
      key: const ValueKey<String>('dockable-tool-palette'),
      dock: _dock,
      panelId: DockLayout.toolsPanel,
      title: context.l10n?.editorDockTools ?? 'لوحة الأدوات',
      icon: Icons.handyman_outlined,
      axis: axis,
      // السحب يُحسب داخل مساحة العمل، فتبقى الإحداثيات صحيحة عند الإرساء
      // في الشريط الجانبي أو العودة إلى العوم.
      viewportKey: _dock.tools.slot == DockSlot.topBar ? null : _canvasViewportKey,
      slotLabel: _dockSlotLabel,
      child: EditorToolPalette(
        controller: _controller,
        axis: axis,
        onTextAdded: (_) => _textFocusNode.requestFocus(),
      ),
    );
  }

  /// اسم موضع الإرساء مترجماً (يُمرَّر إلى الشريط الرفيع ومؤشّر الالتقاط).
  String _dockSlotLabel(DockSlot slot) => switch (slot) {
        DockSlot.leftRail =>
          context.l10n?.editorDockLeftRail ?? 'الشريط الجانبي',
        DockSlot.topBar => context.l10n?.editorDockTopBar ?? 'الشريط العلوي',
        DockSlot.inspector =>
          context.l10n?.editorDockInspector ?? 'اللوحة الجانبية',
        DockSlot.floating => context.l10n?.editorDockFloating ?? 'عائمة',
      };

  /// أدوات مقاس الورق في السطر الواحد: قائمة المقاسات القياسية (A4/A5/Letter/…)
  /// ومدخل المقاس المخصّص (سم/مليمتر/بوصة)، أو شريحة تعرض المقاس المخصّص مع
  /// زرّ العودة للمقاس القياسي — كلها في السطر نفسه بلا أي ارتفاع إضافي.
  Widget _paperSizeControls(BuildContext context) {
    final CustomPageSize? custom = _controller.document.customPageSize;
    if (custom == null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          DropdownField<PaperSize>(
            label: context.l10n?.editorPageSize ?? 'المقاس',
            value: _controller.document.paperSize,
            items: PaperSize.values,
            labelOf: (PaperSize size) => size.labelAr,
            width: 110,
            onChanged: _controller.setPaperSize,
          ),
          const SizedBox(width: AppTheme.space8),
          IconAction(
            key: const ValueKey<String>('custom-size-button'),
            icon: Icons.straighten_rounded,
            tooltip: context.l10n?.editorCustomSize ?? 'مقاس مخصّص',
            onPressed: _openCustomSizeDialog,
          ),
        ],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        OutlinedButton.icon(
          key: const ValueKey<String>('custom-size-chip'),
          onPressed: _openCustomSizeDialog,
          icon: const Icon(Icons.straighten_rounded, size: 16),
          label: Text(
            '${custom.width.toStringAsFixed(2)} × '
            '${custom.height.toStringAsFixed(2)} ${custom.unit.labelAr}',
          ),
          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
        ),
        const SizedBox(width: AppTheme.space8),
        IconAction(
          key: const ValueKey<String>('standard-size-button'),
          icon: Icons.aspect_ratio_rounded,
          tooltip: context.l10n?.editorStandardSize ?? 'مقاس قياسي',
          onPressed: _controller.clearCustomPageSize,
        ),
      ],
    );
  }

  /// نافذة تحرير المقاس المخصّص (وحدة + عرض + ارتفاع + عودة للمقاس القياسي).
  ///
  /// انتقلت من السطر إلى نافذة لتظلّ الترويسة **صفّاً واحداً** بلا ارتفاع إضافي.
  Future<void> _openCustomSizeDialog() async {
    if (_controller.document.customPageSize == null) {
      _controller.enableCustomPageSize();
    }
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(context.l10n?.editorCustomSize ?? 'مقاس مخصّص'),
        content: AnimatedBuilder(
          animation: _controller,
          builder: (BuildContext context, Widget? _) {
            final CustomPageSize? size = _controller.document.customPageSize;
            if (size == null) return const SizedBox.shrink();
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                DropdownField<MeasurementUnit>(
                  label: context.l10n?.editorUnit ?? 'الوحدة',
                  value: size.unit,
                  items: MeasurementUnit.values,
                  labelOf: (MeasurementUnit unit) => unit.labelAr,
                  width: 220,
                  onChanged: (MeasurementUnit unit) =>
                      _controller.setCustomPageSize(size.width, size.height, unit),
                ),
                const SizedBox(height: AppTheme.space12),
                NumberField(
                  label: context.l10n?.tevWidthCm ?? 'العرض (cm)',
                  value: size.width,
                  min: 1,
                  max: 500,
                  decimals: 2,
                  onChanged: (double width) =>
                      _controller.setCustomPageSize(width, size.height, size.unit),
                ),
                const SizedBox(height: AppTheme.space12),
                NumberField(
                  label: context.l10n?.tevHeightCm ?? 'الارتفاع (cm)',
                  value: size.height,
                  min: 1,
                  max: 500,
                  decimals: 2,
                  onChanged: (double height) =>
                      _controller.setCustomPageSize(size.width, height, size.unit),
                ),
                const SizedBox(height: AppTheme.space12),
                Text(
                  '${size.width.toStringAsFixed(2)} × '
                  '${size.height.toStringAsFixed(2)} ${size.unit.labelAr} '
                  '→ ${_controller.paperSizeLabel}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            );
          },
        ),
        actions: <Widget>[
          TextButton(
            key: const ValueKey<String>('standard-size-button'),
            onPressed: () {
              _controller.clearCustomPageSize();
              Navigator.of(dialogContext).pop();
            },
            child: Text(context.l10n?.editorStandardSize ?? 'مقاس قياسي'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(context.l10n?.editorDone ?? 'تم'),
          ),
        ],
      ),
    );
  }

  /// فاصل رأسي رفيع يفصل مجموعات شريط الأدوات دون تغيير ارتفاعه.
  Widget _toolbarDivider(BuildContext context) => Container(
        width: 1,
        height: 24,
        margin: const EdgeInsets.symmetric(horizontal: AppTheme.space4),
        color: Theme.of(context).colorScheme.outline,
      );

  /// مبدّل جنس المعاينة الحيّة: `♂ ذكر` / `♀ أنثى`.
  ///
  /// نقر الزر المحدَّد يُلغي الفرض ويعود للاستنتاج التلقائي من الاسم، فلا يعلق
  /// المصمّم في وضع معاينة لا يريده.
  Widget _genderPreviewToggle(BuildContext context) {
    final Gender? active = _controller.previewGender;
    Widget option(Gender gender, IconData icon, String label, String key) {
      final bool selected = active == gender;
      return IconAction(
        key: ValueKey<String>(key),
        icon: icon,
        tooltip: selected
            ? '$label — ${context.l10n?.genderPreviewAutoHint ?? 'نقر لإلغاء الفرض (تلقائي)'}'
            : label,
        selected: selected,
        onPressed: () =>
            _controller.setPreviewGender(selected ? null : gender),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        option(
          Gender.male,
          Icons.male_rounded,
          context.l10n?.genderMale ?? 'ذكر',
          'editor-gender-male',
        ),
        option(
          Gender.female,
          Icons.female_rounded,
          context.l10n?.genderFemale ?? 'أنثى',
          'editor-gender-female',
        ),
      ],
    );
  }

  /// مجموعة أدوات العرض: تراجع/إعادة، الشبكة، خطوط الإرشاد، التكبير، الملاءمة.
  List<Widget> _viewControls(BuildContext context) => <Widget>[
        IconAction(
          icon: Icons.undo_rounded,
          tooltip: context.l10n?.tevUndo ?? 'تراجع (Ctrl+Z)',
          onPressed: _controller.canUndo ? _controller.undo : null,
        ),
        IconAction(
          icon: Icons.redo_rounded,
          tooltip: context.l10n?.tevRedo ?? 'إعادة (Ctrl+Y)',
          onPressed: _controller.canRedo ? _controller.redo : null,
        ),
        IconAction(
          icon: Icons.grid_on_rounded,
          tooltip: context.l10n?.tevSnapGrid ?? 'شبكة التوجيه',
          selected: _showGrid,
          onPressed: () => setState(() => _showGrid = !_showGrid),
        ),
        IconAction(
          key: const ValueKey<String>('toggle-snap-guides'),
          icon: Icons.align_vertical_center_rounded,
          tooltip: _snapToGuides
              ? context.l10n?.tevGuidesOn ?? 'خطوط الإرشاد الذكية: مُفعّلة (إيقاف)'
              : context.l10n?.tevGuidesOff ?? 'خطوط الإرشاد الذكية: معطّلة (تشغيل)',
          selected: _snapToGuides,
          onPressed: () => setState(() => _snapToGuides = !_snapToGuides),
        ),
        if (_mode == EditorViewMode.editor) ...<Widget>[
          SliderField(
            label: context.l10n?.tevZoom ?? 'التكبير',
            value: _zoom,
            min: 0.5,
            max: 3,
            width: 150,
            display: (double value) => '${(value * 100).round()}%',
            onChanged: (double value) => setState(() => _zoom = value),
          ),
          // «ملاءمة الشاشة»: تعيد التكبير والإزاحة إلى الوضع الافتراضي
          IconAction(
            key: const ValueKey<String>('editor-fit-screen'),
            icon: Icons.fit_screen_rounded,
            tooltip: context.l10n?.editorFitToScreen ?? 'ملاءمة الشاشة',
            onPressed: () => setState(() {
              _zoom = 1;
              _panOffset = Offset.zero;
            }),
          ),
        ],
      ];

  /// يبدأ مستنداً جديداً من **نافذة «مستند جديد» العائمة**.
  ///
  /// النافذة تُفتح فوق المحرّر نفسه (لا صفحة تنقّل) وتفتح على مجموعة مقاسات
  /// هذه الوحدة — الفتح من محرّك الشهادات يبدأ بالشهادات الأفقية، ومن محرّك
  /// العقود بالعقود الرأسية — ثم تُفتح المسودة المختارة في المحرّر مباشرةً.
  Future<void> _newDocument() async {
    if (_controller.hasUnsavedChanges) {
      final bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext dialogContext) => AlertDialog(
          title: Text(context.l10n?.editorNewTemplate ?? 'قالب جديد'),
          content: Text(
            context.l10n?.editorNewConfirm ??
                'سيبدأ قالب جديد من التصميم الافتراضي. متابعة؟',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(context.l10n?.editorCancel ?? 'إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(context.l10n?.editorNewTemplate ?? 'قالب جديد'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    // المالك (شاشة الميزة) يفتح نافذة «مستند جديد» العائمة بمعرفة وحدته.
    // النواة **لا تستورد الميزات** أبداً، فالتكامل هنا عبر دالّة يمرّرها المالك.
    final Future<void> Function()? openDialog = widget.onNewDocument;
    if (openDialog != null) {
      await openDialog();
      return;
    }
    // الافتراضي (بلا مالك): البداية من التصميم الافتراضي كما كان.
    await _controller.loadTemplateAsset(
      widget.initialTemplateAsset,
      asClean: true,
    );
  }

  Widget _titleChip(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: context.l10n?.tevChangeTitle ?? 'تغيير عنوان القالب',
      child: InkWell(
        onTap: () async {
          final String? title = await _askTitle(initial: _controller.title);
          if (title == null || !mounted) return;
          // يُغيَّر العنوان محلياً ويُثبَّت في قاعدة البيانات عند الحفظ التالي.
          _controller.rename(title);
        },
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
            border: Border.all(color: scheme.outline),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.edit_outlined, size: 14, color: scheme.primary),
              const SizedBox(width: 6),
              Text(
                _controller.title,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: scheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// إجراءات الملفّ الثانوية (قالب جديد/قوالبي/حفظ باسم) — مجموعة واحدة
  /// مستقلّة تُخلى وحدها إلى قائمة «أدوات أخرى» عند ضيق الشريط.
  Widget _fileActionsRow(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // قالب جديد من التصميم الافتراضي (مع تأكيد عند وجود تعديلات).
        OutlinedButton.icon(
          key: const ValueKey<String>('editor-new-template'),
          onPressed: _newDocument,
          icon: const Icon(Icons.insert_drive_file_outlined, size: 17),
          label: Text(context.l10n?.editorNewTemplate ?? 'قالب جديد'),
          style: OutlinedButton.styleFrom(minimumSize: const Size(120, 44)),
        ),
        const SizedBox(width: AppTheme.space8),
        OutlinedButton.icon(
          onPressed: _openLibrary,
          icon: const Icon(Icons.folder_open_rounded, size: 17),
          label: Text(context.l10n?.tevMyTemplates ?? 'قوالبي'),
          style: OutlinedButton.styleFrom(minimumSize: const Size(120, 44)),
        ),
        const SizedBox(width: AppTheme.space8),
        OutlinedButton.icon(
          onPressed: () => _save(saveAs: true),
          icon: const Icon(Icons.save_as_rounded, size: 17),
          label: Text(context.l10n?.tevSaveAs ?? 'حفظ باسم'),
          style: OutlinedButton.styleFrom(minimumSize: const Size(130, 44)),
        ),
      ],
    );
  }

  /// إجراءات ملفّ المشروع المستقل (‎.jood‎): تصدير وفـتح عبر منتقي الملفات.
  ///
  /// مجموعة مستقلة تُخلى وحدها إلى «أدوات أخرى» عند ضيق الشريط، فلا تُقتطع
  /// أزرار الحفظ/تصدير PDF الأساسية قبلها.
  Widget _joodActionsRow(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        OutlinedButton.icon(
          key: const ValueKey<String>('editor-export-jood'),
          onPressed: _isExportingJood ? null : _exportJood,
          icon: _isExportingJood
              ? const SizedBox.square(
                  dimension: 15,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.inventory_2_outlined, size: 17),
          label: Text(
            context.l10n?.joodExportProject ?? 'تصدير مشروع (.jood)',
          ),
          style: OutlinedButton.styleFrom(minimumSize: const Size(150, 44)),
        ),
        const SizedBox(width: AppTheme.space8),
        OutlinedButton.icon(
          key: const ValueKey<String>('editor-import-jood'),
          onPressed: _isImportingJood ? null : _importJood,
          icon: _isImportingJood
              ? const SizedBox.square(
                  dimension: 15,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.folder_zip_outlined, size: 17),
          label: Text(
            context.l10n?.joodImportProject ?? 'فتح مشروع (.jood)',
          ),
          style: OutlinedButton.styleFrom(minimumSize: const Size(150, 44)),
        ),
      ],
    );
  }

  /// شارة حالة الحفظ التلقائي: «جاري الحفظ…» أثناء الكتابة، وإلا «تم الحفظ
  /// تلقائياً» بعد أول كتابة ناجحة. لا تظهر قبل أول حفظ إطلاقاً (لا ضجيج بلا داعٍ).
  Widget _autosaveBadge(BuildContext context) {
    final JoodAutosaveService? service = _controller.autosave;
    if (service == null) return const SizedBox.shrink();
    return AnimatedBuilder(
      animation: service,
      builder: (BuildContext context, Widget? _) {
        final bool saving = service.isSaving;
        if (!saving && !service.hasSavedOnce) {
          return const SizedBox.shrink();
        }
        final ColorScheme scheme = Theme.of(context).colorScheme;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              saving ? Icons.sync_rounded : Icons.cloud_done_rounded,
              size: 14,
              color: saving ? scheme.primary : AppColors.goldDeep,
            ),
            const SizedBox(width: AppTheme.space4),
            Text(
              saving
                  ? (context.l10n?.joodAutosaveSaving ?? 'جاري الحفظ…')
                  : (context.l10n?.joodAutosaveSaved ?? 'تم الحفظ تلقائياً'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(width: AppTheme.space8),
          ],
        );
      },
    );
  }

  /// زرّ حفظ القالب: يبقى في الشريط أطول ما أمكن — فقدانه أغلى من فقدان أي
  /// أداة عرض.
  Widget _saveAction(BuildContext context) {
    final bool persist = _controller.canPersist;
    return FilledButton.icon(
      onPressed: _controller.isSaving ? null : () => _save(),
      icon: _controller.isSaving
          ? const SizedBox.square(
              dimension: 15,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.save_rounded, size: 17),
      label: Text(
        persist
            ? context.l10n?.tevSaveTemplate ?? 'حفظ القالب'
            : context.l10n?.tevSaveUnavailable ?? 'الحفظ غير متاح',
      ),
      style: FilledButton.styleFrom(minimumSize: const Size(150, 44)),
    );
  }

  /// زرّ تصدير PDF — الإجراء النهائي الذي يبحث عنه المستخدم دائماً.
  Widget _exportAction(BuildContext context) {
    return FilledButton.icon(
      key: const ValueKey<String>('editor-export-pdf'),
      onPressed: _isExporting ? null : _exportPdf,
      icon: _isExporting
          ? const SizedBox.square(
              dimension: 15,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.picture_as_pdf_rounded, size: 17),
      label: Text(context.l10n?.commonExportPdf ?? 'تصدير PDF'),
      style: FilledButton.styleFrom(
        minimumSize: const Size(140, 44),
        backgroundColor: AppColors.goldDeep,
        foregroundColor: AppColors.onNavy,
      ),
    );
  }

  /// توليد ملف PDF للمستند الحالي ومشاركته/حفظه فوراً من داخل المحرّر.
  ///
  /// **بلا أي شرط إيقاف بسبب الأصول**: كل عنصر صورة يُحلّ من مرجعه الحيّ أو من
  /// نسخته المضمّنة (Base64) واحتياطاً من البايتات المعروضة على اللوحة؛ وإن
  /// تعذّر ذلك يُرسم بقية المستند بلا شريط خطأ يحجب التصدير. أي فشل حقيقي في
  /// توليد الملف يظهر كرسالة عربية.
  Future<void> _exportPdf() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);
    try {
      final PdfGeneratorService service = await PdfGeneratorService.create();
      final PdfGenerationReport report = await service.generate(
        document: _controller.document,
        data: _controller.document.sampleData,
      );
      
      final Uri? selectedPath = await FilePicker.saveFile(
        dialogTitle: 'حفظ شهادة PDF',
        fileName: widget.exportFileName,
        bytes: report.bytes,
        type: FileType.custom,
        allowedExtensions: <String>['pdf'],
      );

      if (!mounted || selectedPath == null) return;

      // **أرشفة محلية:** يُسجّل الإصدار بعد نجاح الحفظ فعلاً — بالتاريخ
      // والمدير الحالي وعدد الصفحات — فيرى المدير من أصدر أيّ مستند.
      unawaited(
        ExportAuditLog.instance.record(
          documentTitle: _controller.title,
          kind: widget.category == TemplateCategory.contract
              ? ExportKind.contract
              : ExportKind.certificate,
          templateId: _controller.recordId,
          fileName: widget.exportFileName,
          pageCount: report.pageCount,
        ),
      );

      context.showSuccess(
        context.l10n?.commonExportReady(widget.exportFileName) ??
            'تم حفظ الملف بنجاح باسم ${widget.exportFileName}.',
      );
    } on AppException catch (error) {
      if (!mounted) return;
      context.showError(error.message);
    } on Object {
      if (!mounted) return;
      context.showError('تعذّر تصدير ملف PDF.');
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  /// يصدّر المشروع كملف ‎.jood‎ **واحد مستقلّ** يحوي المستند وأصوله وخطوطه
  /// وصورته المصغّرة، عبر منتقي الملفات (سطح المكتب والويب).
  ///
  /// الألوان والإحداثيات تُنقل حرفياً (المستند يُكتب بـ`toJson` كما هو)، فلا
  /// يمسّ التصدير أي تحويل لوني ولا أي إزاحة.
  Future<void> _exportJood() async {
    if (_isExportingJood) return;
    // نصّ الترجمة يُقرأ قبل أي `await` فلا نمرّ بالسياق عبر فجوة غير متزامنة.
    final String dialogTitle =
        context.l10n?.joodExportProject ?? 'تصدير مشروع (.jood)';
    final String readyMessage =
        context.l10n?.joodExportReady ?? 'تم تجهيز ملف المشروع للحفظ.';
    final String failedMessage =
        context.l10n?.joodExportFailed ?? 'تعذّر تصدير ملف المشروع.';
    setState(() => _isExportingJood = true);
    try {
      final Uint8List? thumbnail =
          await ProjectThumbnails.captureBytes(_paperCaptureKey);
      final Uint8List bytes = const JoodProjectExporter().export(
        document: _controller.document,
        title: _controller.title,
        assets: AssetsController.instance,
        fonts: CustomFontController.instance,
        thumbnailPng: (thumbnail == null || thumbnail.isEmpty)
            ? null
            : thumbnail,
      );
      final Uri? saved = await FilePicker.saveFile(
        fileName: '${_joodFileName(_controller.title)}.${JoodFormat.extension}',
        bytes: bytes,
        mimeType: 'application/zip',
        dialogTitle: dialogTitle,
        type: FileType.custom,
        allowedExtensions: <String>[JoodFormat.extension],
      );
      if (!mounted || saved == null) return;
      // تصدير المشروع يُسجّل أيضاً: الملف قد يحمل بيانات تُنسى في المكتبة.
      unawaited(
        ExportAuditLog.instance.record(
          documentTitle: _controller.title,
          kind: ExportKind.project,
          templateId: _controller.recordId,
          fileName: '${_joodFileName(_controller.title)}.${JoodFormat.extension}',
        ),
      );
      context.showSuccess(readyMessage);
    } catch (error) {
      if (!mounted) return;
      debugPrint('[مشروع Jood] تعذّر تصدير الملف: $error');
      context.showError(failedMessage);
    } finally {
      if (mounted) setState(() => _isExportingJood = false);
    }
  }

  /// يفتح ملف ‎.jood‎ عبر منتقي الملفات، يدمج أصوله وخطوطه بمعرّفاتها الأصلية،
  /// ثم يُحمّل مستنده في المحرّر فوراً (بلا مغادرة الشاشة).
  Future<void> _importJood() async {
    if (_isImportingJood) return;
    setState(() => _isImportingJood = true);
    try {
      final List<PlatformFile> picked = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: <String>[JoodFormat.extension],
        dialogTitle: context.l10n?.joodImportProject ?? 'فتح مشروع (.jood)',
      );
      if (picked.isEmpty) return;
      final Uint8List bytes = await picked.first.readAsBytes();

      final JoodProject project =
          await const JoodProjectImporter().readAndRestore(
        bytes,
        assets: AssetsController.instance,
        fonts: CustomFontController.instance,
      );
      AssetImageCache.instance.clear();
      _controller.loadDocument(
        project.document,
        asClean: true,
        title: project.title,
      );
      unawaited(warmDocumentImageCache(project.document));
      // المشروع المستورد نظيف ومحفوظ صراحةً — لا حاجة لمسودة استعادة.
      await _autosave.discard();
      if (!mounted) return;
      context.showSuccess(
        context.l10n?.joodImportOpened ?? 'تم فتح المشروع المستورد.',
      );
    } on JoodArchiveException catch (error) {
      if (!mounted) return;
      context.showError(error.message);
    } on Object catch (error) {
      if (!mounted) return;
      debugPrint('[مشروع Jood] تعذّر استيراد الملف: $error');
      context.showError(
        context.l10n?.joodImportFailed ?? 'تعذّر فتح ملف المشروع.',
      );
    } finally {
      if (mounted) setState(() => _isImportingJood = false);
    }
  }

  /// اسم ملف آمن لمشروع ‎.jood‎ من عنوان القالب.
  static String _joodFileName(String title) {
    final String clean =
        title.trim().replaceAll(RegExp(r'[\\/:*?"<>|]+'), '_').trim();
    return clean.isEmpty ? 'joodcraft-project' : clean;
  }

  /// إدراج إطار/شعار مرفوع كخلفية للمستند (خلف كل العناصر) بمرجع `userAsset`.
  ///
  /// يظهر على اللوحة وفي الـ PDF المطبوع مباشرةً لأن محرّك الطباعة يحلّ
  /// `ImageSourceKind.userAsset` من مكتبة الأصول المحلية.
  Future<void> _pickBackgroundFromLibrary() async {
    // تُعرض **كل** الأنواع المرفوعة (إطارات/شعارات/أختام/توقيعات) لا الإطارات
    // والشعارات فقط — الختم قد يُستخدم علامة مائية والتوقيع قد يُدرَج كطبقة،
    // وحصر المنتقي سابقاً كان يُخفي الأختام والتوقيعات عن المستخدم تماماً.
    final UserAsset? asset = await showAssetLibraryPicker(
      context,
      title: context.l10n?.tevBackgroundTitle ?? 'خلفية المستند من مكتبة أصولي',
    );
    if (asset == null || !mounted) return;

    final TemplateElement element = ElementFactory.fromUserAsset(
      asset: asset,
      design: _controller.designSize,
      asBackground: true,
    );
    _controller.insertElement(element, index: 0);
    context.showSuccess(
      context.l10n?.tevBackgroundAdded(asset.name) ??
          'أُضيف «${asset.name}» كخلفية للمستند.',
    );
  }

  // ==========================================================================
  //  المحرر
  // ==========================================================================
  Widget _editorPanel() {
    return Focus(
      focusNode: _canvasFocusNode,
      autofocus: true,
      onKeyEvent: _onKeyEvent,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (BuildContext context, Widget? _) {
              final double panelWidth = _panelWidth(constraints);
              final bool hasPanel = panelWidth > 0;

              return Stack(
                // مرجع الإحداثيات الذي تُحسب داخله سحب اللوحة والتقاطها
                // المغناطيسي (نفس أبعاد مساحة عمل الورقة).
                key: _canvasViewportKey,
                children: <Widget>[
                  Positioned.fill(
                    // اللوحة تُزاح عن الشريط العائم بدل أن يُغطى جزء منها:
                    // ما يراه المستخدم هو الورقة كاملة ° دائماً.
                    child: AnimatedPadding(
                      duration: const Duration(milliseconds: 170),
                      curve: Curves.easeOutCubic,
                      padding: EdgeInsets.only(
                        right:
                            hasPanel ? panelWidth + AppTheme.space12 : 0,
                      ),
                      child: ClipRect(
                        child: DecoratedBox(
                          key: const ValueKey<String>('editor-canvas-viewport'),
                        decoration: BoxDecoration(
                          // تباين الورقة: مساحة عمل **أفتح من الهيكل الموحّد**
                          // في الوضعين (رمادي `#4A4A4A` ليلاً وغسيل كحلي
                          // نهاراً) فيقلّ التباين الحادّ حول الورقة البيضاء
                          // وتبقى حدودها واضحة بظل ناعم (راجع `canvasViewport`).
                          color: Theme.of(context).colorScheme.canvasViewport,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusLg),
                        ),
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onDoubleTap: () => setState(() {
                              _zoom = 1.0;
                              _panOffset = Offset.zero;
                            }),
                            child: Listener(
                              behavior: HitTestBehavior.opaque,
                              onPointerDown: (PointerDownEvent event) {
                                _endNudge();
                                _canvasFocusNode.requestFocus();
                                _showScrollbarsTemporarily();
                                final HardwareKeyboard keyboard = HardwareKeyboard.instance;
                                if (keyboard.isControlPressed || keyboard.isMetaPressed) {
                                  setState(() => _isPanningWithCtrl = true);
                                }
                              },
                              onPointerMove: (PointerMoveEvent event) {
                                if (_isPanningWithCtrl) {
                                  _showScrollbarsTemporarily();
                                  setState(() {
                                    _panOffset += event.delta;
                                  });
                                }
                              },
                              onPointerUp: (PointerUpEvent _) {
                                if (_isPanningWithCtrl) {
                                  setState(() => _isPanningWithCtrl = false);
                                }
                              },
                              onPointerCancel: (PointerCancelEvent _) {
                                if (_isPanningWithCtrl) {
                                  setState(() => _isPanningWithCtrl = false);
                                }
                              },
                              onPointerSignal: (PointerSignalEvent event) {
                                if (event is PointerScrollEvent) {
                                  _showScrollbarsTemporarily();
                                  final HardwareKeyboard keyboard = HardwareKeyboard.instance;
                                  final bool isCtrl = keyboard.isControlPressed || keyboard.isMetaPressed;
                                  final bool isAlt = keyboard.isAltPressed;
                                  // سرعة معتدلة ومتوازنة (ليست سريعة ولا بطيئة)
                                  const double speed = 0.5;
                                  final double rawDy = event.scrollDelta.dy;

                                  if (isAlt) {
                                    // Alt + بكرة الماوس: تكبير/تصغير عند نقطة سهم الماوس بدقة 100%
                                    if (rawDy != 0) {
                                      final double factor = rawDy < 0 ? 1.08 : 0.92;
                                      final double newZoom = (_zoom * factor).clamp(0.15, 5.0);
                                      if (newZoom != _zoom) {
                                        final Offset mousePos = event.localPosition;
                                        final double ratio = newZoom / _zoom;
                                        // مركز الـ viewport (نقطة ارتكاز Center widget الداخلية)
                                        final Offset vpCenter = Offset(
                                          _canvasViewportSize.width / 2,
                                          _canvasViewportSize.height / 2,
                                        );
                                        // المعادلة الصحيحة:
                                        // النقطة تحت الماوس في فضاء المحتوى (نسبةً لمركز الـ viewport)
                                        // = (mousePos - vpCenter - panOffset) / oldZoom
                                        // نريدها تبقى ثابتة بعد تغيير الزوم:
                                        // newPan = panOffset - (ratio - 1) * (mousePos - vpCenter - panOffset)
                                        // (`Offset * double` لا `double * Offset`: الحزمة لا تقبل إزاحة كعامل أيسر.)
                                        final Offset newPan = _panOffset - (mousePos - vpCenter - _panOffset) * (ratio - 1);
                                        setState(() {
                                          _zoom = newZoom;
                                          _panOffset = newPan;
                                        });
                                      }
                                    }
                                  } else if (isCtrl) {
                                    // Ctrl + بكرة الماوس: تمرير أفقي (فوق=يمين، تحت=شمال)
                                    setState(() {
                                      _panOffset -= Offset(rawDy * speed, 0);
                                    });
                                  } else {
                                    // بكرة الماوس وحدها أو مع Shift: تمرير رأسي (فوق=فوق، تحت=تحت)
                                    setState(() {
                                      _panOffset -= Offset(0, rawDy * speed);
                                    });
                                  }
                                }
                              },
                              child: LayoutBuilder(
                                builder: (BuildContext context, BoxConstraints vpConstraints) {
                                  _canvasViewportSize = Size(vpConstraints.maxWidth, vpConstraints.maxHeight);
                                  return Stack(
                                children: <Widget>[
                                  Positioned.fill(
                                    child: Transform.translate(
                                      offset: _panOffset,
                                      child: IgnorePointer(
                                        ignoring: _isPanningWithCtrl,
                                        child: TemplateCanvas(
                                          controller: _controller,
                                          zoom: _zoom,
                                          showGrid: _showGrid,
                                          snapToGuides: _snapToGuides,
                                          paperKey: _paperCaptureKey,
                                          onRequestTextEdit: (_) {},
                                        ),
                                      ),
                                    ),
                                  ),
                                  // شريط التحكم بالسلايدر الأفقي في أسفل مساحة Viewport (يختفي بعد 3 ثوانٍ من عدم الحركة)
                                  Positioned(
                                    left: 40,
                                    right: 40,
                                    bottom: 8,
                                    child: AnimatedOpacity(
                                      duration: const Duration(milliseconds: 250),
                                      opacity: _showScrollbars ? 0.75 : 0.0,
                                      child: IgnorePointer(
                                        ignoring: !_showScrollbars,
                                        child: SliderTheme(
                                          data: SliderThemeData(
                                            trackHeight: 3,
                                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                            activeTrackColor: Theme.of(context).colorScheme.primary,
                                            inactiveTrackColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15),
                                          ),
                                          child: Slider(
                                            value: _panOffset.dx.clamp(-1500.0, 1500.0),
                                            min: -1500.0,
                                            max: 1500.0,
                                            onChanged: (double value) {
                                              _showScrollbarsTemporarily();
                                              setState(() {
                                                _panOffset = Offset(value, _panOffset.dy);
                                              });
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // شريط التحكم بالسلايدر الرأسي في يمين مساحة Viewport (يختفي بعد 3 ثوانٍ من عدم الحركة)
                                  Positioned(
                                    top: 40,
                                    bottom: 40,
                                    right: 8,
                                    child: AnimatedOpacity(
                                      duration: const Duration(milliseconds: 250),
                                      opacity: _showScrollbars ? 0.75 : 0.0,
                                      child: IgnorePointer(
                                        ignoring: !_showScrollbars,
                                        child: RotatedBox(
                                          quarterTurns: 1,
                                          child: SliderTheme(
                                            data: SliderThemeData(
                                              trackHeight: 3,
                                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                              activeTrackColor: Theme.of(context).colorScheme.primary,
                                              inactiveTrackColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15),
                                            ),
                                            child: Slider(
                                              value: _panOffset.dy.clamp(-1500.0, 1500.0),
                                              min: -1500.0,
                                              max: 1500.0,
                                              onChanged: (double value) {
                                                _showScrollbarsTemporarily();
                                                setState(() {
                                                  _panOffset = Offset(_panOffset.dx, value);
                                                });
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    ),
                  ),
                ),
                  // لوحة الأدوات القابلة للإرساء: شريط رأسي رفيع (نمط
                  // Photoshop) يطفو على يسار اللوحة فلا يحجب الورقة ولا
                  // يقتطع من مساحة التصميم — أو عائمة حيث أسقطها المستخدم.
                  if (constraints.maxWidth >= 640 &&
                      _dock.tools.slot == DockSlot.leftRail)
                    Positioned(
                      left: AppTheme.space12,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: _dockedToolPalette(context, axis: Axis.vertical),
                      ),
                    ),
                  if (_dock.tools.slot == DockSlot.floating)
                    Positioned(
                      left: _dock.tools.dx,
                      top: _dock.tools.dy,
                      child: _dockedToolPalette(context, axis: Axis.vertical),
                    ),
                  if (_panelCollapsed && constraints.maxWidth >= 700)
                    Positioned(
                      top: AppTheme.space12,
                      right: AppTheme.space4,
                      child: IconAction(
                        key: const ValueKey<String>('panel-expand-button'),
                        icon: Icons.chevron_left_rounded,
                        tooltip: context.l10n?.editorExpandPanel ??
                            'إظهار اللوحة الجانبية',
                        onPressed: () =>
                            setState(() => _panelCollapsed = false),
                      ),
                    ),
                  if (hasPanel)
                    Positioned(
                      top: AppTheme.space12,
                      bottom: AppTheme.space12,
                      right: AppTheme.space12,
                      child: SizedBox(
                        width: panelWidth,
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              // لوحة الأدوات بعد إرسائها في اللوحة الجانبية
                              // (أفقيّة، محفوظة بنفس أزرارها وتلميحاتها).
                              if (_dock.tools.slot == DockSlot.inspector) ...<
                                  Widget>[
                                _dockedToolPalette(context,
                                    axis: Axis.horizontal),
                                const SizedBox(height: AppTheme.space12),
                              ],
                              // شريط الخصائص أولاً كي يبقى موضع أدوات العنصر
                              // المحدد ثابتاً كما اعتاده المستخدم، ثم لوحة
                              // الطبقات أسفله (ظاهرة دائماً بلا تحديد).
                              if (_controller.hasSelection) ...<Widget>[
                                PropertyToolbar(
                                  controller: _controller,
                                  textFocusNode: _textFocusNode,
                                  maxWidth: panelWidth,
                                ),
                                const SizedBox(height: AppTheme.space12),
                              ],
                              LayersPanel(controller: _controller),
                              const SizedBox(height: AppTheme.space12),
                              // عناصر الهوية الجاهزة: إدراج سريع للأختام/التوقيعات
                              // وبناء الترويسة/التذييل وتطبيق الألوان.
                              BrandPresetsPanel(
                                controller: _controller,
                                onOpenSettings: () =>
                                    context.go(AppRoutes.brand),
                              ),
                              const SizedBox(height: AppTheme.space8),
                              // طيّ اللوحة لمزيد من مساحة التصميم.
                              Align(
                                alignment: AlignmentDirectional.centerEnd,
                                child: IconAction(
                                  key: const ValueKey<String>(
                                      'panel-collapse-button'),
                                  icon: Icons.chevron_right_rounded,
                                  tooltip: context.l10n?.editorCollapsePanel ??
                                      'طيّ اللوحة الجانبية',
                                  onPressed: () => setState(
                                      () => _panelCollapsed = true),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  // مؤشّر الالتقاط المغناطيسي أثناء سحب لوحة الأدوات.
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DockSnapIndicator(
                        dock: _dock,
                        slotLabel: _dockSlotLabel,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  /// عرض شريط الخصائص العائم (صفر عندما لا يوجد تحديد).
  ///
  /// عرض محدود على جانب اللوحة لا في وسطها، ومحتواه يُمرَّر داخلياً — فلا
  /// يحجب مساحة التصميم مهما كان حجم النافذة.
  double _panelWidth(BoxConstraints constraints) {
    // اللوحة الجانبية دائمة الظهور (لوحة الطبقات + شريط الخصائص) لأن الطبقات
    // أداة تنسيق لا تخصّ عنصراً محدّداً؛ ومع ذلك تختفي على الشاشات الضيقة جداً
    // حيث لا يبقى للورقة متسع، فيبقى المحرّر صالحاً على الهاتف.
    if (_panelCollapsed) return 0;
    if (constraints.maxWidth < 700) return 0;
    // على الشاشات الواسعة نُضيّق اللوحة الجانبية لتوسيع مساحة التصميم،
    // مع إبقاء حدّها الأدنى كما كان حتى لا تنضغط أدوات المفتش الرأسية
    // (منتقيات الخط/الحقول) فتفيض على الشاشات الضيقة.
    return math.min(360, math.max(300, constraints.maxWidth * 0.42));
  }

  Widget _bottomBar(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space16,
        vertical: AppTheme.space12,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outline)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.add_circle_outline_rounded,
                  size: 15, color: scheme.goldDeep),
              const SizedBox(width: 6),
              Text(
                context.l10n?.tevAddElement ?? 'إضافة عنصر',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space8),
          ElementPaletteBar(controller: _controller),
        ],
      ),
    );
  }

  // ==========================================================================
  //  معاينة الـ PDF
  // ==========================================================================
  Widget _previewPanel() {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: PdfTemplatePreview(
        key: const ValueKey<String>('editor-live-preview'),
        document: _controller.document,
        revision: _previewRevision,
        exportFileName: widget.exportFileName,
        dataPanelTitle: context.l10n?.commonDataPanelTitle ?? 'بيانات تجريبية',
      ),
    );
  }

  void _setMode(EditorViewMode mode) {
    setState(() {
      _mode = mode;
      // كل انتقال إلى المعاينة يُنشئ نسخة مطابقة للحالة الحالية للمحرر.
      if (mode == EditorViewMode.preview) _previewRevision++;
    });
  }

  // ==========================================================================
  //  الحفظ والفتح
  // ==========================================================================
  Future<void> _save({bool saveAs = false}) async {
    if (!_controller.canPersist) {
      context.showWarning(
        context.l10n?.tevSaveNeedsSupabase ??
            'الحفظ المحلي غير متاح في هذه الجلسة — تعذّر فتح مخزن المشاريع '
                'على هذا الجهاز.',
      );
      return;
    }

    // تنبيه غير مُعطِّل: القالب يُحفظ، لكن عنصراً بلا أصل سيبدو فارغاً لاحقاً.
    final List<String> missing = missingAssetReferences(_controller.document);
    if (missing.isNotEmpty) {
      context.showWarning(
        context.l10n?.tevMissingAssets(missing.join('، ')) ??
            'أصول مفقودة: ${missing.join('، ')} — أعد اختيار الإطار/الأصل من '
                '«مكتبة أصولي» لتفادي ظهورها فارغة.',
      );
    }

    String? title = _controller.title;
    if (saveAs || _controller.recordId == null) {
      title = await _askTitle(initial: _controller.title);
      if (title == null || !mounted) return;
    }

    try {
      final TemplateRecord saved = await _controller.save(title: title);
      // بديل المشروع للبطاقات: يُلتقط بعد الحفظ فقط (النصّ هو الذي صار محفوظاً
      // فعلاً)، ولا يؤخّر شيئاً ولا يرمي — فشله يعني «مشروع بلا صورة مصغّرة».
      unawaited(_captureThumbnail(saved.id));
    } on AppException catch (error) {
      if (!mounted) return;
      context.showError(error.message);
    }
  }

  /// يلتقط ورقة التصميم ويخزّن الصورة المصغّرة محلياً ثم يربطها بالمشروع.
  Future<void> _captureThumbnail(String projectId) async {
    final String? path = await ProjectThumbnails.capture(
      _paperCaptureKey,
      projectId: projectId,
    );
    if (path == null) return;
    await ProjectsController.instance.attachThumbnail(projectId, path);
  }

  Future<void> _openLibrary() async {
    if (!_library.isAvailable) {
      context.showWarning(
        context.l10n?.tevTemplateLibraryNeedsSupabase ??
            'مكتبة المشاريع المحلية غير متاحة في هذه الجلسة.',
      );
      return;
    }
    unawaited(_library.refresh());
    final TemplateRecord? record = await showDialog<TemplateRecord>(
      context: context,
      builder: (BuildContext dialogContext) =>
          _TemplateLibraryDialog(library: _library),
    );
    if (record == null || !mounted) return;

    // قالب جديد قد يستخدم أصولاً مختلفة — نُفرّغ ذاكرة الصور المرتبطة بالقديم.
    AssetImageCache.instance.clear();
    final TemplateDocument document = record.toDocument();
    _controller.loadDocument(
      document,
      asClean: true,
      recordId: record.id,
      title: record.title,
    );
    // إعادة تسخين الذاكرة من الكاش القرصي بدل إعادة فكّ Base64 لكل صورة عند
    // أول رسم — غير حاجزة كي لا يتأخّر فتح القالب.
    unawaited(warmDocumentImageCache(document));
    context.showSuccess(
      context.l10n?.tevOpenedTemplate(record.title) ??
          'تم فتح «${record.title}».',
    );
  }

  /// نافذة عنوان القالب.
  ///
  /// المتحكم بالحقل مملوك للنافذة نفسها: لو حُرّر عند انتهاء `Future`
  /// لحظياً (وما زالت نافذة الحوار تُحرّك خروجها) لانهارت الشجرة أثناء
  /// حركة الإغلاق — وهذا ما حدث فعلاً واكتشفه الاختبار.
  Future<String?> _askTitle({required String initial}) {
    return showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) =>
          _TemplateTitleDialog(initial: initial),
    );
  }

  // ==========================================================================
  //  اختصارات لوحة المفاتيح
  // ==========================================================================
  /// هل يكتب المستخدم فعلاً داخل حقل نصي؟
  ///
  /// عندها تُترك الاختصارات لحقل النص (نسخ/قص/لصق/تدوير… داخل الحقل) ولا
  /// تُنفَّذ على اللوحة — وهذا ما يمنع "قفزة" العنصر أثناء الكتابة.
  bool get _isEditingText {
    if (_textFocusNode.hasFocus) return true;
    final BuildContext? context = FocusManager.instance.primaryFocus?.context;
    if (context == null) return false;
    if (context.widget is EditableText) return true;
    return context.findAncestorWidgetOfExactType<EditableText>() != null;
  }

  /// اختصارات لوحة المفاتيح بأعراف الفوتوشوب — تُطبّق على كل التحديد.
  ///
  /// * أسهم: 1px (ومع Shift: 10px) — واستمرار الضغط على السهم يُسجَّل في
  ///   التراجع كخطوة واحدة بدل حركة لكل تكرار مفتاح.
  /// * `Ctrl+C/X/V`: نسخ/قص/لصق — `Ctrl+D`: تكرار — `Ctrl+A`: تحديد الكل.
  /// * `Ctrl+Z`: تراجع — `Ctrl+Shift+Z` أو `Ctrl+Y`: إعادة.
  /// * `Ctrl+[`/`]`: خطوة للخلف/الأمام — ومع Shift: إلى الخلف/المقدمة تماماً.
  /// * `Ctrl+Shift+D`: تبديل اتجاه النص (عربي ↔ لاتيني) — يعمل حتى أثناء
  ///   الكتابة داخل حقل النص فيتحرّك المؤشر في الاتجاه الجديد فوراً.
  /// * `Delete`/`Backspace`: حذف — `Esc`: إلغاء التحديد.
  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    // إفلات مفتاح أسهم يُغلق جلسة النقل المفتوحة فوراً؛ وأي مفتاح آخر قبله
    // يُغلقها أيضاً كي يُسجَّل وحده في التاريخ (حذف/تراجع/…) بلا امتزاج مع
    // حركة الأسهم السابقة.
    if (event is KeyUpEvent && _isArrowKey(event.logicalKey)) {
      _endNudge();
      return KeyEventResult.ignored;
    }

    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    if (!_isArrowKey(event.logicalKey)) _endNudge();

    final HardwareKeyboard keyboard = HardwareKeyboard.instance;
    final bool control = keyboard.isControlPressed || keyboard.isMetaPressed;
    final bool shift = keyboard.isShiftPressed;

    // تبديل اتجاه النص يُعالَج **قبل** حماية حقول الإدخال كي يعمل أثناء الكتابة،
    // فينقلب اتجاه حقل النص ومؤشره ومفاتيح الأسهم فيه في الحال بدل انتظار
    // الخروج من الحقل.
    if (control && shift && event.logicalKey == LogicalKeyboardKey.keyD) {
      _toggleTextDirection();
      return KeyEventResult.handled;
    }

    // لا تسرق أي مفتاح آخر أثناء الكتابة داخل حقول الإدخال.
    if (_isEditingText) return KeyEventResult.ignored;

    final double step = shift ? 10 : 1;
    final KeyEventResult handled = KeyEventResult.handled;

    if (control) {
      switch (event.logicalKey) {
        case LogicalKeyboardKey.keyC:
          _controller.copySelection();
          return handled;
        case LogicalKeyboardKey.keyX:
          _controller.cutSelection();
          return handled;
        case LogicalKeyboardKey.keyV:
          _controller.pasteClipboard();
          return handled;
        case LogicalKeyboardKey.keyD:
          _controller.duplicateSelected();
          return handled;
        case LogicalKeyboardKey.keyA:
          _controller.selectAll();
          return handled;
        case LogicalKeyboardKey.keyZ:
          shift ? _controller.redo() : _controller.undo();
          return handled;
        case LogicalKeyboardKey.keyY:
          _controller.redo();
          return handled;
        case LogicalKeyboardKey.bracketLeft:
          shift ? _controller.sendToBack() : _controller.sendBackward();
          return handled;
        case LogicalKeyboardKey.bracketRight:
          shift ? _controller.bringToFront() : _controller.bringForward();
          return handled;
        case LogicalKeyboardKey.keyS:
          unawaited(_save());
          return handled;
      }
      return KeyEventResult.ignored;
    }

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowLeft:
        return _nudge(-step, 0, handled);
      case LogicalKeyboardKey.arrowRight:
        return _nudge(step, 0, handled);
      case LogicalKeyboardKey.arrowUp:
        return _nudge(0, -step, handled);
      case LogicalKeyboardKey.arrowDown:
        return _nudge(0, step, handled);
      case LogicalKeyboardKey.delete:
      case LogicalKeyboardKey.backspace:
        if (!_controller.hasSelection) return KeyEventResult.ignored;
        _controller.deleteSelected();
        return handled;
      case LogicalKeyboardKey.escape:
        _controller.clearSelection();
        return handled;
    }
    return KeyEventResult.ignored;
  }

  /// يبدّل اتجاه عناصر النص المحددة (عربي ↔ لاتيني) عبر المتحكم.
  ///
  /// لا يُظهر إشعاراً: الانقلاب يظهر مباشرةً في اللوحة وفي مفتاح «الاتجاه»
  /// وفي اتجاه حقل النص — والإشعار المتكرّر أثناء الكتابة إزعاج لا فائدة فيه.
  void _toggleTextDirection() {
    _controller.toggleSelectedTextDirection();
  }

  /// هل المفتاح أحد أسهم الاتجاهات الأربع؟
  static bool _isArrowKey(LogicalKeyboardKey key) =>
      key == LogicalKeyboardKey.arrowLeft ||
      key == LogicalKeyboardKey.arrowRight ||
      key == LogicalKeyboardKey.arrowUp ||
      key == LogicalKeyboardKey.arrowDown;

  /// نقل العنصر المحدد بمقدار (dx, dy) ضمن جلسة نقل واحدة للتراجع.
  ///
  /// أول ضغطة تفتح الجلسة (تُسجَّل حالة ما قبل الحركة مرة واحدة في التاريخ)،
  /// وتكرارات المفتاح أثناء الاستمرار تحرّك داخلها دون إدخالات جديدة، ويُغلق
  /// الجلسة إفلات المفتاح أو مؤقّت الأمان أو أي مفتاح/نقر آخر.
  KeyEventResult _nudge(double dx, double dy, KeyEventResult handled) {
    if (!_controller.hasSelection) return KeyEventResult.ignored;
    if (!_nudging) {
      _nudging = true;
      _controller.beginInteraction();
    }
    _controller.moveSelectedBy(dx, dy, snap: false);
    _nudgeSettleTimer?.cancel();
    _nudgeSettleTimer = Timer(_nudgeSettleDelay, _endNudge);
    return handled;
  }

  /// إغلاق جلسة النقل المفتوحة (إن وُجدت) وإلغاء مؤقّت الأمان.
  void _endNudge() {
    _nudgeSettleTimer?.cancel();
    _nudgeSettleTimer = null;
    if (!_nudging) return;
    _nudging = false;
    _controller.endInteraction();
  }
}

/// اختيار المستخدم في نافذة «تعديلات غير محفوظة».
enum _LeaveChoice { save, discard, cancel }

/// نافذة إدخال عنوان القالب (تملك متحكم الحقل وتُنظّفه بنفسها).
class _TemplateTitleDialog extends StatefulWidget {
  const _TemplateTitleDialog({required this.initial});

  final String initial;

  @override
  State<_TemplateTitleDialog> createState() => _TemplateTitleDialogState();
}

class _TemplateTitleDialogState extends State<_TemplateTitleDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.of(context).pop(_controller.text.trim());

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n?.tplRenameTitle ?? 'عنوان القالب'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,
        decoration: InputDecoration(
          labelText: context.l10n?.tplFieldTitle ?? 'العنوان',
          hintText: context.l10n?.tevTitleHint ??
              'مثال: شهادة إتمام دورة إدارة المشاريع',
        ),
        onSubmitted: (String value) => _submit(),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n?.editorCancel ?? 'إلغاء'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(context.l10n?.tevContinue ?? 'متابعة'),
        ),
      ],
    );
  }
}

/// نافذة "قوالبي": عرض قوالب المستخدم وفتحها أو حذفها.
class _TemplateLibraryDialog extends StatelessWidget {
  const _TemplateLibraryDialog({required this.library});

  final TemplateLibraryController library;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: <Widget>[
          Icon(Icons.collections_bookmark_rounded,
              size: 18, color: Theme.of(context).colorScheme.goldDeep),
          const SizedBox(width: 8),
          Text(context.l10n?.tevSavedTemplates ?? 'قوالبي المحفوظة'),
        ],
      ),
      content: SizedBox(
        width: 480,
        height: 380,
        child: AnimatedBuilder(
          animation: library,
          builder: (BuildContext context, Widget? _) {
            if (library.isBusy) {
              return const Center(child: CircularProgressIndicator());
            }
            final String? error = library.errorMessage;
            if (error != null) {
              return Center(
                child: Text(error, textAlign: TextAlign.center),
              );
            }
            if (library.templates.isEmpty) {
              return Center(
                child: Text(
                  context.l10n?.tevNoSavedTemplates ??
                      'لا توجد قوالب محفوظة بعد.\nاحفظ قالباً من الزر «حفظ القالب».',
                  textAlign: TextAlign.center,
                ),
              );
            }
            return ListView.separated(
              itemCount: library.templates.length,
              separatorBuilder: (BuildContext context, int index) =>
                  const Divider(height: 1),
              itemBuilder: (BuildContext context, int index) {
                final TemplateRecord record = library.templates[index];
                return ListTile(
                  title: Text(record.title),
                  subtitle: Text(
                    '${record.category.labelAr} • '
                    '${record.orientation.labelAr}'
                    '${record.updatedAt == null ? '' : ' • ${_formatDate(record.updatedAt!)}'}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  leading: Icon(Icons.description_outlined,
                      color: Theme.of(context).colorScheme.primary),
                  trailing: IconButton(
                    tooltip: context.l10n?.tplDelete ?? 'حذف',
                    icon: Icon(Icons.delete_outline_rounded,
                        color: Theme.of(context).colorScheme.danger, size: 18),
                    onPressed: () async {
                      try {
                        await library.remove(record.id);
                      } on AppException catch (failure) {
                        if (!context.mounted) return;
                        context.showError(failure.message);
                      }
                    },
                  ),
                  onTap: () => Navigator.of(context).pop(record),
                );
              },
            );
          },
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n?.editorClose ?? 'إغلاق'),
        ),
      ],
    );
  }

  static String _formatDate(DateTime value) {
    String two(int number) => number.toString().padLeft(2, '0');
    return '${value.year}/${two(value.month)}/${two(value.day)} '
        '${two(value.hour)}:${two(value.minute)}';
  }
}
