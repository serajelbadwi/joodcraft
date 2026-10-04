import 'dart:typed_data';

/// فحص ملف خط (.ttf / .otf) داخل دارت بلا أي مكتبة خارجية.
///
/// لماذا نحتاج هذا الفحص؟ لأن محرّك الطباعة في دارت يرسم العربية **بصيغ العرض
/// المتصلة** (`Arabic Presentation Forms-B`, U+FE80..FEF4) ولا ينفّذ جداول
/// GSUB. لذلك أي خط يُرفع بلا هذه الصيغ في `cmap` سيظهر مربعات فارغة رغم أنه
/// «خط عربي» سليم. الفحص هنا يحوّل ذلك من مفاجأة عند الطباعة إلى تحذير واضح
/// لحظة الرفع.
///
/// يُقرأ من ملف الـ sfnt الحد الأدنى اللازم فقط: جدول المحارف (`head`)،
/// الأسماء (`name`)، و`cmap` بصيغتيه 4 و12.
class FontInspection {
  const FontInspection({
    required this.isValid,
    this.errorAr,
    this.sfntVersion,
    this.tables = const <String>{},
    this.familyName,
    this.subfamilyName,
    this.fullName,
    this.postScriptName,
    this.unitsPerEm,
    this.presentationForms = const <int>{},
    this.lamAlefForms = const <int>{},
    this.codePoints = const <int>{},
  });

  const FontInspection.invalid(String message)
      : this(isValid: false, errorAr: message);

  final bool isValid;

  /// سبب الرفض بالعربية (عند `isValid == false`).
  final String? errorAr;

  /// `TrueType` أو `OTTO` (خط CFF) أو `true` (تنسيق أبل القديم).
  final String? sfntVersion;

  /// أسماء جداول الملف — مفيدة للتشخيص.
  final Set<String> tables;

  final String? familyName;
  final String? subfamilyName;
  final String? fullName;
  final String? postScriptName;

  final int? unitsPerEm;

  /// صور الحروف (U+FE80..FEF4) الموجودة فعلاً في `cmap`.
  final Set<int> presentationForms;

  /// صور لام-ألف (U+FEF5..FEFC).
  final Set<int> lamAlefForms;

  /// كل محارف BMP (‎U+0000..U+FFFF‎) الموجودة في `cmap` فعلاً.
  ///
  /// أساس فحص التغطية العام: به نضمن أن أي نص ترجمة يُرسم بلا مربعات فارغة
  /// (□□□) — راجع `test/unit/cjk_font_coverage_test.dart`.
  final Set<int> codePoints;

  /// هل يرسم هذا الخط المحرف [codePoint]؟
  bool covers(int codePoint) => codePoints.contains(codePoint);

  static const int presentationFormStart = 0xFE80;
  static const int presentationFormEnd = 0xFEF4;
  static const int lamAlefStart = 0xFEF5;
  static const int lamAlefEnd = 0xFEFC;

  /// إجمالي صور الحروف المطلوبة (117).
  static const int requiredPresentationFormCount =
      presentationFormEnd - presentationFormStart + 1;

  /// إجمالي صور لام-ألف المطلوبة (8).
  static const int requiredLamAlefFormCount = lamAlefEnd - lamAlefStart + 1;

  bool get supportsArabicPdf =>
      missingPresentationFormCount == 0 && missingLamAlefFormCount == 0;

  int get missingPresentationFormCount =>
      requiredPresentationFormCount - presentationForms.length;

  int get missingLamAlefFormCount =>
      requiredLamAlefFormCount - lamAlefForms.length;

  /// مثال: `117/117`.
  String get arabicCoverageLabel =>
      '${presentationForms.length}/$requiredPresentationFormCount';

  String get lamAlefCoverageLabel =>
      '${lamAlefForms.length}/$requiredLamAlefFormCount';

  /// هل تنسيق الملف CFF (OpenType/PostScript) بدل TrueType؟
  bool get isOpenTypeCff => sfntVersion == 'OTTO';

