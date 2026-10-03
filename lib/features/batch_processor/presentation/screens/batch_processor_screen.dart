import 'dart:async';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/templates/local_template_store.dart';
import '../../../../core/templates/template_library_controller.dart';
import '../../../../core/templates/template_library_entry.dart';
import '../../../../core/templates/template_record.dart';
import '../../../../core/templates/template_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/ui_feedback.dart';
import '../../domain/bulk_generation.dart';
import '../../domain/sheet_data.dart';
import '../../domain/sheet_reader.dart';
import '../providers/batch_processor_controller.dart';

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
  }

  @override
  void dispose() {
    // لا نُتلف محرّكات يملكها المستدعي.
    if (_ownsLibrary) _library.dispose();
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  static BatchTemplateKind _kindFor(TemplateCategory category) =>
      category == TemplateCategory.contract
          ? BatchTemplateKind.contract
          : BatchTemplateKind.certificate;

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
  //  اختيار الملف
  // --------------------------------------------------------------------------
  Future<void> _pickFile() async {
    final List<PlatformFile> picked;
    try {
      picked = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: BatchProcessorScreen.acceptedExtensions,
        dialogTitle: 'اختر ملف البيانات (Excel أو CSV)',
      );
    } catch (error) {
      if (!mounted) return;
      context.showError('تعذّر فتح منتقي الملفات: $error');
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
      context.showError('تعذّر قراءة الملف: $error');
      return;
    }

    if (!mounted) return;
    final String? error = _controller.errorAr;
    if (error != null) {
      context.showError(error);
    } else {
      context.showSuccess(
        'قُرئ الملف محلياً: ${_controller.sheet.rowCount} صفاً '
        'و${_controller.sheet.columnCount} عموداً.',
      );
    }
  }

  Future<void> _generate() async {
    await _controller.generate();
    if (!mounted) return;
    final String? error = _controller.errorAr;
    if (error != null) {
      context.showError(error);
      return;
    }
    final BulkGenerationReport? report = _controller.report;
    if (report == null) return;
    context.showSuccess(
      'تم توليد ${report.generatedCount} سجل'
      '${report.skippedCount > 0 ? ' وتخطّي ${report.skippedCount}' : ''}.',
    );
  }

  Future<void> _print() async {
    final Uint8List? bytes = _controller.report?.combinedPdf;
    if (bytes == null) return;
    try {
      await Printing.layoutPdf(
        name: 'joodcraft-batch.pdf',
        onLayout: (PdfPageFormat format) async => bytes,
      );
    } on Object {
      if (!mounted) return;
      context.showError('تعذّر إرسال الملف إلى الطابعة.');
    }
  }

  Future<void> _export() async {
    final Uint8List? bytes = _controller.report?.combinedPdf;
    if (bytes == null) return;
    try {
      await Printing.sharePdf(bytes: bytes, filename: 'joodcraft-batch.pdf');
      if (!mounted) return;
      context.showSuccess('تم تجهيز الملف للحفظ.');
    } on Object {
      if (!mounted) return;
      context.showError('تعذّر تصدير ملف PDF.');
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
              Expanded(
                child: Row(
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
                Text('التوليد الجماعي من Excel', style: text.titleMedium),
                Text(
                  'استورد ملف .xlsx أو .csv، اربط أعمدته بحقول القالب، ثم ولّد '
                  'ملف PDF بصفحة لكل سجل — كل ذلك على جهازك بلا إنترنت.',
                  style: text.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
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
            _controller.kind.labelAr;
        return _Card(
          icon: Icons.school_outlined,
          title: '1) القالب',
          subtitle: _controller.document == null
              ? 'جارٍ تحميل القالب النموذجي…'
              : 'القالب: $activeTemplate • الحقول المطلوبة: '
                  '${_controller.availableFields.length}',
          // تحذير صريح حين لا يحوي القالب أي حقل `{{...}}`: المستخدم يظنّ
          // أنه «مربوط» بينما النص ثابت لا يتغيّر بين السجلات.
          warning: _controller.document != null &&
                  !_controller.templateHasDynamicFields
              ? 'هذا القالب بلا حقول ديناميكية — لن تتغيّر البيانات بين '
                  'السجلات. أضف حقل «اسم المتدرب» من شريط المحرّر '
                  '(حقل ديناميكي) ثم احفظ القالب.'
              : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SegmentedButton<BatchTemplateKind>(
                segments: <ButtonSegment<BatchTemplateKind>>[
                  for (final BatchTemplateKind kind
                      in BatchTemplateKind.values)
                    ButtonSegment<BatchTemplateKind>(
                      value: kind,
                      label: Text(kind.labelAr),
                      icon: Icon(
                        kind == BatchTemplateKind.certificate
                            ? Icons.workspace_premium_outlined
                            : Icons.handshake_outlined,
                        size: 16,
                      ),
                    ),
                ],
                selected: <BatchTemplateKind>{_controller.kind},
                onSelectionChanged: (Set<BatchTemplateKind> selection) {
                  if (selection.isEmpty) return;
                  _applyDefaultTemplate(selection.first);
                },
              ),
              const SizedBox(height: AppTheme.space12),
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
                  ? 'جارٍ تحميل قوالبك…'
                  : 'لا توجد قوالب محفوظة بعد — أنشئ قالباً في المحرّر أو '
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
            decoration: const InputDecoration(
              labelText: 'قالب من قوالبي',
              isDense: true,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            ),
            items: <DropdownMenuItem<String>>[
              const DropdownMenuItem<String>(
                value: '',
                child: Text(
                  '— القوالب النموذجية —',
                  style: TextStyle(fontSize: 12),
                ),
              ),
              for (final TemplateLibraryEntry entry in mine)
                DropdownMenuItem<String>(
                  value: entry.id,
                  child: Text(
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
      title: '2) ملف البيانات',
      subtitle: _controller.loadingFile
          ? 'جارٍ قراءة الملف…'
          : fileName == null
              ? 'لم يُختَر ملف بعد — الصيغ المدعومة: '
                  '${SheetReaders.supportedLabel}'
              : '$fileName — ${sheet.rowCount} صفاً، ${sheet.columnCount} عموداً'
                  '${sheet.sheetName.isEmpty ? '' : ' (ورقة: ${sheet.sheetName})'}',
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
                label: const Text('اختيار ملف'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(150, 44),
                ),
              ),
              if (fileName != null)
                OutlinedButton.icon(
                  onPressed: _controller.clearFile,
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: const Text('إزالة'),
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
            decoration: const InputDecoration(
              labelText: 'صف العناوين',
              isDense: true,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            ),
            selectedItemBuilder: (BuildContext context) => <Widget>[
              DropdownMenuItem<int>(
                value: autoValue,
                child: Text(
                  'تلقائي (الصف ${_controller.effectiveHeaderRowIndex + 1})',
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              for (int i = 0; i < samples.length; i++)
                DropdownMenuItem<int>(
                  value: i,
                  child: Text(
                    'الصف ${i + 1}',
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            items: <DropdownMenuItem<int>>[
              DropdownMenuItem<int>(
                value: autoValue,
                child: Text(
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
    if (filled.isEmpty) return '(صف فارغ)';
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
            decoration: const InputDecoration(
              labelText: 'ورقة العمل',
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
      title: '3) ربط الأعمدة بالحقول',
      subtitle: sheet.isEmpty
          ? 'اختر ملفاً أولاً ليظهر جدول الربط.'
          : _controller.availableFields.isEmpty
                  && _controller.document != null
              ? 'لا حقول ديناميكية في القالب الحالي.'
              : 'مرتبط ${_controller.mapping.mappedCount} من '
                  '${_controller.visibleColumns.length} عموداً',
      child: sheet.isEmpty
          ? Text(
              'بعد اختيار الملف سيُقترح ربط تلقائي ذكي، ويمكنك تعديل كل عمود.',
              style: text.bodySmall,
            )
          : _controller.availableFields.isEmpty
              ? Text(
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
                      label: const Text('ربط تلقائي'),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(130, 40),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _controller.clearMapping,
                      icon: const Icon(Icons.link_off_rounded, size: 16),
                      label: const Text('مسح الربط'),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(120, 40),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.space4),
                for (final int column in _controller.visibleColumns)
                  _mappingRow(column),
                if (_controller.mapping.hasDuplicates)
                  _Note(
                    color: AppColors.danger,
                    soft: AppColors.dangerSoft,
                    icon: Icons.error_outline_rounded,
                    text: 'الحقل «${_controller.mapping.duplicateFields.first}» '
                        'مرتبط بأكثر من عمود. اجعل كل حقل بعمود واحد.',
                  ),
                if (_controller.unmappedColumnCount > 0)
                  _Note(
                    color: AppColors.warning,
                    soft: AppColors.warningSoft,
                    icon: Icons.info_outline_rounded,
                    text: '${_controller.unmappedColumnCount} عموداً بلا ربط — '
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
        : 'عمود ${column + 1}';
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
                  preview.isEmpty ? '(فارغ)' : preview,
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
                      key.isEmpty ? '— غير مربوط —' : key,
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
                          ? '— غير مربوط —'
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
      title: '4) الخلايا الفارغة والبيانات الناقصة',
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
            Text('لا ملاحظات قبل اختيار الملف.', style: text.bodySmall),
        ],
      ),
    );
  }

  Widget _generateStep() {
    final BulkGenerationReport? report = _controller.report;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;

    return _Card(
      icon: Icons.play_circle_outline_rounded,
      title: '5) التوليد',
      subtitle: _controller.busy
          ? 'جارٍ التوليد… ${_controller.progressLabelAr}'
          : 'ملف PDF واحد، صفحة لكل سجل مُصدر.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (_controller.busy) ...<Widget>[
            LinearProgressIndicator(value: _controller.progress),
            const SizedBox(height: AppTheme.space8),
          ],
          if (_controller.errorAr != null)
            _Note(
              color: AppColors.danger,
              soft: AppColors.dangerSoft,
              icon: Icons.error_outline_rounded,
              text: _controller.errorAr!,
            ),
          FilledButton.icon(
            onPressed: _controller.canGenerate ? _generate : null,
            icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
            label: Text(
              report == null ? 'توليد الشهادات' : 'إعادة التوليد',
            ),
          ),
          if (report != null) ...<Widget>[
            const SizedBox(height: AppTheme.space12),
            Wrap(
              spacing: AppTheme.space8,
              runSpacing: AppTheme.space8,
              children: <Widget>[
                _Stat(
                  label: 'مُصدرة',
                  value: '${report.generatedCount}',
                  color: scheme.success,
                ),
                _Stat(
                  label: 'متخطّاة',
                  value: '${report.skippedCount}',
                  color: report.skippedCount == 0
                      ? scheme.onSurfaceVariant
                      : scheme.warning,
                ),
                _Stat(
                  label: 'صفحات',
                  value: '${report.pageCount}',
                  color: scheme.primary,
                ),
                _Stat(
                  label: 'الحجم',
                  value: '${(report.byteSize / 1024).toStringAsFixed(0)} ك.ب',
                  color: scheme.onSurfaceVariant,
                ),
                _Stat(
                  label: 'الزمن',
                  value: '${report.elapsed.inMilliseconds} م.ث',
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
            const SizedBox(height: AppTheme.space8),
            Text(
              'اكتمال ${(report.successRate * 100).round()}% من '
              '${report.totalRows} صفاً.',
              style: text.bodySmall,
            ),
            const SizedBox(height: AppTheme.space8),
            Row(
              children: <Widget>[
                OutlinedButton.icon(
                  onPressed: report.hasOutput ? _print : null,
                  icon: const Icon(Icons.print_outlined, size: 18),
                  label: const Text('طباعة'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(120, 44),
                  ),
                ),
                const SizedBox(width: AppTheme.space8),
                FilledButton.icon(
                  onPressed: report.hasOutput ? _export : null,
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text('تصدير PDF'),
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
              Text('صفوف لم تُصدر:', style: text.titleSmall),
              for (final BulkRowResult row in report.skipped)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
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
    final TextTheme text = Theme.of(context).textTheme;

    if (bytes == null) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.picture_as_pdf_outlined,
                  size: 40, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: AppTheme.space12),
              Text('المعاينة تظهر هنا', style: text.titleMedium),
              const SizedBox(height: AppTheme.space8),
              Text(
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

    return PdfPreview(
      build: (PdfPageFormat format) async => bytes,
      allowPrinting: false,
      allowSharing: false,
      canChangePageFormat: false,
      canChangeOrientation: false,
      canDebug: false,
    );
  }
}

// ============================================================================
//  عناصر واجهة صغيرة
// ============================================================================

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
