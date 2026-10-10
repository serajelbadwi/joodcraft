import 'dart:ui' show Size;

import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/editor/element_factory.dart';
import 'package:joodcraft/core/models/template_element.dart';

/// اختبارات محرّك الأشكال الموسّع: التدرّج، الظل، الشرطات، الزوايا، النجم/المضلّع.
void main() {
  const ElementBox box = ElementBox(x: 10, y: 20, width: 120, height: 80);

  group('أنواع الأشكال الجديدة', () {
    test('النجمة تُحفظ وتُستعاد بكل خصائصها', () {
      const ShapeElement star = ShapeElement(
        id: 'star-1',
        box: box,
        kind: ShapeKind.star,
        points: 7,
        innerRadius: 0.3,
        fillHex: '#C7A26B',
      );
      final Map<String, dynamic> json = star.toJson();
      expect(json['type'], 'star');
      expect(json['points'], 7);
      expect(json['innerRadius'], 0.3);

      final ShapeElement restored =
          ShapeElement.fromJson(json, 'star-1', ShapeKind.star);
      expect(restored.kind, ShapeKind.star);
      expect(restored.points, 7);
      expect(restored.innerRadius, 0.3);
    });

    test('المضلّع يُحفظ بنوعه وعدد أضلاعه', () {
      final ShapeElement polygon =
          ShapeElement(id: 'p', box: box, kind: ShapeKind.polygon, points: 8);
      expect(polygon.toJson()['type'], 'polygon');
      final ShapeElement restored = ShapeElement.fromJson(
        polygon.toJson(),
        'p',
        ShapeKind.polygon,
      );
      expect(restored.points, 8);
    });

    test('القيم الافتراضية لا تُكتب في JSON', () {
      const ShapeElement shape =
          ShapeElement(id: 's', box: box, kind: ShapeKind.star);
      final Map<String, dynamic> json = shape.toJson();
      expect(json.containsKey('points'), isFalse);
      expect(json.containsKey('innerRadius'), isFalse);
    });
  });

  group('التدرّج والظل والشرطات والزوايا', () {
    test('التدرّج يُحفظ ويُستعاد', () {
      const ShapeElement shape = ShapeElement(
        id: 'g',
        box: box,
        kind: ShapeKind.rect,
        gradient: ShapeGradient(
          startHex: '#FFFFFF',
          endHex: '#000000',
          angle: 45,
          kind: ShapeFillKind.radialGradient,
        ),
      );
      final Map<String, dynamic> json = shape.toJson();
      expect(json['gradient'], isA<Map<String, dynamic>>());
      final ShapeElement restored =
          ShapeElement.fromJson(json, 'g', ShapeKind.rect);
      expect(restored.gradient, isNotNull);
      expect(restored.gradient!.startHex, '#FFFFFF');
      expect(restored.gradient!.endHex, '#000000');
      expect(restored.gradient!.angle, 45);
      expect(restored.gradient!.kind, ShapeFillKind.radialGradient);
    });

    test('الظل يُحفظ ويُستعاد بكل حقوله', () {
      const ShapeElement shape = ShapeElement(
        id: 'sh',
        box: box,
        kind: ShapeKind.rect,
        shadow: ShapeShadow(
          colorHex: '#112233',
          blurRadius: 12,
          offsetX: 3,
          offsetY: -4,
          spread: 5,
        ),
      );
      final ShapeElement restored = ShapeElement.fromJson(
        shape.toJson(),
        'sh',
        ShapeKind.rect,
      );
      expect(restored.shadow, isNotNull);
      expect(restored.shadow!.colorHex, '#112233');
      expect(restored.shadow!.blurRadius, 12);
      expect(restored.shadow!.offsetX, 3);
      expect(restored.shadow!.offsetY, -4);
      expect(restored.shadow!.spread, 5);
    });

    test('الشرطات وأنصاف أقطار الزوايا والقلب تُحفظ وتُستعاد', () {
      const ShapeElement shape = ShapeElement(
        id: 'c',
        box: box,
        kind: ShapeKind.rect,
        cornerRadii: <double>[4, 8, 12, 16],
        dashPattern: <double>[6, 3],
        flipH: true,
        flipV: true,
      );
      final Map<String, dynamic> json = shape.toJson();
      final ShapeElement restored =
          ShapeElement.fromJson(json, 'c', ShapeKind.rect);
      expect(restored.cornerRadii, <double>[4, 8, 12, 16]);
      expect(restored.dashPattern, <double>[6, 3]);
      expect(restored.flipH, isTrue);
      expect(restored.flipV, isTrue);
    });

    test('copyWith يُحدّث التدرّج والظل ويُميّز null عن غيابه', () {
      const ShapeElement shape =
          ShapeElement(id: 'x', box: box, kind: ShapeKind.rect);
      final ShapeElement withGradient = shape.copyWith(
        gradient: const ShapeGradient(startHex: '#111111', endHex: '#222222'),
        shadow: const ShapeShadow(),
      );
      expect(withGradient.gradient, isNotNull);
      expect(withGradient.shadow, isNotNull);
      final ShapeElement cleared = withGradient.copyWith(
        gradient: null,
        shadow: null,
      );
      expect(cleared.gradient, isNull);
      expect(cleared.shadow, isNull);
    });
  });

  group('الدمج المنطقي (النموذج)', () {
    test('الشكل المركّب يُحفظ بأجزائه وعمليته', () {
      const ShapeElement partA = ShapeElement(
        id: 'a',
        box: ElementBox(width: 40, height: 40),
        kind: ShapeKind.rect,
      );
      const ShapeElement partB = ShapeElement(
        id: 'b',
        box: ElementBox(x: 20, y: 20, width: 40, height: 40),
        kind: ShapeKind.ellipse,
      );
      const ShapeElement compound = ShapeElement(
        id: 'compound',
        box: box,
        kind: ShapeKind.rect,
        booleanOp: ShapeBooleanOp.subtract,
        booleanParts: <ShapeElement>[partA, partB],
      );
      expect(compound.isCompound, isTrue);

      final ShapeElement restored = ShapeElement.fromJson(
        compound.toJson(),
        'compound',
        ShapeKind.rect,
      );
      expect(restored.isCompound, isTrue);
      expect(restored.booleanOp, ShapeBooleanOp.subtract);
      expect(restored.booleanParts, hasLength(2));
      expect(restored.booleanParts.last.kind, ShapeKind.ellipse);
    });
  });

  group('المصنع', () {
    const Size design = Size(1000, 700);

    test('النجمة تُنشأ بنوعها وخمسة رؤوس', () {
      final ShapeElement star = ElementFactory.create(
        kind: NewElementKind.star,
        design: design,
      ) as ShapeElement;
      expect(star.kind, ShapeKind.star);
      expect(star.points, 5);
      expect(star.fillHex, isNotNull);
    });

    test('المضلّع يُنشأ بنوعه', () {
      final ShapeElement polygon = ElementFactory.create(
        kind: NewElementKind.polygon,
        design: design,
      ) as ShapeElement;
      expect(polygon.kind, ShapeKind.polygon);
    });
  });
}
