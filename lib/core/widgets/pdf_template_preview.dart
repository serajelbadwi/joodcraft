import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../errors/app_exception.dart';
import '../models/template_document.dart';
import '../services/pdf_generator_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/ui_feedback.dart';

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
    this.dataPanelTitle = 'بيانات تجريبية',
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

  final String dataPanelTitle;
  final String? emptyStateHint;

  @override
  State<PdfTemplatePreview> createState() => _PdfTemplatePreviewState();
}

class _PdfTemplatePreviewState extends State<PdfTemplatePreview> {
  PdfGeneratorService? _service;
  TemplateDocument? _document;
  PdfGenerationReport? _report;
  Uint8List? _bytes;

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
      final TemplateDocument document = provided ??
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
        _error = 'تعذّر تحضير المعاينة. تحقّق من ملف القالب.';
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
      final PdfGenerationReport report = await service.generate(
        document: document,
        data: <String, String>{...document.sampleData, ..._data},
      );
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
      context.showError('تعذّر إرسال الملف إلى الطابعة.');
    }
  }

  Future<void> _export() async {
    final Uint8List? bytes = _bytes;
    if (bytes == null) return;
    try {
      await Printing.sharePdf(bytes: bytes, filename: widget.exportFileName);
      if (!mounted) return;
      context.showSuccess('تم تجهيز الملف للحفظ باسم ${widget.exportFileName}.');
    } on Object {
      if (!mounted) return;
      context.showError('تعذّر تصدير ملف PDF.');
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
              label: '${document.paperSize.labelAr} — '
                  '${document.orientation.labelAr}',
            ),
            _Chip(
              icon: Icons.layers_outlined,
              label: '${document.drawableElementCount} عنصراً',
            ),
            if (report != null)
              _Chip(
                icon: Icons.memory_rounded,
                label: '${report.elapsed.inMilliseconds} م.ث — '
                    '${(report.byteSize / 1024).toStringAsFixed(1)} ك.ب',
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
                Text('جارٍ التوليد…', style: text.bodySmall),
              ],
            ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: _bytes == null ? null : _print,
                icon: const Icon(Icons.print_outlined, size: 18),
                label: const Text('طباعة'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(120, 42),
                ),
              ),
              const SizedBox(width: AppTheme.space8),
              FilledButton.icon(
                onPressed: _bytes == null || _busy ? null : _export,
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text('تصدير PDF'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(150, 42),
                ),
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
      color: Theme.of(context)
          .colorScheme
          .primaryContainer
          .withValues(alpha: 0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.edit_note_rounded,
                  size: 18, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: AppTheme.space8),
              Text(widget.dataPanelTitle, style: text.titleSmall),
              const SizedBox(width: AppTheme.space8),
              Text(
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
          const Icon(Icons.warning_amber_rounded,
              size: 16, color: AppColors.warning),
          const SizedBox(width: AppTheme.space8),
          Expanded(
            child: Text(
              warnings.join(' • '),
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.warning),
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
    final String? error = _error;
    if (error != null) {
      return _centeredMessage(
        icon: Icons.error_outline_rounded,
        color: Theme.of(context).colorScheme.danger,
        title: 'تعذّر توليد المعاينة',
        message: error,
        action: FilledButton.icon(
          onPressed: _bootstrap,
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('إعادة المحاولة'),
          style: FilledButton.styleFrom(minimumSize: const Size(180, 44)),
        ),
      );
    }

    final Uint8List? bytes = _bytes;
    if (bytes == null || document == null) {
      return _centeredMessage(
        icon: Icons.picture_as_pdf_outlined,
        color: Theme.of(context).colorScheme.primary,
        title: 'جارٍ تحضير المحرك…',
        message: widget.emptyStateHint ??
            'يتم تحميل الخطوط المحزومة وتوليد أول نسخة من الملف.',
      );
    }    return PdfPreview(
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
        title: 'تعذّر عرض المعاينة',
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
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}