  /// هل يحمل الملف محيطات حروف TrueType (`glyf`/`loca`) القابلة للرسم في
  /// محرّك الطباعة؟
  ///
  /// خطوط CFF/PostScript (‎.otf) تحمل صور الحروف داخل جدول `CFF ` لا ينفّذه
  /// محرّك `pdf`، فيُرسَم النص بحروف فارغة أو مشوّهة. مفتاح الفحص هذا هو ما يمنع
  /// ظهور ذلك التشوّه عند الحفظ/الطباعة.
  bool get hasTrueTypeOutlines =>
      tables.contains('glyf') && tables.contains('loca');

  /// هل يصلح هذا الخط للرسم في محرّك الـ PDF (صور حروف + محيطات TrueType)؟
  bool get isPdfRenderable => hasTrueTypeOutlines;

  /// الوزن المستنتج من اسم النمط الفرعي (Regular/Bold/Medium…).
  ///
  /// القيم تعود إلى الأوزان الثلاثة التي يدعمها المحرك (400/600/700).
  /// الترتيب مهم: `SemiBold` تحتوي `Bold`، فيُفحص المتوسط أولاً.
  int get inferredWeight {
    final String source = subfamilyName?.isNotEmpty == true
        ? subfamilyName!
        : '${fullName ?? ''} ${postScriptName ?? ''}';
    final String needle = source.toLowerCase();
    if (needle.contains('semibold') ||
        needle.contains('semi bold') ||
        needle.contains('demibold') ||
        needle.contains('demi bold') ||
        needle.contains('medium')) {
      return 600;
    }
    if (needle.contains('bold') ||
        needle.contains('black') ||
        needle.contains('heavy')) {
      return 700;
    }
    // Light/Thin/Regular كلها تُعالج كوزن عادي: المحرك لا يميّز أخف من العادي.
    return 400;
  }
}

/// قارئ الحد الأدنى من بنية ملفات sfnt.
abstract final class FontInspector {
  static const Set<String> _latinFallbackTables = <String>{
    'head',
    'cmap',
    'name',
    'hhea',
    'hmtx',
    'maxp',
  };

  /// فحص بايتات خط. لا يرمي استثناءات أبداً — أي تلف يُعاد كـ
  /// [FontInspection.invalid] مع سبب عربي واضح.
  static FontInspection inspect(Uint8List bytes) {
    try {
      return _inspect(bytes);
    } catch (error) {
      return FontInspection.invalid('تعذّرت قراءة بنية ملف الخط: $error');
    }
  }

