import 'dart:convert' show base64Encode, latin1;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:joodcraft/core/constants/app_constants.dart';
import 'package:joodcraft/core/models/template_document.dart';
import 'package:joodcraft/core/models/template_element.dart';
import 'package:joodcraft/core/pdf/pdf_image_adjust.dart';
import 'package:joodcraft/core/pdf/pdf_render_engine.dart';
import 'package:joodcraft/core/services/pdf_generator_service.dart';

/// اختبارات **تماسك الطباعة مع لوحة التأثيرات**:
/// * طبقات التوهّج الخارجي للنص وطبقات التوسيع تُحسب بدوال نقية قابلة للفحص.
/// * الضبط اللوني للصورة يُعالَج فعلاً على البكسلات قبل التضمين (مصفوفات
///   الألوان غير مدعومة في حزمة `pdf`).
/// * الملف الناتج يحمل الأثر (أكبر/مختلف عن ملف بلا تأثير).
void main() {
  late PdfGeneratorService service;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    service = await PdfGeneratorService.create(
      compress: false,
      useIsolate: false,
    );
  });

  /// صورة PNG صغيرة بلون واحد حقيقي (للتحقّق من البكسلات).
  Uint8List solidPng({int r = 200, int g = 100, int b = 50}) {
    final img.Image image = img.Image(width: 4, height: 4);
    img.fill(image, color: img.ColorRgb8(r, g, b));
    return img.encodePng(image);
  }

  group('معالجة بكسلات الضبط اللوني', () {
    test('الحياد لا يعالج شيئاً (يعيد الأصل)', () async {
      final Uint8List source = solidPng();
      expect(adjustImageBytes(source, ElementAdjustments.none), isNull);
      final Uint8List safe =
          await adjustImageBytesSafely(source, ElementAdjustments.none);
      expect(identical(safe, source), isTrue);
      final Uint8List none =
          await adjustImageBytesSafely(source, const ElementAdjustments());
      expect(identical(none, source), isTrue);
    });

    test('السطوع يرفع القنوات فعلاً في البكسلات', () async {
      final Uint8List source = solidPng();
      final Uint8List bright = await adjustImageBytesSafely(
        source,
        const ElementAdjustments(brightness: 0.5),
      );
      expect(bright, isNot(source));

      final img.Pixel before = img.decodeImage(source)!.getPixel(1, 1);
      final img.Pixel after = img.decodeImage(bright)!.getPixel(1, 1);
      expect(after.g, greaterThan(before.g));
      expect(after.b, greaterThan(before.b));
      expect(after.r, greaterThanOrEqualTo(before.r));
      expect(after.r, lessThanOrEqualTo(255));
    });

    test('التشبّع السالب الكامل يجعل الصورة رمادية', () async {
      final Uint8List gray = await adjustImageBytesSafely(
        solidPng(r: 200, g: 40, b: 10),
        const ElementAdjustments(saturation: -1),
      );
      final img.Pixel pixel = img.decodeImage(gray)!.getPixel(1, 1);
      expect((pixel.r - pixel.g).abs(), lessThanOrEqualTo(2));
      expect((pixel.g - pixel.b).abs(), lessThanOrEqualTo(2));
    });

    test('النص المدوّر لونياً يغيّر القنوات فعلاً', () async {
      final Uint8List source = solidPng(r: 255, g: 0, b: 0);
      final Uint8List rotated = await adjustImageBytesSafely(
        source,
        const ElementAdjustments(hue: 120),
      );
      final img.Pixel after = img.decodeImage(rotated)!.getPixel(1, 1);
      expect(after.g, greaterThan(after.r));
    });
  });

  group('طبقات التوهّج والتوسيع في الـ PDF', () {
    test('التوهّج غير المرئي لا يضيف أي طبقة', () {
      expect(pdfTextGlowLayers(null, 1), isEmpty);
      expect(
        pdfTextGlowLayers(const GlowEffect(opacity: 0), 1),
        isEmpty,
        reason: 'شفافية صفر = توهّج مطفأ',
      );
      expect(
        pdfTextGlowLayers(const GlowEffect(radius: 0, spread: 0), 1),
        isEmpty,
      );
    });

    test('التوهّج يبني طبقة مركزية + حلقة تمويه + حلقة توسيع', () {
      final List<PdfTextShadowLayer> layers = pdfTextGlowLayers(
        const GlowEffect(radius: 8, spread: 4, opacity: 1),
        1,
      );
      // مركزية + أربع للتمويه + أربع للتوسيع.
      expect(layers, hasLength(9));
      expect(layers.first.dx, 0);
      expect(layers.first.dy, 0);
      final PdfTextShadowLayer spreadLayer =
          layers.lastWhere((PdfTextShadowLayer l) => l.dx != 0 && l.dy == 0);
      expect(spreadLayer.dx.abs(), 4, reason: 'إزاحة التوسيع الفعلية');
      expect(layers.every((PdfTextShadowLayer l) => l.opacity > 0), isTrue);
      expect(layers.every((PdfTextShadowLayer l) => l.opacity <= 1), isTrue);
    });

    test('التوسيع يضيف حلقة إلى طبقات ظل النص', () {
      final List<PdfTextShadowLayer> plain =
          pdfTextShadowLayers(const TextShadow(blurRadius: 0), 1);
      expect(plain, hasLength(1));

      final List<PdfTextShadowLayer> spread = pdfTextShadowLayers(
        const TextShadow(offsetX: 0, offsetY: 0, blurRadius: 0, spread: 6),
        1,
      );
      expect(spread, hasLength(9), reason: 'الأصلية + ثمانية إزاحات توسيع');
      for (final PdfTextShadowLayer layer in spread.skip(1)) {
        expect(layer.dx.abs() <= 6 && layer.dy.abs() <= 6, isTrue);
        expect(layer.dx.abs() + layer.dy.abs(), greaterThan(0));
      }
    });

    test('كل الطبقات مقيَّسة بالمقياس المطلوب', () {
      final List<PdfTextShadowLayer> layers = pdfTextShadowLayers(
        const TextShadow(offsetX: 0, offsetY: 0, blurRadius: 0, spread: 3),
        2,
      );
      // التوسيع 3×2 = 6 نقاط طباعة.
      expect(
        layers.map((PdfTextShadowLayer l) => l.dx).contains(6),
        isTrue,
      );
    });
  });

  group('أثر التأثير في ملف الـ PDF', () {
    TemplateDocument textDoc({GlowEffect? glow}) => TemplateDocument(
          orientation: PageOrientation.landscape,
          elements: <TemplateElement>[
            TextElement(
              id: 'title',
              box: const ElementBox(x: 40, y: 40, width: 500, height: 90),
              text: 'شهادة متوهّجة',
              fontSize: 26,
              outerGlow: glow,
            ),
          ],
        );

    test('توهّج النص يُرسم في الملف (نسخ إضافية)', () async {
      final PdfGenerationReport plain =
          await service.generate(document: textDoc());
      final PdfGenerationReport glowing = await service.generate(
        document: textDoc(
          glow: const GlowEffect(colorHex: '#FFD166', radius: 10, spread: 3),
        ),
      );

      expect(latin1.decode(plain.bytes).startsWith('%PDF-'), isTrue);
      expect(latin1.decode(glowing.bytes).startsWith('%PDF-'), isTrue);
      expect(
        glowing.bytes.length,
        greaterThan(plain.bytes.length),
        reason: 'طبقات التوهّج تضيف محتوى فعلياً',
      );
    });

    test('ضبط الصورة اللوني يصل إلى الملف (نسخة معالجة)', () async {
      final Uint8List png = solidPng();
      final String base64Image = base64Encode(png);

      TemplateDocument imageDoc({ElementAdjustments? adjustments}) =>
          TemplateDocument(
            orientation: PageOrientation.landscape,
            elements: <TemplateElement>[
              ImageElement(
                id: 'img',
                box: const ElementBox(x: 40, y: 40, width: 300, height: 200),
                sourceKind: ImageSourceKind.dataUri,
                path: base64Image,
                adjustments: adjustments,
              ),
            ],
          );

      final PdfGenerationReport plain =
          await service.generate(document: imageDoc());
      final PdfGenerationReport adjusted = await service.generate(
        document: imageDoc(
          adjustments: const ElementAdjustments(brightness: 0.4),
        ),
      );

      expect(plain.bytes, isNotEmpty);
      expect(adjusted.bytes, isNotEmpty);
      expect(
        adjusted.bytes,
        isNot(plain.bytes),
        reason: 'البكسلات المعالجة تُضمَّن فعلاً في الملف',
      );
    });
  });
}
