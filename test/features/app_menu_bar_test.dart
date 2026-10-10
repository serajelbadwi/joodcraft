import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/app/router/app_routes.dart';
import 'package:joodcraft/core/locale/app_locale.dart';
import 'package:joodcraft/core/locale/locale_controller.dart';
import 'package:joodcraft/core/theme/app_theme.dart';
import 'package:joodcraft/core/theme/theme_controller.dart';
import 'package:joodcraft/features/auth/presentation/providers/auth_provider.dart';
import 'package:joodcraft/features/dashboard/presentation/widgets/app_menu_bar.dart';
import 'package:joodcraft/features/project_hub/presentation/providers/new_document_controller.dart';
import 'package:joodcraft/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_auth_repository.dart';

/// اختبارات شريط القوائم العلوي (بطراز سطح المكتب).
///
/// نتحقّق من ثلاثة أشياء معاً: أن القوائم الخمس ظاهرة، وأن «مستند جديد…» صار
/// أمراً في قائمة `ملف` لا تبويباً، وأن كل بند **ينفّذ فعلاً** ما يدّعيه
/// (مظهر، لغة، تنقّل، تفريغ) بدل أن يكون بندَ زينة.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ThemeController theme;
  late LocaleController locale;
  late List<String> navigated;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    theme = ThemeController();
    locale = LocaleController();
    navigated = <String>[];
    NewDocumentController.debugClearRecent();
  });

  tearDown(() {
    theme.dispose();
    locale.dispose();
  });

  Future<void> pumpBar(WidgetTester tester, {AuthProvider? auth}) async {
    await tester.binding.setSurfaceSize(const Size(1200, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(
            value: auth ?? AuthProvider(null),
          ),
          ChangeNotifierProvider<ThemeController>.value(value: theme),
          ChangeNotifierProvider<LocaleController>.value(value: locale),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('ar'),
          supportedLocales: AppLocales.locales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: Column(
              children: <Widget>[
                AppMenuBar(onNavigate: navigated.add),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// يفتح قائمة بعنوانها الظاهر في الشريط.
  Future<void> openMenu(WidgetTester tester, String title) async {
    await tester.tap(find.text(title));
    await tester.pumpAndSettle();
  }

  testWidgets('القوائم الخمس ظاهرة والشريط رقيق', (WidgetTester tester) async {
    await pumpBar(tester);

    for (final String title in <String>[
      'ملف',
      'تعديل',
      'عرض',
      'أدوات',
      'مساعدة',
    ]) {
      expect(find.text(title), findsOneWidget, reason: title);
    }
    expect(AppMenuBar.height, lessThanOrEqualTo(32));
  });

  testWidgets('«ملف» يحمل «مستند جديد…» بـCtrl+N ويفتح النافذة',
      (WidgetTester tester) async {
    await pumpBar(tester);

    await openMenu(tester, 'ملف');
    expect(find.text('مستند جديد…'), findsOneWidget);
    expect(find.text('Ctrl+N'), findsOneWidget);
    // أوامر الملفات الأخرى حقيقية أيضاً.
    expect(find.text('مكتبة القوالب'), findsOneWidget);
    // «تسجيل الخروج» لا يُعرض في الوضع المحلي (لا حساب مربوط)، فلا يُعرض
    // إجراء يفشل حتماً.
    expect(find.text('تسجيل الخروج'), findsNothing);

    await tester.tap(find.text('مستند جديد…'));
    await tester.pumpAndSettle();
    expect(navigated, <String>[AppRoutes.newProject]);
  });

  testWidgets('«ملف» يعرض تسجيل الخروج فقط عند وجود حساب مربوط',
      (WidgetTester tester) async {
    final FakeAuthRepository repository = FakeAuthRepository();
    final AuthProvider auth = AuthProvider(repository);
    await auth.signIn(email: 'user@joodcraft.dev', password: 'secret');
    addTearDown(() {
      auth.dispose();
      repository.close();
    });

    await pumpBar(tester, auth: auth);
    await openMenu(tester, 'ملف');

    expect(find.text('تسجيل الخروج'), findsOneWidget);
  });

  testWidgets('«عرض» يبدّل المظهر فعلاً', (WidgetTester tester) async {
    await pumpBar(tester);

    await openMenu(tester, 'عرض');
    await tester.tap(find.text('داكن'));
    await tester.pumpAndSettle();

    expect(theme.mode, ThemeMode.dark);
  });

  testWidgets('«عرض» يبدّل اللغة فعلاً', (WidgetTester tester) async {
    await pumpBar(tester);

    await openMenu(tester, 'عرض');
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(locale.locale.languageCode, 'en');
  });

  testWidgets('«أدوات» تفتح المحرّكات', (WidgetTester tester) async {
    await pumpBar(tester);

    await openMenu(tester, 'أدوات');
    await tester.tap(find.text('التوليد الجماعي'));
    await tester.pumpAndSettle();

    expect(navigated, <String>[AppRoutes.batchProcessor]);
  });

  testWidgets('«تعديل» تُفرّغ الأبعاد الأخيرة فعلاً', (WidgetTester tester) async {
    NewDocumentController.recentFamilyIds.add('card.business');
    await pumpBar(tester);

    await openMenu(tester, 'تعديل');
    await tester.tap(find.text('تفريغ قائمة الأبعاد الأخيرة'));
    await tester.pumpAndSettle();

    expect(NewDocumentController.recentFamilyIds, isEmpty);
  });

  testWidgets('«مساعدة» تنقل إلى شاشة «حول»', (WidgetTester tester) async {
    await pumpBar(tester);

    await openMenu(tester, 'مساعدة');
    await tester.tap(find.text('حول JoodCraft'));
    await tester.pumpAndSettle();

    // الأمر لم يبقَ نافذة `showAboutDialog` صغيرة، بل ينقل إلى شاشة «حول»
    // الكاملة (`AppRoutes.about`) — نفس نمط بقية أوامر القوائم.
    expect(navigated, <String>[AppRoutes.about]);
  });
}
