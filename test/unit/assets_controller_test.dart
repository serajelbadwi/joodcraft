import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:joodcraft/core/assets/asset_store.dart';
import 'package:joodcraft/core/assets/assets_controller.dart';
import 'package:joodcraft/core/assets/user_asset.dart';
import 'package:joodcraft/core/constants/app_constants.dart';
import 'package:joodcraft/core/errors/app_exception.dart';

import '../support/sample_image.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late InMemoryAssetStore store;
  late AssetsController controller;

  setUp(() {
    store = InMemoryAssetStore();
    controller = AssetsController(store: store);
  });

  group('رفع الأصول', () {
    test('يُضيف صورة صالحة ويحفظها محلياً', () async {
      final UserAsset asset = await controller.addAsset(
        type: AssetType.logo,
        name: '',
        fileName: 'logo.png',
        bytes: samplePngBytes(),
      );

      expect(asset.type, AssetType.logo);
      expect(asset.name, 'logo'); // الاسم من اسم الملف بلا امتداد
      expect(asset.mime, 'image/png');
      expect(asset.bytes, samplePngBytes());
      expect(controller.count, 1);
      expect(store.assets.length, 1);
      expect(controller.byId(asset.id), isNotNull);
      expect(controller.byType(AssetType.logo).single.id, asset.id);
    });

    test('يرفض ما ليس صورة برسالة عربية', () async {
      await expectLater(
        controller.addAsset(
          type: AssetType.stamp,
          name: 'ختم',
          fileName: 'stamp.bin',
          bytes: notAnImageBytes(),
        ),
        throwsA(isA<AppException>()),
      );
      expect(controller.isEmpty, isTrue);
    });

    test('يرفض الملفات الأكبر من الحد المسموح', () async {
      final AssetsController small =
          AssetsController(store: InMemoryAssetStore(), maxBytes: 4);
      await expectLater(
        small.addAsset(
          type: AssetType.signature,
          name: 'توقيع',
          fileName: 'sig.png',
          bytes: Uint8List(64),
        ),
        throwsA(isA<AppException>()),
      );
    });

    test('كشف نوع الصورة من بصمتها', () {
      expect(
        AssetsController.detectImageMime(samplePngBytes()),
        'image/png',
      );
      expect(
        AssetsController.detectImageMime(
          Uint8List.fromList(<int>[0xFF, 0xD8, 0xFF, 0xE0]),
        ),
        'image/jpeg',
      );
      expect(AssetsController.detectImageMime(notAnImageBytes()), isNull);
    });
  });

  group('الاستعادة أوفلاين', () {
    test('الأصول تُستعاد عند إعادة فتح التطبيق', () async {
      await controller.addAsset(
        type: AssetType.signature,
        name: 'توقيعي',
        fileName: 'sig.png',
        bytes: samplePngBytes(),
      );

      final AssetsController restarted =
          AssetsController(store: InMemoryAssetStore(store.assets));
      expect(restarted.isEmpty, isTrue);

      await restarted.restore();
      expect(restarted.isRestored, isTrue);
      expect(restarted.count, 1);
      expect(restarted.assets.single.name, 'توقيعي');
    });

    test('يستعيد من المخزن الدائم (SharedPreferences) بعد إعادة التشغيل',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final AssetsController first =
          AssetsController(store: SharedPreferencesAssetStore());
      await first.addAsset(
        type: AssetType.logo,
        name: 'شعار',
        fileName: 'logo.png',
        bytes: samplePngBytes(),
      );

      final AssetsController restarted =
          AssetsController(store: SharedPreferencesAssetStore());
      await restarted.restore();
      expect(restarted.count, 1);
      expect(restarted.assets.single.name, 'شعار');
    });
  });

  group('التعديل والحذف', () {
    test('إعادة التسمية تحدّث الاسم وتحفظه', () async {
      final UserAsset asset = await controller.addAsset(
        type: AssetType.logo,
        name: 'قديم',
        fileName: 'logo.png',
        bytes: samplePngBytes(),
      );
      await controller.renameAsset(asset.id, 'شعار الشركة');
      expect(controller.byId(asset.id)!.name, 'شعار الشركة');
      expect(store.assets.single.name, 'شعار الشركة');
    });

    test('الحذف يُزيل الأصل من الذاكرة والمخزن', () async {
      final UserAsset asset = await controller.addAsset(
        type: AssetType.stamp,
        name: 'ختم',
        fileName: 'stamp.png',
        bytes: samplePngBytes(),
      );
      await controller.removeAsset(asset.id);
      expect(controller.isEmpty, isTrue);
      expect(store.assets, isEmpty);
    });
  });
}
