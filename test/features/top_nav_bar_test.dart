import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/app/router/app_routes.dart';
import 'package:joodcraft/core/locale/app_locale.dart';
import 'package:joodcraft/core/locale/locale_controller.dart';
import 'package:joodcraft/core/theme/app_theme.dart';
import 'package:joodcraft/core/theme/theme_controller.dart';
import 'package:joodcraft/features/auth/presentation/providers/auth_provider.dart';
import 'package:joodcraft/features/dashboard/presentation/widgets/top_nav_bar.dart';
import 'package:joodcraft/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_auth_repository.dart';

/// اختبارات شريط التنقّل العلوي **بعد إعادة تنظيمه إلى ستة عناصر**:
///
/// 1. لوحة التحكم (مباشر) 2. المحرّكات ▾ 3. التوليد الجماعي (مباشر)
/// 4. المكتبات ▾ 5. الإدارة ▾ 6. الحساب ▾ (في الطرف)
///
/// القواعد التي يتحقق منها: الوجهات الخفية لا تزال قابلة للوصول من داخل
/// القوائم، ولا مسار ولا شاشة يضيعان، والاتجاه RTL مضمون.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    // لا `setSurfaceSize` في `setUp` ولا `tearDown`: كلاهما يعمل خارج نطاق
    // الاختبار فيرمي `'inTest': is not true` (والثاني يتسبّب في انهيار متسلسل
    // للمشغّل). التوسيع كله يجريه `widen` داخل كل اختبار.
  });

  /// يُوسّع سطح الاختبار فوق عتبة 1600px: مجموعتا «المكتبات» و«الإدارة»
  /// تخرجان من نطاق التمرير الأفقي في النوافذ الأضيق، فتتعذّل مراجعتهما.
  Future<void> widen(WidgetTester tester) async {
    final TestWidgetsFlutterBinding binding = TestWidgetsFlutterBinding.instance;
    await binding.setSurfaceSize(const Size(1920, 1080));
    await tester.pump();
  }

  Widget harness({
    required String currentPath,
    ValueChanged<String>? onNavigate,
    VoidCallback? onMenuTap,
    bool showLabels = true,
    bool showBrandTitle = true,
    bool showAccountDetails = true,
    AuthProvider? auth,
    Locale locale = const Locale('ar'),
  }) {    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(
          value: auth ?? AuthProvider(null),
        ),
        ChangeNotifierProvider<ThemeController>.value(value: ThemeController()),
        ChangeNotifierProvider<LocaleController>.value(value: LocaleController()),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        locale: locale,
        supportedLocales: AppLocales.locales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(
          body: TopNavBar(
            currentPath: currentPath,
            onNavigate: onNavigate ?? (_) {},
            onMenuTap: onMenuTap,
            showLabels: showLabels,
            showBrandTitle: showBrandTitle,
            showAccountDetails: showAccountDetails,
          ),
        ),
      ),
    );
  }

  /// مفتاحا كل عنصر من عناصر الشريط الستة (خمسة تنقّل + الحساب).
  List<Finder> sixItems() => <Finder>[
        find.byKey(const ValueKey<String>('top-tab-${AppRoutes.dashboard}')),
        find.byKey(const ValueKey<String>('top-menu-editors')),
        find.byKey(const ValueKey<String>('top-tab-${AppRoutes.batchProcessor}')),
        find.byKey(const ValueKey<String>('top-menu-libraries')),
        find.byKey(const ValueKey<String>('top-menu-admin')),
        find.byKey(const ValueKey<String>('top-account-menu')),
      ];

  // ---------------------------------------------------------------------------
  //  العدد والمجموعات
  // ---------------------------------------------------------------------------

  testWidgets('الشريط يعرض ستة عناصر لا أحد عشر', (WidgetTester tester) async {
    await widen(tester);
    await tester.pumpWidget(harness(currentPath: AppRoutes.dashboard));
    await tester.pumpAndSettle();

    expect(find.text('JoodCraft'), findsOneWidget);

    for (final Finder item in sixItems()) {
      expect(item, findsOneWidget, reason: 'عنصر مفقود من الشريط: $item');
    }

    // الوجهات الخفية لم تعد تبويبات مستقلة…
    expect(find.text('محـرّك الشهادات'), findsNothing);
    expect(find.text('محـرّك العقود'), findsNothing);
    expect(find.text('جود كاتب'), findsNothing);
    expect(find.text('مكتبة القوالب'), findsNothing);
    expect(find.text('الأصول والتوقيعات'), findsNothing);
    expect(find.text('الهوية والبروفايل'), findsNothing);
    expect(find.text('إدارة المديرين'), findsNothing);
    // «الدعوات» صارت جزءاً من التوليد الجماعي فخرجت من الشريط (لا من التطبيق).
    expect(find.text('دعوات شخصية جماعية'), findsNothing);
    // «مشروع جديد» نافذة عائمة من قائمة «ملف» لا تبويب.
    expect(find.text('مشروع جديد'), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('top-tab-${AppRoutes.newProject}')),
      findsNothing,
    );
  });

  testWidgets('التسميات الخمس ظاهرة في الوضع العادي', (WidgetTester tester) async {
    await widen(tester);
    await tester.pumpWidget(harness(currentPath: AppRoutes.dashboard));
    await tester.pumpAndSettle();

    expect(find.text('لوحة التحكم'), findsOneWidget);
    expect(find.text('المحرّكات'), findsOneWidget);
    expect(find.text('التوليد الجماعي'), findsOneWidget);
    expect(find.text('المكتبات'), findsOneWidget);
    expect(find.text('الإدارة'), findsOneWidget);
  });

  // ---------------------------------------------------------------------------
  //  التنقل المباشر
  // ---------------------------------------------------------------------------

  testWidgets('النقر على تبويب مباشر يُمرّر مساره', (WidgetTester tester) async {
    await widen(tester);
    await widen(tester);
    String? navigated;
    await tester.pumpWidget(
      harness(
        currentPath: AppRoutes.dashboard,
        onNavigate: (String path) => navigated = path,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('التوليد الجماعي'));
    await tester.pumpAndSettle();

    expect(navigated, AppRoutes.batchProcessor);
  });

  testWidgets('التبويب النشط يعكس المسار الحالي', (WidgetTester tester) async {
    await widen(tester);
    await tester.pumpWidget(harness(currentPath: AppRoutes.batchProcessor));
    await tester.pumpAndSettle();

    // كبسولة التمييز الأساسية = لون primary على تبويب المسار الحالي.
    final Container active = tester.widget<Container>(
      find
          .descendant(
            of: find.byKey(
              const ValueKey<String>('top-tab-${AppRoutes.batchProcessor}'),
            ),
            matching: find.byType(Container),
          )
          .first,
    );
    expect(
      active.decoration,
      isA<BoxDecoration>().having(
        (BoxDecoration d) => d.color,
        'color',
        isNotNull,
      ),
    );
  });

  // ---------------------------------------------------------------------------
  //  القوائم المنسدلة
  // ---------------------------------------------------------------------------

  testWidgets('قائمة المحرّكات تعرض محرّكاتها الثلاثة وتفتح المختار',
      (WidgetTester tester) async {
    await widen(tester);
    String? navigated;
    await tester.pumpWidget(
      harness(
        currentPath: AppRoutes.dashboard,
        onNavigate: (String path) => navigated = path,
      ),
    );
    await tester.pumpAndSettle();

    // قبل الضغط: البنود داخل القائمة غير مبنية أصلاً.
    expect(find.text('محـرّك الشهادات'), findsNothing);

    await tester.tap(find.byKey(const ValueKey<String>('top-menu-editors')));
    await tester.pumpAndSettle();

    expect(find.text('محـرّك الشهادات'), findsOneWidget);
    expect(find.text('محـرّك العقود'), findsOneWidget);
    expect(find.text('جود كاتب'), findsOneWidget);

    await tester.tap(find.text('محـرّك العقود'));
    await tester.pumpAndSettle();

    expect(navigated, AppRoutes.contractBuilder);
    // القائمة تُغلق تلقائياً بعد الاختيار.
    expect(find.text('محـرّك الشهادات'), findsNothing);
  });

  testWidgets('قائمة المكتبات تعرض مكتباتها الثلاث وتفتح المختار',
      (WidgetTester tester) async {
    await widen(tester);
    String? navigated;
    await tester.pumpWidget(
      harness(
        currentPath: AppRoutes.dashboard,
        onNavigate: (String path) => navigated = path,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('مكتبة القوالب'), findsNothing);

    await tester.tap(find.byKey(const ValueKey<String>('top-menu-libraries')));
    await tester.pumpAndSettle();

    expect(find.text('مكتبة القوالب'), findsOneWidget);
    expect(find.text('الأصول والتوقيعات'), findsOneWidget);
    expect(find.text('الهوية والبروفايل'), findsOneWidget);

    await tester.tap(find.text('مكتبة القوالب'));
    await tester.pumpAndSettle();

    expect(navigated, AppRoutes.templates);
    expect(find.text('مكتبة القوالب'), findsNothing);
  });

  testWidgets('قائمة الإدارة تعرض إدارة المديرين وتفتحها',
      (WidgetTester tester) async {
    await widen(tester);
    String? navigated;
    await tester.pumpWidget(
      harness(
        currentPath: AppRoutes.dashboard,
        onNavigate: (String path) => navigated = path,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('إدارة المديرين'), findsNothing);

    await tester.tap(find.byKey(const ValueKey<String>('top-menu-admin')));
    await tester.pumpAndSettle();

    expect(find.text('إدارة المديرين'), findsOneWidget);

    await tester.tap(find.text('إدارة المديرين'));
    await tester.pumpAndSettle();

    expect(navigated, AppRoutes.admins);
    expect(find.text('إدارة المديرين'), findsNothing);
  });

  testWidgets('كل وجهة مخفية ما تزال قابلة للوصول من مجموعتها',
      (WidgetTester tester) async {
    await widen(tester);
    final Map<String, String> menuToRoute = <String, String>{
      'top-menu-editors': AppRoutes.certificateBuilder,
      'top-menu-libraries': AppRoutes.brand,
      'top-menu-admin': AppRoutes.admins,
    };
    final Map<String, Finder> entryToFinder = <String, Finder>{
      AppRoutes.certificateBuilder: find.text('محـرّك الشهادات'),
      AppRoutes.brand: find.text('الهوية والبروفايل'),
      AppRoutes.admins: find.text('إدارة المديرين'),
    };

    for (final MapEntry<String, String> menu in menuToRoute.entries) {
      await tester.pumpWidget(harness(currentPath: AppRoutes.dashboard));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ValueKey<String>(menu.key)));
      await tester.pumpAndSettle();

      final Finder entry = entryToFinder[menu.value]!;
      expect(entry, findsOneWidget, reason: 'الوجهة ${menu.value} غير قابلة للوصول');
    }
  });

  // ---------------------------------------------------------------------------
  //  العرض والأدوات
  // ---------------------------------------------------------------------------

  testWidgets('يُظهر زر القائمة ويُخفيه حسب الحاجة', (WidgetTester tester) async {
    await widen(tester);
    await tester.pumpWidget(
      harness(currentPath: AppRoutes.dashboard, onMenuTap: () {}),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.menu_rounded), findsOneWidget);

    await tester.pumpWidget(harness(currentPath: AppRoutes.dashboard));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.menu_rounded), findsNothing);
  });

  testWidgets('يُخفي التسميات في الوضع المضغوط ويُبقي الأيقونات',
      (WidgetTester tester) async {
    await widen(tester);
    await tester.pumpWidget(
      harness(currentPath: AppRoutes.dashboard, showLabels: false),
    );
    await tester.pumpAndSettle();

    expect(find.text('المكتبات'), findsNothing);
    expect(find.byIcon(Icons.collections_bookmark_rounded), findsOneWidget);
    // التلميح يسدّ مكان النص المخفي.
    expect(find.byTooltip('المكتبات'), findsOneWidget);
    expect(find.byTooltip('المحرّكات'), findsOneWidget);
    expect(find.byTooltip('الإدارة'), findsOneWidget);
  });

  testWidgets('يعرض أدوات اللغة وشارة «محلي» بلا حساب بعيد',
      (WidgetTester tester) async {
    await widen(tester);
    await tester.pumpWidget(harness(currentPath: AppRoutes.dashboard));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.translate_rounded), findsOneWidget);
    expect(find.byType(CircleAvatar), findsOneWidget);
    // التطبيق محلي: شارة تعلن ذلك بدل زرّ خروج لا معنى له بلا حساب.
    expect(find.byIcon(Icons.offline_bolt_rounded), findsOneWidget);
    expect(find.text('محلي'), findsOneWidget);
    expect(find.byIcon(Icons.logout_rounded), findsNothing);
  });

  testWidgets('قائمة الحساب تعرض البروفايل وتسجيل الخروج',
      (WidgetTester tester) async {
    await widen(tester);
    final FakeAuthRepository repository = FakeAuthRepository();
    final AuthProvider auth = AuthProvider(repository);
    await auth.signIn(email: 'user@joodcraft.dev', password: 'secret');
    addTearDown(() {
      auth.dispose();
      repository.close();
    });

    await tester.pumpWidget(
      harness(currentPath: AppRoutes.dashboard, auth: auth),
    );
    await tester.pumpAndSettle();

    // الشريط نفسه خفيف: لا زرّ خروج مستقل يزاحم الطرف، بل داخل القائمة.
    expect(find.byIcon(Icons.logout_rounded), findsNothing);
    expect(find.byIcon(Icons.offline_bolt_rounded), findsNothing);

    await tester.tap(find.byKey(const ValueKey<String>('top-account-menu')));
    await tester.pumpAndSettle();

    // البروفايل: الاسم والبريد داخل القائمة.
    expect(find.text('user@joodcraft.dev'), findsOneWidget);
    expect(find.byIcon(Icons.logout_rounded), findsOneWidget);
  });

  testWidgets('قائمة الحساب في الوضع المحلي تشرح الحفظ بلا خروج',
      (WidgetTester tester) async {
    await widen(tester);
    await tester.pumpWidget(harness(currentPath: AppRoutes.dashboard));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('top-account-menu')));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.logout_rounded), findsNothing);
    expect(
      find.textContaining('الحفظ محلي على هذا الجهاز'),
      findsOneWidget,
    );
  });
}
