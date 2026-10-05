import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/fonts/custom_font_controller.dart';
import 'package:joodcraft/core/fonts/custom_font_store.dart';
import 'package:joodcraft/core/fonts/system_font_cache.dart';
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

  group('SystemFontCache (تخزين كسول)', () {
    test('يحسب المفتاح مرة واحدة ويعيد المخزّن بعده', () async {
      final SystemFontCache<int> cache = SystemFontCache<int>();
      int calls = 0;
      Future<int> load() async => ++calls;

      expect(await cache.get('k', load), 1);
      expect(await cache.get('k', load), 1);
      expect(calls, 1);
      expect(cache.hits, 1);
      expect(cache.misses, 1);
      expect(cache.valueOf('k'), 1);
    });

    test('force يعيد الحساب ويستبدل المخزّن', () async {
      final SystemFontCache<int> cache = SystemFontCache<int>();
      int calls = 0;
      Future<int> load() async => ++calls;

      expect(await cache.get('k', load), 1);
      expect(await cache.get('k', load, force: true), 2);
      expect(await cache.get('k', load), 2);
      expect(calls, 2);
    });

    test('الطلبات المتسابقة تتشارك الحساب نفسه', () async {
      final SystemFontCache<int> cache = SystemFontCache<int>();
      int calls = 0;
      final Completer<int> gate = Completer<int>();
      Future<int> load() {
        calls++;
        return gate.future;
      }

      final Future<int> first = cache.get('k', load);
      final Future<int> second = cache.get('k', load);
      gate.complete(7);

      expect(await first, 7);
      expect(await second, 7);
      expect(calls, 1);
    });

    test('الإسقاط LRU يُبقي أحدث المفاتيح فقط', () async {
      final SystemFontCache<int> cache = SystemFontCache<int>(maxEntries: 2);
      await cache.get('a', () async => 1);
      await cache.get('b', () async => 2);
      await cache.get('a', () async => 1); // يجعل b الأقدم.
      await cache.get('c', () async => 3);

      expect(cache.containsKey('b'), isFalse);
      expect(cache.containsKey('a'), isTrue);
      expect(cache.containsKey('c'), isTrue);
      expect(cache.length, 2);
    });

    test('clear يُفرّغ كل شيء', () async {
      final SystemFontCache<int> cache = SystemFontCache<int>();
      await cache.get('k', () async => 1);
      cache.clear();

      expect(cache.containsKey('k'), isFalse);
      expect(cache.length, 0);
    });
  });

  group('تخزين خدمة خطوط النظام مؤقتاً', () {
    setUp(WindowsSystemFontService.clearCache);
    tearDown(WindowsSystemFontService.clearCache);

    test('نتيجة الفحص تُخزّن فلا يُعاد الفحص', () async {
      await WindowsSystemFontService.discover(platform: 'linux');
      expect(WindowsSystemFontService.debugDiscoveryCache.misses, 1);

      await WindowsSystemFontService.discover(platform: 'linux');
      expect(WindowsSystemFontService.debugDiscoveryCache.hits, 1);
      expect(WindowsSystemFontService.debugDiscoveryCache.misses, 1);
    });

    test('force يتجاوز المخزّن ويعيد الفحص', () async {
      await WindowsSystemFontService.discover(platform: 'linux');
      await WindowsSystemFontService.discover(platform: 'linux', force: true);
      expect(WindowsSystemFontService.debugDiscoveryCache.misses, 2);
    });

    test('بايتات الخط تُخزّن كسولاً بحسب المسار', () async {
      // مسار مضمون عدم الوجود كي لا يلمس الاختبار قرص الجهاز فعلاً.
      const String path = 'C:/__no_such_font_dir__/arial.ttf';
      expect(await WindowsSystemFontService.readFontBytes(path), isNull);
      expect(WindowsSystemFontService.isFontCached(path), isTrue);
      expect(WindowsSystemFontService.debugBytesCache.hits, 0);

      await WindowsSystemFontService.readFontBytes(path);
      expect(WindowsSystemFontService.debugBytesCache.hits, 1);
    });

    test('clearCache يُفرّغ الفحص والبايتات معاً', () async {
      await WindowsSystemFontService.discover(platform: 'linux');
      await WindowsSystemFontService.readFontBytes('C:/x.ttf');

      WindowsSystemFontService.clearCache();

      expect(
        WindowsSystemFontService.debugDiscoveryCache.containsKey('linux'),
        isFalse,
      );
      expect(WindowsSystemFontService.isFontCached('C:/x.ttf'), isFalse);
    });
  });
}
