import 'dart:math' as math;
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../core/l10n/app_l10n.dart';
import '../../../../core/models/template_document.dart';
import '../../../../core/services/pdf_generator_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/templates/invitation_gallery.dart';
import '../../../../core/templates/invitation_group.dart';
import '../../../../core/templates/invitation_size.dart';
import '../../../batch_processor/domain/sheet_reader.dart';
import '../../../templates/presentation/widgets/template_thumbnail.dart';
import '../../data/invitation_output_writer.dart';
import '../../domain/invitation_export_service.dart';
import '../../domain/invitation_name_file.dart';
import '../providers/invitations_controller.dart';

/// شاشة «الدعوات الشخصية الجماعية»: كارت واحد ← ملف أسماء ← نسخة لكل اسم.
class InvitationsScreen extends StatefulWidget {
  const InvitationsScreen({
    super.key,
    this.controller,
    this.generator,
    this.service,
    this.writer,
    this.embedded = false,
  });

  /// يُمرَّر من الخارج في الاختبارات (وإلا بُني داخل الشاشة).
  final InvitationsController? controller;
  final PdfGeneratorService? generator;
  final InvitationExportService? service;
  final InvitationOutputWriter? writer;

  /// هل يُعرض **بلا Scaffold**؟
  ///
  /// الصورة الموحّدة للشاشتين: عند `true` يخرج المحتوى نفسه (القائمة
  /// الكاملة بكل أقسامها) ليُضمَّن داخل شاشة «التوليد الجماعي» حين يختار
  /// المستخدم «نوع القالب ← دعوة». وعند `false` (الافتراضي، وهو مسار
  /// `/invitations` الأصلي) تحتفظ الشاشة بـScaffoldها وخلفيتها وSafeArea
  /// تماماً كما كانت — فالمنطق كله واحد والفرق سطران في `build`.
  final bool embedded;

  @override
  State<InvitationsScreen> createState() => _InvitationsScreenState();
}

