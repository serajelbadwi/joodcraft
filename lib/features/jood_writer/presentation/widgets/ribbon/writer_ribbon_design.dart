/// تبويب «التصميم» في شريط Ribbon — القوالب الجاهزة، الإدراج (أشكال/صور/
/// جداول/رموز)، وتنسيق الأشكال (لون الحشو والحدّ وسماكتها عند الإدراج).
///
/// ملاحظات ربط صريح:
/// * القوالب تُطبَّق كمستند كامل عبر `loadDocument` (محتوى لا سلوك).
/// * «دمج الأشكال / التجميع / المحاذاة» تتطلّب تحديداً تفاعلياً للأشكال
///   داخل اللوحة — غير مضمّنة هنا كي لا تظهر أزرار ميتة.
/// * ألوان تنسيق الشكل تُستخدم كقيم ابتدائية عند إدراج شكل جديد.
library;

import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../../core/l10n/app_l10n.dart';
import '../../../domain/writer_image.dart';
import '../../../domain/writer_shape.dart';
import '../../theme/writer_ribbon_theme.dart';
import '../../writer_document_controller.dart';
import 'writer_ribbon_common.dart';
import 'writer_ribbon_insert.dart';
import 'writer_templates_catalog.dart';

/// رموز جاهزة للإدراج.
const List<String> writerSymbols = <String>[
  '★', '☆', '✓', '✗', '§', '¶', '©', '®', '™',
  'π', 'Ω', '±', '≠', '≤', '≥', '×', '÷', '≈',
  '∞', '←', '→', '↑', '↓',
];

class WriterRibbonDesignTab extends StatefulWidget {
  const WriterRibbonDesignTab({super.key, required this.controller});

  final WriterDocumentController controller;

  @override
  State<WriterRibbonDesignTab> createState() => _WriterRibbonDesignTabState();
}

class _WriterRibbonDesignTabState extends State<WriterRibbonDesignTab> {
  /// القيم الابتدائية لألوان/سماكة الأشكال الجديدة.
  Color _shapeFill = const Color(0x33B8932E);
  Color _shapeOutline = const Color(0xFFB8932E);
  double _shapeStroke = 1.5;

  WriterTemplateCategory? _category;

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _applyTemplate(WriterDocumentTemplate template) {
    widget.controller.loadDocument(template.build());
    _snack('تم تطبيق القالب: ${template.nameAr}');
  }

  void _insertShape(WriterShapeKind kind) {
    widget.controller.addShape(
      WriterShape(
        kind: kind,
        pageIndex: 0,
        xMm: 60,
        yMm: 60,
        widthMm: kind == WriterShapeKind.line || kind == WriterShapeKind.arrow
            ? 60
            : 50,
        heightMm: kind == WriterShapeKind.line || kind == WriterShapeKind.arrow
            ? 0.1
            : 35,
        strokeColor: _shapeOutline,
        fillColor: kind == WriterShapeKind.line || kind == WriterShapeKind.arrow
            ? null
            : _shapeFill,
        strokeWidth: _shapeStroke,
      ),
    );
    _snack('أُدرج شكل: ${kind.labelAr}');
  }

  Future<void> _insertImage() async {
    try {
      // واجهة file_picker 13: `FilePicker.pickFiles` ثابتة وتعيد ملفات مباشرة.
      final List<PlatformFile> files = await FilePicker.pickFiles(
        type: FileType.image,
      );
      if (files.isEmpty) return; // أُلغي الاختيار.
      final PlatformFile file = files.first;
      final Uint8List bytes = await file.readAsBytes();
      widget.controller.addImage(
        WriterImage(
          pageIndex: 0,
          xMm: 30,
          yMm: 40,
          widthMm: 110,
          heightMm: 75,
          bytes: bytes,
          label: file.name,
        ),
      );
      _snack('أُدرجت الصورة');
    } catch (_) {
      _snack('تعذّر فتح منتقي الصور في هذه البيئة');
    }
  }

