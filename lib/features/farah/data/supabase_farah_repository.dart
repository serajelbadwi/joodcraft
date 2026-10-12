/// تنفيذ [FarahRepository] فوق Supabase — سبع دوال (RPC) لا شيء غيرها.
///
/// **لماذا لا جداول مباشرة؟** تطبيق «فرح» صفحة عامة بلا جلسة تسجيل دخول
/// (`auth.uid()` يعود `null` دائماً)، وجدول `members` ليس فيه عمود `user_id`
/// أصلاً — فسياسات RLS لا تجد من تحمي جلسته. لذلك أُغلقت الجداول الثلاثة
/// (`farah_messages` و`farah_licenses` و`farah_daily_counts`) بلا أي سياسة،
/// وكل قراءة وكتابة تمرّ من دوال `security definer` تحدّد العضو من تليفونه
/// على السيرفر — كما تفعل دوال صفحة القرية.
///
/// في السجلّ لا تُطبع أرقام قومية ولا تليفونات: إنما اسم الدالة ونتيجتها فقط.
library;

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/supabase_service.dart';
import '../../village/domain/village_validators.dart';
import '../domain/farah_models.dart';
import '../domain/farah_text.dart';
import 'farah_repository.dart';

class SupabaseFarahRepository implements FarahRepository {
  /// بنّاء افتراضي يستخدم عميل Supabase العام المُهيّأ في `main()`.
  const SupabaseFarahRepository({SupabaseClient? client}) : _client = client;

  /// عميل مُمرَّر (للاختبارات) — وغيابه يعني استخدام العميل العام المُهيّأ.
  ///
  /// بنّاء `const` حتى يستطيع تطبيق Farah اشتقاقه افتراضياً (`const FarahApp()`).
  final SupabaseClient? _client;

  SupabaseClient get _supabase => _client ?? SupabaseService.client;

  @override
  bool get isAvailable => _client != null || SupabaseService.isInitialized;

  /// أسماء الدوال على السيرفر — مصدر واحد للحقيقة.
  static const String resolveFunction = 'farah_resolve_member';
  static const String membersFunction = 'farah_members';
  static const String conversationsFunction = 'farah_conversations';
  static const String threadFunction = 'farah_thread';
  static const String allowanceFunction = 'farah_allowance';
  static const String sendFunction = 'farah_send';
  static const String activateFunction = 'farah_activate';

  @override
  Future<FarahSession> login(String phone) async {
    _ensureAvailable();
    final String normalized = VillageValidators.normalizeDigits(phone);
    debugPrint('[farah] RPC $resolveFunction(phone: ${normalized.length} رقماً)');
    try {
      final Map<String, dynamic>? row = _firstRow(
        await _supabase.rpc(
          resolveFunction,
          params: <String, dynamic>{'p_phone': normalized},
        ),
      );
      if (row == null) {
        debugPrint('[farah] $resolveFunction → null (التليفون غير مسجَّل)');
        throw const FarahException(
          FarahErrorKind.notRegistered,
          FarahText.notRegistered,
        );
      }
      final FarahSession session = FarahSession.fromRow(row, phone: normalized);
      debugPrint('[farah] $resolveFunction → ${session.fullName} '
          '(owner=${session.isOwner})');
      return session;
    } catch (error) {
      throw error is FarahException ? error : _map(error);
    }
  }

  @override
  Future<List<FarahMember>> fetchMembers(String phone) async {
    _ensureAvailable();
    try {
      final List<Map<String, dynamic>> rows = _rows(
        await _supabase.rpc(
          membersFunction,
          params: <String, dynamic>{
            'p_phone': VillageValidators.normalizeDigits(phone),
          },
        ),
      );
      return rows.map(FarahMember.fromRow).toList(growable: false);
    } catch (error) {
      throw error is FarahException ? error : _map(error);
    }
  }

  @override
  Future<List<FarahConversation>> fetchConversations(String phone) async {
    _ensureAvailable();
    try {
      final List<Map<String, dynamic>> rows = _rows(
        await _supabase.rpc(
          conversationsFunction,
          params: <String, dynamic>{
            'p_phone': VillageValidators.normalizeDigits(phone),
          },
        ),
      );
      return rows
          .map(FarahConversation.fromRow)
          .toList(growable: false);
    } catch (error) {
      throw error is FarahException ? error : _map(error);
    }
  }

  @override
  Future<List<FarahMessage>> fetchThread({
    required String phone,
    required String partnerId,
  }) async {
    _ensureAvailable();
    try {
      final List<Map<String, dynamic>> rows = _rows(
        await _supabase.rpc(
          threadFunction,
          params: <String, dynamic>{
            'p_phone': VillageValidators.normalizeDigits(phone),
            'p_partner_id': partnerId,
          },
        ),
      );
      return rows.map(FarahMessage.fromRow).toList(growable: false);
    } catch (error) {
      throw error is FarahException ? error : _map(error);
    }
  }

