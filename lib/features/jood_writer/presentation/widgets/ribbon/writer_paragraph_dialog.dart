/// نافذة «الفقرة» — كل خصائص الفقرة في حوار واحد كـWord:
/// المحاذاة، الإزاحات (يسار/يمين/السطر الأول)، والتباعد (قبل/بعد/بين الأسطر).
///
/// التحقّق من الإدخال: أرقام موجبة، والخطوات تُطبَّق على الكتلة النشطة عند
/// «موافق» فقط (لا تغيير فوري أثناء الكتابة في الحقول).
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/l10n/app_l10n.dart';
import '../../../domain/jood_writer_block.dart';
import '../../writer_document_controller.dart';

Future<void> showWriterParagraphDialog(
  BuildContext context, {
  required WriterDocumentController controller,
}) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext dialogContext) =>
        WriterParagraphDialog(controller: controller),
  );
}

class WriterParagraphDialog extends StatefulWidget {
  const WriterParagraphDialog({super.key, required this.controller});

  final WriterDocumentController controller;

  @override
  State<WriterParagraphDialog> createState() => _WriterParagraphDialogState();
}

class _WriterParagraphDialogState extends State<WriterParagraphDialog> {
  late JoodWriterAlign _align;
  late double _indentCm;
  late double _firstLineCm;
  late double _before;
  late double _after;
  late double _lineSpacing;

  late final TextEditingController _indent =
      TextEditingController(text: _fmt(_initial.indentCm));
  late final TextEditingController _firstLine =
      TextEditingController(text: _fmt(_initial.firstLineIndentCm));
  late final TextEditingController _beforeCtrl =
      TextEditingController(text: _fmt(_initial.spaceBefore));
  late final TextEditingController _afterCtrl =
      TextEditingController(text: _fmt(_initial.spaceAfter));

  JoodWriterBlock get _initial =>
      widget.controller.activeBlock ?? const JoodWriterBlock(text: '');

  static String _fmt(double v) => v == v.roundToDouble()
      ? v.round().toString()
      : v.toStringAsFixed(1);

  @override
  void initState() {
    super.initState();
    final JoodWriterBlock block = _initial;
    _align = block.align;
    _indentCm = block.indentCm;
    _firstLineCm = block.firstLineIndentCm;
    _before = block.spaceBefore;
    _after = block.spaceAfter;
    _lineSpacing = block.lineSpacing;
  }

  @override
  void dispose() {
    _indent.dispose();
    _firstLine.dispose();
    _beforeCtrl.dispose();
    _afterCtrl.dispose();
    super.dispose();
  }

  static double _parse(TextEditingController c, double fallback) =>
      double.tryParse(c.text.trim()) ?? fallback;

  void _apply() {
    final JoodWriterBlock? block = widget.controller.activeBlock;
    if (block != null) {
      widget.controller.updateActiveBlock(
        block.copyWith(
          align: _align,
          indentCm: _parse(_indent, _indentCm).clamp(0.0, 10.0),
          firstLineIndentCm: _parse(_firstLine, _firstLineCm).clamp(-5.0, 10.0),
          spaceBefore: _parse(_beforeCtrl, _before).clamp(0.0, 100.0),
          spaceAfter: _parse(_afterCtrl, _after).clamp(0.0, 100.0),
          lineSpacing: _lineSpacing.clamp(0.75, 3.0),
        ),
      );
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n?.jwParagraphDialogTitle ?? 'إعدادات الفقرة'),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // ------------------------- المحاذاة -------------------------
              Text(
                l10n?.jwAlignLabel ?? 'المحاذاة',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 6),
              SegmentedButton<JoodWriterAlign>(
                segments: <ButtonSegment<JoodWriterAlign>>[
                  ButtonSegment<JoodWriterAlign>(
                    value: JoodWriterAlign.start,
                    icon: const Icon(Icons.format_align_right, size: 18),
                    tooltip: l10n?.jwAlignRight ?? 'يمين',
                  ),
                  ButtonSegment<JoodWriterAlign>(
                    value: JoodWriterAlign.center,
                    icon: const Icon(Icons.format_align_center, size: 18),
                    tooltip: l10n?.jwAlignCenter ?? 'وسط',
                  ),
                  ButtonSegment<JoodWriterAlign>(
                    value: JoodWriterAlign.end,
                    icon: const Icon(Icons.format_align_left, size: 18),
                    tooltip: l10n?.jwAlignLeft ?? 'يسار',
                  ),
                  ButtonSegment<JoodWriterAlign>(
                    value: JoodWriterAlign.justify,
                    icon: const Icon(Icons.format_align_justify, size: 18),
                    tooltip: l10n?.jwJustify ?? 'ضبط',
                  ),
                ],
                selected: <JoodWriterAlign>{_align},
                onSelectionChanged: (Set<JoodWriterAlign> s) =>
                    setState(() => _align = s.first),
              ),
              const SizedBox(height: 16),

              // ------------------------- الإزاحات -------------------------
              Text(
                l10n?.jwIndentationLabel ?? 'الإزاحات (سم)',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 6),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _NumberField(
                      key: const ValueKey<String>('paragraph-indent-general'),
                      label: l10n?.jwIndentGeneral ?? 'إزاحة الفقرة',
                      controller: _indent,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _NumberField(
                      key: const ValueKey<String>('paragraph-indent-first'),
                      label: l10n?.jwIndentFirstLine ?? 'السطر الأول',
                      controller: _firstLine,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ------------------------- التباعد -------------------------
              Text(
                l10n?.jwSpacingLabel ?? 'التباعد',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 6),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _NumberField(
                      key: const ValueKey<String>('paragraph-space-before'),
                      label: l10n?.jwSpaceBefore ?? 'قبل (بكسل)',
                      controller: _beforeCtrl,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _NumberField(
                      key: const ValueKey<String>('paragraph-space-after'),
                      label: l10n?.jwSpaceAfter ?? 'بعد (بكسل)',
                      controller: _afterCtrl,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<double>(
                key: const ValueKey<String>('paragraph-line-spacing'),
                initialValue: <double>[1.0, 1.15, 1.5, 2.0, 2.5, 3.0].contains(
                  _lineSpacing,
                )
                    ? _lineSpacing
                    : 1.5,
                decoration: InputDecoration(
                  labelText: l10n?.jwLineHeightLabel ?? 'ارتفاع السطر',
                ),
                items: <double>[1.0, 1.15, 1.5, 2.0, 2.5, 3.0]
                    .map(
                      (double v) => DropdownMenuItem<double>(
                        value: v,
                        child: Text(v.toString()),
                      ),
                    )
                    .toList(),
                onChanged: (double? v) =>
                    setState(() => _lineSpacing = v ?? _lineSpacing),
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          key: const ValueKey<String>('paragraph-cancel'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n?.jwCancel ?? 'إلغاء'),
        ),
        FilledButton(
          key: const ValueKey<String>('paragraph-ok'),
          onPressed: _apply,
          child: Text(l10n?.jwOk ?? 'موافق'),
        ),
      ],
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    super.key,
    required this.label,
    required this.controller,
  });

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.-]')),
      ],
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
