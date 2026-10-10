import 'package:flutter/material.dart';

import '../constants/app_assets.dart';
import '../l10n/app_l10n.dart';
import '../theme/app_colors.dart';
import 'app_icon.dart';

/// **نص العلامة التجارية «JoodCraft»** بنمط أنيق مزدوج اللون (كحلي/فاتح + ذهبي).
///
/// يُستخدم في الشريط العلوي وشاشات الدخول/التهيئة، فيبقى شكل الهوية موحّداً في
/// كل مكان بلا اعتماد على أي خط من الشبكة: يُبنى على خط الواجهة المحزوم مع وزن
/// ثقيل وتباعد أحرف (letter-spacing) يعطيه الطابع الاحترافي المميّز.
///
/// **لماذا الألوان من الثيم؟** لأن اللون الثابت (كحلي `#1B2539`) كان يختفي
/// تماماً على أسطح المظهر الداكن السليت (‎#3E3E3E‎) فيبدو جزء من
/// النص مفقوداً. الآن يُشتق اللون من `ColorScheme`:
/// - الكلمة الأولى: `onSurface` (كحلي نهاراً، فاتح ليلاً) — أو `onBrandSurface`
///   عند الوقوف على سطح هوية داكن صريح.
/// - كلمة «Craft»: ذهبي الهوية، ويُعمَّق نهاراً (`goldDeep`) ليقرأ على الأبيض
///   ويُضيء ليلاً (`gold`) ليقرأ على الفحمي.
class BrandWordmark extends StatelessWidget {
  const BrandWordmark({
    super.key,
    this.fontSize = 18,
    this.onDark = false,
    this.letterSpacing = 0.8,
  });

  /// حجم الخط بالبكسل.
  final double fontSize;

  /// إن كان النص موضوعاً على **سطح هوية داكن صريح** (كحلي أو فحمي).
  /// عند `false` يُشتق اللون من سطوع الثيم تلقائياً فلا يختفي على أي خلفية.
  final bool onDark;

  /// تباعد الأحرف — يمنح الطابع «المطبوع» الأنيق.
  final double letterSpacing;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    // سطح داكن صريح ⇒ نصّ فاتح ثابت؛ خلاف ذلك نتبع سطوع الثيم.
    final Color ink = onDark ? scheme.onBrandSurface : scheme.onSurface;
    final Color accent = onDark ? AppColors.gold : scheme.goldDeep;

    return Text.rich(
      TextSpan(
        children: <InlineSpan>[
          TextSpan(
            text: 'Jood',
            style: TextStyle(color: ink, fontWeight: FontWeight.w800),
          ),
          TextSpan(
            text: 'Craft',
            style: TextStyle(color: accent, fontWeight: FontWeight.w700),
          ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textDirection: TextDirection.ltr,
      style: TextStyle(
        fontSize: fontSize,
        letterSpacing: letterSpacing,
        height: 1.1,
      ),
    );
  }
}

/// الشعار الرسمي لمنصة JoodCraft — **أيقونة البرنامج المحزومة**
/// ([AppAssets.appIconImage]) بجوار النص، بدل الرسم البرمجي السابق.
///
/// **ضبط اللون:** أيقونة البرنامج كحلية، وعلى أسطح المظهر الداكن الفحمية تفقد
/// تباينها؛ فيُطبَّق عليها تصحيح سطوع خفيف (`_darkLiftMatrix`) يفتح الكحلي
/// والذهبي بلا مساس بالهوية. ويمكن لأي شاشة طلب **تلوين أحادي** صريح عبر
/// [tint]. وعند تعذّر قراءة الأصل (منصة بلا حزمة أصول) يسقط الرمز تلقائياً إلى
/// الرسم المتجهي [AppIcon] فلا تفرغ الهوية أبداً.
class JoodCraftLogo extends StatelessWidget {
  const JoodCraftLogo({
    super.key,
    this.size = 48,
    this.onDark = false,
    this.tint,
  });

  /// طول ضلع الشعار بالبكسل.
  final double size;

  /// إن كان الشعار موضوعاً على خلفية داكنة (يفتح ألوان الأيقونة).
  final bool onDark;

  /// تلوين أحادي صريح للأيقونة (اختياري) — يتجاوز ضبط السطوع.
  final Color? tint;

  /// تصحيح سطوع لطيف لأيقونة البرنامج على الأسطح الداكنة: مضاعفة القنوات بـ
  /// ‎1.15‎ مع إضافة ‎+18‎ (مقياس 0..255) — يفتح الكحلي والذهبي بلا تشويه.
  static const List<double> _darkLiftMatrix = <double>[
    1.15, 0, 0, 0, 18, //
    0, 1.15, 0, 0, 18, //
    0, 0, 1.15, 0, 18, //
    0, 0, 0, 1, 0, //
  ];

  @override
  Widget build(BuildContext context) {
    final Color? explicit = tint;
    final ColorFilter? filter = explicit != null
        ? ColorFilter.mode(explicit, BlendMode.srcIn)
        : onDark
            ? const ColorFilter.matrix(_darkLiftMatrix)
            : null;

    final double radius = size * 0.26;

    Widget icon = Image.asset(
      AppAssets.appIconImage,
      width: size,
      height: size,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
      semanticLabel: 'JoodCraft',
      // منصة بلا حزمة أصول (أو أصل مفقود) ⇒ الرسم المتجهي البديل.
      errorBuilder: (BuildContext context, Object error, StackTrace? stack) =>
          AppIcon(size: size, onDark: onDark, semanticLabel: 'JoodCraft'),
    );
    if (filter != null) {
      icon = ColorFiltered(colorFilter: filter, child: icon);
    }

    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: onDark ? 0.30 : 0.12),
              blurRadius: size * 0.14,
              offset: Offset(0, size * 0.05),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: icon,
        ),
      ),
    );
  }
}

/// ترويسة الهوية: أيقونة البرنامج + اسم البرنامج «JoodCraft» بنمط أنيق.
class JoodCraftWordmark extends StatelessWidget {
  const JoodCraftWordmark({
    super.key,
    this.markSize = 46,
    this.onDark = false,
    this.showTagline = true,
  });

  /// طول ضلع الرمز بالبكسل.
  final double markSize;

  /// إن كان الشعار موضوعاً على خلفية كحلية/فحمية داكنة.
  final bool onDark;

  /// إظهار السطر التعريفي أسفل الاسم.
  final bool showTagline;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color muted =
        onDark ? AppColors.onNavy : scheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        JoodCraftLogo(size: markSize, onDark: onDark),
        SizedBox(width: markSize * 0.26),
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              BrandWordmark(
                fontSize: markSize * 0.42,
                onDark: onDark,
              ),
              if (showTagline) ...<Widget>[
                SizedBox(height: markSize * 0.06),
                Text(
                  context.l10n?.appTagline ?? 'منصة توليد الشهادات والعقود',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: markSize * 0.2,
                    color: muted,
                    height: 1.2,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
