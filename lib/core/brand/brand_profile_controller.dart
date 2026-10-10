import 'package:flutter/foundation.dart';

import 'brand_profile.dart';
import 'brand_store.dart';

/// محرّك هوية المؤسسة: يقرأ البروفايل المحفوظ ويوفّره للمحرّر ولشاشة الإعدادات.
///
/// الحالة محلية فقط (بلا شبكة): الصور في مكتبة الأصول ويُشار إليها بمعرّفات،
/// وهذا الكائن يحفظ البيانات النصية والألوان والخطوط وخريطة الأصول.
class BrandProfileController extends ChangeNotifier {
  BrandProfileController({BrandStore? store, BrandProfile? initial})
      : _store = store ?? SharedPreferencesBrandStore(),
        _profile = initial ?? const BrandProfile();

  /// نسخة واحدة للتطبيق كله (تُحقن في الشجرة بلا تمرير يدوي).
  static BrandProfileController? _instance;

  static BrandProfileController get instance =>
      _instance ??= BrandProfileController();

  static set instance(BrandProfileController value) => _instance = value;

  final BrandStore _store;
  BrandProfile _profile;

  bool _restored = false;
  bool get isRestored => _restored;

  BrandProfile get profile => _profile;

  /// حفظ جارٍ (لتعطيل الأزرار مؤقّتاً إن لزم).
  bool _saving = false;
  bool get isSaving => _saving;

  // --------------------------------------------------------------------------
  //  قراءات مساعدة
  // --------------------------------------------------------------------------

  bool get hasPrimaryLogo => _profile.hasPrimaryLogo;
  bool get hasWatermark => _profile.hasWatermark;
  bool get hasSeals => _profile.hasSeals;
  bool get hasSignatures => _profile.hasSignatures;
  bool get hasHeaderAssets => _profile.hasPrimaryLogo || _profile.hasSeals;
  bool get isEmpty => _profile.isEmpty;

  /// أسماء الأختام بترتيب ثابت (لثبات قوائم الإدراج).
  List<String> get sealNames {
    final List<String> names = _profile.officialSealPaths.keys.toList();
    names.sort();
    return names;
  }

  /// معرّف أصل ختم باسمه.
  String? sealPath(String name) => _profile.officialSealPaths[name];

  BrandSignature? signatureById(String id) {
    for (final BrandSignature signature in _profile.signatures) {
      if (signature.id == id) return signature;
    }
    return null;
  }

  // --------------------------------------------------------------------------
  //  الاستعادة والحفظ
  // --------------------------------------------------------------------------

  /// يقرأ البروفايل المحفوظ. آمن للاستدعاء أكثر من مرة ولا يرمي.
  Future<void> restore({bool force = false}) async {
    if (_restored && !force) return;
    try {
      _profile = await _store.load();
    } catch (error, stackTrace) {
      debugPrint('[الهوية] تعذّرت الاستعادة: $error\n$stackTrace');
      _profile = const BrandProfile();
    }
    _restored = true;
    notifyListeners();
  }

  /// يطبّق تعديلاً على البروفايل ثم يحفظه (خطوة واحدة لكل تغيير منطقي).
  Future<void> update(BrandProfile Function(BrandProfile current) transform) {
    final BrandProfile next = transform(_profile);
    if (next == _profile) return Future<void>.value();
    _profile = next;
    notifyListeners();
    return _persist();
  }

  Future<void> _persist() async {
    _saving = true;
    try {
      await _store.save(_profile);
    } catch (error, stackTrace) {
      debugPrint('[الهوية] تعذّر الحفظ: $error\n$stackTrace');
    } finally {
      _saving = false;
    }
  }

