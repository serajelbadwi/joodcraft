import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:joodcraft/core/assets/asset_store.dart';
import 'package:joodcraft/core/assets/user_asset.dart';
import 'package:joodcraft/core/constants/app_constants.dart';

import '../support/sample_image.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  UserAsset asset({String id = 'asset_1', AssetType type = AssetType.logo}) {
    return UserAsset(
      id: id,
      type: type,
      name: 'شعاري',
      fileName: 'logo.png',
      base64Data: samplePngBase64(),
      mime: 'image/png',
      addedAt: DateTime.utc(2026, 2, 3),
    );
  }

  group('SharedPreferencesAssetStore', () {
    setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

    test('حفظ ثم قراءة من نسخة جديدة يعيد الأصول كما هي', () async {
      final SharedPreferencesAssetStore first = SharedPreferencesAssetStore();
      expect(await first.loadAll(), isEmpty);

      await first.saveAll(<UserAsset>[asset()]);

      final List<UserAsset> loaded =
          await SharedPreferencesAssetStore().loadAll();
      expect(loaded.length, 1);
      expect(loaded.single.name, 'شعاري');
      expect(loaded.single.type, AssetType.logo);
      expect(loaded.single.bytes, samplePngBytes());
    });

    test('حفظ قائمة فارغة يمسح المفتاح', () async {
      final SharedPreferencesAssetStore store = SharedPreferencesAssetStore();
      await store.saveAll(<UserAsset>[asset()]);
      await store.saveAll(<UserAsset>[]);
      expect(await store.loadAll(), isEmpty);
    });

    test('فك الترميز لا يرمي على محتوى تالف', () {
      expect(SharedPreferencesAssetStore.decodeAssets('ليس JSON'), isEmpty);
      expect(SharedPreferencesAssetStore.decodeAssets('{"a":1}'), isEmpty);
      // سجل بلا معرّف أو بيانات يُتجاهل.
      expect(
        SharedPreferencesAssetStore.decodeAssets('[{"name":"بلا معرّف"}]'),
        isEmpty,
      );
    });
  });

  test('InMemoryAssetStore لا يشارك المراجع', () async {
    final InMemoryAssetStore store = InMemoryAssetStore();
    await store.saveAll(<UserAsset>[asset()]);
    final List<UserAsset> first = await store.loadAll();
    first.add(asset(id: 'asset_2'));
    expect((await store.loadAll()).length, 1);
  });
}
