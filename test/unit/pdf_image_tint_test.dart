import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:joodcraft/core/models/template_element.dart';
import 'package:joodcraft/core/pdf/pdf_image_tint.dart';

import '../support/sample_image.dart';

/// تلوين صور الـ PDF: يجب أن يطابق `BlendMode.srcIn` في اللوحة — يتبدّل لون
/// البكسلات المرسومة ويبقى الشفاف شفافاً (لا يتسرّب اللون إلى الفراغ).
void main() {
  /// صورة 2×1: بكسل شفاف تماماً ثم بكسل داكن مصمت.
  Uint8List transparentThenOpaque() {
    final img.Image image = img.Image(width: 2, height: 1, numChannels: 4);
    image.setPixelRgba(0, 0, 27, 37, 57, 0); // شفاف (اللون غير مرئي)
    image.setPixelRgba(1, 0, 27, 37, 57, 255);
    return Uint8List.fromList(img.encodePng(image));
  }

  group('tintRgbOf', () {
    test('يقرأ ‎#RRGGBB‎ وRRGGBB و‎#RGB‎', () {
      expect(tintRgbOf('#FF0000'), (255, 0, 0));
      expect(tintRgbOf('ff0000'), (255, 0, 0));
      expect(tintRgbOf('#F00'), (255, 0, 0));
      expect(tintRgbOf('#C7A26B'), (0xC7, 0xA2, 0x6B));
    });

    test('يتجاهل قناة الشفافية في ‎#AARRGGBB‎ (الشفافية من الصورة)', () {
      expect(tintRgbOf('#8012AB34'), (0x12, 0xAB, 0x34));
    });

    test('يعيد null للقيم الفارغة أو غير الصالحة', () {
      expect(tintRgbOf(null), isNull);
      expect(tintRgbOf('   '), isNull);
      expect(tintRgbOf('#12345'), isNull);
      expect(tintRgbOf('#ZZZZZZ'), isNull);
      expect(tintRgbOf('أزرق'), isNull);
    });
  });

  group('tintImageBytes', () {
    test('يستبدل لون البكسلات المرسومة ويحفظ الشفافية', () {
      final Uint8List? tinted = tintImageBytes(transparentThenOpaque(), '#FF0000');
      expect(tinted, isNotNull);

      final img.Image out = img.decodeImage(tinted!)!;
      expect(out.width, 2);

      // البكسل الشفاف لم يكتسب لوناً ولا شفافية: بقي شفافاً تماماً.
      expect(out.getPixel(0, 0).a, 0);

      // البكسل المرسوم صار بلون التلوين كاملاً.
      final img.Pixel painted = out.getPixel(1, 0);
      expect(painted.r, 255);
      expect(painted.g, 0);
      expect(painted.b, 0);
      expect(painted.a, 255);
    });

    test('صور شفافة بالكامل تبقى شفافة بعد التلوين', () {
      final img.Image clear = img.Image(width: 2, height: 2, numChannels: 4);
      final Uint8List? tinted = tintImageBytes(
        Uint8List.fromList(img.encodePng(clear)),
        '#00FF00',
      );

      expect(tinted, isNotNull);
      final img.Image out = img.decodeImage(tinted!)!;
      for (final img.Pixel pixel in out) {
        expect(pixel.a, 0, reason: 'لا يكسب الفراغ الشفاف أي لون.');
      }
    });

    test('يعيد null لبيانات ليست صورة ولا يرمي', () {
      expect(tintImageBytes(notAnImageBytes(), '#FF0000'), isNull);
    });

    test('يعيد null للون غير صالح', () {
      expect(tintImageBytes(transparentThenOpaque(), 'ليس لوناً'), isNull);
    });

    test('tintImageBytesSafely: يلوّن عند النجاح ويعيد الأصل عند الفشل', () async {
      final Uint8List source = samplePngBytes();

      expect(await tintImageBytesSafely(source, 'ليس لوناً'), source);

      final Uint8List tinted = await tintImageBytesSafely(source, '#00FF00');
      expect(tinted, isNot(source));
      final img.Image out = img.decodeImage(tinted)!;
      expect(out.getPixel(0, 0).g, 255);
      expect(out.getPixel(0, 0).a, 255);
    });
  });

  group('مفتاح الصورة المشترك مع محرّك الطباعة', () {
    ImageElement element({String? tintHex}) => ImageElement(
          id: 'img',
          box: const ElementBox(x: 0, y: 0, width: 100, height: 100),
          sourceKind: ImageSourceKind.userAsset,
          path: 'asset_1',
          tintHex: tintHex,
        );

    test('pdfImageCacheKey يطابق مفتاحي العنصر تماماً', () {
      expect(
        pdfImageCacheKey('asset_1', ImageSourceKind.userAsset),
        element().imageKey,
      );
      expect(
        pdfImageCacheKey(
          'asset_1',
          ImageSourceKind.userAsset,
          tintHex: '  #FF0000 ',
        ),
        element(tintHex: '#FF0000').tintedImageKey,
      );
      expect(pdfImageCacheKey('a', ImageSourceKind.asset, tintHex: '  '),
          'asset:a');
    });
  });
}
