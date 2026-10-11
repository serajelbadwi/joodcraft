/// هوية صفحة القرية البصرية: لوحة داكنة فاخرة (رمادي + تركواز + ذهبي).
///
/// اللوحة مستقلة تماماً عن هوية JoodCraft (كحلي/ذهبي فاتح) لأن هذه صفحة عامة
/// لمبادرة قرية، ومع ذلك تبقى الخطوط هي الخطوط المحزومة نفسها (Cairo للنصوص و
/// Amiri للعناوين) فلا يُجلب أي خط من الشبكة.
library;

import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';

/// ألوان الصفحة — القيم الأربع الأولى هي المطلوبة في التصميم ولا تُغيَّر إلا
/// بقرار تصميمي، وباقيها مشتقّات منها لتغطية الحالات (خطأ/نجاح/حدود).
abstract final class VillageColors {
  const VillageColors._();

  // ---------------------------- اللوحة المعتمدة ----------------------------
  /// خلفية الصفحة — رمادي داكن.
  static const Color background = Color(0xFF3D3D3D);

  /// لون الإبراز — تركواز.
  static const Color teal = Color(0xFF0E6B6B);

  /// العناصر الثانوية — رمادي.
  static const Color secondary = Color(0xFF5C5C5C);

  /// اللمسات الفاخرة — ذهبي.
  static const Color gold = Color(0xFFB8932E);

  /// النص الأساسي.
  static const Color white = Color(0xFFFFFFFF);

  // ------------------------------- المشتقّات -------------------------------
  /// سطح البطاقات — درجة أفتح من الخلفية لتفصل الكتل عن بعضها.
  static const Color surface = Color(0xFF474747);

  /// سطح مرتفع (حقول/أزرار ثانوية).
  static const Color surfaceHigh = Color(0xFF535353);

  /// حدود وفواصل.
  static const Color border = Color(0xFF6B6B6B);

  /// نص ثانوي/تلميحات — رمادي فاتح بتباين كافٍ على الداكن.
  static const Color muted = Color(0xFFB6B6B6);

  /// نص فرعي أفتح من [muted].
  static const Color inkSoft = Color(0xFFDCDCDC);

  /// تركواز فاتح للمرور (hover) والحالات النشطة.
  static const Color tealSoft = Color(0xFF1A8C8C);

  /// ذهبي فاتح للمرور وللخطوط الزخرفية.
  static const Color goldSoft = Color(0xFFD9B85C);

  /// حبر داكن يُكتب به فوق الذهبي (تباين عالٍ).
  static const Color onGold = Color(0xFF2A2208);

  /// خطأ — أحمر فاتح يُقرأ على الخلفية الداكنة.
  static const Color danger = Color(0xFFFF8A80);

  /// نجاح — أخضر فاتح يُقرأ على الخلفية الداكنة.
  static const Color success = Color(0xFF58D68D);
}

/// مقاسات ومسافات الصفحة.
abstract final class VillageMetrics {
  const VillageMetrics._();

  static const double space4 = 4;
  static const double space8 = 8;
  static const double space12 = 12;
  static const double space16 = 16;
  static const double space20 = 20;
  static const double space24 = 24;
  static const double space32 = 32;
  static const double space48 = 48;

  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 18;

  /// أقصى عرض للمحتوى — يمنع تمدّد الأسطر على الشاشات العريضة.
  static const double maxContentWidth = 980;

  /// أقصى عرض للنموذج (أضيق من المحتوى العام لراحة القراءة).
  static const double maxFormWidth = 620;

  /// ارتفاع إطار الخريطة.
  static const double mapHeight = 340;
}

/// مظهر الصفحة الداكن — يُبنى من الصفر (لا يرث مظهر JoodCraft).
abstract final class VillageTheme {
  const VillageTheme._();

