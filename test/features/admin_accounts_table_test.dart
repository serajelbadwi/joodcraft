import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/features/auth/data/local_auth_repository.dart';
import 'package:joodcraft/features/auth/domain/admin_account.dart';
import 'package:joodcraft/features/auth/presentation/providers/admin_accounts_controller.dart';
import 'package:joodcraft/features/auth/presentation/screens/admin_accounts_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// اختبارات وِدجت لتبويب **المديرون**: جدول بأعمدة (المدير/اسم المستخدم المحلي/
/// الصلاحية/تاريخ الإضافة) وأزرار الإجراءات وحوار الإضافة.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalAuthRepository repository;
  late AdminAccountsController controller;
  late String subId;

  Future<void> seed() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    repository = await LocalAuthRepository.create();
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
    subId = sub.id;
    controller = AdminAccountsController(repository);
    await controller.load();
  }

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(home: AdminAccountsScreen(controller: controller)),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('يعرض ترويسة الجدول وصفوفه وأعمدة اسم المستخدم',
      (WidgetTester tester) async {
    await seed();
    await pumpScreen(tester);

    expect(
      find.byKey(const ValueKey<String>('adm-table-header')),
      findsOneWidget,
    );
    // اسم المستخدم المحلي للحساب الفرعي يظهر في عموده.
    expect(
      find.byKey(ValueKey<String>('adm-username-$subId')),
      findsOneWidget,
    );
    expect(find.text('@sub1'), findsOneWidget);
  });

  testWidgets('لكل مدير أزرار تعديل وكلمة مرور وحذف',
      (WidgetTester tester) async {
    await seed();
    await pumpScreen(tester);

    expect(find.byKey(ValueKey<String>('adm-edit-$subId')), findsOneWidget);
    expect(find.byKey(ValueKey<String>('adm-password-$subId')), findsOneWidget);
    expect(find.byKey(ValueKey<String>('adm-delete-$subId')), findsOneWidget);
    expect(find.byKey(ValueKey<String>('adm-menu-$subId')), findsOneWidget);
  });

  testWidgets('زر إضافة مدير يفتح حواراً بحقل اسم المستخدم المحلي',
      (WidgetTester tester) async {
    await seed();
    await pumpScreen(tester);

    await tester.tap(find.byKey(const ValueKey<String>('adm-add')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('adm-dialog-username')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('adm-dialog-password')),
      findsOneWidget,
    );
  });
}
