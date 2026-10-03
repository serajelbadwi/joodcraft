import 'dart:async';

import 'package:joodcraft/features/auth/domain/app_user.dart';
import 'package:joodcraft/features/auth/domain/auth_repository.dart';

/// مستودع مصادقة وهمي للاختبارات — يثبت أن الواجهة معزولة تماماً عن Supabase.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    this.signInError,
    this.requiresEmailConfirmation = false,
  });

  /// خطأ يُرمى عند محاولة تسجيل الدخول (لمحاكاة سيناريوهات الفشل).
  final Object? signInError;

  /// يحاكي حالة "تأكيد البريد مُفعّل" في إعدادات مشروع Supabase.
  final bool requiresEmailConfirmation;

  final StreamController<AppUser?> _controller =
      StreamController<AppUser?>.broadcast();

  AppUser? _current;
  bool signedOut = false;
  int signUpCalls = 0;

  /// آخر بيانات وصلت إلى التسجيل (للتحقق من تمرير النموذج كاملاً).
  String? lastSignUpEmail;
  String? lastSignUpFullName;
  String? lastSignUpOrganization;

  @override
  AppUser? get currentUser => _current;

  @override
  Stream<AppUser?> authStateChanges() => _controller.stream;

  @override
  Future<AppUser> signInWithPassword({
    required String email,
    required String password,
  }) async {
    if (signInError != null) throw signInError!;
    _current = AppUser(id: 'u-1', email: email, fullName: 'عبدالله');
    _controller.add(_current);
    return _current!;
  }

  @override
  Future<SignUpOutcome> signUpWithPassword({
    required String email,
    required String password,
    required String fullName,
    String? organizationName,
  }) async {
    signUpCalls++;
    lastSignUpEmail = email;
    lastSignUpFullName = fullName;
    lastSignUpOrganization = organizationName;
    final AppUser user = AppUser(
      id: 'u-2',
      email: email,
      fullName: fullName,
      organizationName: organizationName,
    );
    if (!requiresEmailConfirmation) {
      _current = user;
      _controller.add(user);
    }
    return SignUpOutcome(
      user: user,
      requiresEmailConfirmation: requiresEmailConfirmation,
    );
  }

  @override
  Future<void> sendPasswordReset(String email) async {}

  @override
  Future<Map<String, dynamic>?> fetchProfile(String userId) async {
    return <String, dynamic>{
      'full_name': 'الاسم من قاعدة البيانات',
      'subscription_tier': 'pro',
    };
  }

  @override
  Future<void> signOut() async {
    signedOut = true;
    _current = null;
    _controller.add(null);
  }

  Future<void> close() => _controller.close();
}
