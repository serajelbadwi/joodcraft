import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'env_file_reader.dart';

/// مصدر مفاتيح Supabase وقت التشغيل — يُستخدم في رسائل التشخيص.
enum EnvConfigSource {
  dartDefine('--dart-define وقت البناء'),
  file('ملف env.json على القرص'),
  asset('ملف env.json داخل التطبيق'),
  none('لا يوجد مصدر');

  const EnvConfigSource(this.labelAr);

  /// وصف عربي للمصدر (للعرض في شاشة التهيئة ورسائل التشخيص).
  final String labelAr;
}

/// مفاتيح الاتصال بعد التحقق من صحتها.
class EnvConfig {
  const EnvConfig({
    required this.url,
    required this.anonKey,
    required this.source,
  });

  final String url;
  final String anonKey;
  final EnvConfigSource source;
}

/// قارئ محتمل لمحتوى ملف البيئة (قرص أو أصل محزوم).
typedef EnvReader = Future<String?> Function(String fileName);

/// يجلب مفاتيح Supabase من ملف `env.json` دون أي علامة تشغيل (flags).
///
/// **الترتيب** (الأسبق يفوز، والمصدر يُعامَل كوحدة واحدة — لا خلط بينهما):
/// 1. `--dart-define` يُفحص في [AppEnv.load] قبل هذا المُحمّل (أمر صريح يتفوق دائماً).
/// 2. **القرص**: أثناء التطوير `Directory.current` هو جذر المشروع، فيُقرأ الملف
///    بأحدث نسخة دون إعادة بناء (انظر `env_file_reader_io.dart`).
/// 3. **الأصل المحزوم**: `assets/env/env.json` داخل المجلد المُعلن كأصل
///    (`assets/env/`) في `pubspec.yaml` — يعمل على كل المنصات بما فيها نسخ
///    الإنتاج المثبتة، ولا يُسقط غيابُه بناء النسخ النظيفة.
///
/// أي فشل (ملف غائب، JSON غير صالح، نص نموذج غير مُملأ) يُعتبر «غير موجود»
/// ويُرجَع `null` — لا يُسقط التطبيق أبداً وتبقى شاشة التهيئة هي الحالات القصوى.
///
/// ملاحظة أمنية: مفتاح `service_role` **يتجاهله** هذا المُحمّل مهما ورد في الملف؛
/// التطبيق لا يملك صلاحية المشرف إطلاقاً.
class EnvConfigLoader {
  const EnvConfigLoader({
    this.readFile = readEnvFile,
    this.readAsset = _readBundledAsset,
    this.diskFileNames = defaultDiskFileNames,
    this.assetFileName = defaultAssetFileName,
  });

  /// أسماء ملفات القرص أثناء التطوير (بترتيب الأسبقية).
  ///
  /// الجذر أولاً (السلوك التاريخي)، ثم مسار الحزمة نفسه حتى يعمل التطوير
  /// بنفس الملف المحزوم دون نسختين متباعدتين.
  static const List<String> defaultDiskFileNames = <String>[
    'env.json',
    defaultAssetFileName,
  ];

  /// مسار الملف المحزوم داخل أصول التطبيق.
  ///
  /// **مجلد** مُعلن كأصل في `pubspec.yaml` (`assets/env/`) وليس ملفاً بذاته،
  /// لذا لا يُسقط غيابُه بناءَ النسخ النظيفة من الريبو؛ يبقى `localBundle`
  /// يُعيد خطأً عند القراءة يُلتقط بهدوء (انظر [_safely]).
  static const String defaultAssetFileName = 'assets/env/env.json';

  final EnvReader readFile;
  final EnvReader readAsset;

  /// ملفات القرص المحتملة بترتيب الأسبقية.
  final List<String> diskFileNames;

  /// مسار الملف المحزوم في أصول التطبيق.
  final String assetFileName;

  /// يبحث بالترتيب: القرص (بكل أسمائه) ثم أصل التطبيق المحزوم.
  Future<EnvConfig?> load() async {
    for (final String name in diskFileNames) {
      final EnvConfig? fromDisk = EnvConfigLoader.parse(
        await _safely(readFile, name),
        EnvConfigSource.file,
      );
      if (fromDisk != null) return fromDisk;
    }
    return EnvConfigLoader.parse(
      await _safely(readAsset, assetFileName),
      EnvConfigSource.asset,
    );
  }

  /// يحوّل محتوى ملف JSON إلى [EnvConfig]، ويرفض كل ما ليس مفاتيح حقيقية.
  ///
  /// تُقبل المفاتيح بصيغة `--dart-define-from-file` (القياسي) وبصيغ Supabase CLI.
  static EnvConfig? parse(String? raw, EnvConfigSource source) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final Object? data = jsonDecode(raw);
      if (data is! Map) return null;

      final String url = _firstText(data, const <String>[
        'SUPABASE_URL',
        'API_URL',
      ]);
      final String key = _firstText(data, const <String>[
        'SUPABASE_ANON_KEY',
        'SUPABASE_PUBLISHABLE_KEY',
        'ANON_KEY',
      ]);

      if (!_isHttpUrl(url)) return null;
      if (key.length < 20) return null;
      if (_isUnfilledPlaceholder(url, key)) return null;

      return EnvConfig(url: url, anonKey: key, source: source);
    } on FormatException {
      return null;
    }
  }

  Future<String?> _safely(EnvReader reader, String fileName) async {
    try {
      return await reader(fileName);
    } on Object {
      // ملف غائب أو أصل غير مُعلن أو فشل قراءة: ليس خطأً قاتلاً — ننتقل
      // للمصدر التالي (وهذا ما يجعل غياب env.json المحزوم غير مُعطِّل).
      return null;
    }
  }

  static String _firstText(Map<dynamic, dynamic> data, List<String> keys) {
    for (final String key in keys) {
      final Object? value = data[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return '';
  }

  static bool _isHttpUrl(String url) =>
      url.startsWith('http://') || url.startsWith('https://');

  /// يكشف نص `env.example.json` قبل ملئه حتى لا تُعامل القيم النموذجية
  /// كمفاتيح صالحة (ولو عُوامللت لفشلت الاتصالات برسائل غامضة).
  static bool _isUnfilledPlaceholder(String url, String key) =>
      url.contains('xxxx') ||
      url.contains('<') ||
      key.contains('<') ||
      key.contains('ضع-هنا');

  static Future<String?> _readBundledAsset(String fileName) =>
      rootBundle.loadString(fileName);
}
