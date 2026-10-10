import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/constants/app_assets.dart';
import 'package:joodcraft/core/constants/app_constants.dart';
import 'package:joodcraft/core/editor/template_editor_controller.dart';
import 'package:joodcraft/core/editor/widgets/property_toolbar.dart';
import 'package:joodcraft/core/editor/widgets/template_editor_view.dart';
import 'package:joodcraft/core/gender/arabic_gender.dart';
import 'package:joodcraft/core/models/template_document.dart';
import 'package:joodcraft/core/models/template_element.dart';
import 'package:joodcraft/core/theme/app_theme.dart';

import '../support/fake_template_repository.dart';

/// **أدوات الجنس في المحرّر**: زرّ إدراج الصيغة الشرطية في لوحة النص، ومبدّل
/// جنس المعاينة الحيّة في الشريط العلوي.
void main() {
  TemplateDocument document({String text = ''}) => TemplateDocument(
        orientation: PageOrientation.landscape,
        sampleData: const <String, String>{
          'اسم_المتدرب': 'سارة العتيبي',
        },
        elements: <TemplateElement>[
          TextElement(
            id: 'text-1',
            box: const ElementBox(x: 120, y: 140, width: 560, height: 90),
            text: text,
            fontSize: 18,
          ),
        ],
      );

  group('إدراج صيغة شرطية من لوحة الخصائص', () {
    late TemplateEditorController controller;

    setUp(() {
      controller = TemplateEditorController(
        document: document(),
        category: TemplateCategory.certificate,
      );
      controller.select('text-1');
    });

    tearDown(() => controller.dispose());

    Future<void> pumpToolbar(WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: SingleChildScrollView(
              child: PropertyToolbar(controller: controller),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('الزرّ يفتح نافذة الصيغ ويُدرج الصيغة في النص', (
      WidgetTester tester,
    ) async {
      await pumpToolbar(tester);

      final Finder button =
          find.byKey(const ValueKey<String>('gender-snippet-button'));
      expect(button, findsOneWidget);

      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('gender-snippet-dialog')),
        findsOneWidget,
      );
      // كل صيغة جاهزة معروضة في النافذة.
      expect(
        find.byKey(const ValueKey<String>('gender-snippet-genderPresetCompleted')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('gender-snippet-genderPresetCompleted')),
      );
      await tester.pumpAndSettle();

      final TextElement element =
          controller.document.elements.single as TextElement;
      expect(element.text, contains('{{الجنس:'));
      expect(element.text, contains('|'));
      expect(element.text, contains('أتمّت'));
      expect(
        find.byKey(const ValueKey<String>('gender-snippet-dialog')),
        findsNothing,
      );
    });

    testWidgets('زرّ الإغلاق يغلق النافذة بلا إدراج', (
      WidgetTester tester,
    ) async {
      await pumpToolbar(tester);

      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('gender-snippet-button')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('gender-snippet-button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey<String>('gender-snippet-close')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('gender-snippet-dialog')),
        findsNothing,
      );
      expect(
        (controller.document.elements.single as TextElement).text,
        isEmpty,
      );
    });
  });

  group('مبدّل جنس المعاينة الحيّة', () {
    test('الافتراضي تلقائي والمبدّل يفرض الجنس ثم يلغيه', () {
      final TemplateEditorController controller = TemplateEditorController(
        document: document(),
        category: TemplateCategory.certificate,
      );
      addTearDown(controller.dispose);

      expect(controller.previewGender, isNull);
      controller.togglePreviewGender();
      expect(controller.previewGender, Gender.female);
      controller.togglePreviewGender();
      expect(controller.previewGender, Gender.male);

      controller.setPreviewGender(null);
      expect(controller.previewGender, isNull);
    });

    testWidgets('المعاينة تتبدّل على اللوحة فوراً (أنثى ← ذكر ← أنثى)', (
      WidgetTester tester,
    ) async {
      // شاشة واسعة تُظهر كل أدوات الشريط (مبدّل الجنس ضمنها) بلا قائمة فيض.
      await tester.binding.setSurfaceSize(const Size(3600, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: TemplateEditorView(
              category: TemplateCategory.certificate,
              initialTemplateAsset: AppAssets.sampleCertificateTemplate,
              exportFileName: 'joodcraft-certificate.pdf',
              repository: FakeTemplateRepository(),
              title: 'شهادة جديدة',
              document: document(
                text: '{{الجنس: أتمّ | أتمّت}} الدورة بنجاح',
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // الوضع التلقائي: الاسم التجريبي «سارة» ← صياغة مؤنّثة.
      expect(find.text('أتمّت الدورة بنجاح'), findsOneWidget);

      final Finder maleToggle =
          find.byKey(const ValueKey<String>('editor-gender-male'));
      expect(maleToggle, findsOneWidget);
      await tester.ensureVisible(maleToggle);
      await tester.pumpAndSettle();
      await tester.tap(maleToggle);
      await tester.pump();

      await tester.pump();
      await tester.pump();
      expect(find.text('أتمّ الدورة بنجاح'), findsOneWidget);
      expect(find.text('أتمّت الدورة بنجاح'), findsNothing);

      final Finder femaleToggle =
          find.byKey(const ValueKey<String>('editor-gender-female'));
      await tester.ensureVisible(femaleToggle);
      await tester.pumpAndSettle();
      await tester.tap(femaleToggle);
      await tester.pump();
      await tester.pump();
      await tester.pump();
      expect(find.text('أتمّت الدورة بنجاح'), findsOneWidget);

      // النقر على الزر المحدّد يُلغي الفرض ويعود للاستنتاج التلقائي.
      await tester.tap(femaleToggle);
      await tester.pump();
      await tester.pump();
      await tester.pump();
      expect(find.text('أتمّت الدورة بنجاح'), findsOneWidget);
    });
  });
}
