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
  SheetData read(Uint8List bytes, {String sourceName = ''});
}

/// اختيار القارئ المناسب حسب امتداد الملف.
abstract final class SheetReaders {
  /// الامتدادات المدعومة (بدون النقطة).
  static const List<String> supportedExtensions = <String>[
    'xlsx',
    'xlsm',
    'csv',
    'tsv',
    'txt',
  ];

  /// وصف عربي للامتدادات — يُعرض في نصوص الواجهة.
  static const String supportedLabel = 'xlsx, xlsm, csv, tsv';

  /// امتداد الملف بحروف صغيرة، أو `''`.
  static String extensionOf(String fileName) {
    final String base = fileName.replaceAll('\\', '/').split('/').last;
    final int dot = base.lastIndexOf('.');
    if (dot <= 0 || dot == base.length - 1) return '';
    return base.substring(dot + 1).toLowerCase();
  }

  static bool isSupported(String fileName) =>
      supportedExtensions.contains(extensionOf(fileName));

  /// القارئ المناسب للملف، أو رمي [AppException] برسالة عربية واضحة.
  static SheetReader forFileName(String fileName) {
    final String extension = extensionOf(fileName);
    switch (extension) {
      case 'xlsx':
      case 'xlsm':
        return const XlsxSheetReader();
      case 'csv':
      case 'tsv':
      case 'txt':
        return CsvSheetReader(forcedDelimiter: extension == 'tsv' ? '\t' : null);
      default:
        throw AppException(
          AppErrorCode.excelImport,
          message: 'صيغة الملف غير مدعومة (.$extension). '
              'الصيغ المقبولة: $supportedLabel.',
        );
    }
  }

  /// قراءة ملف كامل بالخطوة الواحدة (اختيار القارئ ثم القراءة).
  static SheetData read(
    Uint8List bytes, {
    required String fileName,
  }) =>
      forFileName(fileName).read(bytes, sourceName: fileName);
}
