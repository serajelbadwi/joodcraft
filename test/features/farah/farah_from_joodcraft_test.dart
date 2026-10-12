/// اختبارات فتح «تطبيق فرح» من داخل JoodCraft: **صفحة حوار ملء الشاشة بزرّ
/// X** تُدفع فوق القسم الحالي بدل استبدال موقع التنقّل — وهي الشكوى الأصلي:
/// كانت تُفتح بشاشة كاملة بلا سهم رجوع ولا طريق للعودة.
///
/// الاختبار يستدعي دالة التنقّل الإنتاجية نفسها (`navigateToDestination`)
/// لا تقليداً لها: فلو أُسقط فرح من `_overlayRoutes` ثانيةً يعود `go`
/// ليستبدل الموقع — ويفشل الاختبار تلقائياً.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:joodcraft/app/router/app_routes.dart';
import 'package:joodcraft/features/dashboard/presentation/dashboard_destinations.dart';
import 'package:joodcraft/features/farah/data/farah_repository.dart';
import 'package:joodcraft/features/farah/domain/farah_models.dart';
import 'package:joodcraft/features/farah/domain/farah_text.dart';
import 'package:joodcraft/features/farah/presentation/screens/farah_dialog_host.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// مستودع وهمي: النافذة لا تتجاوز شاشة الدخول في هذه الاختبارات.
class _StubFarahRepository implements FarahRepository {
  const _StubFarahRepository();

  @override
  bool get isAvailable => true;

  @override
  Future<FarahSession> login(String phone) async => FarahSession(
    memberId: 'me-1',
    fullName: 'أحمد محمود حسن',
    villageId: 'v-1',
    villageName: 'منشأة الأمراء ومحلة حسن',
    isOwner: false,
    phone: phone,
  );

  @override
  Future<List<FarahMember>> fetchMembers(String phone) async =>
      const <FarahMember>[];

  @override
  Future<List<FarahConversation>> fetchConversations(String phone) async =>
      const <FarahConversation>[];

  @override
  Future<List<FarahMessage>> fetchThread({
    required String phone,
    required String partnerId,
  }) async =>
      const <FarahMessage>[];

  @override
  Future<FarahAllowance> fetchAllowance({
    required String phone,
    required String partnerId,
  }) async =>
      const FarahAllowance(remaining: 500, isOwner: false);

  @override
  Future<FarahSendResult> sendMessage({
    required String phone,
    required String partnerId,
    required String body,
  }) async => FarahSendResult(
    message: FarahMessage(
      id: 'm-1',
      senderId: 'me-1',
      body: body,
      createdAt: DateTime(2026),
    ),
    remaining: 499,
  );

  @override
  Future<bool> activateLicense({
    required String phone,
    required String code,
  }) async =>
      false;
}

/// بديل «اللوحة»: يمثّل القسم الذي يعمل عليه المستخدم قبل أن يفتح فرح،
/// وزرّه يستدعي **دالة التنقّل الإنتاجية نفسها** (`navigateToDestination`).
class _LauncherScreen extends StatelessWidget {
  const _LauncherScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey<String>('launcher-mark'),
      body: Center(
        child: TextButton(
          key: const ValueKey<String>('open-farah'),
          onPressed: () => navigateToDestination(context, AppRoutes.farah),
          child: const Text('تطبيق فرح'),
        ),
      ),
    );
  }
}

/// محرّك يحاكي توصيل الإنتاج: قسم لوحة + مسار `/farah` بمضيف الحوار
/// (بمستودع الاختبار — الإنتاج يمرّر Supabase افتراضياً في المضيف نفسه).
GoRouter _buildRouter() => GoRouter(
  initialLocation: '/',
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) =>
          const _LauncherScreen(),
    ),
    GoRoute(
      path: AppRoutes.farah,
      builder: (BuildContext context, GoRouterState state) =>
          const FarahDialogHost(repository: _StubFarahRepository()),
    ),
  ],
);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('الزرّ يفتح حواراً بزرّ X فوق القسم الحيّ — لا استبدالاً ولا سهم رجوع', (
    WidgetTester tester,
  ) async {
    final GoRouter router = _buildRouter();
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    // نفس مسار النقر الفعلي في شريط JoodCraft: onNavigate ← navigateToDestination.
    await tester.tap(find.byKey(const ValueKey<String>('open-farah')));
    await tester.pumpAndSettle();

    // النافذة ظاهرة: زرّ X (بترجمة «إغلاق») وبلا سهم رجوع افتراضي.
    expect(
      find.byKey(const ValueKey<String>('farah-dialog-close')),
      findsOneWidget,
    );
    expect(find.byTooltip(FarahText.closeDialog), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsNothing);
    expect(find.byIcon(Icons.arrow_back_ios_new), findsNothing);
    // والقسم الذي كان عليه المستخدم **ما زال حيّاً تحت النافذة** —
    // (`skipOffstage: false` تفحص حتى الصفحات المُدفونة خلف الحالية).
    expect(
      find.byKey(const ValueKey<String>('launcher-mark'), skipOffstage: false),
      findsOneWidget,
    );
    // وشاشة الدخول داخل النافذة بشعارها.
    expect(find.byKey(const ValueKey<String>('farah-logo')), findsOneWidget);
    // وترويسة النافذة تحمل اسم التطبيق.
    expect(find.text(FarahText.appName), findsOneWidget);
  });

  testWidgets('زرّ X يُعيد المستخدم إلى قسمه بالضبط', (
    WidgetTester tester,
  ) async {
    final GoRouter router = _buildRouter();
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('open-farah')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('farah-dialog-close')));
    await tester.pumpAndSettle();

    // النافذة غادرت والقسم عاد ظاهراً — لا كائن عالق.
    expect(find.byType(FarahDialogHost), findsNothing);
    expect(find.byKey(const ValueKey<String>('launcher-mark')), findsOneWidget);
  });
}
