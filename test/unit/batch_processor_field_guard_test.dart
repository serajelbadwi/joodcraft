import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/constants/app_constants.dart';
import 'package:joodcraft/core/models/template_document.dart';
import 'package:joodcraft/core/models/template_element.dart';
import 'package:joodcraft/features/batch_processor/presentation/providers/batch_processor_controller.dart';

/// ملف CSV: عمود اسم وعمود تاريخ — الحالة التي أطلق فيها الاسم مكان التاريخ.
final Uint8List _csv = Uint8List.fromList(
  utf8.encode(
    'الاسم,التاريخ\n'
    'أحمد الشمري,1447/03/12\n'
    'سارة العتيبي,1447/03/13\n',
  ),
);

/// قالب فيه حقل تاريخ فقط ونصّ ثابت يشبه اسم المتدرب.
TemplateDocument _dateOnlyTemplate() => TemplateDocument(
      orientation: PageOrientation.landscape,
      elements: const <TemplateElement>[
        TextElement(
          id: 'name-placeholder',
          box: ElementBox(x: 100, y: 260, width: 420, height: 60),
          text: 'محمد بن عبد الله الشمري',
          fontSize: 22,
        ),
        TextElement(
          id: 'date-field',
          box: ElementBox(x: 100, y: 100, width: 320, height: 40),
          text: 'صدر بتاريخ {{التاريخ}}',
          fontSize: 14,
        ),
      ],
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late BatchProcessorController controller;

  setUp(() => controller = BatchProcessorController());
  tearDown(() => controller.dispose());

  group('تحذير القالب بلا حقل اسم', () {
    test('قالب بحقل تاريخ فقط: بلا حقل اسم ويُظهر التحذير', () {
      controller.useDocument(_dateOnlyTemplate());

      expect(controller.templateHasDynamicFields, isTrue);
      expect(controller.availableFields, <String>['التاريخ']);
      expect(controller.hasNameField, isFalse);
      expect(
        controller.templateWarningAr,
        contains('لا يحتوي على حقل اسم ديناميكي'),
      );
      expect(controller.templateWarningAr, contains('{{اسم_المتدرب}}'));
    });

    test('قالب فيه حقل اسم: لا تحذير', () {
      controller.useDocument(
        TemplateDocument(
          orientation: PageOrientation.landscape,
          elements: const <TemplateElement>[
            TextElement(
              id: 'name',
              box: ElementBox(x: 100, y: 100, width: 420, height: 60),
              text: 'تشهد بأن {{اسم_المتدرب}} أتمّ الدورة',
            ),
          ],
        ),
      );

      expect(controller.hasNameField, isTrue);
      expect(controller.templateWarningAr, isNull);
    });

    test('قالب بلا حقول إطلاقاً: تحذير الحقوق الصفري', () {
      controller.useDocument(
        TemplateDocument(
          elements: const <TemplateElement>[
            TextElement(
              id: 'static',
              box: ElementBox(x: 100, y: 100, width: 420, height: 60),
              text: 'شهادة ثابتة بلا حقول',
            ),
          ],
        ),
      );

      expect(controller.templateHasDynamicFields, isFalse);
      expect(controller.templateWarningAr, contains('بلا حقول ديناميكية'));
    });
  });

  group('حاجز الربط: لا يُربط عمود الاسم بحقل تاريخ', () {
    test('يترك عمود «الاسم» غير مربوط ويبقى زر التوليد مفعّلاً', () {
      controller.useDocument(_dateOnlyTemplate());
      controller.loadBytes(fileName: 'data.csv', bytes: _csv);

      // العمود 0 «الاسم» لا يُربط بحقل «التاريخ» — تُربط خانة التاريخ فقط.
      expect(controller.mapping.fieldFor(0), isNull);
      expect(controller.mapping.fieldFor(1), 'التاريخ');
      expect(controller.mapping.hasDuplicates, isFalse);
      expect(controller.canGenerate, isTrue);
      expect(controller.unmappedColumnCount, 1);
    });
  });

  group('الربط التلقائي غير التخميني', () {
    TemplateDocument nameOnly() => TemplateDocument(
          orientation: PageOrientation.landscape,
          elements: const <TemplateElement>[
            TextElement(
              id: 'n',
              box: ElementBox(x: 0, y: 0, width: 200, height: 30),
              text: '{{اسم_المتدرب}}',
            ),
          ],
        );

    test('عند التحميل يُربط التطابق المؤكَّد (مرادف مطابق) تلقائياً', () {
      controller.useDocument(nameOnly());
      final Uint8List csv =
          Uint8List.fromList(utf8.encode('الاسم\nأحمد الشمري\n'));
      controller.loadBytes(fileName: 'd.csv', bytes: csv);

      // «الاسم» مرادف مطابق تماماً للحقل — ربط مؤكَّد لا تخميني.
      expect(controller.mapping.fieldFor(0), 'اسم_المتدرب');
    });

    test('عنوان يشبه الحقل جزئياً لا يُربط تلقائياً عند التحميل', () {
      controller.useDocument(nameOnly());
      // «اسم متدرب» يشابه «اسم_المتدرب» تشابهاً جزئياً (‏875 دون حدّ 900).
      final Uint8List csv =
          Uint8List.fromList(utf8.encode('اسم متدرب\nأحمد الشمري\n'));
      controller.loadBytes(fileName: 'd.csv', bytes: csv);

      expect(controller.mapping.isEmpty, isTrue);
      // ولا حاجة للتوليد حتى يُفعّل الزر — فالمستخدم لم يوافق بعد.
      expect(controller.canGenerate, isFalse);

      // زر «ربط تلقائي» الصريح يقبل المطابقة المرنة.
      controller.autoMap();
      expect(controller.mapping.fieldFor(0), 'اسم_المتدرب');
    });
  });

  group('تحويل النص الثابت إلى حقل بضغطة', () {
    test('يقترح النص الذي يشبه الاسم ثم يحوّله ويربط عمود الاسم', () {
      controller.useDocument(_dateOnlyTemplate());
      controller.loadBytes(fileName: 'data.csv', bytes: _csv);

      final List<NameTextFieldCandidate> candidates =
          controller.nameFieldCandidates;
      expect(candidates, hasLength(1));
      expect(candidates.single.preview, 'محمد بن عبد الله الشمري');

      final bool converted =
          controller.convertTextToField(candidates.single.index);
      expect(converted, isTrue);

      // صار الحقل متاحاً والتحذير زال والعمود ارتبط فعلاً.
      expect(controller.hasNameField, isTrue);
      expect(controller.templateWarningAr, isNull);
      expect(
        controller.availableFields,
        containsAll(<String>['اسم_المتدرب', 'التاريخ']),
      );
      expect(controller.mapping.fieldFor(0), 'اسم_المتدرب');
      expect(controller.mapping.fieldFor(1), 'التاريخ');
    });

    test('يرفض فهرساً غير صالح أو عنصراً غير نصّي', () {
      controller.useDocument(_dateOnlyTemplate());
      expect(controller.convertTextToField(99), isFalse);
      expect(controller.convertTextToField(-1), isFalse);
    });

    test('revertTextToField يُعيد النص ويزيل الحقل والربط', () {
      controller.useDocument(_dateOnlyTemplate());
      controller.loadBytes(fileName: 'data.csv', bytes: _csv);

      final NameTextFieldCandidate candidate =
          controller.nameFieldCandidates.single;
      final String original = candidate.preview;
      controller.convertTextToField(candidate.index);
      expect(controller.mapping.fieldFor(0), 'اسم_المتدرب');

      final bool reverted =
          controller.revertTextToField(candidate.index, original);
      expect(reverted, isTrue);

      // عاد النص ثابتاً، وزال الحقل، وعاد عمود الاسم بلا ربط.
      expect(controller.hasNameField, isFalse);
      expect(controller.availableFields, <String>['التاريخ']);
      expect(controller.mapping.fieldFor(0), isNull);
      final TextElement restored =
          controller.document!.elements[candidate.index] as TextElement;
      expect(restored.text, original);
      expect(
        controller.document!.fieldKeys,
        isNot(contains('اسم_المتدرب')),
      );
    });

    test('revertTextToField يرفض فهرساً غير صالح', () {
      controller.useDocument(_dateOnlyTemplate());
      expect(controller.revertTextToField(42, 'x'), isFalse);
    });
  });
}
