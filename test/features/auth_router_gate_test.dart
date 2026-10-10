import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:joodcraft/app/router/app_router.dart';
import 'package:joodcraft/core/assets/asset_store.dart';
import 'package:joodcraft/core/assets/assets_controller.dart';
import 'package:joodcraft/core/locale/app_locale.dart';
import 'package:joodcraft/core/locale/locale_controller.dart';
import 'package:joodcraft/core/projects/local_projects_database.dart';
import 'package:joodcraft/core/projects/projects_controller.dart';
import 'package:joodcraft/core/theme/app_theme.dart';
import 'package:joodcraft/core/theme/theme_controller.dart';
import 'package:joodcraft/features/auth/presentation/providers/auth_provider.dart';
import 'package:joodcraft/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:joodcraft/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_auth_repository.dart';

/// **بوابة تسجيل الدخول الإلزامية**: بلا مستخدم مُتحقَّق منه لا تُفتح أي شاشة
/// غير شاشتي الدخول/الإنشاء — وبعد نجاح الدخول يُفتح المسار المطلوب.
///
/// وغياب مستودع المصادقة (`AuthProvider(null)`) يعني أن لا وسيلة لدخول، فلا
/// بوابة — وهو ما يجعل التطبيق يعمل في الاختبارات بلا حبس المستخدم.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeAuthRepository repository;
  late AuthProvider auth;
  late GoRouter router;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    AssetsController.instance = AssetsController(store: InMemoryAssetStore());
    ProjectsController.instance = ProjectsController(
      database: InMemoryProjectsDatabase(),
    );
    repository = FakeAuthRepository();
    auth = AuthProvider(repository);
    router = AppRouter.create(auth);
  });

  tearDown(() {
    router.dispose();
    auth.dispose();
    repository.close();
    ProjectsController.instance.dispose();
    ProjectsController.instance = ProjectsController();
  });

  /// يبني التطبيق الفعلي بموجّه حقيقي (لا شاشة واحدة معزولة).
  Future<void> pumpRouter(
    WidgetTester tester, {
    required GoRouter target,
    required AuthProvider provider,
  }) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final ThemeController theme = ThemeController();
    final LocaleController locale = LocaleController();
    addTearDown(() {
      theme.dispose();
      locale.dispose();
    });

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ThemeController>.value(value: theme),
          ChangeNotifierProvider<LocaleController>.value(value: locale),
          ChangeNotifierProvider<AuthProvider>.value(value: provider),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light,
          locale: const Locale('ar'),
          supportedLocales: AppLocales.locales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          routerConfig: target,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pumpApp(WidgetTester tester) =>
      pumpRouter(tester, target: router, provider: auth);

  testWidgets('غير المسجّل يُعاد توجيهه إلى شاشة الدخول ولا يرى اللوحة',
      (WidgetTester tester) async {
    await pumpApp(tester);

    expect(find.text('دخول إلى اللوحة'), findsOneWidget);
    expect(find.byType(DashboardScreen), findsNothing);
    expect(router.state.matchedLocation, '/login');
  });

  testWidgets('بعد نجاح الدخول تُفتح لوحة التحكم ويُزاح الدخول',
      (WidgetTester tester) async {
    await auth.signIn(email: 'user@joodcraft.dev', password: 'secret');

    await pumpApp(tester);

    expect(find.text('دخول إلى اللوحة'), findsNothing);
    expect(find.byType(DashboardScreen), findsOneWidget);
  });

  testWidgets('تسجيل الخروج يُعيد المستخدم إلى شاشة الدخول',
      (WidgetTester tester) async {
    await auth.signIn(email: 'user@joodcraft.dev', password: 'secret');
    await pumpApp(tester);
    expect(find.byType(DashboardScreen), findsOneWidget);

    await auth.signOut();
    await tester.pumpAndSettle();

    expect(find.text('دخول إلى اللوحة'), findsOneWidget);
    expect(find.byType(DashboardScreen), findsNothing);
  });

  testWidgets('بلا مستودع مصادقة لا بوابة (يعمل التطبيق محلياً بلا حساب)',
      (WidgetTester tester) async {
    // نفس المزوّد يمرَّر للموجّه والشجرة — مزوّدان مختلفان كانا يُبطل الاختبار.
    final AuthProvider open = AuthProvider(null);
    final GoRouter openRouter = AppRouter.create(open);
    addTearDown(() {
      openRouter.dispose();
      open.dispose();
    });

    await pumpRouter(tester, target: openRouter, provider: open);

    expect(find.byType(DashboardScreen), findsOneWidget);
    expect(find.text('دخول إلى اللوحة'), findsNothing);
  });
}
