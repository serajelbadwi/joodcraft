import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/theme/theme_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// اختبارات حفظ واستعادة تفضيل المظهر (ThemeMode) — جوهر ميزة التبديل.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('التخزين والتحويل', () {
    test('الوضع الافتراضي هو النظام', () {
      final ThemeController controller = ThemeController();
      expect(controller.mode, ThemeMode.system);
    });

    test('encode/parse يُدوِّران الأوضاع الثلاثة ويرفضان المجهول', () {
      expect(ThemeController.encode(ThemeMode.system), 'system');
      expect(ThemeController.encode(ThemeMode.light), 'light');
      expect(ThemeController.encode(ThemeMode.dark), 'dark');

      expect(ThemeController.parse(null), ThemeMode.system);
      expect(ThemeController.parse('light'), ThemeMode.light);
      expect(ThemeController.parse('dark'), ThemeMode.dark);
      expect(ThemeController.parse('system'), ThemeMode.system);
      // قيمة تالفة/مجهولة لا تُسقط التطبيق — تعود إلى النظام.
      expect(ThemeController.parse('banana'), ThemeMode.system);
    });

    test('setMode يحفظ التفضيل في SharedPreferences', () async {
      final ThemeController controller = ThemeController();
      await controller.setMode(ThemeMode.dark);

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(ThemeController.prefsKey), 'dark');
      expect(controller.mode, ThemeMode.dark);
    });

    test('load يستعيد الوضع المحفوظ عند إعادة التشغيل', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        ThemeController.prefsKey: 'dark',
      });
      final ThemeController controller = ThemeController();
      await controller.load();
      expect(controller.mode, ThemeMode.dark);
      expect(controller.isDark, isTrue);
    });

    test('load تتعامل مع قيمة تالفة بعودتها إلى النظام', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        ThemeController.prefsKey: 'غير صالح',
      });
      final ThemeController controller = ThemeController();
      await controller.load();
      expect(controller.mode, ThemeMode.system);
    });

    test('الحفظ يعود للوضع المخزَّن بمحرّك ثانٍ (دورة إغلاق/فتح)', () async {
      final ThemeController first = ThemeController();
      await first.setMode(ThemeMode.light);

      final ThemeController second = ThemeController();
      await second.load();
      expect(second.mode, ThemeMode.light);
    });
  });

  group('التبديل والتنبيهات', () {
    test('toggle ينقل إلى عكس المظهر المعروض', () async {
      final ThemeController controller = ThemeController();

      await controller.setMode(ThemeMode.light);
      await controller.toggle();
      expect(controller.mode, ThemeMode.dark);

      await controller.toggle();
      expect(controller.mode, ThemeMode.light);
    });

    test('toggle من وضع النظام يذهب إلى الوضع المعاكس لسطوع المنصة', () async {
      final ThemeController controller = ThemeController();
      expect(controller.mode, ThemeMode.system);

      // سطوع المنصة في الاختبارات فاتح ⇒ النظام يعرض الفاتح ⇒ النقر للداكن.
      expect(controller.isDark, isFalse);
      await controller.toggle();
      expect(controller.mode, ThemeMode.dark);
      expect(controller.isDark, isTrue);
    });

    test('setMode يُعلم المستمعين عند التغيير فقط', () async {
      final ThemeController controller = ThemeController();
      int notifications = 0;
      controller.addListener(() => notifications++);

      await controller.setMode(ThemeMode.dark);
      expect(notifications, 1);

      // إعادة ضبط الوضع نفسه بلا تغيير — بلا إشعار بلا داعٍ.
      await controller.setMode(ThemeMode.dark);
      expect(notifications, 1);

      await controller.setMode(ThemeMode.light);
      expect(notifications, 2);
      controller.dispose();
    });
  });
}
