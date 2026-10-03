// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTagline =>
      'Generate official certificates and contracts offline';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navCertificates => 'Certificate Builder';

  @override
  String get navContracts => 'Contract Builder';

  @override
  String get navBatch => 'Batch Generation';

  @override
  String get navTemplates => 'Template Library';

  @override
  String get navAssets => 'Assets & Signatures';

  @override
  String get actionSignOut => 'Sign out';

  @override
  String get actionBackToDashboard => 'Back to dashboard';

  @override
  String get offlineProcessingLabel => 'Local processing';

  @override
  String get themeTooltip => 'Toggle theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get languageTooltip => 'Change language';

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
  String get configMissingKeysTitle => 'Connection keys not found';

  @override
  String get configMissingKeysBody =>
      'At startup the app looks for keys in three sources: the --dart-define flag, then an env.json file on disk (root or assets/env/), then the bundled copy inside the app — but none was found. Create the file, fill it once, then run with no flags:';

  @override
  String get configEnvNote =>
      'The bundle declares assets/env/ as an asset, so a missing file will not break a clean build. Create it from env.example.json or run: dart run tool/ensure_env.dart — only the anon/public key is required; service_role is never used in the app.';

  @override
  String get routeNotFoundTitle => 'Page not found';

  @override
  String get routeNotFoundBody =>
      'The requested route is not defined in the app:';
}
