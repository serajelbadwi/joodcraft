import 'admin_account.dart';

/// **إدارة المديرين محلياً** — واجهة تفصل شاشة الإدارة عن مستودع المصادقة،
/// فيمكن حقن مستودع وهمي في الاختبارات بلا لمس أي شاشة.
///
/// تنفيذها الوحيد اليوم هو `LocalAuthRepository` (المخزن على القرص)، فلا شبكة
/// ولا مستخدم خارجي في أي من هذه العمليات.
abstract interface class AdminRepository {
  /// كل الحسابات المحلية، مرتّبة (الرئيسي أولاً ثم الأحدث إنشاءً).
  Future<List<AdminAccount>> listAdmins();

  /// إنشاء مدير جديد. يرمي [AppException] عند تكرار البريد أو ضعف كلمة المرور.
  ///
  /// [username] هو **اسم المستخدم المحلي** الذي يدخل به الأدمن الفرعي على هذا
  /// الجهاز؛ إن غاب يُشتقّ تلقائياً من الجزء قبل `@` في البريد.
  Future<AdminAccount> createAdmin({
    required String email,
    required String password,
    required String fullName,
    String? organizationName,
    String? username,
    AdminRole role = AdminRole.admin,
  });

  /// تحديث بيانات مدير قائم (الاسم/المؤسسة/الرتبة) بلا مسّ كلمة مروره.
  Future<AdminAccount> updateAdminProfile({
    required String id,
    required String fullName,
    String? organizationName,
    String? username,
    AdminRole? role,
  });

  /// تغيير كلمة مرور مدير.
  ///
  /// [currentPassword] مطلوب فقط عند تغيير **كلمة مرور نفسك**؛ وعند غيابه
  /// تُعامل العملية كإعادة تعيين من مدير آخر (صلاحية إدارية).
  Future<void> setAdminPassword({
    required String id,
    required String newPassword,
    String? currentPassword,
  });

  /// حذف مدير. يرمي [AppException] إن كان الحساب المطلوب حذفه هو الحساب الحالي.
  Future<void> deleteAdmin(String id);

  /// يُصدّر كل الحسابات في **شفرة مشفّرة** بعبارة المرور (للنقل بين الأجهزة).
  Future<String> exportAdminConfig({required String passphrase});

  /// يستورد شفرة/ملف حسابات مُشفَّراً.
  ///
  /// [replaceExisting] = `true` يستبدل كلمة مرور الحساب الموجود، و`false`
  /// يتركه كما هو ويعدّه «مُتخطّى».
  Future<AdminImportReport> importAdminConfig({
    required String code,
    required String passphrase,
    bool replaceExisting = false,
  });
}
