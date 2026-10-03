/// متغيرات البيئة الخاصة بالاتصال بـ Supabase — وتُقرأ **تلقائياً وقت التشغيل**.
///
/// لا تُخزَّن المفاتيح في الكود المصدري. الأسبقية عند [AppEnv.load]:
///
/// 1. `--dart-define` وقت البناء (أمر صريح — يتفوق دائماً):
/// ```bash
/// flutter run -d windows \
///   --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
///   --dart-define=SUPABASE_ANON_KEY=eyJhbGciOi...
/// ```
/// 2. ملف `env.json` في جذر المشروع (يُقرأ من القرص ثم من الأصل المحزوم) —
///    أي أن التشغيل المعتاد **بلا أي علامة** يجد المفاتيح وحده:
/// ```bash
/// dart run tool/ensure_env.dart   # مرة واحدة، ثم املأ القيم
/// flutter run -d windows
/// ```
///
/// ملاحظة أمنية: `anon key` مفتاح **عام** مصمّم للعمل في الواجهات، والحماية
/// الحقيقية تأتي من سياسات RLS في `supabase_setup.sql`. أما `service_role`
/// فلا يُستخدم في التطبيق إطلاقاً ولا يقرأه مُحمّل الإعدادات حتى لو ورد في الملف.
library;

import 'package:flutter/foundation.dart';

import '../services/env_config_loader.dart';

abstract final class AppEnv {
  const AppEnv._();

  // --------------- مفاتيح وقت البناء (Tier 0) ---------------
  static const String _buildUrl = String.fromEnvironment('SUPABASE_URL');
  static const String _buildAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY');

  /// وضع التطوير — يُفعَّل صرياً لمنع تفعيله في نسخ الإنتاج.
  static const bool isDev = bool.fromEnvironment('FLUTTER_ENV_DEV');

  // --------------- الحالة بعد التحميل ---------------
  static String _url = _buildUrl;
  static String _anonKey = _buildAnonKey;
  static bool _loaded = _buildUrl.isNotEmpty && _buildAnonKey.isNotEmpty;
  static EnvConfigSource _source =
      _loaded ? EnvConfigSource.dartDefine : EnvConfigSource.none;

  /// رابط مشروع Supabase (فارغ ما لم تُضبط المفاتيح).
  static String get supabaseUrl => _url;

  /// المفتاح العام (anon / publishable).
  static String get supabaseAnonKey => _anonKey;

  /// هل وُجدت مفاتيح صالحة؟ التطبيق يعرض شاشة تهيئة إن كانت الإجابة لا.
  static bool get isSupabaseConfigured => _url.isNotEmpty && _anonKey.isNotEmpty;

  /// من أين جاءت المفاتيح (للتشخيص) — `none` قبل [load] أو عند الغياب التام.
  static EnvConfigSource get source => _source;

  /// يجلب المفاتيح مرة واحدة من أفضل مصدر متاح. آمن الاستدعاء المتكرر.
  ///
  /// تُستدعى من `SupabaseService.initialize()` قبل تهيئة العميل.
  static Future<void> load({EnvConfigLoader? loader}) async {
    if (_loaded) return;
    _loaded = true;

    // --dart-define صريح يتفوق على كل الملفات.
    if (_buildUrl.isNotEmpty && _buildAnonKey.isNotEmpty) {
      _url = _buildUrl;
      _anonKey = _buildAnonKey;
      _source = EnvConfigSource.dartDefine;
      return;
    }

    final EnvConfig? config = await (loader ?? const EnvConfigLoader()).load();
    if (config == null) {
      _source = EnvConfigSource.none;
      return;
    }
    _url = config.url;
    _anonKey = config.anonKey;
    _source = config.source;
  }

  /// لإعادة الحالة بين الاختبارات فقط.
  @visibleForTesting
  static void resetForTesting() {
    _url = _buildUrl;
    _anonKey = _buildAnonKey;
    _loaded = _buildUrl.isNotEmpty && _buildAnonKey.isNotEmpty;
    _source = _loaded ? EnvConfigSource.dartDefine : EnvConfigSource.none;
  }
}
