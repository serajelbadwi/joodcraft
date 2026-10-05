import 'dart:typed_data';

/// التنفيذ الفارغ (ويب/بلا نظام ملفات) لمخزن كاش الصور القرصي.
///
/// الغرض: التهدئة — على الويب لا نظام ملفات دائم، فتُرجع القراءة `null` ولا
/// تفعل الكتابة شيئاً، فيبقى كود الكاش واحداً على كل المنصات بلا كسر البناء.
/// راجع التنفيذ الفعلي في `asset_image_disk_cache_io.dart`.
class AssetImageDiskCacheStore {
  AssetImageDiskCacheStore(this.rootPath, this.maxEntries, this.maxBytes);

  final String rootPath;
  final int maxEntries;
  final int maxBytes;

  Future<Uint8List?> read(String assetId) async => null;

  Future<void> write(String assetId, Uint8List bytes) async {}

  Future<void> remove(String assetId) async {}

  Future<void> clear() async {}

  /// لا نظام ملفات — لا شيء يُحذف.
  Future<int> prune(Set<String> keepIds) async => 0;

  /// لا نظام ملفات — لا حجم على القرص.
  Future<(int, int)> stats() async => (0, 0);
}

/// لا نظام ملفات على الويب — لا جذر افتراضي.
String defaultImageCacheRootPath() => '';
