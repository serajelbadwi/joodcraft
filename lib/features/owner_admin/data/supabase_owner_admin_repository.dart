/// تنفيذ المستودع فوق Supabase — يُستدعى من بوابة اللوحة في التطبيق.
///
/// القراءة المباشرة من الجداول (سياسات RLS تكفي: `villages_manage_platform`
/// و`licenses_select_platform`)، والإنشاء عبر دوال `security definer` في
/// `supabase_village.sql` لأنها تولّد الأكواد وتفحص `is_platform_admin()`.
library;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/supabase_service.dart';
import '../domain/owner_models.dart';
import 'owner_admin_repository.dart';

class SupabaseOwnerAdminRepository implements OwnerAdminRepository {
  const SupabaseOwnerAdminRepository([SupabaseClient? client])
    : _client = client;

  /// عميل مُحقن للاختبارات الإنشائية؛ وإلا عميل التطبيق المهيّأ.
  final SupabaseClient? _client;

  SupabaseClient get _supabase => _client ?? SupabaseService.client;

  @override
  bool get isAvailable => _client != null || SupabaseService.isInitialized;

  @override
  bool get isSignedIn {
    if (_client != null) return _client.auth.currentSession != null;
    return isAvailable && SupabaseService.currentSession != null;
  }

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _supabase.auth.signInWithPassword(email: email, password: password);
    } catch (error) {
      throw _map(error, fallback: 'تعذّر تسجيل الدخول — راجع البيانات');
    }
  }

  @override
  Future<bool> isPlatformAdmin() async {
    if (!isSignedIn) return false;
    try {
      // RLS لا تُعيد صفّاً إلا لصاحب الصلاحية — غياب الصف يعني «لا».
      final dynamic row = await _supabase
          .from('platform_admins')
          .select('user_id')
          .limit(1)
          .maybeSingle();
      return row != null;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<OwnerVillage>> fetchVillages() async {
    try {
      final dynamic rows = await _supabase
          .from('villages')
          .select('id, name, name_en, code, governorate, center')
          .order('name');
      return _rows(rows)
          .map(OwnerVillage.fromRow)
          .toList(growable: false);
    } catch (error) {
      // أعمدة قسم 20 قد لا تزال غائبة: نسقط للاسم والكود ونبقى عمّالاً.
      try {
        final dynamic rows = await _supabase
            .from('villages')
            .select('id, name, code')
            .order('name');
        return _rows(rows)
            .map(OwnerVillage.fromRow)
            .toList(growable: false);
      } catch (fallbackError) {
        throw _map(fallbackError, fallback: 'تعذّر جلب القرى');
      }
    }
  }

  @override
  Future<Map<String, int>> fetchMemberCounts() async {
    try {
      final dynamic rows = await _supabase.from('members').select('village_id');
      final Map<String, int> counts = <String, int>{};
      for (final Map<String, dynamic> row in _rows(rows)) {
        final Object? villageId = row['village_id'];
        if (villageId == null) continue;
        final String key = '$villageId';
        counts[key] = (counts[key] ?? 0) + 1;
      }
      return counts;
    } catch (_) {
      // العدّ تحسّلي — فشله لا يمنع إدارة القرى.
      return const <String, int>{};
    }
  }

  @override
  Future<String> createVillage({
    required String nameAr,
    required String nameEn,
    required String governorate,
    required String center,
    String? postalCode,
    String? plusCode,
  }) async {
    try {
      final dynamic response = await _supabase.rpc(
        'owner_generate_village_code',
        params: <String, dynamic>{
          'p_name_ar': nameAr.trim(),
          'p_name_en': nameEn.trim(),
          'p_gov': governorate.trim(),
          'p_center': center.trim(),
          if (postalCode != null && postalCode.trim().isNotEmpty)
            'p_postal': postalCode.trim(),
          if (plusCode != null && plusCode.trim().isNotEmpty)
            'p_plus_code': plusCode.trim(),
        },
      );
      if (response == null) {
        throw const OwnerAdminException('تعذّر إنشاء القرية');
      }
      return '$response';
    } catch (error) {
      throw _map(error, fallback: 'تعذّر إنشاء القرية');
    }
  }

  @override
  Future<void> updateVillage({
    required String id,
    String? name,
    String? code,
    String? governorate,
  }) async {
    final Map<String, dynamic> patch = <String, dynamic>{
      if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
      if (code != null && code.trim().isNotEmpty)
        'code': code.trim().toUpperCase(),
      if (governorate != null && governorate.trim().isNotEmpty)
        'governorate': governorate.trim(),
    };
    if (patch.isEmpty) return;
    try {
      await _supabase.from('villages').update(patch).eq('id', id);
    } catch (error) {
      throw _map(error, fallback: 'تعذّر حفظ التعديلات');
    }
  }

  @override
  Future<void> deleteVillage(String id) async {
    try {
      await _supabase.from('villages').delete().eq('id', id);
    } catch (error) {
      throw _map(error, fallback: 'تعذّر حذف القرية');
    }
  }

  @override
  Future<List<OwnerLicense>> fetchLicenses() async {
    try {
      final dynamic rows = await _supabase
          .from('farah_licenses')
          .select(
            'id, code, village_id, subscriber_name, subscriber_phone, '
            'months, is_active, created_at',
          )
          .order('created_at', ascending: false);
      final List<OwnerLicense> licenses = _rows(rows)
          .map(OwnerLicense.fromRow)
          .toList(growable: false);

      // أسماء القرى من جدول منفصل — بساطة على المحلّل من join متداخل.
      final dynamic villages = await _supabase
          .from('villages')
          .select('id, name');
      final Map<String, String> names = <String, String>{
        for (final Map<String, dynamic> row in _rows(villages))
          '${row['id']}': '${row['name'] ?? ''}',
      };
      return licenses
          .map(
            (OwnerLicense license) =>
                license.copyWith(villageName: names[license.villageId]),
          )
          .toList(growable: false);
    } catch (error) {
      throw _map(error, fallback: 'تعذّر جلب التراخيص');
    }
  }

  @override
  Future<String> createLicense({
    required String villageId,
    required String subscriberName,
    required String phone,
    required int months,
  }) async {
    try {
      final dynamic response = await _supabase.rpc(
        'owner_create_license',
        params: <String, dynamic>{
          'p_village_id': villageId,
          'p_name': subscriberName.trim(),
          'p_phone': phone.trim(),
          'p_months': months,
        },
      );
      if (response == null) {
        throw const OwnerAdminException('تعذّر إصدار الترخيص');
      }
      return '$response';
    } catch (error) {
      throw _map(error, fallback: 'تعذّر إصدار الترخيص');
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
  /// `raise exception`)، وإلا الرمز الافتراضي.
  static OwnerAdminException _map(Object error, {required String fallback}) {
    if (error is OwnerAdminException) return error;
    if (error is PostgrestException) {
      final String message = error.message;
      if (message.isNotEmpty && _looksArabic(message)) {
        return OwnerAdminException(message);
      }
      // انتهاك صلاحية/قيود يحمل رمزاً مفهوماً.
      if (error.code == '42501') {
        return const OwnerAdminException('غير مصرَّح بهذا الإجراء');
      }
      if (error.code == '23505') {
        return const OwnerAdminException('هذا الكود مستخدم لقرية أخرى');
      }
      if (error.code == '23514') {
        return const OwnerAdminException('صيغة الكود غير مسموحة');
      }
    }
    if (error is AuthException) {
      return const OwnerAdminException('بيانات الدخول غير صحيحة');
    }
    return OwnerAdminException(fallback);
  }

  static bool _looksArabic(String text) {
    for (final int rune in text.runes) {
      if (rune >= 0x0600 && rune <= 0x06FF) return true;
    }
    return false;
  }
}
