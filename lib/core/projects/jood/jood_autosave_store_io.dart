import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'jood_autosave_store.dart';

/// حفظ تلقائي في ملف واحد داخل مجلد بيانات التطبيق (سطح المكتب/الجوال).
///
/// الكتابة **ذرّية**: تُكتب المسودّة في ملف مؤقّت ثم تُستبدل به النسخة السابقة،
/// فلا يبقى نصف ملف إن انقطع التيار أو أُغلق التطبيق أثناء الكتابة — وهذا جوهر
/// التعافي من الإغلاق المفاجئ. كل العمليات غير حاجزة (‎async‎ I/O‎) فلا تتجمّد
/// الواجهة. لا يرمي أي شيء: الفشل يُسجَّل ويُتجاهل.
class FileJoodAutosaveStore implements JoodAutosaveStore {
  FileJoodAutosaveStore({this.fileName = defaultFileName});

  /// اسم ملف المسودّة الافتراضي — ملف واحد يُستعاد تلقائياً عند الإقلاع.
  static const String defaultFileName = 'autosave_draft.jood';

  final String fileName;

  File? _cached;

  Future<File> _file() async {
    final File? cached = _cached;
    if (cached != null) return cached;
    final Directory support = await getApplicationSupportDirectory();
    if (!support.existsSync()) {
      await support.create(recursive: true);
    }
    final File file = File('${support.path}${Platform.pathSeparator}$fileName');
    _cached = file;
    return file;
  }

  @override
  Future<void> write(Uint8List bytes) async {
    try {
      final File target = await _file();
      final File temp = File('${target.path}.tmp');
      await temp.writeAsBytes(bytes, flush: true);
      // استبدال ذرّي: نحاول إعادة التسمية فوق الهدف مباشرةً، وإن رفضتها
      // المنصة (Windows أحياناً) نحذف القديم ثم نُعيد التسمية.
      try {
        await temp.rename(target.path);
      } on FileSystemException {
        if (await target.exists()) await target.delete();
        await temp.rename(target.path);
      }
    } catch (error) {
      debugPrint('[الحفظ التلقائي] تعذّرت كتابة المسودّة: $error');
    }
  }

  @override
  Future<Uint8List?> read() async {
    try {
      final File file = await _file();
      if (!await file.exists()) return null;
      final Uint8List bytes = await file.readAsBytes();
      return bytes.isEmpty ? null : bytes;
    } catch (error) {
      debugPrint('[الحفظ التلقائي] تعذّرت قراءة المسودّة: $error');
      return null;
    }
  }

  @override
  Future<void> delete() async {
    try {
      final File file = await _file();
      if (await file.exists()) await file.delete();
    } catch (error) {
      debugPrint('[الحفظ التلقائي] تعذّر حذف المسودّة: $error');
    }
  }
}

/// المخزن الافتراضي على المنصات التي تدعم الملفات.
JoodAutosaveStore defaultJoodAutosaveStore() => FileJoodAutosaveStore();
