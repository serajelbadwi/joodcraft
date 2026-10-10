import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../audit/export_audit_log.dart';
import '../errors/app_exception.dart';
import '../l10n/app_l10n.dart';
import '../models/template_document.dart';
import '../print/crop_marks.dart';
import '../print/widgets/imposition_preview.dart';
import '../services/pdf_generator_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/ui_feedback.dart';

/// نوع تصدير ملف PDF — يحدّد صيغة الملف الناتج.
///
/// * [images]: صور نقطية (Raster) مطابقة للمحرر 100% بحجم أكبر، والنص غير
///   قابل للنسخ — المسار المتاح حالياً والافتراضي.
/// * [vector]: فيكتور (Vector) نصه قابل للنسخ والبحث وحجمه أصغر — **قيد
///   التطوير**، فيظهر الخيار معطّلاً مع شارة «قريباً» ولا يُنفّذ تصديراً.
enum PdfExportType {
  /// صور نقطية — متاح الآن (وهو الخيار الافتراضي).
  images,

  /// فيكتور — قيد التطوير (يظهر معطّلاً بشارة «قريباً»).
  vector,
}

/// معاينة حيّة لقالب PDF + طباعة وتصدير — ودجت محايد عن الميزات.
///
/// وُضع في `core` لأن كلاً من محرّك الشهادات ومحرّك العقود (وغيرهما لاحقاً)
/// يستخدمه بلا أي ارتباط بين الميزات.
class PdfTemplatePreview extends StatefulWidget {
  const PdfTemplatePreview({
    super.key,
    required this.exportFileName,
    this.templateAssetPath,
    this.document,
    this.revision = 0,
    this.dataPanelTitle,
    this.emptyStateHint,
  }) : assert(
         templateAssetPath != null || document != null,
         'يجب تمرير مسار القالب أو مستند جاهز.',
       );

  /// مسار ملف القالب (JSON) داخل أصول التطبيق.
  ///
  /// يُستخدم في المعاينة الثابتة (قالب نموذجي). أما محرر القوالب فيمرّر
  /// [document] مباشرةً ليعاين التعديلات الحية.
  final String? templateAssetPath;

  /// مستند جاهز للتوليد (وضع المحرر) — يتقدّم على [templateAssetPath].
  final TemplateDocument? document;

  /// رقم مراجعة يرتفع مع كل تعديل، فيُعاد التوليد عند تغيّره.
  final int revision;

  /// اسم الملف المُصدَّر.
  final String exportFileName;

  final String? dataPanelTitle;
  final String? emptyStateHint;

  @override
  State<PdfTemplatePreview> createState() => _PdfTemplatePreviewState();
}

class _PdfTemplatePreviewState extends State<PdfTemplatePreview> {
  PdfGeneratorService? _service;
  TemplateDocument? _document;
  PdfGenerationReport? _report;
  Uint8List? _bytes;

  /// وضع «تجميع للطباعة» — يعرض ورقة التجميع ويخرِج ملف PDF بعلامات القصّ.
  ///
  /// لا يتاح إلا للمقاسات الصغيرة (بطاقات، أرقام جلوس، معايدات) حيث يكون
  /// التجميع على ورقة أكبر مفيداً فعلاً.
  bool _imposition = false;

  /// هل يتاح التجميع لمقاس المستند الحالي؟
  bool get _impositionAvailable =>
      _document != null && ImpositionSpec.isEligible(_document!);

  /// مواصفة الحصر الوحيدة المصدر — تُستخدم في المعاينة وفي التصدير معاً.
  ImpositionSpec? _specFor(TemplateDocument? document) => document == null
      ? null
      : ImpositionSpec.fromDocument(
          document,
          sheet: ImpositionSpec.suggestSheetFor(document),
        );

  final Map<String, TextEditingController> _controllers =
      <String, TextEditingController>{};
  final Map<String, String> _data = <String, String>{};
  Set<String> _fieldKeys = const <String>{};

