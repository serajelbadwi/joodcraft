import 'dart:ui' show Size;

import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/editor/element_factory.dart';
import 'package:joodcraft/core/models/template_element.dart';

/// اختبارات محرّك الأشكال: الأنواع، الاستدارة، وشفافية التعبئة.
void main() {
  const ElementBox box = ElementBox(x: 10, y: 20, width: 120, height: 80);

  group('ترميز ShapeElement', () {
    test('الخصائص الكاملة تُحفظ وتُستعاد', () {
      const ShapeElement shape = ShapeElement(
        id: 's1',
        box: box,
        kind: ShapeKind.rect,
        fillHex: '#FFFFFF',
        strokeHex: '#000000',
        strokeWidth: 2.5,
        radius: 18,
        opacity: 0.9,
        fillOpacity: 0.35,
      );

      final Map<String, dynamic> json = shape.toJson();
      expect(json['type'], 'rect');
      expect(json['fillOpacity'], 0.35);

      final ShapeElement restored =
          ShapeElement.fromJson(json, 's1', ShapeKind.rect);
      expect(restored.fillHex, '#FFFFFF');
      expect(restored.strokeHex, '#000000');
      expect(restored.strokeWidth, 2.5);
      expect(restored.radius, 18);
      expect(restored.opacity, 0.9);
      expect(restored.fillOpacity, 0.35);
    });

    test('شفافية التعبئة الافتراضية = 1 ولا تُكتب في JSON', () {
      const ShapeElement shape = ShapeElement(
        id: 's2',
        box: box,
        kind: ShapeKind.ellipse,
        fillHex: '#C7A26B',
      );
      expect(shape.fillOpacity, 1);
      expect(shape.toJson().containsKey('fillOpacity'), isFalse);
      expect(shape.toJson()['type'], 'ellipse');
    });

    test('copyWith يُغيّر شفافية التعبئة ويحفظ النوع والاستدارة', () {
      const ShapeElement shape = ShapeElement(
        id: 's3',
        box: box,
        kind: ShapeKind.rect,
        radius: 12,
      );
      final ShapeElement updated = shape.copyWith(fillOpacity: 0.5);
      expect(updated.fillOpacity, 0.5);
      expect(updated.radius, 12);
      expect(updated.kind, ShapeKind.rect);
    });
  });

  group('مصنع الأشكال', () {
    const Size design = Size(1000, 700);

    test('الدائرة/البيضاوي', () {
      final TemplateElement element =
          ElementFactory.create(kind: NewElementKind.ellipse, design: design);
      expect(element, isA<ShapeElement>());
      expect((element as ShapeElement).kind, ShapeKind.ellipse);
    });

    test('المستطيل بحواف منحنية يستخدم radius موجباً', () {
      final ShapeElement element = ElementFactory.create(
        kind: NewElementKind.roundedRect,
        design: design,
      ) as ShapeElement;
      expect(element.kind, ShapeKind.rect);
      expect(element.radius, greaterThan(0));
      expect(element.fillHex, isNotNull);
    });

    test('الخط الفاصل', () {
      final ShapeElement element = ElementFactory.create(
        kind: NewElementKind.divider,
        design: design,
      ) as ShapeElement;
      expect(element.kind, ShapeKind.line);
    });
  });
}
