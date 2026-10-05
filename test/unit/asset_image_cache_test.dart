import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/assets/asset_image_cache.dart';
import 'package:joodcraft/core/assets/asset_image_disk_cache.dart';
import 'package:joodcraft/core/assets/asset_store.dart';
import 'package:joodcraft/core/assets/assets_controller.dart';
import 'package:joodcraft/core/assets/user_asset.dart';
import 'package:joodcraft/core/constants/app_constants.dart';

import '../support/sample_image.dart';

void main() {
  late Directory tempCache;
  late AssetImageDiskCache previousDisk;

  setUp(() {
    AssetImageCache.instance.clear();
    // جذر قرصي مؤقّت حتى لا نلمس الكاش الحقيقي للمستخدم في الاختبارات.
    tempCache = Directory.systemTemp.createTempSync('jood_img_disk_test');
    previousDisk = AssetImageDiskCache.instance;
    AssetImageDiskCache.instance = AssetImageDiskCache(
      rootPath: '${tempCache.path}/cache',
    );
  });

  tearDown(() {
    AssetImageCache.instance.clear();
    AssetImageDiskCache.instance = previousDisk;
    try {
      if (tempCache.existsSync()) tempCache.deleteSync(recursive: true);
    } on FileSystemException {
      // على ويندوز قد يبقى الملف مقفولاً لحظةً بعد كتابة غير حاجزة — لا نُسقط
      // الاختبار لذلك؛ المجلد مؤقّت ويُكنسه النظام لاحقاً.
    }
  });

  /// ينتظر حتى تتطابق حالة الكاش القرصي للأصل [id] مع [present].
  Future<void> waitForDisk(String id, {required bool present}) async {
    for (int i = 0; i < 100; i++) {
      final bool has =
          (await AssetImageDiskCache.instance.read(id)) != null;
      if (has == present) return;
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  }

  UserAsset asset({String id = 'asset_1'}) => UserAsset(
        id: id,
        type: AssetType.border,
        name: 'إطار',
        fileName: 'border.png',
        base64Data: samplePngBase64(),
        addedAt: DateTime(2026, 1, 1),
      );

  group('ذاكرة الصور المفكوكة', () {
    test('بايتات الأصل تُفكّ مرة واحدة وتُعاد بنفس المرجع', () {
      final UserAsset a = asset();

      final Uint8List first = AssetImageCache.instance.bytesForAsset(a);
      final Uint8List second = AssetImageCache.instance.bytesForAsset(a);

      // نفس المرجع هو ما يثبّت مفتاح `MemoryImage` فلا يُعاد فكّ الصورة.
      expect(identical(first, second), isTrue);
      expect(first, samplePngBytes());
      expect(AssetImageCache.instance.length, 1);
    });

    test('موفّر الرسم يُبنى مرة واحدة عبر إعادات البناء', () {
      final UserAsset a = asset();

      final ImageProvider first = AssetImageCache.instance.providerForAsset(a);
      final ImageProvider second = AssetImageCache.instance.providerForAsset(a);

      expect(identical(first, second), isTrue);
    });

    test('بايتات Base64 المضمّنة تُخزَّن مرة واحدة', () {
      final Uint8List first =
          AssetImageCache.instance.bytesForBase64(samplePngBase64());
      final Uint8List second =
          AssetImageCache.instance.bytesForBase64(samplePngBase64());

      expect(identical(first, second), isTrue);
      expect(first, samplePngBytes());
    });

    test('فكّ Base64 غير صالح يرمي ولا يُخزّن شيئاً', () {
      expect(
        () => AssetImageCache.instance.bytesForBase64('!!!not-base64!!!'),
        throwsA(isA<FormatException>()),
      );
      expect(AssetImageCache.instance.length, 0);
    });

    test('إزالة أصل تُسقط بايتاته وموفّره', () {
      final UserAsset a = asset();
      AssetImageCache.instance.providerForAsset(a);
      expect(AssetImageCache.instance.length, 1);

      AssetImageCache.instance.evictAsset(a.id);
      expect(AssetImageCache.instance.length, 0);
    });

    test('تفريغ الذاكرة يُزيل كل الأصول', () {
      AssetImageCache.instance.providerForAsset(asset(id: 'a1'));
      AssetImageCache.instance.providerForAsset(asset(id: 'a2'));
      expect(AssetImageCache.instance.length, 2);

      AssetImageCache.instance.clear();
      expect(AssetImageCache.instance.length, 0);
    });
  });

  group('ربط الذاكرة بمكتبة الأصول', () {
    test('حذف أصل من المتحكم يُسقط صورته المخزّنة', () async {
      final AssetsController controller =
          AssetsController(store: InMemoryAssetStore());
      final UserAsset added = await controller.addAsset(
        type: AssetType.border,
        name: 'إطار',
        fileName: 'border.png',
        bytes: samplePngBytes(),
      );
      AssetImageCache.instance.providerForAsset(added);
      expect(AssetImageCache.instance.length, 1);

      await controller.removeAsset(added.id);
      expect(AssetImageCache.instance.length, 0);
      controller.dispose();
    });

    test('تفريغ المكتبة يُفرّغ الذاكرة', () async {
      final AssetsController controller =
          AssetsController(store: InMemoryAssetStore());
      final UserAsset added = await controller.addAsset(
        type: AssetType.border,
        name: 'إطار',
        fileName: 'border.png',
        bytes: samplePngBytes(),
      );
      AssetImageCache.instance.providerForAsset(added);

      await controller.clear();
      expect(AssetImageCache.instance.length, 0);
      controller.dispose();
    });
  });

  group('الطبقة القرصية (إعادة الاستخدام عبر التشغيلات)', () {
    test('preload يعيد البايتات من القرص بلا إعادة فكّ Base64', () async {
      final UserAsset a = asset();
      // نحاكي فتحة سابقة: البايتات المفكوكة محفوظة على القرص.
      await AssetImageDiskCache.instance.write(a.id, samplePngBytes());
      AssetImageCache.instance.clear();

      await AssetImageCache.instance.preload(<UserAsset>[a]);

      expect(AssetImageCache.instance.length, 1);
      expect(AssetImageCache.instance.bytesForAsset(a), samplePngBytes());
    });

    test('preload يفكّ من Base64 ويحفظ على القرص عند غياب النسخة', () async {
      final UserAsset a = asset();

      await AssetImageCache.instance.preload(<UserAsset>[a]);
      expect(AssetImageCache.instance.bytesForAsset(a), samplePngBytes());

      // الكتابة القرصية غير حاجزة — ننتظر ظهورها بإمهال محدود.
      await waitForDisk(a.id, present: true);
      expect(await AssetImageDiskCache.instance.read(a.id), samplePngBytes());
    });

    test('إزالة أصل تحذف نسخته القرصية', () async {
      final UserAsset a = asset();
      await AssetImageDiskCache.instance.write(a.id, samplePngBytes());
      await AssetImageCache.instance.preload(<UserAsset>[a]);

      AssetImageCache.instance.evictAsset(a.id);
      await waitForDisk(a.id, present: false);

      expect(await AssetImageDiskCache.instance.read(a.id), isNull);
    });

    test('إضافة أصل تحفظ صورته على القرص فوراً', () async {
      final AssetsController controller =
          AssetsController(store: InMemoryAssetStore());
      final UserAsset added = await controller.addAsset(
        type: AssetType.border,
        name: 'إطار',
        fileName: 'border.png',
        bytes: samplePngBytes(),
      );

      // الحفظ القرصي مجدول غير حاجز — ننتظر ظهوره بإمهال محدود.
      await waitForDisk(added.id, present: true);
      expect(
        await AssetImageDiskCache.instance.read(added.id),
        samplePngBytes(),
      );
      controller.dispose();
    });

    test('استعادة المكتبة تسخّن الذاكرة من الكاش القرصي', () async {
      final InMemoryAssetStore store = InMemoryAssetStore();
      final AssetsController first = AssetsController(store: store);
      final UserAsset added = await first.addAsset(
        type: AssetType.border,
        name: 'إطار',
        fileName: 'border.png',
        bytes: samplePngBytes(),
      );
      first.dispose();
      await pumpEventQueue();

      // كأن التطبيق أُغلق وأُعيد فتحه: الذاكرة فارغة والقرص هو الذاكرة.
      AssetImageCache.instance.clear();
      final AssetsController second = AssetsController(store: store);
      await second.restore();
      // التسخين غير حاجز (لا يؤخّر الإقلاع) — نمنحه فرصة بإمهال محدود.
      for (int i = 0;
          i < 100 && AssetImageCache.instance.length == 0;
          i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }

      expect(AssetImageCache.instance.length, greaterThan(0));
      expect(AssetImageCache.instance.bytesForAsset(added), samplePngBytes());
      second.dispose();
    });
  });
}
