import 'package:flutter/material.dart';

import '../constants/app_assets.dart';
import 'app_colors.dart';

/// الثيم البصري الرسمي لمنصة JoodCraft — فاتح وداكن.
///
/// القواعد المعمارية المطبقة هنا:
/// * خط **Cairo** هو الخط الافتراضي لكل نصوص الواجهة.
/// * الاتجاه **RTL** يُفرض على مستوى التطبيق (راجع `app.dart`).
/// * نصف الأقطار موحّد عبر ``AppRadii`` والفروق عبر ``AppSpacing``.
/// * مكونات Material مُعاد تنسيقها مسبقاً حتى لا تُكرَّر الأنماط داخل الشاشات.
/// * الثيمان (فاتح/داكن) يُنشآن من **منشئ واحد** (`_build`) مبني على
///   `ColorScheme` — فلا يتشتت التنسيق بين الوضعين، وتتكيّف الأسطح والحقول
///   والنصوص تلقائياً مع `Theme.of(context).colorScheme`.
abstract final class AppTheme {
  const AppTheme._();

  /// نصف قطر العناصر الصغيرة (شارات، حقول مصغّرة).
  static const double radiusSm = 8;

  /// نصف القطر الافتراضي للعناصر التفاعلية.
  static const double radiusMd = 12;

  /// نصف قطر البطاقات والألواح.
  static const double radiusLg = 18;

  /// نصف قطر العناصر الدائرية بالكامل (أزرار أيقونية).
  static const double radiusPill = 999;

  /// سلم التباعد الموحّد (مضاعفات 4).
  static const double space2 = 2;
  static const double space4 = 4;
  static const double space6 = 6;
  static const double space8 = 8;
  static const double space10 = 10;
  static const double space12 = 12;
  static const double space16 = 16;
  static const double space20 = 20;
  static const double space24 = 24;
  static const double space32 = 32;
  static const double space40 = 40;
  static const double space48 = 48;

  /// ارتفاع أزرار الإجراءات الرئيسية.
  static const double controlHeight = 52;

  /// ارتفاع حقول الإدخال.
  static const double fieldHeight = 56;

  // ==========================================================================
  //  الثيمات
  // ==========================================================================

  /// الثيم الفاتح (الافتراضي).
  static ThemeData get light => _build(scheme: _lightScheme(), isDark: false);

  /// الثيم الداكن — نفس الهوية بترتيب إضاءة معكوس.
  static ThemeData get dark => _build(scheme: _darkScheme(), isDark: true);

