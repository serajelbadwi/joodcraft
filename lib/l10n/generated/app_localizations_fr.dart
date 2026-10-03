// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTagline =>
      'Générez des certificats et des contrats officiels hors ligne';

  @override
  String get navDashboard => 'Tableau de bord';

  @override
  String get navCertificates => 'Créateur de certificats';

  @override
  String get navContracts => 'Créateur de contrats';

  @override
  String get navBatch => 'Génération en lot';

  @override
  String get navTemplates => 'Bibliothèque de modèles';

  @override
  String get navAssets => 'Ressources et signatures';

  @override
  String get actionSignOut => 'Se déconnecter';

  @override
  String get actionBackToDashboard => 'Retour au tableau de bord';

  @override
  String get offlineProcessingLabel => 'Traitement local';

  @override
  String get themeTooltip => 'Changer le thème';

  @override
  String get themeSystem => 'Système';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeDark => 'Sombre';

  @override
  String get languageTooltip => 'Changer de langue';

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
  String get configMissingKeysTitle => 'Clés de connexion introuvables';

  @override
  String get configMissingKeysBody =>
      'Au démarrage, l\'application cherche les clés dans trois sources : le drapeau --dart-define, puis un fichier env.json sur le disque (racine ou assets/env/), puis la copie intégrée — aucune n\'a été trouvée. Créez le fichier, remplissez-le une fois, puis lancez sans aucun drapeau :';

  @override
  String get configEnvNote =>
      'Le bundle déclare assets/env/ comme ressource, donc l\'absence du fichier ne casse pas une compilation propre. Créez-le depuis env.example.json ou exécutez : dart run tool/ensure_env.dart — seule la clé anon/public est requise ; service_role n\'est jamais utilisée dans l\'application.';

  @override
  String get routeNotFoundTitle => 'Page introuvable';

  @override
  String get routeNotFoundBody =>
      'La route demandée n\'est pas définie dans l\'application :';
}
