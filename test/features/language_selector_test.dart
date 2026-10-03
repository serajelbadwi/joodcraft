import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/app/app.dart';
import 'package:joodcraft/core/locale/app_locale.dart';
import 'package:joodcraft/core/locale/locale_controller.dart';
import 'package:joodcraft/core/theme/theme_controller.dart';
import 'package:joodcraft/core/widgets/configuration_screen.dart';
import 'package:joodcraft/core/widgets/language_menu_button.dart';
import 'package:joodcraft/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  Widget harness(LocaleController controller) {
    return ChangeNotifierProvider<LocaleController>.value(
      value: controller,
      child: ListenableBuilder(
        listenable: controller,
        builder: (BuildContext context, Widget? _) => MaterialApp(
          locale: controller.locale,
          supportedLocales: AppLocales.locales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const Scaffold(
            body: Center(child: LanguageMenuButton(showLabel: true)),
          ),
        ),
      ),
    );
  }

  testWidgets('يعرض اللغات بأسمائها الأصلية ويبدّل اللغة والاتجاه فوراً',
      (WidgetTester tester) async {
    final LocaleController controller = LocaleController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(harness(controller));
    await tester.pumpAndSettle();

    // الاسم الحالي معروض بلغته الأصلية (العربية).
    expect(find.text('العربية'), findsOneWidget);

    await tester.tap(find.text('العربية'));
    await tester.pumpAndSettle();

    // القائمة تعرض كل اللغات بأسمائها الأصلية.
    expect(find.text('Français'), findsWidgets);
    expect(find.text('简体中文'), findsOneWidget);
    expect(find.text('Русский'), findsOneWidget);

    await tester.tap(find.text('Français').last);
    await tester.pumpAndSettle();

    expect(controller.locale.languageCode, 'fr');
    expect(find.text('Français'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byType(LanguageMenuButton))),
      TextDirection.ltr,
    );
  });

  testWidgets('JoodCraftApp يطبّق اللغة المخزَّنة واتجاهها ثم يبدّلها',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      LocaleController.prefsKey: 'en',
    });
    final LocaleController locale = LocaleController();
    await locale.load();
    final ThemeController theme = ThemeController();
    await theme.load();

    await tester.pumpWidget(
      JoodCraftApp(
        authRepository: null,
        themeController: theme,
        localeController: locale,
      ),
    );
    await tester.pump();

    final MaterialApp app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.locale, const Locale('en'));
    expect(app.supportedLocales, AppLocales.locales);
    expect(app.localizationsDelegates, isNotNull);
    expect(
      Directionality.of(tester.element(find.byType(ConfigurationScreen))),
      TextDirection.ltr,
    );

    // التبديل إلى الأوردو يقلب الاتجاه إلى RTL بلا إعادة تشغيل.
    await locale.setLocale(const Locale('ur'));
    await tester.pumpAndSettle();

    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).locale,
      const Locale('ur'),
    );
    expect(
      Directionality.of(tester.element(find.byType(ConfigurationScreen))),
      TextDirection.rtl,
    );
  });
}
