import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/constants/app_assets.dart';
import 'package:joodcraft/core/editor/widgets/element_view.dart';
import 'package:joodcraft/core/models/template_element.dart';
import 'package:joodcraft/core/theme/app_theme.dart';

/// اختبار حرس يقفز `[AppAssets.uiFontFallback]` ثابتةً.
///
/// السبب العملي: بدون هذه الخطوط الاحتياطية يظهر النص العربي/الصيني مربعاً
/// فارغاً (□□□) على منصات لا يغطّيها خط Cairo. أي حذف أو إعادة ترتيب هنا
/// يُعيد المشكلة بصمت، فالسطر الأخير من الدفاع هو هذا الاختبار.
void main() {
  /// كل أساليب `TextTheme` — لأن الطلب هو تطبيق الاحتياطي على **كل** نصوص الثيم.
  List<TextStyle> textStyles(ThemeData theme) => <TextStyle?>[
        theme.textTheme.displayLarge,
        theme.textTheme.displayMedium,
        theme.textTheme.displaySmall,
        theme.textTheme.headlineLarge,
        theme.textTheme.headlineMedium,
        theme.textTheme.headlineSmall,
        theme.textTheme.titleLarge,
        theme.textTheme.titleMedium,
        theme.textTheme.titleSmall,
        theme.textTheme.bodyLarge,
        theme.textTheme.bodyMedium,
        theme.textTheme.bodySmall,
        theme.textTheme.labelLarge,
        theme.textTheme.labelMedium,
        theme.textTheme.labelSmall,
      ].whereType<TextStyle>().toList();

  group('قائمة uiFontFallback نفسها', () {
    test('تحتوي خطوط نظام تغطي العربية', () {
      // Tahoma وArial يحملان محارف العربية على ويندوز وماك — هذا هو دفاع
      // اللغة الأساسية من المربعات الفارغة.
      expect(AppAssets.uiFontFallback, contains('Tahoma'));
      expect(AppAssets.uiFontFallback, contains('Arial'));
    });

    test('تحتوي خطوط نظام تغطي CJK', () {
      // ويندوز / ماك / لينكس — لأن فلاتر لا تحزم خطاً صينياً.
      for (final String font in <String>[
        'Microsoft YaHei',
        'PingFang SC',
        'Noto Sans CJK SC',
        'SimSun',
      ]) {
        expect(AppAssets.uiFontFallback, contains(font), reason: font);
      }
    });

    test('العربي يأتي قبل خطوط CJK فلا يضيع محرف عربي في خط صيني', () {
      final List<String> fonts = AppAssets.uiFontFallback;
      expect(fonts.indexOf('Tahoma'), lessThan(fonts.indexOf('Microsoft YaHei')));
      expect(fonts.indexOf('Arial'), lessThan(fonts.indexOf('PingFang SC')));
    });

    test('ينتهي بخط عام أخير (sans-serif)', () {
      // آخر حلقة إن لم يجد النظام أي خط مذكور أعلاه.
      expect(AppAssets.uiFontFallback.last, 'sans-serif');
    });

    test('بلا تكرار حتى لا يتكرّر البحث عن نفس الخط', () {
      final List<String> fonts = AppAssets.uiFontFallback;
      expect(fonts.toSet().length, fonts.length);
    });

    test('القائمة غير فارغة وكل عنصر اسم خط صالح', () {
      expect(AppAssets.uiFontFallback, isNotEmpty);
      for (final String font in AppAssets.uiFontFallback) {
        expect(font, isNotEmpty, reason: 'عنصر فارغ في القائمة');
        expect(font.trim(), font, reason: 'اسم خط بمسافات زائدة: "$font"');
      }
    });
  });

  group('تطبيقها على الثيم', () {
    test('خط الواجهة هو Cairo', () {
      // ThemeData لا تحفظ fontFamily حقلًا — تدمجه في نصوصها.
      for (final ThemeData theme in <ThemeData>[
        AppTheme.light,
        AppTheme.dark,
      ]) {
        expect(theme.textTheme.bodyMedium?.fontFamily, AppAssets.cairoFont);
      }
    });

    test('الفاتح والداكن يحملان الاحتياطي نفسه', () {
      for (final ThemeData theme in <ThemeData>[
        AppTheme.light,
        AppTheme.dark,
      ]) {
        expect(theme.textTheme.bodyMedium?.fontFamilyFallback,
            AppAssets.uiFontFallback);
      }
    });

    test('كل أساليب النصوص تحمل الاحتياطي لا بعضها فقط', () {
      for (final ThemeData theme in <ThemeData>[
        AppTheme.light,
        AppTheme.dark,
      ]) {
        final List<TextStyle> styles = textStyles(theme);
        expect(styles, isNotEmpty);
        for (final TextStyle style in styles) {
          expect(style.fontFamilyFallback, AppAssets.uiFontFallback,
              reason: 'نمط نصي بلا خطوط احتياطية: $style');
        }
      }
    });
  });

  group('تطبيقها على معاينة القالب', () {
    test('editorTextStyle يحمل الاحتياطي', () {
      const TextElement element = TextElement(
        id: 't1',
        box: ElementBox(x: 0, y: 0, width: 100, height: 40),
        text: 'شهادة تكريمية',
      );
      final TextStyle style = editorTextStyle(element, 1.0);
      expect(style.fontFamilyFallback, AppAssets.uiFontFallback);
    });
  });
}
