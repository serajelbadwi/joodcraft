import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/constants/app_assets.dart';
import 'package:joodcraft/core/constants/app_constants.dart';
import 'package:joodcraft/core/editor/widgets/accordion.dart';
import 'package:joodcraft/core/editor/widgets/template_editor_view.dart';
import 'package:joodcraft/core/models/template_document.dart';
import 'package:joodcraft/core/models/template_element.dart';
import 'package:joodcraft/core/theme/app_theme.dart';

/// اختبارات **الأكورديون الحصري** لأقسام الشريط الجانبي: قسم واحد مفتوح في كل
/// لحظة، وفتح قسم يُغلق ما سواه — مع بقاء الحالة الافتراضية قبل أول تفاعل.
void main() {
  const TemplateDocument document = TemplateDocument(
    orientation: PageOrientation.landscape,
    elements: <TemplateElement>[
      TextElement(
        id: 'text-1',
        box: ElementBox(x: 200, y: 200, width: 400, height: 80),
        text: 'شهادة إتمام',
      ),
      ShapeElement(
        id: 'shape-1',
        kind: ShapeKind.rect,
        box: ElementBox(x: 640, y: 200, width: 120, height: 120),
      ),
    ],
  );

  Future<void> pumpEditor(
    WidgetTester tester, {
    String? initialSelectionId,
  }) async {
    await tester.binding.setSurfaceSize(const Size(1600, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: TemplateEditorView(
            category: TemplateCategory.certificate,
            initialTemplateAsset: AppAssets.sampleCertificateTemplate,
            exportFileName: 'joodcraft-certificate.pdf',
            title: 'شهادة جديدة',
            document: document,
            initialSelectionId: initialSelectionId,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Finder byKey(String key) => find.byKey(ValueKey<String>(key));

  group('متحكّم الأكورديون', () {
    test('يبدأ بلا اختيار صريح ثم يصبح السلوك حصرياً بعد أول تفاعل', () {
      final AccordionController controller = AccordionController();
      addTearDown(controller.dispose);

      expect(controller.hasExplicitSelection, isFalse);

      controller.expand('a');
      expect(controller.hasExplicitSelection, isTrue);
      expect(controller.isExpanded('a'), isTrue);

      // فتح قسم يُغلق ما سواه.
      controller.expand('b');
      expect(controller.isExpanded('a'), isFalse);
      expect(controller.isExpanded('b'), isTrue);

      // إغلاق القسم المفتوح يطوي الجميع.
      controller.toggle('b');
      expect(controller.isExpanded('b'), isFalse);
      expect(controller.expandedId, AccordionController.none);

      // إعادة الضبط تُلغي الاختيار الصريح.
      controller.expand('a');
      controller.reset();
      expect(controller.hasExplicitSelection, isFalse);
    });
  });

  group('الشريط الجانبي', () {
    testWidgets('قبل أي نقرة تتبع الأقسام حالتها الافتراضية (مفتوحة)',
        (WidgetTester tester) async {
      await pumpEditor(tester, initialSelectionId: 'text-1');

      expect(find.text('تنسيق النص'), findsOneWidget);
      expect(find.text('حجم الخط'), findsOneWidget);
      expect(find.text('الطبقات'), findsOneWidget);
      expect(byKey('layer-tile-text-1'), findsOneWidget);
    });

    testWidgets('فتح قسم يُغلق بقية الأقسام (سلوك حصري)',
        (WidgetTester tester) async {
      await pumpEditor(tester);

      // نحدّد النص فيظهر شريط خصائصه، وتكون أقسامه مفتوحة كلها في البداية.
      await tester.ensureVisible(byKey('layer-select-text-1'));
      await tester.tap(byKey('layer-select-text-1'));
      await tester.pumpAndSettle();

      expect(find.text('حجم الخط'), findsOneWidget);
      expect(byKey('layer-tile-shape-1'), findsOneWidget);

      // فتح «الطبقات» يُغلق «تنسيق النص» تلقائياً.
      await tester.ensureVisible(find.text('الطبقات'));
      await tester.tap(find.text('الطبقات'));
      await tester.pumpAndSettle();

      expect(find.text('حجم الخط'), findsNothing);
      expect(byKey('layer-tile-shape-1'), findsOneWidget);

      // وفتح «تنسيق النص» يُغلق «الطبقات».
      await tester.ensureVisible(find.text('تنسيق النص'));
      await tester.tap(find.text('تنسيق النص'));
      await tester.pumpAndSettle();

      expect(find.text('حجم الخط'), findsOneWidget);
      expect(byKey('layer-tile-shape-1'), findsNothing);
    });

    testWidgets('النقر على القسم المفتوح مرّتين يطويه وحده',
        (WidgetTester tester) async {
      await pumpEditor(tester);

      await tester.ensureVisible(byKey('layer-select-text-1'));
      await tester.tap(byKey('layer-select-text-1'));
      await tester.pumpAndSettle();

      // النقرة الأولى تجعله القسم الوحيد المفتوح…
      await tester.ensureVisible(find.text('تنسيق النص'));
      await tester.tap(find.text('تنسيق النص'));
      await tester.pumpAndSettle();
      expect(find.text('حجم الخط'), findsOneWidget);

      // …والثانية تطويه فيُغلق كل شيء.
      await tester.ensureVisible(find.text('تنسيق النص'));
      await tester.tap(find.text('تنسيق النص'));
      await tester.pumpAndSettle();
      expect(find.text('حجم الخط'), findsNothing);
    });

    testWidgets('تغيير نوع التحديد يُعيد الأقسام إلى حالتها الافتراضية',
        (WidgetTester tester) async {
      await pumpEditor(tester);

      // تحديد النص ثم توسيع «الطبقات» صراحةً (اختيار حصري).
      await tester.ensureVisible(byKey('layer-select-text-1'));
      await tester.tap(byKey('layer-select-text-1'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('الطبقات'));
      await tester.tap(find.text('الطبقات'));
      await tester.pumpAndSettle();
      expect(find.text('حجم الخط'), findsNothing);

      // تغيير نوع التحديد إلى شكل يُعيد الضبط، فتظهر أقسام الشكل مفتوحة كلها.
      await tester.ensureVisible(byKey('layer-select-shape-1'));
      await tester.tap(byKey('layer-select-shape-1'));
      await tester.pumpAndSettle();

      expect(find.text('الشكل'), findsOneWidget);
      expect(find.text('شفافية التعبئة'), findsOneWidget);
    });
  });
}
