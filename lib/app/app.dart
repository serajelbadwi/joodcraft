import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/theme_controller.dart';
import '../core/widgets/configuration_screen.dart';
import '../features/auth/domain/auth_repository.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import 'router/app_router.dart';

/// جذر تطبيق JoodCraft.
///
/// * إذا لم تُضبط مفاتيح Supabase تُعرض شاشة التهيئة بدل الانهيار.
/// * العربية هي اللغة الوحيدة، والاتجاه RTL مفروض على الشجرة بالكامل.
class JoodCraftApp extends StatefulWidget {
  const JoodCraftApp({
    super.key,
    required this.authRepository,
    this.themeController,
  });

  /// `null` يعني أن Supabase غير مهيأ في هذه الجلسة.
  final AuthRepository? authRepository;

  /// محرّك المظهر — يُمرَّر من `main` محمّلاً مسبقاً بالتفضيل المخزَّن،
  /// وعند غيابه ينشئ التطبيق محرّكاً بوضع افتراضي ويحمّله بنفسه.
  final ThemeController? themeController;

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

  @override
  void initState() {
    super.initState();
    // إعادة بناء التطبيق عند تغيّر المظهر كي يُطبَّق `themeMode` فوراً.
    _theme.addListener(_onThemeChanged);
    // محرّك مملوك (بدون مرّر من main) يرمّل تفضيله المخزَّن بنفسه.
    if (_ownsThemeController) unawaited(_theme.load());
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  static const List<LocalizationsDelegate<Object>> _delegates =
      <LocalizationsDelegate<Object>>[
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  @override
  void dispose() {
    _theme.removeListener(_onThemeChanged);
    // تحرير الموجّه أولاً (ينتزع مستمعه من المحرّك) ثم المحرّك نفسه.
    _routerCache?.dispose();
    _auth.dispose();
    if (_ownsThemeController) _theme.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // --------------- لم يُربط المشروع بـ Supabase بعد ---------------
    if (widget.authRepository == null) {
      return MaterialApp(
        title: '${AppConstants.appName} — ${AppConstants.appNameAr}',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: _theme.mode,
        locale: const Locale('ar'),
        supportedLocales: const <Locale>[Locale('ar')],
        localizationsDelegates: _delegates,
        home: const ConfigurationScreen(),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: _auth),
        ChangeNotifierProvider<ThemeController>.value(value: _theme),
      ],
      child: MaterialApp.router(
        title: '${AppConstants.appName} — ${AppConstants.appNameAr}',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: _theme.mode,
        routerConfig: _router,
        locale: const Locale('ar'),
        supportedLocales: const <Locale>[Locale('ar')],
        localizationsDelegates: _delegates,
        // ضمان الاتجاه RTL حتى لو تغيّر مصدر اللغة لاحقاً.
        builder: (BuildContext context, Widget? child) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: child ?? const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}
