/// اختبارات ترويسة «فرح» وفوترها: الشعار يحلّ محلّ النصّ والأيقونة في
/// شاشتي الدخول والرئيسية، والفوتر يجلس أسفل الشاشات.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/features/farah/data/farah_repository.dart';
import 'package:joodcraft/features/farah/domain/farah_models.dart';
import 'package:joodcraft/features/farah/domain/farah_text.dart';
import 'package:joodcraft/features/farah/presentation/screens/farah_home_screen.dart';
import 'package:joodcraft/features/farah/presentation/screens/farah_login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// مستودع وهمي في الذاكرة — يكفي الترويسة والفاتور لا يحتاج بيانات حقيقية.
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
  Future<List<FarahMember>> fetchMembers(String phone) async => const <FarahMember>[
    FarahMember(memberId: 'me-1', fullName: 'أحمد محمود حسن', isOwner: false),
    FarahMember(memberId: 'm-2', fullName: 'سميرة عبد الله', isOwner: false),
  ];

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
  Future<bool> activateLicense({
    required String phone,
    required String code,
  }) async =>
      false;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('شاشة الدخول: الشعار بعرض ‎60%‎ (حدّ أقصى ‎300px‎) بدل الأيقونة', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: FarahLoginScreen(repository: _StubFarahRepository()),
      ),
    );
    await tester.pumpAndSettle();

    final Finder logo = find.byKey(const ValueKey<String>('farah-logo'));
    expect(logo, findsOneWidget);
    // `BoxFit.contain` مطلوب صراحةً: الشعار مربّع فلا يشوَّه أبداً.
    expect(tester.widget<Image>(logo).fit, BoxFit.contain);
    // استُبدل بالصورة لا أُضيف إليها: الأيقونة القديمة مفقودة.
    expect(find.byIcon(Icons.celebration_rounded), findsNothing);
    // والاسم باقٍ لقارئ الشاشة رغم أنه لم يُعرض نصّاً.
    expect(tester.widget<Image>(logo).semanticLabel, FarahText.appName);
  });

  testWidgets('الشعار في ترويسة الدخول يقع ضمن سقف ‎300px‎ فعلياً', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: FarahLoginScreen(repository: _StubFarahRepository()),
      ),
    );
    await tester.pumpAndSettle();

    final Size size = tester.getSize(
      find.byKey(const ValueKey<String>('farah-logo')),
    );
    expect(size.width, lessThanOrEqualTo(300));
    expect(size.width, moreOrLessEquals(300, epsilon: 0.5));
  });

  testWidgets('شريط الرئيسية: الشعار بارتفاع ‎40px‎ مكان العنوان', (
    WidgetTester tester,
  ) async {
    // مقاس صريح: الشريط يُختبر بعرضه لا بعرض السطح الافتراضي.
    tester.view.physicalSize = const Size(1000, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: FarahHomeScreen(
          repository: _StubFarahRepository(),
          session: FarahSession(
            memberId: 'me-1',
            fullName: 'أحمد محمود حسن',
            villageId: 'v-1',
            villageName: 'منشأة الأمراء ومحلة حسن',
            isOwner: false,
            phone: '01012345678',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final Finder logo = find.byKey(const ValueKey<String>('farah-home-logo'));
    expect(logo, findsOneWidget);
    expect(tester.widget<Image>(logo).height, 40);
  });

  testWidgets('الفوتر أسفل الشاشات: يمين شعار JoodCraft ووسط المطوّر ويسار الحقوق', (
    WidgetTester tester,
  ) async {
    // شاشة طويلة بما يكفي لبناء الفوتر وحده (لا يُبنى ما دون حدّ التمرير).
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: FarahLoginScreen(repository: _StubFarahRepository()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey<String>('farah-footer')), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('farah-footer-brand-logo')),
      findsOneWidget,
    );
    expect(find.text(FarahText.footerFrom), findsOneWidget);
    expect(find.text(FarahText.footerDeveloperName), findsOneWidget);
    expect(find.text(FarahText.footerPhone), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('farah-footer-signature')),
      findsOneWidget,
    );
    expect(find.text(FarahText.footerCopyright), findsOneWidget);
  });

  testWidgets('الفوتر يجلس أسفل الشاشة لا في أعلاها', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: FarahLoginScreen(repository: _StubFarahRepository()),
      ),
    );
    await tester.pumpAndSettle();

    final Rect footerRect = tester.getRect(
      find.byKey(const ValueKey<String>('farah-footer')),
    );
    final Rect logoRect = tester.getRect(
      find.byKey(const ValueKey<String>('farah-logo')),
    );
    expect(footerRect.top, greaterThan(logoRect.bottom));
  });
}
