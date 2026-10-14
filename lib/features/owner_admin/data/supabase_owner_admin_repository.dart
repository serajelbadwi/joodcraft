/// تنفيذ المستودع فوق Supabase — يُستدعى من بوابة اللوحة في التطبيق.
///
/// القراءة المباشرة من الجداول (سياسات RLS تكفي: `villages_manage_platform`
/// و`licenses_select_platform`)، والإنشاء عبر دوال `security definer` في
/// `supabase_village.sql` لأنها تولّد الأكواد وتفحص `is_platform_admin()`.
///
/// **سجلّ صريح:** كل نداء يُسجَّل عبر `debugPrint` — ما نُفِّذ، ورمز الخطأ
/// الخام ونصّه عند الفشل — كي يرى المالك السبب الحقيقي في الـConsole بلا
/// تخمين (كان `_map` يحوّل أي خطأ غير عربي إلى «تعذّر جلب…» فتُخفى أسبابه).
///
/// **تدرّج آمن:** صورة القاعدة تختلف بين مشروع ومشروع: قسم 20 من
/// `supabase_village.sql` (أعمدة المشترك على `farah_licenses` والأعمدة
/// الجغرافية على `villages`) قد لا يكون مُشغَّلاً بعد. فتُقرأ الأعمدة
/// **الأغنى أولاً** ثم تُتراجع إلى الأصلية، فتبقى اللوحة تعرض البيانات
/// المتاحة بدل شاشة خطأ — ورسالة الـSQL المطلوبة تُطبع في السجلّ.
library;

