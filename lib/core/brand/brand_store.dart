import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'brand_profile.dart';

/// مخزن هوية المؤسسة محلياً — ملف JSON واحد صغير (بلا صور: الصور في مكتبة
/// الأصول ويُشار إليها بمعرّفات).
///
/// الواجهة قابلة للحقن حتى تُختبر الاستعادة/الحفظ أوفلاين بلا منصة.
abstract interface class BrandStore {
  Future<BrandProfile> load();

  Future<void> save(BrandProfile profile);

  Future<void> clear();
}

/// تخزين دائم عبر `SharedPreferences`.
class SharedPreferencesBrandStore implements BrandStore {
  SharedPreferencesBrandStore({this.key = defaultKey});

  /// المفتاح يحمل إصداراً حتى يمكن تغيير الشكل لاحقاً بلا كسر بيانات قديمة.
  static const String defaultKey = 'joodcraft.brand_profile.v1';

  final String key;

  @override
  Future<BrandProfile> load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(key);
    if (raw == null || raw.trim().isEmpty) return const BrandProfile();
    return decode(raw);
  }

  @override
  Future<void> save(BrandProfile profile) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (profile.isEmpty) {
      await prefs.remove(key);
      return;
    }
    await prefs.setString(key, encode(profile));
  }

  @override
  Future<void> clear() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  /// فك ترميز البروفايل — مشترك مع الاختبارات، ولا يرمي على محتوى تالف.
  static BrandProfile decode(String raw) {
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      return const BrandProfile();
    }
    return BrandProfile.fromJson(decoded);
  }

  static String encode(BrandProfile profile) => jsonEncode(profile.toJson());
}

/// تخزين في الذاكرة — للاختبارات وللمعاينة السريعة.
class InMemoryBrandStore implements BrandStore {
  InMemoryBrandStore([this._profile = const BrandProfile()]);

  BrandProfile _profile;

  bool saved = false;

  BrandProfile get profile => _profile;

  @override
  Future<BrandProfile> load() async => _profile;

  @override
  Future<void> save(BrandProfile profile) async {
    _profile = profile;
    saved = true;
  }

  @override
  Future<void> clear() async {
    _profile = const BrandProfile();
    saved = true;
  }
}
