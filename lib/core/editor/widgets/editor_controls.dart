import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// مُستورَد باسم مستعار لأن الحزمة تُصدّر `colorFromHex` أيضاً، وهو ما يتعارض
// مع أداة الألوان الخاصة بالمشروع (نفس الاسم وترتيب معاملات مختلف).
import 'package:flutter_colorpicker/flutter_colorpicker.dart' as picker;

import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../utils/hex_color.dart';

/// لوحة ألوان الهوية السريعة — تُعرض قبل منتقي الألوان الكامل.
const List<Color> kEditorPalette = <Color>[
  AppColors.navy,
  AppColors.gold,
  AppColors.goldDeep,
  AppColors.navySoft,
  AppColors.inkMuted,
  AppColors.success,
  AppColors.warning,
  AppColors.danger,
  Colors.black,
  Colors.white,
];

/// عنوان قسم داخل شريط الخصائص.
class ControlSection extends StatelessWidget {
  const ControlSection({
    super.key,
    required this.icon,
    required this.label,
    required this.children,
  });

  final IconData icon;
  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 14, color: Theme.of(context).colorScheme.goldDeep),
            const SizedBox(width: 5),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 11.5,
                  ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.space8),
        Wrap(
          spacing: AppTheme.space12,
          runSpacing: AppTheme.space8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: children,
        ),
      ],
    );
  }
}

/// حقل رقمي مع أزرار زيادة/إنقاص — أدق من الشريط للأحجام والزوايا.
class NumberField extends StatefulWidget {
  const NumberField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.step = 1,
    this.min,
    this.max,
    this.decimals = 0,
    this.unit,
    this.width = 148,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final double step;
  final double? min;
  final double? max;
  final int decimals;

  /// وحدة تُعرض بجانب الرقم (نقطة/بكسل…).
  final String? unit;
  final double width;

  @override
  State<NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<NumberField> {
  late final TextEditingController _controller =
      TextEditingController(text: _format(widget.value));
  late final FocusNode _focusNode = FocusNode();

  String _format(double value) => widget.decimals == 0
      ? value.round().toString()
      : value.toStringAsFixed(widget.decimals);

  @override
  void didUpdateWidget(NumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_focusNode.hasFocus) return;
    final String next = _format(widget.value);
    if (_controller.text != next) _controller.text = next;
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _emit(double value) {
    double next = value;
    if (widget.min != null) next = next < widget.min! ? widget.min! : next;
    if (widget.max != null) next = next > widget.max! ? widget.max! : next;
    widget.onChanged(next);
  }

  void _commitText(String raw) {
    final double? parsed = double.tryParse(raw.trim());
    if (parsed == null) {
      _controller.text = _format(widget.value);
      return;
    }
    _emit(parsed);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface),
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]')),
              ],
              decoration: InputDecoration(
                isDense: true,
                labelText: widget.label,
                labelStyle: const TextStyle(fontSize: 11.5),
                suffixText: widget.unit,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 10,
                ),
              ),
              onSubmitted: _commitText,
              onEditingComplete: () => _commitText(_controller.text),
              onTapOutside: (_) => _commitText(_controller.text),
            ),
          ),
          const SizedBox(width: 4),
          _StepButton(
            icon: Icons.remove_rounded,
            onTap: () => _emit(widget.value - widget.step),
          ),
          _StepButton(
            icon: Icons.add_rounded,
            onTap: () => _emit(widget.value + widget.step),
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, size: 15),
      color: Theme.of(context).colorScheme.primary,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 26, height: 30),
      tooltip: icon == Icons.add_rounded ? 'زيادة' : 'إنقاص',
    );
  }
}

