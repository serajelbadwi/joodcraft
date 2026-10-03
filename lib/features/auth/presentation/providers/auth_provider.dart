import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_error_code.dart';
import '../../../../core/errors/app_exception.dart';
import '../../domain/app_user.dart';
import '../../domain/auth_repository.dart';

/// حالة المصادقة داخل التطبيق.
///
/// ملاحظة معمارية: هذا المزوّد **لا يعرض رسائل** — يرمي [AppException] فقط،
/// والشاشة هي التي تقرّر كيف تُظهر الخطأ (SnackBar/Inline message).
class AuthProvider extends ChangeNotifier {
  AuthProvider(this._repository) {
    _user = _repository?.currentUser;
    _initializing = false;
    _subscribe();
  }

  /// `null` يعني أن التطبيق لم يُربط بـ Supabase بعد (شاشة تهيئة).
  final AuthRepository? _repository;

  StreamSubscription<AppUser?>? _subscription;

  AppUser? _user;
  bool _busy = false;
  bool _initializing = true;
  bool _emailConfirmationPending = false;

  // ------------------------------ الحالة العامة ------------------------------
  AppUser? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isBusy => _busy;
  bool get isInitializing => _initializing;
  bool get isServiceAvailable => _repository != null;

  /// صحيح بعد تسجيل حساب يحتاج تأكيد بريد — تُعرض رسالة إرشادية في شاشة الدخول.
  bool get isEmailConfirmationPending => _emailConfirmationPending;

  void _subscribe() {
    final AuthRepository? repository = _repository;
    if (repository == null) return;

    _subscription = repository.authStateChanges().listen(
      (AppUser? user) {
        _applyUser(user);
        _initializing = false;
        notifyListeners();
        if (user != null) unawaited(_refreshProfile());
      },
      onError: (Object _) {
        _initializing = false;
        notifyListeners();
      },
    );
  }

  void _applyUser(AppUser? user) {
    _user = user;
    if (user != null) _emailConfirmationPending = false;
  }

  /// تسجيل الدخول. يرمي [AppException] عند الفشل.
  Future<void> signIn({
    required String email,
    required String password,
  }) {
    return _run(() async {
      _user = await _requireRepository().signInWithPassword(
        email: email,
        password: password,
      );
      unawaited(_refreshProfile());
    });
  }

  /// إنشاء حساب جديد. يعيد [SignUpOutcome] عند النجاح.
  Future<SignUpOutcome> signUp({
    required String email,
    required String password,
    required String fullName,
    String? organizationName,
  }) {
    return _run(() async {
      final SignUpOutcome outcome =
          await _requireRepository().signUpWithPassword(
        email: email,
        password: password,
        fullName: fullName,
        organizationName: organizationName,
      );
      _emailConfirmationPending = outcome.requiresEmailConfirmation;
      if (!outcome.requiresEmailConfirmation) {
        _user = outcome.user;
      }
      return outcome;
    });
  }

  /// إرسال رابط استعادة كلمة المرور.
  Future<void> sendPasswordReset(String email) {
    return _run(() => _requireRepository().sendPasswordReset(email));
  }

  /// إنهاء الجلسة.
  Future<void> signOut() {
    return _run(() async {
      await _requireRepository().signOut();
      _user = null;
    });
  }

  /// نسيان رسالة "تم إنشاء الحساب" بعد قراءتها.
  void clearEmailConfirmationFlag() {
    if (!_emailConfirmationPending) return;
    _emailConfirmationPending = false;
    notifyListeners();
  }

  // ============================== أدوات داخلية ==============================

  AuthRepository _requireRepository() {
    final AuthRepository? repository = _repository;
    if (repository == null) {
      throw const AppException(AppErrorCode.notConfigured);
    }
    return repository;
  }

  /// تغليف موحّد: إدارة حالة الانشغال + تحويل أي خطأ إلى [AppException].
  Future<T> _run<T>(Future<T> Function() action) async {
    _busy = true;
    notifyListeners();
    try {
      return await action();
    } catch (error) {
      throw error is AppException
          ? error
          : AppException(AppErrorCode.unknown, cause: error);
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// جلب بيانات profiles في الخلفية (فشلها لا يكسر تجربة الدخول).
  Future<void> _refreshProfile() async {
    final AppUser? current = _user;
    final AuthRepository? repository = _repository;
    if (current == null || repository == null) return;
    try {
      final Map<String, dynamic>? row = await repository.fetchProfile(current.id);
      if (row == null) return;
      final AppUser enriched = current.mergeProfile(row);
      final bool changed = enriched.fullName != current.fullName ||
          enriched.organizationName != current.organizationName ||
          enriched.subscriptionTier != current.subscriptionTier;
      if (changed) {
        _user = enriched;
        notifyListeners();
      }
    } catch (_) {
      // تجاهُل صامت: البيانات الأساسية متوفرة من الجلسة أصلاً.
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
