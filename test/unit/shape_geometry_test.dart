import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/models/shape_geometry.dart';
import 'package:joodcraft/core/models/template_element.dart';

/// اختبارات الهندسة النقية للأشكال — مصدر الحقيقة المشترك بين المحرر والـ PDF.
void main() {
  group('أوامر المسار الأساسية', () {
    test('المستطيل: أربع نقاط وإغلاق', () {
      final List<ShapeCommand> commands = shapeOutline(
        kind: ShapeKind.rect,
        width: 100,
        height: 50,
      );
      expect(commands, hasLength(5));
      expect(commands.first, isA<ShapeMove>());
      expect(commands.last, isA<ShapeClose>());
    });

    test('المستطيل المنحني يستخدم منحنيات تكعيبية', () {
      final List<ShapeCommand> commands = shapeOutline(
        kind: ShapeKind.rect,
        width: 120,
        height: 80,
        cornerRadii: const <double>[20, 10, 0, 0],
      );
      expect(commands.whereType<ShapeCubic>(), isNotEmpty);
      expect(commands.last, isA<ShapeClose>());
    });

    test('البيضاوي: أربعة منحنيات تكعيبية مغلقة', () {
      final List<ShapeCommand> commands = shapeOutline(
        kind: ShapeKind.ellipse,
        width: 100,
        height: 60,
      );
      expect(commands.whereType<ShapeCubic>().length, 4);
      expect(commands.first, isA<ShapeMove>());
      expect(commands.last, isA<ShapeClose>());
    });

    test('الخط: حركة وخط أفقي في منتصف الارتفاع', () {
      final List<ShapeCommand> commands = shapeOutline(
        kind: ShapeKind.line,
        width: 90,
        height: 20,
      );
      expect(commands, hasLength(2));
      final ShapeMove move = commands.first as ShapeMove;
      final ShapeLine line = commands.last as ShapeLine;
      expect(move.y, 10);
      expect(line.x, 90);
      expect(line.y, 10);
    });

    test('النجمة الخماسية: عشرة رؤوس (خارجي/داخلي) وإغلاق', () {
      final List<ShapeCommand> commands = shapeOutline(
        kind: ShapeKind.star,
        width: 100,
        height: 100,
        points: 5,
        innerRadius: 0.5,
      );
      // 10 نقاط → حركة + 9 خطوط + إغلاق.
      expect(commands, hasLength(11));
      expect(commands.whereType<ShapeLine>().length, 9);
      expect(commands.last, isA<ShapeClose>());
    });

    test('المضلّع السداسي: ست رؤوس', () {
      final List<ShapeCommand> commands = shapeOutline(
        kind: ShapeKind.polygon,
        width: 80,
        height: 80,
        points: 6,
      );
      expect(commands.whereType<ShapeLine>().length, 5);
    });

    test('عدد الرؤوس يُقيَّد في المدى 3..60', () {
      final List<ShapeCommand> tooFew = shapeOutline(
        kind: ShapeKind.polygon,
        width: 50,
        height: 50,
        points: 1,
      );
      // 3 أضلاع → 3 خطوط.
      expect(tooFew.whereType<ShapeLine>().length, 2);
    });

    test('التدوير الموضعي يغيّر الإحداثيات', () {
      final List<ShapeCommand> straight = shapeOutline(
        kind: ShapeKind.rect,
        width: 100,
        height: 50,
      );
      final List<ShapeCommand> rotated = shapeOutline(
        kind: ShapeKind.rect,
        width: 100,
        height: 50,
        rotationDeg: 90,
      );
      final ShapeLine a = straight[1] as ShapeLine;
      final ShapeLine b = rotated[1] as ShapeLine;
      expect(b.x, isNot(closeTo(a.x, 0.001)));
    });
  });

  group('محور التدرّج', () {
    test('زاوية 0: من أعلى إلى أسفل في المنتصف أفقياً', () {
      final ({double sx, double sy, double ex, double ey}) axis =
          gradientAxis(100, 100, 0);
      expect(axis.sx, closeTo(50, 0.001));
      expect(axis.ex, closeTo(50, 0.001));
      expect(axis.sy, lessThan(axis.ey));
    });

    test('زاوية 90: من اليسار إلى اليمين', () {
      final ({double sx, double sy, double ex, double ey}) axis =
          gradientAxis(100, 100, 90);
      expect(axis.sx, lessThan(axis.ex));
      expect(axis.sy, closeTo(axis.ey, 0.001));
    });
  });
}
