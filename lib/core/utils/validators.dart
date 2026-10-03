import '../constants/app_constants.dart';

/// مدقّقات المدخلات — منطق نقي قابل للاختبار بلا واجهة.
///
/// كل دالة تُعيد `null` عند الصحة، أو رسالة عربية جاهزة للعرض عند الخطأ
/// (وهو العقد الذي يتوقعه `TextFormField.validator`).
abstract final class Validators {
  const Validators._();

  /// تعبير مبسّط وصارم بما يكفي للنطاق العملي (التحقق النهائي يبقى على الخادم).
  static final RegExp _emailPattern = RegExp(
    r'^[\w.!#$%&*+/=?^`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?'
    r'(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$',
  );

  /// حقل إلزامي.
  static String? required(String? value, {String fieldName = 'هذا الحقل'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName مطلوب.';
    }
    return null;
  }

  /// بريد إلكتروني صالح.
  static String? email(String? value) {
    final String text = (value ?? '').trim();
    if (text.isEmpty) return 'البريد الإلكتروني مطلوب.';
    if (!_emailPattern.hasMatch(text)) {
      return 'صيغة البريد الإلكتروني غير صحيحة.';
    }
    return null;
  }

  /// كلمة مرور مطابقة لسياسة Supabase (8 أحرف على الأقل).
  static String? password(String? value) {
    final String text = value ?? '';
    if (text.isEmpty) return 'كلمة المرور مطلوبة.';
    if (text.length < AppConstants.minPasswordLength) {
      return 'كلمة المرور يجب أن تكون ${AppConstants.minPasswordLength} أحرف على الأقل.';
    }
    return null;
  }

  /// تأكيد كلمة المرور.
  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) return 'يرجى تأكيد كلمة المرور.';
    if (value != original) return 'كلمتا المرور غير متطابقتين.';
    return null;
  }

  /// اسم شخص أو مؤسسة (طول وحدود منطقية).
  static String? displayName(String? value, {String fieldName = 'الاسم'}) {
    final String text = (value ?? '').trim();
    if (text.isEmpty) return '$fieldName مطلوب.';
    if (text.length < 3) return '$fieldName قصير جداً.';
    if (text.length > AppConstants.maxNameLength) {
      return '$fieldName طويل جداً (الحد ${AppConstants.maxNameLength} حرفاً).';
    }
    return null;
  }

  /// اسم اختياري: يقبل الفراغ، ويرفض الطول المفرط فقط.
  static String? optionalName(String? value, {String fieldName = 'الحقل'}) {
    final String text = (value ?? '').trim();
    if (text.isEmpty) return null;
    if (text.length > AppConstants.maxNameLength) {
      return '$fieldName طويل جداً (الحد ${AppConstants.maxNameLength} حرفاً).';
    }
    return null;
  }
}
