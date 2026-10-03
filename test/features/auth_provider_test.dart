import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/errors/app_error_code.dart';
import 'package:joodcraft/core/errors/app_exception.dart';
import 'package:joodcraft/features/auth/domain/app_user.dart';
import 'package:joodcraft/features/auth/presentation/providers/auth_provider.dart';

import '../support/fake_auth_repository.dart';

void main() {
  group('AuthProvider — بدون تهيئة Supabase', () {
    test('يُعلن أن الخدمة غير متوفرة ويرمي notConfigured', () async {
      final AuthProvider provider = AuthProvider(null);
      addTearDown(provider.dispose);

      expect(provider.isServiceAvailable, isFalse);
      expect(provider.isAuthenticated, isFalse);

      await expectLater(
        provider.signIn(email: 'a@b.com', password: '12345678'),
        throwsA(
          isA<AppException>().having(
            (AppException e) => e.code,
            'code',
            AppErrorCode.notConfigured,
          ),
        ),
      );
    });
  });

  group('AuthProvider — مع مستودع وهمي', () {
    late FakeAuthRepository repository;

    AuthProvider build() {
      final AuthProvider provider = AuthProvider(repository);
      addTearDown(provider.dispose);
      return provider;
    }

    setUp(() => repository = FakeAuthRepository());
    tearDown(() => repository.close());

    test('الحالة الابتدائية: غير مسجّل وليس في حالته الانشغال', () {
      final AuthProvider provider = build();
      expect(provider.isAuthenticated, isFalse);
      expect(provider.isBusy, isFalse);
      expect(provider.isInitializing, isFalse);
      expect(provider.isServiceAvailable, isTrue);
    });

    test('تسجيل الدخول الناجح يُحدّث المستخدم ويُثري البيانات من profiles',
        () async {
      final AuthProvider provider = build();

      await provider.signIn(email: 'abdullah@jood.org', password: '12345678');
      expect(provider.isAuthenticated, isTrue);
      expect(provider.user?.email, 'abdullah@jood.org');

      // تحديث الملف يجري في الخلفية.
      await pumpEventQueue();
      expect(provider.user?.fullName, 'الاسم من قاعدة البيانات');
      expect(provider.user?.subscriptionTier.labelAr, 'احترافي');
    });

    test('فشل تسجيل الدخول يُمرّر AppException العربية كما هي', () async {
      repository = FakeAuthRepository(
        signInError: const AppException(AppErrorCode.invalidCredentials),
      );
      final AuthProvider provider = build();

      await expectLater(
        provider.signIn(email: 'a@b.com', password: '12345678'),
        throwsA(
          isA<AppException>().having(
            (AppException e) => e.message,
            'message',
            AppErrorCode.invalidCredentials.messageAr,
          ),
        ),
      );

      expect(provider.isAuthenticated, isFalse);
      expect(provider.isBusy, isFalse, reason: 'يجب ألا تبقى حالة الانشغال عالقة');
    });

    test('الخطأ غير المعروف يُغلَّف في AppException', () async {
      repository = FakeAuthRepository(signInError: StateError('boom'));
      final AuthProvider provider = build();

      await expectLater(
        provider.signIn(email: 'a@b.com', password: '12345678'),
        throwsA(
          isA<AppException>().having(
            (AppException e) => e.code,
            'code',
            AppErrorCode.unknown,
          ),
        ),
      );
    });

    test('التسجيل مع تأكيد البريد لا يفتح جلسة ويُعلّم الحالة', () async {
      repository = FakeAuthRepository(requiresEmailConfirmation: true);
      final AuthProvider provider = build();

      final SignUpOutcome outcome = await provider.signUp(
        email: 'new@jood.org',
        password: '12345678',
        fullName: 'منى العبدالله',
      );

      expect(outcome.requiresEmailConfirmation, isTrue);
      expect(provider.isEmailConfirmationPending, isTrue);
      expect(provider.isAuthenticated, isFalse);
    });

    test('التسجيل بلا تأكيد بريد يفتح الجلسة مباشرة', () async {
      final AuthProvider provider = build();

      await provider.signUp(
        email: 'new@jood.org',
        password: '12345678',
        fullName: 'منى العبدالله',
        organizationName: 'جمعية جود',
      );

      expect(provider.isAuthenticated, isTrue);
      expect(provider.user?.organizationName, 'جمعية جود');
      expect(provider.isEmailConfirmationPending, isFalse);
    });

    test('استعادة كلمة المرور تُنفَّذ دون تغيير حالة الدخول', () async {
      final AuthProvider provider = build();
      await provider.sendPasswordReset('abdullah@jood.org');
      expect(provider.isAuthenticated, isFalse);
      expect(provider.isBusy, isFalse);
    });

    test('تسجيل الخروج يُفرغ المستخدم', () async {
      final AuthProvider provider = build();
      await provider.signIn(email: 'abdullah@jood.org', password: '12345678');
      expect(provider.isAuthenticated, isTrue);

      await provider.signOut();
      expect(provider.isAuthenticated, isFalse);
      expect(repository.signedOut, isTrue);
    });

    test('علم تأكيد البريد يُصفَّر يدوياً', () async {
      repository = FakeAuthRepository(requiresEmailConfirmation: true);
      final AuthProvider provider = build();

      await provider.signUp(
        email: 'new@jood.org',
        password: '12345678',
        fullName: 'منى العبدالله',
      );
      expect(provider.isEmailConfirmationPending, isTrue);

      provider.clearEmailConfirmationFlag();
      expect(provider.isEmailConfirmationPending, isFalse);
    });
  });
}