  void _insertTable(int rows, int cols) {
    final String row = List<String>.filled(cols, 'خانة').join(' │ ');
    for (int r = 0; r < rows; r++) {
      widget.controller.addBlockAfterActive();
      widget.controller.updateActiveBlock(
        widget.controller.activeBlock!.copyWith(text: row),
      );
    }
    _snack('أُدرج جدول $rows×$cols (نصّ بخانات — يُنسّق عند التحرير)');
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (BuildContext context, _) {
        final l10n = context.l10n;
        final List<WriterDocumentTemplate> templates =
            WriterTemplatesCatalog.of(_category);

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // ------------------------- 1. القوالب -------------------------
            RibbonSection(
              title: l10n?.jwSectionTemplates ?? 'القوالب',
              child: Row(
                children: <Widget>[
                  RibbonMenu<String>(
                    key: const ValueKey<String>('ribbon-template-category'),
                    tooltip: l10n?.jwTemplateCategory ?? 'فئة القالب',
                    icon: Icons.category_outlined,
                    buttonLabel: _category?.labelAr ??
                        (l10n?.jwTemplateAll ?? 'كل الفئات'),
                    items: <RibbonMenuItem<String>>[
                      RibbonMenuItem<String>(
                        value: '',
                        label: l10n?.jwTemplateAll ?? 'كل الفئات',
                        checked: _category == null,
                      ),
                      for (final WriterTemplateCategory c
                          in WriterTemplateCategory.values)
                        RibbonMenuItem<String>(
                          value: c.name,
                          label: c.labelAr,
                          checked: _category == c,
                        ),
                    ],
                    onSelected: (String value) => setState(() {
                      _category = value.isEmpty
                          ? null
                          : WriterTemplateCategory.values.firstWhere(
                              (WriterTemplateCategory c) => c.name == value,
                            );
                    }),
                  ),
                  const SizedBox(width: 6),
                  // شرائح القوالب — أول ستة من الفئة المختارة.
                  SizedBox(
                    height: 60,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: <Widget>[
                          for (final WriterDocumentTemplate t
                              in templates.take(6))
                            Padding(
                              padding: const EdgeInsetsDirectional.only(end: 6),
                              child: _TemplateChip(
                                key: ValueKey<String>('ribbon-template-${t.id}'),
                                template: t,
                                onTap: () => _applyTemplate(t),
                              ),
                            ),
                          RibbonToolButton(
                            key: const ValueKey<String>(
                              'ribbon-template-all',
                            ),
                            tooltip: l10n?.jwTemplates ?? 'كل القوالب',
                            icon: Icons.grid_view,
                            onPressed: () => showWriterTemplatesDialog(
                              context,
                              controller: widget.controller,
                              onApplied: _applyTemplate,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            RibbonVerticalDivider(),

            // ------------------------- 2. الإدراج -------------------------
            RibbonSection(
              title: l10n?.jwSectionInsert ?? 'الإدراج',
              child: Row(
                children: <Widget>[
                  RibbonMenu<WriterShapeKind>(
                    key: const ValueKey<String>('ribbon-shapes'),
                    tooltip: l10n?.jwShapes ?? 'أشكال',
                    icon: Icons.category_outlined,
                    items: <RibbonMenuItem<WriterShapeKind>>[
                      for (final WriterShapeKind kind in WriterShapeKind.values)
                        RibbonMenuItem<WriterShapeKind>(
                          value: kind,
                          label: kind.labelAr,
                        ),
                    ],
                    onSelected: _insertShape,
                  ),
                  RibbonToolButton(
                    key: const ValueKey<String>('ribbon-insert-image'),
                    tooltip: l10n?.jwInsertImage ?? 'إدراج صورة',
                    icon: Icons.image_outlined,
                    label: l10n?.jwInsertImageShort ?? 'صورة',
                    onPressed: _insertImage,
                  ),
                  RibbonMenu<String>(
                    key: const ValueKey<String>('ribbon-insert-table'),
                    tooltip: l10n?.jwInsertTable ?? 'إدراج جدول',
                    icon: Icons.grid_on_outlined,
                    items: const <RibbonMenuItem<String>>[
                      RibbonMenuItem<String>(value: '2x2', label: '2 × 2'),
                      RibbonMenuItem<String>(value: '3x3', label: '3 × 3'),
                      RibbonMenuItem<String>(value: '3x4', label: '3 × 4'),
                      RibbonMenuItem<String>(value: '4x5', label: '4 × 5'),
                    ],
                    onSelected: (String value) {
                      final List<int> parts = value
                          .split('x')
                          .map((String p) => int.parse(p))
                          .toList();
                      _insertTable(parts[0], parts[1]);
                    },
                  ),
                  RibbonMenu<String>(
                    key: const ValueKey<String>('ribbon-symbols'),
                    tooltip: l10n?.jwInsertSymbol ?? 'إدراج رمز',
                    icon: Icons.emoji_symbols_outlined,
                    items: <RibbonMenuItem<String>>[
                      for (final String s in writerSymbols)
                        RibbonMenuItem<String>(value: s, label: s),
                    ],
                    onSelected: (String s) =>
                        WriterRibbonInsert.atCaret(widget.controller, s),
                  ),
                ],
              ),
            ),
            RibbonVerticalDivider(),

            // --------------------- 3. تنسيق الأشكال ---------------------
            RibbonSection(
              title: l10n?.jwSectionShapeFormat ?? 'تنسيق الأشكال',
              child: Row(
                children: <Widget>[
                  RibbonColorTool(
                    key: const ValueKey<String>('ribbon-shape-fill'),
                    tooltip: l10n?.jwShapeFill ?? 'لون الحشو',
                    icon: Icons.format_color_fill,
                    selected: _shapeFill,
                    onSelected: (Color? c) => setState(() {
                      _shapeFill = c ?? const Color(0x33B8932E);
                    }),
                  ),
                  RibbonColorTool(
                    key: const ValueKey<String>('ribbon-shape-outline'),
                    tooltip: l10n?.jwShapeOutline ?? 'لون الحدّ',
                    icon: Icons.border_color_outlined,
                    selected: _shapeOutline,
                    onSelected: (Color? c) => setState(() {
                      _shapeOutline = c ?? const Color(0xFF000000);
                    }),
                  ),
                  RibbonMenu<double>(
                    key: const ValueKey<String>('ribbon-shape-stroke'),
                    tooltip: l10n?.jwShapeStrokeWidth ?? 'سماكة الحدّ',
                    icon: Icons.line_weight,
                    buttonLabel: '$_shapeStroke',
                    items: <RibbonMenuItem<double>>[
                      for (final double w in const <double>[0.5, 1, 1.5, 3])
                        RibbonMenuItem<double>(
                          value: w,
                          label: '$w',
                          checked: _shapeStroke == w,
                        ),
                    ],
                    onSelected: (double w) => setState(() => _shapeStroke = w),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    l10n?.jwShapeDefaultsHint ?? 'تُطبَّق عند الإدراج',
                    style: WriterRibbonTheme.sectionLabel,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// شريط قالب صغير: اسم القالب على بطاقة ذهبية الحدّ.
class _TemplateChip extends StatelessWidget {
  const _TemplateChip({
    super.key,
    required this.template,
    required this.onTap,
  });

  final WriterDocumentTemplate template;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: WriterRibbonTheme.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              template.nameAr,
              style: WriterRibbonTheme.toolLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              template.category.labelAr,
              style: WriterRibbonTheme.sectionLabel.copyWith(fontSize: 9),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
//  نافذة كل القوالب (مشتركة بين تبويبَي التصميم والحفظ)
// =============================================================================

Future<void> showWriterTemplatesDialog(
  BuildContext context, {
  required WriterDocumentController controller,
  required ValueChanged<WriterDocumentTemplate> onApplied,
}) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext dialogContext) => WriterTemplatesDialog(
      controller: controller,
      onApplied: onApplied,
    ),
  );
}

class WriterTemplatesDialog extends StatefulWidget {
  const WriterTemplatesDialog({
    super.key,
    required this.controller,
    required this.onApplied,
  });

  final WriterDocumentController controller;
  final ValueChanged<WriterDocumentTemplate> onApplied;

  @override
  State<WriterTemplatesDialog> createState() => _WriterTemplatesDialogState();
}

class _WriterTemplatesDialogState extends State<WriterTemplatesDialog> {
  WriterTemplateCategory? _category;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final List<WriterDocumentTemplate> templates =
        WriterTemplatesCatalog.of(_category);

    return AlertDialog(
      title: Text(l10n?.jwTemplates ?? 'القوالب'),
      content: SizedBox(
        width: 560,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Wrap(
              spacing: 6,
              children: <Widget>[
                ChoiceChip(
                  key: const ValueKey<String>('template-cat-all'),
                  label: Text(l10n?.jwTemplateAll ?? 'كل الفئات'),
                  selected: _category == null,
                  onSelected: (_) => setState(() => _category = null),
                ),
                for (final WriterTemplateCategory c
                    in WriterTemplateCategory.values)
                  ChoiceChip(
                    key: ValueKey<String>('template-cat-${c.name}'),
                    label: Text(c.labelAr),
                    selected: _category == c,
                    onSelected: (_) => setState(() => _category = c),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Flexible(
              child: GridView.count(
                shrinkWrap: true,
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 2.4,
                children: <Widget>[
                  for (final WriterDocumentTemplate t in templates)
                    InkWell(
                      key: ValueKey<String>('template-card-${t.id}'),
                      borderRadius: BorderRadius.circular(6),
                      onTap: () {
                        Navigator.of(context).pop();
                        widget.onApplied(t);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: WriterRibbonTheme.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              t.nameAr,
                              style: WriterRibbonTheme.toolLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Spacer(),
                            Text(
                              t.category.labelAr,
                              style: WriterRibbonTheme.sectionLabel,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n?.jwCancel ?? 'إلغاء'),
        ),
      ],
    );
  }
}
