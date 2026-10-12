import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/features/farah/data/farah_repository.dart';
import 'package:joodcraft/features/farah/domain/farah_models.dart';
import 'package:joodcraft/features/farah/domain/farah_text.dart';
import 'package:joodcraft/features/farah/presentation/screens/farah_login_screen.dart';
import 'package:joodcraft/features/farah/presentation/widgets/farah_common.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// مستودع وهمي في الذاكرة: يعيد جلسات وأهل قرى ومحادثات مُعدّة مسبقاً،
/// ويسجّل ما وصل إليه — بلا شبكة ولا Supabase إطلاقاً.
class _FakeFarahRepository implements FarahRepository {
  _FakeFarahRepository();

  /// جلسات صحيحة: تليفون ← جلسة (الدخول لا يقبل غيرها).
  final Map<String, FarahSession> sessions = <String, FarahSession>{
    '01012345678': FarahSession(
      memberId: 'me-1',
      fullName: 'أحمد محمود حسن',
      villageId: 'v-1',
      villageName: 'منشأة الأمراء ومحلة حسن',
      isOwner: false,
      phone: '01012345678',
    ),
  };

  /// أهل القرية — أساس شاشة الرئيسية وقائمة المحادثات.
  final List<FarahMember> members = <FarahMember>[
    const FarahMember(
      memberId: 'me-1',
      fullName: 'أحمد محمود حسن',
      isOwner: false,
    ),
    const FarahMember(
      memberId: 'm-2',
      fullName: 'سميرة عبد الله',
      isOwner: false,
    ),
    const FarahMember(
      memberId: 'm-3',
      fullName: 'مكتب الأفراح',
      isOwner: true,
    ),
  ];

  /// سلسلة كل محادثة (معرّف المدعو ← رسائله).
  final Map<String, List<FarahMessage>> threads =
      <String, List<FarahMessage>>{};

  /// ما تبقّى من حدّ الإرسال في المحادثة الحالية.
  int remaining = 500;

  /// هل العضو صاحب فرح؟
  bool isOwner = false;

  /// أخطاء يُرميها الاختبار متى شاء (null = كل شيء ينجح).
  Object? failLoginWith;
  Object? failSendWith;
  Object? failLicenseWith;

  /// سجلّ ما أُرسل — للتحقّق من نظافة النص قبل الإرسال.
  final List<String> sentBodies = <String>[];

  int _sentCount = 0;

  @override
  bool get isAvailable => true;

  @override
  Future<FarahSession> login(String phone) async {
    final Object? failure = failLoginWith;
    if (failure != null) throw failure;
    final FarahSession? session = sessions[phone.trim()];
    if (session == null) {
      throw const FarahException(
        FarahErrorKind.notRegistered,
        FarahText.notRegistered,
      );
    }
    return session;
  }

  @override
  Future<List<FarahMember>> fetchMembers(String phone) async => members;

  @override
  Future<List<FarahConversation>> fetchConversations(String phone) async =>
      members
          .where((FarahMember m) => m.memberId != 'me-1')
          .map(
            (FarahMember m) => FarahConversation(
              partnerId: m.memberId,
              partnerName: m.fullName,
              partnerIsOwner: m.isOwner,
              lastBody: '',
              lastAt: null,
              lastFromMe: false,
              remaining: remaining,
            ),
          )
          .toList(growable: false);

  @override
  Future<List<FarahMessage>> fetchThread({
    required String phone,
    required String partnerId,
  }) async =>
      threads[partnerId] ?? const <FarahMessage>[];

  @override
  Future<FarahAllowance> fetchAllowance({
    required String phone,
    required String partnerId,
  }) async =>
      FarahAllowance(remaining: remaining, isOwner: isOwner);

  @override
  Future<FarahSendResult> sendMessage({
    required String phone,
    required String partnerId,
    required String body,
  }) async {
    final Object? failure = failSendWith;
    if (failure != null) throw failure;
    sentBodies.add(body);
    final FarahMessage message = FarahMessage(
      id: 'sent-${++_sentCount}',
      senderId: 'me-1',
      body: body,
      createdAt: DateTime(2026, 10, 12, 20, 30),
    );
    remaining = (remaining - body.length).clamp(0, 1 << 30);
    return FarahSendResult(message: message, remaining: remaining);
  }

