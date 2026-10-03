import 'dart:convert';
import 'dart:typed_data';

import '../../../core/errors/app_error_code.dart';
import '../../../core/errors/app_exception.dart';
import '../domain/sheet_data.dart';
import '../domain/sheet_reader.dart';

/// قارئ ملفات CSV/TSV محلي بلا أي مكتبة خارجية.
///
/// يتعامل مع الحالات التي تُفشل قارئات CSV الساذجة فعلياً:
/// * علامة ترتيب البايتات (BOM) التي يضيفها Excel في أول الخلية.
/// * الترميز: UTF-8 و UTF-16 (‏LE/BE) — فتصدير Excel العربي يعمل مباشرة.
/// * علامات التنصيص وعلامات التنصيص المُهرَّبة (`""`) والنقطة/السطر الجديد
///   **داخل** الخلية.
/// * الفواصل العربية: `,` و`;` و`\t` و`|` — تُكتشف تلقائياً من الملف.
class CsvSheetReader implements SheetReader {
  const CsvSheetReader({this.forcedDelimiter});

  /// فاصل مُفرَض (يُستخدم لملفات `.tsv` التي نعرف فاصلها مسبقاً).
  final String? forcedDelimiter;

  /// الفواصل المرشَّحة للكشف التلقائي، بترتيب الأولوية عند التعادل.
  static const List<String> candidateDelimiters = <String>[
    ',',
    ';',
    '\t',
    '|',
  ];

  @override
  SheetData read(
    Uint8List bytes, {
    String sourceName = '',
    int? headerRowIndex,
  }) {
    if (bytes.isEmpty) {
      throw const AppException(
        AppErrorCode.excelImport,
        message: 'الملف فارغ.',
      );
    }
    final String text = decodeText(bytes);
    if (text.trim().isEmpty) {
      throw const AppException(
        AppErrorCode.excelImport,
        message: 'الملف لا يحتوي أي نص قابل للقراءة.',
      );
    }

    final String delimiter = forcedDelimiter ?? detectDelimiter(text);
    final List<List<String>> matrix = parse(text, delimiter);

    final SheetData data = SheetData.fromMatrix(
      matrix,
      sourceName: sourceName,
      headerRowIndex: headerRowIndex,
    );
    if (data.isEmpty) {
      throw const AppException(
        AppErrorCode.excelImport,
        message: 'لم يُعثر على صف عناوين في الملف.',
      );
    }
    return data;
  }

  /// فك ترميز النص مع مراعاة BOM وترميز UTF-16.
  static String decodeText(Uint8List bytes) {
    if (bytes.lengthInBytes >= 2) {
      final int b0 = bytes[0];
      final int b1 = bytes[1];
      if (b0 == 0xFF && b1 == 0xFE) {
        return _utf16(bytes, 2, littleEndian: true);
      }
      if (b0 == 0xFE && b1 == 0xFF) {
        return _utf16(bytes, 2, littleEndian: false);
      }
    }
    String text = utf8.decode(bytes, allowMalformed: true);
    // U+FEFF في بداية النص (يظهر أيضاً بعد فك ترميز UTF-16).
    if (text.isNotEmpty && text.codeUnitAt(0) == 0xFEFF) {
      text = text.substring(1);
    }
    return text;
  }

  static String _utf16(Uint8List bytes, int start, {required bool littleEndian}) {
    final StringBuffer buffer = StringBuffer();
    for (int i = start; i + 1 < bytes.length; i += 2) {
      final int unit = littleEndian
          ? bytes[i] | (bytes[i + 1] << 8)
          : (bytes[i] << 8) | bytes[i + 1];
      buffer.writeCharCode(unit);
    }
    return buffer.toString();
  }

  /// يحصر عدد الفاصل [delimiter] في السطر خارج علامات التنصيص.
  static int countOutsideQuotes(String line, String delimiter) {
    bool inQuotes = false;
    int count = 0;
    for (int i = 0; i < line.length; i++) {
      final String ch = line[i];
      if (ch == '"') {
        inQuotes = !inQuotes;
      } else if (!inQuotes && ch == delimiter) {
        count++;
      }
    }
    return count;
  }

  /// كشف الفاصل الأرجح من أول أسطر الملف.
  ///
  /// المنطق: لكل مرشَّح نحسب عدد الفواصل في كل سطر، ثم نُرجّح المرشَّح الذي
  /// يعطي **أكثر الفواصل مع أكثر ثبات** (كل الأسطر بالعدد نفسه). هذا يمنع
  /// الخلط بين `,` داخل نص مروَّس و`;` الحقيقي، ويُفلح مع ملفات عربية يُصدّرها
  /// Excel بأي فاصل.
  static String detectDelimiter(String text) {
    final List<String> lines = text
        .split(RegExp(r'\r\n|\n|\r'))
        .where((String line) => line.trim().isNotEmpty)
        .take(20)
        .toList(growable: false);
    if (lines.isEmpty) return ',';

    double bestScore = -1;
    String best = ',';
    for (final String candidate in candidateDelimiters) {
      final List<int> counts = lines
          .map((String line) => countOutsideQuotes(line, candidate))
          .toList(growable: false);
      final int mode = counts.first;
      if (mode == 0) continue;
      final int consistent =
          counts.where((int value) => value == mode).length;
      final double score = mode + consistent / counts.length;
      if (score > bestScore) {
        bestScore = score;
        best = candidate;
      }
    }
    return best;
  }

  /// تحليل نص مفصول إلى مصفوفة خلايا وفق RFC 4180.
  static List<List<String>> parse(String text, String delimiter) {
    final List<List<String>> rows = <List<String>>[];
    final StringBuffer field = StringBuffer();
    List<String> row = <String>[];
    bool inQuotes = false;

    void endField() {
      row.add(field.toString());
      field.clear();
    }

    void endRow() {
      endField();
      rows.add(row);
      row = <String>[];
    }

    for (int i = 0; i < text.length; i++) {
      final String ch = text[i];
      if (inQuotes) {
        if (ch == '"') {
          // علامة تنصيص مُهرَّبة: "" تعني " حرفياً.
          if (i + 1 < text.length && text[i + 1] == '"') {
            field.write('"');
            i++;
          } else {
            inQuotes = false;
          }
        } else {
          field.write(ch);
        }
        continue;
      }
      if (ch == '"') {
        inQuotes = true;
      } else if (ch == delimiter) {
        endField();
      } else if (ch == '\n') {
        endRow();
      } else if (ch == '\r') {
        if (i + 1 < text.length && text[i + 1] == '\n') continue;
        endRow();
      } else {
        field.write(ch);
      }
    }
    if (field.isNotEmpty || row.isNotEmpty) endRow();
    return rows;
  }
}
