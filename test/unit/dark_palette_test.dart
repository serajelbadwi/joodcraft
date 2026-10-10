import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/theme/app_colors.dart';
import 'package:joodcraft/core/theme/app_theme.dart';

/// اختبارات **اللوحة الفحمية المحايدة** للمظهر الداكن: القيم الدقيقة، تدرّج
/// الإضاءة (خلفية ← سطح ← مرتفع ← حد)، وتباين النصوص، وتطبيقها على أسطح
/// الثيم (الخلفية، البطاقات، النوافذ، الحقول).
void main() {
  group('قيم التوكنات الداكنة (فحمي محايد)', () {
    test('القيم الأساسية مطابقة للمرجع', () {
      expect(AppColors.darkBackground, const Color(0xFF3E3E3E));
      expect(AppColors.darkSurface, const Color(0xFF3E3E3E));
      expect(AppColors.darkElevated, const Color(0xFF454545));
      expect(AppColors.darkCanvas, const Color(0xFF4A4A4A));
      expect(AppColors.darkBorder, const Color(0xFF5A5A5A));
      expect(AppColors.darkInk, const Color(0xFFF5F5F5));
      expect(AppColors.darkInkMuted, const Color(0xFFD1D5DB));
    });

    test('لا درجة شبه سوداء + هيكل موحّد ← مرتفع ← مساحة عمل ← حدود', () {
      // أوّلاً: حُذفت القيم شبه السوداء نهائياً — كل الأسطح رمادية فاتحة.
      for (final Color color in <Color>[
        AppColors.darkBackground,
        AppColors.darkSurface,
        AppColors.darkElevated,
        AppColors.darkBorderFaint,
        AppColors.darkBorder,
      ]) {
        expect(
          color.computeLuminance(),
          greaterThan(0.03),
          reason: 'لا يجب أن تبقى أي درجة شبه سوداء: $color',
        );
      }
      final double bg = AppColors.darkBackground.computeLuminance();
      final double surface = AppColors.darkSurface.computeLuminance();
      final double elevated = AppColors.darkElevated.computeLuminance();
      final double canvas = AppColors.darkCanvas.computeLuminance();
      final double border = AppColors.darkBorder.computeLuminance();
      // الهيكل الخارجي موحّد تماماً (الخلفية = السطح = الأشرطة).
      expect(surface, equals(bg));
      // ثم يتصاعد الضوء: مرتفع ← مساحة عمل، والحدود أفتح قليلاً فتُرى.
      expect(elevated, greaterThan(bg));
      expect(canvas, greaterThan(elevated));
      expect(border, greaterThan(bg));
    });

    test('مساحة عمل اللوحة أفتح من الهيكل (تنفيس التباين حول الورقة)', () {
      // راحة العين: المحيط المباشر للورقة البيضاء أفتح من اللوحات والأشرطة،
      // فلا يكون الورق صادماً في محيط غامق (نمط Photoshop/Figma).
      final double canvas = AppColors.darkCanvas.computeLuminance();
      expect(canvas, greaterThan(AppColors.darkBackground.computeLuminance()));
      expect(canvas, greaterThan(AppColors.darkSurface.computeLuminance()));
      expect(canvas, greaterThan(AppColors.darkElevated.computeLuminance()));
      // وفرق واضح لا مجرد خطوة طفيفة، فتبقى الورقة "طافية" على محيط مميّز.
      expect(
        canvas - AppColors.darkSurface.computeLuminance(),
        greaterThan(0.02),
      );
    });

    test('تباين النص كافٍ (النص الأساسي أفتح بكثير من الخلفية)', () {
      final double ink = AppColors.darkInk.computeLuminance();
      final double muted = AppColors.darkInkMuted.computeLuminance();
      final double bg = AppColors.darkBackground.computeLuminance();
      final double surface = AppColors.darkSurface.computeLuminance();
      // النص الأساسي فاتح جداً والثانوي فاتح بوضوح على الخلفية والسطح.
      expect(ink, greaterThan(0.8));
      expect(muted, greaterThan(0.3));
      expect(ink - bg, greaterThan(0.7));
      expect(muted - surface, greaterThan(0.2));
    });
  });

  group('تباين نص لوحة الخصائص على الطنّ السليت', () {
    /// نسبة تباين WCAG بين لونين (1 = بلا تباين، 21 = أبيض/أسود).
    double contrast(Color a, Color b) {
      final double la = a.computeLuminance();
      final double lb = b.computeLuminance();
      final double hi = math.max(la, lb);
      final double lo = math.min(la, lb);
      return (hi + 0.05) / (lo + 0.05);
    }

    test('النص الأساسي والثانوي مقروءان على اللوحة والحقول (WCAG AA)', () {
      // بعد رفع أسطح اللوحة إلى الطنّ السليت الأفتح، يجب أن يبقى نص الشريط
      // الجانبي (العناصر والتسميات والأوصاف) عالي التباين لا باهتاً.
      final ColorScheme scheme = AppTheme.dark.colorScheme;
      for (final Color bg in <Color>[
        scheme.surface,
        AppColors.darkElevated
      ]) {
        expect(
          contrast(scheme.onSurface, bg),
          greaterThanOrEqualTo(4.5),
          reason: 'النص الأساسي باهت على $bg',
        );
        expect(
          contrast(scheme.onSurfaceVariant, bg),
          greaterThanOrEqualTo(4.5),
          reason: 'النص الثانوي/التسميات باهت على $bg',
        );
      }
    });

    test('التلميحات وحدود الحقول مقروءة على السطح الأفتح', () {
      final ColorScheme scheme = AppTheme.dark.colorScheme;
      // التلميحات والنص المعطّل داخل الحقول يبقى مقروءاً (لا يختفي).
      expect(
        contrast(AppColors.darkInkDisabled, AppColors.darkElevated),
        greaterThanOrEqualTo(4.5),
      );
      // وحدّ الحقول/الفواصل يظهر بوضوح فوق اللوحة.
      expect(contrast(scheme.outline, scheme.surface), greaterThan(1.5));
    });
  });

  group('تطبيق اللوحة على ثيم المظهر الداكن', () {
    final ThemeData dark = AppTheme.dark;

    test('اللوحة الداكنة تستخدم التوكنات الفحمية', () {
      final ColorScheme scheme = dark.colorScheme;
      expect(scheme.brightness, Brightness.dark);
      expect(scheme.surface, AppColors.darkSurface);
      expect(scheme.surfaceContainerHighest, AppColors.darkBackground);
      expect(scheme.surfaceContainerHigh, AppColors.darkElevated);
      expect(scheme.onSurface, AppColors.darkInk);
      expect(scheme.onSurfaceVariant, AppColors.darkInkMuted);
      expect(scheme.outline, AppColors.darkBorder);
    });

    test('مساحة عمل اللوحة مكيّفة السطوع في الوضعين', () {
      expect(
        AppTheme.dark.colorScheme.canvasViewport,
        AppColors.darkCanvas,
      );
      // نهاراً: غسيل كحلي باهت لا أبيض صريح، فيبقى مميزاً عن اللوحات.
      final Color lightCanvas = AppTheme.light.colorScheme.canvasViewport;
      expect(lightCanvas, isNot(AppColors.surface));
      expect(lightCanvas.computeLuminance(), greaterThan(0.8));
    });

    test('الخلفية العامة والبطاقات والنوافذ والحقول على الأسطح الصحيحة', () {
      expect(dark.scaffoldBackgroundColor, AppColors.darkBackground);
      expect(dark.cardTheme.color, AppColors.darkElevated);
      expect(dark.dialogTheme.backgroundColor, AppColors.darkElevated);
      expect(
        dark.inputDecorationTheme.fillColor,
        AppColors.darkElevated,
      );
    });
  });

  group('أسطح الهوية المتكيّفة: لا كحلي إطلاقاً في المظهر الداكن', () {
    test('نهاراً: كحلي الهوية الأصلي', () {
      final ColorScheme scheme = AppTheme.light.colorScheme;
      expect(scheme.brandSurface, AppColors.navy);
      expect(scheme.brandSurfaceDeep, AppColors.navyDeep);
      expect(scheme.brandSurfaceSoft, AppColors.navySoft);
      expect(scheme.onBrandSurface, AppColors.onNavy);
    });

    test('ليلاً: أسطح فحمية محايدة بدل الكحلي', () {
      final ColorScheme scheme = AppTheme.dark.colorScheme;
      expect(scheme.brandSurface, AppColors.darkSurface);
      expect(scheme.brandSurfaceDeep, AppColors.darkBackground);
      expect(scheme.brandSurfaceSoft, AppColors.darkElevated);
      expect(scheme.onBrandSurface, AppColors.onNavy);
      // لا أثر لكحلي الهوية في أي سطح داكن.
      expect(scheme.brandSurface, isNot(AppColors.navy));
      expect(scheme.brandSurfaceDeep, isNot(AppColors.navyDeep));
      expect(scheme.brandSurfaceSoft, isNot(AppColors.navySoft));
    });

    test('الذهبي يبقى لون الإبراز الوحيد الدافئ في الوضعين', () {
      // الذهبي في النهار `secondary` وفي الليل `primary` — دافئ في الحالتين.
      expect(AppTheme.light.colorScheme.secondary, AppColors.gold);
      expect(AppTheme.dark.colorScheme.primary, AppColors.gold);
    });
  });

  group('لا تراجع في المظهر الفاتح', () {
    final ThemeData light = AppTheme.light;

    test('اللوحة الفاتحة تبقى بيضاء/كحلية', () {
      expect(light.colorScheme.brightness, Brightness.light);
      expect(light.colorScheme.surface, AppColors.surface);
      expect(light.scaffoldBackgroundColor, AppColors.background);
      expect(light.cardTheme.color, AppColors.surface);
      expect(light.colorScheme.onSurface, AppColors.ink);
    });
  });
}