  static FontInspection _inspect(Uint8List bytes) {
    if (bytes.lengthInBytes < 12) {
      return const FontInspection.invalid(
        'الملف أصغر من أن يكون خطاً صالحاً.',
      );
    }
    final ByteData data = ByteData.sublistView(bytes);
    final String? sfntVersion = switch (data.getUint32(0)) {
      0x00010000 => 'TrueType',
      0x4F54544F => 'OTTO', // 'OTTO'
      0x74727565 => 'true', // 'true'
      0x74797031 => 'typ1',
      _ => null,
    };
    if (sfntVersion == null) {
      return const FontInspection.invalid(
        'الملف ليس خط TrueType/OpenType. تأكد أنه ملف .ttf أو .otf خام '
        '(لا حزمة مضغوطة ولا ملف مرفق ببرنامج).',
      );
    }

    final int numTables = data.getUint16(4);
    if (numTables == 0 || numTables > 512) {
      return const FontInspection.invalid('جدول محتويات الخط تالف.');
    }

    final Map<String, _Table> tables = <String, _Table>{};
    for (int i = 0; i < numTables; i++) {
      final int record = 12 + i * 16;
      if (record + 16 > bytes.length) break;
      final String tag = String.fromCharCodes(bytes, record, record + 4);
      final int offset = data.getUint32(record + 8);
      final int length = data.getUint32(record + 12);
      if (offset <= 0 || length <= 0) continue;
      if (offset + length > bytes.length) continue;
      tables[tag] = _Table(offset, length);
    }

    final Set<String> missingRequired = _latinFallbackTables
        .where((String tag) => !tables.containsKey(tag))
        .toSet();
    if (missingRequired.contains('head') || missingRequired.contains('cmap')) {
      return const FontInspection.invalid(
        'الخط يفتقد جداول أساسية (head/cmap) — الملف تالف أو مبتور.',
      );
    }

    return FontInspection(
      isValid: true,
      sfntVersion: sfntVersion,
      tables: tables.keys.toSet(),
      // 16/17 هما الاسمان "الطباعيان" (بلا الوزن)؛ 1/2 قد يحملان الوزن داخل
      // اسم العائلة (مثل "IBM Plex Sans Arabic SemiBold")، لذلك هما الاحتياط.
      familyName: _readName(data, tables['name'], 16) ??
          _readName(data, tables['name'], 1),
      subfamilyName: _readName(data, tables['name'], 17) ??
          _readName(data, tables['name'], 2),
      fullName: _readName(data, tables['name'], 4),
      postScriptName: _readName(data, tables['name'], 6),
      unitsPerEm: _readUnitsPerEm(data, tables['head']),
      presentationForms: _coveredCodePoints(
        data,
        tables['cmap'],
        FontInspection.presentationFormStart,
        FontInspection.presentationFormEnd,
      ),
      lamAlefForms: _coveredCodePoints(
        data,
        tables['cmap'],
        FontInspection.lamAlefStart,
        FontInspection.lamAlefEnd,
      ),
      codePoints: _coveredCodePoints(data, tables['cmap'], 0x0000, 0xFFFF),
    );
  }

  // --------------------------------------------------------------------------
  //  head
  // --------------------------------------------------------------------------
  static int? _readUnitsPerEm(ByteData data, _Table? table) {
    if (table == null || table.offset + 20 > data.lengthInBytes) return null;
    final int units = data.getUint16(table.offset + 18);
    return units == 0 ? null : units;
  }

  // --------------------------------------------------------------------------
  //  name
  // --------------------------------------------------------------------------
  /// يقرأ اسم الحقل [nameId] بأفضل ترميز متاح: UTF-16BE (منصة ويندوز) أولاً،
  /// ثم MacRoman/Latin، ثم أي سجل يطابق المعرّف.
  static String? _readName(ByteData data, _Table? table, int nameId) {
    if (table == null || table.length < 6) return null;
    final int base = table.offset;
    if (base + 6 > data.lengthInBytes) return null;
    final int count = data.getUint16(base + 2);
    final int stringOffset = data.getUint16(base + 4);

    String? best;
    int bestScore = -1;
    for (int i = 0; i < count; i++) {
      final int record = base + 6 + i * 12;
      if (record + 12 > data.lengthInBytes) break;
      if (data.getUint16(record + 6) != nameId) continue;
      final int platformId = data.getUint16(record);
      final int length = data.getUint16(record + 8);
      final int offset = data.getUint16(record + 10);
      final int start = base + stringOffset + offset;
      if (start < 0 || start + length > data.lengthInBytes || length == 0) {
        continue;
      }
      final int score = switch (platformId) {
        3 => 3, // Windows/UTF-16BE
        0 => 2, // Unicode
        1 => 1, // Macintosh
        _ => 0,
      };
      if (score < bestScore) continue;
      final String value = platformId == 3 || platformId == 0
          ? _utf16Be(data, start, length)
          : _latin1(data, start, length);
      final String trimmed = value.trim();
      if (trimmed.isEmpty) continue;
      best = trimmed;
      bestScore = score;
    }
    return best;
  }