  Timer? _debounce;
  bool _busy = true;
  String? _error;
  int _revision = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_bootstrap());
  }

  @override
  void didUpdateWidget(PdfTemplatePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    final TemplateDocument? incoming = widget.document;
    // المعاينة الحية: أي تعديل في المحرر (مراجعة جديدة) يُعيد التوليد بلا
    // إعادة تحميل الخطوط المحزومة.
    if (incoming == null) return;
    if (oldWidget.revision == widget.revision) return;
    _applyDocument(incoming, rebuildFields: true);
    unawaited(_regenerate());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    for (final TextEditingController controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _bootstrap() async {
    try {
      final TemplateDocument? provided = widget.document;
      final TemplateDocument document =
          provided ??
          TemplateDocument.fromJsonString(
            await rootBundle.loadString(widget.templateAssetPath!),
          );
      final PdfGeneratorService service = await PdfGeneratorService.create();

      if (!mounted) return;

      _applyDocument(document, rebuildFields: true);
      setState(() {
        _service = service;
      });
      await _regenerate();
    } on AppException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _busy = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _error =
            context.l10n?.ptpPrepError ??
            'تعذّر تحضير المعاينة. تحقّق من ملف القالب.';
        _busy = false;
      });
    }
  }

  /// اعتماد مستند جديد مع إعادة بناء حقول البيانات عند تغيّر مفاتيحها.
  void _applyDocument(
    TemplateDocument document, {
    required bool rebuildFields,
  }) {
    final Set<String> nextKeys = document.fieldKeys;
    if (rebuildFields && !_sameKeys(nextKeys)) {
      for (final TextEditingController controller in _controllers.values) {
        controller.dispose();
      }
      _controllers.clear();
      _data.clear();
      for (final String key in nextKeys) {
        final String seed = document.sampleData[key] ?? '';
        _controllers[key] = TextEditingController(text: seed);
        _data[key] = seed;
      }
      _fieldKeys = nextKeys;
    }
    setState(() {
      _document = document;
      _error = null;
    });
  }

  bool _sameKeys(Set<String> keys) {
    if (keys.length != _fieldKeys.length) return false;
    for (final String key in keys) {
      if (!_fieldKeys.contains(key)) return false;
    }
    return true;
  }

  /// إعادة التوليد (تُستدعى مباشرة وعبر تأخير عند الكتابة).
  Future<void> _regenerate() async {
    final TemplateDocument? document = _document;
    final PdfGeneratorService? service = _service;
    if (document == null || service == null) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final PdfGenerationReport report;
      if (_imposition) {
        final ImpositionSpec? spec = _specFor(document);
        report = await service.generateImposition(
          document: document,
          spec: spec!,
          data: <String, String>{...document.sampleData, ..._data},
        );
      } else {
        report = await service.generate(
          document: document,
          data: <String, String>{...document.sampleData, ..._data},
        );
      }
      if (!mounted) return;
      setState(() {
        _report = report;
        _bytes = report.bytes;
        _revision++;
        _busy = false;
      });
    } on AppException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _busy = false;
      });
    }
  }

  void _onFieldChanged(String key, String value) {
    _data[key] = value;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) unawaited(_regenerate());
    });
  }

  /// تبديل وضع التجميع — يُعيد التوليد لحظياً في الوضع الجديد.
  void _setImposition(bool value) {
    if (value == _imposition) return;
    setState(() {
      _imposition = value;
      _error = null;
    });
    unawaited(_regenerate());
  }

  /// صفّ التبديل: أيقونة + تسمية + مفتاح، يظهر للمقاسات الصغيرة فقط.
  Widget _impositionToggle() {
    final TextTheme text = Theme.of(context).textTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(
          Icons.grid_on_rounded,
          size: 16,
          color: _imposition
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 6),
        Text(
          context.l10n?.ptpImpositionToggle ?? 'تجميع للطباعة',
          style: text.labelMedium?.copyWith(
            fontWeight: _imposition ? FontWeight.w700 : FontWeight.w500,
            color: _imposition
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 4),
        Switch(
          key: const ValueKey<String>('ptp-imposition-toggle'),
          value: _imposition,
          onChanged: _setImposition,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ],
    );
  }

  /// منطقة التجميع: طبقات المعاينة (ورقة + علامات قصّ + خط أمان النزف).
  ///
  /// لا تعتمد على بايتات الـ PDF: تُرسم من المواصفة نفسها مباشرةً، فترى
  /// الشبكة فوراً بينما تُولَّد نسخة الطباعة في الخلفية.
  Widget _impositionArea(TemplateDocument document) {
    final ImpositionSpec? spec = _specFor(document);
    if (spec == null) return const SizedBox.shrink();
    return ImpositionPreview(
      key: const ValueKey<String>('imposition-preview'),
      spec: spec,
      document: document,
      itemCount: spec.layout().count,
    );
  }

  Future<void> _print() async {
    final Uint8List? bytes = _bytes;
    if (bytes == null) return;
    try {
      await Printing.layoutPdf(
        name: widget.exportFileName,
        onLayout: (PdfPageFormat format) async => bytes,
      );
    } on Object {
      if (!mounted) return;
      context.showError(
        context.l10n?.commonPrintFailed ?? 'تعذّر إرسال الملف إلى الطابعة.',
      );
    }
  }

  /// يفتح حوار «نوع التصدير» ثم يسلّم الخيار المختار لمساره.
  ///
  /// «صور» يسلك دالة التصدير الحالية كما هي بلا أي تغيير؛ أما «فيكتور»
  /// فلم يُبنَ بعد — لا تصدير خلفه (ويظهر الخيار من البداية معطّلاً).
  Future<void> _export() async {
    final PdfExportType? type = await showDialog<PdfExportType>(
      context: context,
      builder: (BuildContext dialogContext) => const PdfExportTypeDialog(),
    );
    if (!mounted || type == null) return;
    switch (type) {
      case PdfExportType.images:
        await _exportImages();
      case PdfExportType.vector:
        // قيد التطوير — لم يُبنَ مسار التصدير بعد.
        break;
    }
  }

  /// حفظ الملف على القرص بمسار **الصور النقطية** (المسار الحالي بلا تغيير).
  Future<void> _exportImages() async {
    final Uint8List? bytes = _bytes;
    if (bytes == null) return;
    try {
      final Uri? selectedPath = await FilePicker.saveFile(
        dialogTitle: 'حفظ شهادة PDF',
        fileName: widget.exportFileName,
        bytes: bytes,
        type: FileType.custom,
        allowedExtensions: <String>['pdf'],
      );
      if (!mounted || selectedPath == null) return;
      // أرشفة محلية لمعاينات الطباعة/التصدير أيضاً (قد تُطبع النسخة النموذجية
      // وتُعتمد قبل تصميم قالب فعلي).
      unawaited(
        ExportAuditLog.instance.record(
          documentTitle: widget.exportFileName,
          kind: ExportKind.preview,
          fileName: widget.exportFileName,
        ),
      );
      context.showSuccess(
        context.l10n?.commonExportReady(widget.exportFileName) ??
            'تم حفظ الملف بنجاح باسم ${widget.exportFileName}.',
      );
    } on Object {
      if (!mounted) return;
      context.showError(
        context.l10n?.commonExportFailed ?? 'تعذّر تصدير ملف PDF.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final TemplateDocument? document = _document;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _header(document),
        if (document != null && document.fieldKeys.isNotEmpty) _dataPanel(),
        if (document != null && document.warnings.isNotEmpty)
          _warningsBanner(document.warnings),
        Expanded(child: _previewArea(document)),
      ],
    );
  }

  // -------------------------------------------------------------------------
  //  الترويسة
  // -------------------------------------------------------------------------
  Widget _header(TemplateDocument? document) {
    final TextTheme text = Theme.of(context).textTheme;
    final PdfGenerationReport? report = _report;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space20,
        vertical: AppTheme.space12,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).colorScheme.outline),
        ),
      ),
      child: Wrap(
        spacing: AppTheme.space12,
        runSpacing: AppTheme.space8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          if (document != null) ...<Widget>[
            _Chip(
              icon: Icons.description_outlined,
              label:
                  '${document.paperSize.labelAr} — '
                  '${document.orientation.labelAr}',
            ),
            _Chip(
              icon: Icons.layers_outlined,
              label:
                  context.l10n?.evElementCount(document.drawableElementCount) ??
                  '${document.drawableElementCount} عنصراً',
            ),
            if (report != null)
              _Chip(
                icon: Icons.memory_rounded,
                label:
                    context.l10n?.ptpElapsedSize(
                      report.elapsed.inMilliseconds,
                      (report.byteSize / 1024).toStringAsFixed(1),
                    ) ??
                    '${report.elapsed.inMilliseconds} م.ث — ${(report.byteSize / 1024).toStringAsFixed(1)} ك.ب',
              ),
          ],
          if (_busy)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const SizedBox.square(
                  dimension: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: AppTheme.space8),
                Text(
                  context.l10n?.commonGenerating ?? 'جارٍ التوليد…',
                  style: text.bodySmall,
                ),
              ],
            ),
          if (document != null && _impositionAvailable) _impositionToggle(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: _bytes == null ? null : _print,
                icon: const Icon(Icons.print_outlined, size: 18),
                label: Text(context.l10n?.commonPrint ?? 'طباعة'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(120, 42),
                ),
              ),
              const SizedBox(width: AppTheme.space8),
              FilledButton.icon(
                onPressed: _bytes == null || _busy ? null : _export,
                icon: const Icon(Icons.download_rounded, size: 18),
                label: Text(context.l10n?.commonExportPdf ?? 'تصدير PDF'),
                style: FilledButton.styleFrom(minimumSize: const Size(150, 42)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  //  لوحة البيانات التجريبية
  // -------------------------------------------------------------------------
  Widget _dataPanel() {
    final TextTheme text = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space20,
        vertical: AppTheme.space12,
      ),
      color: Theme.of(
        context,
      ).colorScheme.primaryContainer.withValues(alpha: 0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.edit_note_rounded,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: AppTheme.space8),
              Text(
                widget.dataPanelTitle ??
                    context.l10n?.commonDataPanelTitle ??
                    'بيانات تجريبية',
                style: text.titleSmall,
              ),
              const SizedBox(width: AppTheme.space8),
              Text(
                context.l10n?.ptpGeneratingNote ??
                    '— تُحدَّث المعاينة تلقائياً',
                style: text.bodySmall?.copyWith(fontSize: 11.5),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space8),
          Wrap(
            spacing: AppTheme.space12,
            runSpacing: AppTheme.space8,
            children: <Widget>[
              for (final MapEntry<String, TextEditingController> entry
                  in _controllers.entries)
                SizedBox(
                  width: 240,
                  child: TextField(
                    controller: entry.value,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    style: text.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      labelText: entry.key,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.space12,
                        vertical: AppTheme.space12,
                      ),
                    ),
                    onChanged: (String value) =>
                        _onFieldChanged(entry.key, value),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _warningsBanner(List<String> warnings) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space20,
        vertical: AppTheme.space8,
      ),
      color: AppColors.warningSoft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(
            Icons.warning_amber_rounded,
            size: 16,
            color: AppColors.warning,
          ),
          const SizedBox(width: AppTheme.space8),
          Expanded(
            child: Text(
              warnings.join(' • '),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.warning),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  //  منطقة المعاينة
  // -------------------------------------------------------------------------
  Widget _previewArea(TemplateDocument? document) {
    // وضع التجميع يرسم من المواصفة نفسها: لا ينتظر بايتات الـ PDF، فيبقى
    // التخطيط مرئياً حتى لو تعذّر توليد ملف الطباعة في الخلفية.
    if (_imposition && document != null) return _impositionArea(document);
    final String? error = _error;
    if (error != null) {
      return _centeredMessage(
        icon: Icons.error_outline_rounded,
        color: Theme.of(context).colorScheme.danger,
        title: context.l10n?.ptpGenerateFailedTitle ?? 'تعذّر توليد المعاينة',
        message: error,
        action: FilledButton.icon(
          onPressed: _bootstrap,
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: Text(context.l10n?.commonRetry ?? 'إعادة المحاولة'),
          style: FilledButton.styleFrom(minimumSize: const Size(180, 44)),
        ),
      );
    }

    final Uint8List? bytes = _bytes;
    if (bytes == null || document == null) {
      return _centeredMessage(
        icon: Icons.picture_as_pdf_outlined,
        color: Theme.of(context).colorScheme.primary,
        title: context.l10n?.ptpPreparingTitle ?? 'جارٍ تحضير المحرك…',
        message:
            widget.emptyStateHint ??
            context.l10n?.ptpPreparingMessage ??
            'يتم تحميل الخطوط المحزومة وتوليد أول نسخة من الملف.',
      );
    }
    return PdfPreview(
      // مفتاح يتغيّر مع كل توليد ليُعيد الودجت بناء المعاينة بالنسخة الجديدة.
      key: ValueKey<int>(_revision),
      build: (PdfPageFormat format) async => bytes,
      initialPageFormat: PdfPageFormat(
        document.pageWidthPt,
        document.pageHeightPt,
        marginAll: 0,
      ),
      canChangePageFormat: false,
      canChangeOrientation: false,
      canDebug: false,
      allowPrinting: true,
      allowSharing: true,
      pdfFileName: widget.exportFileName,
      loadingWidget: const Center(child: CircularProgressIndicator()),
      onError: (BuildContext context, Object error) => _centeredMessage(
        icon: Icons.error_outline_rounded,
        color: Theme.of(context).colorScheme.danger,
        title: context.l10n?.ptpShowFailedTitle ?? 'تعذّر عرض المعاينة',
        message: '$error',
      ),
    );
  }

  Widget _centeredMessage({
    required IconData icon,
    required Color color,
    required String title,
    required String message,
    Widget? action,
  }) {
    final TextTheme text = Theme.of(context).textTheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 34, color: color),
            const SizedBox(height: AppTheme.space12),
            Text(title, style: text.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: AppTheme.space8),
            Text(message, style: text.bodyMedium, textAlign: TextAlign.center),
            if (action != null) ...<Widget>[
              const SizedBox(height: AppTheme.space20),
              action,
            ],
          ],
        ),
      ),
    );
  }
}

