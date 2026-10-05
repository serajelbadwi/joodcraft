import 'dart:io';
import 'dart:typed_data';

/// كاش على القرص لبايتات خطوط النظام.
///
/// **لماذا كاش قرصي؟** قراءة ملفات الخطوط من `C:\Windows\Fonts` متكررة عند كل
/// تشغيل للتطبيق (وتحليل الخط لاحقاً ثقيل). فهنا نحفظ نسخة من البايتات في مجلد
/// كاش محلي، فيكون الفتح التالي قراءة تسلسلية واحدة من الـSSD بدل المسار الكامل.
///
/// **صلاحية النسخة:** مفتاح الملف = دالة تجزئة ثابتة على (المسار + الحجم + زمن
/// آخر تعديل)، فإذا تغيّر ملف الخط (تحديث النظام مثلاً) يتغيّر المفتاح تلقائياً
/// ولا يُستعمل كاش قديم.
///
/// **حدّ أعلى (LRU):** نُبقي أحدث [maxEntries] ملفاً ونُسقط الأقدم.
///
/// **لا يرمي أبداً:** كل الأخطاء (صلاحيات/مجلد غير قابل للكتابة) تُبتلع بهدوء،
/// لأن الكاش مجرّد تسريع لا يجوز أن يُعطّل قراءة الخط نفسه.
class SystemFontDiskCache {
  SystemFontDiskCache({Directory? root, this.maxEntries = defaultMaxEntries})
      : _root = root ?? defaultRoot();

  /// أقصى عدد ملفات محفوظة على القرص.
  static const int defaultMaxEntries = 64;

  final Directory _root;
  final int maxEntries;

  /// المجلد الجذر الافتراضي للكاش (قابل للاستبدال في الاختبارات).
  static Directory defaultRoot() {
    final Map<String, String> env = Platform.environment;
    final String base = env['LOCALAPPDATA'] ??
        env['XDG_CACHE_HOME'] ??
        env['HOME'] ??
        Directory.systemTemp.path;
    return Directory('$base/JoodCraft/font_cache');
  }

  /// المجلد الفعلي للكاش (للتشخيص).
  Directory get root => _root;

  /// يقرأ بايتات [path] من الكاش، أو `null` إن غابت/تغيّر ملفها المصدر.
  Future<Uint8List?> read(String path) async {
    try {
      final File source = File(path);
      if (!await source.exists()) return null;
      final FileStat stat = await source.stat();
      final File cached = File('${_root.path}/${_keyFor(path, stat)}.bin');
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

  /// يحفظ بايتات [path] في الكاش (بصمت عند الفشل).
  Future<void> write(String path, Uint8List bytes) async {
    try {
      if (bytes.isEmpty) return;
      await _root.create(recursive: true);
      final FileStat stat = await File(path).stat();
      final File cached = File('${_root.path}/${_keyFor(path, stat)}.bin');
      await cached.writeAsBytes(bytes, flush: false);
      await _trim();
    } on Object catch (_) {
      // الكاش تحسين اختياري — الفشل لا يُبلَّغ.
    }
  }

  /// يُسقط «الأقل استخداماً» حتى لا يتجاوز الحدّ الأعلى.
  Future<void> _trim() async {
    try {
      final List<File> files = await _root
          .list()
          .where((FileSystemEntity e) => e is File && e.path.endsWith('.bin'))
          .cast<File>()
          .toList();
      if (files.length <= maxEntries) return;
      final List<(File, DateTime)> stamped = <(File, DateTime)>[];
      for (final File file in files) {
        stamped.add((file, (await file.stat()).modified));
      }
      stamped.sort(
        ((File, DateTime) a, (File, DateTime) b) =>
            a.$2.compareTo(b.$2),
      );
      for (int i = 0; i < stamped.length - maxEntries; i++) {
        try {
          await stamped[i].$1.delete();
        } on Object catch (_) {
          // تجاهل: قد يُحذف من عملية أخرى.
        }
      }
    } on Object catch (_) {
      // المجلد غير موجود/غير قابل للقراءة — لا شيء.
    }
  }

  /// يمسح الكاش كله (للاختبارات أو إعادة الضبط).
  Future<void> clear() async {
    try {
      if (await _root.exists()) {
        await _root.delete(recursive: true);
      }
    } on Object catch (_) {
      // تجاهل.
    }
  }

  /// يبني مفتاحاً ثابتاً من المسار وحجم الملف وزمن تعديله.
  String _keyFor(String path, FileStat stat) {
    final String seed =
        '${path.toLowerCase()}|${stat.size}|${stat.modified.millisecondsSinceEpoch}';
    return _stableHash(seed);
  }

  /// تجزئة FNV-1a ‏64‑بت ثابتة عبر التشغيلات (بعكس `hashCode` غير المضمون).
  static String _stableHash(String input) {
    int hash = 0xcbf29ce484222325;
    for (final int unit in input.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x100000001b3) & 0xFFFFFFFFFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(16, '0');
  }
}
