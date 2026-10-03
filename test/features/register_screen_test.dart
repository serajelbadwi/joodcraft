import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/theme/app_theme.dart';
import 'package:joodcraft/features/auth/presentation/providers/auth_provider.dart';
import 'package:joodcraft/features/auth/presentation/screens/register_screen.dart';
import 'package:provider/provider.dart';

import '../support/fake_auth_repository.dart';

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
        home: const RegisterScreen(),
      ),
    );
  }

  Future<void> pumpScreen(WidgetTester tester, AuthProvider provider) async {
    await tester.pumpWidget(wrap(provider));
    await tester.pumpAndSettle();
  }

  testWidgets('تعرض كل الحقول المطلوبة بالعربية', (WidgetTester tester) async {
    final AuthProvider provider = AuthProvider(repository);
    addTearDown(provider.dispose);

    await pumpScreen(tester, provider);

    expect(find.text('إنشاء حساب'), findsOneWidget);
    expect(find.text('الاسم الكامل'), findsOneWidget);
    expect(find.text('اسم الجهة / المؤسسة (اختياري)'), findsOneWidget);
    expect(find.text('البريد الإلكتروني'), findsOneWidget);
    expect(find.text('كلمة المرور'), findsOneWidget);
    expect(find.text('تأكيد كلمة المرور'), findsOneWidget);
    expect(find.text('إنشاء الحساب'), findsOneWidget);
  });

  testWidgets('عدم تطابق كلمتي المرور يُظهر رسالة عربية',
      (WidgetTester tester) async {
    final AuthProvider provider = AuthProvider(repository);
    addTearDown(provider.dispose);

    await pumpScreen(tester, provider);

    await tester.enterText(find.byType(TextFormField).at(0), 'منى العبدالله');
    await tester.enterText(
      find.byType(TextFormField).at(2),
      'mona@jood.org',
    );
    await tester.enterText(find.byType(TextFormField).at(3), '12345678');
    await tester.enterText(find.byType(TextFormField).at(4), '87654321');

    await tester.ensureVisible(find.text('إنشاء الحساب'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('إنشاء الحساب'));
    await tester.pumpAndSettle();

    expect(find.text('كلمتا المرور غير متطابقتين.'), findsOneWidget);
    expect(repository.signUpCalls, 0, reason: 'لا يُرسل الطلب قبل صحّة التحقق');
  });

  testWidgets('إنشاء حساب ناجح يمرّر كل البيانات إلى المستودع',
      (WidgetTester tester) async {
    final AuthProvider provider = AuthProvider(repository);
    addTearDown(provider.dispose);

    await pumpScreen(tester, provider);

    await tester.enterText(find.byType(TextFormField).at(0), 'منى العبدالله');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'جمعية جود الخيرية',
    );
    await tester.enterText(
      find.byType(TextFormField).at(2),
      'mona@jood.org',
    );
    await tester.enterText(find.byType(TextFormField).at(3), '12345678');
    await tester.enterText(find.byType(TextFormField).at(4), '12345678');

    await tester.ensureVisible(find.text('إنشاء الحساب'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('إنشاء الحساب'));
    await tester.pumpAndSettle();

    expect(repository.signUpCalls, 1);
    expect(repository.lastSignUpEmail, 'mona@jood.org');
    expect(repository.lastSignUpFullName, 'منى العبدالله');
    expect(repository.lastSignUpOrganization, 'جمعية جود الخيرية');
    expect(provider.isAuthenticated, isTrue);
    // بعد التسجيل تُقرأ البيانات من profiles (المصدر الأدق) لا من الحقول.
  });
}
