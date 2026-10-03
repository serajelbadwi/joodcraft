import 'package:flutter/widgets.dart';

/// لغة مدعومة في التطبيق: رمزها، واسمها **بلغتها الأصلية**، واتجاه كتابتها.
///
/// اسم اللغة يُعرض دائماً بلغتها الأصلية (العربية، English، 中文…) لا بلغة
/// الواجهة الحالية — وهذا هو العُرف في منتقيات اللغات، إذ يعرف المستخدم لغته
/// أياً كانت لغة الواجهة المعروضة.
class AppLocale {
  const AppLocale({
    required this.code,
    required this.nativeName,
    required this.direction,
  });

  /// رمز اللغة (ISO 639-1) كما يُخزَّن ويُطابق ملفات ARB.
  final String code;

  /// الاسم الأصلي للغة كما يكتبه أهلها.
  final String nativeName;

  /// اتجاه الكتابة — يُفعَّل تلقائياً عند اختيار اللغة.
  final TextDirection direction;

  bool get isRtl => direction == TextDirection.rtl;

  Locale get locale => Locale(code);
}

/// اللغات العشر المدعومة، بالترتيب نفسه في [AppLocales.locales].
///
/// العربية هي الافتراضية (RTL)، والأوردو ثاني لغات RTL — والباقي LTR.
const List<AppLocale> supportedAppLocales = <AppLocale>[
  AppLocale(code: 'ar', nativeName: 'العربية', direction: TextDirection.rtl),
  AppLocale(code: 'en', nativeName: 'English', direction: TextDirection.ltr),
  AppLocale(code: 'fr', nativeName: 'Français', direction: TextDirection.ltr),
  AppLocale(code: 'es', nativeName: 'Español', direction: TextDirection.ltr),
  AppLocale(code: 'tr', nativeName: 'Türkçe', direction: TextDirection.ltr),
  AppLocale(code: 'ur', nativeName: 'اردو', direction: TextDirection.rtl),
  AppLocale(code: 'de', nativeName: 'Deutsch', direction: TextDirection.ltr),
  AppLocale(
    code: 'id',
    nativeName: 'Bahasa Indonesia',
    direction: TextDirection.ltr,
  ),
  AppLocale(code: 'ru', nativeName: 'Русский', direction: TextDirection.ltr),
  AppLocale(code: 'zh', nativeName: '简体中文', direction: TextDirection.ltr),
];

/// اللغة الافتراضية عند أول تشغيل أو عند قيمة مخزَّنة غير معروفة.
const AppLocale defaultAppLocale = AppLocale(
  code: 'ar',
  nativeName: 'العربية',
  direction: TextDirection.rtl,
);

/// أدوات مساعدة حول اللغات المدعومة — مصدر واحد للحقيقة لا يُكرَّر.
abstract final class AppLocales {
  const AppLocales._();

  /// رمز اللغة الافتراضية.
  static const String defaultCode = 'ar';

  /// أسماء أكواد اللغات المدعومة (بترتيب العرض).
  static List<String> get codes =>
      supportedAppLocales.map((AppLocale l) => l.code).toList(growable: false);

  /// كائنات `Locale` لتمريرها إلى `MaterialApp.supportedLocales`.
  static List<Locale> get locales =>
      supportedAppLocales.map((AppLocale l) => l.locale).toList(growable: false);

  /// اللغة الافتراضية كـ `Locale`.
  static Locale get fallback => const Locale(defaultCode);

  /// البحث عن لغة بكودها (أو `null` إن لم تكن مدعومة).
  static AppLocale? byCode(String? code) {
    if (code == null) return null;
    final String needle = code.trim().toLowerCase();
    for (final AppLocale locale in supportedAppLocales) {
      if (locale.code == needle) return locale;
    }
    return null;
  }

  /// تحويل نص مخزَّن إلى لغة — أي قيمة مجهولة تعود إلى الافتراضية.
  static AppLocale parse(String? raw) => byCode(raw) ?? defaultAppLocale;

  /// اللغة المدعومة الموافقة للوكال (مع الرجوع للافتراضية).
  static AppLocale resolve(Locale? locale) =>
      byCode(locale?.languageCode) ?? defaultAppLocale;

  /// اتجاه الكتابة للغة ما (LTR افتراضياً لغير المدعوم من RTL).
  static TextDirection directionOf(Locale? locale) => resolve(locale).direction;
}
