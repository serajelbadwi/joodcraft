// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTagline =>
      'Offizielle Zertifikate und Verträge offline erstellen';

  @override
  String get navDashboard => 'Übersicht';

  @override
  String get navCertificates => 'Zertifikats-Editor';

  @override
  String get navContracts => 'Vertrags-Editor';

  @override
  String get navBatch => 'Stapelverarbeitung';

  @override
  String get navTemplates => 'Vorlagenbibliothek';

  @override
  String get navAssets => 'Assets & Signaturen';

  @override
  String get actionSignOut => 'Abmelden';

  @override
  String get actionBackToDashboard => 'Zurück zur Übersicht';

  @override
  String get offlineProcessingLabel => 'Lokale Verarbeitung';

  @override
  String get themeTooltip => 'Design wechseln';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Hell';

  @override
  String get themeDark => 'Dunkel';

  @override
  String get languageTooltip => 'Sprache ändern';

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
  String get configMissingKeysTitle => 'Verbindungsschlüssel nicht gefunden';

  @override
  String get configMissingKeysBody =>
      'Beim Start sucht die App nach Schlüsseln in drei Quellen: dem --dart-define-Flag, dann einer env.json-Datei auf der Festplatte (Stammverzeichnis oder assets/env/) und schließlich der eingebetteten Kopie — keine wurde gefunden. Erstellen Sie die Datei, füllen Sie sie einmal aus und starten Sie ohne Flags:';

  @override
  String get configEnvNote =>
      'Das Bundle deklariert assets/env/ als Asset, daher bricht ein fehlendes File einen sauberen Build nicht ab. Erstellen Sie es aus env.example.json oder führen Sie aus: dart run tool/ensure_env.dart — nur der anon/public-Schlüssel ist nötig; service_role wird nie in der App verwendet.';

  @override
  String get routeNotFoundTitle => 'Seite nicht gefunden';

  @override
  String get routeNotFoundBody =>
      'Die angeforderte Route ist in der App nicht definiert:';
}
