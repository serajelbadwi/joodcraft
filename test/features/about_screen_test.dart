import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/app/router/app_routes.dart';
import 'package:joodcraft/core/locale/app_locale.dart';
import 'package:joodcraft/core/theme/app_theme.dart';
import 'package:joodcraft/core/widgets/joodcraft_logo.dart';
import 'package:joodcraft/features/about/presentation/screens/about_screen.dart';
import 'package:joodcraft/l10n/generated/app_localizations.dart';
import 'package:joodcraft/l10n/generated/app_localizations_ar.dart';
import 'package:joodcraft/l10n/generated/app_localizations_en.dart';
import 'package:joodcraft/l10n/generated/app_localizations_zh.dart';

/// اختبارات شاشة **«حول JoodCraft»** — تبنيها وتفحص أقسامها وروابطها:
///
/// * البناء في المظهر الفاتح والداكن وبلا مندوبي ترجمة (نصوص احتياطية).
/// * الأقسام الخمسة: نبذة، مميزات، مطوّر، روابط، شكر — كلها بمفاتيحها.
/// * ترويسة الهوية (أيقونة + اسم + وصف) ورقم الإصدار بصيغة مفتاح الترجمة.
/// * رابط التراخيص يفتح [LicensePage]، ورابط الملاحظات ينسخ بريد المطوّر.
/// * مسار `/about` معرَّف في [AppRoutes] (وقائمة «مساعدة» تفتحه).
void main() {
  Future<void> pumpAbout(WidgetTester tester, {ThemeData? theme}) async {
    await tester.binding.setSurfaceSize(const Size(1024, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? AppTheme.light,
        locale: const Locale('ar'),
        supportedLocales: AppLocales.locales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: const AboutScreen(),
      ),
    );
    await tester.pump();
  }

  AppLocalizations l10nOf(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(AboutScreen)));

  Finder byKey(String name) => find.byKey(ValueKey<String>(name));

  // ==========================================================================
  //  البناء
  // ==========================================================================
  group('البناء', () {
    testWidgets('تُبنى في المظهر الفاتح', (WidgetTester tester) async {
      await pumpAbout(tester);

      expect(find.byType(AboutScreen), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(JoodCraftLogo), findsOneWidget);
      expect(find.text(l10nOf(tester).aboutTitle), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('تُبنى في المظهر الداكن بلا انهيار', (
      WidgetTester tester,
    ) async {
      await pumpAbout(tester, theme: AppTheme.dark);

      expect(find.byType(AboutScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('تظهر بلا مندوبي ترجمة (نصوص احتياطية)', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1024, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(const MaterialApp(home: AboutScreen()));
      await tester.pump();

      // بلا مندوب ⇒ `context.l10n` يُعيد null فتُستخدم النصوص الاحتياطية.
      expect(tester.takeException(), isNull);
      expect(find.text('JoodCraft'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('about-summary')),
        findsOneWidget,
      );
    });
  });

  // ==========================================================================
  //  الأقسام
  // ==========================================================================
  group('الأقسام الخمسة', () {
    testWidgets('كل الأقسام موجودة بمفاتيحها', (WidgetTester tester) async {
      await pumpAbout(tester);

      for (final String key in const <String>[
        'about-summary',
        'about-features',
        'about-developer',
        'about-links',
        'about-credits',
      ]) {
        expect(byKey(key), findsOneWidget, reason: 'القسم $key مفقود');
      }
    });

    testWidgets('عناوين الأقسام تظهر من الترجمة', (WidgetTester tester) async {
      await pumpAbout(tester);
      final AppLocalizations l10n = l10nOf(tester);

      expect(find.text(l10n.aboutSummaryTitle), findsOneWidget);
      expect(find.text(l10n.aboutFeaturesTitle), findsOneWidget);
      expect(find.text(l10n.aboutDeveloperTitle), findsOneWidget);
      expect(find.text(l10n.aboutLinksTitle), findsOneWidget);
      expect(find.text(l10n.aboutCreditsTitle), findsOneWidget);
    });

    testWidgets('الترويسة تعرض الاسم والوصف', (WidgetTester tester) async {
      await pumpAbout(tester);
      final AppLocalizations l10n = l10nOf(tester);

      expect(byKey('about-heading'), findsOneWidget);
      expect(byKey('about-app-name'), findsOneWidget);
      expect(byKey('about-tagline'), findsOneWidget);
      expect(find.text('JoodCraft'), findsOneWidget);
      expect(find.text(l10n.aboutTagline), findsOneWidget);
    });

    testWidgets('المميزات السبع المعروضة كلها ظاهرة', (
      WidgetTester tester,
    ) async {
      await pumpAbout(tester);
      final AppLocalizations l10n = l10nOf(tester);

      expect(
        find.descendant(
          of: byKey('about-features'),
          matching: find.byIcon(Icons.check_circle_rounded),
        ),
        findsNWidgets(7),
      );
      expect(find.text(l10n.aboutFeatureOffline), findsOneWidget);
      expect(find.text(l10n.aboutFeatureArabicFonts), findsOneWidget);
      expect(find.text(l10n.aboutFeatureExcel), findsOneWidget);
      expect(find.text(l10n.aboutFeatureBatch), findsOneWidget);
      expect(find.text(l10n.aboutFeatureVisualEditor), findsOneWidget);
      expect(find.text(l10n.aboutFeatureInvitations), findsOneWidget);
      expect(find.text(l10n.aboutFeatureExports), findsOneWidget);
    });

    testWidgets('بطاقة المطوّر تعرض الاسم والبريد والحالة', (
      WidgetTester tester,
    ) async {
      await pumpAbout(tester);
      final AppLocalizations l10n = l10nOf(tester);

      expect(byKey('about-developer-name'), findsOneWidget);
      expect(byKey('about-developer-email'), findsOneWidget);
      expect(byKey('about-developer-status'), findsOneWidget);
      expect(find.text(l10n.aboutDeveloperName), findsOneWidget);
      expect(
        find.text(l10n.aboutDeveloperEmail),
        findsNWidgets(2),
        reason: 'البريد يظهر في بطاقة المطوّر وفي رابط «إرسال ملاحظات»',
      );
      expect(find.text(l10n.aboutDeveloperStatus), findsOneWidget);
    });
  });

  // ==========================================================================
  //  الإصدار
  // ==========================================================================
  group('الإصدار', () {
    testWidgets('الإصدار يظهر بصيغة المفتاح المترجم', (
      WidgetTester tester,
    ) async {
      await pumpAbout(tester);
      final AppLocalizations l10n = l10nOf(tester);

      expect(byKey('about-version'), findsOneWidget);
      expect(find.text(l10n.aboutVersion('1.0.0')), findsOneWidget);
    });

    test('مفتاح aboutVersion يحمل معامل version في كل اللغات', () {
      // حرس ثابت: المفتاح دالة (بمعامل) لا نصّ ثابت — وإلا اختفى رقم الإصدار.
      for (final AppLocalizations l10n in <AppLocalizations>[
        AppLocalizationsAr('ar'),
        AppLocalizationsEn('en'),
        AppLocalizationsZh('zh'),
      ]) {
        expect(l10n.aboutVersion('9.9.9'), contains('9.9.9'));
      }
    });
  });

  // ==========================================================================
  //  الروابط
  // ==========================================================================
  group('الروابط والتراخيص', () {
    testWidgets('زر التراخيص موجود ويفتح صفحة تراخيص Flutter', (
      WidgetTester tester,
    ) async {
      await pumpAbout(tester);
      final AppLocalizations l10n = l10nOf(tester);

      expect(byKey('about-licenses'), findsOneWidget);
      expect(find.text(l10n.aboutLicenses), findsOneWidget);
      expect(find.byType(LicensePage), findsNothing);

      await tester.tap(byKey('about-licenses'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(LicensePage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('زر إرسال الملاحظات ينسخ البريد ويُظهر تأكيداً', (
      WidgetTester tester,
    ) async {
      await pumpAbout(tester);
      final AppLocalizations l10n = l10nOf(tester);

      expect(byKey('about-feedback'), findsOneWidget);
      expect(find.text(l10n.aboutFeedback), findsOneWidget);
      expect(
        find.text(AboutScreen.developerEmail),
        findsNWidgets(2),
        reason: 'البريد يظهر في بطاقة المطوّر وفي رابط «إرسال ملاحظات»',
      );

      await tester.tap(byKey('about-feedback'));
      await tester.pump();
      // النسخ إلى الحافظة نداء منصّة حقيقي: يُتاح له إتمامه في زمن حقيقي
      // (`runAsync`) قبل أن يُبنى SnackBar التأكيد.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text(l10n.aboutFeedbackCopied), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  // ==========================================================================
  //  الموجّه
  // ==========================================================================
  group('الموجّه', () {
    test('مسار /about معرَّف في AppRoutes', () {
      expect(AppRoutes.about, '/about');
    });
  });
}
