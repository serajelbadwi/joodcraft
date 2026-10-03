// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTagline =>
      'Genera certificados y contratos oficiales sin conexión';

  @override
  String get navDashboard => 'Panel';

  @override
  String get navCertificates => 'Creador de certificados';

  @override
  String get navContracts => 'Creador de contratos';

  @override
  String get navBatch => 'Generación por lotes';

  @override
  String get navTemplates => 'Biblioteca de plantillas';

  @override
  String get navAssets => 'Recursos y firmas';

  @override
  String get actionSignOut => 'Cerrar sesión';

  @override
  String get actionBackToDashboard => 'Volver al panel';

  @override
  String get offlineProcessingLabel => 'Procesamiento local';

  @override
  String get themeTooltip => 'Cambiar tema';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get languageTooltip => 'Cambiar idioma';

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
  String get configMissingKeysTitle =>
      'No se encontraron las claves de conexión';

  @override
  String get configMissingKeysBody =>
      'Al iniciar, la aplicación busca las claves en tres fuentes: el indicador --dart-define, luego un archivo env.json en el disco (raíz o assets/env/) y, por último, la copia incluida en la aplicación; no se encontró ninguna. Cree el archivo, complételo una vez y ejecute sin indicadores:';

  @override
  String get configEnvNote =>
      'El paquete declara assets/env/ como recurso, así que la ausencia del archivo no rompe una compilación limpia. Créelo desde env.example.json o ejecute: dart run tool/ensure_env.dart — solo se requiere la clave anon/public; service_role nunca se usa en la aplicación.';

  @override
  String get routeNotFoundTitle => 'Página no encontrada';

  @override
  String get routeNotFoundBody =>
      'La ruta solicitada no está definida en la aplicación:';
}
