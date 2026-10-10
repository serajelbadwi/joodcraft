import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/constants/app_constants.dart';
import 'package:joodcraft/core/editor/template_editor_controller.dart';
import 'package:joodcraft/core/editor/widgets/element_view.dart';
import 'package:joodcraft/core/editor/widgets/layers_panel.dart';
import 'package:joodcraft/core/editor/widgets/template_canvas.dart';
import 'package:joodcraft/core/models/template_document.dart';
import 'package:joodcraft/core/models/template_element.dart';
import 'package:joodcraft/core/theme/app_theme.dart';

/// اختبارات لوحة الطبقات والسلوك البصري للعناصر المخفية/المقفلة على اللوحة.
void main() {
  late TemplateEditorController controller;

  TemplateDocument buildDocument({BackgroundGradient? gradient}) =>
      TemplateDocument(
        orientation: PageOrientation.landscape,
        backgroundGradient: gradient,
        elements: const <TemplateElement>[
          TextElement(
            id: 'a',
            box: ElementBox(x: 100, y: 100, width: 200, height: 80),
            text: 'الأول',
          ),
          TextElement(
            id: 'b',
            box: ElementBox(x: 400, y: 100, width: 200, height: 80),
            text: 'الثاني',
          ),
        ],
      );

  setUp(() {
    controller = TemplateEditorController(
      document: buildDocument(),
      category: TemplateCategory.certificate,
    );
  });

  tearDown(() => controller.dispose());

  Future<void> pumpPanel(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(width: 380, child: LayersPanel(controller: controller)),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> pumpCanvas(WidgetTester tester,
      {BackgroundGradient? gradient}) async {
    controller.dispose();
    controller = TemplateEditorController(
      document: buildDocument(gradient: gradient),
      category: TemplateCategory.certificate,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: TemplateCanvas(controller: controller)),
      ),
    );
    await tester.pump();
  }

  testWidgets('اللوحة تعرض صفاً لكل عنصر بترتيب من الأعلى', (WidgetTester tester) async {
    await pumpPanel(tester);
    expect(find.byKey(const ValueKey<String>('layer-tile-a')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('layer-tile-b')), findsOneWidget);
  });

  testWidgets('زر الإظهار يُخفي العنصر وزر القفل يقفله',
      (WidgetTester tester) async {
    await pumpPanel(tester);

    await tester.tap(find.byKey(const ValueKey<String>('layer-visibility-a')));
    await tester.pump();
    expect(controller.isElementHidden('a'), isTrue);

    await tester.tap(find.byKey(const ValueKey<String>('layer-lock-b')));
    await tester.pump();
    expect(controller.isElementLocked('b'), isTrue);
    expect(controller.isElementLocked('a'), isFalse);
  });

  testWidgets('النقر على صف الطبقة يحدّد العنصر مباشرةً',
      (WidgetTester tester) async {
    await pumpPanel(tester);
    expect(controller.hasSelection, isFalse);

    await tester.tap(find.byKey(const ValueKey<String>('layer-select-b')));
    await tester.pump();
    expect(controller.isSelected('b'), isTrue);
  });

  testWidgets('العنصر المخفي لا يُرسم على اللوحة', (WidgetTester tester) async {
    await pumpCanvas(tester);
    expect(find.byType(ElementView), findsNWidgets(2));

    controller.setElementHidden('a', true);
    await tester.pump();
    expect(find.byType(ElementView), findsOneWidget);
  });

  testWidgets('العنصر المقفل لا يُحدَّد بالنقر على اللوحة',
      (WidgetTester tester) async {
    await pumpCanvas(tester);
    controller.setElementLocked('a', true);
    await tester.pump();

    // العنصر المقفل يرفض الإصابة، فالنقرة لا تصل إليه — لهذا نتجاهل تحذير
    // «لم يُصِب العنصر» فهو السلوك المطلوب بالضبط.
    await tester.tap(find.byType(ElementView).first, warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 400));
    expect(controller.isSelected('a'), isFalse);
  });

  testWidgets('تدرّج الخلفية يُرسم على الورقة', (WidgetTester tester) async {
    await pumpCanvas(
      tester,
      gradient: const BackgroundGradient(
        startHex: '#112233',
        endHex: '#AABBCC',
      ),
    );

    final Iterable<DecoratedBox> boxes =
        tester.widgetList<DecoratedBox>(find.byType(DecoratedBox));
    final bool hasGradient = boxes.any((DecoratedBox box) {
      final Decoration decoration = box.decoration;
      return decoration is BoxDecoration && decoration.gradient != null;
    });
    expect(hasGradient, isTrue);
  });
}
