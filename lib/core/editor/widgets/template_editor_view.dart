import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';

import '../../assets/asset_image_cache.dart';
import '../../assets/embedded_assets.dart';
import '../../assets/user_asset.dart';
import '../../constants/app_assets.dart';
import '../../constants/app_constants.dart';
import '../../errors/app_exception.dart';
import '../../l10n/app_l10n.dart';
import '../../models/template_document.dart';
import '../../models/template_element.dart';
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
import '../element_factory.dart';
import '../template_editor_controller.dart';
import 'asset_library_picker.dart';
import 'editor_controls.dart';
import 'property_toolbar.dart';
import 'template_canvas.dart';

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

  /// معالج المغادرة المسجَّل في [UnsavedChangesGuard] — نحتفظ به كحقل لضمان
  /// أن إزالته عند التخلّص تُطابق نسخة التسجيل نفسها.
  late final Future<bool> Function() _leaveHandler = _confirmLeave;

  /// علم مؤقّت يسمح بالخروج البرمجي بعد تأكيد المستخدم (يتجاوز `PopScope`).
  bool _allowPop = false;

  double _zoom = 1;
  bool _showGrid = true;
  bool _snapToGuides = true;
  EditorViewMode _mode = EditorViewMode.editor;
  int _previewRevision = 0;
  bool _isExporting = false;

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
    // نافذة «قوالبي» داخل المحرّر تعرض القوالب السحابية فقط، فلا داعي لفتح
    // المخزن المحلي (يتفادى اعتماداً غير ضروري على المنصة).
    _library = TemplateLibraryController(
      widget.repository,
      localStore: InMemoryLocalTemplateStore(),
    );

    if (widget.document == null) {
      // تحميل القالب النموذجي المحزوم — بلا أي شبكة.
      unawaited(_bootstrapFromAsset());
    } else {
      _applyInitialSelection();
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
    _textFocusNode.dispose();
    _canvasFocusNode.dispose();
    // تحرير البايتات المفكوكة عند إغلاق المحرّر حتى لا تتراكم صور الإطار
    // والخلفيات عالية الدقة في الذاكرة مع الاستخدام المطوّل.
    AssetImageCache.instance.clear();
    super.dispose();
  }

  /// إظهار رسالة نجاح الحفظ مرة واحدة.
  void _onControllerChanged() {
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
  Widget _header(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? _) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.space16,
            vertical: AppTheme.space12,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              bottom: BorderSide(color: Theme.of(context).colorScheme.outline),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Wrap(
                spacing: AppTheme.space12,
                runSpacing: AppTheme.space8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  _titleChip(context),
                  SegmentedField<EditorViewMode>(
                    label: context.l10n?.tevViewMode ?? 'طريقة العرض',
                    value: _mode,
                    options: EditorViewMode.values,
                    labelOf: (EditorViewMode mode) =>
                        mode == EditorViewMode.editor ? context.l10n?.tevModeEditor ?? 'المحرر' : context.l10n?.tevModePreview ?? 'معاينة PDF',
                    iconOf: (EditorViewMode mode) => mode == EditorViewMode.editor
                        ? Icons.design_services_rounded
                        : Icons.picture_as_pdf_rounded,
                    onChanged: _setMode,
                  ),
                  SegmentedField<PageOrientation>(
                    label: context.l10n?.tevPaperDirection ?? 'اتجاه الورقة',
                    value: _controller.document.orientation,
                    options: PageOrientation.values,
                    labelOf: (PageOrientation orientation) =>
                        orientation.isLandscape ? context.l10n?.tplOrientationLandscape ?? 'أفقي' : context.l10n?.tplOrientationPortrait ?? 'رأسي',
                    iconOf: (PageOrientation orientation) =>
                        orientation.isLandscape
                            ? Icons.crop_landscape_rounded
                            : Icons.crop_portrait_rounded,
                    onChanged: _controller.setOrientation,
                  ),
                  // شريط إعدادات الصفحة المتجاوز (أفقي) — خيارات المقاسات القياسية
  // ومقاس مخصّص بالسنتيمتر/المليمتر/البوصة مع التحويل التلقائي إلى نقاط.
  if (_controller.document.customPageSize == null)
    Wrap(
      spacing: AppTheme.space8,
      runSpacing: AppTheme.space8,
      children: <Widget>[
        DropdownField<PaperSize>(
          label: context.l10n?.editorPageSize ?? 'المقاس',
          value: _controller.document.paperSize,
          items: PaperSize.values,
          labelOf: (PaperSize size) => size.labelAr,
          width: 110,
          onChanged: _controller.setPaperSize,
        ),
      ],
    )
  else
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: DropdownField<MeasurementUnit>(
                label: context.l10n?.editorUnit ?? 'الوحدة',
                value: _controller.document.customPageSize!.unit,
                items: MeasurementUnit.values,
                labelOf: (MeasurementUnit unit) => unit.labelAr,
                width: 110,
                onChanged: (MeasurementUnit unit) => _controller.setCustomPageSize(
                  _controller.document.customPageSize!.width,
                  _controller.document.customPageSize!.height,
                  unit,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: NumberField(
                label: context.l10n?.tevWidthCm ?? 'العرض (cm)',
                value: _controller.document.customPageSize!.width,
                min: 1,
                max: 500,
                decimals: 2,
                onChanged: (double width) => _controller.setCustomPageSize(
                  width,
                  _controller.document.customPageSize!.height,
                  _controller.document.customPageSize!.unit,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: NumberField(
                label: context.l10n?.tevHeightCm ?? 'الارتفاع (cm)',
                value: _controller.document.customPageSize!.height,
                min: 1,
                max: 500,
                decimals: 2,
                onChanged: (double height) => _controller.setCustomPageSize(
                  _controller.document.customPageSize!.width,
                  height,
                  _controller.document.customPageSize!.unit,
                ),
              ),
            ),
          ],
        ),
        Text(
          '${_controller.document.customPageSize!.width.toStringAsFixed(2)} × '
          '${_controller.document.customPageSize!.height.toStringAsFixed(2)} '
          '→ ${_controller.paperSizeLabel}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontFamily: AppAssets.cairoFont,
          ),
        ),
      ],
    ),
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
                    onPressed: () =>
                        setState(() => _snapToGuides = !_snapToGuides),
                  ),
                  if (_mode == EditorViewMode.editor)
                    SliderField(
                      label: context.l10n?.tevZoom ?? 'التكبير',
                      value: _zoom,
                      min: 0.5,
                      max: 3,
                      width: 150,
                      display: (double value) => '${(value * 100).round()}%',
                      onChanged: (double value) => setState(() => _zoom = value),
                    ),
                ],
              ),
              const SizedBox(height: AppTheme.space12),
              Wrap(
                spacing: AppTheme.space12,
                runSpacing: AppTheme.space8,
                crossAxisAlignment: WrapCrossAlignment.end,
                children: <Widget>[
                  ColorField(
                    label: context.l10n?.tevDocumentBackground ?? 'خلفية المستند',
                    hex: _controller.document.backgroundHex,
                    width: 200,
                    onChanged: _controller.setBackgroundHex,
                  ),
                  OutlinedButton.icon(
                    key: const ValueKey<String>('document-background-library'),
                    onPressed: _pickBackgroundFromLibrary,
                    icon: const Icon(Icons.collections_bookmark_rounded,
                        size: 16),
                    label: Text(context.l10n?.tevFrameFromLibrary ?? 'إطار من مكتبة أصولي'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 44),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                    ),
                  ),
                  Text(
                    '${context.l10n?.evElementCount(_controller.document.drawableElementCount) ?? '${_controller.document.drawableElementCount} عنصراً'}'
                    '${_controller.hasDynamicFields ? (context.l10n?.evStatusDynamicFields ?? ' • حقول ديناميكية') : ''}'
                    '${_controller.hasUnsavedChanges ? (context.l10n?.evStatusUnsaved ?? ' • تعديلات غير محفوظة') : ''}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(width: AppTheme.space8),
                  _actionsRow(context),
                ],
              ),
            ],
          ),
        );
      },
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

  Widget _actionsRow(BuildContext context) {
    final bool persist = _controller.canPersist;
    return Wrap(
      spacing: AppTheme.space8,
      runSpacing: AppTheme.space8,
      children: <Widget>[
        OutlinedButton.icon(
          onPressed: _openLibrary,
          icon: const Icon(Icons.folder_open_rounded, size: 17),
          label: Text(context.l10n?.tevMyTemplates ?? 'قوالبي'),
          style: OutlinedButton.styleFrom(minimumSize: const Size(120, 44)),
        ),
        OutlinedButton.icon(
          onPressed: () => _save(saveAs: true),
          icon: const Icon(Icons.save_as_rounded, size: 17),
          label: Text(context.l10n?.tevSaveAs ?? 'حفظ باسم'),
          style: OutlinedButton.styleFrom(minimumSize: const Size(130, 44)),
        ),
        FilledButton.icon(
          onPressed: _controller.isSaving ? null : () => _save(),
          icon: _controller.isSaving
              ? const SizedBox.square(
                  dimension: 15,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_rounded, size: 17),
          label: Text(persist ? context.l10n?.tevSaveTemplate ?? 'حفظ القالب' : context.l10n?.tevSaveUnavailable ?? 'الحفظ غير متاح'),
          style: FilledButton.styleFrom(minimumSize: const Size(150, 44)),
        ),
        FilledButton.icon(
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
        ),
      ],
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
      await Printing.sharePdf(
        bytes: report.bytes,
        filename: widget.exportFileName,
      );
      if (!mounted) return;
      context.showSuccess(
        context.l10n?.commonExportReady(widget.exportFileName) ??
            'تم تجهيز الملف للحفظ باسم ${widget.exportFileName}.',
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

  /// إدراج إطار/شعار مرفوع كخلفية للمستند (خلف كل العناصر) بمرجع `userAsset`.
  ///
  /// يظهر على اللوحة وفي الـ PDF المطبوع مباشرةً لأن محرّك الطباعة يحلّ
  /// `ImageSourceKind.userAsset` من مكتبة الأصول المحلية.
  Future<void> _pickBackgroundFromLibrary() async {
    final UserAsset? asset = await showAssetLibraryPicker(
      context,
      title: context.l10n?.tevBackgroundTitle ?? 'خلفية المستند من مكتبة أصولي',
      filterTypes: const <AssetType>[AssetType.border, AssetType.logo],
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
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          // تباين الورقة: مساحة عمل فاتحة في النهار وداكنة
                          // ليلاً فتبقى حدود الورقة البيضاء واضحة في الوضعين.
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                              : AppColors.navyWash.withValues(alpha: 0.6),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusLg),
                        ),
                        child: Listener(
                          // أي نقر على اللوحة — عنصراً كان أو مساحة فارغة أو
                          // مقابس التحجيم — يعيد التركيز إلى عقدة اللوحة فوراً
                          // فتعمل الاختصارات مباشرةً بعد النقر حتى لو كان
                          // المؤشر كان في حقل نصي في شريط الخصائص.
                          onPointerDown: (PointerDownEvent _) {
                            _endNudge();
                            _canvasFocusNode.requestFocus();
                          },
                          child: TemplateCanvas(
                            controller: _controller,
                            zoom: _zoom,
                            showGrid: _showGrid,
                            snapToGuides: _snapToGuides,
                            onRequestTextEdit: (_) =>
                                _textFocusNode.requestFocus(),
                          ),
                        ),
                      ),
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
                          child: PropertyToolbar(
                            controller: _controller,
                            textFocusNode: _textFocusNode,
                            maxWidth: panelWidth,
                          ),
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
    if (!_controller.hasSelection) return 0;
    return math.min(430, math.max(300, constraints.maxWidth * 0.42));
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
            'الحفظ يتطلب الاتصال بمشروع Supabase. شغّل التطبيق بمفاتيح مشروعك '
                '(env.json) لتتمكن من حفظ القوالب.',
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
      await _controller.save(title: title);
    } on AppException catch (error) {
      if (!mounted) return;
      context.showError(error.message);
    }
  }

  Future<void> _openLibrary() async {
    if (!_library.isAvailable) {
      context.showWarning(
        context.l10n?.tevTemplateLibraryNeedsSupabase ??
            'مكتبة القوالب تتطلب الاتصال بمشروع Supabase.',
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
    _controller.loadDocument(
      record.toDocument(),
      asClean: true,
      recordId: record.id,
      title: record.title,
    );
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
