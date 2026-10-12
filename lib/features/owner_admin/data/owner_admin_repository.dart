/// واجهة مستودع لوحة تحكم المالك — الواجهة الوحيدة التي تعرفها الشاشات.
///
/// التطبيق يُحقن فيه [SupabaseOwnerAdminRepository]، والاختبارات بكائن وهمي
/// يحفظ في الذاكرة؛ فلا تُفتح أي شبكة في `flutter test`.
library;

import '../domain/owner_models.dart';

abstract class OwnerAdminRepository {
  /// هل خدمة Supabase مهيّأة أصلاً (مفاتيح صحيحة)؟
  bool get isAvailable;

  /// هل يوجد جلسة مستخدم مسجَّلة؟
  bool get isSignedIn;

  /// تسجيل دخول Supabase Auth — لبوابة اللوحة حين لا تكون جلسة قائمة.
  Future<void> signIn({required String email, required String password});

  /// هل الحساب الحالي صاحب المنصّة (له صفّ في `platform_admins`)؟
  /// فشل الاستعلام يعني «لا» — الحماية في النهاية سياسات RLS والدوال.
  Future<bool> isPlatformAdmin();

  /// كل القرى — للأعمدة الجديدة اختيارية (قد لا يزال قسم 20 غير مُشغَّل).
  Future<List<OwnerVillage>> fetchVillages();

  /// عدد الأعضاء لكل قرية (`villageId` ⇒ العدد).
  Future<Map<String, int>> fetchMemberCounts();

  /// إنشاء قرية توليد كودها الخادم — يعيد الكود المولَّد.
  ///
  /// [postalCode] و[plusCode] اختياريان: الأول الرمز البريدي، والثاني Plus
  /// Code كما يكتبه المستخدم (يُؤخذ جزؤه القبلي لعلامة `+`).
  Future<String> createVillage({
    required String nameAr,
    required String nameEn,
    required String governorate,
    required String center,
    String? postalCode,
    String? plusCode,
  });

  /// تعديل الاسم أو الكود أو المحافظة — الحقول `null` تبقى كما هي.
  Future<void> updateVillage({
    required String id,
    String? name,
    String? code,
    String? governorate,
  });

  Future<void> deleteVillage(String id);

  /// التراخيص — تُرفق باسم القرية من جدول القرى.
  Future<List<OwnerLicense>> fetchLicenses();

  /// إصدار ترخيص بمدة [months] (1 أو 3 أو 12) — يعيد الكود `FRH-…`.
  Future<String> createLicense({
    required String villageId,
    required String subscriberName,
    required String phone,
    required int months,
  });
}