/// شارة معلومات صغيرة في الترويسة.
class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
//  حوار «نوع التصدير»: صور (افتراضي) أو فيكتور (قيد التطوير)
// ===========================================================================

/// حوار اختيار نوع ملف PDF قبل التصدير: **صور** أو **فيكتور**.
///
/// «صور» هو الخيار الافتراضي والوحيد المفعّل؛ «فيكتور» يظهر رمادياً مع شارة
/// «قريباً»، والضغط عليه يعرض رسالة «قريباً» بلا أي تصدير. يُعيد
/// [PdfExportType] المختار عند التأكيد، أو `null` عند الإلغاء.
class PdfExportTypeDialog extends StatefulWidget {
  const PdfExportTypeDialog({
    super.key,
    this.initialType = PdfExportType.images,
  });

  /// النوع المختار ابتداءً — «صور» افتراضياً.
  final PdfExportType initialType;

  @override
  State<PdfExportTypeDialog> createState() => _PdfExportTypeDialogState();
}

class _PdfExportTypeDialogState extends State<PdfExportTypeDialog> {
  static const String _imagesValue = 'images';
  static const String _vectorValue = 'vector';

  /// القيمة الفعلية المختارة — «صور» دائماً في هذه المرحلة.
  late String _value = widget.initialType == PdfExportType.vector
      ? _vectorValue
      : _imagesValue;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final l10n = context.l10n;
    return AlertDialog(
      key: const ValueKey<String>('pdf-export-type-dialog'),
      title: Text(l10n?.pdfExportTypeTitle ?? 'نوع التصدير'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            l10n?.pdfExportTypeHint ?? 'اختر صيغة الملف قبل التصدير.',
            style: text.bodySmall,
          ),
          const SizedBox(height: AppTheme.space12),
          _ExportTypeOption(
            key: const ValueKey<String>('pdf-export-option-images'),
            icon: Icons.image_outlined,
            title: l10n?.pdfExportTypeImages ?? 'صور',
            description:
                l10n?.pdfExportTypeImagesDesc ?? 'مطابقة 100% — حجم أكبر',
            notes: <String>[
              l10n?.pdfExportTypeImagesNotCopyable ?? 'النص غير قابل للنسخ',
            ],
            selected: _value == _imagesValue,
            onTap: () => setState(() => _value = _imagesValue),
          ),
          const SizedBox(height: AppTheme.space8),
          _ExportTypeOption(
            key: const ValueKey<String>('pdf-export-option-vector'),
            icon: Icons.auto_awesome_outlined,
            title: l10n?.pdfExportTypeVector ?? 'فيكتور',
            description:
                l10n?.pdfExportTypeVectorDesc ?? 'نص قابل للنسخ — حجم أصغر',
            notes: <String>[
              l10n?.pdfExportTypeVectorCopyable ?? 'نص قابل للنسخ والبحث',
              l10n?.pdfExportTypeVectorBestFor ?? 'مثالي للطباعة الاحترافية',
            ],
            badge: l10n?.pdfExportTypeComingSoon ?? 'قريباً',
            enabled: false,
            comingSoonMessage:
                l10n?.pdfExportTypeComingSoonMessage ??
                'تصدير الفيكتور قيد التطوير — سيتوفر قريباً.',
            selected: false,
            onTap: () => context.showWarning(
              l10n?.pdfExportTypeComingSoonMessage ??
                  'تصدير الفيكتور قيد التطوير — سيتوفر قريباً.',
            ),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          key: const ValueKey<String>('pdf-export-cancel'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n?.editorCancel ?? 'إلغاء'),
        ),
        FilledButton(
          key: const ValueKey<String>('pdf-export-confirm'),
          // «صور» هو المسار الوحيد الموصول في هذه المرحلة.
          onPressed: () => Navigator.of(context).pop(
            _value == _vectorValue
                ? PdfExportType.vector
                : PdfExportType.images,
          ),
          child: Text(l10n?.commonExportPdf ?? 'تصدير PDF'),
        ),
      ],
    );
  }
}