/// حقل شريط تمرير لقيمة تقع بين حدّين.
class SliderField extends StatelessWidget {
  const SliderField({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.display,
    this.width = 190,
    this.divisions,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final String Function(double value)? display;
  final double width;
  final int? divisions;

  @override
  Widget build(BuildContext context) {
    final String shown = display?.call(value) ??
        (value == value.roundToDouble()
            ? value.round().toString()
            : value.toStringAsFixed(2));
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                label,
                style: TextStyle(fontSize: 11.5, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const Spacer(),
              Text(
                shown,
                textDirection: TextDirection.ltr,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          SizedBox(
            height: 24,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2.5,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              ),
              child: Slider(
                value: value.clamp(min, max),
                min: min,
                max: max,
                divisions: divisions,
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// قائمة منسدلة مدمجة.
class DropdownField<T> extends StatelessWidget {
  const DropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.labelOf,
    required this.onChanged,
    this.width = 180,
    this.keyOf,
  });

  final String label;
  final T value;
  final List<T> items;
  final String Function(T item) labelOf;
  final ValueChanged<T> onChanged;
  final double width;

  /// مفتاح التمييز (للأنواع التي لا تُقارن بالهوية).
  final String Function(T item)? keyOf;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: InputDecorator(
        decoration: InputDecoration(
          isDense: true,
          labelText: label,
          labelStyle: const TextStyle(fontSize: 11.5),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: value,
            isDense: true,
            isExpanded: true,
            style: TextStyle(fontSize: 12.5, color: Theme.of(context).colorScheme.onSurface),
            icon: const Icon(Icons.expand_more_rounded, size: 16),
            items: <DropdownMenuItem<T>>[
              for (final T item in items)
                DropdownMenuItem<T>(
                  value: item,
                  child: Text(
                    labelOf(item),
                    style: const TextStyle(fontSize: 12.5),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (T? selected) {
              if (selected != null) onChanged(selected);
            },
          ),
        ),
      ),
    );
  }
}

/// اختيار من عدة خيارات بأزرار مدمجة.
class SegmentedField<T> extends StatelessWidget {
  const SegmentedField({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.labelOf,
    required this.onChanged,
    this.iconOf,
    this.hint,
  });

  final String label;
  final T value;
  final List<T> options;
  final String Function(T option) labelOf;
  final IconData? Function(T option)? iconOf;
  final ValueChanged<T> onChanged;

  /// تلميح اختياري يظهر عند المرور على التسمية (مثل اختصار لوحة المفاتيح).
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final Widget labelWidget = Text(
      label,
      style: TextStyle(fontSize: 11.5, color: Theme.of(context).colorScheme.onSurfaceVariant),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (hint == null)
          labelWidget
        else
          Tooltip(message: hint!, child: labelWidget),
        const SizedBox(height: 5),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (final T option in options)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: _SegmentButton(
                  label: labelOf(option),
                  icon: iconOf?.call(option),
                  selected: option == value,
                  onTap: () => onChanged(option),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? scheme.primary : scheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            border: Border.all(
              color: selected ? scheme.primary : scheme.outline,
            ),
          ),
          child: icon == null
              ? Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
                  ),
                )
              : Icon(
                  icon,
                  size: 15,
                  color: selected
                      ? (scheme.brightness == Brightness.dark
                          ? scheme.onPrimary
                          : AppColors.gold)
                      : scheme.onSurfaceVariant,
                ),
        ),
      ),
    );
  }
}

/// حقل لون مع لوحة سريعة ومنتقي كامل.
class ColorField extends StatelessWidget {
  const ColorField({
    super.key,
    required this.label,
    required this.hex,
    required this.onChanged,
    this.onClear,
    this.width = 190,
  });

  final String label;

  /// القيمة الحالية `#RRGGBB` (أو null للشفاف).
  final String? hex;
  final ValueChanged<String> onChanged;

  /// عند تمريره يظهر زر "بلا" لإزالة اللون.
  final VoidCallback? onClear;

