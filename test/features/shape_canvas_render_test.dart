import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/editor/widgets/element_painters.dart';
import 'package:joodcraft/core/editor/widgets/element_view.dart';
import 'package:joodcraft/core/models/template_document.dart';
import 'package:joodcraft/core/models/template_element.dart';

/// اختبارات رسم الأشكال على اللوحة عبر [ShapePainter].
void main() {
  Widget host(TemplateElement element) => MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 160,
              height: 160,
              child: ElementView(
                element: element,
                document: TemplateDocument(elements: <TemplateElement>[element]),
                scale: 1.4,
              ),
            ),
          ),
        ),
      );

  Finder shapePainterFinder() => find.byWidgetPredicate(
        (Widget widget) =>
            widget is CustomPaint && widget.painter is ShapePainter,
      );

  testWidgets('النجمة تُرسم عبر ShapePainter بلا أخطاء',
      (WidgetTester tester) async {
    const ShapeElement star = ShapeElement(
      id: 'star',
      kind: ShapeKind.star,
      box: ElementBox(x: 0, y: 0, width: 120, height: 120),
      points: 6,
      innerRadius: 0.4,
      fillHex: '#C7A26B',
      strokeHex: '#1B2539',
      strokeWidth: 2,
      dashPattern: <double>[6, 3],
      shadow: ShapeShadow(offsetX: 4, offsetY: 4, blurRadius: 8),
    );
    await tester.pumpWidget(host(star));
    await tester.pump();
    expect(shapePainterFinder(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('شكل بتدرّج وقلب يُرسم بلا أخطاء', (WidgetTester tester) async {
    const ShapeElement rect = ShapeElement(
      id: 'gradient',
      kind: ShapeKind.rect,
      box: ElementBox(x: 0, y: 0, width: 120, height: 80),
      cornerRadii: <double>[12, 8, 4, 0],
      gradient: ShapeGradient(startHex: '#FFFFFF', endHex: '#000000', angle: 30),
      flipH: true,
    );
    await tester.pumpWidget(host(rect));
    await tester.pump();
    expect(shapePainterFinder(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('الشكل المركّب (دمج) يُرسم بلا أخطاء', (WidgetTester tester) async {
    const ShapeElement compound = ShapeElement(
      id: 'compound',
      kind: ShapeKind.rect,
      box: ElementBox(x: 0, y: 0, width: 120, height: 120),
      fillHex: '#1B2539',
      booleanOp: ShapeBooleanOp.union,
      booleanParts: <ShapeElement>[
        ShapeElement(
          id: 'a',
          kind: ShapeKind.rect,
          box: ElementBox(width: 80, height: 80),
        ),
        ShapeElement(
          id: 'b',
          kind: ShapeKind.ellipse,
          box: ElementBox(x: 40, y: 40, width: 80, height: 80),
        ),
      ],
    );
    await tester.pumpWidget(host(compound));
    await tester.pump();
    expect(shapePainterFinder(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
