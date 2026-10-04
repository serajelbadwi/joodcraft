import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/fonts/custom_font_controller.dart';
import 'package:joodcraft/core/fonts/custom_font_store.dart';
import 'package:joodcraft/core/fonts/system_font_font_loader.dart';
import 'package:joodcraft/core/fonts/windows_system_font_service.dart';

/// حرس التهدئة: خدمة خطوط النظام يجب ألا ترمي أو تكسر شيئاً على المنصات غير
/// Windows (الويب/الجوال)، وأن تعود دائماً بقائمة فارغة.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('الفحص على منصة غير Windows يُرجع فراغاً بلا استثناء', () async {
    final WindowsFontDiscoveryResult result =
        await WindowsSystemFontService.discover(platform: 'linux');

    expect(result.families, isEmpty);
    expect(result.scannedDirs, isEmpty);
    expect(result.error, isNull);
  });

  test('منصات الاختبار/الويب/الجوال لا تُدعم خطوط النظام', () {
    // المنصة الافتراضية في اختبارات فلاتر هي Android، والويب مستثنى صراحة.
    expect(WindowsSystemFontService.isSupported, isFalse);
  });

  test('تحميل خط نظام على منصة غير مدعومة يُرجع null بلا رمي', () async {
    final SystemFontLoadResult? loaded =
        await SystemFontFontLoader.loadSystemFont('Arial');

    expect(loaded, isNull);
    expect(SystemFontFontLoader.isRegistered('Arial'), isFalse);
  });

  test('فحص خطوط النظام في المتحكّم آمن على منصة غير مدعومة', () async {
    final CustomFontController controller =
        CustomFontController(store: InMemoryCustomFontStore());

    expect(controller.systemFamilies, isEmpty);
    expect(controller.hasSystemFonts, isFalse);

    await controller.scanSystemFonts();

    expect(controller.systemFamilies, isEmpty);
    expect(controller.hasSystemFonts, isFalse);
  });

  test('تسجيل خط نظام غير متاح يفشل بلطف ولا يُسجّل شيئاً', () async {
    final CustomFontController controller =
        CustomFontController(store: InMemoryCustomFontStore());

    expect(await controller.registerSystemFont('No Such Font 12345'), isFalse);
    expect(controller.isRegisteredWithUi('No Such Font 12345'), isFalse);
  });

  test('عائلة خط النظام تُقارن بالقيمة لا بالمرجع', () {
    const WindowsSystemFontFamily a = WindowsSystemFontFamily(
      displayName: 'Arial',
      filePaths: <String>['C:/Windows/Fonts/arial.ttf'],
    );
    const WindowsSystemFontFamily b = WindowsSystemFontFamily(
      displayName: 'Arial',
      filePaths: <String>['C:/Windows/Fonts/arial.ttf'],
    );

    expect(a, equals(b));
    expect(a.hashCode, equals(b.hashCode));
  });
}
