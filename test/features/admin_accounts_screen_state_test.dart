import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/audit/export_audit_log.dart';
import 'package:joodcraft/core/theme/app_theme.dart';
import 'package:joodcraft/features/auth/data/local_auth_repository.dart';
import 'package:joodcraft/features/auth/domain/admin_account.dart';
import 'package:joodcraft/features/auth/domain/admin_repository.dart';
import 'package:joodcraft/features/auth/presentation/providers/admin_accounts_controller.dart';
import 'package:joodcraft/features/auth/presentation/providers/auth_provider.dart';
import 'package:joodcraft/features/auth/presentation/screens/admin_accounts_screen.dart';
import 'package:joodcraft/features/auth/presentation/widgets/fast_switch_dialog.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// اختبارات **جلب البيانات وحالة العرض** لشاشة إدارة المديرين:
///
/// * الشاشة تعمل داخل مزوّداتها الحقيقية (`ChangeNotifierProvider` كما في
///   `app.dart`) بلا أخطاء بناء، ويظهر الجدول ببيانات المخزن المحلي.
/// * حالة التحميل لا تُخفي الجدول خلف نصّ «لا حسابات» الكاذب.
/// * أي إضافة/تعديل يظهر في الجدول فوراً (تفاعل فوري).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalAuthRepository repository;
  late String subId;

  /// يزرع مديراً رئيسياً وفرعياً على المخزن المحلي الحقيقي.
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
  }

  /// يبني الشاشة **كما في التطبيق الحقيقي**: بلا مُحقَن مباشر، فتقرأ من
  /// مزوّد الإدارة عبر الشجرة، وتحت الثيم الحقيقي (`AppTheme.light`) الذي
  /// يضبط أزراره بعرض أدنى لا نهائي داخل الأعمدة — فلا يفوتنا عيب تخطيطي
  /// يظهر فقط تحت الثيم (مثل زر داخل صف).
  ///
  /// ضخّ إطارات محدّد بدل `pumpAndSettle`: مؤشّر التحميل دوّار لا يتوقّف،
  /// فكان `pumpAndSettle` يانتهي حتى لو كانت الشاشة سليمة.
  Future<void> pumpHostedScreen(
    WidgetTester tester, {
    AdminAccountsController? controller,
  }) async {
    final AdminAccountsController admins =
        controller ?? AdminAccountsController(repository);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AdminAccountsController>.value(value: admins),
          ChangeNotifierProvider<ExportAuditLog>.value(
            value: ExportAuditLog.instance,
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const AdminAccountsScreen(),
        ),
      ),
    );
    // إطاران: الأول يبني الشاشة ويطلق الجلب المؤجَّل، والثاني يعرض ناتجه.
    await tester.pump();
    await tester.pump();
  }

  testWidgets(
      'شاشة داخل مزوّداتها تعرض جدول المديرين دون أي خطأ بناء',
      (WidgetTester tester) async {
    await seed();
    await pumpHostedScreen(tester);

    // العلة القديمة: جلب بدأ من `didChangeDependencies` فأبلغ المزوّد أثناء
    // البناء — «setState() or markNeedsBuild() called during build» — ويحلّ
    // `ErrorWidget` محل الشاشة فلا يظهر الجدول.
    expect(tester.takeException(), isNull);
    expect(
      find.byKey(const ValueKey<String>('adm-table-header'),
          skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.byKey(ValueKey<String>('adm-username-$subId'), skipOffstage: false),
      findsOneWidget,
    );
    expect(find.text('@sub1'), findsOneWidget);
  });

  testWidgets('حالة التحميل تُظهر مؤشّراً لا نصّ «لا حسابات»',
      (WidgetTester tester) async {
    await seed();
    final _SlowAdminsRepository slow =
        _SlowAdminsRepository(repository)..gate = Completer<void>();

    await pumpHostedScreen(
      tester,
      controller: AdminAccountsController(slow),
    );

    // الجدول هنا مؤجَّل… لكن المؤشّر ظاهر والنصّ الكاذب غائب.
    expect(find.text('لا حسابات مديرين بعد.'), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('adm-loading'), skipOffstage: false),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    // اكتمل الجلب ⇒ تظهر الصفوف وتختفي حالة التحميل.
    slow.gate!.complete();
    await tester.pumpAndSettle();

    expect(
      find.byKey(ValueKey<String>('adm-username-$subId'), skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('adm-loading'), skipOffstage: false),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('إضافة مدير من الشاشة تُظهر صفّه فوراً في الجدول',
      (WidgetTester tester) async {
    await seed();
    final AdminAccountsController admins = AdminAccountsController(repository);
    await pumpHostedScreen(tester, controller: admins);

    await admins.create(
      email: 'new@jood.test',
      password: 'NewPass123!',
      fullName: 'مدير جديد',
      username: 'newadmin',
    );
    await tester.pumpAndSettle();

    expect(find.text('@newadmin'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('حوار التبديل السريع يُحمّل الحسابات دون خطأ بناء',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    repository = await LocalAuthRepository.create();
    await repository.signUpWithPassword(
      email: 'owner@jood.test',
      password: 'OwnerPass123!',
      fullName: 'المدير الرئيسي',
    );
    final AuthProvider auth = AuthProvider(repository);
    final AdminAccountsController admins = AdminAccountsController(repository);
    addTearDown(() {
      auth.dispose();
      admins.dispose();
    });

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
          ChangeNotifierProvider<AdminAccountsController>.value(value: admins),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
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

    // القائمة كانت فارغة ⇒ حاول الحوار جلبها أثناء بنائه (العلة القديمة).
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
    expect(admins.isLoaded, isTrue);
  });
}

/// مستودع بطيء يحاكي **جهازاً حقيقياً تأخرت قراءته**: لا يعيد القائمة قبل
/// إكمال [gate] — لاختبار حالة التحميل في الواجهة.
class _SlowAdminsRepository implements AdminRepository {
  _SlowAdminsRepository(this._inner);

  final LocalAuthRepository _inner;

  /// بوابة الانتظار: لا تُسلَّم أي قائمة قبل إكمالها.
  Completer<void>? gate;

  Future<List<AdminAccount>> _await(
    Future<List<AdminAccount>> Function() next,
  ) async {
    final Completer<void>? pending = gate;
    if (pending != null) {
      await pending.future;
      // تُفتح البوابة بعد أول تسليم كي لا تُعمي كل إعادة تحميل لاحقة.
      gate = null;
    }
    return next();
  }

  @override
  Future<List<AdminAccount>> listAdmins() => _await(_inner.listAdmins);

  @override
  Future<AdminAccount> createAdmin({
    required String email,
    required String password,
    required String fullName,
    String? organizationName,
    String? username,
    AdminRole role = AdminRole.admin,
  }) =>
      _inner.createAdmin(
        email: email,
        password: password,
        fullName: fullName,
        organizationName: organizationName,
        username: username,
        role: role,
      );

  @override
  Future<AdminAccount> updateAdminProfile({
    required String id,
    required String fullName,
    String? organizationName,
    String? username,
    AdminRole? role,
  }) =>
      _inner.updateAdminProfile(
        id: id,
        fullName: fullName,
        organizationName: organizationName,
        username: username,
        role: role,
      );

  @override
  Future<void> setAdminPassword({
    required String id,
    required String newPassword,
    String? currentPassword,
  }) =>
      _inner.setAdminPassword(
        id: id,
        newPassword: newPassword,
        currentPassword: currentPassword,
      );

  @override
  Future<void> deleteAdmin(String id) => _inner.deleteAdmin(id);

  @override
  Future<String> exportAdminConfig({required String passphrase}) =>
      _inner.exportAdminConfig(passphrase: passphrase);

  @override
  Future<AdminImportReport> importAdminConfig({
    required String code,
    required String passphrase,
    bool replaceExisting = false,
  }) =>
      _inner.importAdminConfig(
        code: code,
        passphrase: passphrase,
        replaceExisting: replaceExisting,
      );
}
