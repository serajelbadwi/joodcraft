import 'app_user.dart';

/// رتبة المدير داخل التطبيق المحلي.
///
/// التمييز **دلالي محلياً**: «المدير الرئيسي» هو من يملك الجهاز ويدير الحسابات
/// وينقلها للأجهزة الأخرى، و«مدير» حساب عمل عادي. لا سيرفر ولا سياسات عن بعد،
/// فالحماية الحقيقية هي بقاء الملف المحلي على الجهاز.
enum AdminRole {
  owner('المدير الرئيسي', 'owner'),
  admin('مدير', 'admin');

  const AdminRole(this.labelAr, this.dbValue);

  /// التسمية العربية للعرض.
  final String labelAr;

  /// القيمة المخزَّنة في ملف الحسابات.
  final String dbValue;

  /// يقرأ الرتبة من قيمتها المخزَّنة (`null` أو مجهولة ⇒ [AdminRole.admin]).
  static AdminRole fromDb(String? value) {
    for (final AdminRole role in AdminRole.values) {
      if (role.dbValue == value) return role;
    }
    // حساب قديم سُجّل قبل إضافة الرتبة: يُعامل «مديراً» ولا يُرقّى تلقائياً،
    // فيبقى ترقية أحدهم إلى «رئيسي» قراراً صريحاً من مدير موجود.
    return AdminRole.admin;
  }

  /// عنصر قائمة منسدلة.
  static List<AdminRole> get selectable => AdminRole.values;
}

/// حساب أدمن كما تعرضه شاشة الإدارة.
///
/// **لا يحمل كلمة المرور ولا بصمتها إطلاقاً** — البصمة تُبقى في مستودع
/// المصادقة وحده، فلا تتسرّب إلى الشجرة ولا إلى السجلات.
class AdminAccount {
  const AdminAccount({
    required this.id,
    required this.email,
    this.username,
    this.fullName,
    this.organizationName,
    this.role = AdminRole.admin,
    this.createdAt,
    this.updatedAt,
    this.isCurrent = false,
  });

  final String id;
  final String email;

  /// **اسم المستخدم المحلي** الذي يدخل به الأدمن الفرعي على هذا الجهاز.
  ///
  /// اختياري: إن لم يُضبط صراحةً عند الإنشاء، يُشتقّ تلقائياً من الجزء قبل
  /// `@` في البريد ([effectiveUsername]) — فتبقى كل الحسابات القائمة قابلة
  /// للتبديل السريع بلا هجرة بيانات.
  final String? username;

  final String? fullName;
  final String? organizationName;
  final AdminRole role;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// هل هذا حساب المستخدم المسجَّل الآن؟ (تمنع حذف نفسه أو تجريدها من الرتبة)
  final bool isCurrent;

  bool get isOwner => role == AdminRole.owner;

  /// اسم المستخدم المحلي الفعّال لهذا الحساب (المضبوط صراحةً أو المشتق من
  /// البريد) — هو ما يُعرض في قائمة التبديل السريع ويُطابَق عند المصادقة المحلية.
  String get effectiveUsername {
    final String? raw = username?.trim();
    if (raw != null && raw.isNotEmpty) return raw;
    final int at = email.indexOf('@');
    return at > 0 ? email.substring(0, at) : email;
  }

  /// الاسم المعروض — يرجع إلى البريد إن لم يُسجَّل الاسم.
  String get displayName => AppUser(
        id: id,
        email: email,
        fullName: fullName,
      ).displayName;

  /// الحرفان الأولان للصورة الرمزية.
  String get initials => AppUser(
        id: id,
        email: email,
        fullName: fullName,
      ).initials;

  AdminAccount copyWith({
    String? email,
    String? username,
    String? fullName,
    String? organizationName,
    AdminRole? role,
    DateTime? updatedAt,
    bool? isCurrent,
  }) {
    return AdminAccount(
      id: id,
      email: email ?? this.email,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      organizationName: organizationName ?? this.organizationName,
      role: role ?? this.role,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isCurrent: isCurrent ?? this.isCurrent,
    );
  }
}

/// نتيجة استيراد ملف حسابات إلى الجهاز.
class AdminImportReport {
  const AdminImportReport({
    required this.added,
    required this.updated,
    required this.skipped,
  });

  /// حسابات جديدة أُضيفت.
  final int added;

  /// حسابات قائمة حُدّثت بياناتها (وكلمة مرورها).
  final int updated;

  /// حسابات تُركت كما هي (موجودة والاستيراد لا يستبدل).
  final int skipped;

  int get total => added + updated + skipped;
}
