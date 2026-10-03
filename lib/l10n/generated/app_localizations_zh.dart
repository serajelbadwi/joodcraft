// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTagline => '离线生成官方证书和合同';

  @override
  String get navDashboard => '仪表板';

  @override
  String get navCertificates => '证书设计器';

  @override
  String get navContracts => '合同设计器';

  @override
  String get navBatch => '批量生成';

  @override
  String get navTemplates => '模板库';

  @override
  String get navAssets => '资源与签名';

  @override
  String get actionSignOut => '退出登录';

  @override
  String get actionBackToDashboard => '返回仪表板';

  @override
  String get offlineProcessingLabel => '本地处理';

  @override
  String get themeTooltip => '切换主题';

  @override
  String get themeSystem => '跟随系统';

  @override
  String get themeLight => '浅色';

  @override
  String get themeDark => '深色';

  @override
  String get languageTooltip => '更改语言';

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
  String get configMissingKeysTitle => '未找到连接密钥';

  @override
  String get configMissingKeysBody =>
      '启动时，应用会依次在三个来源中查找密钥：--dart-define 标志、磁盘上的 env.json 文件（根目录或 assets/env/），以及应用内置的副本——但均未找到。请创建该文件并填写一次，然后无需任何标志即可运行：';

  @override
  String get configEnvNote =>
      '构建包将 assets/env/ 声明为资源，因此缺少文件不会导致干净构建失败。请从 env.example.json 创建，或运行：dart run tool/ensure_env.dart — 仅需 anon/public 密钥；service_role 绝不会在应用中使用。';

  @override
  String get routeNotFoundTitle => '页面未找到';

  @override
  String get routeNotFoundBody => '应用未定义所请求的路由：';
}
