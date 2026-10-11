/// تنفيذ [VillageRepository] فوق Supabase — دوال (RPC) لكل ما يتحقّق أو يُنشئ،
/// واستعلام مباشر من الجدول حيث القراءة العامة وحدها.
///
/// لماذا RPC؟ لأن الصفحة **عامة**: الزائر غير مسجَّل دخول، وسياسات RLS تمنع أي
/// وصول مباشر إلى `members` أو `villages` من دور `anon`. الدالتان
/// `village_lookup` و`village_register_member` تعملان بـ `security definer`
/// على السيرفر، فتُنجَز العمليتان المصرَّح بهما فقط: التحقق من الكود، وإدراج
/// عضو جديد بعد تحقّق كامل من الرقم القومي على السيرفر.
///
/// استثناء واحد هو جدول `videos`: قراءته عامة بسياسة `videos_select_public`
/// (الفيديو محتوى مُعلَن لا سرّاً)، فيكفي `select` بـ `village_id` — ويتبقّى
/// `village_lookup` حاملاً لتحويل الكود إلى معرّف القرية.
library;

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/supabase_service.dart';
import '../domain/village.dart';
import '../domain/village_code.dart';
import '../domain/village_validators.dart';
import '../domain/village_video.dart';
import 'village_repository.dart';

class SupabaseVillageRepository implements VillageRepository {
  SupabaseVillageRepository({SupabaseClient? client}) : _client = client;

  /// عميل مُمرَّر (للاختبارات) — وغيابه يعني استخدام العميل العام المُهيّأ.
  final SupabaseClient? _client;

  SupabaseClient get _supabase => _client ?? SupabaseService.client;

  @override
  bool get isAvailable => _client != null || SupabaseService.isInitialized;

  /// أسماء الدوال على السيرفر — مصدر واحد للحقيقة.
  static const String lookupFunction = 'village_lookup';
  static const String registerFunction = 'village_register_member';

  /// جدول الفيديوهات — قراءته عامة (سياسة `videos_select_public`).
  static const String videosTable = 'videos';

  /// أعمدة الفيديوهات المطلوبة — لا نسحب عموداً لا يُعرض.
  static const String _videoColumns =
      'id, title, youtube_url, youtube_id, description, published_at';

  @override
  Future<Village?> lookupVillage(String code) async {
    _ensureAvailable();
    final String canonical = VillageCode.canonical(code);
    debugPrint('[village] RPC $lookupFunction(p_code: "$canonical")');
    try {
      final dynamic response = await _supabase.rpc(
        lookupFunction,
        params: <String, dynamic>{'p_code': canonical},
      );
      final Map<String, dynamic>? row = _firstRow(response);
      debugPrint('[village] RPC $lookupFunction → ${row ?? 'null'}');
      if (row == null) return null;
      final Village village = Village.fromRow(row);
      return village.isUsable ? village : null;
    } catch (error) {
      // السجلّ يحمل الخطأ كما جاء من PostgREST قبل ترجمته لرسالة عربية.
      debugPrint('[village] RPC $lookupFunction FAILED: $error');
      throw error is VillageException ? error : _map(error);
    }
  }

  @override
  Future<String> registerMember({
    required String villageCode,
    required String name,
    required String phone,
    required String nationalId,
  }) async {
    _ensureAvailable();
    try {
      final dynamic response = await _supabase.rpc(
        registerFunction,
        params: <String, dynamic>{
          'p_code': VillageCode.canonical(villageCode),
          'p_name': name.trim(),
          'p_phone': VillageValidators.normalizeDigits(phone),
          'p_national_id': VillageValidators.normalizeDigits(nationalId),
        },
      );
      if (response == null) {
        throw const VillageException(
          VillageErrorKind.unknown,
          VillageText.genericError,
        );
      }
      return '$response';
    } catch (error) {
      throw error is VillageException ? error : _map(error);
    }
  }

