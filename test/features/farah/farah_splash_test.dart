/// اختبارات شاشة افتتاح «فرح»: تظهر — ثم **تنتقل وحدها** إلى شاشة الدخول
/// بعد مدة العرض (بلا ضغطة زرّ).
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/features/farah/data/farah_repository.dart';
import 'package:joodcraft/features/farah/domain/farah_models.dart';
import 'package:joodcraft/features/farah/domain/farah_text.dart';
import 'package:joodcraft/features/farah/presentation/screens/farah_login_screen.dart';
import 'package:joodcraft/features/farah/presentation/screens/farah_splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// مستودع وهمي: الافتتاح لا يقرأ بيانات، والدخول في هذا الاختبار لا يُستدعى
/// — نكتفي بتنفيذ العقدّ بلا شبكة ولا Supabase.
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
  }) async =>
      FarahSendResult(
        message: FarahMessage(
          id: 'm-1',
          senderId: 'me-1',
          body: body,
          createdAt: DateTime(2026),
        ),
        remaining: 499,
      );

  @override
  Future<bool> activateLicense({required String phone, required String code}) async =>
      false;
}

void main() {
  setUp(() {
    // المخزن الوهمي يمنع أخطاء القناة أثناء تفكيك الشاشة (شاشة الدخول
    // تحفظ التليفون فيه).
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('الافتتاح يعرض الشعار ونصّ «تطبيق فرح» ولا يفتح الدخول بعد', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: FarahSplashScreen(repository: _StubFarahRepository())),
    );
    // منتصف الدخول: الشعار ظاهر (تلاشٍ + تكبير) ولم يحن وقت الانتقال.
    await tester.pump(const Duration(milliseconds: 900));

    expect(find.byKey(const ValueKey<String>('farah-splash-logo')), findsOneWidget);
    expect(find.text(FarahText.appName), findsOneWidget);
    expect(find.byType(FarahLoginScreen), findsNothing);
  });

  testWidgets('تنتقل إلى شاشة الدخول بعد مدة العرض (‎≈2.8s‎)', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: FarahSplashScreen(repository: _StubFarahRepository())),
    );

    // بعد الدخول مباشرةً: لا انتقال قبل استقرار الشعار.
    await tester.pump(const Duration(milliseconds: 1200));
    expect(find.byType(FarahLoginScreen), findsNothing);

    // تُستنزَف بقية الحركة (خروج الشعار) ثم يُحقن زمن الانتقال ‎2.8s‎.
    await tester.pumpAndSettle(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    expect(find.byType(FarahLoginScreen), findsOneWidget);
    // `pushReplacement`: الشاشة الأولى مُزيلت فلا يُرجع له الرجوع.
    expect(find.byType(FarahSplashScreen), findsNothing);
  });
}
