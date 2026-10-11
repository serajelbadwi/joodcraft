/// عقد الوصول إلى بيانات القرية — مستقلّ تماماً عن مزوّد الخدمة.
///
/// الواجهة (الشاشة) لا تعرف Supabase ولا PostgREST: تتحدّث مع هذه الواجهة فقط،
/// فيمكن اختبار التدفّق كاملاً بمستودع وهمي في الذاكرة بلا شبكة.
library;

import '../domain/village.dart';
import '../domain/village_video.dart';

/// أنواع فشل عمليات القرية — تُحدَّد في طبقة البيانات وتُعرض في الواجهة.
enum VillageErrorKind {
  /// كود القرية غير موجود.
  notFound,

  /// الرقم القومي مسجَّل من قبل (قيود `unique`).
  duplicate,

  /// بيانات مرفوضة (تحقّق السيرفر).
  invalid,

  /// تعذّر الوصول للشبكة.
  network,

  /// الخدمة غير مُهيّأة (لا مفاتيح Supabase).
  unavailable,

  /// خطأ غير متوقّع.
  unknown,
}

/// استثناء موحّد لكل أخطاء القرية، برسالة عربية جاهزة للعرض.
class VillageException implements Exception {
  const VillageException(this.kind, this.message, {this.cause});

  final VillageErrorKind kind;
  final String message;
  final Object? cause;

  @override
  String toString() => 'VillageException(${kind.name}): $message';
}

/// واجهة مستودع القرية.
abstract interface class VillageRepository {
  /// هل الخدمة متاحة للاستخدام (مفاتيح مضبوطة وعميل جاهز)؟
  bool get isAvailable;

  /// يبحث عن قرية بكودها — يُعيد `null` إن لم يوجد الكود.
  Future<Village?> lookupVillage(String code);

  /// يسجّل عضواً جديداً في القرية ويعيد معرّفه، أو يرمي [VillageException].
  Future<String> registerMember({
    required String villageCode,
    required String name,
    required String phone,
    required String nationalId,
  });

  /// فيديوهات القرية **المنشورة** (الأحدث أولاً) — قد تعود قائمة فارغة إن كان
  /// الكود غير معروف أو لم يُنشر فيديو بعد، وتُرمي [VillageException] عند فشل
  /// الشبكة. قسم الفيديوهات زينة: أي فشل يعني عدم ظهوره لا عطلاً في الصفحة.
  Future<List<VillageVideo>> fetchVideos({required String villageCode});
}
