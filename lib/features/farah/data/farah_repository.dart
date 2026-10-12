/// عقد الوصول إلى بيانات تطبيق «فرح» — مستقلّ تماماً عن مزوّد الخدمة.
///
/// الواجهة (الشاشات) لا تعرف Supabase ولا PostgREST: تتحدّث مع هذه الواجهة
/// فقط، فيمكن اختبار التدفّق كاملاً بمستودع وهمي في الذاكرة بلا شبكة.
///
/// الدخول **بلا OTP** (كما صُمِّمت الصفحة): التليفون نفسه هو المفتاح، ومنه
/// يستخرج السيرفر اسم العضو الكامل ومعرّفه وقريته.
library;

import '../domain/farah_models.dart';

/// أنواع فشل عمليات «فرح» — تُحدَّد في طبقة البيانات وتُعرض في الواجهة.
enum FarahErrorKind {
  /// التليفون غير مسجَّل في `members` — عليه التسجيل في صفحة القرية.
  notRegistered,

  /// بيانات مرفوضة (تحقّق السيرفر).
  invalid,

  /// نفد حدّ الإرسال (يومي للمدعو، أو لكل مدعو لصاحب الفرح).
  limitReached,

  /// الطرف الآخر غير موجود في القرية.
  notFound,

  /// تعذّر الوصول للشبكة.
  network,

  /// الخدمة غير مُهيّأة (لا مفاتيح Supabase).
  unavailable,

  /// خطأ غير متوقّع.
  unknown,
}

/// استثناء موحّد لكل أخطاء «فرح»، برسالة عربية جاهزة للعرض.
class FarahException implements Exception {
  const FarahException(this.kind, this.message, {this.cause});

  final FarahErrorKind kind;
  final String message;
  final Object? cause;

  @override
  String toString() => 'FarahException(${kind.name}): $message';
}

/// واجهة مستودع «فرح».
abstract interface class FarahRepository {
  /// هل الخدمة متاحة للاستخدام (مفاتيح مضبوطة وعميل جاهز)؟
  bool get isAvailable;

  /// الدخول بتليفون العضو — يُرمي [FarahException] بنوع `notRegistered` إن
  /// لم يكن الرقم في `members`.
  Future<FarahSession> login(String phone);

  /// أهل القرية (بما فيهم صاحب الفرح بعلامة مميّزة).
  Future<List<FarahMember>> fetchMembers(String phone);

  /// قائمة المحادثات: اسم كل أهل القرية + آخر رسالة + المتبقي من الحدّ.
  Future<List<FarahConversation>> fetchConversations(String phone);

  /// سلسلة رسائل محادثة واحدة (الأحدث أخيراً للعرض).
  Future<List<FarahMessage>> fetchThread({
    required String phone,
    required String partnerId,
  });

  /// ما تبقّى من حدّ الإرسال إلى هذا المدعو.
  Future<FarahAllowance> fetchAllowance({
    required String phone,
    required String partnerId,
  });

  /// إرسال رسالة — تُرمي [FarahException] بنوع `limitReached` عند نفاد الحدّ.
  Future<FarahSendResult> sendMessage({
    required String phone,
    required String partnerId,
    required String body,
  });

  /// تفعيل كود صاحب الفرح.
  Future<bool> activateLicense({
    required String phone,
    required String code,
  });
}
