import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/app/app.dart';
import 'package:joodcraft/core/theme/app_theme.dart';
import 'package:joodcraft/core/theme/theme_controller.dart';
import 'package:joodcraft/core/widgets/configuration_screen.dart';
import 'package:joodcraft/core/widgets/theme_toggle_button.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// التوصيل الكامل: تفضيل محفوظ ← `MaterialApp.themeMode` ← نقرة الزر.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('JoodCraftApp يطبّق الوضع المحفوظ ثم يبدّله فوراً', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      ThemeController.prefsKey: 'dark',
    });
    final ThemeController controller = ThemeController();
    await controller.load();

    await tester.pumpWidget(
      JoodCraftApp(authRepository: null, themeController: controller),
    );
    await tester.pump();

    MaterialApp app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
    expect(app.darkTheme, isNotNull);
    // السطوع الفعلي داخل الشجرة داكن رغم سطوع المنصة في الاختبارات.
    final BuildContext screen =
        tester.element(find.byType(ConfigurationScreen));
    expect(Theme.of(screen).brightness, Brightness.dark);

    // تبديل بنقرة واحدة ← إعادة بناء التطبيق بالوضع الجديد.
    await controller.toggle();
    // انتظار انتهاء تحوّر `AnimatedTheme` بين الوضعين.
    await tester.pumpAndSettle();

    app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.light);
    expect(
      Theme.of(tester.element(find.byType(ConfigurationScreen))).brightness,
      Brightness.light,
    );
  });

  testWidgets('زر ☾ يبدّل المظهر ويتبدّل أيقونته', (WidgetTester tester) async {
    final ThemeController controller = ThemeController();
    await controller.setMode(ThemeMode.light);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider<ThemeController>.value(
        value: controller,
        child: ListenableBuilder(
          listenable: controller,
          builder: (BuildContext context, Widget? _) {
            return MaterialApp(
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: controller.mode,
              home: const Scaffold(
                body: Align(
                  alignment: AlignmentDirectional.topStart,
                  child: ThemeToggleButton(),
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.pump();

    // الوضع فاتح ⇒ الأيقونة قمر (للانتقال للداكن).
    expect(find.byIcon(Icons.dark_mode_rounded), findsOneWidget);
    expect(controller.isDark, isFalse);

    await tester.tap(find.byType(ThemeToggleButton));
    await tester.pump();

    expect(controller.mode, ThemeMode.dark);
    expect(controller.isDark, isTrue);
    expect(find.byIcon(Icons.light_mode_rounded), findsOneWidget);

    await tester.tap(find.byType(ThemeToggleButton));
    await tester.pump();

    expect(controller.mode, ThemeMode.light);
    expect(find.byIcon(Icons.dark_mode_rounded), findsOneWidget);
  });
}
