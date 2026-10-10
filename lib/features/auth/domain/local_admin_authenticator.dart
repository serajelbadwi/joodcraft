import 'app_user.dart';

/// **مصادقة الأدمن الفرعي محلياً** — واجهة مفصولة عن [AuthRepository] لأن
/// التبديل السريع ظاهرة **خاصّة بالجهاز**: الحسابات الفرعية التي أضافها المدير
/// الرئيسي، ويُختار أحدها بـ«اسم المستخدم المحلي» + كلمة المرور المحلية
/// (تُتحقّق مقابل بصمة PBKDF2 في المخزن المحلي)، دون أي شبكة.
///
/// فصلها هكذا يبقي [AuthRepository] نظيفاً موجّهاً لمزوّد الخدمة، ويسمح
/// لـ`AuthProvider` بأن يسأل وقت التشغيل: هل هذا المخزن يدعم التبديل المحلي؟
/// (`repository is LocalAdminAuthenticator`) فيعرض الزر أو يخفيه بلا انهيار.
abstract interface class LocalAdminAuthenticator {
  /// هل التبديل المحلي متاح أصلاً؟ (مخزن محلي جاهز).
  bool get isLocalSwitchAvailable;

  /// يتحقّق من اسم المستخدم المحلي وكلمة المرور مقابل الحساب الفرعي المخزَّن
  /// على هذا الجهاز، ثم **يحفظ الجلسة** ويعيد مستخدمها.
  ///
  /// يرمي `AppException` عند اسم مستخدم غير موجود أو كلمة مرور خاطئة.
  Future<AppUser> signInWithLocalUsername({
    required String username,
    required String password,
  });
}
