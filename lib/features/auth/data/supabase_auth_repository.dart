import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_error_code.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../domain/app_user.dart';
import '../domain/auth_repository.dart';

/// تنفيذ [AuthRepository] فوق Supabase Auth.
///
/// كل خطأ خارجي يُحوَّل هنا إلى [AppException] عربي، فلا تتسرّب أي رسالة إنجليزية
/// أو استثناء خام إلى طبقة العرض.
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);

  final SupabaseClient _client;

  GoTrueClient get _auth => _client.auth;

  @override
  AppUser? get currentUser {
    final User? user = _auth.currentUser;
    return user == null ? null : AppUser.fromSupabaseUser(user);
  }

  @override
  Stream<AppUser?> authStateChanges() {
    return _auth.onAuthStateChange.map((AuthState state) {
      final User? user = state.session?.user;
      return user == null ? null : AppUser.fromSupabaseUser(user);
    });
  }

  @override
  Future<AppUser> signInWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      final AuthResponse response = await _auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      final User? user = response.user;
      if (user == null) {
        throw const AppException(AppErrorCode.unknown);
      }
      return AppUser.fromSupabaseUser(user);
    } catch (error, stackTrace) {
      throw ErrorMapper.map(error, stackTrace);
    }
  }

  @override
  Future<SignUpOutcome> signUpWithPassword({
    required String email,
    required String password,
    required String fullName,
    String? organizationName,
  }) async {
    try {
      final AuthResponse response = await _auth.signUp(
        email: email.trim(),
        password: password,
        // تُقرأ هذه القيم في الـ trigger لإنشاء سجل profiles مباشرة.
        data: <String, dynamic>{
          'full_name': fullName.trim(),
          if (organizationName != null && organizationName.trim().isNotEmpty)
            'organization_name': organizationName.trim(),
        },
      );

      final User? user = response.user;
      if (user == null) {
        throw const AppException(AppErrorCode.unknown);
      }

      return SignUpOutcome(
        user: AppUser.fromSupabaseUser(user),
        // لا جلسة = تأكيد البريد مُفعّل في إعدادات المشروع.
        requiresEmailConfirmation: response.session == null,
      );
    } catch (error, stackTrace) {
      throw ErrorMapper.map(error, stackTrace);
    }
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.resetPasswordForEmail(email.trim());
    } catch (error, stackTrace) {
      throw ErrorMapper.map(error, stackTrace);
    }
  }

  @override
  Future<Map<String, dynamic>?> fetchProfile(String userId) async {
    try {
      return await _client
          .from(AppConstants.profilesTable)
          .select()
          .eq('id', userId)
          .maybeSingle();
    } catch (error, stackTrace) {
      throw ErrorMapper.map(error, stackTrace);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (error, stackTrace) {
      throw ErrorMapper.map(error, stackTrace);
    }
  }
}
