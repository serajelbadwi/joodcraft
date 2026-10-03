import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_error_code.dart';
import 'app_exception.dart';

/// تحويل أي خطأ قادم من Supabase أو الشبكة إلى `AppException` عربي جاهز للعرض.
abstract final class ErrorMapper {
  const ErrorMapper._();

  /// المدخل الموحّد: استخدم هذا في كل Repository.
  static AppException map(Object error, [StackTrace? stackTrace]) {
    if (error is AppException) return error;

    // ------------------------- أخطاء المصادقة -------------------------
    if (error is AuthException) {
      return AppException(
        _authCode(error),
        cause: error,
        stackTrace: stackTrace,
        // بعض الأخطاء (مثل قيود كلمة المرور) تأتي برسالة إنجليزية مطوّلة،
        // فنُبقي رسالتنا العربية فهي أوضح للمستخدم النهائي.
      );
    }

    // ------------------------- أخطاء قاعدة البيانات -------------------------
    if (error is PostgrestException) {
      return AppException(
        _postgrestCode(error),
        cause: error,
        stackTrace: stackTrace,
      );
    }

    // ------------------------- أخطاء الشبكة -------------------------
    final String raw = error.toString();
    if (error is AuthRetryableFetchException ||
        raw.contains('SocketException') ||
        raw.contains('ClientException') ||
        raw.contains('Failed host lookup') ||
        raw.contains('Connection closed')) {
      return AppException(
        AppErrorCode.network,
        cause: error,
        stackTrace: stackTrace,
      );
    }

    return AppException(
      AppErrorCode.unknown,
      cause: error,
      stackTrace: stackTrace,
    );
  }

  /// تحويل خطأ المصادقة إلى كود عربي.
  ///
  /// طبقتان: (1) اعتماد رمز الخطأ الذي يبنيه SDK، (2) احتياط من نص الرسالة.
  /// الطبقة الثانية ضرورية لأن `AuthException.code` قد تكون **null** بحسب
  /// إصدار بوابة المصادقة: gotrue يقرأ `error_code` (نص) في النسخ القديمة،
  /// ويقرأ `code` في النسخ الأحدث — وقيمتها رقم HTTP (int) لا نص، فيُهملها
  /// ويرجع null. بدون هذا الاحتياط تظهر للمستخدم رسالة "خطأ غير متوقع" بدل
  /// "بيانات الدخول غير صحيحة".
  static AppErrorCode _authCode(AuthException error) {
    final AppErrorCode? fromCode = _authCodeFromSdkCode(error.code);
    if (fromCode != null) return fromCode;

    final AppErrorCode? fromMessage = _authCodeFromMessage(error.message);
    if (fromMessage != null) return fromMessage;

    if (error is AuthRetryableFetchException) return AppErrorCode.network;
    // استجابة 5xx من الخادم
    if ((error.statusCode ?? '').startsWith('5')) return AppErrorCode.server;
    return AppErrorCode.unknown;
  }

  /// رمز Supabase الرسمي → كود التطبيق.
  static AppErrorCode? _authCodeFromSdkCode(String? code) {
    switch (code) {
      case 'invalid_credentials':
      case 'invalid_grant':
        return AppErrorCode.invalidCredentials;
      case 'email_exists':
      case 'user_already_exists':
        return AppErrorCode.emailAlreadyInUse;
      case 'weak_password':
        return AppErrorCode.weakPassword;
      case 'email_not_confirmed':
        return AppErrorCode.emailNotConfirmed;
      case 'same_password':
        return AppErrorCode.samePassword;
      case 'user_not_found':
        return AppErrorCode.userNotFound;
      case 'over_request_rate_limit':
      case 'over_email_send_rate_limit':
        return AppErrorCode.rateLimited;
      case 'session_not_found':
      case 'refresh_token_not_found':
      case 'session_expired':
        return AppErrorCode.sessionExpired;
      case 'validation_failed':
      case 'email_address_invalid':
      case 'signup_disabled':
      case 'signup_requires_valid_password':
        return AppErrorCode.validation;
      default:
        return null;
    }
  }

  /// احتياط نصي — مطابقة الجزء الثابت من رسائل Supabase الإنجليزية.
  static AppErrorCode? _authCodeFromMessage(String rawMessage) {
    final String message = rawMessage.toLowerCase();

    if (message.contains('invalid login credentials') ||
        message.contains('invalid grant')) {
      return AppErrorCode.invalidCredentials;
    }
    if (message.contains('already registered') ||
        message.contains('already exists')) {
      return AppErrorCode.emailAlreadyInUse;
    }
    if (message.contains('email not confirmed')) {
      return AppErrorCode.emailNotConfirmed;
    }
    // ملاحظة ترتيب: فحص "كلمة المرور الجديدة مطابقة للقديمة" يجب أن يسبق فحص
    // الضعف، لأن رسالة Supabase هي "New password should be different from the
    // old password" وتحتوي على عبارة "password should be" أيضاً.
    if (message.contains('should be different') &&
        message.contains('password')) {
      return AppErrorCode.samePassword;
    }
    if (message.contains('password should be at least') ||
        message.contains('password is too short') ||
        message.contains('weak password')) {
      return AppErrorCode.weakPassword;
    }
    if (message.contains('user not found')) {
      return AppErrorCode.userNotFound;
    }
    if (message.contains('rate limit') ||
        message.contains('you can only request this after') ||
        message.contains('too many requests')) {
      return AppErrorCode.rateLimited;
    }
    if (message.contains('auth session missing') ||
        message.contains('jwt expired') ||
        message.contains('refresh token')) {
      return AppErrorCode.sessionExpired;
    }
    if (message.contains('unable to validate email') ||
        message.contains('signups not allowed')) {
      return AppErrorCode.validation;
    }
    return null;
  }

  /// تحويل أخطاء PostgREST إلى كود عربي.
  static AppErrorCode _postgrestCode(PostgrestException error) {
    switch (error.code) {
      case '42501': // insufficient_privilege — غالباً نتيجة سياسة RLS
        return AppErrorCode.permissionDenied;
      case '23503': // foreign_key_violation
      case '23514': // check_violation
      case '23505': // unique_violation
        return AppErrorCode.validation;
      case 'PGRST116': // لا نتائج
        return AppErrorCode.notFound;
      case 'PGRST301': // JWT منتهٍ/غير صالح
        return AppErrorCode.sessionExpired;
      default:
        return AppErrorCode.server;
    }
  }
}
