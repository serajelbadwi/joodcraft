import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';

import '../../../core/errors/app_error_code.dart';
import '../../../core/errors/app_exception.dart';
import '../domain/sheet_data.dart';
import '../domain/sheet_reader.dart';
import 'csv_sheet_reader.dart';

/// قارئ ملفات Excel (`.xlsx` / `.xlsm`) محلياً بلا أي خدمة خارجية.
///
/// التحويل هنا هو **مصدر الحقيقة** لشكل الخلايا: كل نوع خلية يُترجم إلى نص
/// عربي مقروء (تاريخ `1447/03/12` لا `2026-03-12T00:00:00.000Z`، ورقم صحيح لا
/// `150000.0`). هذا ما يُكتب بعدها في مكان `{{الحقل}}` داخل الشهادة.
class XlsxSheetReader implements SheetReader {
  const XlsxSheetReader({this.sheetName});

  /// اسم الورقة المطلوب قراءتها؛ `null` = أول ورقة في الملف.
  final String? sheetName;

  @override
  SheetData read(Uint8List bytes, {String sourceName = ''}) {
    if (bytes.isEmpty) {
      throw const AppException(
        AppErrorCode.excelImport,
        message: 'الملف فارغ.',
      );
    }

    // قراءة آمنة: البايتات تصل من القرص عبر `await file.readAsBytes()` (شاشة
    // الاستيراد) ثم تمرّ إلى المكتبة هنا داخل try-catch — فلا يتوقف البرنامج
    // عند اختلاف صيغ الملفات، ويُطبع السبب الحقيقي مع الـ stacktrace في الـ
    // Console بدل الاكتفاء برسالة تلف مبهمة.
    final Excel workbook;
    try {
      workbook = Excel.decodeBytes(bytes);
    } catch (error, stackTrace) {
      debugPrint(
        '[استيراد Excel] فشل تفكيك الملف كـ XLSX: $error\n$stackTrace',
      );
      // احتياطي: محتوى نصي بامتداد مُختلف (CSV أُعيدت تسميته مثلاً) يُقرأ
      // كـ CSV تلقائياً بذات الهيكلية بدل رفضه.
      final SheetData? fallback = _readAsCsvText(bytes, sourceName: sourceName);
      if (fallback != null) return fallback;
      throw AppException(
        AppErrorCode.excelImport,
        message: 'تعذّر قراءة الملف: لا يُفتح كملف Excel (.xlsx) سليم ولا '
            'يُقرأ كملف نصي (CSV/TSV). السبب الكامل مسجَّل في وحدة التحكم.',
        cause: error,
      );
    }

    // أوراق تلقائية: التحقق من وجود شيتات ثم أخذ أول ورقة متاحة بدلاً من
    // الالتزام باسم محدد قد لا يكون موجوداً في هذا الملف.
    if (workbook.tables.isEmpty) {
      throw const AppException(
        AppErrorCode.excelImport,
        message: 'ملف Excel لا يحتوي أي ورقة عمل.',
      );
    }

    final String resolved = sheetName != null &&
            workbook.tables.containsKey(sheetName)
        ? sheetName!
        : workbook.tables.keys.first;
    final Sheet sheet = workbook.tables[resolved]!;

    int formulaCells = 0;
    final List<List<String>> matrix = <List<String>>[];
    for (final List<Data?> row in sheet.rows) {
      final List<String> cells = <String>[];
      for (final Data? cell in row) {
        final CellValue? value = cell?.value;
        if (value is FormulaCellValue) {
          formulaCells++;
          cells.add('');
          continue;
        }
        cells.add(cellValueText(value));
      }
      matrix.add(cells);
    }

    final SheetData data = SheetData.fromMatrix(
      matrix,
      sourceName: sourceName,
      sheetName: resolved,
    );
    if (data.isEmpty) {
      throw AppException(
        AppErrorCode.excelImport,
        message: 'الورقة "$resolved" فارغة — لا عناوين أعمدة.',
      );
    }
    if (formulaCells > 0) {
      return SheetData(
        headers: data.headers,
        rows: data.rows,
        sourceName: data.sourceName,
        sheetName: data.sheetName,
        notes: <String>[
          ...data.notes,
          'يحتوي الملف $formulaCells خلية بصيغة غير محسوبة — تُستورد فارغة. '
              'انسخ القيم ولصقها كقيم ثابتة قبل الاستيراد.',
        ],
      );
    }
    return data;
  }

  /// أسماء أوراق الملف (لعرضها في الواجهة عند وجود أكثر من ورقة).
  static List<String> sheetNamesOf(Uint8List bytes) {
    try {
      return Excel.decodeBytes(bytes).tables.keys.toList(growable: false);
    } catch (error, stackTrace) {
      debugPrint('[استيراد Excel] تعذّر سرد أوراق الملف: $error\n$stackTrace');
      return const <String>[];
    }
  }

