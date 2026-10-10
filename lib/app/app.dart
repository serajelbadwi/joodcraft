import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/audit/export_audit_log.dart';
import '../core/constants/app_constants.dart';
import '../core/locale/app_locale.dart';
import '../core/locale/locale_controller.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/theme_controller.dart';
import '../core/widgets/bidi_arrow_navigation.dart';
import '../features/auth/domain/admin_repository.dart';
import '../features/auth/domain/app_user.dart';
import '../features/auth/domain/auth_repository.dart';
import '../features/auth/presentation/providers/admin_accounts_controller.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../l10n/generated/app_localizations.dart';
import 'router/app_router.dart';

/// جذر تطبيق JoodCraft — **محلي أولاً**: لا تهيئة شبكة إطلاقاً، فالمشاريع
/// والقوالب في قاعدة محلية، والحساب محلي كذلك ([LocalAuthRepository]).
///
/// * يُمرَّر [authRepository] من `main` (حساب محلي على القرص)، فيصبح تسجيل
///   الدخول **إلزامياً** قبل فتح أي شاشة. تمريره `null` (اختبارات/تشغيل بلا
///   حساب) يفتح التطبيق بلا بوابة — فالغياب يعني "لا مصادقة مُهيّأة".
/// * اللغة والاتجاه يُشتقّان من اللغة المختارة (العربية والأوردو RTL، والباقي
///   LTR) ويُطبَّقان فوراً بلا إعادة تشغيل عند التغيير.
class JoodCraftApp extends StatefulWidget {
  const JoodCraftApp({
    super.key,
    this.authRepository,
    this.themeController,
    this.localeController,
    this.auditLog,
  });

  /// مستودع المصادقة المحلي — يُمرَّر من `main` بعد تجهيز `SharedPreferences`،
  /// فيطلب التطبيق تسجيل الدخول قبل أي شاشة. `null` = لا مصادقة مُهيّأة.
  final AuthRepository? authRepository;

  /// محرّك المظهر — يُمرَّر من `main` محمّلاً مسبقاً بالتفضيل المخزَّن،
  /// وعند غيابه ينشئ التطبيق محرّكاً بوضع افتراضي ويحمّله بنفسه.
  final ThemeController? themeController;

  /// محرّك اللغة — مثل المظهر: يُمرَّر من `main` محمّلاً مسبقاً، وعند غيابه
  /// ينشئ التطبيق محرّكاً بالافتراضية (العربية) ويحمّله بنفسه.
  final LocaleController? localeController;

  /// سجل التصدير — يُمرَّر من `main` بعد استعادته، فيعرف التطبيق ما صدر سابقاً
  /// من اللحظة الأولى. وعند غيابه يُستعمل السجل العام [ExportAuditLog.instance].
  final ExportAuditLog? auditLog;

  @override
  State<JoodCraftApp> createState() => _JoodCraftAppState();
}

class _JoodCraftAppState extends State<JoodCraftApp> {
  // لا افتراضي هنا عن قصد: افتراض مستودع حقيقي كان يفرض بوابة دخول على كل
  // شجرة اختبار تُمرّر `authRepository: null` فتُسقطها. `main` هو المصدر
  // الوحيد الذي يجهّز الحساب المحلي في الوضع الحقيقي.
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

  /// إدارة المديرين: تُربط بمستودع المصادقة **إن كان** ينفّذ واجهة الإدارة
  /// (‎`LocalAuthRepository`). ومع مستودع وهمي أو غيابه تُعلن الشاشة أن الإدارة
  /// غير متاحة بلا انهيار.
  late final AdminAccountsController _admins = AdminAccountsController(
    widget.authRepository is AdminRepository
        ? widget.authRepository as AdminRepository
        : null,
  );

  late final ExportAuditLog _audit = widget.auditLog ?? ExportAuditLog.instance;

  @override
  void initState() {
    super.initState();
    // إعادة بناء التطبيق عند تغيّر المظهر أو اللغة كي يُطبَّق كلٌّ منهما فوراً.
    _theme.addListener(_onPreferencesChanged);
    _locale.addListener(_onPreferencesChanged);
    // ربط السجل بالمستخدم الحالي: فيُسجَّل من أصدر كل ملف بلا أن تعرف طبقة
    // الأرشفة شيئاً عن الواجهة ولا عن `AuthProvider`.
    ExportAuditLog.currentAdmin = () {
      final AppUser? user = _auth.user;
      if (user == null) return (id: null, email: null, name: null);
      return (id: user.id, email: user.email, name: user.displayName);
    };
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
    // الربط يشير إلى مزوّد سيُحرَّر — يُفرَّغ حتى لا يُقرأ بعد التخلّص.
    ExportAuditLog.currentAdmin = null;
    _admins.dispose();
    _auth.dispose();
    if (_ownsThemeController) _theme.dispose();
    if (_ownsLocaleController) _locale.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // المحرّكات متاحة لكل الشجرة — بما فيها شاشات الدخول/الإنشاء، فيصل إليها
    // التفضيل المحفوظ للغة والمظهر قبل التحقق من الهوية.
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeController>.value(value: _theme),
        ChangeNotifierProvider<LocaleController>.value(value: _locale),
        // يُوفَّر دائماً — حتى بلا حساب بعيد — لأن الشريط العلوي يعرض حالة
        // الحساب/الوضع المحلي، وغيابه كان يُسقط الشجرة.
        ChangeNotifierProvider<AuthProvider>.value(value: _auth),
        // إدارة المديرين وسجل التصدير: يُوفَّران دائماً (ولو بلا مستودع) كي
        // تُبنى شاشة الإدارة في أي وضع وتُعلن حالتها بلا انهيار.
        ChangeNotifierProvider<AdminAccountsController>.value(value: _admins),
        ChangeNotifierProvider<ExportAuditLog>.value(value: _audit),
      ],
      // التطبيق يُبنى دائماً بمساره الكامل — لا شاشة تهيئة شبكة ولا اعتماد على
      // مفاتيح خارجية. المصادقة محلية، وإعادة التوجيه في [AppRouter] هي التي
      // تحجب الشاشات حتى يسجّل المستخدم الدخول.
      child: _buildRouterApp(),
    );
  }

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

  /// يغلّف الشجرة بـ `Directionality` موافق للغة الحالية، فلا تبقى RTL ثابتة،
  /// ويُثبّت [BidiArrowNavigation] فوق الراوتر والحوارات: مفاتيح الأسهم
  /// داخل حقول النص العربية تتحرّك بصرياً (يساراً/يميناً) لا بترتيب منطقيّ
  /// يجعل المؤشر يمشي عكس السهم.
  Widget _directionBuilder(BuildContext context, Widget? child) => Directionality(
        textDirection: _locale.textDirection,
        child: BidiArrowNavigation(
          child: child ?? const SizedBox.shrink(),
        ),
      );
}
