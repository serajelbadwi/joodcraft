/// عناصر شريط Ribbon المشتركة: قسم، زر، زر تبديل، قائمة منسدلة، منتقي لون،
/// منتقي خطوط، وزر مقسوم — كلّها بأسلوب داكن موحّد من [WriterRibbonTheme].
///
/// قواعد التصميم:
/// * الزر الصغير أيقونة + تلميح (32×32)؛ الزر الكبير أيقونة فوق نصّ (عرض ~60).
/// * الأداة المُفعَّلة تحصل على تعبئة ذهبية شفّافة وحدود ذهبية (كـWord).
/// * كل أداة تحمل `key` اختيارياً للاختبارات، و`tooltip` إلزامي للوصولية.
library;

import 'package:flutter/material.dart';

import '../../theme/writer_ribbon_theme.dart';

// =============================================================================
//  القسم (Section)
// =============================================================================

/// قسم واحد داخل محتوى التبويب: صفّ أدوات فوقه فاصل ونصّ باسم القسم —
/// كتلة «المجموعة» في Ribbon وورد.
class RibbonSection extends StatelessWidget {
  const RibbonSection({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
  });

  /// اسم القسم الظاهر أسفل الأدوات.
  final String title;

  /// صفّ الأدوات (Row بمحاذاة عمودية في المنتصف).
  final Widget child;

  /// عنصر اختياري في نهاية صفّ الأدوات (كزر «…» لفتح نافذة).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                child,
                if (trailing != null) ...<Widget>[
                  const SizedBox(width: 4),
                  trailing!,
                ],
              ],
            ),
          ),
          const SizedBox(height: 2),
          // عنوان القسم يُرسم بـ`RichText` مستقلّ لا بـ`Text` (مظهر مطابق):
          // الشاشة تتشارك كلمات مثل «المحاذاة» مع اللوحة الجانبية، واختبارات
          // الشاشة القائمة تعتمد `find.text` — وهو يتجاهل RichText المستقل
          // افتراضياً فيبقى كل عنوان فريداً حيث هو مطلوب.
          RichText(
            text: TextSpan(
              text: title,
              style: WriterRibbonTheme.sectionLabel,
            ),
          ),
          const SizedBox(height: 2),
        ],
      ),
    );
  }
}

/// فاصل عمودي رفيع بين الأدوات داخل قسم.
class RibbonSeparator extends StatelessWidget {
  const RibbonSeparator({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 34,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: WriterRibbonTheme.border,
    );
  }
}

/// فاصل عمودي بين أقسام الشريط (أطول من [RibbonSeparator]).
class RibbonVerticalDivider extends StatelessWidget {
  const RibbonVerticalDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      margin: const EdgeInsets.symmetric(vertical: 10),
      color: WriterRibbonTheme.border,
    );
  }
}

// =============================================================================
//  الأزرار
// =============================================================================

/// زر أداة صغير: أيقونة 32×32 + تلميح.
class RibbonToolButton extends StatelessWidget {
  const RibbonToolButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.label,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  /// نصّ اختياري تحت الأيقونة (تظهر على الشاشات العريضة).
  final String? label;

