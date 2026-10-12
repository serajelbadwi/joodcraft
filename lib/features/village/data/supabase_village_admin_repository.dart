/// تنفيذ [VillageAdminRepository] فوق Supabase — قراءة مباشرة من الجداول
/// وكتابة مباشرة، وكل امتياز مفروض على السيرفر بسياسات RLS ودالة
/// `is_platform_admin` (الصفحة العامة لا تملك مفتاح `service_role` إطلاقاً).
///
/// لماذا بدون دوال (RPC) للكتابة؟ لأن صاحب المكتب مستخدم `authenticated`
/// عادي: سياسات `*_platform` تفتح صفوف كل القرى على من يملك صفّه في
/// `platform_admins`، فيكفي PostgREST مع رفض أي صف لم يُصرَّح به. وحيد
/// الاستثناءات `admin_overview()` (عدّادات كل القرى في نداء واحد) و
/// `is_platform_admin()`، وهما ما يُستدعى من هنا بـ `rpc`.
library;

import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/supabase_service.dart';
import '../domain/google_drive_link.dart';
import '../domain/village.dart';
import '../domain/village_ad.dart';
import '../domain/village_admin_overview.dart';
import '../domain/village_admin_text.dart';
import '../domain/village_code.dart';
import '../domain/village_member.dart';
import '../domain/village_validators.dart';
import '../domain/village_video.dart';
import 'village_admin_repository.dart';
import 'village_repository.dart';

/// مستودع اللوحة فوق Supabase — يُبنى بلا معامل في التطبيق الحقيقي
/// (يقرأ `SupabaseService.client`)، وبمعامل وهمي/موصى في الاختبارات.
class SupabaseVillageAdminRepository implements VillageAdminRepository {
  /// مستودع اللوحة — يُبنى هنا إن لم يُمرَّر (التطبيق الحقيقي)، ووهمي في
  /// الاختبارات.
  const SupabaseVillageAdminRepository([SupabaseClient? client])
      : _client = client;

  final SupabaseClient? _client;

  // ------------- مرجع أسماء الجداول والدوال (يطابق SQL) -------------
  static const String villagesTable = 'villages';
  static const String membersTable = 'members';
  static const String videosTable = 'videos';
  static const String adsTable = 'local_ads';
  static const String overviewFunction = 'admin_overview';
  static const String platformAdminFunction = 'is_platform_admin';
  static const String adsBucket = 'village-ads';

  static const String _villageColumns = 'id, name, code, created_at';
  static const String _memberColumns =
      'id, village_id, name, phone, national_id, birth_date, age, created_at';
  static const String _videoColumnsBase =
      'id, village_id, title, youtube_url, youtube_id, description, '
      'published_at, created_at';
  static const String _videoColumns = '$_videoColumnsBase, aspect_ratio';
  static const String _adColumns =
      'id, village_id, title, image_url, contact_phone, contact_url, '
      'starts_at, ends_at, is_active, created_at';

  SupabaseClient get _supabase => _client ?? SupabaseService.client;

  @override
  bool get isAvailable => _client != null || SupabaseService.isInitialized;

  @override
  bool get isSignedIn => isAvailable && _supabase.auth.currentSession != null;

