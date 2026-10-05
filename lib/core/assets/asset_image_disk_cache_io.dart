import 'dart:io';
import 'dart:typed_data';

/// التنفيذ الفعلي (بنظام ملفات) لمخزن كاش الصور القرصي.
///
/// **المشكلة التي يحلّها:** صور المستخدم تُحفظ محلياً بترميز Base64 داخل
/// `SharedPreferences`، ويُعاد فكّها وتحميلها في الذاكرة عند كل تشغيل للتطبيق.
/// كاش الذاكرة وحده يضيع بإغلاق التطبيق، فتعود الكلفة كاملة في الفتحة التالية.
///
/// **الحل:** نحفظ البايتات **المفكوكة** (بايتات PNG/JPEG كما هي) في ملف قرصي
/// واحد لكل أصل. الصيغة هي **صيغة الصورة الأصلية نفسها** — بلا ترميز أو فكّ
/// ترميز إضافي وبلا أي حزمة جديدة.
///
/// **الصلاحية:** المفتاح هو معرّف الأصل (`UserAsset.id`) وهو ثابت المضمون.
/// **حدّ أعلى (LRU):** نُبقي أحدث [maxEntries] ملفاً ونُسقط الأقدم.
/// **لا يرمي أبداً:** كل الأخطاء تُبتلع بهدوء، فالكاش مجرّد تسريع.
class AssetImageDiskCacheStore {
  AssetImageDiskCacheStore(this.rootPath, this.maxEntries, this.maxBytes);

  final String rootPath;
  final int maxEntries;

  /// سقف مجموع البايتات المحفوظة — يمنع إطارات ضخمة من ملء مجلّد الكاش.
  final int maxBytes;

  /// يقرأ بايتات الأصل [assetId]، أو `null` إن لم تكن محفوظة.
  Future<Uint8List?> read(String assetId) async {
    try {
      final File cached = _fileFor(assetId);
      if (!await cached.exists()) return null;
      final Uint8List bytes = await cached.readAsBytes();
      if (bytes.isEmpty) return null;
      // تحديث «حداثة الاستخدام» ليحفظها LRU.
      await cached.setLastModified(DateTime.now());
      return bytes;
    } on Object catch (_) {
      return null;
    }
  }

  /// يحفظ بايتات الأصل [assetId] (بصمت عند الفشل).
  Future<void> write(String assetId, Uint8List bytes) async {
    try {
      if (bytes.isEmpty) return;
      await Directory(rootPath).create(recursive: true);
      await _fileFor(assetId).writeAsBytes(bytes, flush: false);
      await _trim();
    } on Object catch (_) {
      // الكاش تحسين اختياري — الفشل لا يُبلَّغ.
    }
  }

  /// يحذف نسخة الأصل [assetId] (عند حذفه من المكتبة).
  Future<void> remove(String assetId) async {
    try {
      final File cached = _fileFor(assetId);
      if (await cached.exists()) await cached.delete();
    } on Object catch (_) {
      // تجاهل.
    }
  }

  /// يمسح الكاش كله (للاختبارات أو إعادة الضبط).
  Future<void> clear() async {
    try {
      final Directory root = Directory(rootPath);
      if (await root.exists()) await root.delete(recursive: true);
    } on Object catch (_) {
      // تجاهل.
    }
  }

  /// يحذف ملفات الكاش التي لا تعود تخص أي أصل في المكتبة (يعيد العدد).
  ///
  /// **الغرض:** أصلٌ حُذف من المكتبة لا يجب أن يشغل القرص إلى الأبد، والحدّ
  /// الأعلى ([maxEntries]/[maxBytes]) يقيس الكاش كاملاً بما فيه اليتيم. تُمرَّر
  /// المعرّفات الصالحة [keepIds] فقط، فتُحذف كل ملف ‎`.bin‎` غير مطابق. لا يرمي.
  Future<int> prune(Set<String> keepIds) async {
    try {
      final Directory root = Directory(rootPath);
      if (!await root.exists()) return 0;
      final Set<String> keep = keepIds.map(_sanitize).toSet();
      int removed = 0;
      await for (final FileSystemEntity entity in root.list()) {
        if (entity is! File) continue;
        final String name = entity.uri.pathSegments.last;
        if (!name.endsWith('.bin')) continue;
        if (keep.contains(name.substring(0, name.length - 4))) continue;
        try {
          await entity.delete();
          removed++;
        } on Object catch (_) {
          // قد يكون حُذف من عملية أخرى أو كان مقفولاً (ويندوز).
        }
      }
      return removed;
    } on Object catch (_) {
      return 0;
    }
  }

  /// حجم الكاش على القرص: (عدد الملفات، مجموع البايتات).
  ///
  /// يُستخدم لعرض الاستهلاك في مدير الأصول. لا يرمي — أي خطأ يُرجَع كـ«فارغ».
  Future<(int, int)> stats() async {
    try {
      final Directory root = Directory(rootPath);
      if (!await root.exists()) return (0, 0);
      int files = 0;
      int bytes = 0;
      await for (final FileSystemEntity entity in root.list()) {
        if (entity is File && entity.path.endsWith('.bin')) {
          files++;
          bytes += await entity.length();
        }
      }
      return (files, bytes);
    } on Object catch (_) {
      return (0, 0);
    }
  }

  /// يُسقط «الأقل استخداماً» حتى لا يتجاوز عدد الملفات ولا مجموع البايتات
  /// الحدّين. لا يُسقط الملف **الأحدث** أبداً حتى لو تجاوز وحده السقف، فلا يبقى
  /// المجلد فارغاً بعد كتابة صورة ضخمة واحدة.
  Future<void> _trim() async {
    try {
      final List<File> files = await Directory(rootPath)
          .list()
          .where((FileSystemEntity e) => e is File && e.path.endsWith('.bin'))
          .cast<File>()
          .toList();

      final List<(File, DateTime, int)> entries = <(File, DateTime, int)>[];
      int total = 0;
      for (final File file in files) {
        final FileStat stat = await file.stat();
        entries.add((file, stat.modified, stat.size));
        total += stat.size;
      }
      // الأقدم استخداماً أولاً.
      entries.sort((a, b) => a.$2.compareTo(b.$2));

      int count = entries.length;
      for (int i = 0; i < entries.length - 1; i++) {
        if (count <= maxEntries && total <= maxBytes) break;
        try {
          await entries[i].$1.delete();
        } on Object catch (_) {
          // تجاهل: قد يُحذف من عملية أخرى.
        }
        count--;
        total -= entries[i].$3;
      }
    } on Object catch (_) {
      // المجلد غير موجود/غير قابل للقراءة — لا شيء.
    }
  }

  File _fileFor(String assetId) => File('$rootPath/${_sanitize(assetId)}.bin');

  /// يجعل المعرّف اسماً آمناً للملف على كل الأنظمة.
  static String _sanitize(String assetId) =>
      assetId.replaceAll(RegExp(r'[^A-Za-z0-9_.-]'), '_');
}

/// المجلد الجذر الافتراضي للكاش (مجلد كاش المستخدم القياسي على كل نظام).
String defaultImageCacheRootPath() {
  final Map<String, String> env = Platform.environment;
  final String base = env['LOCALAPPDATA'] ??
      env['XDG_CACHE_HOME'] ??
      env['HOME'] ??
      Directory.systemTemp.path;
  return '$base/JoodCraft/image_cache';
}