  final double width;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color current = colorFromHex(hex, fallback: Colors.transparent);
    final bool hasColor = hex != null && hex!.trim().isNotEmpty;

    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: TextStyle(fontSize: 11.5, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 5),
          Row(
            children: <Widget>[
              Tooltip(
                message: 'لوحة سريعة',
                child: PopupMenuButton<Color>(
                  tooltip: 'لوحة سريعة',
                  onSelected: (Color color) => onChanged(hexFromColor(color)),
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<Color>>[
                    for (final Color color in kEditorPalette)
                      PopupMenuItem<Color>(
                        value: color,
                        height: 34,
                        child: Row(
                          children: <Widget>[
                            Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: scheme.outline),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              hexFromColor(color),
                              style: const TextStyle(fontSize: 11.5),
                            ),
                          ],
                        ),
                      ),
                  ],
                  child: Container(
                    width: 34,
                    height: 30,
                    decoration: BoxDecoration(
                      color: hasColor ? current : scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      border: Border.all(color: scheme.outline),
                    ),
                    child: hasColor
                        ? null
                        : Icon(Icons.block_rounded,
                            size: 14, color: scheme.onSurfaceVariant),
                  ),
                ),
              ),
              const SizedBox(width: 5),
              Tooltip(
                message: 'منتقي ألوان كامل',
                child: InkWell(
                  onTap: () async {
                    final String? picked = await showEditorColorPicker(
                      context,
                      initialHex: hasColor ? hex! : '#1B2539',
                    );
                    if (picked != null) onChanged(picked);
                  },
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      border: Border.all(color: scheme.outline),
                    ),
                    child: Icon(Icons.colorize_rounded,
                        size: 15, color: scheme.primary),
                  ),
                ),
              ),
              if (onClear != null) ...<Widget>[
                const SizedBox(width: 5),
                Tooltip(
                  message: 'إزالة اللون',
                  child: InkWell(
                    onTap: onClear,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        border: Border.all(color: scheme.outline),
                      ),
                      child: Text(
                        'بلا',
                        style: TextStyle(
                          fontSize: 11,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// زر أيقوني مدمج في شريط الأدوات.
class IconAction extends StatelessWidget {
  const IconAction({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.selected = false,
    this.danger = false,
    this.size = 32,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool selected;
  final bool danger;
  final double size;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool enabled = onPressed != null;
    final Color foreground = !enabled
        ? AppColors.inkDisabled
        : danger
            ? scheme.danger
            : selected
                ? (scheme.brightness == Brightness.dark
                    ? scheme.onPrimary
                    : AppColors.gold)
                : scheme.primary;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: selected ? scheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            border: Border.all(
              color: selected ? scheme.primary : scheme.outline,
            ),
          ),
          child: Icon(icon, size: size * 0.52, color: foreground),
        ),
      ),
    );
  }
}

/// منتقي ألوان كامل (يعيد `#RRGGBB` أو `null` عند الإلغاء).
Future<String?> showEditorColorPicker(
  BuildContext context, {
  required String initialHex,
}) {
  Color picked = colorFromHex(initialHex);
  return showDialog<String>(
    context: context,
    builder: (BuildContext dialogContext) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return AlertDialog(
            title: const Text('اختيار لون'),
            contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  picker.ColorPicker(
                    pickerColor: picked,
                    // بلا قناة شفافية: الشفافية تُدار بحقل مستقل لكل عنصر.
                    enableAlpha: false,
                    hexInputBar: true,
                    labelTypes: const <picker.ColorLabelType>[
                      picker.ColorLabelType.rgb,
                    ],
                    onColorChanged: (Color color) =>
                        setState(() => picked = color),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: <Widget>[
                      for (final Color color in kEditorPalette)
                        InkWell(
                          onTap: () => setState(() => picked = color),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('إلغاء'),
              ),
              FilledButton(
                onPressed: () =>
                    Navigator.of(dialogContext).pop(hexFromColor(picked)),
                child: const Text('تطبيق'),
              ),
            ],
          );
        },
      );
    },
  );
}