  // ------------------------------ المصادقة ------------------------------
  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    _ensureAvailable();
    try {
      await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
    } catch (error) {
      throw error is VillageException ? error : _mapAuth(error);
    }
  }

  @override
  Future<void> signOut() async {
    if (!isAvailable) return;
    try {
      await _supabase.auth.signOut();
    } on Object {
      // خروج صامت: فشل الشبكة لا يمنع العودة لشاشة الدخول.
    }
  }

  @override
  Future<bool> isPlatformAdmin() async {
    _ensureAvailable();
    if (_supabase.auth.currentSession == null) return false;
    try {
      final dynamic response = await _supabase.rpc(platformAdminFunction);
      return response == true;
    } catch (error) {
      throw error is VillageException ? error : _map(error);
    }
  }

  // ------------------------------ القرى ------------------------------
  @override
  Future<List<VillageAdminOverview>> fetchOverviews() async {
    _ensureAvailable();
    try {
      final dynamic response = await _supabase.rpc(overviewFunction);
      final List<VillageAdminOverview> items = <VillageAdminOverview>[];
      if (response is List) {
        for (final Object? row in response) {
          if (row is Map) {
            items.add(
              VillageAdminOverview.fromRow(Map<String, dynamic>.from(row)),
            );
          }
        }
      }
      return items;
    } catch (error) {
      throw error is VillageException ? error : _map(error);
    }
  }

  @override
  Future<Village> createVillage({
    required String name,
    required String code,
  }) async {
    _ensureAvailable();
    try {
      final Map<String, dynamic> row = await _supabase
          .from(villagesTable)
          .insert(<String, dynamic>{
            'name': name.trim(),
            'code': VillageCode.canonical(code),
          })
          .select(_villageColumns)
          .single();
      return Village.fromRow(row);
    } catch (error) {
      throw error is VillageException ? error : _map(error);
    }
  }

  // ------------------------------ الأعضاء ------------------------------
  @override
  Future<List<VillageMember>> fetchMembers({
    required String villageId,
  }) async {
    _ensureAvailable();
    try {
      final List<Map<String, dynamic>> rows = await _supabase
          .from(membersTable)
          .select(_memberColumns)
          .eq('village_id', villageId)
          .order('created_at', ascending: false);
      return rows
          .map(VillageMember.fromRow)
          .toList(growable: false);
    } catch (error) {
      throw error is VillageException ? error : _map(error);
    }
  }

  @override
  Future<void> deleteMember({required String memberId}) async {
    _ensureAvailable();
    try {
      await _supabase.from(membersTable).delete().eq('id', memberId);
    } catch (error) {
      throw error is VillageException ? error : _map(error);
    }
  }

  // ------------------------------ الفيديوهات ------------------------------
  @override
  Future<List<VillageVideo>> fetchVideos({
    required String villageId,
  }) async {
    _ensureAvailable();
    try {
      final List<Map<String, dynamic>> rows = await _selectVideoRows(villageId);
      // اللوحة ترى **كل** الصفوف (بما فيها المجدولة) — بعكس الصفحة العامة.
      return rows.map(VillageVideo.fromRow).toList(growable: false);
    } catch (error) {
      throw error is VillageException ? error : _map(error);
    }
  }

  /// جلب صفوف فيديوهات القرية — وإن غاب عمود `aspect_ratio` (قبل تشغيل سطر
  /// `alter table`) يُعاد الطلب بالأعمدة القديمة.
  Future<List<Map<String, dynamic>>> _selectVideoRows(String villageId) async {
    try {
      return await _supabase
          .from(videosTable)
          .select(_videoColumns)
          .eq('village_id', villageId)
          .order('created_at', ascending: false);
    } catch (error) {
      if (!'$error'.contains('aspect_ratio')) rethrow;
      return await _supabase
          .from(videosTable)
          .select(_videoColumnsBase)
          .eq('village_id', villageId)
          .order('created_at', ascending: false);
    }
  }

  @override
  Future<VillageVideo> saveVideo({
    String? id,
    required String villageId,
    required String title,
    required String youtubeUrl,
    String? description,
  }) async {
    _ensureAvailable();
    final String url = youtubeUrl.trim();
    final String? extracted = VillageYoutube.idFromUrl(url);
    if (extracted == null) {
      throw const VillageException(
        VillageErrorKind.invalid,
        VillageAdminText.videoIdMissing,
      );
    }
    // نرسل المعرّف صراحةً: يبقى صالحاً إن غاب المُشغّل `videos_fill_youtube_id`
    // على السيرفر، ويقبله المُشغّل حين موجوداً (يطابقه ثم يطبّع الرابط).
    // ونسبة الأبعاد تُشتقّ من صيغة الرابط: shorts/live ⇒ 9:16 وما عداها 16:9.
    final Map<String, dynamic> payload = <String, dynamic>{
      'village_id': villageId,
      'title': title.trim(),
      'youtube_url': url,
      'youtube_id': extracted,
      'aspect_ratio': VillageVideoAspect.fromYoutubeUrl(url).label,
      'description': (description ?? '').trim().isEmpty
          ? null
          : description!.trim(),
    };
    try {
      return VillageVideo.fromRow(await _saveVideoRow(
        id: id,
        payload: payload,
      ));
    } catch (error) {
      // عمود `aspect_ratio` لم يُنشأ بعد (لم يُشغَّل سطر `alter table`) —
      // نُسقط المفتاح ونعيد المحاولة، والنسبة تُشتقّ من الرابط في النموذج.
      if ('$error'.contains('aspect_ratio')) {
        final Map<String, dynamic> legacy =
            Map<String, dynamic>.of(payload)..remove('aspect_ratio');
        return VillageVideo.fromRow(
          await _saveVideoRow(id: id, payload: legacy, legacyColumns: true),
        );
      }
      throw error is VillageException ? error : _map(error);
    }
  }

  /// إدراج أو تعديل صف فيديو وإعادته بالأعمدة المطلوبة.
  Future<Map<String, dynamic>> _saveVideoRow({
    required String? id,
    required Map<String, dynamic> payload,
    bool legacyColumns = false,
  }) async {
    final String columns = legacyColumns ? _videoColumnsBase : _videoColumns;
    if (id == null || id.isEmpty) {
      return _supabase
          .from(videosTable)
          .insert(payload)
          .select(columns)
          .single();
    }
    return _supabase
        .from(videosTable)
        .update(payload)
        .eq('id', id)
        .select(columns)
        .single();
  }

  @override
  Future<void> deleteVideo({required String videoId}) async {
    _ensureAvailable();
    try {
      await _supabase.from(videosTable).delete().eq('id', videoId);
    } catch (error) {
      throw error is VillageException ? error : _map(error);
    }
  }

  // ------------------------------ الإعلانات ------------------------------
  @override
  Future<List<VillageAd>> fetchAds({required String villageId}) async {
    _ensureAvailable();
    try {
      final List<Map<String, dynamic>> rows = await _supabase
          .from(adsTable)
          .select(_adColumns)
          .eq('village_id', villageId)
          .order('created_at', ascending: false);
      return rows.map(VillageAd.fromRow).toList(growable: false);
    } catch (error) {
      throw error is VillageException ? error : _map(error);
    }
  }

  @override
  Future<VillageAd> saveAd({
    String? id,
    required String villageId,
    required String title,
    String? imageUrl,
    String? contactPhone,
    String? contactUrl,
    DateTime? startsAt,
    DateTime? endsAt,
    required bool isActive,
  }) async {
    _ensureAvailable();
    // بناء الصف في النموذج نفسه: ترميز التواريخ وتنقية الحقول في موضع واحد.
    // رابط Google Drive يُطبَّع إلى صيغة صورة مباشرة قبل الكتابة، فلا يُخزَّن
    // في القاعدة إلا رابط جاهز للعرض في `Image.network`.
    final Map<String, dynamic> payload = VillageAd(
      id: '',
      villageId: villageId,
      title: title.trim(),
      imageUrl: normalizeGoogleDriveUrl(imageUrl ?? ''),
      contactPhone: (contactPhone ?? '').trim().isEmpty
          ? null
          : contactPhone!.trim(),
      contactUrl: (contactUrl ?? '').trim().isEmpty
          ? null
          : contactUrl!.trim(),
      startsAt: startsAt,
      endsAt: endsAt,
      isActive: isActive,
    ).toRow();
    try {
      if (id == null || id.isEmpty) {
        final Map<String, dynamic> row = await _supabase
            .from(adsTable)
            .insert(payload)
            .select(_adColumns)
            .single();
        return VillageAd.fromRow(row);
      }
      final Map<String, dynamic> row = await _supabase
          .from(adsTable)
          .update(payload)
          .eq('id', id)
          .select(_adColumns)
          .single();
      return VillageAd.fromRow(row);
    } catch (error) {
      throw error is VillageException ? error : _map(error);
    }
  }

  @override
  Future<void> deleteAd({required String adId}) async {
    _ensureAvailable();
    try {
      await _supabase.from(adsTable).delete().eq('id', adId);
    } catch (error) {
      throw error is VillageException ? error : _map(error);
    }
  }

  @override
  Future<String> uploadAdImage({
    required String villageId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    _ensureAvailable();
    try {
      final String safe = fileName
          .trim()
          .replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
      final String path =
          '$villageId/${DateTime.now().millisecondsSinceEpoch}-$safe';
      await _supabase.storage.from(adsBucket).uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: _contentType(safe)),
          );
      return _supabase.storage.from(adsBucket).getPublicUrl(path);
    } catch (error) {
      throw error is VillageException ? error : _map(error);
    }
  }

  /// نوع المحتوى من امتداد الصورة (لرفعها بترميز سليم).
  String _contentType(String fileName) {
    final String lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.bmp')) return 'image/bmp';
    return 'image/jpeg';
  }

  // ----------------------------- تتبّع الأخطاء -----------------------------
  void _ensureAvailable() {
    if (!isAvailable) {
      throw const VillageException(
        VillageErrorKind.unavailable,
        VillageText.serviceTitle,
      );
    }
  }

  /// أخطاء المصادقة برسائل عربية (رسائل Supabase إنجليزية).
  VillageException _mapAuth(Object error) {
    if (error is AuthException) {
      final String text = error.message.toLowerCase();
      if (text.contains('invalid login credentials')) {
        return VillageException(
          VillageErrorKind.invalid,
          VillageAdminText.invalidCredentials,
          cause: error,
        );
      }
      if (text.contains('email not confirmed')) {
        return VillageException(
          VillageErrorKind.invalid,
          VillageAdminText.emailNotConfirmed,
          cause: error,
        );
      }
      if (_isNetworkText(text)) {
        return VillageException(
          VillageErrorKind.network,
          VillageAdminText.networkError,
          cause: error,
        );
      }
      return VillageException(
        VillageErrorKind.invalid,
        VillageAdminText.signInFailed,
        cause: error,
      );
    }
    return _map(error);
  }

  /// يحوّل أي خطأ إلى [VillageException] برسالة عربية جاهزة للعرض.
  VillageException _map(Object error) {
    if (error is PostgrestException) {
      switch (error.code) {
        // قيد unique (كود قرية مكرّر).
        case '23505':
          return VillageException(
            VillageErrorKind.duplicate,
            VillageAdminText.codeInUse,
            cause: error,
          );
        // يرفض RLS الصف (لا سياسة تسمح) أو صلاحية غير كافية.
        case '42501':
          return VillageException(
            VillageErrorKind.invalid,
            VillageAdminText.notAuthorized,
            cause: error,
          );
        // انتهت جلسة الدخول.
        case 'PGRST301':
          return VillageException(
            VillageErrorKind.invalid,
            VillageAdminText.sessionExpired,
            cause: error,
          );
        // رفض تحقّق السيرفر (رسالة عربية جاهزة من الدالة/المُشغّل).
        case 'P0001':
        case 'P0002':
          return VillageException(
            VillageErrorKind.invalid,
            _serverMessage(error),
            cause: error,
          );
        default:
          final String joined =
              '${error.message} ${error.details} ${error.hint}';
          return VillageException(
            _isNetworkText(joined)
                ? VillageErrorKind.network
                : VillageErrorKind.unknown,
            _isNetworkText(joined)
                ? VillageAdminText.networkError
                : VillageAdminText.genericError,
            cause: error,
          );
      }
    }
    if (error is AuthException) {
      if (_isNetworkText(error.message)) {
        return VillageException(
          VillageErrorKind.network,
          VillageAdminText.networkError,
          cause: error,
        );
      }
      return VillageException(
        VillageErrorKind.unknown,
        VillageAdminText.genericError,
        cause: error,
      );
    }
    if (_isNetworkText(error.toString())) {
      return VillageException(
        VillageErrorKind.network,
        VillageAdminText.networkError,
        cause: error,
      );
    }
    return VillageException(
      VillageErrorKind.unknown,
      VillageAdminText.genericError,
      cause: error,
    );
  }

  /// رسالة السيرفر إن كانت عربية ومفيدة، وإلا الرسالة العامة.
  String _serverMessage(PostgrestException error) {
    final String message = error.message.trim();
    final bool hasArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(message);
    if (hasArabic && message.length > 3) return message;
    return VillageAdminText.genericError;
  }

  /// كشف أخطاء الشبكة بنصوصها الشائعة (الويب لا يوفّر `SocketException`).
  bool _isNetworkText(String text) {
    final String value = text.toLowerCase();
    return value.contains('failed to fetch') ||
        value.contains('socketexception') ||
        value.contains('clientexception') ||
        value.contains('network') ||
        value.contains('connection') ||
        value.contains('timeout');
  }
}
