import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'user_asset.dart';

/// مخزن أصول المستخدم محلياً — لا يمر أي بايت عبر الشبكة.
///
/// التنفيذ الافتراضي يستخدم `SharedPreferences` (ملف JSON في مجلد بيانات
/// التطبيق على سطح المكتب، و`localStorage` على الويب). الواجهة قابلة للحقن حتى
/// تُختبر الاستعادة أوفلاين بلا أي منصة.
abstract interface class AssetStore {
  Future<List<UserAsset>> loadAll();

  Future<void> saveAll(List<UserAsset> assets);
}

/// تخزين دائم عبر `SharedPreferences`.
class SharedPreferencesAssetStore implements AssetStore {
  SharedPreferencesAssetStore({this.key = defaultKey});

  /// المفتاح يحمل إصداراً حتى يمكن تغيير الشكل لاحقاً بلا كسر مكتبة قديمة.
  static const String defaultKey = 'joodcraft.user_assets.v1';

  final String key;

  @override
  Future<List<UserAsset>> loadAll() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(key);
    if (raw == null || raw.trim().isEmpty) return <UserAsset>[];
    return decodeAssets(raw);
  }

  @override
  Future<void> saveAll(List<UserAsset> assets) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (assets.isEmpty) {
      await prefs.remove(key);
      return;
    }
    await prefs.setString(key, encodeAssets(assets));
  }

  /// فك ترميز الأصول — مشترك مع الاختبارات، ولا يرمي على محتوى تالف.
  static List<UserAsset> decodeAssets(String raw) {
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      return <UserAsset>[];
    }
    if (decoded is! List) return <UserAsset>[];
    return decoded
        .map(UserAsset.fromJson)
        .whereType<UserAsset>()
        .toList(growable: false);
  }

  static String encodeAssets(List<UserAsset> assets) =>
      jsonEncode(assets.map((UserAsset a) => a.toJson()).toList());
}

/// تخزين في الذاكرة — للاختبارات وللمعاينة السريعة.
class InMemoryAssetStore implements AssetStore {
  InMemoryAssetStore([List<UserAsset>? initial])
      : _assets = <UserAsset>[...?initial];

  List<UserAsset> _assets;

  List<UserAsset> get assets => List<UserAsset>.unmodifiable(_assets);

  @override
  Future<List<UserAsset>> loadAll() async => List<UserAsset>.from(_assets);

  @override
  Future<void> saveAll(List<UserAsset> assets) async {
    _assets = <UserAsset>[...assets];
  }
}