import 'package:flutter/foundation.dart';
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

  /// أعمدة لوحة المالك على التراخيص (قسم 20.2 من `supabase_village.sql`):
  /// بيانات المشترك والمدة. تُغيب في قاعدة لم يُشغَّل عليها القسم 20.
  static const String _licenseRichColumns =
      'id, code, village_id, subscriber_name, subscriber_phone, '
      'months, is_active, created_at';

  /// الأعمدة الأصلية للجدول (قسم 17) — موجودة في كل صور القاعدة.
  static const String _licenseBaseColumns =
      'id, code, village_id, is_active, created_at';

  /// أعمدة القرى بلوحة المالك (قسم 20.1) — قد تغيب قبل تشغيل القسم 20.
  static const String _villageRichColumns =
      'id, name, name_en, code, governorate, center';

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
      debugPrint('[owner-admin] signIn OK: ${email.trim()}');
    } catch (error) {
      _log('signIn', error);
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
      final bool admin = row != null;
      debugPrint('[owner-admin] isPlatformAdmin ⇒ $admin');
      return admin;
    } catch (error) {
      _log('isPlatformAdmin', error);
      return false;
    }
  }

  @override
  Future<List<OwnerVillage>> fetchVillages() async {
    try {
      final List<OwnerVillage> villages = await _readVillages(
        _villageRichColumns,
      );
      debugPrint('[owner-admin] fetchVillages ⇒ ${villages.length} قرية');
      return villages;
    } catch (error) {
      _log('fetchVillages (أعمدة اللوحة)', error);
      // أعمدة قسم 20 قد لا تزال غائبة: نسقط للاسم والكود ونبقى عمّالاً.
      try {
        final List<OwnerVillage> villages = await _readVillages(
          'id, name, code',
        );
        debugPrint(
          '[owner-admin] fetchVillages (أعمدة أصلية) ⇒ ${villages.length} قرية',
        );
        return villages;
      } catch (fallbackError) {
        _log('fetchVillages', fallbackError);
        throw _map(fallbackError, fallback: 'تعذّر جلب القرى');
      }
    }
  }

  Future<List<OwnerVillage>> _readVillages(String columns) async {
    final dynamic rows = await _supabase
        .from('villages')
        .select(columns)
        .order('name');
    return _rows(rows).map(OwnerVillage.fromRow).toList(growable: false);
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
      debugPrint('[owner-admin] fetchMemberCounts ⇒ ${counts.length} قرية');
      return counts;
    } catch (error) {
      // العدّ تحسّلي — فشله لا يمنع إدارة القرى.
      _log('fetchMemberCounts', error);
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
      debugPrint('[owner-admin] createVillage ⇒ $response');
      return '$response';
    } catch (error) {
      _log('createVillage', error);
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
      debugPrint('[owner-admin] updateVillage $id ⇒ ${patch.keys}');
    } catch (error) {
      _log('updateVillage', error);
      throw _map(error, fallback: 'تعذّر حفظ التعديلات');
    }
  }

  @override
  Future<void> deleteVillage(String id) async {
    try {
      await _supabase.from('villages').delete().eq('id', id);
      debugPrint('[owner-admin] deleteVillage $id ⇒ حُذفت');
    } catch (error) {
      _log('deleteVillage', error);
      throw _map(error, fallback: 'تعذّر حذف القرية');
    }
  }

  @override
  Future<List<OwnerLicense>> fetchLicenses() async {
    try {
      return await _loadLicenses();
    } on OwnerAdminException {
      rethrow;
    } catch (error) {
      _log('fetchLicenses', error);
      throw _map(error, fallback: 'تعذّر جلب التراخيص');
    }
  }

  /// يقرأ التراخيص بأغنى أعمدة ممكنة: أعمدة لوحة المالك أولاً (بيانات
  /// المشترك والمدة)، فإن غابت في القاعدة — أي لم يُشغَّل قسم 20 من
  /// `supabase_village.sql` — يُتراجع إلى الأعمدة الأصلية فتظهر التراخيص
  /// كما هي بدل شاشة «تعذّر جلب التراخيص».
  Future<List<OwnerLicense>> _loadLicenses() async {
    try {
      final List<OwnerLicense> licenses = await _readLicenses(
        _licenseRichColumns,
      );
      debugPrint('[owner-admin] fetchLicenses ⇒ ${licenses.length} ترخيص');
      return licenses;
    } catch (error) {
      _log('fetchLicenses (أعمدة لوحة المالك)', error);
      debugPrint(
        '[owner-admin] أعمدة المشترك مفقودة — نقرأ الأعمدة الأصلية. '
        'شغّل قسم 20 من supabase_village.sql لإظهار بيانات المشترك.',
      );
      return _readLicenses(_licenseBaseColumns);
    }
  }

  Future<List<OwnerLicense>> _readLicenses(String columns) async {
    final dynamic rows = await _supabase
        .from('farah_licenses')
        .select(columns)
        .order('created_at', ascending: false);
    final List<OwnerLicense> licenses = _rows(rows)
        .map(OwnerLicense.fromRow)
        .toList(growable: false);

    // أسماء القرى من جدول منفصل — بساطة على المحلّل من join متداخل،
    // وفشلها لا يمنع عرض التراخيص (يبقى الاسم «قرية محذوفة»).
    final Map<String, String> names = await _villageNames();
    return licenses
        .map(
          (OwnerLicense license) =>
              license.copyWith(villageName: names[license.villageId]),
        )
        .toList(growable: false);
  }

  Future<Map<String, String>> _villageNames() async {
    try {
      final dynamic villages = await _supabase
          .from('villages')
          .select('id, name');
      return <String, String>{
        for (final Map<String, dynamic> row in _rows(villages))
          '${row['id']}': '${row['name'] ?? ''}',
      };
    } catch (error) {
      _log('_villageNames', error);
      return const <String, String>{};
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
      debugPrint('[owner-admin] createLicense ⇒ $response');
      return '$response';
    } catch (error) {
      _log('createLicense', error);
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

  /// الخطأ الخام كما رآه العميل — يظهر في الـConsole قبل أي ترجمة، فلا
  /// يُخفى سبب الفشل خلف رسالة عربية عامة.
  static void _log(String where, Object error) {
    if (error is PostgrestException) {
      debugPrint(
        '[owner-admin] $where FAILED [${error.code}] ${error.message}',
      );
      return;
    }
    debugPrint('[owner-admin] $where FAILED: $error');
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
      switch (error.code) {
        case '42501':
          return const OwnerAdminException('غير مصرَّح بهذا الإجراء');
        case '23505':
          return const OwnerAdminException('هذا الكود مستخدم لقرية أخرى');
        case '23514':
          return const OwnerAdminException('صيغة الكود غير مسموحة');
        // عمود مفقود: قسم 20 من `supabase_village.sql` غير مُشغَّل.
        case '42703':
          return const OwnerAdminException(
            'أعمدة لوحة المالك مفقودة في القاعدة — شغّل قسم 20 من '
            'supabase_village.sql على مشروع Supabase',
          );
        // دالّة غير موجودة أو بمعاملات مختلفة — القسم 20 مفقود قديماً.
        case 'PGRST202':
          return const OwnerAdminException(
            'الدالة المطلوبة غير موجودة في القاعدة — شغّل قسم 20 من '
            'supabase_village.sql على مشروع Supabase',
          );
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
