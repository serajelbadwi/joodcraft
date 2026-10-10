import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/constants/app_constants.dart';
import 'package:joodcraft/core/editor/template_editor_controller.dart';
import 'package:joodcraft/core/editor/widgets/property_toolbar.dart';
import 'package:joodcraft/core/models/template_document.dart';
import 'package:joodcraft/core/models/template_element.dart';
import 'package:joodcraft/core/theme/app_theme.dart';

/// اختبارات واجهة عمليات الدمج المنطقي في لوحة التحديد المتعدد.
void main() {
  late TemplateEditorController controller;

  setUp(() {
    controller = TemplateEditorController(
      document: const TemplateDocument(
        elements: <TemplateElement>[
          ShapeElement(
            id: 'a',
            kind: ShapeKind.rect,
            box: ElementBox(x: 0, y: 0, width: 100, height: 100),
            fillHex: '#C7A26B',
          ),
          ShapeElement(
            id: 'b',
            kind: ShapeKind.ellipse,
            box: ElementBox(x: 50, y: 50, width: 100, height: 100),
            fillHex: '#1B2539',
          ),
          TextElement(
            id: 't',
            box: ElementBox(x: 0, y: 200, width: 100, height: 40),
            text: 'نص',
          ),
        ],
      ),
      category: TemplateCategory.certificate,
    );
  });

  tearDown(() => controller.dispose());

  Future<void> pumpToolbar(WidgetTester tester) async {
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

  Finder byKey(String key) => find.byKey(ValueKey<String>(key));

  testWidgets('تحديد شكلين يُظهر أزرار العمليات الأربع',
      (WidgetTester tester) async {
    controller.select('a');
    controller.toggleSelection('b');

    await pumpToolbar(tester);

    expect(byKey('editor-boolean-union'), findsOneWidget);
    expect(byKey('editor-boolean-subtract'), findsOneWidget);
    expect(byKey('editor-boolean-intersect'), findsOneWidget);
    expect(byKey('editor-boolean-exclude'), findsOneWidget);
    // لا شكل مركّب بعد ⇒ لا زرّ فصل.
    expect(byKey('editor-boolean-ungroup'), findsNothing);
  });

  testWidgets('تحديد شكل واحد لا يُظهر قسم الدمج',
      (WidgetTester tester) async {
    controller.select('a');
    await pumpToolbar(tester);

    expect(byKey('editor-boolean-union'), findsNothing);
    expect(byKey('editor-boolean-exclude'), findsNothing);
    expect(find.text('عمليات الدمج'), findsNothing);
  });

  testWidgets('ضغط الاستثناء يُنتج شكلاً مركّباً واحداً',
      (WidgetTester tester) async {
    controller.select('a');
    controller.toggleSelection('b');
    await pumpToolbar(tester);

    await tester.tap(byKey('editor-boolean-exclude'));
    await tester.pump();

    final ShapeElement compound =
        controller.document.elements.first as ShapeElement;
    expect(compound.isCompound, isTrue);
    expect(compound.booleanOp, ShapeBooleanOp.exclude);
    expect(controller.document.elements, hasLength(2)); // الشكل + النص
  });

  testWidgets('الشكل المركّب يُظهر زرّ الفصل في شريط الشكل',
      (WidgetTester tester) async {
    controller.select('a');
    controller.toggleSelection('b');
    controller.applyShapeBoolean(ShapeBooleanOp.union);
    await pumpToolbar(tester);

    expect(find.text('فصل الشكل المركّب'), findsOneWidget);
  });
}
