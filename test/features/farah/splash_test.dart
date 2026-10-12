/// اختبارات شاشة افتتاح «Jood Reach»: تعمل — اسمها يُكتب حرفًا حرفًا —
/// ثم **تنتقل وحدها** إلى شاشة الدخول بعد ‎5s‎ (بلا ضغطة زرّ).
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/features/farah/data/farah_repository.dart';
import 'package:joodcraft/features/farah/domain/farah_models.dart';
import 'package:joodcraft/features/farah/presentation/screens/farah_login_screen.dart';
import 'package:joodcraft/features/farah/presentation/screens/jood_reach_splash_screen.dart';
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

  testWidgets('الافتتاح يعمل ويعرض «Jood Reach» حرفًا حرفًا ولا يفتح الدخول بعد', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: JoodReachSplashScreen(repository: _StubFarahRepository()),
      ),
    );
    // بعد ‎1.6s‎: كل الحروف العشرة بدأت بالظهور (آخرها يبدأ عند ‎1.35s‎).
    await tester.pump(const Duration(milliseconds: 1600));

    expect(find.byKey(const ValueKey<String>('jood-reach-splash')), findsOneWidget);
    // الحروف Texts منفصلّة (تتابع الظهور) — نجمّع صفّ الاسم فنقرأ الاسم كاملاً.
    final Iterable<Text> letters = tester.widgetList<Text>(
      find.descendant(
        of: find.byKey(const ValueKey<String>('jood-reach-splash-name')),
        matching: find.byType(Text),
      ),
    );
    expect(letters.map((Text letter) => letter.data).join(), 'Jood Reach');
    // حارس تجمّد الرسمة: الحرف الأول بلغ كماله — فالأنيميشن يُعيد الرسم
    // فعلاً لا أن المشهد صورة مُجمَّدة على أوّل إطار.
    final Finder opacityFinder = find.descendant(
      of: find.byKey(const ValueKey<String>('jood-reach-splash-name')),
      matching: find.byType(Opacity),
    );
    final Opacity firstLetter = tester.widget<Opacity>(opacityFinder.first);
    expect(firstLetter.opacity, moreOrLessEquals(1.0));
    expect(find.byType(FarahLoginScreen), findsNothing);
  });

  testWidgets('الرسالة المجنّحة تظهر بين ‎1.5s‎ و‎3s‎ ثم تنعدم تماماً', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: JoodReachSplashScreen(repository: _StubFarahRepository()),
      ),
    );

    // قبل الطيران: الرسالة مطفأة تماماً.
    await tester.pump(const Duration(milliseconds: 1000));
    expect(_envelopeOpacityOf(tester), 0.0);

    // في قلب الطيران (‎2s‎): ظاهرة بشفافية كاملة.
    await tester.pump(const Duration(milliseconds: 1000));
    expect(_envelopeOpacityOf(tester), greaterThan(0.9));

    // التوقّف (‎3.5s‎): قد طارت وانقضت — لا أثر لها خلف الاسم الثابت.
    await tester.pump(const Duration(milliseconds: 1500));
    expect(_envelopeOpacityOf(tester), 0.0);
  });

  testWidgets('تنتقل إلى شاشة الدخول بعد ‎5s‎', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: JoodReachSplashScreen(repository: _StubFarahRepository()),
      ),
    );

    // قبل الميعاد: لا انتقال.
    await tester.pump(const Duration(milliseconds: 4900));
    expect(find.byType(FarahLoginScreen), findsNothing);

    // يُستنزَف الباقي: مؤقّت ‎5s‎ يُحقن الانتقال، ثم يكتمل بهتان ‎400ms‎.
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    expect(find.byType(FarahLoginScreen), findsOneWidget);
    // `pushReplacement`: الشاشة الأولى مُزيلت فلا يُرجع له الرجوع.
    expect(find.byType(JoodReachSplashScreen), findsNothing);
  });
}

/// شفافية غلاف الرسالة المجنّحة (أقرب `Opacity` يحيط بأيقونة البريد).
double _envelopeOpacityOf(WidgetTester tester) {
  // الأيقونة تُرسم مرتين: نسخة الذهبي ونسخة اللمعة — تكفي إحداهما.
  final Finder icons = find.byIcon(Icons.mail_rounded);
  expect(icons, findsWidgets);
  final Finder ancestors = find.ancestor(
    of: icons.first,
    matching: find.byType(Opacity),
  );
  return tester.widgetList<Opacity>(ancestors).first.opacity;
}
