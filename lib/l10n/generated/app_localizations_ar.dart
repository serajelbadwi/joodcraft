// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTagline => 'منصة توليد الشهادات والعقود الرسمية';

  @override
  String get navDashboard => 'لوحة التحكم';

  @override
  String get navCertificates => 'محـرّك الشهادات';

  @override
  String get navContracts => 'محـرّك العقود';

  @override
  String get navBatch => 'التوليد الجماعي';

  @override
  String get navTemplates => 'مكتبة القوالب';

  @override
  String get navAssets => 'الأصول والتوقيعات';

  @override
  String get actionSignOut => 'تسجيل الخروج';

  @override
  String get actionBackToDashboard => 'العودة إلى لوحة التحكم';

  @override
  String get offlineProcessingLabel => 'معالجة محلية';

  @override
  String get themeTooltip => 'تبديل المظهر';

  @override
  String get themeSystem => 'حسب النظام';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeDark => 'داكن';

  @override
  String get languageTooltip => 'تغيير اللغة';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageFrench => 'Français';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languageTurkish => 'Türkçe';

  @override
  String get languageUrdu => 'اردو';

  @override
  String get languageGerman => 'Deutsch';

  @override
  String get languageIndonesian => 'Bahasa Indonesia';

  @override
  String get languageRussian => 'Русский';

  @override
  String get languageChinese => '简体中文';

  @override
  String get configMissingKeysTitle => 'لم يُعثر على مفاتيح الاتصال';

  @override
  String get configMissingKeysBody =>
      'يبحث التطبيق تلقائياً وقت التشغيل في ثلاثة مصادر: علامة --dart-define، ثم ملف env.json على القرص (الجذر أو assets/env/)، ثم النسخة المحزومة داخل التطبيق — ولم يُعثر على أيٍّ منها. أنشئ الملف واملأه مرة واحدة ثم شغّل بلا أي علامة:';

  @override
  String get configEnvNote =>
      'الحزمة تُعلن مجلد assets/env/ كأصل، لذا غياب الملف لا يُسقط البناء من نسخة نظيفة. أنشئه من env.example.json أو شغّل: dart run tool/ensure_env.dart — والمفتاح المطلوب anon/public فقط، وservice_role لا يُستخدم في التطبيق إطلاقاً.';

  @override
  String get routeNotFoundTitle => 'الصفحة غير موجودة';

  @override
  String get routeNotFoundBody => 'المسار المطلوب غير معرّف في التطبيق:';
}
