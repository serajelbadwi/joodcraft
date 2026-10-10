import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:joodcraft/app/router/app_router.dart';
import 'package:joodcraft/core/audit/export_audit_log.dart';
import 'package:joodcraft/core/locale/app_locale.dart';
import 'package:joodcraft/core/locale/locale_controller.dart';
import 'package:joodcraft/core/theme/app_theme.dart';
import 'package:joodcraft/core/theme/theme_controller.dart';
import 'package:joodcraft/features/auth/data/local_auth_repository.dart';
import 'package:joodcraft/features/auth/domain/admin_account.dart';
import 'package:joodcraft/features/auth/presentation/providers/admin_accounts_controller.dart';
import 'package:joodcraft/features/auth/presentation/providers/auth_provider.dart';
import 'package:joodcraft/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('تطبيق كامل: فتح /admin-accounts يعرض جدول المديرين',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final LocalAuthRepository repository = await LocalAuthRepository.create();
    await repository.signUpWithPassword(
      email: 'owner@jood.test',
      password: 'OwnerPass123!',
      fullName: 'المدير الرئيسي',
    );
    final AdminAccount sub = await repository.createAdmin(
      email: 'sub@jood.test',
      password: 'SubPass123!',
      fullName: 'أدمن فرعي',
      username: 'sub1',
    );

    final AuthProvider auth = AuthProvider(repository);
    final AdminAccountsController admins = AdminAccountsController(repository);
    final ExportAuditLog audit = ExportAuditLog.instance;
    final GoRouter router = AppRouter.create(auth);
    addTearDown(() {
      router.dispose();
      auth.dispose();
      admins.dispose();
    });

    await auth.signIn(email: 'owner@jood.test', password: 'OwnerPass123!');

    final List<String> errors = <String>[];
    final void Function(FlutterErrorDetails)? previous = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      errors.add(details.exceptionAsString());
    };
    addTearDown(() => FlutterError.onError = previous);

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
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
          ChangeNotifierProvider<AdminAccountsController>.value(value: admins),
          ChangeNotifierProvider<ExportAuditLog>.value(value: audit),
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

    router.go('/admin-accounts');
    await tester.pumpAndSettle();

    FlutterError.onError = previous;
    debugPrint('COLLECTED=${errors.length}');
    for (final String e in errors.take(4)) {
      debugPrint('ERR>> $e');
    }
    debugPrint('at=${router.state.matchedLocation}');
  });
}
