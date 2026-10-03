import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/constants/app_constants.dart';
import 'package:joodcraft/core/models/decoration.dart';
import 'package:joodcraft/core/models/template_document.dart';
import 'package:joodcraft/core/models/template_element.dart';

/// بصمة تشمل الإحداثيات فعلياً — حتى يكشف أي تغيّر هندسي بين مخرجين.
String _signature(List<DecorPath> paths) => paths.map((DecorPath p) {
      final StringBuffer buffer = StringBuffer('${p.colorHex}:${p.closed}:${p.stroke}');
      for (final DecorSegment segment in p.segments) {
        switch (segment) {
          case DecorMove(:final double x, :final double y):
            buffer.write('M$x,$y;');
          case DecorLine(:final double x, :final double y):
            buffer.write('L$x,$y;');
          case DecorCubic(
              :final double x1,
              :final double y1,
              :final double x2,
              :final double y2,
              :final double x,
              :final double y,
            ):
            buffer.write('C$x1,$y1,$x2,$y2,$x,$y;');
        }
      }
      return buffer.toString();
    }).join('|');

void main() {
  test('كل نوع يُنتج مسارات فعلية بمقاس معطّى', () {
    for (final DecorKind kind in DecorKind.values) {
      final List<DecorPath> paths =
          VectorDecor.build(DecorSpec(kind: kind), 400, 300);
      expect(paths, isNotEmpty, reason: kind.name);
      expect(
        paths.every((DecorPath p) => p.segments.isNotEmpty),
        isTrue,
        reason: kind.name,
      );
    }
  });

  test('الإخراج حتمي: نفس المدخلات ⇒ نفس المسارات', () {
    const DecorSpec spec = DecorSpec(kind: DecorKind.guilloche, seed: 5);
    final List<DecorPath> a = VectorDecor.build(spec, 300, 200);
    final List<DecorPath> b = VectorDecor.build(spec, 300, 200);
    expect(_signature(a), _signature(b));
  });

  test('تغيير البذرة يغيّر الزخرفة (تنويع بلا عشوائية)', () {
    final String a = _signature(VectorDecor.build(
      const DecorSpec(kind: DecorKind.modernWave, seed: 1),
      200,
      150,
    ));
    final String b = _signature(VectorDecor.build(
      const DecorSpec(kind: DecorKind.modernWave, seed: 2),
      200,
      150,
    ));
    expect(a, isNot(b));
  });

  test('عدد الطبقات محترم ومحدود بسقف آمن', () {
    expect(
      VectorDecor.build(
        const DecorSpec(kind: DecorKind.modernWave, layers: 3),
        100,
        100,
      ).length,
      3,
    );
    expect(
      VectorDecor.build(
        const DecorSpec(kind: DecorKind.modernWave, layers: 99),
        100,
        100,
      ).length,
      VectorDecor.maxLayers,
    );
  });

  test('مقاس صفري لا يُنتج مسارات', () {
    expect(VectorDecor.build(const DecorSpec(), 0, 100), isEmpty);
    expect(VectorDecor.build(const DecorSpec(), 100, 0), isEmpty);
  });

  test('lerpHex يدرّج بين لونين بنسبة صحيحة', () {
    expect(VectorDecor.lerpHex('#000000', '#ffffff', 0), '#000000');
    expect(VectorDecor.lerpHex('#000000', '#ffffff', 1), '#ffffff');
    expect(VectorDecor.lerpHex('#000000', '#ffffff', 0.5), '#808080');
  });

  test('دورة JSON كاملة للعنصر بلا فقد', () {
    final DecorationElement element = DecorationElement(
      id: 'd1',
      box: const ElementBox(x: 10, y: 20, width: 300, height: 200),
      spec: const DecorSpec(
        kind: DecorKind.classicCorner,
        primaryHex: '#112233',
        layers: 4,
        seed: 9,
      ),
      opacity: 0.8,
    );

    final DecorationElement back =
        DecorationElement.fromJson(element.toJson(), 'd1');

    expect(back.spec, element.spec);
    expect(back.opacity, 0.8);
    expect(back.box.width, 300);
    expect(back.box.y, 20);
  });

  test('TemplateDocument يستعيد عنصر الزخرفة بنوعه الصحيح', () {
    final TemplateDocument document = TemplateDocument(
      orientation: PageOrientation.landscape,
      elements: <TemplateElement>[
        DecorationElement(
          id: 'd',
          box: const ElementBox(x: 0, y: 0, width: 200, height: 100),
          spec: const DecorSpec(kind: DecorKind.ribbonBanner),
        ),
      ],
    );

    final TemplateDocument back =
        TemplateDocument.fromJson(Map<String, dynamic>.from(document.toJson()));

    expect(back.elements.single, isA<DecorationElement>());
    expect(
      (back.elements.single as DecorationElement).spec.kind,
      DecorKind.ribbonBanner,
    );
  });

  test('الزخرفة لا تُدخل حقولاً ديناميكية على القالب', () {
    final TemplateDocument document = TemplateDocument(
      elements: <TemplateElement>[
        DecorationElement(
          id: 'd',
          box: const ElementBox(x: 0, y: 0, width: 10, height: 10),
        ),
      ],
    );
    expect(document.fieldKeys, isEmpty);
    expect(document.hasDynamicFields, isFalse);
  });
}
