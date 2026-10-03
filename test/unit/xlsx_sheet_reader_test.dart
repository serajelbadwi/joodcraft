import 'dart:convert';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/errors/app_exception.dart';
import 'package:joodcraft/features/batch_processor/data/xlsx_sheet_reader.dart';
import 'package:joodcraft/features/batch_processor/domain/sheet_data.dart';
import 'package:joodcraft/features/batch_processor/domain/sheet_reader.dart';

/// يبني ملف xlsx حقيقياً في الذاكرة ثم يقرأه بالقارئ المحلي.
Uint8List buildWorkbook(List<List<CellValue?>> rows, {String sheet = 'Sheet1'}) {
  final Excel excel = Excel.createExcel();
  final Sheet target = excel[sheet];
  for (final List<CellValue?> row in rows) {
    target.appendRow(row);
  }
  final List<int>? encoded = excel.encode();
  expect(encoded, isNotNull);
  return Uint8List.fromList(encoded!);
}

void main() {
  const XlsxSheetReader reader = XlsxSheetReader();

  test('يقرأ ورقة Excel ويحوّل الأنواع إلى نص عربي مقروء', () {
    final Uint8List bytes = buildWorkbook(<List<CellValue?>>[
      <CellValue?>[
        TextCellValue('اسم المتدرب'),
        TextCellValue('قيمة العقد'),
        TextCellValue('تاريخ البداية'),
        TextCellValue('مستوى الأداء'),
      ],
      <CellValue?>[
        TextCellValue('أحمد الشمري'),
        IntCellValue(150000),
        TextCellValue('1447/03/12'),
        BoolCellValue(true),
      ],
      <CellValue?>[
        TextCellValue('سارة'),
        DoubleCellValue(1250.5),
        TextCellValue('2026/01/05'),
        BoolCellValue(false),
      ],
    ]);

    final SheetData data = reader.read(bytes, sourceName: 'students.xlsx');

    expect(data.headers.length, 4);
    expect(data.rowCount, 2);
    expect(data.sheetName, 'Sheet1');
    expect(data.sourceName, 'students.xlsx');

    // الأرقام بلا كسر عشري زائد، والتواريخ بصيغة عربية مفهومة.
    expect(data.rowAt(0).cell('قيمة العقد'), '150000');
    expect(data.rowAt(0).cell('تاريخ البداية'), '1447/03/12');
    expect(data.rowAt(0).cell('مستوى الأداء'), 'نعم');
    expect(data.rowAt(1).cell('قيمة العقد'), '1250.5');
    expect(data.rowAt(1).cell('تاريخ البداية'), '2026/01/05');
    expect(data.rowAt(1).cell('مستوى الأداء'), 'لا');
  });

  test('الصيغ غير المحسوبة تُستورد فارغة مع تنبيه للمستخدم', () {
    final Uint8List bytes = buildWorkbook(<List<CellValue?>>[
      <CellValue?>[TextCellValue('الاسم'), TextCellValue('المجموع')],
      <CellValue?>[TextCellValue('أحمد'), FormulaCellValue('=SUM(A1:A1)')],
    ]);

    final SheetData data = reader.read(bytes);
    expect(data.rowAt(0).cell('المجموع'), '');
    expect(data.notes.join(' '), contains('صيغة غير محسوبة'));
  });

  test('كل أنواع الخلايا تُترجم إلى نص عربي مقروء', () {
    expect(XlsxSheetReader.cellValueText(null), '');
    expect(XlsxSheetReader.cellValueText(TextCellValue('أحمد')), 'أحمد');
    expect(XlsxSheetReader.cellValueText(IntCellValue(5)), '5');
    expect(XlsxSheetReader.cellValueText(DoubleCellValue(1250.5)), '1250.5');
    expect(XlsxSheetReader.cellValueText(BoolCellValue(true)), 'نعم');
    expect(XlsxSheetReader.cellValueText(BoolCellValue(false)), 'لا');
    expect(
      XlsxSheetReader.cellValueText(
        DateCellValue(year: 1447, month: 3, day: 12),
      ),
      '1447/03/12',
    );
    expect(
      XlsxSheetReader.cellValueText(
        DateTimeCellValue(
          year: 1447,
          month: 3,
          day: 12,
          hour: 0,
          minute: 0,
        ),
      ),
      '1447/03/12',
    );
    expect(
      XlsxSheetReader.cellValueText(
        DateTimeCellValue(
          year: 1447,
          month: 3,
          day: 12,
          hour: 9,
          minute: 30,
        ),
      ),
      '1447/03/12 09:30',
    );
    expect(
      XlsxSheetReader.cellValueText(
        const TimeCellValue(hour: 9, minute: 30, second: 5),
      ),
      '09:30:05',
    );
    expect(XlsxSheetReader.cellValueText(FormulaCellValue('=A1')), '');
  });

  test('الأرقام العشرية تُنسَّق بلا أصفار زائدة', () {
    expect(XlsxSheetReader.formatNumber(150000), '150000');
    expect(XlsxSheetReader.formatNumber(1250.5), '1250.5');
    expect(XlsxSheetReader.formatNumber(0.25), '0.25');
    expect(XlsxSheetReader.formatNumber(12.5000), '12.5');
    expect(XlsxSheetReader.formatNumber(double.nan), '');
  });

  test('يرفع استثناء عربياً واضحاً على ملف تالف أو فارغ', () {
    expect(() => reader.read(Uint8List(0)), throwsA(isA<AppException>()));
    expect(
      () => reader.read(Uint8List.fromList(<int>[1, 2, 3, 4, 5, 6, 7, 8])),
      throwsA(isA<AppException>()),
    );
  });

  test('يرفض ملفاً ثنائياً تالفناً ولا يقبله كـ CSV احتياطياً', () {
    // محتوى ثنائي يحوي NUL — لا يُقرأ كنص مهما كان الامتداد.
    expect(
      () => reader.read(
        Uint8List.fromList(<int>[0x50, 0x4B, 0x00, 0x01, 0x02, 0x00]),
        sourceName: 'broken.xlsx',
      ),
      throwsA(isA<AppException>()),
    );
  });

  test('يقرأ الملف النصي كـ CSV تلقائياً إذا فشل تفكيكه كـ XLSX', () {
    // ملف CSV أُعيدت تسميته إلى .xlsx — يُقرأ دون أن يفشل الاستيراد.
    final Uint8List bytes = Uint8List.fromList(
      utf8.encode('الاسم,قيمة العقد\nأحمد الشمري,150000\nسارة,1250.5\n'),
    );

    final SheetData data = reader.read(bytes, sourceName: 'students.xlsx');

    expect(data.headers, <String>['الاسم', 'قيمة العقد']);
    expect(data.rowCount, 2);
    expect(data.rowAt(0).cell('قيمة العقد'), '150000');
    expect(data.rowAt(1).cell('الاسم'), 'سارة');
    expect(data.notes.join(' '), contains('رُوِّي تلقائياً'));
    expect(data.sourceName, 'students.xlsx');
  });

  test('يستطيع سرد أوراق العمل واختيار ورقة بعينها', () {
    final Excel excel = Excel.createExcel();
    excel['البيانات'].appendRow(<CellValue?>[
      TextCellValue('اسم المتدرب'),
    ]);
    excel['البيانات'].appendRow(<CellValue?>[TextCellValue('سالم')]);
    final Uint8List bytes = Uint8List.fromList(excel.encode()!);

    final List<String> sheets = XlsxSheetReader.sheetNamesOf(bytes);
    expect(sheets, contains('البيانات'));

    final SheetData data =
        const XlsxSheetReader(sheetName: 'البيانات').read(bytes);
    expect(data.sheetName, 'البيانات');
    expect(data.rowAt(0).cell('اسم المتدرب'), 'سالم');
  });

  test('الكشف الذكي يتجاهل أسطر العنوان والعنوان الممتد ثم يجد العناوين', () {
    final Uint8List bytes = buildWorkbook(<List<CellValue?>>[
      // عنوان الملف — خلية واحدة (كما تُقرأ الخلية المدمجة: ممتلئة ثم فارغة).
      <CellValue?>[TextCellValue('كشف المتدربين لحفل التخرج ٢٠٢٦')],
      <CellValue?>[TextCellValue('تاريخ الإصدار: 1447/03/12')],
      <CellValue?>[TextCellValue('الاسم'), TextCellValue('الرقم')],
      <CellValue?>[TextCellValue('أحمد'), TextCellValue('JC-1')],
      <CellValue?>[TextCellValue('سارة'), TextCellValue('JC-2')],
    ]);

    final SheetData data = reader.read(bytes);

    expect(data.headerRowIndex, 2);
    expect(data.headers, <String>['الاسم', 'الرقم']);
    expect(data.rowCount, 2);
    expect(data.rowAt(0).cell('الاسم'), 'أحمد');
    expect(data.notes.join(' '), contains('تمهيدية'));
  });

  test('يقرأ العناوين من صف محدَّد بعد أسطر تعريفية', () {
    final Uint8List bytes = buildWorkbook(<List<CellValue?>>[
      <CellValue?>[TextCellValue('كشف المتدربين لحفل التخرج ٢٠٢٦')],
      <CellValue?>[TextCellValue('تاريخ الإصدار: 1447/03/12')],
      <CellValue?>[TextCellValue('الاسم'), TextCellValue('الرقم')],
      <CellValue?>[TextCellValue('أحمد'), TextCellValue('JC-1')],
      <CellValue?>[TextCellValue('سارة'), TextCellValue('JC-2')],
    ]);

    final SheetData data = reader.read(bytes, headerRowIndex: 2);

    expect(data.headers, <String>['الاسم', 'الرقم']);
    expect(data.rowCount, 2);
    expect(data.rowAt(0).cell('الاسم'), 'أحمد');
    expect(data.headerRowIndex, 2);
    expect(data.rowAt(0).displayNumber, 4);
    expect(data.notes.join(' '), contains('اختيارك'));
  });

  test('قراءة واحدة تُعيد الورقة المطلوبة وأسماء كل الأوراق معاً', () {
    final Excel excel = Excel.createExcel();
    final String first = excel.getDefaultSheet() ?? 'Sheet1';
    excel[first].appendRow(<CellValue?>[TextCellValue('الاسم')]);
    excel[first].appendRow(<CellValue?>[TextCellValue('أحمد')]);
    excel['الثانية'].appendRow(<CellValue?>[TextCellValue('الاسم')]);
    excel['الثانية'].appendRow(<CellValue?>[TextCellValue('سارة')]);
    final Uint8List bytes = Uint8List.fromList(excel.encode()!);

    final SheetReadResult named = SheetReaders.readResult(
      bytes,
      fileName: 'multi.xlsx',
      sheetName: 'الثانية',
    );
    expect(named.sheetNames, containsAll(<String>[first, 'الثانية']));
    expect(named.sheet.sheetName, 'الثانية');
    expect(named.sheet.rowAt(0).cell('الاسم'), 'سارة');

    // بلا اسم ورقة ⇒ أول ورقة في المصنّف.
    final SheetReadResult defaultSheet =
        SheetReaders.readResult(bytes, fileName: 'multi.xlsx');
    expect(defaultSheet.sheet.rowAt(0).cell('الاسم'), 'أحمد');
    expect(defaultSheet.sheetNames.length, 2);
  });
}
