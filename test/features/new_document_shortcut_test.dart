import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:joodcraft/features/auth/presentation/providers/auth_provider.dart';
import 'package:joodcraft/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:joodcraft/features/project_hub/presentation/dialogs/new_document_dialog.dart';
import 'package:joodcraft/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_auth_repository.dart';

/// الاختصار `Ctrl+N` — أمر «مستند جديد…» في قائمة `ملف` يجب أن يكون **مفتاحاً
/// عاملاً** لا تلميحاً مكتوباً: من أي شاشة، ومن أول لحظة بلا نقرة تمهيدية.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeAuthRepository repository;
  late AuthProvider auth;
  late ThemeController theme;
  late LocaleController locale;
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
    theme = ThemeController();
    locale = LocaleController();
    router = AppRouter.create(auth);
  });

  tearDown(() {
    router.dispose();
    auth.dispose();
    theme.dispose();
    locale.dispose();
    repository.close();
    ProjectsController.instance.dispose();
    ProjectsController.instance = ProjectsController();
  });

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ThemeController>.value(value: theme),
          ChangeNotifierProvider<LocaleController>.value(value: locale),
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

  /// ضغط مجموعة مفاتيح حقيقية (Ctrl+N / ⌘N) كما يفعل المستخدم.
  Future<void> pressNewDocument(WidgetTester tester, {bool meta = false}) async {
    final LogicalKeyboardKey modifier =
        meta ? LogicalKeyboardKey.metaLeft : LogicalKeyboardKey.controlLeft;
    await tester.sendKeyDownEvent(modifier);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
    await tester.sendKeyUpEvent(modifier);
    await tester.pumpAndSettle();
  }

  testWidgets('Ctrl+N يفتح نافذة «مستند جديد» من لوحة التحكم بلا تنقّل',
      (WidgetTester tester) async {
    await pumpApp(tester);
    expect(find.byType(DashboardScreen), findsOneWidget);
    expect(byKey(NewDocumentKeys.window), findsNothing);

    await pressNewDocument(tester);

    expect(byKey(NewDocumentKeys.window), findsOneWidget);
    // النافذة عائمة فوق المكان نفسه: لم نغادر لوحة التحكم ولم ننتقل إلى
    // مسار آخر.
    expect(find.byType(DashboardScreen), findsOneWidget);
    expect(router.state.uri.path, AppRoutes.dashboard);

    // و`Esc` يُغلق بلا إنشاء.
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(byKey(NewDocumentKeys.window), findsNothing);
    expect(router.state.uri.path, AppRoutes.dashboard);
  });

  testWidgets('⌘N يعمل أيضاً (سلوك macOS)', (WidgetTester tester) async {
    await pumpApp(tester);

    await pressNewDocument(tester, meta: true);

    expect(byKey(NewDocumentKeys.window), findsOneWidget);
  });

  testWidgets('الاختصار لا يقاطع الكتابة داخل حقول النص',
      (WidgetTester tester) async {
    await pumpApp(tester);
    await pressNewDocument(tester);
    expect(byKey(NewDocumentKeys.window), findsOneWidget);

    // داخل النافذة: كتابة `n` في حقل العنوان تعدّل النص ولا تفتح نافذة أخرى.
    await tester.enterText(byKey(NewDocumentKeys.titleField), 'n');
    await pressNewDocument(tester);

    expect(byKey(NewDocumentKeys.window), findsOneWidget);
    expect(find.text('n'), findsWidgets);
  });
}

/// مفتاح عنصر داخل النافذة (نفس مجموعة المفاتيح المستخدمة في اختبار النافذة).
Finder byKey(String key) => find.byKey(ValueKey<String>(key));
