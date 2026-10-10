import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/audit/export_audit_log.dart';
import 'package:joodcraft/features/auth/data/local_auth_repository.dart';
import 'package:joodcraft/features/auth/domain/admin_account.dart';
import 'package:joodcraft/features/auth/presentation/providers/admin_accounts_controller.dart';
import 'package:joodcraft/features/auth/presentation/screens/admin_accounts_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('الشاشة داخل ChangeNotifierProvider كما في التطبيق الحقيقي',
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

    final AdminAccountsController controller =
        AdminAccountsController(repository);
    final ExportAuditLog audit = ExportAuditLog.instance;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AdminAccountsController>.value(
            value: controller,
          ),
          ChangeNotifierProvider<ExportAuditLog>.value(value: audit),
        ],
        child: const MaterialApp(home: AdminAccountsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    debugPrint('exception=${tester.takeException()}');
    debugPrint('isAvailable=${controller.isAvailable} '
        'count=${controller.admins.length} busy=${controller.isBusy} '
        'err=${controller.errorMessage}');
    debugPrint('header=${find.byKey(const ValueKey<String>('adm-table-header')).evaluate().length}');
    debugPrint('username=${find.byKey(ValueKey<String>('adm-username-${sub.id}')).evaluate().length}');
    debugPrint('unavailable=${find.byKey(const ValueKey<String>('adm-unavailable')).evaluate().length}');
    debugPrint('empty=${find.text('لا حسابات مديرين بعد.').evaluate().length}');
  });
}
