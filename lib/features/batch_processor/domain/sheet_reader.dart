import 'dart:typed_data';

import '../../../core/errors/app_error_code.dart';
import '../../../core/errors/app_exception.dart';
import '../data/csv_sheet_reader.dart';
import '../data/xlsx_sheet_reader.dart';
import 'sheet_data.dart';

/// قارئ ملفات البيانات — واجهة واحدة لكل صيغة.
///
/// القراءة **محلية بالكامل**: البايتات تأتي من القرص (أو من المتصفح عند الويب)
/// ولا تُرفع إلى أي خادم.
abstract interface class SheetReader {
  /// قراءة الملف وتحويله إلى [SheetData].
  ///
  /// [headerRowIndex] فهرس صف العناوين (يبدأ من صفر) عندما يختاره المستخدم
  /// يدوياً — مثل ملف فيه عنوان أو أسطر تعريفية قبل العناوين. `null` يعني
  /// الاكتشاف التلقائي (أول صف غير فارغ).
  SheetData read(
    Uint8List bytes, {
    String sourceName = '',
    int? headerRowIndex,
  });
}

/// نتيجة قراءة ملف بيانات: الورقة المختارة + أسماء **كل** الأوراق في الملف.
///
/// تُستخدم في الواجهة لعرض منتقي ورقة العمل عندما يحتوي المصنّف على أكثر من
/// ورقة (`sheetNames.length > 1`)، فلا تُقرأ الورقة الأولى صامتةً.
class SheetReadResult {
  const SheetReadResult({
    required this.sheet,
    this.sheetNames = const <String>[],
  });

  final SheetData sheet;

  /// أسماء أوراق المصنّف (فارغة لملفات CSV/TSV النصية).
  final List<String> sheetNames;
}

/// اختيار القارئ المناسب حسب امتداد الملف.
abstract final class SheetReaders {
  /// **المصدر الوحيد للحقيقة**: كل ما يُقبل في منتقي الملفات وفي القارئ معاً.
  ///
  /// لا تُكرّر هذه القائمة في أي مكان آخر — الواجهة تقرأ منها مباشرةً
  /// (`BatchProcessorScreen.acceptedExtensions`)، والوصف العربي [supportedLabel]
  /// يُبنى منها حتى لا تتباعد القائمتان أبداً.
  static const List<String> supportedExtensions = <String>[
    'xlsx',
    'xlsm',
    'csv',
    'tsv',
    'txt',
  ];

  /// وصف عربي للامتدادات — يُعرض في نصوص الواجهة.
  static const String supportedLabel = 'xlsx, xlsm, csv, tsv, txt';

  /// امتداد الملف بحروف صغيرة، أو `''`.
  static String extensionOf(String fileName) {
    final String base = fileName.replaceAll('\\', '/').split('/').last;
    final int dot = base.lastIndexOf('.');
    if (dot <= 0 || dot == base.length - 1) return '';
    return base.substring(dot + 1).toLowerCase();
  }

  static bool isSupported(String fileName) =>
      supportedExtensions.contains(extensionOf(fileName));

  /// هل الملف مصنّف Excel حديث (`xlsx`/`xlsm`)؟ أي هل يحتمل أوراقاً متعددة؟
  static bool isWorkbook(String fileName) {
    final String extension = extensionOf(fileName);
    return extension == 'xlsx' || extension == 'xlsm';
  }

  /// القارئ المناسب للملف، أو رمي [AppException] برسالة عربية واضحة.
  ///
  /// [sheetName] يُمرَّر للقارئ لاختيار ورقة بعينها في ملفات Excel الحديثة.
  static SheetReader forFileName(String fileName, {String? sheetName}) {
    final String extension = extensionOf(fileName);
    switch (extension) {
      case 'xlsx':
      case 'xlsm':
        return XlsxSheetReader(sheetName: sheetName);
      case 'csv':
      case 'tsv':
      case 'txt':
        return CsvSheetReader(forcedDelimiter: extension == 'tsv' ? '\t' : null);
      case 'xls':
        // تنبيه لطيف بدل رسالة رفض عامة: الملف صالح، لكن Excel القديم غير مدعوم.
        throw const AppException(
          AppErrorCode.excelImport,
          message: 'ملف Excel قديم بصيغة .xls غير مدعوم. افتحه في Excel ثم '
              '«حفظ باسم» بصيغة .xlsx (أو صدّره CSV) وأعد المحاولة — التنسيق '
              'سيُحفظ كما هو.',
        );
      default:
        throw AppException(
          AppErrorCode.excelImport,
          message: 'صيغة الملف غير مدعومة (.$extension). '
              'الصيغ المقبولة: $supportedLabel.',
        );
    }
  }

  /// قراءة الملف مع سرد أسماء أوراقه (لعرض منتقي الأوراق في الواجهة).
  ///
  /// ملفات Excel تُفكّ **مرة واحدة** فتعود الأسماء والبيانات معاً؛ أما الملفات
  /// النصية فلا أوراق لها.
  static SheetReadResult readResult(
    Uint8List bytes, {
    required String fileName,
    String? sheetName,
    int? headerRowIndex,
  }) {
    if (isWorkbook(fileName)) {
      return XlsxSheetReader.readResult(
        bytes,
        sourceName: fileName,
        sheetName: sheetName,
        headerRowIndex: headerRowIndex,
      );
    }
    return SheetReadResult(
      sheet: forFileName(fileName, sheetName: sheetName)
          .read(bytes, sourceName: fileName, headerRowIndex: headerRowIndex),
    );
  }

  /// أسماء أوراق الملف (فارغة لغير ملفات Excel الحديثة).
  static List<String> sheetNamesOf(String fileName, Uint8List bytes) =>
      isWorkbook(fileName)
          ? XlsxSheetReader.sheetNamesOf(bytes)
          : const <String>[];

  /// قراءة ملف كامل بالخطوة الواحدة (اختيار القارئ ثم القراءة).
  static SheetData read(
    Uint8List bytes, {
    required String fileName,
    int? headerRowIndex,
  }) =>
      forFileName(fileName)
          .read(bytes, sourceName: fileName, headerRowIndex: headerRowIndex);
}