/// بطاقة خيار واحد في حوار «نوع التصدير».
///
/// [enabled] = false يعني معطّلاً: يظهر رمادياً وبشارة [badge]، ولا يُغيَّر
/// الاختيار به أبداً؛ وإن أُتيح [comingSoonMessage] يُعرض عند الضغط بدل أي
/// تصدير.
class _ExportTypeOption extends StatelessWidget {
  const _ExportTypeOption({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.notes,
    required this.selected,
    required this.onTap,
    this.badge,
    this.enabled = true,
    this.comingSoonMessage,
  });

  /// أيقونة الصيغة (صورة نقطية / فيكتور).
  final IconData icon;

  /// عنوان الخيار («صور» / «فيكتور»).
  final String title;

  /// سطر الوصف المختصر.
  final String description;

  /// نقاط فرعية بعلامة «•».
  final List<String> notes;

  /// هل الخيار مختار — «صور» افتراضياً.
  final bool selected;

  /// هل الخيار متاح — «فيكتور» معطّل في هذه المرحلة.
  final bool enabled;

  /// شارة صغيرة بجانب العنوان (مثل «قريباً»).
  final String? badge;

  /// رسالة تُعرض عند الضغط على خيار معطّل — بلا أي تصدير.
  final String? comingSoonMessage;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    final Color contentColor = enabled
        ? scheme.onSurface
        : scheme.onSurfaceVariant;
    final Color background = !enabled
        ? scheme.surfaceContainerHighest
        : selected
        ? scheme.primaryContainer.withValues(alpha: 0.35)
        : scheme.surface;
    // الإطار الملوّن يفرّق المختار وحده؛ أمّا البطاقة المعطّلة فبإطار خفيف.
    final Color borderColor = selected && enabled
        ? scheme.primary
        : scheme.outlineVariant;

