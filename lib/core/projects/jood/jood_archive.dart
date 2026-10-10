import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

/// ثوابت صيغة ملفات JoodCraft المستقلة (‎.jood‎).
///
/// الملف أرشيف ZIP واحد يحوي المستند وملحقاته المرتبطة فقط، فينتقل بين الأجهزة
/// **بلا روابط مفقودة**: لا مسار محلي مطلق ولا مرجع إلى مكتبة أصول المستخدم إلا
/// وهو مضمّن بالبايتات. هذا ما يجعل الملف مستقلّاً تماماً عن جهاز التصدير.
abstract final class JoodFormat {
  const JoodFormat._();

  /// امتداد الملف المعتمد.
  static const String extension = 'jood';

  /// اسم ملف المخطّط (المستند + فهارس الملحقات) — لا يُغيَّر إلا بترقية إصدار.
  static const String documentFile = 'document.json';

  /// مسار فهرس الأصول داخل الأرشيف.
  static const String assetsIndexFile = 'assets/index.json';

  /// مسار فهرس الخطوط المخصصة داخل الأرشيف.
  static const String fontsIndexFile = 'fonts/index.json';

  /// الصورة المصغّرة للمستند داخل الأرشيف.
  static const String thumbnailFile = 'thumbnail.png';

  /// بادئة مجلد الأصول داخل الأرشيف.
  static const String assetsPrefix = 'assets/';

  /// بادئة مجلد الخطوط داخل الأرشيف.
  static const String fontsPrefix = 'fonts/';

  /// بصمة الصيغة داخل المخطّط — تمنع فتح ملف ليس من JoodCraft.
  static const String formatKey = 'joodcraft';

  /// إصدار الصيغة الحالي (يتيح ترقية القراءة لاحقاً بلا كسر ملفات قديمة).
  static const int formatVersion = 1;

  /// هل هذا امتداد ملف مشروع صالح (‎`.jood` أو `jood` بلا نقطة)؟
  static bool isJoodFileName(String fileName) {
    final String lower = fileName.trim().toLowerCase();
    return lower.endsWith('.$extension') || lower == extension;
  }
}

/// أرشيف ZIP خام لملفات ‎.jood‎ — غلاف رقيق حول حزمة `archive`.
///
/// **لماذا طبقة وسيطة؟** حتى تبقى صيغة الملف في مكان واحد، وتُختبر القراءة
/// والكتابة بلا أي منصة: كل ما في هذا الملف نقّي (`Uint8List` ↔ خريطة ملفات)
/// ولا يلمس القرص ولا الشبكة. الأخطاء تُترجم إلى [JoodArchiveException] واضحة.
class JoodArchive {
  JoodArchive();

  /// أرشيف مبني من خريطة اسم ← بايتات (للاختبارات والبناء اليدوي).
  JoodArchive.fromEntries(Map<String, Uint8List> entries) {
    for (final MapEntry<String, Uint8List> entry in entries.entries) {
      _entries[_normalize(entry.key)] = entry.value;
    }
  }

  final Map<String, Uint8List> _entries = <String, Uint8List>{};

  /// أسماء الملفات داخل الأرشيف (بترتيب الإضافة).
  Iterable<String> get names => _entries.keys;

  bool contains(String name) => _entries.containsKey(name);

  int get length => _entries.length;

  /// يضيف ملفاً بايتياً. الاسم يُطبَّع (يُقلَّص، ويُحوَّل الشرط المائل).
  void add(String name, Uint8List bytes) {
    final String key = _normalize(name);
    if (key.isEmpty) {
      throw const JoodArchiveException('اسم ملف داخل الأرشيف فارغ.');
    }
    _entries[key] = bytes;
  }

  /// يضيف ملفاً نصّياً بترميز UTF-8.
  void addText(String name, String text) => add(name, _utf8(text));

  /// يضيف ملفاً من خريطة JSON.
  void addJson(String name, Map<String, dynamic> json) =>
      addText(name, jsonEncode(json));

  /// بايتات ملف، أو `null` إن لم يوجد.
  Uint8List? bytesOf(String name) => _entries[_normalize(name)];

  /// نص ملف (UTF-8)، أو `null` إن لم يوجد.
  String? textOf(String name) {
    final Uint8List? bytes = bytesOf(name);
    return bytes == null ? null : utf8.decode(bytes);
  }

  /// يقرأ JSON من ملف، ويعيد `null` لغيابه أو تلفه (بلا رمي).
  Map<String, dynamic>? jsonOf(String name) {
    final String? text = textOf(name);
    if (text == null || text.trim().isEmpty) return null;
    try {
      final Object? decoded = jsonDecode(text);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
    } catch (_) {
      return null;
    }
  }

  /// يرمّز الأرشيف إلى بايتات ZIP (مضغوطة).
  Uint8List encode() {
    final Archive archive = Archive();
    for (final MapEntry<String, Uint8List> entry in _entries.entries) {
      archive.addFile(ArchiveFile(entry.key, entry.value.length, entry.value));
    }
    final List<int>? encoded = ZipEncoder().encode(archive);
    if (encoded == null) {
      throw const JoodArchiveException('تعذّر ترميز أرشيف المشروع.');
    }
    return Uint8List.fromList(encoded);
  }

  /// يفكّ بايتات ZIP إلى أرشيف. يرمي [JoodArchiveException] على ملف تالف.
  static JoodArchive decode(List<int> data) {
    if (data.isEmpty) {
      throw const JoodArchiveException('ملف المشروع فارغ.');
    }
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(data);
    } catch (error) {
      throw JoodArchiveException('ملف المشروع ليس أرشيفاً صالحاً: $error');
    }
    final JoodArchive result = JoodArchive();
    for (final ArchiveFile file in archive.files) {
      if (!file.isFile) continue;
      result.add(file.name, _readContent(file));
    }
    return result;
  }

  static Uint8List _readContent(ArchiveFile file) {
    final Object? raw = file.content;
    if (raw is Uint8List) return raw;
    if (raw is List<int>) return Uint8List.fromList(raw);
    if (raw is List) return Uint8List.fromList(raw.cast<int>());
    return Uint8List.fromList(utf8.encode('$raw'));
  }

  static String _normalize(String name) =>
      name.trim().replaceAll('\\', '/').replaceAll(RegExp(r'^/+'), '');

  static Uint8List _utf8(String text) => Uint8List.fromList(utf8.encode(text));
}

/// خطأ صيغة ‎.jood‎ — رسالة عربية مباشرة للمستخدم.
class JoodArchiveException implements Exception {
  const JoodArchiveException(this.message);

  final String message;

  @override
  String toString() => message;
}
