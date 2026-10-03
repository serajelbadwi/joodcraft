import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/errors/app_exception.dart';
import 'package:joodcraft/features/batch_processor/data/csv_sheet_reader.dart';
import 'package:joodcraft/features/batch_processor/domain/sheet_data.dart';
import 'package:joodcraft/features/batch_processor/domain/sheet_reader.dart';

Uint8List _utf8(String text) => Uint8List.fromList(utf8.encode(text));

Uint8List _utf8WithBom(String text) =>
    Uint8List.fromList(<int>[0xEF, 0xBB, 0xBF, ...utf8.encode(text)]);

Uint8List _utf16le(String text) {
  final List<int> out = <int>[0xFF, 0xFE];
  for (final int unit in text.codeUnits) {
    out..add(unit & 0xFF)..add((unit >> 8) & 0xFF);
  }
  return Uint8List.fromList(out);
}

void main() {
  const CsvSheetReader reader = CsvSheetReader();

  group('قراءة CSV', () {
    test('يقرأ ملفاً عربياً مفصولاً بفواصل مع BOM', () {
      final SheetData data = reader.read(
        _utf8WithBom('اسم المتدرب,رقم الشهادة\nأحمد الشمري,JC-1\nسارة,JC-2\n'),
        sourceName: 'students.csv',
      );

      expect(data.headers, <String>['اسم المتدرب', 'رقم الشهادة']);
      expect(data.rowCount, 2);
      expect(data.rowAt(0).cell('اسم المتدرب'), 'أحمد الشمري');
      expect(data.rowAt(1).cell('رقم الشهادة'), 'JC-2');
      expect(data.sourceName, 'students.csv');
    });

    test('يحترم علامات التنصيص والفواصل والأسطر الجديدة داخلها', () {
      final SheetData data = reader.read(
        _utf8('name,note\n"أحمد, الشمري","سطر أول\nسطر ثانٍ"\n'),
      );

      expect(data.rowCount, 1);
      expect(data.rowAt(0).cell('name'), 'أحمد, الشمري');
      expect(data.rowAt(0).cell('note'), 'سطر أول\nسطر ثانٍ');
    });

    test('يفكّ التنصيص المُهرَّب "" إلى علامة واحدة', () {
      final SheetData data = reader.read(
        _utf8('title,code\n"شهادة ""جود"" المعتمدة",X1\n'),
      );
      expect(data.rowAt(0).cell('title'), 'شهادة "جود" المعتمدة');
    });

    test('يكشف الفاصل نقطةً منقوطة تلقائياً', () {
      final SheetData data = reader.read(
        _utf8('اسم المتدرب;رقم الشهادة;التاريخ\nأحمد;JC-1;1447/03/12\n'),
      );
      expect(data.headers.length, 3);
      expect(data.rowAt(0).cell('التاريخ'), '1447/03/12');
    });

    test('يقبل الملفات مفصولة بـ Tab (TSV)', () {
      final SheetData data = SheetSamples.tsv();
      expect(data.headers.length, 3);
      expect(data.rowAt(0).cells.last, 'ممتاز');
    });

    test('يفكّ ترميز UTF-16LE (تصدير Excel «Unicode text»)', () {
      final SheetData data = reader.read(
        _utf16le('اسم المتدرب,رقم الشهادة\nأحمد,JC-9\n'),
      );
      expect(data.headers, <String>['اسم المتدرب', 'رقم الشهادة']);
      expect(data.rowAt(0).cell('رقم الشهادة'), 'JC-9');
    });

    test('يرفع استثناء عربياً واضحاً على ملف فارغ أو غير مقروء', () {
      expect(() => reader.read(Uint8List(0)), throwsA(isA<AppException>()));
      expect(
        () => reader.read(_utf8('   \n  \n')),
        throwsA(isA<AppException>()),
      );
    });

    test('يستخدم قارئاً مناسباً حسب الامتداد ويرفض غير المدعوم', () {
      expect(SheetReaders.extensionOf(r'C:\ملفات\data.XLSX'), 'xlsx');
      expect(SheetReaders.isSupported('a.csv'), isTrue);
      expect(SheetReaders.isSupported('a.pdf'), isFalse);
      expect(
        () => SheetReaders.forFileName('a.pdf'),
        throwsA(isA<AppException>()),
      );
      expect(
        SheetReaders.forFileName('a.csv'),
        isA<CsvSheetReader>(),
      );
    });

    test('يرفض .xls برسالة لطيفة تنصح بالتحويل إلى .xlsx', () {
      expect(SheetReaders.isSupported('قديم.xls'), isFalse);
      expect(
        () => SheetReaders.forFileName('قديم.xls'),
        throwsA(
          isA<AppException>()
              .having((AppException e) => e.message, 'message',
                  contains('Excel قديم'))
              .having((AppException e) => e.message, 'message',
                  contains('.xlsx')),
        ),
      );
    });

    test('الامتدادات والوصف مصدر واحد متطابقان', () {
      expect(SheetReaders.supportedExtensions, contains('txt'));
      for (final String extension in SheetReaders.supportedExtensions) {
        expect(SheetReaders.supportedLabel, contains(extension),
            reason: 'الوصف يجب أن يذكر كل امتداد مدعوم');
      }
    });
  });

  group('تطبيع الورقة', () {
    test('يسمّي الأعمدة الفارغة ويجعل العناوين فريدة', () {
      final SheetData data = reader.read(
        _utf8('الاسم,,الاسم\nأحمد,1,2\n'),
      );
      expect(data.headers, <String>['الاسم', 'عمود 2', 'الاسم (1)']);
      expect(data.notes, isNotEmpty);
    });

    test('يسقط الصفوف الفارغة ويطبّع عرض الصفوف', () {
      final SheetData data = reader.read(
        _utf8('a,b,c\n1,2\n,\n\n3,4,5\n'),
      );
      expect(data.rowCount, 2);
      expect(data.rowAt(0).cells, <String>['1', '2', '']);
      expect(data.rowAt(1).cells, <String>['3', '4', '5']);
      expect(data.notes.join(' '), contains('فارغة'));
    });

    test('يحسب ترقيم الصف كما يراه المستخدم في Excel', () {
      final SheetData data = reader.read(_utf8('a\n1\n2\n'));
      expect(data.rowAt(0).displayNumber, 2);
      expect(data.rowAt(1).displayNumber, 3);
    });

    test('يبدأ العناوين من صفٍ يختاره المستخدم بعد الأسطر التعريفية', () {
      final SheetData data = reader.read(
        _utf8('شهادات دورة ٢٠٢٦\nتقرير المتدربين\nالاسم,الرقم\nأحمد,JC-1\nسارة,JC-2\n'),
        headerRowIndex: 2,
      );

      expect(data.headers, <String>['الاسم', 'الرقم']);
      expect(data.rowCount, 2);
      expect(data.rowAt(0).cell('الاسم'), 'أحمد');
      expect(data.headerRowIndex, 2);
      expect(data.notes.join(' '), contains('اختيارك'));
      // الصف الأول من البيانات هو الصف الرابع في Excel (بعد العناوين في الثالث).
      expect(data.rowAt(0).displayNumber, 4);
      // الصفوف الأولية محفوظة للمنتقي كي يستطيع المستخدم التبديل.
      expect(data.rowSamples.first.first, 'شهادات دورة ٢٠٢٦');
    });

    test('الاكتشاف التلقائي يبقى افتراضياً عندما لا يُختار صف', () {
      final SheetData data = reader.read(
        _utf8('الاسم,الرقم\nأحمد,JC-1\n'),
      );
      expect(data.headerRowIndex, 0);
      expect(data.rowAt(0).displayNumber, 2);
    });

    test('الكشف الذكي يتجاهل أسطر العنوان أحادية الخلية ويجد العناوين', () {
      final SheetData data = reader.read(
        _utf8('شهادات دورة ٢٠٢٦\nتقرير المتدربين\n'
            'الاسم,الرقم\nأحمد,JC-1\n'),
      );

      expect(data.headerRowIndex, 2);
      expect(data.headers, <String>['الاسم', 'الرقم']);
      expect(data.rowCount, 1);
      expect(data.rowAt(0).cell('الاسم'), 'أحمد');
      expect(data.notes.join(' '), contains('تمهيدية'));
    });

    test('الكشف الذكي يسقط الأسطر الفارغة في الأعلى', () {
      final SheetData data = reader.read(
        _utf8('\n\nالاسم,الرقم\nأحمد,JC-1\n'),
      );
      expect(data.headerRowIndex, 2);
      expect(data.headers, <String>['الاسم', 'الرقم']);
    });

    test('ملف بعمود واحد يبقى على أول صف غير فارغ', () {
      // لا صف متعدد الأعمدة ⇒ لا إشارة للكشف الذكي، فيبقى السلوك الآمن.
      final SheetData data = reader.read(_utf8('الاسم\nأحمد\n'));
      expect(data.headerRowIndex, 0);
      expect(data.headers, <String>['الاسم']);
      expect(data.rowCount, 1);
    });

    test('يرصد الأعمدة التي تحمل بيانات فعلية', () {
      final SheetData data = reader.read(_utf8('a,b,c\n1,,3\n'));
      expect(data.dataColumns, <int>[0, 2]);
      expect(data.columnCount, 3);
    });

    test('toMap و blankColumns يعطيان صورة كاملة عن الصف', () {
      final SheetData data = reader.read(_utf8('a,b,c\n1,,3\n'));
      final SheetRow row = data.rowAt(0);
      expect(row.filledCount, 2);
      expect(row.isBlank, isFalse);
      expect(row.blankColumns, <int>[1]);
      expect(row.toMap(), <String, String>{'a': '1', 'b': '', 'c': '3'});
      expect(row.toMap(skipEmpty: true), <String, String>{'a': '1', 'c': '3'});
      expect(row.cell('مفقود'), '');
    });
  });
}

/// عيّنات جاهزة لملفات الاختبار.
abstract final class SheetSamples {
  static SheetData tsv() => const CsvSheetReader(forcedDelimiter: '\t').read(
        _utf8('اسم المتدرب\tرقم الشهادة\tالتقدير\nأحمد\tJC-1\tممتاز\n'),
      );
}
