import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../constants/app_constants.dart';
import '../errors/app_error_code.dart';
import '../errors/app_exception.dart';
import 'asset_image_cache.dart';
import 'asset_store.dart';
import 'user_asset.dart';

/// المحرّك الديناميكي لأصول المستخدم (شعار/ختم/توقيع/إطار).
///
/// المسؤولية: استقبال بايتات صورة ← فحصها ← حفظها محلياً (‎SharedPreferences‎)
/// وتوفيرها لمحرّر القوالب ولمحرّك الطباعة عبر [byId]. الحالة محلية فقط وتُعاد
/// عند بدء التشغيل عبر [restore] — بلا أي شبكة.
class AssetsController extends ChangeNotifier {
  AssetsController({AssetStore? store, this.maxBytes = 3 * 1024 * 1024})
      : _store = store ?? SharedPreferencesAssetStore();

  /// نسخة واحدة للتطبيق كله (تُحقن في شجرة الواجهة بلا تمرير يدوي).
  static AssetsController? _instance;

  static AssetsController get instance => _instance ??= AssetsController();

  static set instance(AssetsController value) => _instance = value;

  /// أكبر حجم مسموح لصورة واحدة (3MB).
  final int maxBytes;

  final AssetStore _store;
  final List<UserAsset> _assets = <UserAsset>[];

  bool _restored = false;
  bool get isRestored => _restored;

  /// كل الأصول، مرتّبة بالنوع ثم الاسم (لثبات ترتيب القوائم).
  List<UserAsset> get assets {
    final List<UserAsset> sorted = <UserAsset>[..._assets];
    sorted.sort((UserAsset a, UserAsset b) {
      final int byType = a.type.index.compareTo(b.type.index);
      return byType != 0 ? byType : a.name.compareTo(b.name);
    });
    return List<UserAsset>.unmodifiable(sorted);
  }

  bool get isEmpty => _assets.isEmpty;
  int get count => _assets.length;

  /// مجموع الحجم المحفوظ محلياً.
  int get totalBytes =>
      _assets.fold<int>(0, (int sum, UserAsset a) => sum + a.byteSize);

  UserAsset? byId(String? id) {
    if (id == null) return null;
    for (final UserAsset asset in _assets) {
      if (asset.id == id) return asset;
    }
    return null;
  }

  List<UserAsset> byType(AssetType type) =>
      assets.where((UserAsset a) => a.type == type).toList(growable: false);

  // ==========================================================================
  //  الاستعادة
  // ==========================================================================

  /// يقرأ المكتبة المحفوظة. آمن للاستدعاء أكثر من مرة ولا يرمي.
  Future<void> restore({bool force = false}) async {
    if (_restored && !force) return;
    _assets.clear();
    try {
      final List<UserAsset> saved = await _store.loadAll();
      for (final UserAsset asset in saved) {
        // احترام الحدّ عند الاستعادة أيضاً حتى لا يُدخل سجل ضخم الذاكرة.
        if (asset.byteSize > maxBytes) {
          debugPrint('[الأصول] تجاهل أصلاً يتجاوز الحد: ${asset.name}');
          continue;
        }
        _assets.add(asset);
      }
    } catch (error, stackTrace) {
      debugPrint('[الأصول] تعذّرت الاستعادة: $error\n$stackTrace');
    }
    _restored = true;
    notifyListeners();
  }

  // ==========================================================================
  //  الإضافة والتعديل والحذف
  // ==========================================================================

  /// إضافة أصل من بايتاته (تأتي من منتقي الملفات — لا تُقرأ من القرص هنا).
  Future<UserAsset> addAsset({
    required AssetType type,
    required String name,
    required String fileName,
    required Uint8List bytes,
  }) async {
    if (bytes.isEmpty) {
      throw const AppException(
        AppErrorCode.validation,
        message: 'ملف الصورة فارغ.',
      );
    }
    if (bytes.lengthInBytes > maxBytes) {
      throw AppException(
        AppErrorCode.validation,
        message: 'حجم الصورة يتجاوز ${(maxBytes / (1024 * 1024)).round()}MB. '
            'اختر صورة أصغر أو اضغطها.',
      );
    }

    final String? mime = detectImageMime(bytes);
    if (mime == null) {
      throw const AppException(
        AppErrorCode.validation,
        message: 'الملف ليس صورة مدعومة (PNG أو JPEG أو GIF أو WebP أو BMP).',
      );
    }

    final UserAsset asset = UserAsset(
      id: UserAsset.newId(),
      type: type,
      name: (name.trim().isEmpty ? _nameFromFile(fileName) : name.trim()),
      fileName: fileName.replaceAll('\\', '/').split('/').last,
      base64Data: base64Encode(bytes),
      mime: mime,
      addedAt: DateTime.now(),
    );

    _assets.add(asset);
    await _persist();
    notifyListeners();
    return asset;
  }

  /// إعادة تسمية أصل. لا يرمي.
  Future<void> renameAsset(String id, String name) async {
    final String clean = name.trim();
    if (clean.isEmpty) return;
    final int index = _assets.indexWhere((UserAsset a) => a.id == id);
    if (index < 0) return;
    _assets[index] = _assets[index].copyWith(name: clean);
    await _persist();
    notifyListeners();
  }

  /// حذف أصل. القوالب التي تشير إليه تفقد الصورة بأناقة (لا فشل).
  Future<void> removeAsset(String id) async {
    final int before = _assets.length;
    _assets.removeWhere((UserAsset a) => a.id == id);
    if (_assets.length == before) return;
    // إسقاط البايتات المفكوكة كي لا تبقى صورة محذوفة في الذاكرة.
    AssetImageCache.instance.evictAsset(id);
    await _persist();
    notifyListeners();
  }

  /// حذف الكل (أداة إعادة تعيين/اختبارات).
  Future<void> clear() async {
    _assets.clear();
    AssetImageCache.instance.clear();
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() => _store.saveAll(List<UserAsset>.from(_assets));

  // ==========================================================================
  //  أدوات داخلية
  // ==========================================================================

  static String _nameFromFile(String fileName) {
    String base = fileName.replaceAll('\\', '/').split('/').last;
    final int dot = base.lastIndexOf('.');
    if (dot > 0) base = base.substring(0, dot);
    return base.trim().isEmpty ? 'أصل بلا اسم' : base.trim();
  }

  /// كشف نوع الصورة من بصمتها (Magic Bytes) — بلا أي مكتبة خارجية.
  static String? detectImageMime(Uint8List bytes) {
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'image/png';
    }
    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return 'image/jpeg';
    }
    if (bytes.length >= 6 &&
        bytes[0] == 0x47 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x38) {
      return 'image/gif';
    }
    if (bytes.length >= 4 && bytes[0] == 0x42 && bytes[1] == 0x4D) {
      return 'image/bmp';
    }
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return 'image/webp';
    }
    return null;
  }
}

