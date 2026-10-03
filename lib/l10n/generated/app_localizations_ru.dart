// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTagline =>
      'Создавайте официальные сертификаты и договоры офлайн';

  @override
  String get navDashboard => 'Панель управления';

  @override
  String get navCertificates => 'Конструктор сертификатов';

  @override
  String get navContracts => 'Конструктор договоров';

  @override
  String get navBatch => 'Пакетная генерация';

  @override
  String get navTemplates => 'Библиотека шаблонов';

  @override
  String get navAssets => 'Ресурсы и подписи';

  @override
  String get actionSignOut => 'Выйти';

  @override
  String get actionBackToDashboard => 'Вернуться к панели';

  @override
  String get offlineProcessingLabel => 'Локальная обработка';

  @override
  String get themeTooltip => 'Сменить тему';

  @override
  String get themeSystem => 'Системная';

  @override
  String get themeLight => 'Светлая';

  @override
  String get themeDark => 'Тёмная';

  @override
  String get languageTooltip => 'Сменить язык';

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
  String get configMissingKeysTitle => 'Ключи подключения не найдены';

  @override
  String get configMissingKeysBody =>
      'При запуске приложение ищет ключи в трёх источниках: флаг --dart-define, затем файл env.json на диске (корень или assets/env/) и, наконец, встроенная копия — ни один не найден. Создайте файл, заполните его один раз и запустите без флагов:';

  @override
  String get configEnvNote =>
      'Пакет объявляет assets/env/ как ресурс, поэтому отсутствие файла не ломает чистую сборку. Создайте его из env.example.json или выполните: dart run tool/ensure_env.dart — требуется только ключ anon/public; service_role в приложении не используется.';

  @override
  String get routeNotFoundTitle => 'Страница не найдена';

  @override
  String get routeNotFoundBody =>
      'Запрошенный маршрут не определён в приложении:';
}