  /// لوحة الألوان الفاتحة — القيم الرسمية في ``AppColors``.
  static ColorScheme _lightScheme() => const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.navy,
        onPrimary: AppColors.onNavy,
        primaryContainer: AppColors.navyWash,
        onPrimaryContainer: AppColors.navy,
        secondary: AppColors.gold,
        onSecondary: AppColors.navy,
        secondaryContainer: AppColors.goldSoft,
        onSecondaryContainer: AppColors.goldDeep,
        tertiary: AppColors.navySoft,
        onTertiary: AppColors.onNavy,
        error: AppColors.danger,
        onError: Colors.white,
        errorContainer: AppColors.dangerSoft,
        onErrorContainer: AppColors.danger,
        surface: AppColors.surface,
        onSurface: AppColors.ink,
        surfaceContainerHighest: AppColors.background,
        onSurfaceVariant: AppColors.inkMuted,
        outline: AppColors.border,
        outlineVariant: AppColors.border,
        shadow: Color(0x14000000),
        // التنبيهات والتلميحات تبقى كحلية (هوية الشعار) في الوضعين:
        inverseSurface: AppColors.navy,
        onInverseSurface: AppColors.onNavy,
        inversePrimary: AppColors.gold,
      );

  /// لوحة الألوان الداكنة — **سليت موحّد** (Unified Slate): الهيكل الخارجي
  /// `#3E3E3E` (الخلفية والسطح معاً) ← مرتفع `#454545` ← مساحة عمل `#4A4A4A`
  /// ← حدود `#4F4F4F`، والنصوص `#F0F0F0`/`#A0A0A0`. لا وجود لأي درجة شبه
  /// سوداء، ويبقى الذهبي لون الإبراز الوحيد الدافئ لتبقى هوية المنصة واضحة.
  static ColorScheme _darkScheme() => const ColorScheme(
        brightness: Brightness.dark,
        primary: AppColors.gold,
        onPrimary: AppColors.navy,
        primaryContainer: AppColors.darkNavyWash,
        onPrimaryContainer: AppColors.darkInk,
        secondary: AppColors.gold,
        onSecondary: AppColors.navy,
        secondaryContainer: AppColors.darkGoldSoft,
        onSecondaryContainer: AppColors.gold,
        tertiary: Color(0xFF8FA8D0),
        onTertiary: Color(0xFF10203C),
        error: AppColors.darkDanger,
        onError: Color(0xFF2A0F0C),
        errorContainer: Color(0xFF3A1F1D),
        onErrorContainer: Color(0xFFFFC9C2),
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkInk,
        // الهيكل الخارجي موحّد (لا فرق مُظلم بين الخلفية والسطح).
        surfaceContainerLowest: Color(0xFF383838),
        surfaceContainerLow: AppColors.darkBackground,
        surfaceContainer: Color(0xFF424242),
        // الأسطح المرتفعة (البطاقات/النوافذ/القوائم المنبثقة).
        surfaceContainerHigh: AppColors.darkElevated,
        surfaceContainerHighest: AppColors.darkBackground,
        onSurfaceVariant: AppColors.darkInkMuted,
        outline: AppColors.darkBorder,
        outlineVariant: AppColors.darkBorderFaint,
        shadow: Color(0x66000000),
        inverseSurface: AppColors.navy,
        onInverseSurface: AppColors.onNavy,
        inversePrimary: AppColors.gold,
      );

  // ==========================================================================
  //  المنشئ المشترك
  // ==========================================================================

  /// يبني الثيم كاملاً من اللوحة: الأسطح والحدود والحقول والنصوص كلها
  /// مشتقّة من [scheme] فتتكيّف مع السطوع تلقائياً.
  static ThemeData _build({required ColorScheme scheme, required bool isDark}) {
    final TextTheme textTheme = _textTheme(
      ink: scheme.onSurface,
      muted: scheme.onSurfaceVariant,
      label: isDark ? AppColors.gold : AppColors.navy,
    );

    // إبراز الهوية: الذهبي يعمل فوق أي سطح، والكحلي الداكن يبقى للفاتح.
    final Color gold = AppColors.gold;
    // الأساس الإرشادي: فحمي مرتفع ليلاً، كحلي نهاراً.
    final Color elevatedBg = isDark ? AppColors.darkElevated : AppColors.navy;
    // أسطح البطاقات والنوافذ والحقول: مرتفعة ليلاً (‎#454545‎) بيضاء نهاراً.
    final Color cardSurface = isDark ? AppColors.darkElevated : scheme.surface;
    final Color disabledFg =
        isDark ? AppColors.darkInkDisabled : AppColors.inkDisabled;
    final Color hint =
        isDark ? AppColors.darkInkDisabled : AppColors.inkDisabled;

    final ThemeData base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surfaceContainerHighest,
      canvasColor: scheme.surfaceContainerHighest,
      // الخط المحزوم محلياً — لا استدعاء شبكة ولا خط احتياطي شبكي.
      fontFamily: AppAssets.cairoFont,
      // خطوط نظام احتياطية (عربي + CJK) — تمنع ظهور مربعات فارغة (□□□)
      // عند محرف لا يغطّيه خط Cairo. راجع AppAssets.uiFontFallback.
      fontFamilyFallback: AppAssets.uiFontFallback,
      textTheme: textTheme,
      visualDensity: VisualDensity.standard,
      splashFactory: InkSparkle.splashFactory,
    );

    return base.copyWith(
      // (1) الأشرطة العلوية -------------------------------------------------
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: 64,
        titleTextStyle: textTheme.titleMedium?.copyWith(fontSize: 18),
        shape: Border(
          bottom: BorderSide(color: scheme.outline, width: 1),
        ),
      ),

      // (2) الأزرار ---------------------------------------------------------
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: gold,
          foregroundColor: AppColors.navy,
          disabledBackgroundColor: scheme.outline,
          disabledForegroundColor: disabledFg,
          minimumSize: const Size(0, controlHeight),
          padding: const EdgeInsets.symmetric(horizontal: space24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: textTheme.labelLarge?.copyWith(fontSize: 15),
          elevation: 0,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: elevatedBg,
          foregroundColor: AppColors.onNavy,
          minimumSize: const (0, controlHeight),
          padding: const EdgeInsets.symmetric(horizontal: space24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: textTheme.labelLarge?.copyWith(fontSize: 15),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.outline, width: 1.2),
          minimumSize: const Size(0, controlHeight),
          padding: const EdgeInsets.symmetric(horizontal: space24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: textTheme.labelLarge?.copyWith(fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: textTheme.labelLarge?.copyWith(
            fontSize: 14,
            decoration: TextDecoration.underline,
            decorationColor: gold,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: scheme.primary,
          highlightColor: scheme.primaryContainer,
        ),
      ),

      // (3) حقول الإدخال ----------------------------------------------------
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: space16,
          vertical: space16,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: hint),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        floatingLabelStyle: textTheme.bodySmall?.copyWith(
          color: scheme.primary,
        ),
        errorStyle: textTheme.bodySmall?.copyWith(color: scheme.error),
        prefixIconColor: scheme.onSurfaceVariant,
        suffixIconColor: scheme.onSurfaceVariant,
        border: _fieldBorder(scheme.outline),
        enabledBorder: _fieldBorder(scheme.outline),
        focusedBorder: _fieldBorder(gold, width: 1.6),
        errorBorder: _fieldBorder(scheme.error),
        focusedErrorBorder: _fieldBorder(scheme.error, width: 1.6),
        disabledBorder: _fieldBorder(scheme.outline),
      ),

      // (4) الأسطح ----------------------------------------------------------
      cardTheme: CardThemeData(
        color: cardSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: BorderSide(color: scheme.outline),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
        titleTextStyle: textTheme.titleMedium,
        contentTextStyle: textTheme.bodyMedium,
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outline,
        thickness: 1,
        space: 1,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: scheme.inverseSurface,
          borderRadius: BorderRadius.circular(radiusSm),
        ),
        textStyle: textTheme.bodySmall?.copyWith(
          color: scheme.onInverseSurface,
        ),
      ),

      // (5) عناصر مساعدية ----------------------------------------------------
      chipTheme: ChipThemeData(
        backgroundColor: scheme.primaryContainer,
        selectedColor: scheme.secondaryContainer,
        side: BorderSide(color: scheme.outline),
        labelStyle: textTheme.labelSmall,
        shape: const StadiumBorder(),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        // فحمي مرتفع ليلاً، كحلي نهاراً — فلا تظهر كتلة كحلية في المظهر الداكن.
        backgroundColor: isDark ? AppColors.darkElevated : AppColors.navy,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        elevation: 0,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: gold,
        linearTrackColor: scheme.primaryContainer,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: gold,
        selectionColor: scheme.secondaryContainer,
        selectionHandleColor: gold,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.primary,
        titleTextStyle: textTheme.bodyLarge,
        subtitleTextStyle: textTheme.bodySmall,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thickness: WidgetStateProperty.all(6),
        radius: const Radius.circular(radiusPill),
        thumbColor: WidgetStateProperty.all(scheme.outline),
      ),
    );
  }

  // ==========================================================================
  //  أدوات داخلية
  // ==========================================================================

  /// خط الحقول الموحّد (RTL-friendly لأن الانحناء موحّد على الجهات الأربع).
  static OutlineInputBorder _fieldBorder(Color color, {double width = 1.2}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusMd),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  /// سلم النصوص المعتمد — مبني على خط Cairo المحزوم محلياً.
  ///
  /// [ink]: النص الأساسي · [muted]: الثانوي · [label]: التسميات — تتبدّل مع
  /// الثيم فتبقى قراءة في الوضعين.
  static TextTheme _textTheme({
    required Color ink,
    required Color muted,
    required Color label,
  }) {
    final TextTheme theme = TextTheme(
      displaySmall: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 1.35,
        color: ink,
      ),
      headlineMedium: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        height: 1.35,
        color: ink,
      ),
      headlineSmall: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 1.4,
        color: ink,
      ),
      titleLarge: TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w700,
        height: 1.4,
        color: ink,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.45,
        color: ink,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: ink,
      ),
      bodyLarge: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.6,
        color: ink,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.6,
        color: muted,
      ),
      bodySmall: TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w400,
        height: 1.55,
        color: muted,
      ),
      labelLarge: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: label,
      ),
      labelMedium: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        height: 1.2,
        color: label,
      ),
      labelSmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.2,
        color: label,
      ),
    );
    // كل نمط نصي يحمل خطوط النظام الاحتياطية (عربي + CJK)، فلا تظهر مربعات
    // فارغة في أي نص واجهة. راجع `AppAssets.uiFontFallback`.
    return theme.apply(fontFamilyFallback: AppAssets.uiFontFallback);
  }
}
