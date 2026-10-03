import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/constants/dynamic_fields.dart';
import 'package:joodcraft/features/batch_processor/domain/column_mapping.dart';
import 'package:joodcraft/features/batch_processor/domain/sheet_data.dart';

List<String> get _certificateKeys =>
    DynamicFields.certificate.map((DynamicField f) => f.key).toList();

void main() {
  group('الكشف التلقائي', () {
    test('يربط عناوين عربية بحقول الشهادة بالضبط', () {
      final ColumnMapping mapping = ColumnMapping.autoDetect(
        columns: <int>[0, 1, 2],
        headers: <String>['اسم المتدرب', 'رقم الشهادة', 'التاريخ'],
        fieldKeys: _certificateKeys,
      );

      expect(mapping.fieldFor(0), 'اسم_المتدرب');
      expect(mapping.fieldFor(1), 'رقم_الشهادة');
      expect(mapping.fieldFor(2), 'التاريخ');
      expect(mapping.mappedCount, 3);
    });

    test('يتجاهل الهمزات والتشكيل والتاء المربوطة في المقارنة', () {
      expect(ColumnMapping.similarity('اسم المدرب', 'اسم_المدرب'), 1000);
      expect(
        ColumnMapping.similarity('مدة الدورة ', 'مدة_الدورة'),
        1000,
      );
      expect(ColumnMapping.similarity('الجهة المانحة', 'الجهة_المانحة'), 1000);
    });

    test('يطابق حقل الاسم الطويل مع عنوان مختصر', () {
      final int score =
          ColumnMapping.similarity('الاسم', 'اسم_المتدرب');
      expect(score, greaterThanOrEqualTo(ColumnMapping.autoDetectThreshold));
    });

    test('لا يربط عناوين لا علاقة لها بالحقول', () {
      final ColumnMapping mapping = ColumnMapping.autoDetect(
        columns: <int>[0, 1],
        headers: <String>['رقم الجوال', 'ملاحظات المدقق'],
        fieldKeys: _certificateKeys,
      );
      expect(mapping.isEmpty, isTrue);
    });

    test('لا يربط الحقل نفسه بعمودين', () {
      final ColumnMapping mapping = ColumnMapping.autoDetect(
        columns: <int>[0, 1],
        headers: <String>['اسم المتدرب', 'اسم المتدرب'],
        fieldKeys: _certificateKeys,
      );
      expect(mapping.mappedCount, 1);
      expect(mapping.hasDuplicates, isFalse);
    });

    test('يربط بحقول العقود أيضاً حسب القالب المستخدم', () {
      final ColumnMapping mapping = ColumnMapping.autoDetect(
        columns: <int>[0, 1],
        headers: <String>['اسم الطرف الأول', 'قيمة العقد'],
        fieldKeys:
            DynamicFields.contract.map((DynamicField f) => f.key).toList(),
      );
      expect(mapping.fieldFor(0), 'اسم_الطرف_الأول');
      expect(mapping.fieldFor(1), 'قيمة_العقد');
    });
  });

  group('إدارة الربط', () {
    test('withColumn يربط ويفكّ الربط', () {
      ColumnMapping mapping = ColumnMapping.empty
          .withColumn(0, 'اسم_المتدرب')
          .withColumn(1, 'رقم_الشهادة');
      expect(mapping.mappedCount, 2);

      mapping = mapping.withColumn(1, null);
      expect(mapping.mappedCount, 1);
      expect(mapping.columnFor('اسم_المتدرب'), 0);

      mapping = mapping.withoutColumns(<int>[0]);
      expect(mapping.isEmpty, isTrue);
    });

    test('يرصد الحقول المكرّرة لمنع الغموض', () {
      const ColumnMapping mapping = ColumnMapping(<int, String>{
        0: 'التاريخ',
        1: 'التاريخ',
      });
      expect(mapping.hasDuplicates, isTrue);
      expect(mapping.duplicateFields, <String>['التاريخ']);
    });

    test('fields مرتّبة بترتيب الأعمدة وبلا تكرار', () {
      const ColumnMapping mapping = ColumnMapping(<int, String>{
        3: 'التاريخ',
        0: 'اسم_المتدرب',
        2: 'رقم_الشهادة',
      });
      expect(mapping.fields, <String>['اسم_المتدرب', 'رقم_الشهادة', 'التاريخ']);
    });

    test('apply يبني بيانات الصف ويُبقي الخلايا الفارغة ظاهرة', () {
      const SheetData sheet = SheetData(
        headers: <String>['الاسم', 'الرقم'],
        rows: <List<String>>[
          <String>['أحمد', ''],
        ],
      );
      const ColumnMapping mapping = ColumnMapping(<int, String>{
        0: 'اسم_المتدرب',
        1: 'رقم_الشهادة',
      });

      final Map<String, String> data = mapping.apply(sheet.rowAt(0));
      expect(data['اسم_المتدرب'], 'أحمد');
      expect(data.containsKey('رقم_الشهادة'), isTrue);
      expect(data['رقم_الشهادة'], '');
    });

    test('دورة JSON كاملة بلا فقد', () {
      const ColumnMapping mapping = ColumnMapping(<int, String>{
        0: 'اسم_المتدرب',
        4: 'التاريخ',
      });
      final ColumnMapping back = ColumnMapping.fromJson(mapping.toJson());
      expect(back.byColumn, mapping.byColumn);
    });

    test('يتجاهل JSON تالفاً بلا رمي', () {
      expect(ColumnMapping.fromJson(null).isEmpty, isTrue);
      expect(ColumnMapping.fromJson('نص').isEmpty, isTrue);
      expect(
        ColumnMapping.fromJson(<String, dynamic>{'columns': 'x'}).isEmpty,
        isTrue,
      );
      expect(
        ColumnMapping.fromJson(<String, dynamic>{
          'columns': <String, dynamic>{'a': 'التاريخ', '1': ''},
        }).isEmpty,
        isTrue,
      );
    });
  });
}
