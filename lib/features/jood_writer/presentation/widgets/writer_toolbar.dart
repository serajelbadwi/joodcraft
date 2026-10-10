import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/jood_writer_block.dart';

/// شريط أدوات النصوص الأساسي لمستند «جود كاتب»: أنواع الكتل (عنوان رئيسي/
/// فرعي/فقرة/قائمة نقطية) + محاذاة النص + إضافة/حذف كتلة + تبديل المعاينة.
///
/// **مستقلّ عن الشاشة**: يستقبل القيم الفعلية للكتلة النشطة ويعيد كل تغيير عبر
/// النداءات الممرَّرة، فيبقى قابلاً للاختبار وحده.
class WriterToolbar extends StatelessWidget {
  const WriterToolbar({
    super.key,
    required this.activeKind,
    required this.activeAlign,
    required this.onKind,
    required this.onAlign,
    required this.onAddBlock,
    required this.onDeleteBlock,
    required this.previewOnly,
    required this.onTogglePreview,
    this.canDeleteBlock = true,
  });

  final JoodWriterBlockKind activeKind;
  final JoodWriterAlign activeAlign;
  final ValueChanged<JoodWriterBlockKind> onKind;
  final ValueChanged<JoodWriterAlign> onAlign;
  final VoidCallback onAddBlock;
  final VoidCallback onDeleteBlock;
  final bool previewOnly;
  final VoidCallback onTogglePreview;
  final bool canDeleteBlock;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      key: const ValueKey<String>('writer-toolbar'),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space12,
        vertical: AppTheme.space8,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Wrap(
        spacing: AppTheme.space6,
        runSpacing: AppTheme.space6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          _ToolButton(
            buttonKey: const ValueKey<String>('writer-kind-h1'),
            label: 'H1',
            tooltip: JoodWriterBlockKind.heading1.labelAr,
            selected: activeKind == JoodWriterBlockKind.heading1,
            onTap: () => onKind(JoodWriterBlockKind.heading1),
          ),
          _ToolButton(
            buttonKey: const ValueKey<String>('writer-kind-h2'),
            label: 'H2',
            tooltip: JoodWriterBlockKind.heading2.labelAr,
            selected: activeKind == JoodWriterBlockKind.heading2,
            onTap: () => onKind(JoodWriterBlockKind.heading2),
          ),
          _ToolButton(
            buttonKey: const ValueKey<String>('writer-kind-p'),
            label: 'نص',
            tooltip: JoodWriterBlockKind.paragraph.labelAr,
            selected: activeKind == JoodWriterBlockKind.paragraph,
            onTap: () => onKind(JoodWriterBlockKind.paragraph),
          ),
          _ToolButton(
            buttonKey: const ValueKey<String>('writer-kind-bullet'),
            label: '• قائمة',
            tooltip: JoodWriterBlockKind.bullet.labelAr,
            selected: activeKind == JoodWriterBlockKind.bullet,
            onTap: () => onKind(JoodWriterBlockKind.bullet),
          ),
          _Separator(color: scheme.outlineVariant),
          for (final JoodWriterAlign align in JoodWriterAlign.values)
            _ToolButton(
              buttonKey: ValueKey<String>('writer-align-${align.jsonValue}'),
              label: _alignLabel(align),
              tooltip: 'محاذاة: ${align.labelAr}',
              selected: activeAlign == align,
              onTap: () => onAlign(align),
            ),
          _Separator(color: scheme.outlineVariant),
          _ToolButton(
            buttonKey: const ValueKey<String>('writer-add-block'),
            icon: Icons.add_rounded,
            tooltip: 'إضافة كتلة',
            selected: false,
            onTap: onAddBlock,
          ),
          _ToolButton(
            buttonKey: const ValueKey<String>('writer-delete-block'),
            icon: Icons.delete_outline_rounded,
            tooltip: 'حذف الكتلة',
            selected: false,
            onTap: canDeleteBlock ? onDeleteBlock : null,
          ),
          _Separator(color: scheme.outlineVariant),
          _ToolButton(
            buttonKey: const ValueKey<String>('writer-toggle-preview'),
            icon: previewOnly
                ? Icons.edit_note_rounded
                : Icons.auto_stories_rounded,
            label: previewOnly ? 'تحرير' : 'معاينة الصفحات',
            tooltip: previewOnly ? 'العودة إلى التحرير' : 'معاينة الصفحات',
            selected: previewOnly,
            onTap: onTogglePreview,
          ),
        ],
      ),
    );
  }

  static String _alignLabel(JoodWriterAlign align) {
    switch (align) {
      case JoodWriterAlign.start:
        return '⟸';
      case JoodWriterAlign.center:
        return '≡';
      case JoodWriterAlign.end:
        return '⟹';
      case JoodWriterAlign.justify:
        return '☰';
    }
  }
}

class _Separator extends StatelessWidget {
  const _Separator({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 22,
    margin: const EdgeInsets.symmetric(horizontal: 2),
    color: color,
  );
}

/// زر أداة صغير بحالة تحديد واضحة ومفتاح اختبار.
class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.buttonKey,
    this.label,
    this.icon,
    required this.tooltip,
    required this.selected,
    required this.onTap,
  });

  final Key buttonKey;
  final String? label;
  final IconData? icon;
  final String tooltip;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool enabled = onTap != null;
    final Color background = selected
        ? scheme.primary.withValues(alpha: 0.14)
        : Colors.transparent;
    final Color foreground = !enabled
        ? scheme.onSurface.withValues(alpha: 0.38)
        : selected
        ? scheme.primary
        : scheme.onSurfaceVariant;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        key: buttonKey,
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            border: Border.all(
              color: selected ? scheme.primary : scheme.outlineVariant,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (icon != null)
                Icon(icon, size: 16, color: foreground)
              else
                Text(
                  label!,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    color: foreground,
                  ),
                ),
              if (icon != null && label != null) ...<Widget>[
                const SizedBox(width: 6),
                Text(
                  label!,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: foreground,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
