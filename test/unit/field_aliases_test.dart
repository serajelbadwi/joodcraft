import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/constants/dynamic_fields.dart';
import 'package:joodcraft/features/batch_processor/domain/column_mapping.dart';
import 'package:joodcraft/features/batch_processor/domain/field_aliases.dart';

/// مفاتيح قالب المستخدم كما تُدرَج من المحرّر (عربية).
List<String> get _arabicKeys =>
    DynamicFields.certificate.map((DynamicField f) => f.key).toList();

void main() {
  group('مرادفات الحقول — قوالب المستخدم بمفاتيح عربية', () {
    test('عنوان «اسم الطالب» يرتبط بحقل {{اسم_المتدرب}}', () {
      final ColumnMapping mapping = ColumnMapping.autoDetect(
        columns: <int>[0],
        headers: <String>['اسم الطالب'],
        fieldKeys: _arabicKeys,
        aliases: FieldAliases.byToken,
      );
      expect(mapping.fieldFor(0), 'اسم_المتدرب');
    });

    test('يربط عناوين الملف العربية الشائعة كلها بالمفاتيح العربية', () {
      final List<String> headers = <String>[
        'اسم المشارك',
        'رقم التحقق',
        'اسم البرنامج',
        'تاريخ الإصدار',
        'اسم الجهة',
      ];
      final ColumnMapping mapping = ColumnMapping.autoDetect(
        columns: List<int>.generate(headers.length, (int i) => i),
        headers: headers,
        fieldKeys: _arabicKeys,
        aliases: FieldAliases.byToken,
      );

      expect(mapping.fieldFor(0), 'اسم_المتدرب');
      expect(mapping.fieldFor(1), 'رقم_الشهادة');
      expect(mapping.fieldFor(2), 'اسم_الدورة');
      expect(mapping.fieldFor(3), 'التاريخ');
      expect(mapping.fieldFor(4), 'الجهة_المانحة');
      expect(mapping.hasDuplicates, isFalse);
    });

    test('مفاتيح العقود العربية تعمل مثل مفاتيح الشهادات', () {
      final ColumnMapping mapping = ColumnMapping.autoDetect(
        columns: <int>[0, 1, 2],
        headers: <String>['اسم الموظف', 'اسم الشركة', 'الأجر'],
        fieldKeys: DynamicFields.contract
            .map((DynamicField f) => f.key)
            .toList(growable: false),
        aliases: FieldAliases.byToken,
      );

      expect(mapping.fieldFor(0), 'اسم_الطرف_الثاني');
      expect(mapping.fieldFor(1), 'اسم_المنشأة');
      expect(mapping.fieldFor(2), 'قيمة_العقد');
    });

    test('العنوان الحرفي للمفتاح لا يحتاج مرادفاً أصلاً', () {
      final ColumnMapping mapping = ColumnMapping.autoDetect(
        columns: <int>[0],
        headers: <String>['اسم المتدرب'],
        fieldKeys: _arabicKeys,
        aliases: FieldAliases.byToken,
      );
      expect(mapping.fieldFor(0), 'اسم_المتدرب');
    });

    test('لا يربط حقل {{رقم_الشهادة}} بعمود «رقم الشهادة» مرتين', () {
      // عمودان بعنوانين متطابقين: يُربط واحد فقط ويبقى الآخر للمستخدم.
      final ColumnMapping mapping = ColumnMapping.autoDetect(
        columns: <int>[0, 1],
        headers: <String>['رقم الشهادة', 'رقم الشهادة'],
        fieldKeys: _arabicKeys,
        aliases: FieldAliases.byToken,
      );
      expect(mapping.mappedCount, 1);
      expect(mapping.hasDuplicates, isFalse);
    });

    test('المرادفات لا تُكتب في الربط — المفتاح يبقى مفتاح القالب', () {
      final ColumnMapping mapping = ColumnMapping.autoDetect(
        columns: <int>[0],
        headers: <String>['اسم الطالب'],
        fieldKeys: _arabicKeys,
        aliases: FieldAliases.byToken,
      );
      // لو كُتب العنوان بدل المفتاح لما استبدل resolveFields شيئاً.
      expect(mapping.fieldFor(0), isNot('اسم الطالب'));
      expect(mapping.fieldFor(0), 'اسم_المتدرب');
    });

    test('كل مفتاح في مكتبة الحقول العربية له مرادف واحد على الأقل', () {
      for (final DynamicField field in DynamicFields.all) {
        expect(
          FieldAliases.aliasesFor(field.key),
          isNotEmpty,
          reason: 'الحقل «${field.key}» بلا مرادفات فيستحيل ربطه تلقائياً',
        );
      }
    });
  });

  group('تصنيف الحقول والعناوين', () {
    test('يميّز مفاتيح الاسم عن مفاتيح التاريخ/الرقم', () {
      for (final String token in <String>[
        'student_name',
        'party_1',
        'اسم_المتدرب',
        'اسم_الطرف_الثاني',
      ]) {
        expect(FieldAliases.isNameToken(token), isTrue, reason: token);
      }
      for (final String token in <String>[
        'date',
        'start_date',
        'verify_code',
        'التاريخ',
        'رقم_الشهادة',
      ]) {
        expect(FieldAliases.isTemporalOrCodeToken(token), isTrue, reason: token);
      }
    });

    test('يكتشف عناوين الأعمدة التي تشير إلى اسم', () {
      for (final String header in <String>[
        'الاسم',
        'اسم المتدرب',
        'اسم الطالب',
        'Full Name',
        'Employee Name',
      ]) {
        expect(FieldAliases.looksLikeNameHeader(header), isTrue, reason: header);
      }
      for (final String header in <String>[
        'التاريخ',
        'رقم الإشعار',
        'رقم الشهادة',
        'value',
      ]) {
        expect(FieldAliases.looksLikeNameHeader(header), isFalse, reason: header);
      }
    });

    test('يكتشف النصوص الثابتة التي تشبه اسم شخص', () {
      expect(
        FieldAliases.looksLikePersonName('محمد بن عبد الله الشمري'),
        isTrue,
      );
      expect(FieldAliases.looksLikePersonName('Sara Al-Otaibi'), isTrue);
      expect(FieldAliases.looksLikePersonName('{{اسم_المتدرب}}'), isFalse);
      expect(FieldAliases.looksLikePersonName('شهادة إتمام دورة'), isFalse);
      expect(FieldAliases.looksLikePersonName('1447/03/12'), isFalse);
      expect(
        FieldAliases.looksLikePersonName('محمد الشمري', fontSize: 9),
        isFalse,
      );
    });
  });
}
