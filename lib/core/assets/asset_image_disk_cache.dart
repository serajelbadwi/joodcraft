import 'package:flutter/foundation.dart';

import 'asset_image_disk_cache_stub.dart'
    if (dart.library.io) 'asset_image_disk_cache_io.dart' as impl;

/// حجم كاش الصور القرصي: عدد الملفات ومجموع البايتات.
class AssetImageCacheStats {
  const AssetImageCacheStats({required this.files, required this.bytes});

  final int files;
  final int bytes;

  /// كاش فارغ (الويب أو بعد المسح).
  static const AssetImageCacheStats empty =
      AssetImageCacheStats(files: 0, bytes: 0);

  bool get isEmpty => files == 0 || bytes == 0;
}

// كاش على القرص لبايتات الصور المفكوكة من Base64 (الإطارات/الخلفيات).
//
// يحفظ البايتات **المفكوكة** (صيغة الصورة الأصلية: PNG/JPEG كما هي) في ملف
// واحد لكل أصل، فيجدتها الفتحة التالية للتطبيق بلا إعادة فكّ Base64 وبلا أي
// حزمة ترميز جديدة. التنفيذ الفعلي يُستورد شرطياً (فارغ على الويب).
class AssetImageDiskCache {
  AssetImageDiskCache({
    String? rootPath,
    this.maxEntries = defaultMaxEntries,
    this.maxBytes = defaultMaxBytes,
  }) : _store = impl.AssetImageDiskCacheStore(
          rootPath ?? impl.defaultImageCacheRootPath(),
          maxEntries,
          maxBytes,
        );

  /// أقصى عدد صور محفوظة على القرص.
  static const int defaultMaxEntries = 64;

  /// سقف مجموع البايتات المحفوظة (‎32MB‎) — يمنع إطارات/خلفيات ضخمة من ملء
  /// مجلّد الكاش وإن كان عددها صغيراً.
  static const int defaultMaxBytes = 32 * 1024 * 1024;

  static AssetImageDiskCache _instance = AssetImageDiskCache();

  /// النسخة المشتركة للتطبيق (وهي نسخة الويب الفارغة على الويب).
  static AssetImageDiskCache get instance => _instance;

  /// استبدال النسخة المشتركة — للاختبارات (جذر مؤقّت) ولإعادة الضبط.
  @visibleForTesting
  static set instance(AssetImageDiskCache value) => _instance = value;

  final impl.AssetImageDiskCacheStore _store;

  /// سقف عدد الصور المحفوظة على القرص.
  final int maxEntries;

  /// سقف مجموع بايتات الصور المحفوظة على القرص.
  final int maxBytes;

  /// يقرأ بايتات الأصل [assetId] من الكاش، أو `null` إن لم تكن محفوظة.
  Future<Uint8List?> read(String assetId) => _store.read(assetId);

  /// يحفظ بايتات الأصل [assetId] في الكاش (لا يرمي).
  Future<void> write(String assetId, Uint8List bytes) =>
      _store.write(assetId, bytes);

  /// يحذف نسخة الأصل [assetId].
  Future<void> remove(String assetId) => _store.remove(assetId);

  /// يمسح الكاش كله.
  Future<void> clear() => _store.clear();

  /// يحذف ملفات الكاش التي لا تعود تخص أي أصل في المكتبة (يعيد العدد).
  ///
  /// يستدعى من الخلفية عند بدء التشغيل فيُسترجع القرص الذي شغله أصلٌ حُذف،
  /// ولا يعطّل القراءة الحالية لأن كل عملية قراءة/كتابة تعيد التحقق من الملف.
  Future<int> prune(Set<String> keepIds) => _store.prune(keepIds);

  /// حجم الكاش على القرص (للعرض والتشخيص).
  Future<AssetImageCacheStats> stats() async {
    final (int files, int bytes) = await _store.stats();
    return AssetImageCacheStats(files: files, bytes: bytes);
  }
}
