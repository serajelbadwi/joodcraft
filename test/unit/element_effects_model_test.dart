import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/models/template_element.dart';

/// اختبارات نموذج **التأثيرات** (Prompt 1.4):
/// التوهّج (خارجي/داخلي)، الضبط اللوني ومصفوفة ألوانه، وحقلا الظل الجديدان
/// (توسيع النص، وشفافية الشكل) — مع دورات JSON لكل منها.
void main() {
  /// يطبّق مصفوفة ألوان (4×5) على لون ثم يرجع قنواته في المجال 0..255.
  (double, double, double) applyMatrix(List<double> m, double r, double g, double b) {
    double row(int i) =>
        m[i * 5] * r + m[i * 5 + 1] * g + m[i * 5 + 2] * b + m[i * 5 + 4];
    double clamp01(double v) => v < 0 ? 0 : (v > 255 ? 255 : v);
    return (clamp01(row(0)), clamp01(row(1)), clamp01(row(2)));
  }

  group('مصفوفة الضبط اللوني', () {
    test('الحياد يعطي مصفوفة الوحدة تماماً', () {
      final List<double> matrix = ElementAdjustments.none.toMatrix();
      expect(matrix, hasLength(20));
      const List<double> identity = <double>[
        1, 0, 0, 0, 0, //
        0, 1, 0, 0, 0, //
        0, 0, 1, 0, 0, //
        0, 0, 0, 1, 0, //
      ];
      for (int i = 0; i < 20; i++) {
        expect(matrix[i], closeTo(identity[i], 1e-9), reason: 'العنصر $i');
      }
      expect(ElementAdjustments.none.isIdentity, isTrue);
      expect(ElementAdjustments.none.key, isEmpty);
    });

    test('السطوع يُزحزح القنوات فقط دون تغيير الميل', () {
      final List<double> m =
          const ElementAdjustments(brightness: 0.5).toMatrix();
      for (int row = 0; row < 3; row++) {
        expect(m[row * 5 + row], closeTo(1, 1e-9));
        expect(m[row * 5 + 4], closeTo(0.5 * 255, 1e-6));
      }
      // الأسود يصير رمادياً بقدار الزيادة، والأبيض يبقى أبيض (تشبّع عند 255).
      final (double, double, double) black =
          applyMatrix(m, 0, 0, 0);
      expect(black.$1, closeTo(127.5, 1e-6));
      final (double, double, double) white =
          applyMatrix(m, 255, 255, 255);
      expect(white.$1, 255);
    });

    test('التباين يتوسّع حول المنتصف (127.5)', () {
      final List<double> m =
          const ElementAdjustments(contrast: 1).toMatrix();
      expect(m[0], closeTo(2, 1e-9));
      expect(m[4], closeTo(-127.5, 1e-6));
      // المنتصف ثابت، والداكن يصير أداكن.
      expect(applyMatrix(m, 127.5, 127.5, 127.5).$1, closeTo(127.5, 1e-6));
      expect(applyMatrix(m, 100, 100, 100).$1, closeTo(72.5, 1e-6));
    });

    test('التشبّع يحفظ الإضاءة: كل صف يجمع إلى 1', () {
      for (final double saturation in <double>[0, 0.5, 2]) {
        final List<double> m =
            ElementAdjustments(saturation: saturation).toMatrix();
        for (int row = 0; row < 3; row++) {
          final double sum =
              m[row * 5] + m[row * 5 + 1] + m[row * 5 + 2];
          expect(sum, closeTo(1, 1e-9), reason: 'صف $row');
        }
      }
      // رمادي بلا تشبّع يبقى رمادياً (لا يتلوّن).
      final List<double> gray =
          const ElementAdjustments(saturation: -1).toMatrix();
      final (double, double, double) mid = applyMatrix(gray, 128, 128, 128);
      expect(mid.$1, closeTo(128, 1e-6));
      expect(mid.$2, closeTo(128, 1e-6));
      expect(mid.$3, closeTo(128, 1e-6));
    });

    test('تدوير اللون 120° ينقل الأحمر إلى الأخضر (مصفوفة SVG القياسية)', () {
      final List<double> m = const ElementAdjustments(hue: 120).toMatrix();
      final (double, double, double) red = applyMatrix(m, 255, 0, 0);
      expect(red.$2, greaterThan(red.$1));
      expect(red.$2, greaterThan(red.$3));
      // الأخضر المتوقّع ≈ 0.443 من شدة الأحمر الأصلية.
      expect(red.$2, closeTo(0.4433 * 255, 1));
      // ‎-120° على الأحمر يعطي أزرق متقدّماً على الأخضر.
      final (double, double, double) blue = applyMatrix(
        const ElementAdjustments(hue: -120).toMatrix(),
        255,
        0,
        0,
      );
      expect(blue.$3, greaterThan(blue.$2));
    });
  });

  group('نموذج التوهّج', () {
    test('العتبات: بلا تمويه ولا توسيع لا توهّج مرئي', () {
      expect(const GlowEffect().isVisible, isTrue);
      expect(const GlowEffect(radius: 0).isVisible, isFalse);
      expect(const GlowEffect(radius: 0, spread: 4).isVisible, isTrue);
      expect(const GlowEffect(opacity: 0).isVisible, isFalse);
    });

    test('copyWith يغيّر حقلاً واحداً ويحفظ البقية', () {
      const GlowEffect glow = GlowEffect(
        colorHex: '#00FF00',
        radius: 12,
        spread: 3,
        opacity: 0.4,
      );
      final GlowEffect next = glow.copyWith(radius: 20);
      expect(next.radius, 20);
      expect(next.colorHex, '#00FF00');
      expect(next.spread, 3);
      expect(next.opacity, 0.4);
    });

    test('دورة JSON كاملة مع القيم غير الافتراضية', () {
      const GlowEffect glow = GlowEffect(
        colorHex: '#FF00AA',
        radius: 15,
        spread: 5,
        opacity: 0.25,
      );
      final GlowEffect? restored = GlowEffect.fromJson(glow.toJson());
      expect(restored, glow);
      expect(restored!.colorHex, '#FF00AA');
      expect(restored.radius, 15);
      expect(restored.spread, 5);
      expect(restored.opacity, 0.25);
      // القيم الافتراضية لا تُكتب في الملف.
      expect(const GlowEffect().toJson().containsKey('radius'), isFalse);
      expect(const GlowEffect().toJson().containsKey('spread'), isFalse);
      // وقيم خارج الحدود تُضبط.
      expect(
        GlowEffect.fromJson(<String, dynamic>{'opacity': 5})!.opacity,
        1,
      );
      expect(GlowEffect.fromJson(<String, dynamic>{'radius': -3})!.radius, 0);
    });
  });

  group('حقول الظل الجديدة', () {
    test('ظل النص يحفظ التوسيع ويعتبره ظلاً مرئياً', () {
      const TextShadow shadow = TextShadow(
        blurRadius: 0,
        offsetX: 0,
        offsetY: 0,
        spread: 6,
      );
      expect(shadow.isVisible, isTrue);
      final TextShadow? restored = TextShadow.fromJson(shadow.toJson());
      expect(restored!.spread, 6);
      expect(restored, shadow);
    });

    test('ظل الشكل يحفظ الشفافية بدورتها', () {
      const ShapeShadow shadow = ShapeShadow(opacity: 0.3);
      expect(shadow.isVisible, isTrue);
      expect(ShapeShadow.fromJson(shadow.toJson())!.opacity, 0.3);
      expect(const ShapeShadow(opacity: 0).isVisible, isFalse);
      expect(ShapeShadow.fromJson(null), isNull);
    });
  });

  group('دورات JSON للعناصر', () {
    test('نص: التوهّجان يُحفظان ويُستعادان، وغيابهما لا يُكتب', () {
      const TextElement plain = TextElement(
        id: 't1',
        box: ElementBox(x: 0, y: 0, width: 100, height: 40),
        text: 'نص',
      );
      expect(plain.toJson().containsKey('outerGlow'), isFalse);
      expect(TextElement.fromJson(plain.toJson(), 't1').outerGlow, isNull);

      const TextElement glowing = TextElement(
        id: 't2',
        box: ElementBox(x: 0, y: 0, width: 100, height: 40),
        text: 'نص',
        outerGlow: GlowEffect(colorHex: '#FFD166', radius: 9),
        innerGlow: GlowEffect(colorHex: '#1B2539', radius: 4),
      );
      final TextElement restored =
          TextElement.fromJson(glowing.toJson(), 't2');
      expect(restored.outerGlow, glowing.outerGlow);
      expect(restored.innerGlow, glowing.innerGlow);
      expect(glowing.toJson()['outerGlow'], isA<Map<String, dynamic>>());
    });

    test('شكل: التوهّجان يدوران في JSON', () {
      const ShapeElement shape = ShapeElement(
        id: 's1',
        kind: ShapeKind.rect,
        box: ElementBox(x: 0, y: 0, width: 60, height: 60),
        fillHex: '#FFFFFF',
        outerGlow: GlowEffect(radius: 10, spread: 2),
        innerGlow: GlowEffect(colorHex: '#EF6C00', radius: 3),
      );
      final ShapeElement restored =
          ShapeElement.fromJson(shape.toJson(), 's1', ShapeKind.rect);
      expect(restored.outerGlow, shape.outerGlow);
      expect(restored.innerGlow, shape.innerGlow);
      // إزالة التوهّج بـ`copyWith(outerGlow: null)` تعمل فعلاً.
      expect(shape.copyWith(outerGlow: null).outerGlow, isNull);
    });

    test('صورة: الظل والتوهّج والضبط اللوني تُحفظ وتُستعاد', () {
      const ImageElement image = ImageElement(
        id: 'i1',
        box: ElementBox(x: 0, y: 0, width: 200, height: 100),
        sourceKind: ImageSourceKind.asset,
        path: 'assets/images/logo.png',
        shadow: ShapeShadow(colorHex: '#000000', opacity: 0.4),
        outerGlow: GlowEffect(colorHex: '#00FF00', radius: 6),
        adjustments: ElementAdjustments(
          brightness: 0.2,
          contrast: 0.1,
          hue: -30,
          saturation: 0.5,
        ),
      );
      final ImageElement restored =
          ImageElement.fromJson(image.toJson(), 'i1');
      expect(restored.shadow, image.shadow);
      expect(restored.outerGlow, image.outerGlow);
      expect(restored.adjustments, image.adjustments);
      expect(restored.hasAdjustments, isTrue);
    });

    test('ضبط حياديّ لا يُحفظ ولا يُعتبر فعّالاً', () {
      const ImageElement image = ImageElement(
        id: 'i2',
        box: ElementBox(x: 0, y: 0, width: 200, height: 100),
        sourceKind: ImageSourceKind.asset,
        path: 'a.png',
        adjustments: ElementAdjustments(brightness: 0),
      );
      expect(image.hasAdjustments, isFalse);
      expect(image.toJson().containsKey('adjust'), isFalse);
      expect(ImageElement.fromJson(image.toJson(), 'i2').adjustments, isNull);
    });

    test('مفتاح الصورة المعالجة يضمّ التلوين والضبط معاً', () {
      const ImageElement plain = ImageElement(
        id: 'i3',
        box: ElementBox(x: 0, y: 0, width: 10, height: 10),
        sourceKind: ImageSourceKind.asset,
        path: 'a.png',
      );
      expect(plain.processedImageKey, isNull);

      final ImageElement tinted = plain.copyWith(tintHex: '#112233');
      expect(tinted.processedImageKey, 'asset:a.png#112233');

      final ImageElement adjusted =
          plain.copyWith(adjustments: const ElementAdjustments(brightness: 0.5));
      expect(adjusted.processedImageKey, contains('~b0.50'));
      expect(
        adjusted.processedImageKey,
        isNot(tinted.processedImageKey),
        reason: 'الضبط والتلوين لا يتصادمان في المفتاح',
      );

      final ImageElement both = adjusted.copyWith(tintHex: '#112233');
      expect(both.processedImageKey, startsWith('asset:a.png#112233~b0.50'));
      // والضبط وحده لا يخلط التلوين في المفتاح.
      expect(adjusted.tintedImageKey, isNull);
    });
  });
}