  static String _utf16Be(ByteData data, int start, int length) {
    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i + 1 < length; i += 2) {
      final int unit = data.getUint16(start + i);
      if (unit == 0) continue;
      buffer.writeCharCode(unit);
    }
    return buffer.toString();
  }

  static String _latin1(ByteData data, int start, int length) {
    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < length; i++) {
      final int byte = data.getUint8(start + i);
      if (byte == 0) continue;
      buffer.writeCharCode(byte);
    }
    return buffer.toString();
  }

  // --------------------------------------------------------------------------
  //  cmap
  // --------------------------------------------------------------------------
  /// يبني مجموعة المحارف الموجودة فعلاً (گليف ≠ 0) ضمن النطاق المطلوب.
  static Set<int> _coveredCodePoints(
    ByteData data,
    _Table? cmap,
    int rangeStart,
    int rangeEnd,
  ) {
    final Set<int> covered = <int>{};
    if (cmap == null || cmap.length < 4) return covered;

    final int base = cmap.offset;
    if (base + 4 > data.lengthInBytes) return covered;
    final int subtableCount = data.getUint16(base + 2);

    for (int i = 0; i < subtableCount; i++) {
      final int record = base + 4 + i * 8;
      if (record + 8 > data.lengthInBytes) break;
      final int subOffset = base + data.getUint32(record + 4);
      if (subOffset + 2 > data.lengthInBytes) continue;
      final int format = data.getUint16(subOffset);
      if (format == 4) {
        _collectFormat4(data, subOffset, rangeStart, rangeEnd, covered);
      } else if (format == 12) {
        _collectFormat12(data, subOffset, rangeStart, rangeEnd, covered);
      }
    }
    return covered;
  }

  static void _collectFormat4(
    ByteData data,
    int start,
    int rangeStart,
    int rangeEnd,
    Set<int> covered,
  ) {
    if (start + 14 > data.lengthInBytes) return;
    final int segCountX2 = data.getUint16(start + 6);
    final int segCount = segCountX2 ~/ 2;
    if (segCount == 0) return;
    final int endCodes = start + 14;
    final int startCodes = endCodes + segCountX2 + 2; // +2 للـ reservedPad
    final int idDeltas = startCodes + segCountX2;
    final int idRangeOffsets = idDeltas + segCountX2;
    if (idRangeOffsets + segCountX2 > data.lengthInBytes) return;

    for (int i = 0; i < segCount; i++) {
      final int end = data.getUint16(endCodes + i * 2);
      final int segStart = data.getUint16(startCodes + i * 2);
      if (end == 0xFFFF && segStart == 0xFFFF) continue;
      if (segStart > rangeEnd || end < rangeStart) continue;
      final int delta = data.getInt16(idDeltas + i * 2);
      final int rangeOffset = data.getUint16(idRangeOffsets + i * 2);
      final int from = segStart < rangeStart ? rangeStart : segStart;
      final int to = end > rangeEnd ? rangeEnd : end;
      for (int code = from; code <= to; code++) {
        int glyph;
        if (rangeOffset == 0) {
          glyph = (code + delta) & 0xFFFF;
        } else {
          // موضع الحرف داخل glyphIdArray انطلاقاً من موضع idRangeOffset نفسه.
          final int index =
              idRangeOffsets + i * 2 + rangeOffset + (code - segStart) * 2;
          if (index + 2 > data.lengthInBytes) continue;
          glyph = data.getUint16(index);
          if (glyph != 0) glyph = (glyph + delta) & 0xFFFF;
        }
        if (glyph != 0) covered.add(code);
      }
    }
  }

  static void _collectFormat12(
    ByteData data,
    int start,
    int rangeStart,
    int rangeEnd,
    Set<int> covered,
  ) {
    if (start + 16 > data.lengthInBytes) return;
    final int groupCount = data.getUint32(start + 12);
    for (int g = 0; g < groupCount; g++) {
      final int group = start + 16 + g * 12;
      if (group + 12 > data.lengthInBytes) break;
      final int first = data.getUint32(group);
      final int last = data.getUint32(group + 4);
      if (first > rangeEnd || last < rangeStart) continue;
      final int from = first < rangeStart ? rangeStart : first;
      final int to = last > rangeEnd ? rangeEnd : last;
      for (int code = from; code <= to; code++) {
        covered.add(code);
      }
    }
  }
}

/// موضع جدول داخل الملف.
class _Table {
  const _Table(this.offset, this.length);

  final int offset;
  final int length;
}
