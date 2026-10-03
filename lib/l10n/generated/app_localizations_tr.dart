// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTagline =>
      'Resmî sertifika ve sözleşmeleri çevrimdışı oluşturun';

  @override
  String get navDashboard => 'Kontrol Paneli';

  @override
  String get navCertificates => 'Sertifika Oluşturucu';

  @override
  String get navContracts => 'Sözleşme Oluşturucu';

  @override
  String get navBatch => 'Toplu Üretim';

  @override
  String get navTemplates => 'Şablon Kitaplığı';

  @override
  String get navAssets => 'Varlıklar ve İmzalar';

  @override
  String get actionSignOut => 'Çıkış yap';

  @override
  String get actionBackToDashboard => 'Kontrol paneline dön';

  @override
  String get offlineProcessingLabel => 'Yerel işleme';

  @override
  String get themeTooltip => 'Temayı değiştir';

  @override
  String get themeSystem => 'Sistem';

  @override
  String get themeLight => 'Açık';

  @override
  String get themeDark => 'Koyu';

  @override
  String get languageTooltip => 'Dili değiştir';

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
  String get configMissingKeysTitle => 'Bağlantı anahtarları bulunamadı';

  @override
  String get configMissingKeysBody =>
      'Uygulama başlangıçta anahtarları üç kaynakta arar: --dart-define bayrağı, ardından diskteki env.json dosyası (kök veya assets/env/) ve son olarak uygulamaya gömülü kopya — hiçbiri bulunamadı. Dosyayı oluşturun, bir kez doldurun ve bayraksız çalıştırın:';

  @override
  String get configEnvNote =>
      'Paket assets/env/ klasörünü varlık olarak tanımlar, bu nedenle dosyanın yokluğu temiz bir derlemeyi bozmaz. env.example.json\'dan oluşturun veya şunu çalıştırın: dart run tool/ensure_env.dart — yalnızca anon/public anahtarı gerekir; service_role uygulamada hiç kullanılmaz.';

  @override
  String get routeNotFoundTitle => 'Sayfa bulunamadı';

  @override
  String get routeNotFoundBody => 'İstenen yol uygulamada tanımlı değil:';
}
