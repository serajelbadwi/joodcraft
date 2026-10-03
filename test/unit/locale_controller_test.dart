import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/locale/locale_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test('الافتراضية العربية قبل أي تخزين', () {
    final LocaleController controller = LocaleController();
    addTearDown(controller.dispose);

    expect(controller.locale.languageCode, 'ar');
    expect(controller.textDirection, TextDirection.rtl);
    expect(controller.isRtl, isTrue);
  });

  test('load يستعيد اللغة المخزَّنة', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      LocaleController.prefsKey: 'fr',
    });
    final LocaleController controller = LocaleController();
    addTearDown(controller.dispose);

    await controller.load();

    expect(controller.locale.languageCode, 'fr');
    expect(controller.textDirection, TextDirection.ltr);
    expect(controller.appLocale.nativeName, 'Français');
  });

  test('setLocale يحفظ على الجهاز ويُستعاد في جلسة جديدة', () async {
    final LocaleController controller = LocaleController();
    addTearDown(controller.dispose);

    await controller.setLocale(const Locale('ur'));

    expect(controller.locale.languageCode, 'ur');
    expect(controller.isRtl, isTrue);

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(LocaleController.prefsKey), 'ur');

    // محرّك جديد على نفس التخزين يستعيد اللغة.
    final LocaleController restarted = LocaleController();
    addTearDown(restarted.dispose);
    await restarted.load();
    expect(restarted.locale.languageCode, 'ur');
  });

  test('setLocale يُخطر المستمعين فقط عند تغيّر فعلي', () async {
    final LocaleController controller = LocaleController();
    addTearDown(controller.dispose);

    int notifications = 0;
    controller.addListener(() => notifications++);

    await controller.setLocale(const Locale('de'));
    expect(notifications, 1);

    // القيم غير المدعومة تُحلّ إلى الافتراضية (العربية) فتُحدث تغييراً فعلياً.
    await controller.setLocale(const Locale('ar'));
    expect(notifications, 2);

    // تكرار اللغة نفسها لا يُخطر.
    await controller.setLocale(const Locale('ar'));
    expect(notifications, 2);
  });

  test('قيمة مخزَّنة مجهولة تعود للعربية', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      LocaleController.prefsKey: 'xx-YY',
    });
    final LocaleController controller = LocaleController();
    addTearDown(controller.dispose);

    await controller.load();

    expect(controller.locale.languageCode, 'ar');
  });
}