class _InvitationsScreenState extends State<InvitationsScreen> {
  late final InvitationsController _controller;
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ??
        InvitationsController(
          generator: widget.generator,
          service: widget.service,
          writer: widget.writer,
        );
  }

  @override
  void dispose() {
    _messageController.dispose();
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  // ==========================================================================
  //                                 الأوامر
  // ==========================================================================

  Future<void> _pickFile() async {
    final List<PlatformFile> picked;
    try {
      picked = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: SheetReaders.supportedExtensions,
        dialogTitle: 'اختر ملف الأسماء (Excel أو CSV)',
      );
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذّر فتح منتقي الملفات: $error')),
      );
      return;
    }
    if (picked.isEmpty) return;
    final PlatformFile file = picked.first;
    try {
      final Uint8List bytes = await file.readAsBytes();
      if (!mounted) return;
      await _controller.loadBytes(fileName: file.name, bytes: bytes);
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذّر قراءة الملف: $error')),
      );
    }
  }

  void _selectTemplate(InvitationTemplate template) {
    _controller.selectTemplate(template);
    _messageController.text = _controller.message;
  }

  Future<void> _startExport() async {
    final InvitationExportReport? report = await _controller.startExport();
    if (!mounted || report == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(report.cancelled
            ? 'تم إيقاف التوليد — حُفظ ما تم توليده.'
            : 'تم توليد ${report.fileCount} ملفاً.'),
      ),
    );
  }

  Future<void> _saveReport() async {
    final String? saved = await _controller.saveReport();
    if (!mounted || saved == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم الحفظ في: $saved')),
    );
  }

  // ==========================================================================
  //                                 الواجهة
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    final Widget content = AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, _) {
        final InvitationTemplate? template = _controller.template;
        return ListView(
          padding: const EdgeInsets.all(AppTheme.space24),
          children: <Widget>[
            _header(context),
            const SizedBox(height: AppTheme.space24),
            _sectionCard(
              context,
              title: context.l10n?.invCategoryTitle ?? 'دعوات ومناسبات',
              trailing: _groupFilter(context),
              child: _templateGrid(context, template),
            ),
            if (template != null) ...<Widget>[
              const SizedBox(height: AppTheme.space16),
              _sectionCard(
                context,
                title: template.titleAr,
                subtitle: _templateSubtitle(context, template),
                child: _templateEditor(context, template),
              ),
              const SizedBox(height: AppTheme.space16),
              _sectionCard(
                context,
                title: context.l10n?.invBulkModeTitle ?? 'دعوات شخصية جماعية',
                subtitle: context.l10n?.invBulkModeHint ??
                    'كارت واحد لكل اسم — تصدير فردي.',
                child: _importSection(context),
              ),
              const SizedBox(height: AppTheme.space16),
              _sectionCard(
                context,
                title: context.l10n?.invPreviewTitle ?? 'معاينة أول 3 نسخ',
                child: _previewSection(context),
              ),
              const SizedBox(height: AppTheme.space16),
              _sectionCard(
                context,
                // مضمَّنة: مفتاح الصيغة صار في شريط التوليد الجماعي، فتُسمّى
                // البطاقة بما فيها فعلاً (ZIP وCSV).
                title: widget.embedded
                    ? context.l10n?.invPackOptions ?? 'خيارات الإخراج'
                    : context.l10n?.invExportFormat ?? 'صيغة التصدير',
                child: _optionsSection(context),
              ),
              const SizedBox(height: AppTheme.space24),
              _generateSection(context),
            ],
          ],
        );
      },
    );

    // مضمَّنة داخل التوليد الجماعي: اللون وSafeArea مسؤولية الشاشة الأم،
    // فلا نُغلّف في Scaffold ثانٍ فوق أول.
    if (widget.embedded) return content;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(child: content),
    );
  }

  // ------------------------------- أقسام -------------------------------

  Widget _header(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          context.l10n?.invBulkModeTitle ?? 'دعوات شخصية جماعية',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: AppTheme.space4),
        Text(
          context.l10n?.invBulkModeHint ?? 'كارت واحد لكل اسم — تصدير فردي.',
          style: const TextStyle(color: AppColors.inkMuted),
        ),
      ],
    );
  }

  Widget _groupFilter(BuildContext context) {
    return Wrap(
      spacing: AppTheme.space8,
      children: <Widget>[
        ChoiceChip(
          label: Text(context.l10n?.invCategoryTitle ?? 'الكل'),
          selected: _controller.groupFilter == null,
          onSelected: (_) => _controller.selectGroup(null),
        ),
        for (final InvitationGroup group in InvitationGroup.values)
          ChoiceChip(
            avatar: Icon(group.icon, size: 16),
            label: Text(_groupLabel(context, group)),
            selected: _controller.groupFilter == group,
            onSelected: (_) => _controller.selectGroup(group),
          ),
      ],
    );
  }

  Widget _templateGrid(BuildContext context, InvitationTemplate? selected) {
    final List<InvitationTemplate> visible = _controller.visibleTemplates;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = math.min(constraints.maxWidth, 1180);
        const int columns = 4;
        final double spacing = AppTheme.space12;
        final double tile = (width - spacing * (columns - 1)) / columns;        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: <Widget>[
            for (final InvitationTemplate template in visible)
              SizedBox(
                width: tile,
                child: _TemplateCard(
                  title: _templateTitle(context, template),
                  sizeLabel: _sizeLabel(context, template.size),
                  groupLabel: _groupLabel(context, template.group),
                  accent: Color(_parseHex(template.group.accentHex)),
                  document: template.document,
                  selected: selected?.id == template.id,
                  onTap: () => _selectTemplate(template),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _templateEditor(BuildContext context, InvitationTemplate template) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              child: SizedBox(
                width: 96,
                height: 96,
                child: TemplateThumbnail(document: template.document),
              ),
            ),
            const SizedBox(width: AppTheme.space16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    template.descriptionAr,
                    style: const TextStyle(color: AppColors.inkMuted),
                  ),
                  const SizedBox(height: AppTheme.space8),
                  _InfoRow(
                    label: context.l10n?.invExportFormat ?? 'المقاس',
                    value: _sizeLabel(context, template.size),
                  ),
                  _InfoRow(
                    label: 'حقل الاسم',
                    value: '{{الاسم}}',
                  ),
                ],
              ),
            ),
          ],
        ),
        if (!_controller.templateHasNameField)
          _Notice(
            text: context.l10n?.invNameFieldMissing ??
                'هذا القالب لا يحتوي على حقل {الاسم}',
            color: AppColors.danger,
          ),
        const SizedBox(height: AppTheme.space16),
        TextField(
          controller: _messageController,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'نص الرسالة (قابل للتعديل)',
            border: OutlineInputBorder(),
          ),
          onChanged: _controller.setMessage,
        ),
      ],
    );
  }

  Widget _importSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Wrap(
          spacing: AppTheme.space8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            FilledButton.icon(
              onPressed: _controller.busy ? null : _pickFile,
              icon: const Icon(Icons.upload_file_rounded),
              label: const Text('رفع ملف الأسماء (Excel/CSV)'),
            ),
            if (_controller.loadingFile)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            if (_controller.fileName != null)
              Text(_controller.fileName!,
                  style: const TextStyle(color: AppColors.inkMuted)),
          ],
        ),
        if (_controller.sheetNames.length > 1) ...<Widget>[
          const SizedBox(height: AppTheme.space12),
          DropdownButtonFormField<String>(
            initialValue: _controller.sheetName,
            decoration: const InputDecoration(
              labelText: 'ورقة العمل',
              border: OutlineInputBorder(),
            ),
            items: <DropdownMenuItem<String>>[
              for (final String name in _controller.sheetNames)
                DropdownMenuItem<String>(value: name, child: Text(name)),
            ],
            onChanged: (String? name) {
              if (name != null) _controller.selectSheet(name);
            },
          ),
        ],
        if (_controller.hasSheet) ...<Widget>[
          const SizedBox(height: AppTheme.space12),
          DropdownButtonFormField<int>(
            initialValue: _controller.nameColumn,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'عمود الأسماء',
              border: OutlineInputBorder(),
            ),
            items: <DropdownMenuItem<int>>[
              for (final int column in _controller.dataColumns)
                DropdownMenuItem<int>(
                  value: column,
                  child: Text(
                    'عمود ${column + 1} — ${_controller.headerAt(column)}',
                  ),
                ),
            ],
            onChanged: _controller.setNameColumn,
          ),
          const SizedBox(height: AppTheme.space8),
          Text(
            'عدد الصفوف: ${_controller.sheet.rowCount}',
            style: const TextStyle(color: AppColors.inkMuted),
          ),
        ],
        if (_controller.duplicateNames.isNotEmpty)
          _Notice(
            text:
                context.l10n?.invDuplicateNames(_controller.duplicateNames.length) ??
                    'أسماء مكررة: ${_controller.duplicateNames.length}',
            color: AppColors.warning,
          ),
        if (_controller.emptyCount > 0)
          _Notice(
            text: context.l10n?.invEmptyNames(_controller.emptyCount) ??
                'خلايا فارغة: ${_controller.emptyCount} — ستُتخطى',
            color: AppColors.warning,
          ),
        if (_controller.errorAr != null)
          _Notice(text: _controller.errorAr!, color: AppColors.danger),
      ],
    );
  }

  Widget _previewSection(BuildContext context) {
    final List<InvitationRowPlan> preview = _controller.previewPlans;
    if (preview.isEmpty) {
      return const Text(
        'ارفع ملفاً يحوي عمود «الاسم» لتظهر المعاينة.',
        style: TextStyle(color: AppColors.inkMuted),
      );
    }
    return Column(
      children: <Widget>[
        for (final InvitationRowPlan plan in preview)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppTheme.space4),
            child: Row(
              children: <Widget>[
                Expanded(
                  flex: 2,
                  child: Text(plan.name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                Expanded(
                  child: Text(
                    '${plan.fileNameBase}.png',
                    style: const TextStyle(color: AppColors.inkMuted),
                    textDirection: TextDirection.ltr,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _optionsSection(BuildContext context) {
    return Column(
      children: <Widget>[
        // في الوضع المضمَّن داخل «التوليد الجماعي» يوفّر شريط التوليد مفتاح
        // «نوع التصدير» بخياراته الثلاثة، فلا نكرّر المفتاح هنا — ويبقى في
        // البطاقة ما لا يوجد في الشريط: ضغط ZIP وفهرس CSV.
        if (!widget.embedded) ...<Widget>[
          SegmentedButton<InvitationExportFormat>(
            segments: <ButtonSegment<InvitationExportFormat>>[
              for (final InvitationExportFormat format
                  in InvitationExportFormat.values)
                ButtonSegment<InvitationExportFormat>(
                  value: format,
                  label: Text(_formatLabel(context, format)),
                ),
            ],
            selected: <InvitationExportFormat>{_controller.format},
            onSelectionChanged: (Set<InvitationExportFormat> selection) =>
                _controller.setFormat(selection.first),
          ),
          const SizedBox(height: AppTheme.space12),
        ],
        SwitchListTile(
          value: _controller.zip,
          onChanged: _controller.setZip,
          title: Text(context.l10n?.invZIPOption ?? 'ضغط في ملف ZIP'),
        ),
        SwitchListTile(
          value: _controller.csv,
          onChanged: _controller.setCsv,
          title:
              Text(context.l10n?.invIndexCSVOption ?? 'إنشاء فهرس CSV'),
        ),
      ],
    );
  }

  Widget _generateSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (_controller.busy) ...<Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            child: LinearProgressIndicator(
              value: _controller.progress,
              minHeight: 10,
            ),
          ),
          const SizedBox(height: AppTheme.space8),
          Text(
            context.l10n?.invProgressText(_controller.done, _controller.total) ??
                'تم توليد ${_controller.done} من ${_controller.total}',
            style: const TextStyle(color: AppColors.inkMuted),
          ),
          const SizedBox(height: AppTheme.space8),
          Row(
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: _controller.togglePause,
                icon: Icon(_controller.paused
                    ? Icons.play_arrow_rounded
                    : Icons.pause_rounded),
                label: Text(_controller.paused ? 'متابعة' : 'إيقاف مؤقت'),
              ),
              const SizedBox(width: AppTheme.space8),
              OutlinedButton.icon(
                onPressed: _controller.requestCancel,
                icon: const Icon(Icons.stop_rounded),
                label: const Text('إلغاء'),
              ),
            ],
          ),
        ],
        Wrap(
          spacing: AppTheme.space8,
          children: <Widget>[
            FilledButton.icon(
              onPressed: _controller.busy ? null : _startExport,
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text('ابدأ التوليد'),
            ),
            if (_controller.report != null && _controller.report!.fileCount > 0)
              OutlinedButton.icon(
                onPressed: _saveReport,
                icon: const Icon(Icons.folder_open_rounded),
                label: const Text('حفظ الملفات'),
              ),
          ],
        ),
        if (_controller.report != null) ...<Widget>[
          const SizedBox(height: AppTheme.space12),
          _ResultSummary(report: _controller.report!),
        ],
      ],
    );
  }

  // ------------------------------ مساعدات ------------------------------

  Widget _sectionCard(
    BuildContext context, {
    required String title,
    required Widget child,
    String? subtitle,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    if (subtitle != null)
                      Text(subtitle,
                          style: const TextStyle(color: AppColors.inkMuted)),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: AppTheme.space12),
          child,
        ],
      ),
    );
  }

  String _templateSubtitle(BuildContext context, InvitationTemplate template) =>
      '${_groupLabel(context, template.group)} — '
      '${_sizeLabel(context, template.size)}';

  String _templateTitle(BuildContext context, InvitationTemplate template) {
    return switch (template.titleKey) {
      'invRamadan1Title' =>
        context.l10n?.invRamadan1Title ?? template.titleAr,
      'invRamadan2Title' =>
        context.l10n?.invRamadan2Title ?? template.titleAr,
      'invEid1Title' => context.l10n?.invEid1Title ?? template.titleAr,
      'invEid2Title' => context.l10n?.invEid2Title ?? template.titleAr,
      'invWedding1Title' =>
        context.l10n?.invWedding1Title ?? template.titleAr,
      'invWedding2Title' =>
        context.l10n?.invWedding2Title ?? template.titleAr,
      'invWedding3Title' =>
        context.l10n?.invWedding3Title ?? template.titleAr,
      _ => template.titleAr,
    };
  }

  String _sizeLabel(BuildContext context, InvitationSize size) {
    return switch (size.labelKey) {
      'invSizeA6Portrait' =>
        context.l10n?.invSizeA6Portrait ?? size.labelAr,
      'invSizeA6Landscape' =>
        context.l10n?.invSizeA6Landscape ?? size.labelAr,
      'invSizeSquare148' => context.l10n?.invSizeSquare148 ?? size.labelAr,
      'invSizeA5Folded' => context.l10n?.invSizeA5Folded ?? size.labelAr,
      'invSizeInstagramSquare' =>
        context.l10n?.invSizeInstagramSquare ?? size.labelAr,
      'invSizeInstagramPortrait' =>
        context.l10n?.invSizeInstagramPortrait ?? size.labelAr,
      'invSizeInstagramStory' =>
        context.l10n?.invSizeInstagramStory ?? size.labelAr,
      'invSizeWhatsAppStatus' =>
        context.l10n?.invSizeWhatsAppStatus ?? size.labelAr,
      'invSizeFacebookPost' =>
        context.l10n?.invSizeFacebookPost ?? size.labelAr,
      _ => size.labelAr,
    };
  }

  String _groupLabel(BuildContext context, InvitationGroup group) {
    return switch (group.labelKey) {
      'invCategoryRamadan' => context.l10n?.invCategoryRamadan ?? group.labelAr,
      'invCategoryEid' => context.l10n?.invCategoryEid ?? group.labelAr,
      'invCategoryWedding' =>
        context.l10n?.invCategoryWedding ?? group.labelAr,
      _ => group.labelAr,
    };
  }

  String _formatLabel(BuildContext context, InvitationExportFormat format) {
    return switch (format.labelKey) {
      'invExportFormatPNG' => context.l10n?.invExportFormatPNG ?? format.labelAr,
      'invExportFormatPDF' => context.l10n?.invExportFormatPDF ?? format.labelAr,
      'invExportFormatBoth' =>
        context.l10n?.invExportFormatBoth ?? format.labelAr,
      _ => format.labelAr,
    };
  }
}

