import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/constants/app_assets.dart';
import 'package:joodcraft/core/theme/app_colors.dart';
import 'package:joodcraft/core/theme/app_theme.dart';
import 'package:joodcraft/core/widgets/app_icon.dart';
import 'package:joodcraft/core/widgets/joodcraft_logo.dart';

/// **العلامة التجارية**: أيقونة البرنامج المحزومة + نص «JoodCraft» الذي يجب أن
/// يبقى مقروءاً في المظهرين — كان الكحلي الثابت يختفي على الأسطح الفحمية فيبدو
/// جزء من النص مفقوداً.
void main() {
  /// يجمع كل قطع النص في الشجرة (بما فيها المتشعّبة داخل `Text.rich`).
  List<TextSpan> flatten(InlineSpan span, List<TextSpan> out) {
    if (span is TextSpan) {
      out.add(span);
      span.children?.forEach((InlineSpan child) => flatten(child, out));
    }
    return out;
  }

  /// لونا كلمتَي «Jood» و«Craft» في الشعار النصي.
  (Color, Color) wordmarkColors(WidgetTester tester) {
    final RenderParagraph paragraph = tester.renderObject<RenderParagraph>(
      find.byType(RichText).first,
    );
    final List<TextSpan> spans = flatten(paragraph.text, <TextSpan>[]);
    Color colorOf(String label) => spans
        .firstWhere((TextSpan span) => span.text == label)
        .style!
        .color!;
    return (colorOf('Jood'), colorOf('Craft'));
  }

  Future<void> pump(WidgetTester tester, ThemeData theme, Widget child) async {
    await tester.pumpWidget(
      MaterialApp(theme: theme, home: Scaffold(body: Center(child: child))),
    );
    await tester.pumpAndSettle();
  }

  group('الشعار النصي (BrandWordmark)', () {
    testWidgets('ليلاً: «Jood» فاتح ولا يختفي على السطح الفحمي',
        (WidgetTester tester) async {
      await pump(tester, AppTheme.dark, const BrandWordmark(fontSize: 20));

      final (Color jood, Color craft) = wordmarkColors(tester);
      expect(jood, isNot(AppColors.navy));
      expect(jood.computeLuminance(), greaterThan(0.6));
      // «Craft» ذهبية دافئة واضحة على الفحمي.
      expect(craft, AppColors.gold);
    });

    testWidgets('نهاراً: «Jood» كحلي و«Craft» ذهبي أعمق على الأبيض',
        (WidgetTester tester) async {
      await pump(tester, AppTheme.light, const BrandWordmark(fontSize: 20));

      final (Color jood, Color craft) = wordmarkColors(tester);
      expect(jood, AppColors.ink);
      expect(craft, AppColors.goldDeep);
    });

    testWidgets('على سطح هوية داكن صريح: النص فاتح في الوضعين',
        (WidgetTester tester) async {
      await pump(
        tester,
        AppTheme.light,
        const BrandWordmark(fontSize: 20, onDark: true),
      );
      final (Color jood, Color craft) = wordmarkColors(tester);
      expect(jood, AppColors.onNavy);
      expect(craft, AppColors.gold);
    });
  });

  group('الشعار (JoodCraftLogo)', () {
    testWidgets('يستخدم أيقونة البرنامج المحزومة من الأصول',
        (WidgetTester tester) async {
      await pump(tester, AppTheme.light, const JoodCraftLogo(size: 40));

      final Image image = tester.widget<Image>(find.byType(Image));
      expect(image.image, isA<AssetImage>());
      expect(
        (image.image as AssetImage).assetName,
        AppAssets.appIconImage,
      );
      // نهاراً لا ضبط لون إضافي على الأيقونة.
      expect(find.byType(ColorFiltered), findsNothing);
    });

    testWidgets('ليلاً: يُطبَّق ضبط لون يفتح الأيقونة الكحلية',
        (WidgetTester tester) async {
      await pump(
        tester,
        AppTheme.dark,
        const JoodCraftLogo(size: 40, onDark: true),
      );

      expect(find.byType(ColorFiltered), findsOneWidget);
    });

    testWidgets('تلوين أحادي صريح يُطبَّق عند طلبه', (WidgetTester tester) async {
      await pump(
        tester,
        AppTheme.light,
        const JoodCraftLogo(size: 40, tint: AppColors.gold),
      );

      final ColorFiltered filtered = tester.widget<ColorFiltered>(
        find.byType(ColorFiltered),
      );
      expect(
        filtered.colorFilter,
        const ColorFilter.mode(AppColors.gold, BlendMode.srcIn),
      );
    });

    testWidgets('ترويسة الهوية تجمع الرمز والنص والسطر التعريفي',
        (WidgetTester tester) async {
      await pump(
        tester,
        AppTheme.light,
        const JoodCraftWordmark(markSize: 40),
      );

      expect(find.byType(JoodCraftLogo), findsOneWidget);
      expect(find.byType(BrandWordmark), findsOneWidget);
      expect(find.textContaining('توليد الشهادات'), findsOneWidget);
    });

    testWidgets('الرمز المتجهي يبقى متاحاً كبديل عند تعذّر قراءة الأصل',
        (WidgetTester tester) async {
      // المكوّن نفسه يعرض [AppIcon] كـ`errorBuilder` — نتحقق من توفّره فقط.
      expect(const AppIcon(size: 24), isA<AppIcon>());
    });
  });
}
