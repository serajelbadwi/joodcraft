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

/// اختبارات شريط التنقّل العلوي الأفقي: التبويبات، التلميح النشط، وأدوات
/// المستخدم — مع ضمان الاتجاه RTL الافتراضي.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  Widget harness({
    required String currentPath,
    ValueChanged<String>? onNavigate,
    VoidCallback? onMenuTap,
    bool showLabels = true,
    bool showBrandTitle = true,
    bool showAccountDetails = true,
    AuthProvider? auth,
    Locale locale = const Locale('ar'),
  }) {
    return MultiProvider(
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

  testWidgets('يعرض كل محرّكات العمل والعلامة التجارية', (WidgetTester tester) async {
    await tester.pumpWidget(harness(currentPath: AppRoutes.dashboard));
    await tester.pumpAndSettle();

    expect(find.text('JoodCraft'), findsOneWidget);
    expect(find.text('لوحة التحكم'), findsOneWidget);
    expect(find.text('محـرّك الشهادات'), findsOneWidget);
    expect(find.text('مكتبة القوالب'), findsOneWidget);
    expect(find.text('الهوية والبروفايل'), findsOneWidget);
  });

  testWidgets('النقر على تبويب يُمرّر مساره', (WidgetTester tester) async {
    // مساحة عريضة حتى تظهر كل التبويبات دون تمرير أفقي.
    await tester.binding.setSurfaceSize(const Size(1600, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    String? navigated;
    await tester.pumpWidget(
      harness(
        currentPath: AppRoutes.dashboard,
        onNavigate: (String path) => navigated = path,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('محـرّك العقود').first);
    await tester.pumpAndSettle();

    expect(navigated, AppRoutes.contractBuilder);
  });

  testWidgets('يُظهر زر القائمة ويُخفيه حسب الحاجة', (WidgetTester tester) async {
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
    await tester.pumpWidget(
      harness(currentPath: AppRoutes.dashboard, showLabels: false),
    );
    await tester.pumpAndSettle();

    expect(find.text('مكتبة القوالب'), findsNothing);
    expect(find.byIcon(Icons.collections_bookmark_rounded), findsOneWidget);
    expect(find.byTooltip('مكتبة القوالب'), findsOneWidget);
  });

  testWidgets('يعرض أدوات اللغة وشارة «محلي» بلا حساب بعيد',
      (WidgetTester tester) async {
    await tester.pumpWidget(harness(currentPath: AppRoutes.dashboard));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.translate_rounded), findsOneWidget);
    expect(find.byType(CircleAvatar), findsOneWidget);
    // التطبيق محلي: شارة تعلن ذلك بدل زرّ خروج لا معنى له بلا حساب.
    expect(find.byIcon(Icons.offline_bolt_rounded), findsOneWidget);
    expect(find.text('محلي'), findsOneWidget);
    expect(find.byIcon(Icons.logout_rounded), findsNothing);
  });

  testWidgets('يعرض الخروج فقط عند وجود حساب مربوط',
      (WidgetTester tester) async {
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

    expect(find.byIcon(Icons.logout_rounded), findsOneWidget);
    expect(find.byIcon(Icons.offline_bolt_rounded), findsNothing);
  });

  testWidgets('«مستند جديد» خرج من الشريط العلوي إلى قائمة «ملف»',
      (WidgetTester tester) async {
    await tester.pumpWidget(harness(currentPath: AppRoutes.dashboard));
    await tester.pumpAndSettle();

    // لا تبويب «مشروع جديد» يزاحم تبويبات المحرّكات، ولا زرّ إنشاء في الشريط:
    // المدخل الوحيد هنا هو قائمة «ملف» (أو Ctrl+N).
    expect(find.text('مشروع جديد'), findsNothing);
    expect(find.text('+ جديد'), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('top-tab-${AppRoutes.newProject}')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('top-new-document')),
      findsNothing,
    );
  });
}
