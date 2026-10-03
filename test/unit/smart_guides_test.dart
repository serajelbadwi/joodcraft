import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/editor/canvas_geometry.dart';
import 'package:joodcraft/core/models/template_element.dart';

void main() {
  const Size design = Size(1000, 800);

  group('خطوط مركز اللوحة', () {
    test('منتصف العنصر يلتصق بالمنتصف الرأسي للوحة', () {
      final SnapOutcome outcome = SmartGuides.snap(
        box: const ElementBox(x: 399, y: 200, width: 200, height: 100),
        design: design,
      );

      expect(outcome.box.x, 400);
      expect(outcome.guides.length, 1);
      final SmartGuide guide = outcome.guides.single;
      expect(guide.vertical, isTrue);
      expect(guide.position, closeTo(500, 0.001));
      // خط اللوحة يمتد على كامل الارتفاع.
      expect(guide.start, 0);
      expect(guide.end, 800);
    });

    test('منتصف العنصر يلتصق بالمنتصف الأفقي للوحة', () {
      final SnapOutcome outcome = SmartGuides.snap(
        box: const ElementBox(x: 200, y: 299, width: 200, height: 100),
        design: design,
      );

      expect(outcome.box.y, 300);
      final SmartGuide guide = outcome.guides.single;
      expect(guide.vertical, isFalse);
      expect(guide.position, closeTo(400, 0.001));
    });
  });

  group('المحاذاة بين العناصر', () {
    test('الحافة اليسرى تلتصق بالحافة اليسرى لعنصر آخر', () {
      final SnapOutcome outcome = SmartGuides.snap(
        box: const ElementBox(x: 302, y: 600, width: 100, height: 50),
        design: design,
        others: const <ElementBox>[
          ElementBox(x: 300, y: 50, width: 100, height: 100),
        ],
      );

      expect(outcome.box.x, 300);
      final SmartGuide guide = outcome.guides.single;
      expect(guide.vertical, isTrue);
      expect(guide.position, 300);
      // الخط يربط بين العنصرين (اتحاد نطاقيهما).
      expect(guide.start, 50);
      expect(guide.end, 650);
    });

    test('لا التصاق عندما تتجاوز المسافة الحدّ', () {
      final SnapOutcome outcome = SmartGuides.snap(
        box: const ElementBox(x: 200, y: 600, width: 100, height: 50),
        design: design,
        others: const <ElementBox>[
          ElementBox(x: 400, y: 200, width: 100, height: 100),
        ],
      );

      expect(outcome.hasGuides, isFalse);
      expect(outcome.box.x, 200);
      expect(outcome.box.y, 600);
    });

    test('الحدّ الفاصل: 6 وحدات تلتصق و7 لا تلتصق', () {
      final SnapOutcome at6 = SmartGuides.snap(
        box: const ElementBox(x: 306, y: 600, width: 100, height: 50),
        design: design,
        others: const <ElementBox>[
          ElementBox(x: 300, y: 200, width: 100, height: 100),
        ],
      );
      expect(at6.box.x, 300);
      expect(at6.hasGuides, isTrue);

      final SnapOutcome at7 = SmartGuides.snap(
        box: const ElementBox(x: 307, y: 600, width: 100, height: 50),
        design: design,
        others: const <ElementBox>[
          ElementBox(x: 300, y: 200, width: 100, height: 100),
        ],
      );
      expect(at7.hasGuides, isFalse);
      expect(at7.box.x, 307);
    });
  });

  test('بلا أهداف قريبة: لا خطوط ولا إزاحة', () {
    final SnapOutcome outcome = SmartGuides.snap(
      box: const ElementBox(x: 200, y: 600, width: 100, height: 40),
      design: design,
    );
    expect(outcome.hasGuides, isFalse);
    expect(outcome.box.x, 200);
    expect(outcome.box.y, 600);
  });

  test('منتصف العنصر على مركز اللوحة بلا إزاحة يُظهر خطاً', () {
    final SnapOutcome outcome = SmartGuides.snap(
      box: const ElementBox(x: 450, y: 600, width: 100, height: 40),
      design: design,
    );
    expect(outcome.box.x, 450);
    expect(outcome.guides.length, 1);
    expect(outcome.guides.single.vertical, isTrue);
    expect(outcome.guides.single.position, 500);
  });
}
