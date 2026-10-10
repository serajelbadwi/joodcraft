import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/features/auth/data/local_auth_repository.dart';
import 'package:joodcraft/features/auth/presentation/providers/admin_accounts_controller.dart';
import 'package:joodcraft/features/auth/presentation/providers/auth_provider.dart';
import 'package:joodcraft/features/auth/presentation/widgets/fast_switch_dialog.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// اختبارات وِدجت لحوار **تبديل الحساب السريع** بنظام «المديرين الفرعيين
/// المحليين»: يُختار **اسم المستخدم المحلي** وتُدخَل كلمة المرور المحلية.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalAuthRepository repository;

  /// يزرع مديراً رئيسياً (المسجَّل الآن) ومديراً فرعياً باسم المستخدم `editor`.
  Future<void> seed() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    repository = await LocalAuthRepository.create();
    await repository.signUpWithPassword(
      email: 'owner@jood.test',
      password: 'OwnerPass123!',
      fullName: 'المدير الرئيسي',
    );
    await repository.signUpWithPassword(
      email: 'editor@jood.test',
      password: 'EditorPass456!',
      fullName: 'المدير المساعد',
    );
    await repository.signInWithPassword(
      email: 'owner@jood.test',
      password: 'OwnerPass123!',
    );
  }

  Future<void> pumpDialog(WidgetTester tester, AuthProvider auth) async {
    final AdminAccountsController admins = AdminAccountsController(repository);
    await admins.load();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
          ChangeNotifierProvider<AdminAccountsController>.value(value: admins),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (BuildContext context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  key: const ValueKey<String>('open-switch'),
                  onPressed: () => showFastSwitchDialog(context),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey<String>('open-switch')));
    await tester.pumpAndSettle();
  }

  Future<void> pickUsername(WidgetTester tester, String username) async {
    await tester.tap(find.byKey(const ValueKey<String>('fast-switch-pick')));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('@$username').last);
    await tester.pumpAndSettle();
  }

  testWidgets('يعرض اسم المستخدم المحلي للحساب الفرعي', (WidgetTester tester) async {
    await seed();
    final AuthProvider auth = AuthProvider(repository);
    addTearDown(auth.dispose);
    await pumpDialog(tester, auth);

    // عناصر القائمة تُبنى عند فتح القائمة المنسدلة.
    await tester.tap(find.byKey(const ValueKey<String>('fast-switch-pick')));
    await tester.pumpAndSettle();
    expect(find.textContaining('@editor'), findsWidgets);
    expect(find.textContaining('@owner'), findsNothing,
        reason: 'الحساب الحالي مستبعَد من القائمة');
    await tester.tapAt(const Offset(4, 4));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('fast-switch-password')),
        findsOneWidget);
  });

  testWidgets('اسم مستخدم + كلمة مرور صحيحة ⇒ تبديل الجلسة',
      (WidgetTester tester) async {
    await seed();
    final AuthProvider auth = AuthProvider(repository);
    addTearDown(auth.dispose);
    await pumpDialog(tester, auth);

    await pickUsername(tester, 'editor');
    await tester.enterText(
      find.byKey(const ValueKey<String>('fast-switch-password')),
      'EditorPass456!',
    );
    await tester.tap(find.byKey(const ValueKey<String>('fast-switch-submit')));
    await tester.pumpAndSettle();

    expect(auth.user?.email, 'editor@jood.test');
    expect(repository.currentUser?.email, 'editor@jood.test');
  });

  testWidgets('كلمة مرور خاطئة ⇒ خطأ داخل الحوار وبقاء الجلسة',
      (WidgetTester tester) async {
    await seed();
    final AuthProvider auth = AuthProvider(repository);
    addTearDown(auth.dispose);
    await pumpDialog(tester, auth);

    await pickUsername(tester, 'editor');
    await tester.enterText(
      find.byKey(const ValueKey<String>('fast-switch-password')),
      'wrong-pass',
    );
    await tester.tap(find.byKey(const ValueKey<String>('fast-switch-submit')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey<String>('fast-switch-error')),
        findsOneWidget);
    expect(auth.user?.email, 'owner@jood.test');
  });
}
