import 'package:flutter/material.dart';

import '../../l10n/app_l10n.dart';
import '../../models/template_element.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../element_factory.dart';
import '../template_editor_controller.dart';

/// شريط أدوات رفيع (نمط Photoshop) يطفو على يسار اللوحة.
///
/// يضغط أدوات الإضافة الأساسية في عمود ضيّق (44px) فلا يقتطع من مساحة التصميم
/// إلا أقل قدر، ومع ذلك تُفتح الأشكال في قائمة منسدلة صغيرة عند الطلب.
///
/// ويقبل [axis] ليرسم صفّاً أفقياً عند إرسائه في الشريط العلوي — فالأدوات
/// نفسها تُعاد ترتيبها بلا تكرار ولا نسخة ثانية من الوسوم.
class EditorToolPalette extends StatelessWidget {
  const EditorToolPalette({
    super.key,
    required this.controller,
    this.onTextAdded,
    this.axis = Axis.vertical,
  });

  final TemplateEditorController controller;
  final ValueChanged<TextElement>? onTextAdded;

  /// اتجاه صفّ الأدوات (رأسي في الشريط الجانبي، أفقي في الشريط العلوي).
  final Axis axis;

  static const double width = 44;

  void _add(BuildContext context, NewElementKind kind) {
    final TemplateElement element = controller.addElement(kind);
    if (element is TextElement) onTextAdded?.call(element);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      color: scheme.surface,
      child: Container(
        // العرض الضيّق الثابت للشريط الرأسي وحده؛ الأفقي يتمدّد بطول أدواته
        // فلا يفيض على حاويته عند الإرساء في الشريط العلوي.
        width: axis == Axis.vertical ? width : null,
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
        ),
        child: Flex(
          direction: axis,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _ToolButton(
              key: const ValueKey<String>('tool-select'),
              icon: Icons.near_me_rounded,
              tooltip: context.l10n?.editorToolSelect ?? 'تحديد',
              axis: axis,
              onPressed: controller.clearSelection,
            ),
            _ToolButton(
              key: const ValueKey<String>('tool-text'),
              icon: Icons.text_fields_rounded,
              tooltip: context.l10n?.editorLabelText ?? 'نص',
              axis: axis,
              onPressed: () => _add(context, NewElementKind.text),
            ),
            _ShapesToolButton(
              axis: axis,
              onSelected: (NewElementKind kind) => _add(context, kind),
            ),
            _ToolButton(
              key: const ValueKey<String>('tool-image'),
              icon: Icons.image_outlined,
              tooltip: context.l10n?.editorImage ?? 'صورة',
              axis: axis,
              onPressed: () => _add(context, NewElementKind.image),
            ),
            _ToolButton(
              key: const ValueKey<String>('tool-stamp'),
              icon: Icons.verified_rounded,
              tooltip: context.l10n?.editorLabelSeal ?? 'ختم',
              axis: axis,
              onPressed: () => _add(context, NewElementKind.seal),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShapesToolButton extends StatelessWidget {
  const _ShapesToolButton({required this.onSelected, this.axis = Axis.vertical});

  final ValueChanged<NewElementKind> onSelected;
  final Axis axis;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return PopupMenuButton<NewElementKind>(
      key: const ValueKey<String>('tool-shapes'),
      tooltip: context.l10n?.editorToolShapes ?? 'أشكال',
      onSelected: onSelected,
      itemBuilder: (BuildContext context) => <PopupMenuEntry<NewElementKind>>[
        _item(context, NewElementKind.rectangle, Icons.crop_square_rounded,
            context.l10n?.paletteFrame ?? 'مستطيل/برواز'),
        _item(context, NewElementKind.roundedRect, Icons.rounded_corner_rounded,
            context.l10n?.paletteRoundedRect ?? 'مستطيل بحواف منحنية'),
        _item(context, NewElementKind.ellipse, Icons.circle_outlined,
            context.l10n?.paletteEllipse ?? 'دائرة/بيضاوي'),
        _item(context, NewElementKind.star, Icons.star_outline_rounded,
            context.l10n?.paletteStar ?? 'نجمة'),
        _item(context, NewElementKind.polygon, Icons.hexagon_outlined,
            context.l10n?.palettePolygon ?? 'مضلّع'),
        _item(context, NewElementKind.divider, Icons.horizontal_rule_rounded,
            context.l10n?.paletteDivider ?? 'خط فاصل'),
      ],
      child: _ToolButtonFace(
        icon: Icons.category_rounded,
        color: scheme.primary,
        axis: axis,
      ),
    );
  }

  PopupMenuItem<NewElementKind> _item(
    BuildContext context,
    NewElementKind kind,
    IconData icon,
    String label,
  ) =>
      PopupMenuItem<NewElementKind>(
        value: kind,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
      );
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.axis = Axis.vertical,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Axis axis;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: _ToolButtonFace(
            icon: icon,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            axis: axis,
          ),
        ),
      ),
    );
  }
}

class _ToolButtonFace extends StatelessWidget {
  const _ToolButtonFace({
    required this.icon,
    required this.color,
    this.axis = Axis.vertical,
  });

  final IconData icon;
  final Color color;
  final Axis axis;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: axis == Axis.vertical ? EditorToolPalette.width : 38,
      height: 36,
      child: Icon(icon, size: 19, color: color),
    );
  }
}
