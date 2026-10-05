import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/assets/asset_image_cache.dart';
import 'package:joodcraft/core/assets/asset_image_disk_cache.dart';
import 'package:joodcraft/core/assets/asset_store.dart';
import 'package:joodcraft/core/assets/assets_controller.dart';
import 'package:joodcraft/core/assets/user_asset.dart';
import 'package:joodcraft/core/constants/app_constants.dart';

import '../support/sample_image.dart';

/// اختبارات الكاش القرصي للصور المفكوكة: يحفظ البايتات، يعيدها، يُبطلها عند
/// الحذف، ويحترم الحدّ الأعلى (LRU)، ولا يرمي أبداً.
void main() {
  late Directory temp;

  setUp(() {
    temp = Directory.systemTemp.createTempSync('jood_image_cache_test');
  });

  tearDown(() {
    if (temp.existsSync()) temp.deleteSync(recursive: true);
  });

  AssetImageDiskCache cache({
    int maxEntries = AssetImageDiskCache.defaultMaxEntries,
    int maxBytes = AssetImageDiskCache.defaultMaxBytes,
  }) =>
      AssetImageDiskCache(
        rootPath: '${temp.path}/cache',
        maxEntries: maxEntries,
        maxBytes: maxBytes,
      );

  test('يحفظ البايتات ثم يعيدها من الكاش', () async {
    final AssetImageDiskCache c = cache();

    expect(await c.read('asset_1'), isNull, reason: 'لا نسخة بعد.');

    await c.write('asset_1', Uint8List.fromList(<int>[1, 2, 3, 4]));
    expect(await c.read('asset_1'), <int>[1, 2, 3, 4]);
  });

  test('بايتات فارغة لا تُحفظ', () async {
    final AssetImageDiskCache c = cache();
    await c.write('a', Uint8List(0));
    expect(await c.read('a'), isNull);
  });

  test('حذف أصل يُزيل نسخته القرصية', () async {
    final AssetImageDiskCache c = cache();
    await c.write('a', Uint8List.fromList(<int>[1]));
    await c.remove('a');
    expect(await c.read('a'), isNull);
  });

  test('مسح الكاش يُزيل كل النسخ', () async {
    final AssetImageDiskCache c = cache();
    await c.write('a', Uint8List.fromList(<int>[1]));
    await c.write('b', Uint8List.fromList(<int>[2]));

    await c.clear();

    expect(await c.read('a'), isNull);
    expect(await c.read('b'), isNull);
  });

  test('يحترم الحدّ الأعلى فيُسقط الأقدم (LRU)', () async {
    final AssetImageDiskCache c = cache(maxEntries: 2);
    await c.write('a', Uint8List.fromList(<int>[1]));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await c.write('b', Uint8List.fromList(<int>[2]));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await c.write('c', Uint8List.fromList(<int>[3]));

    // الأقدم (a) أُسقط، وبقي الأحدث.
    expect(await c.read('a'), isNull);
    expect(await c.read('b'), isNotNull);
    expect(await c.read('c'), isNotNull);
  });

  test('يحترم سقف البايتات فيُسقط الأقدم ولو قلّ العدد', () async {
    final AssetImageDiskCache c = cache(maxEntries: 64, maxBytes: 10);
    await c.write('a', Uint8List.fromList(List<int>.filled(6, 1)));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await c.write('b', Uint8List.fromList(List<int>.filled(6, 2)));

    // مجموع 12 بايت > السقف 10 ⇒ يُسقط الأقدم (a).
    expect(await c.read('a'), isNull);
    expect(await c.read('b'), isNotNull);
  });

  test('لا يُسقط أحدث ملف وإن تجاوز وحده السقف', () async {
    final AssetImageDiskCache c = cache(maxBytes: 4);
    await c.write('big', Uint8List.fromList(List<int>.filled(10, 7)));

    // الملف الأحدث يبقى دائماً حتى لو تجاوز السقف وحده (لا نُفرّغ المجلد).
    expect(await c.read('big'), isNotNull);
    expect((await c.stats()).bytes, 10);
  });

  test('معرّف بمحارف خاصة لا يكسر الكتابة والقراءة', () async {
    final AssetImageDiskCache c = cache();
    const String tricky = r'a/../ب:c*?';
    await c.write(tricky, Uint8List.fromList(<int>[9]));
    expect(await c.read(tricky), <int>[9]);
  });

  test('جذر غير قابل للكتابة لا يرمي (الكاش تحسين اختياري)', () async {
    // جذر يشير إلى ملف (وليس مجلداً) فيفشل إنشاؤه.
    final File blocker = File('${temp.path}/blocker')
      ..writeAsBytesSync(<int>[0]);
    final AssetImageDiskCache c =
        AssetImageDiskCache(rootPath: blocker.path);

    await c.write('a', Uint8List.fromList(<int>[1])); // لا يرمي.
    expect(await c.read('a'), isNull);
  });

  test('يُحصي عدد الملفات ومجموع البايتات', () async {
    final AssetImageDiskCache c = cache();
    expect((await c.stats()).files, 0);
    expect((await c.stats()).bytes, 0);

    await c.write('a', Uint8List.fromList(<int>[1, 2, 3]));
    await c.write('b', Uint8List.fromList(<int>[4, 5]));

    final AssetImageCacheStats stats = await c.stats();
    expect(stats.files, 2);
    expect(stats.bytes, 5);
    expect(stats.isEmpty, isFalse);
  });

  group('prune (تنظيف ما لم يعد في المكتبة)', () {
    test('يحذف ملفات الأصول اليتيمة ويُبقي الصالحة', () async {
      final AssetImageDiskCache c = cache();
      await c.write('live', Uint8List.fromList(<int>[1]));
      await c.write('orphan', Uint8List.fromList(<int>[2]));
      // ملف غير ‎.bin‎ لا يمسّه التنظيف (لكاش آخر في المجلد نفسه).
      final File stray = File('${temp.path}/cache/notes.txt')
        ..writeAsStringSync('غير لكاش الصور');

      expect(await c.prune(<String>{'live'}), 1);

      expect(await c.read('live'), <int>[1], reason: 'أصل موجود في المكتبة يبقى.');
      expect(await c.read('orphan'), isNull, reason: 'أصل مُحذوف لا يشغل القرص.');
      expect(stray.existsSync(), isTrue, reason: 'ملف غير ‎.bin‎ لا يُحذف.');
      expect((await c.stats()).files, 1);
    });

    test('معرّفات بمحارف خاصة تُطابق الملفات المخزّنة', () async {
      final AssetImageDiskCache c = cache();
      const String tricky = r'a/../ب:c*?';
      await c.write(tricky, Uint8List.fromList(<int>[9]));
      await c.write('dead', Uint8List.fromList(<int>[8]));

      expect(await c.prune(<String>{tricky}), 1);
      expect(await c.read(tricky), <int>[9]);
      expect(await c.read('dead'), isNull);
    });

    test('كاش فارغ أو جذر مفقود يعيد صفر ولا يرمي', () async {
      final AssetImageDiskCache c = cache();
      expect(await c.prune(<String>{'a'}), 0);

      final AssetImageDiskCache missing =
          AssetImageDiskCache(rootPath: '${temp.path}/does_not_exist');
      expect(await missing.prune(<String>{'a'}), 0);
    });
  });

  test('pruneImageCache: يُنظّف ما لم يعد في المكتبة (تنظيف خلفي عند الإقلاع)',
      () async {
    final AssetImageDiskCache previousDisk = AssetImageDiskCache.instance;
    final Directory tempCache =
        Directory.systemTemp.createTempSync('jood_prune_controller');
    AssetImageDiskCache.instance =
        AssetImageDiskCache(rootPath: '${tempCache.path}/cache');
    AssetImageCache.instance.clear();

    try {
      final AssetsController controller =
          AssetsController(store: InMemoryAssetStore());
      // قبل استعادة المكتبة لا شيء يُنظَّف (لا معرفة بما هو صالح بعد).
      expect(await controller.pruneImageCache(), 0);

      await controller.restore();
      final UserAsset asset = await controller.addAsset(
        type: AssetType.border,
        name: 'إطار',
        fileName: 'border.png',
        bytes: samplePngBytes(),
      );
      // ملف يتيم: أصلٌ حُذف من المكتبة وبقيت نسخته على القرص.
      await AssetImageDiskCache.instance
          .write('orphan_id', Uint8List.fromList(<int>[7, 7]));

      expect(await controller.pruneImageCache(), 1);

      expect(
        await AssetImageDiskCache.instance.read(asset.id),
        isNotNull,
        reason: 'أصل موجود في المكتبة يبقى في الكاش.',
      );
      expect(
        await AssetImageDiskCache.instance.read('orphan_id'),
        isNull,
        reason: 'ما لم يعد في المكتبة يُحذف من القرص.',
      );
    } finally {
      AssetImageDiskCache.instance = previousDisk;
      AssetImageCache.instance.clear();
      try {
        if (tempCache.existsSync()) tempCache.deleteSync(recursive: true);
      } on FileSystemException {
        // قد يبقى ملف مقفولاً لحظياً على ويندوز — لا يُسقط الاختبار.
      }
    }
  });
}