  @override
  Future<bool> activateLicense({
    required String phone,
    required String code,
  }) async {
    final Object? failure = failLicenseWith;
    if (failure != null) throw failure;
    return true;
  }
}

const String _phone = '01012345678';

Future<void> _pumpLogin(
  WidgetTester tester,
  _FakeFarahRepository repo,
) async {
  tester.view.physicalSize = const Size(1100, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: FarahLoginScreen(repository: repo),
    ),
  );
  await tester.pumpAndSettle();
}

/// يملأ التليفون ويضغط «تسجيل» ويعيد إلى شاشة الرئيسية.
Future<void> _login(
  WidgetTester tester,
  _FakeFarahRepository repo,
) async {
  await tester.enterText(
    find.byKey(const ValueKey<String>('farah-login-phone-field')),
    _phone,
  );
  await tester.tap(find.byKey(const ValueKey<String>('farah-login-submit')));
  await tester.pumpAndSettle();
}

/// يفتح محادثة أول مدعو في «أهل القرية» (بلا شاشة الرسائل الوسيطة).
Future<void> _openFirstChat(WidgetTester tester) async {
  await tester.tap(find.text('سميرة عبد الله'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    // مخزن تفضيلات وهمي: الشاشة تحفظ فيه التليفون وتسترجعه.
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('رقم غير مسجَّل يعرض «سجّل في صفحة القرية أولاً»', (
    WidgetTester tester,
  ) async {
    final _FakeFarahRepository repo = _FakeFarahRepository();
    await _pumpLogin(tester, repo);

    await tester.enterText(
      find.byKey(const ValueKey<String>('farah-login-phone-field')),
      '01199999999',
    );
    await tester.tap(find.byKey(const ValueKey<String>('farah-login-submit')));
    await tester.pumpAndSettle();

    expect(find.text(FarahText.notRegistered), findsOneWidget);
    // لم تُفتح الرئيسية إطلاقاً.
    expect(find.byKey(const ValueKey<String>('farah-home')), findsNothing);
  });

  testWidgets('رقم غير مصري يُرفض محلياً بلا نداء للسيرفر', (
    WidgetTester tester,
  ) async {
    final _FakeFarahRepository repo = _FakeFarahRepository();
    await _pumpLogin(tester, repo);

    await tester.enterText(
      find.byKey(const ValueKey<String>('farah-login-phone-field')),
      '1234',
    );
    await tester.tap(find.byKey(const ValueKey<String>('farah-login-submit')));
    await tester.pumpAndSettle();

    expect(find.text(FarahText.notRegistered), findsNothing);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('الدخول برقم مسجَّل يفتح الرئيسية باسم العضو وقريته', (
    WidgetTester tester,
  ) async {
    final _FakeFarahRepository repo = _FakeFarahRepository();
    await _pumpLogin(tester, repo);
    await _login(tester, repo);

    expect(find.byKey(const ValueKey<String>('farah-home')), findsOneWidget);
    expect(find.text('أحمد محمود حسن'), findsOneWidget);
    expect(find.text('منشأة الأمراء ومحلة حسن'), findsOneWidget);
    expect(find.text(FarahText.messagesButton), findsOneWidget);
    expect(find.text(FarahText.invitationsButton), findsOneWidget);
  });

  testWidgets('قائمة أهل القرية تعرض الأسماء وشارة صاحب الفرح', (
    WidgetTester tester,
  ) async {
    final _FakeFarahRepository repo = _FakeFarahRepository();
    await _pumpLogin(tester, repo);
    await _login(tester, repo);

    expect(
      find.byKey(const ValueKey<String>('farah-home-members')),
      findsOneWidget,
    );
    expect(find.text('سميرة عبد الله'), findsOneWidget);
    expect(find.text('مكتب الأفراح'), findsOneWidget);
    // الشارة الذهبية أمام اسم صاحب الفرح وحده.
    expect(find.byType(FarahOwnerBadge), findsOneWidget);
  });

  testWidgets('الضغط على اسم عضو يفتح المحادثة باسمه الكامل', (
    WidgetTester tester,
  ) async {
    final _FakeFarahRepository repo = _FakeFarahRepository();
    await _pumpLogin(tester, repo);
    await _login(tester, repo);
    await _openFirstChat(tester);

    expect(find.byKey(const ValueKey<String>('farah-chat')), findsOneWidget);
    expect(find.text('سميرة عبد الله'), findsOneWidget);
    expect(find.text(FarahText.threadEmpty), findsOneWidget);
  });

  testWidgets('عدّاد الأحرف يبدأ 0 / 100 ويزيد مع الكتابة', (
    WidgetTester tester,
  ) async {
    final _FakeFarahRepository repo = _FakeFarahRepository();
    await _pumpLogin(tester, repo);
    await _login(tester, repo);
    await _openFirstChat(tester);

    expect(
      find.byKey(const ValueKey<String>('farah-chat-counter')),
      findsOneWidget,
    );
    expect(find.text('0 / 100'), findsOneWidget);
    // المتبقي من حدّ المدعو (500 حرف/يوم) معروض قبل أي إرسال.
    expect(find.text(FarahText.remainingToday(500)), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey<String>('farah-chat-input')),
      'السلام عليكم', // 12 حرفاً
    );
    await tester.pumpAndSettle();

    expect(find.text('12 / 100'), findsOneWidget);
  });

  testWidgets('إرسال رسالة يضيفها للسلسلة ويحدّث المتبقي والعدّاد', (
    WidgetTester tester,
  ) async {
    final _FakeFarahRepository repo = _FakeFarahRepository();
    await _pumpLogin(tester, repo);
    await _login(tester, repo);
    await _openFirstChat(tester);

    await tester.enterText(
      find.byKey(const ValueKey<String>('farah-chat-input')),
      'كل سنة وأنتِ بخير', // 17 حرفاً
    );
    await tester.pumpAndSettle(); // يعيد بناء زرّ الإرسال بعد تغيّر النص
    await tester.tap(find.byKey(const ValueKey<String>('farah-chat-send')));
    await tester.pumpAndSettle();

    expect(repo.sentBodies, <String>['كل سنة وأنتِ بخير']);
    expect(find.text('كل سنة وأنتِ بخير'), findsOneWidget);
    // 500 - 17 = 483 حرف متبقٍّ.
    expect(find.text(FarahText.remainingToday(483)), findsOneWidget);
    expect(find.text('0 / 100'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('farah-chat-input')),
      findsOneWidget,
    );
  });

  testWidgets('نفاد الحدّ يعطّل حقل الإرسال ويعرض رسالة انتهاء اليوم', (
    WidgetTester tester,
  ) async {
    final _FakeFarahRepository repo = _FakeFarahRepository()..remaining = 0;
    await _pumpLogin(tester, repo);
    await _login(tester, repo);
    await _openFirstChat(tester);

    expect(find.text(FarahText.limitReachedToday), findsWidgets);

    final Finder send = find.byKey(const ValueKey<String>('farah-chat-send'));
    expect(tester.widget<FilledButton>(send).onPressed, isNull);

    final Finder input = find.byKey(const ValueKey<String>('farah-chat-input'));
    expect(tester.widget<TextField>(input).enabled, isFalse);
  });

  testWidgets('رفض السيرفر بحدّ الإرسال يعرض رسالته العربية', (
    WidgetTester tester,
  ) async {
    final _FakeFarahRepository repo = _FakeFarahRepository()
      ..failSendWith = const FarahException(
        FarahErrorKind.limitReached,
        'انتهى حدّ رسائلك اليوم (استخدمت 500 من 500 حرف) — يتجدد غداً',
      );
    await _pumpLogin(tester, repo);
    await _login(tester, repo);
    await _openFirstChat(tester);

    await tester.enterText(
      find.byKey(const ValueKey<String>('farah-chat-input')),
      'رسالة بعد نفاد الحدّ',
    );
    await tester.pumpAndSettle(); // يعيد بناء زرّ الإرسال بعد تغيّر النص
    await tester.tap(find.byKey(const ValueKey<String>('farah-chat-send')));
    await tester.pumpAndSettle();

    expect(find.textContaining('انتهى حدّ رسائلك اليوم'), findsOneWidget);
    expect(repo.sentBodies, isEmpty);
  });

  testWidgets('كود تفعيل خاطئ يعرض رسالة السيرفر', (WidgetTester tester) async {
    final _FakeFarahRepository repo = _FakeFarahRepository()
      ..failLicenseWith = const FarahException(
        FarahErrorKind.invalid,
        'كود التفعيل غير صحيح — راجع الكود مع مكتب القرية',
      );
    await _pumpLogin(tester, repo);
    await _login(tester, repo);

    await tester.tap(find.byKey(const ValueKey<String>('farah-home-license')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('farah-license')),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const ValueKey<String>('farah-license-code-field')),
      'FARAH-0000',
    );
    await tester.tap(find.byKey(const ValueKey<String>('farah-license-submit')));
    await tester.pumpAndSettle();

    expect(find.textContaining('كود التفعيل غير صحيح'), findsOneWidget);
  });

  testWidgets('التفعيل الناجح يعود للرئيسية بصلاحيات صاحب الفرح', (
    WidgetTester tester,
  ) async {
    final _FakeFarahRepository repo = _FakeFarahRepository();
    await _pumpLogin(tester, repo);
    await _login(tester, repo);

    await tester.tap(find.byKey(const ValueKey<String>('farah-home-license')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey<String>('farah-license-code-field')),
      'FARAH-0001',
    );
    await tester.tap(find.byKey(const ValueKey<String>('farah-license-submit')));
    await tester.pumpAndSettle();

    // عدنا إلى الرئيسية، وصار الزرّ يعرض «مُفعَّل ✓» والشارة ظاهرة
    // (شارة الترويسة + شارة صاحب الفرح «مكتب الأفراح» في القائمة).
    expect(find.byKey(const ValueKey<String>('farah-home')), findsOneWidget);
    expect(find.text(FarahText.ownerActive), findsOneWidget);
    expect(find.byType(FarahOwnerBadge), findsWidgets);
  });

  testWidgets('شاشة الرسائل تعرض المحادثات بحدّها المتبقي', (
    WidgetTester tester,
  ) async {
    final _FakeFarahRepository repo = _FakeFarahRepository()..remaining = 250;
    await _pumpLogin(tester, repo);
    await _login(tester, repo);

    await tester.tap(find.byKey(const ValueKey<String>('farah-home-messages')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('farah-messages-list')),
      findsOneWidget,
    );
    expect(find.text('سميرة عبد الله'), findsOneWidget);
    expect(find.text('مكتب الأفراح'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('farah-conversation-m-2')),
      findsOneWidget,
    );
  });

  // ------------------------- أسهم الرجوع (التنقّل) -------------------------

  testWidgets('من الرئيسية إلى الرسائل ثم سهم الرجوع يعيد للرئيسية', (
    WidgetTester tester,
  ) async {
    final _FakeFarahRepository repo = _FakeFarahRepository();
    await _pumpLogin(tester, repo);
    await _login(tester, repo);

    await tester.tap(find.byKey(const ValueKey<String>('farah-home-messages')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('farah-messages')),
      findsOneWidget,
    );

    // سهم رجوع حقيقي في الشريط العلوي.
    await tester.tap(find.byKey(const ValueKey<String>('farah-back')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey<String>('farah-home')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('farah-messages')), findsNothing);
  });

  testWidgets('زر الرجوع في المحادثة والتفعيل والدعوات يعيد للرئيسية', (
    WidgetTester tester,
  ) async {
    final _FakeFarahRepository repo = _FakeFarahRepository();
    await _pumpLogin(tester, repo);
    await _login(tester, repo);

    // المحادثة ← رجوع.
    await _openFirstChat(tester);
    expect(find.byKey(const ValueKey<String>('farah-chat')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('farah-back')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('farah-home')), findsOneWidget);

    // كود التفعيل ← رجوع.
    await tester.tap(find.byKey(const ValueKey<String>('farah-home-license')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('farah-license')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('farah-back')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('farah-home')), findsOneWidget);

    // الدعوات ← رجوع.
    await tester.tap(
      find.byKey(const ValueKey<String>('farah-home-invitations')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('farah-invitations')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey<String>('farah-back')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('farah-home')), findsOneWidget);
  });

  testWidgets('الرئيسية جذر: بلا سهم رجوع ومعها زرّ «خروج» في الشريط', (
    WidgetTester tester,
  ) async {
    final _FakeFarahRepository repo = _FakeFarahRepository();
    await _pumpLogin(tester, repo);
    await _login(tester, repo);

    expect(find.byKey(const ValueKey<String>('farah-back')), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('farah-home-sign-out')),
      findsOneWidget,
    );

    // «خروج» يعود إلى شاشة الدخول.
    await tester.tap(
      find.byKey(const ValueKey<String>('farah-home-sign-out')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('farah-login')), findsOneWidget);
  });
}
