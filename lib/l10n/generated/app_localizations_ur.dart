// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Urdu (`ur`).
class AppLocalizationsUr extends AppLocalizations {
  AppLocalizationsUr([String locale = 'ur']) : super(locale);

  @override
  String get appTagline => 'سرکاری سرٹیفکیٹ اور معاہدے آف لائن بنائیں';

  @override
  String get navDashboard => 'ڈیش بورڈ';

  @override
  String get navCertificates => 'سرٹیفکیٹ بلڈر';

  @override
  String get navContracts => 'معاہدہ بلڈر';

  @override
  String get navBatch => 'بیچ جنریشن';

  @override
  String get navTemplates => 'ٹیمپلیٹ لائبریری';

  @override
  String get navAssets => 'اثاثے اور دستخط';

  @override
  String get actionSignOut => 'سائن آؤٹ';

  @override
  String get actionBackToDashboard => 'ڈیش بورڈ پر واپس جائیں';

  @override
  String get offlineProcessingLabel => 'مقامی پروسیسنگ';

  @override
  String get themeTooltip => 'تھیم تبدیل کریں';

  @override
  String get themeSystem => 'سسٹم';

  @override
  String get themeLight => 'روشن';

  @override
  String get themeDark => 'گہرا';

  @override
  String get languageTooltip => 'زبان تبدیل کریں';

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
  String get configMissingKeysTitle => 'کنکشن کیز نہیں ملیں';

  @override
  String get configMissingKeysBody =>
      'ایپ آغاز پر تین ذرائع میں کیز تلاش کرتی ہے: --dart-define فلیگ، پھر ڈسک پر env.json فائل (روٹ یا assets/env/) اور پھر ایپ میں شامل کاپی — کوئی نہیں ملی۔ فائل بنائیں، ایک بار بھریں اور بغیر فلیگ چلائیں:';

  @override
  String get configEnvNote =>
      'بنڈل assets/env/ کو اثاثہ قرار دیتا ہے، اس لیے فائل کی عدم موجودگی صاف بلڈ کو نہیں توڑتی۔ env.example.json سے بنائیں یا چلائیں: dart run tool/ensure_env.dart — صرف anon/public کلید درکار ہے؛ service_role ایپ میں کبھی استعمال نہیں ہوتی۔';

  @override
  String get routeNotFoundTitle => 'صفحہ نہیں ملا';

  @override
  String get routeNotFoundBody => 'مطلوبہ راستہ ایپ میں متعین نہیں:';
}
