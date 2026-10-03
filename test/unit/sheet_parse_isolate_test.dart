import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/features/batch_processor/presentation/providers/batch_processor_controller.dart';

/// مصنّف Excel صغير في الذاكرة — يُستخدم لإثبات مسار الـ isolate.
Uint8List _workbook(int rows) {
  final Excel excel = Excel.createExcel();
  final String sheet = excel.getDefaultSheet() ?? 'Sheet1';
  excel[sheet].appendRow(<CellValue?>[
    TextCellValue('اسم المتدرب'),
    TextCellValue('رقم الشهادة'),
  ]);
  for (int i = 0; i < rows; i++) {
    excel[sheet].appendRow(<CellValue?>[
      TextCellValue('متدرب $i'),
      TextCellValue('JC-$i'),
    ]);
  }
  return Uint8List.fromList(excel.encode()!);
}

/// مصنّف فيه سطران تعريفيان قبل صف العناوين الحقيقي.
Uint8List _titledWorkbook() {
  final Excel excel = Excel.createExcel();
  final String sheet = excel.getDefaultSheet() ?? 'Sheet1';
  excel[sheet].appendRow(<CellValue?>[TextCellValue('كشف المتدربين')]);
  excel[sheet].appendRow(<CellValue?>[TextCellValue('تاريخ الإصدار')]);
  excel[sheet].appendRow(<CellValue?>[
    TextCellValue('اسم المتدرب'),
    TextCellValue('رقم الشهادة'),
  ]);
  excel[sheet].appendRow(<CellValue?>[
    TextCellValue('أحمد'),
    TextCellValue('JC-1'),
  ]);
  return Uint8List.fromList(excel.encode()!);
}

void main() {
  // ملاحظة: هذا اختبار عادي (لا widget) لأن اختبارات الودجات تعمل بمؤقّت مزيف
  // لا يقود isolate حقيقياً. هنا نختبر فعلاً نقل التفكيك إلى isolate خلفي.
  test('يفكّ Excel في isolate خلفي ويُرجع الورقة وأسماء الأوراق', () async {
    final BatchProcessorController controller =
        BatchProcessorController(isolateByteThreshold: 0);
    addTearDown(controller.dispose);

    await controller.loadBytes(fileName: 'big.xlsx', bytes: _workbook(500));

    expect(controller.errorAr, isNull);
    expect(controller.loadingFile, isFalse);
    expect(controller.sheet.rowCount, 500);
    expect(controller.sheet.rowAt(0).cell('اسم المتدرب'), 'متدرب 0');
    expect(controller.sheet.rowAt(499).cell('رقم الشهادة'), 'JC-499');
    expect(controller.sheetNames, isNotEmpty);
  });

  test('نقل رسالة الخطأ العربية من الـ isolate عند ملف تالف', () async {
    final BatchProcessorController controller =
        BatchProcessorController(isolateByteThreshold: 0);
    addTearDown(controller.dispose);

    await controller.loadBytes(
      fileName: 'broken.xlsx',
      bytes: Uint8List.fromList(<int>[0x00, 0x01, 0x02, 0x00, 0x03]),
    );

    expect(controller.errorAr, isNotNull);
    expect(controller.sheet.isEmpty, isTrue);
  });

  test('يختار صف العناوين ويمرّر الاختيار عبر الـ isolate', () async {
    final BatchProcessorController controller =
        BatchProcessorController(isolateByteThreshold: 0);
    addTearDown(controller.dispose);

    await controller.loadBytes(fileName: 'titled.xlsx', bytes: _titledWorkbook());
    // الكشف الذكي يتخطى سطري العنوان أحاديّي الخلية ويجد صف العناوين الحقيقي.
    expect(controller.effectiveHeaderRowIndex, 2);
    expect(controller.sheet.headers, <String>['اسم المتدرب', 'رقم الشهادة']);
    expect(controller.sheet.rowAt(0).cell('اسم المتدرب'), 'أحمد');
    expect(controller.canChooseHeaderRow, isTrue);

    // يمكن للمستخدم فرض الصف الأول يدوياً ثم العودة إلى «تلقائي».
    await controller.setHeaderRowIndex(0);
    expect(controller.headerRowIndex, 0);
    expect(controller.sheet.headers.first, 'كشف المتدربين');

    await controller.setHeaderRowIndex(null);
    expect(controller.headerRowIndex, isNull);
    expect(controller.effectiveHeaderRowIndex, 2);
    expect(controller.errorAr, isNull);
  });
}
