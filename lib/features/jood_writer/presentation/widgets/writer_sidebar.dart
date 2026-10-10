import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/jood_writer_document.dart';
import '../writer_document_controller.dart';

class WriterSidebar extends StatelessWidget {
  const WriterSidebar({super.key, required this.controller});

  final WriterDocumentController controller;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(left: BorderSide(color: scheme.outlineVariant)),
      ),
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final JoodWriterDocument doc = controller.document;
          return ListView(
            padding: const EdgeInsets.all(AppTheme.space16),
            children: [
              // المستند: الاسم، الحفظ، والمستندات المحفوظة
              _DocumentPanel(controller: controller),
              const Divider(height: AppTheme.space32),

              Text(
                'إعدادات الصفحة',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: AppTheme.space16),

              // الحجم
              Text('حجم الورقة', style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: AppTheme.space4),
              DropdownButtonFormField<JoodWriterPageSize>(
                initialValue: doc.pageSize,
                decoration: const InputDecoration(isDense: true),
                items: JoodWriterPageSize.all
                    .map(
                      (s) => DropdownMenuItem(value: s, child: Text(s.label)),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) controller.setPageSize(v);
                },
              ),
              const SizedBox(height: AppTheme.space16),

              // الاتجاه
              Text('الاتجاه', style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: AppTheme.space4),
              SegmentedButton<WriterOrientation>(
                segments: WriterOrientation.values
                    .map(
                      (o) => ButtonSegment(
                        value: o,
                        label: Text(o.labelAr),
                        icon: Icon(
                          o == WriterOrientation.portrait
                              ? Icons.crop_portrait
                              : Icons.crop_landscape,
                        ),
                      ),
                    )
                    .toList(),
                selected: {doc.orientation},
                onSelectionChanged: (set) =>
                    controller.setOrientation(set.first),
                style: SegmentedButton.styleFrom(
                  textStyle: const TextStyle(fontSize: 12),
                  padding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(height: AppTheme.space24),

              // الهوامش
              Text(
                'الهوامش (مم)',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(height: AppTheme.space8),
              Row(
                children: [
                  Expanded(
                    child: _MarginField(
                      label: 'أعلى',
                      value: doc.margins.top,
                      onChanged: (v) =>
                          controller.setMargins(doc.margins.copyWith(top: v)),
                    ),
                  ),
                  const SizedBox(width: AppTheme.space8),
                  Expanded(
                    child: _MarginField(
                      label: 'أسفل',
                      value: doc.margins.bottom,
                      onChanged: (v) => controller.setMargins(
                        doc.margins.copyWith(bottom: v),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.space8),
              Row(
                children: [
                  Expanded(
                    child: _MarginField(
                      label: 'يمين',
                      value: doc.margins.right,
                      onChanged: (v) =>
                          controller.setMargins(doc.margins.copyWith(right: v)),
                    ),
                  ),
                  const SizedBox(width: AppTheme.space8),
                  Expanded(
                    child: _MarginField(
                      label: 'يسار',
                      value: doc.margins.left,
                      onChanged: (v) =>
                          controller.setMargins(doc.margins.copyWith(left: v)),
                    ),
                  ),
                ],
              ),
              const Divider(height: AppTheme.space32),

              // تخصيص أرقام الصفحات: النمط والحجم واللون والمحاذاة
              _PageNumberStylePanel(controller: controller),
              const Divider(height: AppTheme.space32),

              // عرض المستند وتكبير
              Text('التكبير', style: Theme.of(context).textTheme.labelSmall),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.zoom_out, size: 18),
                    onPressed: controller.zoomOut,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  Expanded(
                    child: Slider(
                      value: controller.zoomLevel,
                      min: 0.5,
                      max: 3.0,
                      divisions: 25,
                      label: '${(controller.zoomLevel * 100).round()}%',
                      onChanged: controller.setZoom,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.zoom_in, size: 18),
                    onPressed: controller.zoomIn,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              Center(
                child: Text(
                  '${(controller.zoomLevel * 100).round()}%',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// لوحة المستند: اسم المستند، الحفظ الفوري/التلقائي، وقائمة المحفوظات
/// (فتح مستند، حذفه، مستند جديد) — إدارة كاملة لدورة حياة المستند.
class _DocumentPanel extends StatefulWidget {
  const _DocumentPanel({required this.controller});

  final WriterDocumentController controller;

  @override
  State<_DocumentPanel> createState() => _DocumentPanelState();
}

class _DocumentPanelState extends State<_DocumentPanel> {
  late final TextEditingController _titleController;
  final List<WriterDocumentSummary> _saved = <WriterDocumentSummary>[];
  bool _listOpen = false;
  bool _busy = false;

  WriterDocumentController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: controller.document.title);
    controller.addListener(_syncTitleFromDocument);
    _refresh();
  }

  @override
  void dispose() {
    controller.removeListener(_syncTitleFromDocument);
    _titleController.dispose();
    super.dispose();
  }

  /// العنوان يتغيّر من المصدر (فتح مستند، أو استرجاع الجلسة) ⇒ نحدّث الحقل.
  void _syncTitleFromDocument() {
    final String title = controller.document.title;
    if (title == _titleController.text) return;
    _titleController.value = TextEditingValue(
      text: title,
      selection: TextSelection.collapsed(offset: title.length),
    );
  }

  Future<void> _refresh() async {
    // التفضيلات قد لا تتوفر (بيئة اختبار بلا مزوّد) ⇒ لا نُسقط اللوحة.
    final List<WriterDocumentSummary> items;
    try {
      items = await controller.listSavedDocuments();
    } on Object {
      return;
    }
    if (!mounted) return;
    setState(() {
      _saved
        ..clear()
        ..addAll(items);
    });
  }

  Future<void> _saveNow() async {
    setState(() => _busy = true);
    await controller.saveDocument();
    if (!mounted) return;
    setState(() => _busy = false);
    await _refresh();
  }

  Future<void> _open(String id) async {
    setState(() => _busy = true);
    await controller.loadSavedDocument(id);
    if (!mounted) return;
    setState(() => _busy = false);
    await _refresh();
  }

  Future<void> _delete(String id) async {
    await controller.deleteSavedDocument(id);
    if (!mounted) return;
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool dirty = controller.isDirty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('المستند', style: theme.textTheme.titleSmall),
        const SizedBox(height: AppTheme.space8),
        TextField(
          key: const ValueKey<String>('writer-doc-title'),
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'اسم المستند',
            isDense: true,
            contentPadding: EdgeInsets.all(8),
          ),
          onSubmitted: controller.renameDocument,
          onChanged: controller.renameDocument,
        ),
        const SizedBox(height: AppTheme.space8),
        Row(
          children: [
            Expanded(
              child: FilledButton.tonalIcon(
                key: const ValueKey<String>('writer-doc-save'),
                icon: _busy
                    ? const SizedBox.square(
                        dimension: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined, size: 16),
                label: const Text('حفظ الآن'),
                onPressed: _busy ? null : _saveNow,
              ),
            ),
            const SizedBox(width: AppTheme.space8),
            IconButton(
              key: const ValueKey<String>('writer-doc-list-toggle'),
              tooltip: 'المستندات المحفوظة',
              icon: Icon(
                _listOpen ? Icons.expand_less : Icons.folder_open,
                size: 20,
              ),
              onPressed: () => setState(() => _listOpen = !_listOpen),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.space4),
        Row(
          children: [
            Icon(
              dirty ? Icons.radio_button_unchecked : Icons.check_circle,
              size: 12,
              color: dirty ? scheme.error : scheme.primary,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                dirty ? 'تغييرات غير محفوظة' : 'محفوظ (تلقائياً)',
                style: theme.textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        if (_listOpen) ...[
          const SizedBox(height: AppTheme.space8),
          if (_saved.isEmpty)
            Text('لا مستندات محفوظة بعد.', style: theme.textTheme.bodySmall)
          else
            for (final WriterDocumentSummary item in _saved)
              _SavedDocumentTile(
                item: item,
                isCurrent: item.id == controller.documentId,
                onOpen: () => _open(item.id),
                onDelete: () => _delete(item.id),
              ),
          TextButton.icon(
            key: const ValueKey<String>('writer-doc-new'),
            icon: const Icon(Icons.note_add_outlined, size: 16),
            label: const Text('مستند جديد'),
            onPressed: () {
              controller.createNewDocument();
              _refresh();
            },
          ),
        ],
      ],
    );
  }
}

/// بطاقة مستند محفوظ: فتحها باللمس، وحذفها نهائيًا بالأيقونة.
class _SavedDocumentTile extends StatelessWidget {
  const _SavedDocumentTile({
    required this.item,
    required this.isCurrent,
    required this.onOpen,
    required this.onDelete,
  });

  final WriterDocumentSummary item;
  final bool isCurrent;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        isCurrent ? Icons.description : Icons.description_outlined,
        size: 18,
        color: isCurrent ? theme.colorScheme.primary : null,
      ),
      title: Text(item.title, style: theme.textTheme.bodySmall, maxLines: 1),
      subtitle: Text(
        '${item.updatedAt.day}/${item.updatedAt.month}/${item.updatedAt.year}',
        style: theme.textTheme.labelSmall,
      ),
      trailing: IconButton(
        tooltip: 'حذف نهائي',
        icon: const Icon(Icons.delete_outline, size: 16),
        onPressed: onDelete,
      ),
      onTap: onOpen,
    );
  }
}

/// لوحة تخصيص أرقام الصفحات: نمط العرض، حجم الخط، اللون، والمحاذاة —
/// تُحدِّث إعدادات الترقيم في المستند مباشرةً.
class _PageNumberStylePanel extends StatelessWidget {
  const _PageNumberStylePanel({required this.controller});

  final WriterDocumentController controller;

  /// الألوان المقدَّمة ك Алексанات سريعة.
  static const List<Color> _swatches = <Color>[
    Colors.black,
    Color(0xFF757575),
    Color(0xFF1565C0),
    Color(0xFFC62828),
    Color(0xFF2E7D32),
  ];

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final PageNumberingConfig numbering = controller.document.pageNumbering;

    void update(PageNumberingConfig Function(PageNumberingConfig) change) {
      controller.setPageNumbering(change(numbering));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('أرقام الصفحات', style: theme.textTheme.titleSmall),
        const SizedBox(height: AppTheme.space8),

        // نمط العرض
        Text('النمط', style: theme.textTheme.labelSmall),
        DropdownButtonFormField<PageNumberPattern>(
          initialValue: numbering.pattern,
          decoration: const InputDecoration(isDense: true),
          items: PageNumberPattern.values
              .map((p) => DropdownMenuItem(value: p, child: Text(p.labelAr)))
              .toList(),
          onChanged: (v) {
            if (v != null) update((c) => c.copyWith(pattern: v));
          },
        ),
        const SizedBox(height: AppTheme.space8),

        // المحاذاة: يمين/وسط/يسار فعلياً
        Text('المحاذاة', style: theme.textTheme.labelSmall),
        SegmentedButton<PageNumberAlign>(
          segments: PageNumberAlign.values
              .map(
                (a) => ButtonSegment(
                  value: a,
                  label: Text(a.labelAr),
                  icon: Icon(size: 16, switch (a) {
                    // في الاتجاه العربي: `format_align_left` يُقرأ «يمين».
                    PageNumberAlign.right => Icons.format_align_left,
                    PageNumberAlign.center => Icons.format_align_center,
                    PageNumberAlign.left => Icons.format_align_right,
                  }),
                ),
              )
              .toList(),
          selected: {numbering.align},
          onSelectionChanged: (set) =>
              update((c) => c.copyWith(align: set.first)),
          style: SegmentedButton.styleFrom(
            textStyle: const TextStyle(fontSize: 12),
            padding: EdgeInsets.zero,
          ),
        ),
        const SizedBox(height: AppTheme.space8),

        // حجم الخط
        Row(
          children: [
            Text('الحجم', style: theme.textTheme.labelSmall),
            const Spacer(),
            IconButton(
              tooltip: 'تصغير الرقم',
              icon: const Icon(Icons.remove, size: 16),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: numbering.fontSize > 6
                  ? () => update((c) => c.copyWith(fontSize: c.fontSize - 1))
                  : null,
            ),
            SizedBox(
              width: 34,
              child: Text(
                '${numbering.fontSize.round()}',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            ),
            IconButton(
              tooltip: 'تكبير الرقم',
              icon: const Icon(Icons.add, size: 16),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: numbering.fontSize < 24
                  ? () => update((c) => c.copyWith(fontSize: c.fontSize + 1))
                  : null,
            ),
          ],
        ),
        const SizedBox(height: AppTheme.space8),

        // اللون
        Text('اللون', style: theme.textTheme.labelSmall),
        const SizedBox(height: AppTheme.space4),
        Wrap(
          spacing: AppTheme.space8,
          runSpacing: AppTheme.space4,
          children: [
            for (final Color color in _swatches)
              _ColorSwatch(
                color: color,
                selected: numbering.color == color.toARGB32(),
                onTap: () => update((c) => c.copyWith(color: color.toARGB32())),
              ),
            _ColorSwatch(
              color: scheme.outline, // الرمادي الافتراضي للتذييل
              selected: numbering.color == null,
              label: 'تلقائي',
              onTap: () => update((c) => c.copyWith(clearColor: true)),
            ),
          ],
        ),
      ],
    );
  }
}

/// دائرة لون صغيرة مع حلقة تحديد على اللون المختار.
class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({
    required this.color,
    required this.selected,
    required this.onTap,
    this.label,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label ?? '',
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 22,
          height: 22,
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.black12,
              width: selected ? 2.5 : 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _MarginField extends StatelessWidget {
  const _MarginField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value.toStringAsFixed(1),
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        contentPadding: const EdgeInsets.all(8),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (text) {
        final double? val = double.tryParse(text);
        if (val != null && val >= 0) {
          onChanged(val);
        }
      },
    );
  }
}
