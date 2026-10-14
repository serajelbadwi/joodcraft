/// تنفيذ المستودع فوق Supabase.
///
/// القراءة المباشرة من جدول `domains` (سياسة RLS تكفي)، والإنشاء عبر دالة
/// `security definer` في `supabase_domains.sql` لأنها تولّد الكود وتفحص
/// `is_platform_admin()`.
library;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/supabase_service.dart';
import '../domain/domain.dart';
import 'domain_repository.dart';

class SupabaseDomainRepository implements DomainRepository {
  const SupabaseDomainRepository([SupabaseClient? client]) : _client = client;

  /// عميل مُحقن للاختبارات؛ وإلا عميل التطبيق المهيّأ.
  final SupabaseClient? _client;

  SupabaseClient get _supabase => _client ?? SupabaseService.client;

  @override
  bool get isAvailable => _client != null || SupabaseService.isInitialized;

  @override
  Future<List<Domain>> fetchDomains() async {
    try {
      final dynamic rows = await _supabase
          .from('domains')
          .select(
            'id, name_ar, name_en, code, governorate, center, '
            'postal_code, plus_code, latitude, longitude',
          )
          .order('name_ar');
      return _rows(rows).map(Domain.fromRow).toList(growable: false);
    } catch (fallbackError) {
      // الأعمدة الجديدة قد لا تزال غائبة: نسقط للحد الأدنى ونبقى عمّالين.
      try {
        final dynamic rows = await _supabase
            .from('domains')
            .select('id, name_ar, name_en, code')
            .order('name_ar');
        return _rows(rows).map(Domain.fromRow).toList(growable: false);
      } catch (_) {
        throw _map(fallbackError, fallback: 'تعذّر جلب النطاقات');
      }
    }
  }

  @override
  Future<String> createDomain({
    required String nameAr,
    required String nameEn,
    required String governorate,
    required String center,
    String? postalCode,
    String? plusCode,
    double? latitude,
    double? longitude,
  }) async {
    // معاملات الدالة: المطلوب أولاً ثم الاختياري إن وُجد.
    final Map<String, dynamic> params = <String, dynamic>{
      'p_name_ar': nameAr.trim(),
      'p_name_en': nameEn.trim(),
      'p_gov': governorate.trim(),
      'p_center': center.trim(),
    };
    final String postal = (postalCode ?? '').trim();
    if (postal.isNotEmpty) params['p_postal'] = postal;
    final String plus = (plusCode ?? '').trim();
    if (plus.isNotEmpty) params['p_plus_code'] = plus;
    if (latitude != null) params['p_lat'] = latitude;
    if (longitude != null) params['p_lng'] = longitude;

    try {
      final dynamic response = await _supabase.rpc(
        'owner_generate_domain_code',
        params: params,
      );
      if (response == null) {
        throw const DomainAdminException('تعذّر إنشاء النطاق');
      }
      return '$response';
    } catch (error) {
      throw _map(error, fallback: 'تعذّر إنشاء النطاق');
    }
  }

  @override
  Future<void> updateDomain({
    required String id,
    String? nameAr,
    String? governorate,
  }) async {
    final Map<String, dynamic> patch = <String, dynamic>{
      if (nameAr != null && nameAr.trim().isNotEmpty) 'name_ar': nameAr.trim(),
      if (governorate != null && governorate.trim().isNotEmpty)
        'governorate': governorate.trim(),
    };
    if (patch.isEmpty) return;
    try {
      await _supabase.from('domains').update(patch).eq('id', id);
    } catch (error) {
      throw _map(error, fallback: 'تعذّر حفظ التعديلات');
    }
  }

  @override
  Future<void> deleteDomain(String id) async {
    try {
      await _supabase.from('domains').delete().eq('id', id);
    } catch (error) {
      throw _map(error, fallback: 'تعذّر حذف النطاق');
    }
  }

  // --------------------------------------------------------------------------

  /// صفوف الاستجابة — تصل قائمة أو `null`.
  static List<Map<String, dynamic>> _rows(dynamic response) {
    if (response is! List) return const <Map<String, dynamic>>[];
    return response
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
  }

  /// رسالة عربية للواجهة: خطأ الخادم كما هو إن جاء عربياً (استثناء دوال
  /// `raise exception`)، وإلا رمز مفهوم أو الرمز الافتراضي.
  static DomainAdminException _map(
    Object error, {
    required String fallback,
  }) {
    if (error is DomainAdminException) return error;
    if (error is PostgrestException) {
      final String message = error.message;
      if (message.isNotEmpty && _looksArabic(message)) {
        return DomainAdminException(message);
      }
      if (error.code == '42501') {
        return const DomainAdminException('غير مصرَّح بهذا الإجراء');
      }
      if (error.code == '23505') {
        return const DomainAdminException('هذا الكود مستخدم لنطاق آخر');
      }
      if (error.code == '23514') {
        return const DomainAdminException('صيغة الكود غير مسموحة');
      }
    }
    return DomainAdminException(fallback);
  }

  static bool _looksArabic(String text) {
    for (final int rune in text.runes) {
      if (rune >= 0x0600 && rune <= 0x06FF) return true;
    }
    return false;
  }
}