  /// مسح الهوية بالكامل (أداة إعادة تعيين/اختبارات).
  Future<void> clear() async {
    if (_profile.isEmpty) {
      // حتى الفارغ يُحدَّث للتأكد من إزالة أي أثر على القرص.
      try {
        await _store.clear();
      } catch (_) {}
      return;
    }
    _profile = const BrandProfile();
    notifyListeners();
    try {
      await _store.clear();
    } catch (error, stackTrace) {
      debugPrint('[الهوية] تعذّر المسح: $error\n$stackTrace');
    }
  }

  // --------------------------------------------------------------------------
  //  الأصول البصرية
  // --------------------------------------------------------------------------

  Future<void> setPrimaryLogo(String? assetId) =>
      update((BrandProfile p) => p.copyWith(primaryLogoPath: assetId));

  Future<void> setWatermarkLogo(String? assetId) =>
      update((BrandProfile p) => p.copyWith(watermarkLogoPath: assetId));

  /// إضافة/تحديث ختم باسمه ومعرّف أصله.
  Future<void> setSeal(String name, String assetId) {
    final String clean = name.trim();
    if (clean.isEmpty || assetId.trim().isEmpty) {
      return Future<void>.value();
    }
    return update(
      (BrandProfile p) => p.copyWith(
        officialSealPaths: <String, String>{
          ...p.officialSealPaths,
          clean: assetId.trim(),
        },
      ),
    );
  }

  Future<void> removeSeal(String name) {
    if (!_profile.officialSealPaths.containsKey(name)) {
      return Future<void>.value();
    }
    return update((BrandProfile p) {
      final Map<String, String> seals = <String, String>{...p.officialSealPaths}
        ..remove(name);
      return p.copyWith(officialSealPaths: seals);
    });
  }

  /// إضافة/تحديث توقيع (بالاسم نفسه يُحدَّث بدل التكرار).
  Future<void> upsertSignature(BrandSignature signature) {
    return update((BrandProfile p) {
      final List<BrandSignature> next =
          <BrandSignature>[...p.signatures];
      final int index =
          next.indexWhere((BrandSignature s) => s.id == signature.id);
      if (index >= 0) {
        next[index] = signature;
      } else {
        next.add(signature);
      }
      return p.copyWith(signatures: next);
    });
  }

  Future<void> removeSignature(String id) {
    if (!_profile.signatures.any((BrandSignature s) => s.id == id)) {
      return Future<void>.value();
    }
    return update(
      (BrandProfile p) => p.copyWith(
        signatures:
            p.signatures.where((BrandSignature s) => s.id != id).toList(),
      ),
    );
  }

  // --------------------------------------------------------------------------
  //  البيانات النصية
  // --------------------------------------------------------------------------

  Future<void> setOrgNameAr(String value) =>
      update((BrandProfile p) => p.copyWith(orgNameAr: value));

  Future<void> setOrgNameEn(String value) =>
      update((BrandProfile p) => p.copyWith(orgNameEn: value));

  Future<void> setHeaderText(String value) =>
      update((BrandProfile p) => p.copyWith(headerText: value));

  Future<void> setFooterText(String value) =>
      update((BrandProfile p) => p.copyWith(footerText: value));

  Future<void> setTaxOrRegNumber(String value) =>
      update((BrandProfile p) => p.copyWith(taxOrRegNumber: value));

  // --------------------------------------------------------------------------
  //  الألوان والخطوط
  // --------------------------------------------------------------------------

  Future<void> setPrimaryColor(String hex) =>
      update((BrandProfile p) => p.copyWith(primaryColorHex: hex));

  Future<void> setSecondaryColor(String hex) =>
      update((BrandProfile p) => p.copyWith(secondaryColorHex: hex));

  Future<void> setAccentColor(String hex) =>
      update((BrandProfile p) => p.copyWith(accentColorHex: hex));

  Future<void> setHeaderFontFamily(String? family) =>
      update((BrandProfile p) => p.copyWith(defaultHeaderFontFamily: family));

  Future<void> setBodyFontFamily(String? family) =>
      update((BrandProfile p) => p.copyWith(defaultBodyFontFamily: family));
}
