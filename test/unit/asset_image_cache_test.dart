import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/assets/asset_image_cache.dart';
import 'package:joodcraft/core/assets/asset_store.dart';
import 'package:joodcraft/core/assets/assets_controller.dart';
import 'package:joodcraft/core/assets/user_asset.dart';
import 'package:joodcraft/core/constants/app_constants.dart';

import '../support/sample_image.dart';

void main() {
  setUp(() => AssetImageCache.instance.clear());
  tearDown(() => AssetImageCache.instance.clear());

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
}