int _parseHex(String hex) {
  final String clean = hex.replaceAll('#', '');
  return int.parse('FF$clean', radix: 16);
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({
    required this.title,
    required this.sizeLabel,
    required this.groupLabel,
    required this.accent,
    required this.document,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String sizeLabel;
  final String groupLabel;
  final Color accent;
  final TemplateDocument document;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: selected ? accent : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppTheme.radiusMd),
                ),
                child: TemplateThumbnail(document: document),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppTheme.space8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: AppTheme.space2),
                  Text(groupLabel,
                      style: TextStyle(color: accent, fontSize: 12)),
                  Text(sizeLabel,
                      style: const TextStyle(
                          color: AppColors.inkMuted, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.space2),
      child: Row(
        children: <Widget>[
          Text('$label: ',
              style: const TextStyle(color: AppColors.inkMuted)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: AppTheme.space8),
      padding: const EdgeInsets.all(AppTheme.space8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.info_outline_rounded, size: 16, color: color),
          const SizedBox(width: AppTheme.space8),
          Expanded(child: Text(text, style: TextStyle(color: color))),
        ],
      ),
    );
  }
}

class _ResultSummary extends StatelessWidget {
  const _ResultSummary({required this.report});

  final InvitationExportReport report;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space12),
      decoration: BoxDecoration(
        color: AppColors.successSoft,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'تم توليد ${report.fileCount} ملفاً '
            '(${report.pngCount} PNG / ${report.pdfCount} PDF) '
            'خلال ${report.elapsed.inSeconds} ثانية.',
            style: const TextStyle(color: AppColors.ink),
          ),
          if (report.hasZip)
            Text('أرشيف ZIP جاهز (${report.fileCount} ملفاً).',
                style: const TextStyle(color: AppColors.inkMuted)),
          if (report.hasCsv)
            const Text('فهرس CSV جاهز.',
                style: TextStyle(color: AppColors.inkMuted)),
        ],      ),
    );
  }
}
