import 'app_error_code.dart';

/// الاستثناء الموحّد للتطبيق.
///
/// قاعدة معمارية: **لا تُعرض رسائل الأخطاء الخام للمستخدم أبداً**. كل طبقة
/// (Repository/Provider) تحوّل أي خطأ إلى `AppException` يحمل رمزاً برمجياً
/// ورسالة عربية جاهزة للعرض.
class AppException implements Exception {
  const AppException(this.code, {String? message, this.cause, this.stackTrace})
      : _message = message;

  /// رمز الخطأ البرمجي (يُستخدم في المنطق والاختبارات).
  final AppErrorCode code;

  final String? _message;

  /// الخطأ الأصلي (للتسجيل/التصحيح فقط).
  final Object? cause;
  final StackTrace? stackTrace;

  /// الرسالة العربية الجاهزة للعرض.
  String get message => _message ?? code.messageAr;

  @override
  String toString() => 'AppException(${code.name}): $message'
      '${cause == null ? '' : ' | cause: $cause'}';
}
