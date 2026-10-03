import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/theme/app_theme.dart';
import 'package:joodcraft/core/widgets/joodcraft_logo.dart';
import 'package:joodcraft/features/auth/presentation/providers/auth_provider.dart';
import 'package:joodcraft/features/auth/presentation/screens/login_screen.dart';
import 'package:provider/provider.dart';

import '../support/fake_auth_repository.dart';

/// اختبار بناء شاشة الدخول كواجهة عربية RTL مليانة بعقود التحقق.
void main() {
  late FakeAuthRepository repository;

  setUp(() => repository = FakeAuthRepository());
  tearDown(() => repository.close());

  Widget wrap(AuthProvider provider) {
    return ChangeNotifierProvider<AuthProvider>.value(
      value: provider,
      child: MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('ar'),
        supportedLocales: const <Locale>[Locale('ar')],
        localizationsDelegates: const <LocalizationsDelegate<Object>>[
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const LoginScreen(),
      ),
    );
  }

  testWidgets('تعرض العنوان والحقول والأزرار بالعربية', (WidgetTester tester) async {
    final AuthProvider provider = AuthProvider(repository);
    addTearDown(provider.dispose);

    await tester.pumpWidget(wrap(provider));
    await tester.pumpAndSettle();

    expect(find.text('تسجيل الدخول'), findsOneWidget);
    expect(find.text('البريد الإلكتروني'), findsWidgets);
    expect(find.text('كلمة المرور'), findsOneWidget);
    expect(find.text('دخول إلى اللوحة'), findsOneWidget);
    expect(find.text('نسيت كلمة المرور؟'), findsOneWidget);
    expect(find.text('أنشئ حساباً جديداً'), findsOneWidget);
  });

  testWidgets('تتحول إلى تخطيط عمودين على الشاشة العريضة بلا تجاوز',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final AuthProvider provider = AuthProvider(repository);
    addTearDown(provider.dispose);

    await tester.pumpWidget(wrap(provider));
    await tester.pumpAndSettle();

    // لوحة الهوية تظهر في التخطيط العريض (شعار الأصل بدل الرسم البرمجي).
    expect(
      find.byWidgetPredicate(
        (Widget w) =>
            w is Image &&
            w.image is AssetImage &&
            (w.image as AssetImage).assetName == kJoodCraftLogoAsset,
      ),
      findsWidgets,
    );
    expect(
      find.textContaining('شهاداتك وعقودك الرسمية'),
      findsOneWidget,
    );
    expect(find.text('دخول إلى اللوحة'), findsOneWidget);
  });

  testWidgets('الاتجاه RTL مفروض في الواجهة', (WidgetTester tester) async {
    final AuthProvider provider = AuthProvider(repository);
    addTearDown(provider.dispose);

    await tester.pumpWidget(wrap(provider));
    await tester.pumpAndSettle();

    final Directionality directionality =
        tester.widget(find.byType(Directionality).first);
    expect(directionality.textDirection, TextDirection.rtl);
  });

  testWidgets('الضغط على الدخول بلا بيانات يُظهر أخطاء التحقق العربية',
      (WidgetTester tester) async {
    final AuthProvider provider = AuthProvider(repository);
    addTearDown(provider.dispose);

    await tester.pumpWidget(wrap(provider));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('دخول إلى اللوحة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('دخول إلى اللوحة'));
    await tester.pumpAndSettle();

    expect(find.text('البريد الإلكتروني مطلوب.'), findsOneWidget);
    expect(find.text('كلمة المرور مطلوبة.'), findsOneWidget);
  });

  testWidgets('بيانات صحيحة تُنفّذ الدخول وتحدّث حالة المصادقة',
      (WidgetTester tester) async {
    final AuthProvider provider = AuthProvider(repository);
    addTearDown(provider.dispose);

    await tester.pumpWidget(wrap(provider));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'abdullah@jood.org',
    );
    await tester.enterText(find.byType(TextFormField).at(1), '12345678');
    await tester.ensureVisible(find.text('دخول إلى اللوحة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('دخول إلى اللوحة'));
    await tester.pumpAndSettle();

    expect(provider.isAuthenticated, isTrue);
    expect(provider.user?.email, 'abdullah@jood.org');
  });
}