  @override
  Future<List<VillageVideo>> fetchVideos({required String villageCode}) async {
    _ensureAvailable();
    try {
      // (أ) معرّف القرية — الجدول مفهرس بـ village_id لا بالكود.
      final String? villageId = await _lookupVillageId(villageCode);
      if (villageId == null) return const <VillageVideo>[];

      // (ب) قراءة مباشرة من الجدول (سياسة القراءة العامة) — لا دالة ولا دور.
      final List<Map<String, dynamic>> rows = await _supabase
          .from(videosTable)
          .select(_videoColumns)
          .eq('village_id', villageId)
          .order('published_at', ascending: false);

      final List<VillageVideo> videos = <VillageVideo>[];
      for (final Map<String, dynamic> row in rows) {
        final VillageVideo video = VillageVideo.fromRow(row);
        // صف مجدول بموعد مستقبلي يبقى مخفياً حتى موعده (وفق `published_at`).
        if (video.isPublished) videos.add(video);
      }
      return videos;
    } catch (error) {
      throw error is VillageException ? error : _map(error);
    }
  }

  /// معرّف القرية بكودها عبر دالة البحث العامة — `null` إن لم يوجد الكود.
  Future<String?> _lookupVillageId(String villageCode) async {
    final dynamic response = await _supabase.rpc(
      lookupFunction,
      params: <String, dynamic>{'p_code': VillageCode.canonical(villageCode)},
    );
    final Map<String, dynamic>? row = _firstRow(response);
    if (row == null) return null;
    final String id = '${row['id'] ?? ''}';
    return id.isEmpty ? null : id;
  }

  /// يقرأ أول صف من استجابة PostgREST (جدول/قائمة) بلا انهيار على شكل غريب.
  Map<String, dynamic>? _firstRow(Object? response) {
    if (response is List) {
      if (response.isEmpty) return null;
      final Object? first = response.first;
      if (first is Map) return Map<String, dynamic>.from(first);
      return null;
    }
    if (response is Map) return Map<String, dynamic>.from(response);
    return null;
  }

  void _ensureAvailable() {
    if (!isAvailable) {
      throw const VillageException(
        VillageErrorKind.unavailable,
        VillageText.serviceTitle,
      );
    }
  }

  /// يحوّل أي خطأ إلى [VillageException] برسالة عربية مفهومة لأهل القرية.
  VillageException _map(Object error) {
    if (error is PostgrestException) {
      switch (error.code) {
        // قيد unique على الرقم القومي.
        case '23505':
          return VillageException(
            VillageErrorKind.duplicate,
            VillageText.duplicateNationalId,
            cause: error,
          );
        // كود القرية غير موجود — ترفعه الدالة بـ errcode مخصّص.
        case 'P0002':
          return VillageException(
            VillageErrorKind.notFound,
            VillageText.codeNotFound,
            cause: error,
          );
        // رفض تحقّق السيرفر (رقم قومي/سن/صيغة) — الرسالة العربية من الدالة.
        case 'P0001':
          return VillageException(
            VillageErrorKind.invalid,
            _serverMessage(error),
            cause: error,
          );
        default:
          return VillageException(
            _isNetworkText('${error.message} ${error.details} ${error.hint}')
                ? VillageErrorKind.network
                : VillageErrorKind.unknown,
            _isNetworkText(error.message)
                ? VillageText.networkError
                : VillageText.genericError,
            cause: error,
          );
      }
    }
    if (error is AuthException) {
      return VillageException(
        VillageErrorKind.unavailable,
        VillageText.networkError,
        cause: error,
      );
    }
    if (_isNetworkText(error.toString())) {
      return VillageException(
        VillageErrorKind.network,
        VillageText.networkError,
        cause: error,
      );
    }
    return VillageException(
      VillageErrorKind.unknown,
      VillageText.genericError,
      cause: error,
    );
  }

  /// رسالة السيرفر إن كانت عربية ومفيدة، وإلا الرسالة العامة.
  String _serverMessage(PostgrestException error) {
    final String message = error.message.trim();
    final bool hasArabic =
        RegExp(r'[\u0600-\u06FF]').hasMatch(message);
    if (hasArabic && message.length > 3) return message;
    return VillageText.genericError;
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
