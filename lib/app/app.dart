import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_constants.dart';
import '../core/locale/app_locale.dart';
import '../core/locale/locale_controller.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/theme_controller.dart';
import '../core/widgets/configuration_screen.dart';
import '../features/auth/domain/auth_repository.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../l10n/generated/app_localizations.dart';
import 'router/app_router.dart';

/// جذر تطبيق JoodCraft.
///
/// * إذا لم تُضبط مفاتيح Supabase تُعرض شاشة التهيئة بدل الانهيار.
/// * اللغة والاتجاه يُشتقّان من اللغة المختارة (العربية والأوردو RTL، والباقي
///   LTR) ويُطبَّقان فوراً بلا إعادة تشغيل عند التغيير.
class JoodCraftApp extends StatefulWidget {
  const JoodCraftApp({
    super.key,
    required this.authRepository,
    this.themeController,
    this.localeController,
  });

  /// `null` يعني أن Supabase غير مهيأ في هذه الجلسة.
  final AuthRepository? authRepository;

  /// محرّك المظهر — يُمرَّر من `main` محمّلاً مسبقاً بالتفضيل المخزَّن،
  /// وعند غيابه ينشئ التطبيق محرّكاً بوضع افتراضي ويحمّله بنفسه.
  final ThemeController? themeController;

  /// محرّك اللغة — مثل المظهر: يُمرَّر من `main` محمّلاً مسبقاً، وعند غيابه
  /// ينشئ التطبيق محرّكاً بالافتراضية (العربية) ويحمّله بنفسه.
  final LocaleController? localeController;

  @override
  State<JoodCraftApp> createState() => _JoodCraftAppState();
}

class _JoodCraftAppState extends State<JoodCraftApp> {
  late final AuthProvider _auth = AuthProvider(widget.authRepository);

  /// موجّه مُؤجَّل الإنشاء: لا يُبنى إلا عند أول استخدام، وحتى لا يُنشأ موجّهاً
  /// جديداً حتماً عند التخلّص في الشاشة غير المربوطة بـ Supabase.
  GoRouter? _routerCache;
  GoRouter get _router => _routerCache ??= AppRouter.create(_auth);

  late final ThemeController _theme =
      widget.themeController ?? ThemeController();
  late final bool _ownsThemeController = widget.themeController == null;

  late final LocaleController _locale =
      widget.localeController ?? LocaleController();
  late final bool _ownsLocaleController = widget.localeController == null;

  @override
  void initState() {
    super.initState();
    // إعادة بناء التطبيق عند تغيّر المظهر أو اللغة كي يُطبَّق كلٌّ منهما فوراً.
    _theme.addListener(_onPreferencesChanged);
    _locale.addListener(_onPreferencesChanged);
    // محرّكات مملوكة (بلا مرّر من main) ترمّل تفضيلها المخزَّن بنفسها.
    if (_ownsThemeController) unawaited(_theme.load());
    if (_ownsLocaleController) unawaited(_locale.load());
  }

  void _onPreferencesChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _theme.removeListener(_onPreferencesChanged);
    _locale.removeListener(_onPreferencesChanged);
    // تحرير الموجّه أولاً (ينتزع مستمعه من المحرّك) ثم المحرّكات نفسها.
    _routerCache?.dispose();
    _auth.dispose();
    if (_ownsThemeController) _theme.dispose();
    if (_ownsLocaleController) _locale.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // المحرّكات متاحة لكل الشجرة — بما فيها شاشة التهيئة (لمنع تفضيلات اللغة
    // والمظهر من الاختفاء قبل ربط Supabase).
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeController>.value(value: _theme),
        ChangeNotifierProvider<LocaleController>.value(value: _locale),
        if (widget.authRepository != null)
          ChangeNotifierProvider<AuthProvider>.value(value: _auth),
      ],
      child: widget.authRepository == null
          ? _buildConfigurationApp()
          : _buildRouterApp(),
    );
  }

  /// --------------- لم يُربط المشروع بـ Supabase بعد ---------------
  Widget _buildConfigurationApp() => MaterialApp(
        title: '${AppConstants.appName} — ${AppConstants.appNameAr}',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: _theme.mode,
        locale: _locale.locale,
        supportedLocales: AppLocales.locales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        builder: _directionBuilder,
        home: const ConfigurationScreen(),
      );

  /// ------------------------- التطبيق الكامل -------------------------
  Widget _buildRouterApp() => MaterialApp.router(
        title: '${AppConstants.appName} — ${AppConstants.appNameAr}',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: _theme.mode,
        routerConfig: _router,
        locale: _locale.locale,
        supportedLocales: AppLocales.locales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        // فرض الاتجاه من اللغة المختارة: RTL للعربية والأوردو، LTR لغيرهما.
        builder: _directionBuilder,
      );

  /// يغلّف الشجرة بـ `Directionality` موافق للغة الحالية، فلا تبقى RTL ثابتة.
  Widget _directionBuilder(BuildContext context, Widget? child) => Directionality(
        textDirection: _locale.textDirection,
        child: child ?? const SizedBox.shrink(),
      );
}
