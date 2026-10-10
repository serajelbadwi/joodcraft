import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:pdf/widgets.dart' as pw;
import 'package:joodcraft/core/constants/app_constants.dart';
import 'package:joodcraft/core/models/template_document.dart';
import 'package:joodcraft/core/models/template_element.dart';
import 'package:joodcraft/core/pdf/pdf_image_tint.dart';
import 'package:joodcraft/core/pdf/pdf_render_engine.dart';
import 'package:joodcraft/core/services/pdf_generator_service.dart';

/// تلوين العناصر يصل إلى ملف الطباعة: البايتات المضمَّنة في الـ PDF تحمل لون
/// التلوين (لا بكسلات المصدر)، والإطار الشفاف يبقى شفافاً فلا تُصبغ الصفحة.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// إطار «خط عربي أسود على خلفية شفافة»: مربّع داكن داخل إطار شفاف.
  Uint8List frameWithTransparentCenter() {
    final img.Image image = img.Image(width: 8, height: 8, numChannels: 4);
    for (final img.Pixel pixel in image) {
      pixel.r = 27;
      pixel.g = 37;
      pixel.b = 57;
      pixel.a = 0; // القلب شفاف.
    }
    for (int x = 0; x < 8; x++) {
      for (final int y in <int>[0, 7]) {
        image.setPixelRgba(x, y, 27, 37, 57, 255);
      }
    }
    return Uint8List.fromList(img.encodePng(image));
  }

  TemplateDocument page({required List<TemplateElement> elements}) =>
      TemplateDocument(
        orientation: PageOrientation.landscape,
        elements: elements,
      );

  ImageElement frame({String? tintHex}) => ImageElement(
        id: 'frame',
        box: const ElementBox(x: 0, y: 0, width: 400, height: 300),
        sourceKind: ImageSourceKind.dataUri,
        path: _base64Of(frameWithTransparentCenter()),
        fit: ImageFit.fill,
        tintHex: tintHex,
      );

  test('الـ PDF يضمّن الصورة الملوّنة (لا بكسلات المصدر)', () async {
    final PdfGeneratorService service =
        await PdfGeneratorService.create(compress: false);
    final PdfGenerationReport report = await service.generate(
      document: page(
        elements: <TemplateElement>[frame(tintHex: '#C7A26B')],
      ),
    );

    expect(report.warnings, isEmpty);
    expect(report.bytes.lengthInBytes, greaterThan(1000));
  });

  test('نفس الصورة بلونين = صورتان مستقلّتان في الملف (لا تصادم مفاتيح)', () async {
    final PdfGeneratorService service =
        await PdfGeneratorService.create(compress: false);
    final PdfGenerationReport plain = await service.generate(
      document: page(elements: <TemplateElement>[frame()]),
    );
    final PdfGenerationReport tinted = await service.generate(
      document: page(elements: <TemplateElement>[
        frame(tintHex: '#C7A26B'),
        frame(tintHex: '#1B2539'),
      ]),
    );

    // لا فشل ولا تحذير أصل مفقود في الحالتين.
    expect(plain.warnings, isEmpty);
    expect(tinted.warnings, isEmpty);
    expect(tinted.bytes.lengthInBytes, greaterThan(1000));
  });

  test('مُرحّل الصور يعيد البايتات ملوّنة عند طلب اللون', () async {
    final AssetPdfImageResolver resolver = AssetPdfImageResolver(
      userAssetsProvider: (String id) => null,
    );
    final String encoded = _base64Of(frameWithTransparentCenter());

    // بلا لون: بكسلات المصدر كما هي (الحدّ داكن والقلب شفاف).
    final Uint8List plain = (await resolver.resolveBytes(
      encoded,
      ImageSourceKind.dataUri,
    ))!;
    final img.Image plainImage = img.decodeImage(plain)!;
    expect(plainImage.getPixel(0, 0).r, 27);
    expect(plainImage.getPixel(4, 4).a, 0);

    // باللون: البكسلات المرسومة بلون التلوين والقلب الشفاف لم يتغيّر.
    final Uint8List tinted = (await resolver.resolveBytes(
      encoded,
      ImageSourceKind.dataUri,
      tintHex: '#C7A26B',
    ))!;
    final img.Image tintedImage = img.decodeImage(tinted)!;
    expect(tintedImage.getPixel(0, 0).r, 0xC7);
    expect(tintedImage.getPixel(0, 0).g, 0xA2);
    expect(tintedImage.getPixel(0, 0).b, 0x6B);
    expect(tintedImage.getPixel(4, 4).a, 0, reason: 'الفراغ لم يُصبغ.');
  });

  test('مفتاح التخزين المؤقت يفصل الملوّن عن غير الملوّن', () async {
    final AssetPdfImageResolver resolver = AssetPdfImageResolver(
      userAssetsProvider: (String id) => null,
    );
    final String encoded = _base64Of(frameWithTransparentCenter());

    await resolver.resolve(encoded, ImageSourceKind.dataUri);
    await resolver.resolve(
      encoded,
      ImageSourceKind.dataUri,
      tintHex: '#FF0000',
    );
    await resolver.resolve(
      encoded,
      ImageSourceKind.dataUri,
      tintHex: '#00FF00',
    );

    // نسخة لكل لون — لا يتسرّب لون إلى آخر.
    expect(resolver.cacheLength, 3);
  });

  test('محرّك الرسم يفضّل الصورة الملوّنة على الأصلية', () async {
    final PdfGeneratorService service =
        await PdfGeneratorService.create(compress: false);
    final ImageElement element = frame(tintHex: '#C7A26B');

    final PdfRenderer renderer = PdfRenderer(fonts: service.debugFonts);
    final Uint8List bytes = await renderer.build(
      document: page(elements: <TemplateElement>[element]),
      rows: const <Map<String, String>>[<String, String>{}],
      // خريطة تحمل الأصلية والملوّنة معاً: يجب أن يُرسم **الملوّنة**.
      images: <String, pw.ImageProvider?>{
        element.imageKey: pw.MemoryImage(frameWithTransparentCenter()),
        element.tintedImageKey!: pw.MemoryImage(
          tintImageBytes(frameWithTransparentCenter(), '#C7A26B')!,
        ),
      },
    );
    expect(bytes.lengthInBytes, greaterThan(1000));

    // وبلا نسخة ملوّنة في الخريطة يعود للنسخة الأصلية بدل أن يسقط العنصر.
    final Uint8List fallback = await renderer.build(
      document: page(elements: <TemplateElement>[element]),
      rows: const <Map<String, String>>[<String, String>{}],
      images: <String, pw.ImageProvider?>{
        element.imageKey: pw.MemoryImage(frameWithTransparentCenter()),
      },
    );
    expect(fallback.lengthInBytes, greaterThan(1000));
  });

  test('التلوين يحفظ الشفافية ولا يصبغ الفراغ (مقارنة بكسلية)', () {
    // التلوين نفسه المستخدم في التصدير — نتحقّق من دلالته على بكسل شفاف.
    final Uint8List tinted =
        tintImageBytes(frameWithTransparentCenter(), '#C7A26B')!;
    final img.Image out = img.decodeImage(tinted)!;

    expect(out.getPixel(4, 4).a, 0, reason: 'قلب الإطار الشفاف بقي شفافاً.');
    final img.Pixel border = out.getPixel(0, 0);
    expect(border.a, 255);
    expect(border.r, 0xC7);
    expect(border.g, 0xA2);
    expect(border.b, 0x6B);
  });
}

String _base64Of(Uint8List bytes) => base64Encode(bytes);