import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/constants/app_assets.dart';
import 'package:joodcraft/core/gender/arabic_gender.dart';
import 'package:joodcraft/core/models/template_document.dart';
import 'package:joodcraft/core/models/template_element.dart';
import 'package:joodcraft/core/theme/app_theme.dart';
import 'package:joodcraft/features/batch_processor/presentation/providers/batch_processor_controller.dart';
import 'package:joodcraft/features/batch_processor/presentation/screens/batch_processor_screen.dart';

/// ملف CSV فيه اسم مذكّر ثم أنثوي ثم مذكّر — لاختبار الكشف التلقائي للجنس.
final Uint8List _csv = Uint8List.fromList(
  utf8.encode(
    'اسم المتدرب,رقم الشهادة\n'
    'أحمد الشمري,JC-0001\n'
    'سارة العتيبي,JC-0002\n'
    'خالد القحطاني,JC-0003\n',
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TemplateDocument certificateTemplate;
  late BatchProcessorController controller;

  setUpAll(() async {
    certificateTemplate = TemplateDocument.fromJsonString(
      await rootBundle.loadString(AppAssets.sampleCertificateTemplate),
    );
  });

  setUp(() {
    controller = BatchProcessorController(parseInIsolate: false);
    controller.useDocument(certificateTemplate);
  });

  tearDown(() => controller.dispose());

  Future<void> pumpScreen(WidgetTester tester, {Size size = const Size(1400, 1600)}) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(body: BatchProcessorScreen(controller: controller)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('جدول المراجعة المسبقة للجنس', () {
    testWidgets('يعرض الصفوف بأسمائها وجنسها المكتشَف', (WidgetTester tester) async {
      await pumpScreen(tester);
      await controller.loadBytes(fileName: 'students.csv', bytes: _csv);
      await tester.pumpAndSettle();

      expect(controller.hasGenderReview, isTrue);

      final List<GenderReviewRow> rows = controller.genderReviewRows;
      expect(rows, hasLength(3));
      expect(rows[0].rowNumber, 2);
      expect(rows[0].name, 'أحمد الشمري');
      expect(rows[0].effective, Gender.male);
      expect(rows[1].name, 'سارة العتيبي');
      expect(rows[1].effective, Gender.female);
      expect(rows[2].effective, Gender.male);
      // بلا تصحيحات يدوية في البداية.
      expect(controller.genderOverrideCount, 0);
      expect(rows.every((GenderReviewRow r) => !r.overridden), isTrue);

      // الجدول ظاهر برؤوس أعمدته وصفوفه.
      expect(find.text('مراجعة الجنس (تذكير/تأنيث)'), findsOneWidget);
      for (final int rowNumber in <int>[2, 3, 4]) {
        expect(
          find.byKey(ValueKey<String>('bp-gender-row-$rowNumber')),
          findsOneWidget,
          reason: 'صف $rowNumber',
        );
        expect(
          find.byKey(ValueKey<String>('bp-gender-select-$rowNumber')),
          findsOneWidget,
          reason: 'قائمة صف $rowNumber',
        );
      }
      // الأسماء ظاهرة في الجدول.
      expect(find.text('سارة العتيبي'), findsWidgets);
    });

    testWidgets('التصحيح اليدوي يتقدّم على الكشف ويمكن إلغاؤه', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester);
      await controller.loadBytes(fileName: 'students.csv', bytes: _csv);
      await tester.pumpAndSettle();

      // الصف الثاني (أحمد) مذكّر تلقائياً ← نصحّحه يدوياً إلى أنثى.
      controller.setRowGender(2, Gender.female);
      await tester.pumpAndSettle();

      final GenderReviewRow corrected = controller.genderReviewRows.first;
      expect(corrected.detected, Gender.male);
      expect(corrected.effective, Gender.female);
      expect(corrected.overridden, isTrue);
      expect(controller.genderOverrideCount, 1);

      // زرّ إلغاء التصحيحات يظهر بعد وجود تصحيح ويعمل.
      final Finder clear =
          find.byKey(const ValueKey<String>('bp-gender-clear'));
      expect(clear, findsOneWidget);
      await tester.ensureVisible(clear);
      await tester.pumpAndSettle();
      await tester.tap(clear);
      await tester.pumpAndSettle();

      expect(controller.genderOverrideCount, 0);
      expect(controller.genderReviewRows.first.effective, Gender.male);
    });

    test('تصحيحات الجنس تُصفَّر عند تغيير الملف', () async {
      await controller.loadBytes(fileName: 'students.csv', bytes: _csv);
      controller.setRowGender(2, Gender.female);
      expect(controller.genderOverrideCount, 1);

      controller.clearFile();
      expect(controller.genderOverrideCount, 0);
      expect(controller.genderReviewRows, isEmpty);
    });

    test('لا يعرض الجدول حين لا اسم ولا صيغة شرطية', () {
      controller.useDocument(
        const TemplateDocument(
          elements: <TemplateElement>[],
          sampleData: <String, String>{'الجنس': 'أنثى'},
        ),
      );
      expect(controller.hasGenderReview, isFalse);
    });

    testWidgets('تعديل الاسم مباشرة يُخزَّن ويُعيد كشف الجنس تلقائياً', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester);
      await controller.loadBytes(fileName: 'students.csv', bytes: _csv);
      await tester.pumpAndSettle();

      // بلا تصحيحات ← لا مؤشّر قلم.
      expect(find.byIcon(Icons.edit_rounded), findsNothing);

      // الصف 3 «سارة العتيبي» (أنثى) ← نفتح التعديل ونكتب اسماً مذكّراً.
      final Finder cell =
          find.byKey(const ValueKey<String>('bp-gender-name-3'));
      expect(cell, findsOneWidget);
      await tester.ensureVisible(cell);
      await tester.pumpAndSettle();
      await tester.tap(cell);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('bp-gender-name-dialog')),
        findsOneWidget,
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('bp-gender-name-field-3')),
        'خالد القحطاني',
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('bp-gender-name-save-3')),
      );
      await tester.pumpAndSettle();

      expect(controller.nameOverrideCount, 1);
      expect(controller.nameOverrides[3], 'خالد القحطاني');

      final GenderReviewRow row = controller.genderReviewRows[1];
      expect(row.name, 'خالد القحطاني');
      expect(row.nameOverridden, isTrue);
      expect(row.genderOverridden, isFalse);
      // أُعيد الكشف من الاسم الجديد بدل الاسم الأنثوي الأصلي.
      expect(row.detected, Gender.male);
      expect(row.effective, Gender.male);
      // الاسم الجديد ظاهر في الجدول، ومؤشّر التصحيح مرسوم.
      expect(find.text('خالد القحطاني'), findsWidgets);
      expect(find.byIcon(Icons.edit_rounded), findsWidgets);
    });

    test('تصحيح الجنس اليدوي يتقدّم على إعادة الكشف بعد تعديل الاسم', () async {
      await controller.loadBytes(fileName: 'students.csv', bytes: _csv);

      // المستخدم أكّد الجنس يدوياً ثم عدّل الاسم إلى اسم مذكّر.
      controller.setRowGender(3, Gender.female);
      controller.setRowName(3, 'خالد القحطاني');

      final GenderReviewRow row = controller.genderReviewRows[1];
      expect(row.detected, Gender.male, reason: 'الكشف التلقائي يتبع الاسم الجديد');
      expect(row.effective, Gender.female, reason: 'التصحيح اليدوي هو الحاكم');
      expect(row.name, 'خالد القحطاني');
      expect(row.nameOverridden, isTrue);
      expect(row.genderOverridden, isTrue);
      expect(row.overridden, isTrue);
    });

    test('الاسم الفارغ يُلغي تصحيح الاسم ويعود لاسم الملف', () async {
      await controller.loadBytes(fileName: 'students.csv', bytes: _csv);
      controller.setRowName(2, 'نورة');
      expect(controller.nameOverrideCount, 1);

      controller.setRowName(2, '   ');
      expect(controller.nameOverrideCount, 0);
      expect(controller.genderReviewRows.first.name, 'أحمد الشمري');
      expect(controller.genderReviewRows.first.nameOverridden, isFalse);
    });

    testWidgets('زرّ إلغاء التصحيحات يمحو الأسماء والجنس معاً', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester);
      await controller.loadBytes(fileName: 'students.csv', bytes: _csv);
      await tester.pumpAndSettle();

      controller.setRowGender(2, Gender.female);
      controller.setRowName(3, 'نورة');
      await tester.pumpAndSettle();
      expect(controller.hasReviewOverrides, isTrue);

      final Finder clear =
          find.byKey(const ValueKey<String>('bp-gender-clear'));
      expect(clear, findsOneWidget);
      await tester.ensureVisible(clear);
      await tester.pumpAndSettle();
      await tester.tap(clear);
      await tester.pumpAndSettle();

      expect(controller.genderOverrideCount, 0);
      expect(controller.nameOverrideCount, 0);
      expect(controller.hasReviewOverrides, isFalse);
    });

    test('تصحيحات الأسماء تُصفَّر عند تغيير الملف', () async {
      await controller.loadBytes(fileName: 'students.csv', bytes: _csv);
      controller.setRowName(2, 'نورة');
      expect(controller.nameOverrideCount, 1);

      controller.clearFile();
      expect(controller.nameOverrideCount, 0);
      expect(controller.genderReviewRows, isEmpty);
    });
  });
}
