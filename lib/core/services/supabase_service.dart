import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/app_env.dart';

/// نقطة التهيئة الوحيدة لعميل Supabase.
///
/// التطبيق **لا يفترض** وجود مفاتيح صحيحة: إن لم تُضبط عبر
/// `--dart-define` تبقى `isInitialized = false` وتُعرض شاشة التهيئة بدل الانهيار.
abstract final class SupabaseService {
  const SupabaseService._();

  static bool _initialized = false;

  /// هل تم تهيئة العميل بنجاح؟
  static bool get isInitialized => _initialized;

  /// تهيئة العميل. تُستدعى مرة واحدة من `main()`.
  static Future<bool> initialize() async {
    if (_initialized) return true;

    // تجلب المفاتيح تلقائياً إن لم تُمرَّر وقت البناء:
    // --dart-define ← env.json على القرص ← env.json المحزوم.
    await AppEnv.load();
    if (!AppEnv.isSupabaseConfigured) return false;

    try {
      await Supabase.initialize(
        url: AppEnv.supabaseUrl,
        // نستخدم anonKey (لا publishableKey) لأنها تقبل المفتاح القديم
        // (JWT) والجديد على حد سواء — أي أنها لا تفرض على المستخدم تغييراً.
        // ignore: deprecated_member_use
        anonKey: AppEnv.supabaseAnonKey,
        // تخزين الجلسة محلي على الجهاز (shared_preferences / localStorage).
        debug: AppEnv.isDev,
      );
      _initialized = true;
      return true;
    } catch (_) {
      _initialized = false;
      return false;
    }
  }

  /// العميل الجاهز للاستخدام — لا تُستدعَ قبل نجاح [initialize].
  static SupabaseClient get client => Supabase.instance.client;

  /// جلسة المستخدم الحالية (null إن لم يكن مسجلاً).
  static Session? get currentSession =>
      _initialized ? client.auth.currentSession : null;
}