  /// محاولة قراءة البايتات كملف نصي (CSV/TSV) عند فشل التفكيك كـ XLSX.
  ///
  /// تغطّي الحالات الشائعة: ملف نصي بامتداد `.xlsx`، أو ملف Excel حُفظ فعلياً
  /// كـ CSV، أو أي محتوى نصي وصل إلى هذا القارئ. النص يُفكَّ بـ `utf8.decode`
  /// (مع BOM وUTF-16 عبر [CsvSheetReader.decodeText]) ثم تُفكَّك السطور بذات
  /// هيكلية القارئ النصي — وتُرفض الملفات الثنائية كي لا تُقرأ عشوائياً.
  static SheetData? _readAsCsvText(
    Uint8List bytes, {
    required String sourceName,
  }) {
    if (bytes.isEmpty) return null;

    final String text;
    try {
      text = CsvSheetReader.decodeText(bytes);
    } catch (error, stackTrace) {
      debugPrint('[استيراد Excel] تعذّرت قراءة النص: $error\n$stackTrace');
      return null;
    }
    if (!_looksLikeText(text)) return null;

    final String extension = SheetReaders.extensionOf(sourceName);
    try {
      final SheetData data = CsvSheetReader(
        forcedDelimiter: extension == 'tsv' ? '\t' : null,
      ).read(bytes, sourceName: sourceName);
      if (data.isEmpty) return null;
      debugPrint(
        '[استيراد Excel] الملف ليس XLSX صالحاً — رُوِّي تلقائياً كملف نصي '
        '(CSV/TSV): ${data.rowCount} صفاً و${data.headers.length} عموداً.',
      );
      return SheetData(
        headers: data.headers,
        rows: data.rows,
        sourceName: data.sourceName,
        sheetName: data.sheetName,
        notes: <String>[
          ...data.notes,
          'لم يُقرأ الملف كـ Excel (.xlsx)؛ رُوِّي تلقائياً كملف نصي '
              '(CSV/TSV).',
        ],
      );
    } catch (error, stackTrace) {
      debugPrint('[استيراد Excel] تعذّر تفكيك النص كـ CSV: $error\n$stackTrace');
      return null;
    }
  }

  /// هل يبدو [text] محتوى جدول نصياً حقيقياً لا بايتات ثنائية؟
  ///
  /// يرفض NUL ومحارف التحكم الضارة ومحارف الاستبدال الناتجة عن فك ترميز
  /// ملف ثنائي كـ UTF-8 — كي لا يُقبل ملف `.xlsx` تالف على أنه «جدول» من
  /// محارف عشوائية.
  static bool _looksLikeText(String text) {
    if (text.trim().isEmpty) return false;
    int control = 0;
    int replacement = 0;
    for (final int unit in text.runes) {
      if (unit == 0x00) return false;
      if (unit == 0xFFFD) {
        replacement++;
      } else if (unit < 0x20 && unit != 0x09 && unit != 0x0A && unit != 0x0D) {
        control++;
      }
    }
    final int total = text.length;
    // أكثر من ١٪ من المحارف مشوّهة/تحكم ⇒ محتوى ثنائي لا نص.
    return replacement * 100 <= total && control * 100 <= total;
  }

  /// ترجمة قيمة خلية واحدة إلى نص عربي مقروء.
  ///
  /// `CellValue` صنف مُغلَق (sealed) ⇒ التبديل هنا مُتحقَّق منه وقت الترجمة؛ أي
  /// نوع جديد في المكتبة يُظهر خطأ بناء لا خطأ صامتاً.
  static String cellValueText(CellValue? value) {
    if (value == null) return '';
    return switch (value) {
      TextCellValue(:final TextSpan value) => value.toString().trim(),
      IntCellValue(:final int value) => value.toString(),
      DoubleCellValue(:final double value) => formatNumber(value),
      BoolCellValue(:final bool value) => value ? 'نعم' : 'لا',
      DateCellValue(:final int year, :final int month, :final int day) =>
        '$year/${_two(month)}/${_two(day)}',
      DateTimeCellValue(
        :final int year,
        :final int month,
        :final int day,
        :final int hour,
        :final int minute,
      ) =>
        hour == 0 && minute == 0
            ? '$year/${_two(month)}/${_two(day)}'
            : '$year/${_two(month)}/${_two(day)} ${_two(hour)}:${_two(minute)}',
      TimeCellValue(
        :final int hour,
        :final int minute,
        :final int second,
      ) =>
        '${_two(hour)}:${_two(minute)}:${_two(second)}',
      // الصيغ لا تُقيَّم في الوضع غير المتصل ⇒ تُترك فارغة مع تنبيه للمستخدم.
      FormulaCellValue() => '',
    };
  }

  /// تنسيق رقم بلا كسر عشري زائد: `150000` لا `150000.0`.
  static String formatNumber(double value) {
    if (value.isNaN || value.isInfinite) return '';
    if (value == value.roundToDouble() && value.abs() < 1e15) {
      return value.toInt().toString();
    }
    final String text = value.toStringAsFixed(4);
    final String trimmed = text
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
    return trimmed.isEmpty ? '0' : trimmed;
  }

  static String _two(int value) => value < 10 ? '0$value' : '$value';
}
