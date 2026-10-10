import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/constants/app_assets.dart';
import 'package:joodcraft/core/constants/app_constants.dart';
import 'package:joodcraft/core/editor/template_editor_controller.dart';
import 'package:joodcraft/core/editor/widgets/editor_controls.dart';
import 'package:joodcraft/core/editor/widgets/property_toolbar.dart';
import 'package:joodcraft/core/editor/widgets/template_editor_view.dart';
import 'package:joodcraft/core/models/template_document.dart';
import 'package:joodcraft/core/models/template_element.dart';
import 'package:joodcraft/core/theme/app_theme.dart';

/// اختبارات واجهة الأشكال والأقسام القابلة للطيّ (نمط Photoshop).
void main() {
  late TemplateEditorController controller;

  setUp(() {
    controller = TemplateEditorController(
      document: const TemplateDocument(
        elements: <TemplateElement>[
          ShapeElement(
            id: 'shape-1',
            kind: ShapeKind.rect,
            box: ElementBox(x: 40, y: 40, width: 200, height: 120),
            fillHex: '#F3E3C3',
            strokeHex: '#C7A26B',
            strokeWidth: 2,
          ),
        ],
      ),
      category: TemplateCategory.certificate,
    );
  });

  tearDown(() => controller.dispose());

  Widget host(Widget child) => MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(child: child),
        ),
      );

  testWidgets('قائمة «أشكال هندسية» تُدرج دائرة على اللوحة',
      (WidgetTester tester) async {
    await tester.pumpWidget(host(ElementPaletteBar(controller: controller)));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey<String>('palette-shapes')));
    await tester.pumpAndSettle();
    expect(find.text('دائرة/بيضاوي'), findsOneWidget);

    await tester.tap(find.text('دائرة/بيضاوي'));
    await tester.pumpAndSettle();

    final TemplateElement last = controller.document.elements.last;
    expect(last, isA<ShapeElement>());
    expect((last as ShapeElement).kind, ShapeKind.ellipse);
  });

  testWidgets('أدوات الشكل تعرض شفافية التعبئة وتسندها للمتحكم',
      (WidgetTester tester) async {
    controller.select('shape-1');
    await tester.pumpWidget(host(PropertyToolbar(controller: controller)));
    await tester.pump();

    expect(find.text('شفافية التعبئة'), findsOneWidget);

    controller.setSelectedShapeStyle(fillOpacity: 0.4);
    await tester.pump();
    expect((controller.selected! as ShapeElement).fillOpacity, 0.4);
  });

  testWidgets('زر طيّ اللوحة الجانبية يوسّع مساحة التصميم',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: TemplateEditorView(
            category: TemplateCategory.certificate,
            initialTemplateAsset: AppAssets.sampleCertificateTemplate,
            exportFileName: 'joodcraft-certificate.pdf',
            document: controller.document,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey<String>('panel-collapse-button')),
        findsOneWidget);

    await tester.tap(
        find.byKey(const ValueKey<String>('panel-collapse-button')));
    await tester.pump(const Duration(milliseconds: 250));

    // اللوحة الجانبية اختفت وحلّ محلّها زر الإظهار على الحافة.
    expect(find.byKey(const ValueKey<String>('panel-expand-button')),
        findsOneWidget);
    expect(find.byKey(const ValueKey<String>('panel-collapse-button')),
        findsNothing);

    await tester.tap(find.byKey(const ValueKey<String>('panel-expand-button')));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.byKey(const ValueKey<String>('panel-collapse-button')),
        findsOneWidget);
  });

  testWidgets('قسم التحكم يُطوى ويُفتح بنقرة على عنوانه',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: SingleChildScrollView(
            child: ControlSection(
              icon: Icons.tune_rounded,
              label: 'قسم قابل للطيّ',
              children: <Widget>[Text('محتوى القسم')],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('محتوى القسم'), findsOneWidget);
    await tester.tap(find.text('قسم قابل للطيّ'));
    await tester.pump();
    expect(find.text('محتوى القسم'), findsNothing);

    await tester.tap(find.text('قسم قابل للطيّ'));
    await tester.pump();
    expect(find.text('محتوى القسم'), findsOneWidget);
  });
}