    return Semantics(
      selected: selected,
      enabled: enabled,
      child: Opacity(
        // التعطيل مرئي: محتوى باهت مع شارة «قريباً» — ولا يُختار أبداً.
        opacity: enabled ? 1 : 0.6,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(AppTheme.space12),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(icon, size: 20, color: contentColor),
                const SizedBox(width: AppTheme.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Flexible(
                            child: Text(
                              title,
                              style: text.titleSmall?.copyWith(
                                color: contentColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (badge != null) ...<Widget>[
                            const SizedBox(width: AppTheme.space8),
                            _ComingSoonBadge(
                              key: const ValueKey<String>(
                                'pdf-export-coming-soon-badge',
                              ),
                              label: badge!,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: AppTheme.space4),
                      Text(
                        description,
                        style: text.bodySmall?.copyWith(color: contentColor),
                      ),
                      for (final String note in notes) ...<Widget>[
                        const SizedBox(height: AppTheme.space2),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              '•',
                              style: text.bodySmall?.copyWith(
                                color: contentColor,
                              ),
                            ),
                            const SizedBox(width: AppTheme.space6),
                            Expanded(
                              child: Text(
                                note,
                                style: text.bodySmall?.copyWith(
                                  color: contentColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppTheme.space8),
                // دائرة الاختيار: صحّة ممتلئة للمختار، ودائرة فارغة لغيره.
                if (selected)
                  Icon(
                    Icons.check_circle_rounded,
                    size: 20,
                    color: scheme.primary,
                  )
                else
                  Icon(
                    Icons.radio_button_unchecked,
                    size: 20,
                    color: scheme.outline,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// شارة «قريباً» الصغيرة بجانب عنوان خيار غير متاح بعد.
class _ComingSoonBadge extends StatelessWidget {
  const _ComingSoonBadge({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space8,
        vertical: AppTheme.space2,
      ),
      decoration: BoxDecoration(
        color: AppColors.goldSoft,
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
      ),
      child: Text(
        label,
        style: text.labelSmall?.copyWith(
          color: AppColors.goldDeep,
          fontSize: 10.5,
        ),
      ),
    );
  }
}
