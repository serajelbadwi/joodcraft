/// عقد الوصول إلى بيانات النطاقات — مستقلّ تماماً عن مزوّد الخدمة.
///
/// الشاشات لا تعرف Supabase ولا PostgREST: تتحدّث مع هذه الواجهة وحدها،
/// فيمكن اختبار التدفّق كاملاً بمستودع وهمي في الذاكرة بلا شبكة.
library;

import '../domain/domain.dart';

/// خطأ مُترجم ترفعه مستودعات النطاقات — رسالته عربية جاهزة للعرض.
class DomainAdminException implements Exception {
  const DomainAdminException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract interface class DomainRepository {
  /// هل خدمة Supabase مهيّأة أصلاً (مفاتيح صحيحة)؟
  bool get isAvailable;

  /// كل النطاقات — للأعمدة الجديدة اختيارية (قد لا يكون قسم SQL مُشغَّلاً).
  Future<List<Domain>> fetchDomains();

  /// إنشاء نطاق وتوليد كوده في القاعدة — يعيد الكود المولَّد.
  ///
  /// [postalCode] و[plusCode] و[latitude] و[longitude] اختيارية: الكود
  /// يُبنى من بادئة الاسم الإنجليزي + الرمز البريدي + Plus Code.
  Future<String> createDomain({
    required String nameAr,
    required String nameEn,
    required String governorate,
    required String center,
    String? postalCode,
    String? plusCode,
    double? latitude,
    double? longitude,
  });

  /// تعديل الاسم العربي أو المحافظة — الحقول `null` تبقى كما هي.
  Future<void> updateDomain({
    required String id,
    String? nameAr,
    String? governorate,
  });

  Future<void> deleteDomain(String id);
}