  /// المظهر الوحيد للصفحة.
  static ThemeData get dark {
    const ColorScheme scheme = ColorScheme.dark(
      primary: VillageColors.teal,
      onPrimary: VillageColors.white,
      primaryContainer: VillageColors.teal,
      onPrimaryContainer: VillageColors.white,
      secondary: VillageColors.gold,
      onSecondary: VillageColors.onGold,
      secondaryContainer: VillageColors.secondary,
      onSecondaryContainer: VillageColors.white,
      surface: VillageColors.background,
      onSurface: VillageColors.white,
      surfaceContainerHighest: VillageColors.surface,
      onSurfaceVariant: VillageColors.inkSoft,
      error: VillageColors.danger,
      onError: Color(0xFF3A0A06),
      outline: VillageColors.border,
      outlineVariant: VillageColors.secondary,
      shadow: Color(0xFF000000),
      inverseSurface: VillageColors.white,
      onInverseSurface: VillageColors.background,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: VillageColors.background,
      canvasColor: VillageColors.background,
      // الخطوط المحزومة نفسها المستخدمة في المنصة — لا شبكة إطلاقاً.
      fontFamily: AppAssets.cairoFont,
      fontFamilyFallback: AppAssets.uiFontFallback,
      visualDensity: VisualDensity.standard,
      textTheme: _textTheme,
      primaryTextTheme: _textTheme,
      iconTheme: const IconThemeData(color: VillageColors.inkSoft),
      dividerTheme: const DividerThemeData(
        color: VillageColors.border,
        thickness: 1,
        space: VillageMetrics.space24,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: VillageColors.gold,
        linearTrackColor: VillageColors.secondary,
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: VillageColors.surfaceHigh,
        contentTextStyle: TextStyle(
          fontFamily: AppAssets.cairoFont,
          color: VillageColors.white,
          fontSize: 15,
        ),
        behavior: SnackBarBehavior.floating,
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: VillageColors.surfaceHigh,
        isDense: false,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: VillageMetrics.space16,
          vertical: VillageMetrics.space16,
        ),
        labelStyle: const TextStyle(color: VillageColors.muted, fontSize: 15),
        floatingLabelStyle:
            const TextStyle(color: VillageColors.goldSoft, fontSize: 15),
        hintStyle: const TextStyle(color: VillageColors.muted, fontSize: 15),
        errorStyle: const TextStyle(
          color: VillageColors.danger,
          fontSize: 13.5,
          height: 1.5,
        ),
        helperStyle: const TextStyle(
          color: VillageColors.muted,
          fontSize: 13,
          height: 1.5,
        ),
        prefixIconColor: VillageColors.muted,
        suffixIconColor: VillageColors.muted,
        border: _fieldBorder(VillageColors.border),
        enabledBorder: _fieldBorder(VillageColors.border),
        focusedBorder: _fieldBorder(VillageColors.tealSoft, width: 1.8),
        errorBorder: _fieldBorder(VillageColors.danger),
        focusedErrorBorder: _fieldBorder(VillageColors.danger, width: 1.8),
        disabledBorder: _fieldBorder(VillageColors.secondary),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith<Color>(
            (Set<WidgetState> states) {
              if (states.contains(WidgetState.disabled)) {
                return VillageColors.gold.withValues(alpha: 0.38);
              }
              if (states.contains(WidgetState.hovered) ||
                  states.contains(WidgetState.pressed)) {
                return VillageColors.goldSoft;
              }
              return VillageColors.gold;
            },
          ),
          foregroundColor: const WidgetStatePropertyAll<Color>(
            VillageColors.onGold,
          ),
          overlayColor: WidgetStatePropertyAll<Color>(
            VillageColors.white.withValues(alpha: 0.08),
          ),
          minimumSize: const WidgetStatePropertyAll<Size>(
            Size(140, 54),
          ),
          padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
            EdgeInsets.symmetric(
              horizontal: VillageMetrics.space24,
              vertical: VillageMetrics.space12,
            ),
          ),
          shape: WidgetStatePropertyAll<OutlinedBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(VillageMetrics.radiusMd),
            ),
          ),
          textStyle: const WidgetStatePropertyAll<TextStyle>(
            TextStyle(
              fontFamily: AppAssets.cairoFont,
              fontSize: 16.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
          elevation: const WidgetStatePropertyAll<double>(0),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: const WidgetStatePropertyAll<Color>(
            VillageColors.goldSoft,
          ),
          textStyle: const WidgetStatePropertyAll<TextStyle>(
            TextStyle(
              fontFamily: AppAssets.cairoFont,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: const WidgetStatePropertyAll<Color>(
            VillageColors.white,
          ),
          side: const WidgetStatePropertyAll<BorderSide>(
            BorderSide(color: VillageColors.border, width: 1.2),
          ),
          shape: WidgetStatePropertyAll<OutlinedBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(VillageMetrics.radiusMd),
            ),
          ),
          padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
            EdgeInsets.symmetric(
              horizontal: VillageMetrics.space20,
              vertical: VillageMetrics.space12,
            ),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: VillageColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VillageMetrics.radiusLg),
          side: const BorderSide(color: VillageColors.border, width: 0.8),
        ),
      ),
    );
  }

  /// حدود الحقول المشتركة.
  static OutlineInputBorder _fieldBorder(Color color, {double width = 1.2}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(VillageMetrics.radiusMd),
        borderSide: BorderSide(color: color, width: width),
      );

  /// سلم النصوص: عناوين بخط **Amiri** الذهبي، ونصوص بخط **Cairo** الأبيض.
  static const TextTheme _textTheme = TextTheme(
    displayLarge: TextStyle(
      fontFamily: AppAssets.amiriFont,
      fontSize: 44,
      fontWeight: FontWeight.w700,
      color: VillageColors.gold,
      height: 1.45,
    ),
    displayMedium: TextStyle(
      fontFamily: AppAssets.amiriFont,
      fontSize: 36,
      fontWeight: FontWeight.w700,
      color: VillageColors.gold,
      height: 1.45,
    ),
    displaySmall: TextStyle(
      fontFamily: AppAssets.amiriFont,
      fontSize: 26,
      fontWeight: FontWeight.w700,
      color: VillageColors.gold,
      height: 1.5,
    ),
    headlineMedium: TextStyle(
      fontFamily: AppAssets.amiriFont,
      fontSize: 23,
      fontWeight: FontWeight.w700,
      color: VillageColors.goldSoft,
      height: 1.5,
    ),
    headlineSmall: TextStyle(
      fontFamily: AppAssets.amiriFont,
      fontSize: 21,
      fontWeight: FontWeight.w700,
      color: VillageColors.goldSoft,
      height: 1.5,
    ),
    titleLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: VillageColors.white,
      height: 1.5,
    ),
    titleMedium: TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w700,
      color: VillageColors.white,
      height: 1.5,
    ),
    bodyLarge: TextStyle(
      fontSize: 16.5,
      color: VillageColors.inkSoft,
      height: 1.85,
    ),
    bodyMedium: TextStyle(
      fontSize: 15,
      color: VillageColors.muted,
      height: 1.8,
    ),
    bodySmall: TextStyle(
      fontSize: 13.5,
      color: VillageColors.muted,
      height: 1.7,
    ),
    labelLarge: TextStyle(
      fontSize: 15.5,
      fontWeight: FontWeight.w600,
      color: VillageColors.white,
      height: 1.5,
    ),
  );
}
