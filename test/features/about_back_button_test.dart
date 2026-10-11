import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:joodcraft/app/router/app_router.dart';
import 'package:joodcraft/app/router/app_routes.dart';
import 'package:joodcraft/core/assets/asset_store.dart';
import 'package:joodcraft/core/assets/assets_controller.dart';
import 'package:joodcraft/core/locale/app_locale.dart';
import 'package:joodcraft/core/locale/locale_controller.dart';
import 'package:joodcraft/core/projects/local_projects_database.dart';
import 'package:joodcraft/core/projects/projects_controller.dart';
import 'package:joodcraft/core/theme/app_theme.dart';
import 'package:joodcraft/core/theme/theme_controller.dart';
import 'package:joodcraft/core/widgets/joodcraft_logo.dart';
import 'package:joodcraft/features/about/presentation/screens/about_screen.dart';
import 'package:joodcraft/features/auth/presentation/providers/auth_provider.dart';
import 'package:joodcraft/features/dashboard/presentation/dashboard_destinations.dart';
import 'package:joodcraft/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_auth_repository.dart';

/// اختبارات الخروج من شاشة «حول JoodCraft» وظهور شعارها الحقيقي.
///
/// الجوهر: `/about` مسار **خارج** `StatefulShellRoute`، فإذا فُتح بـ`context.go`
/// استبدل مسار المستخدم وفقد `Navigator` سياق الرجوع ⇒ تختفي جهة الرجوع من
/// `AppBar` فلا يستطيع المستخدم الخروج. فتحه بـ`context.push` يُبقي مساره
/// تحتها فيظهر الزر تلقائياً ويعود لما كان عليه.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeAuthRepository repository;
  late AuthProvider auth;
  late ThemeController themeController;
  late LocaleController localeController;
  late GoRouter router;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    AssetsController.instance = AssetsController(store: InMemoryAssetStore());
    ProjectsController.instance = ProjectsController(
      database: InMemoryProjectsDatabase(),
    );
    repository = FakeAuthRepository();
    auth = AuthProvider(repository);
    await auth.signIn(email: 'user@joodcraft.dev', password: 'secret');
    themeController = ThemeController();
    localeController = LocaleController();
    router = AppRouter.create(auth);
  });

  tearDown(() {
    router.dispose();
    auth.dispose();
    themeController.dispose();
    localeController.dispose();
    repository.close();
    ProjectsController.instance.dispose();
    ProjectsController.instance = ProjectsController();
  });

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1600, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ThemeController>.value(value: themeController),
          ChangeNotifierProvider<LocaleController>.value(
            value: localeController,
          ),
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light,
          locale: const Locale('ar'),
          supportedLocales: AppLocales.locales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// سياق **داخل** شجرة المُوجِّه: لا يمكن استعمال سياق `MaterialApp` نفسه
  /// لأنه فوق `GoRouter` فلا يجده [GoRouter.of]. أي ديدجت مُوجَّه كافٍ.
  BuildContext routedContext(WidgetTester tester) =>
      tester.element(find.byType(Scaffold).first);

  testWidgets('زر الرجوع يظهر في شاشة «حول» ويعود للشاشة السابقة', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);

    // التنقّل عبر الدالة نفسها التي تستدعيها قائمة «مساعدة» في الشريط العلوي.
    navigateToDestination(routedContext(tester), AppRoutes.about);
    await tester.pumpAndSettle();

    expect(find.byType(AboutScreen), findsOneWidget);
    expect(
      find.byType(BackButton),
      findsOneWidget,
      reason: '/about يُفتح بـpush فيبقى مسار المستخدم تحته فيظهر الزر.',
    );

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.byType(AboutScreen), findsNothing);
  });

  testWidgets('الشعار الحقيقي (أيقونة البرنامج المحزومة) يظهر في رأس الشاشة', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);

    navigateToDestination(routedContext(tester), AppRoutes.about);
    await tester.pumpAndSettle();

    expect(find.byType(JoodCraftLogo), findsOneWidget);
  });
}