  @override
  Future<FarahAllowance> fetchAllowance({
    required String phone,
    required String partnerId,
  }) async {
    _ensureAvailable();
    try {
      final Map<String, dynamic>? row = _firstRow(
        await _supabase.rpc(
          allowanceFunction,
          params: <String, dynamic>{
            'p_phone': VillageValidators.normalizeDigits(phone),
            'p_partner_id': partnerId,
          },
        ),
      );
      return FarahAllowance(
        remaining: (row?['remaining'] as num?)?.toInt() ?? 0,
        isOwner: row?['is_owner'] == true,
      );
    } catch (error) {
      throw error is FarahException ? error : _map(error);
    }
  }

  @override
  Future<FarahSendResult> sendMessage({
    required String phone,
    required String partnerId,
    required String body,
  }) async {
    _ensureAvailable();
    debugPrint('[farah] RPC $sendFunction(len=${body.trim().length})');
    try {
      final Map<String, dynamic>? row = _firstRow(
        await _supabase.rpc(
          sendFunction,
          params: <String, dynamic>{
            'p_phone': VillageValidators.normalizeDigits(phone),
            'p_partner_id': partnerId,
            'p_body': body.trim(),
          },
        ),
      );
      if (row == null) {
        throw const FarahException(FarahErrorKind.unknown, FarahText.genericError);
      }
      return FarahSendResult(
        message: FarahMessage.fromRow(row),
        remaining: (row['remaining'] as num?)?.toInt() ?? 0,
      );
    } catch (error) {
      throw error is FarahException ? error : _map(error);
    }
  }

  @override
  Future<bool> activateLicense({
    required String phone,
    required String code,
  }) async {
    _ensureAvailable();
    debugPrint('[farah] RPC $activateFunction');
    try {
      final dynamic response = await _supabase.rpc(
        activateFunction,
        params: <String, dynamic>{
          'p_phone': VillageValidators.normalizeDigits(phone),
          'p_code': code.trim().toUpperCase(),
        },
      );
      return response == true;
    } catch (error) {
      throw error is FarahException ? error : _map(error);
    }
  }

  // =========================== مساعدات الترجمة ===========================

  /// يحوّل استجابة PostgREST إلى صفوف — بلا انهيار على شكل غريب.
  List<Map<String, dynamic>> _rows(Object? response) {
    if (response is List) {
      return response
          .whereType<Map>()
          .map<Map<String, dynamic>>((Map<dynamic, dynamic> row) =>
              Map<String, dynamic>.from(row))
          .toList(growable: false);
    }
    if (response is Map) {
      return <Map<String, dynamic>>[Map<String, dynamic>.from(response)];
    }
    return const <Map<String, dynamic>>[];
  }

  Map<String, dynamic>? _firstRow(Object? response) {
    final List<Map<String, dynamic>> rows = _rows(response);
    return rows.isEmpty ? null : rows.first;
  }

  void _ensureAvailable() {
    if (!isAvailable) {
      throw const FarahException(
        FarahErrorKind.unavailable,
        FarahText.serviceUnavailable,
      );
    }
  }

  /// يحوّل أي خطأ من PostgREST إلى [FarahException] برسالة عربية مفهومة.
  FarahException _map(Object error) {
    if (error is PostgrestException) {
      final String raw = error.message;

      switch (error.code) {
        // «سجّل في صفحة القرية أولاً» ⇐ تليفون غير مسجَّل؛ وما عداها ⇐
        // الطرف الآخر غير موجود في القرية.
        case 'P0002':
          if (raw.contains('سجّل')) {
            return FarahException(
              FarahErrorKind.notRegistered,
              FarahText.notRegistered,
              cause: error,
            );
          }
          return FarahException(
            FarahErrorKind.notFound,
            _serverMessage(error) ?? FarahText.genericError,
            cause: error,
          );

        // رسائل السيرفر العربية: تحقّق من صيغة الكود أو **نفاد الحدّ**.
        case 'P0001':
          return FarahException(
            raw.contains('انتهى حدّ')
                ? FarahErrorKind.limitReached
                : FarahErrorKind.invalid,
            _serverMessage(error) ?? FarahText.genericError,
            cause: error,
          );

        // الدالة غير منشأة بعد (لم يُطبَّق سكريبت «فرح» على Supabase).
        case 'PGRST202':
          return FarahException(
            FarahErrorKind.unknown,
            FarahText.genericError,
            cause: error,
          );

        default:
          return FarahException(
            _isNetworkText('$raw ${error.details} ${error.hint}')
                ? FarahErrorKind.network
                : FarahErrorKind.unknown,
            _isNetworkText(raw)
                ? FarahText.networkError
                : FarahText.genericError,
            cause: error,
          );
      }
    }
    if (error is AuthException) {
      return FarahException(
        FarahErrorKind.unavailable,
        FarahText.networkError,
        cause: error,
      );
    }
    if (_isNetworkText(error.toString())) {
      return FarahException(
        FarahErrorKind.network,
        FarahText.networkError,
        cause: error,
      );
    }
    return FarahException(
      FarahErrorKind.unknown,
      FarahText.genericError,
      cause: error,
    );
  }

  /// رسالة السيرفر إن كانت عربية ومفيدة، وإلا `null`.
  String? _serverMessage(PostgrestException error) {
    final String message = error.message.trim();
    final bool hasArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(message);
    if (hasArabic && message.length > 3) return message;
    return null;
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