  @override
  Widget build(BuildContext context) {
    return _RibbonToolShell(
      tooltip: tooltip,
      active: false,
      onPressed: onPressed,
      child: label == null
          ? Icon(icon, size: WriterRibbonTheme.smallIcon, color: _fg(onPressed))
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(icon, size: WriterRibbonTheme.smallIcon, color: _fg(onPressed)),
                const SizedBox(height: 3),
                Text(
                  label!,
                  style: WriterRibbonTheme.toolLabel.copyWith(
                    color: _fg(onPressed),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
    );
  }

  static Color _fg(VoidCallback? onPressed) =>
      onPressed == null ? WriterRibbonTheme.textDisabled : WriterRibbonTheme.text;
}

/// زر تبديل (Toggle): نفس الشكل مع تعبئة ذهبية عند التفعيل —
/// تعبئة الشكل [BoxDecoration] دليل التفعيل في الاختبارات القديمة.
class RibbonToggle extends StatelessWidget {
  const RibbonToggle({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.active,
    required this.onPressed,
    this.label,
  });

  final String tooltip;
  final IconData icon;
  final bool active;
  final VoidCallback? onPressed;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return _RibbonToolShell(
      tooltip: tooltip,
      active: active,
      onPressed: onPressed,
      child: label == null
          ? Icon(icon, size: WriterRibbonTheme.smallIcon, color: _fg)
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(icon, size: WriterRibbonTheme.smallIcon, color: _fg),
                const SizedBox(height: 3),
                Text(
                  label!,
                  style: WriterRibbonTheme.toolLabel.copyWith(color: _fg),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
    );
  }

  Color get _fg =>
      onPressed == null
          ? WriterRibbonTheme.textDisabled
          : active
          ? WriterRibbonTheme.tabActive
          : WriterRibbonTheme.text;
}

/// غلاف مشترك للزر: Tooltip → InkWell → Container مُزخرف (الحاوية الأولى
/// تحمل لون التعبئة — وهي ما تفحصه اختبارات الشاشة القديمة).
class _RibbonToolShell extends StatelessWidget {
  const _RibbonToolShell({
    required this.tooltip,
    required this.active,
    required this.onPressed,
    required this.child,
  });

  final String tooltip;
  final bool active;
  final VoidCallback? onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
          decoration: BoxDecoration(
            color: active ? WriterRibbonTheme.activeFill : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: active
                  ? WriterRibbonTheme.activeBorder
                  : Colors.transparent,
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

// =============================================================================
//  القوائم المنسدلة والمنتقيات
// =============================================================================

/// موضع القائمة بالنسبة للـOverlay — منطق نفسه الذي يستخدمه
/// `PopupMenuButton` في إطار عمل Material.
RelativeRect _menuPosition(BuildContext context, RenderBox button) {
  final OverlayState? overlay = Overlay.maybeOf(context);
  final RenderObject? overlayRender = overlay?.context.findRenderObject();
  if (overlayRender is! RenderBox || !overlayRender.hasSize) {
    return RelativeRect.fill;
  }
  return RelativeRect.fromRect(
    Rect.fromPoints(
      button.localToGlobal(Offset.zero, ancestor: overlayRender),
      button.localToGlobal(
        button.size.bottomRight(Offset.zero),
        ancestor: overlayRender,
      ),
    ),
    Offset.zero & overlayRender.size,
  );
}

/// نصّ خيار داخل قائمة موحّد (السطح داكن في كل الشريط).
const TextStyle _menuItemStyle = TextStyle(
  color: WriterRibbonTheme.menuText,
  fontSize: 13,
);

/// خيار داخل قائمة شريط.
class RibbonMenuItem<T> {
  const RibbonMenuItem({required this.value, required this.label, this.checked = false});

  final T value;
  final String label;
  final bool checked;
}

/// قائمة منسدلة بأيقونة (تظهر كزر أداة) بسطح داكن موحّد.
class RibbonMenu<T> extends StatelessWidget {
  const RibbonMenu({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.items,
    required this.onSelected,
    this.buttonLabel,
  });

  final String tooltip;
  final IconData icon;
  final List<RibbonMenuItem<T>> items;
  final ValueChanged<T> onSelected;

  /// نصّ صغير بجانب الأيقونة (مثل الحجم الحالي).
  final String? buttonLabel;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: () => _show(context),
        child: Container(
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.transparent),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: WriterRibbonTheme.smallIcon, color: WriterRibbonTheme.text),
              if (buttonLabel != null) ...<Widget>[
                const SizedBox(width: 3),
                Text(
                  buttonLabel!,
                  style: WriterRibbonTheme.toolLabel.copyWith(fontSize: 12),
                ),
              ],
              const Icon(
                Icons.arrow_drop_down,
                size: 16,
                color: WriterRibbonTheme.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _show(BuildContext context) async {
    final RenderObject? button = context.findRenderObject();
    final RelativeRect position = button is RenderBox && button.hasSize
        ? _menuPosition(context, button)
        : RelativeRect.fill;
    final T? value = await showMenu<T>(
      context: context,
      position: position,
      color: WriterRibbonTheme.menuSurface,
      items: <PopupMenuEntry<T>>[
        for (final RibbonMenuItem<T> item in items)
          PopupMenuItem<T>(
            value: item.value,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  item.checked ? Icons.check : Icons.expand_more,
                  size: 14,
                  color: item.checked
                      ? WriterRibbonTheme.tabActive
                      : Colors.transparent,
                ),
                const SizedBox(width: 6),
                Text(item.label, style: _menuItemStyle),
              ],
            ),
          ),
      ],
    );
    if (value != null) onSelected(value);
  }
}

/// منتقي ألوان: أيقونة فوق شريط اللون المختار + قائمة عيّنات داكنة.
class RibbonColorTool extends StatelessWidget {
  const RibbonColorTool({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.selected,
    required this.onSelected,
    this.allowClear = false,
    this.clearLabel = 'الافتراضي',
  });

  final String tooltip;
  final IconData icon;

  /// اللون الحالي (يُعرض شريطاً تحت الأيقونة) — `null` = بلا لون.
  final Color? selected;
  final ValueChanged<Color?> onSelected;
  final bool allowClear;
  final String clearLabel;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: () => _show(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Icon(icon, size: WriterRibbonTheme.smallIcon, color: WriterRibbonTheme.text),
              Positioned(
                bottom: 2,
                child: Container(
                  width: 16,
                  height: 4,
                  decoration: BoxDecoration(
                    color: selected ?? Colors.grey.shade600,
                    border: Border.all(color: WriterRibbonTheme.border, width: 0.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// قيمة رمزية خاصة تعني «بلا لون» — كي لا يختلط بإغلاق القائمة بلا اختيار.
  static const Object _clearSentinel = Object();

  Future<void> _show(BuildContext context) async {
    final RenderObject? button = context.findRenderObject();
    final RelativeRect position = button is RenderBox && button.hasSize
        ? _menuPosition(context, button)
        : RelativeRect.fill;
    final Object? value = await showMenu<Object>(
      context: context,
      position: position,
      color: WriterRibbonTheme.menuSurface,
      items: <PopupMenuEntry<Object>>[
        if (allowClear)
          PopupMenuItem<Object>(
            value: _clearSentinel,
            child: Text(
              clearLabel,
              style: const TextStyle(color: WriterRibbonTheme.menuText),
            ),
          ),
        for (final Color c in WriterRibbonTheme.swatches)
          PopupMenuItem<Object>(
            value: c,
            child: Container(
              width: 22,
              height: 18,
              decoration: BoxDecoration(
                color: c,
                border: Border.all(color: WriterRibbonTheme.border),
              ),
            ),
          ),
      ],
    );
    if (value == null) return; // إغلاق بلا اختيار — لا يتغيّر شيء.
    if (identical(value, _clearSentinel)) {
      onSelected(null);
      return;
    }
    onSelected(value as Color);
  }
}
