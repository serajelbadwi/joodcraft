import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' show Rect;

import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/assets/asset_store.dart';
import 'package:joodcraft/core/assets/assets_controller.dart';
import 'package:joodcraft/core/assets/user_asset.dart';
import 'package:image/image.dart' as im;
import 'package:joodcraft/core/constants/app_constants.dart';
import 'package:joodcraft/core/models/template_document.dart';
import 'package:joodcraft/core/models/template_element.dart';
import 'package:joodcraft/core/pdf/pdf_gradient.dart';
import 'package:joodcraft/core/pdf/pdf_quality_image.dart';
import 'package:joodcraft/core/services/pdf_generator_service.dart';
import 'package:pdf/pdf.dart';

/// دقّة التصدير المصفوفية (‎1:1‎ مع الشاشة)، ومعالجة التدرّجات
/// والصور عالية الدقة (Anti-Banding / Anti-Moiré) في ملف الـ PDF.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  String rawPdf(Uint8List bytes) => latin1.decode(bytes, allowInvalid: true);

  // ---------------------------------------------------------------------------
  //  1) العقيدة المصفوفية: ‎1 Pt = 1 Screen Point‎ بلا إعادة حساب
  // ---------------------------------------------------------------------------
  group('العقد المصفوفي الموحّد (1:1 Matrix Mapping)', () {
    test('وحدة التصميم = بكسل 96dpi، ومعاملها 72/96 نقطة', () {
      expect(TemplateDocument.designDpi, 96);
      expect(TemplateDocument.ptPerDesignUnit, closeTo(72 / 96, 1e-12));
    });

    test('الورقة الافتراضية: المعامل هو نفسه بلا تحجيم ولا إزاحة', () {
      final TemplateDocument document = const TemplateDocument(
        orientation: PageOrientation.landscape,
        elements: <TemplateElement>[],
      );
      expect(document.scale, closeTo(TemplateDocument.ptPerDesignUnit, 1e-12));
      expect(document.offsetX, closeTo(0, 1e-12));
      expect(document.offsetY, closeTo(0, 1e-12));
    });

    test('صندوق يغطّي مساحة التصميم يُحوَّل إلى الورقة كاملةً بالضبط', () {
      for (final PageOrientation orientation in PageOrientation.values) {
        final TemplateDocument document = TemplateDocument(
          orientation: orientation,
          elements: const <TemplateElement>[],
        );
        final Rect rect = document.boxToPdfRect(
          ElementBox(
            x: 0,
            y: 0,
            width: document.designWidth,
            height: document.designHeight,
          ),
        );
        expect(rect.left, closeTo(0, 1e-9));
        expect(rect.top, closeTo(0, 1e-9));
        expect(rect.width, closeTo(document.pageWidthPt, 1e-9));
        expect(rect.height, closeTo(document.pageHeightPt, 1e-9));
      }
    });

    test('مقاس الخط يتبع المعامل نفسه فلا يختلف عن الشاشة', () {
      final TemplateDocument document = const TemplateDocument(
        orientation: PageOrientation.portrait,
        elements: <TemplateElement>[],
      );
      const double designFontSize = 48;
      // الخط على الشاشة: 48 وحدة تصميم ⇒ على الورق: 48 × 0.75 = 36 نقطة.
      expect(
        designFontSize * document.scale,
        closeTo(designFontSize * TemplateDocument.ptPerDesignUnit, 1e-9),
      );
      expect(designFontSize * document.scale, closeTo(36, 1e-9));
    });

    test('حجم تصميم مخصّص يحفظ النسبة نفسها من الورقة', () {
      final TemplateDocument a4 = const TemplateDocument(
        orientation: PageOrientation.portrait,
        elements: <TemplateElement>[],
      );
      // مساحة تصميم بنفس نِسَب الورقة ⇒ تحويل خالص بلا إزاحة توسيط.
      const double canvasWidth = 1000;
      final TemplateDocument document = TemplateDocument(
        orientation: PageOrientation.portrait,
        canvasWidth: canvasWidth,
        canvasHeight: canvasWidth * a4.pageHeightPt / a4.pageWidthPt,
        elements: const <TemplateElement>[],
      );
      expect(document.offsetX, closeTo(0, 1e-9));
      expect(document.offsetY, closeTo(0, 1e-9));
      final Rect rect = document.boxToPdfRect(
        const ElementBox(x: 250, y: 350, width: 100, height: 100),
      );
      // الكسر نفسه من مساحة التصميم ومن الورقة — الحجم المخصّص لا يُلغي النِسَب.
      expect(
        rect.left / document.pageWidthPt,
        closeTo(250 / document.designWidth, 1e-9),
      );
      expect(
        rect.top / document.pageHeightPt,
        closeTo(350 / document.designHeight, 1e-9),
      );
      expect(
        rect.width / document.pageWidthPt,
        closeTo(100 / document.designWidth, 1e-9),
      );
      // المربّع يبقى مربعاً: معامل واحد أفقياً ورأسياً (تحويل تشابهي).
      expect(rect.height, closeTo(rect.width, 1e-9));
    });
  });

  // ---------------------------------------------------------------------------
  //  2) سلّم التدرّج عالي الدقة + التشويش (Dithering)
  // ---------------------------------------------------------------------------
  group('سلّم التدرّج عالي الدقة', () {
    const PdfColor black = PdfColor(0, 0, 0);
    const PdfColor white = PdfColor(1, 1, 1);

    test('الطرفان دقيقان تماماً وبلا تشويش', () {
      final List<PdfColor> ramp = pdfGradientRamp(black, white);
      expect(ramp.first.red, 0);
      expect(ramp.first.green, 0);
      expect(ramp.first.blue, 0);
      expect(ramp.last.red, 1);
      expect(ramp.last.green, 1);
      expect(ramp.last.blue, 1);
    });

    test('عدد العيّنات كثيف (64 افتراضاً) فلا تبقى خطوط تكميم', () {
      expect(pdfGradientSamples, 64);
      expect(pdfGradientRamp(black, white).length, pdfGradientSamples);
      expect(
        pdfGradientRamp(black, white, samples: 8).length,
        8,
      );
      // سلّم من أقل من عيّنتين يُرفع إلى عيّنتين (لا سلّم بلا نهاية).
      expect(pdfGradientRamp(black, white, samples: 1).length, 2);
    });

    test('العيّنات الداخلية تنحرف عن الخط المستقيم بمقدار نصف خطوة 8-بت', () {
      final List<PdfColor> ramp = pdfGradientRamp(black, white);
      double maxDeviation = 0;
      for (int i = 1; i < ramp.length - 1; i++) {
        final double exact = i / (ramp.length - 1);
        final double deviation = (ramp[i].red - exact).abs();
        if (deviation > maxDeviation) maxDeviation = deviation;
      }
      // تشويش فعلي (لا صفر) لكن محدود بنصف خطوة التكميم ‎0.5/255‎.
      expect(maxDeviation, greaterThan(0));
      expect(maxDeviation, lessThanOrEqualTo(0.5 / 255 + 1e-12));
    });

    test('التشويش متمركز حول الصفر فلا ينحرف اللون المتوقّع', () {
      final List<PdfColor> ramp = pdfGradientRamp(black, white);
      double sum = 0;
      for (int i = 1; i < ramp.length - 1; i++) {
        final double exact = i / (ramp.length - 1);
        sum += ramp[i].red - exact;
      }
      expect(sum.abs() / (ramp.length - 2), lessThan(0.5 / 255 * 0.5));
    });

    test('حتمي تماماً: الملف نفسه في كل تصدير (لا Random)', () {
      expect(
        pdfGradientRamp(black, white),
        equals(pdfGradientRamp(black, white)),
      );
      expect(pdfDitherOffset(7, 0), pdfDitherOffset(7, 0));
      expect(pdfDitherOffset(7, 0), isNot(pdfDitherOffset(7, 1)));
    });

    test('التشويش يمكن إطفاؤه فيعود استيفاءً خطّياً دقيقاً', () {
      final List<PdfColor> ramp =
          pdfGradientRamp(black, white, dither: false);
      for (int i = 0; i < ramp.length; i++) {
        expect(ramp[i].red, closeTo(i / (ramp.length - 1), 1e-12));
      }
    });

    test('إزاحة التشويش محدودة ومتوسّطها صفر على المدى الطويل', () {
      final double limit = 0.5 / 255;
      double sum = 0;
      const int count = 4000;
      for (int i = 0; i < count; i++) {
        final double offset = pdfDitherOffset(i, 1);
        expect(offset.abs(), lessThanOrEqualTo(limit + 1e-12));
        sum += offset;
      }
      expect((sum / count).abs(), lessThan(limit * 0.05));
    });
  });

  // ---------------------------------------------------------------------------
  //  3) ملف الـ PDF: تدرّج متجهي مضغوط بلا فقدان، وبلا رسترة للخلفية
  // ---------------------------------------------------------------------------
  group('التدرّجات والصور في ملف الـ PDF', () {
    TemplateDocument gradientDocument() => const TemplateDocument(
          orientation: PageOrientation.portrait,
          elements: <TemplateElement>[],
        ).copyWith(
          backgroundGradient: const BackgroundGradient(
            direction: GradientDirection.vertical,
            startHex: '#FFFFFF',
            endHex: '#0B1B3A',
          ),
          elements: <TemplateElement>[
            ShapeElement(
              id: 'sh',
              box: ElementBox(x: 40, y: 40, width: 300, height: 200),
              kind: ShapeKind.rect,
              gradient: ShapeGradient(
                kind: ShapeFillKind.linearGradient,
                startHex: '#FFFFFF',
                endHex: '#000000',
              ),
              fillOpacity: 0.5,
            ),
          ],
        );

    test('خلفية التدرّج تبقى متجهة ولا تُرستر إلى صورة', () async {
      final PdfGeneratorService service =
          await PdfGeneratorService.create(compress: false);
      final PdfGenerationReport report =
          await service.generate(document: gradientDocument());
      final String raw = rawPdf(report.bytes);

      expect(report.warnings, isEmpty);
      // تظليل متجهي (axial) للخلفية وللشكل: لا صورة واحدة في الملف.
      expect('/ShadingType 2'.allMatches(raw).length, 2);
      expect('/AntiAlias true'.allMatches(raw).length, 2);
      expect(raw.contains('Subtype/Image'), isFalse);
    });

    test('كل تدرّج يُصدَّر بـ64 عيّنة عبر دالة تنعيم واحدة', () async {
      final PdfGeneratorService service =
          await PdfGeneratorService.create(compress: false);
      final PdfGenerationReport report =
          await service.generate(document: gradientDocument());
      final String raw = rawPdf(report.bytes);

      // كان قبل ذلك عيّنتين فقط؛ الآن 64 عيّنة مُشوَّشة لكل تدرّج.
      expect('/Size[64]'.allMatches(raw).length, 2);
      expect('/FunctionType 0'.allMatches(raw).length, 2);
    });

    test('شفافية التعبئة تُصدَّر عبر حالة رسوم (ExtGState) لا بألفا مهملة',
        () async {
      final PdfGeneratorService service =
          await PdfGeneratorService.create(compress: false);
      final PdfGenerationReport report =
          await service.generate(document: gradientDocument());
      final String raw = rawPdf(report.bytes);

      expect(raw.contains('/ExtGState'), isTrue);
      expect(raw.contains('/ca 0.5'), isTrue);
    });

    test('الصور تُضمَّن بلا فقدان (لا ضغط JPEG) حتى مع الضغط مفعّلاً',
        () async {
      final AssetsController controller =
          AssetsController(store: InMemoryAssetStore());
      AssetsController.instance = controller;
      await controller.addAsset(
        type: AssetType.border,
        name: 'تدرّج',
        fileName: 'gradient.png',
        bytes: im.encodePng(_gradientImage(180, 180)),
      );
      final UserAsset asset = controller.byType(AssetType.border).single;

      final TemplateDocument document = const TemplateDocument(
        orientation: PageOrientation.portrait,
        elements: <TemplateElement>[],
      ).copyWith(
        elements: <TemplateElement>[
          ImageElement(
            id: 'img',
            box: const ElementBox(x: 40, y: 40, width: 200, height: 200),
            sourceKind: ImageSourceKind.userAsset,
            path: asset.id,
            fit: ImageFit.fill,
          ),
        ],
      );

      final PdfGeneratorService service =
          await PdfGeneratorService.create(compress: true);
      final PdfGenerationReport report = await service.generate(
        document: document,
      );
      final String raw = rawPdf(report.bytes);

      expect(report.warnings, isEmpty);
      expect(raw.contains('Subtype/Image'), isTrue);
      // غير متلف: FlateDecode لا DCTDecode (الذي يُنتج هالات فقدانية).
      expect(raw.contains('DCTDecode'), isFalse);
      expect(raw.contains('FlateDecode'), isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  //  4) إعادة التحجيم: متوسط المساحة يقتل المواريه
  // ---------------------------------------------------------------------------
  group('إعادة تحجيم الصور للطباعة', () {
    test('التصغير بمتوسط المساحة يُنتج لوناً موحّداً لا مواريه', () {
      final im.Image checker = _checkerboard(120, 120);
      final im.Image resized = pdfResampleForPrint(checker, 20);

      expect(resized.width, 20);
      expect(resized.height, 20);
      final (int min, int max) = _redRange(resized);
      // كل بكسل = متوسط مربّع 6×6 (18 أسود + 18 أبيض) ⇒ رمادي وسط متساوٍ.
      expect(min, greaterThanOrEqualTo(120));
      expect(max, lessThanOrEqualTo(135));
    });

    test('«أقرب جار» (السلوك القديم) يُفقد النقش ويلوّن بلون طرفي', () {
      final im.Image checker = _checkerboard(120, 120);
      final im.Image nearest = im.copyResize(
        checker,
        width: 20,
        interpolation: im.Interpolation.nearest,
      );
      final (int min, int max) = _redRange(nearest);
      // مصدر المواريه: النقش ينهار إلى لون واحد صلب (لا تفاصيل) — وهو أسوأ
      // ما يفعله التصغير في الطباعة، ويناقض نتيجة متوسط المساحة أعلاه.
      expect(max - min, lessThan(5));
      expect((min - 127).abs(), greaterThan(100));
    });

    test('التكبير يستيفي بسلاسة (تكعيبي) ويحفظ العرض المطلوب', () {
      final im.Image small = _gradientImage(40, 40);
      final im.Image upscaled = pdfResampleForPrint(small, 160);
      expect(upscaled.width, 160);
      expect(upscaled.height, 160);
    });

    test('الصورة المفهرسة تُحوَّل قبل التحجيم (لا رجوع لأقرب جار)', () {
      final im.Image indexed = im.quantize(
        _gradientImage(64, 64),
        numberOfColors: 16,
      );
      expect(indexed.hasPalette, isTrue);

      final im.Image resized = pdfResampleForPrint(indexed, 16);
      expect(resized.hasPalette, isFalse);
      expect(resized.width, 16);
      // التحويل لا يشوّه: التدرّج الأصلي رمادي متساوٍ في القنوات.
      final im.Pixel pixel = resized.getPixel(8, 8);
      expect((pixel.r - pixel.g).abs(), lessThan(3));
      expect((pixel.g - pixel.b).abs(), lessThan(3));
    });

    test('نفس العرض لا يُعاد تحجيمه إطلاقاً (بلا فقدان)', () {
      final im.Image source = _gradientImage(50, 50);
      expect(identical(pdfResampleForPrint(source, 50), source), isTrue);
    });
  });
}

/// لوح شطرنجي بأعلى تردّد ممكن (بكسل أسود/أبيض بالتناوب) — أصعب حالة مواريه.
im.Image _checkerboard(int width, int height) {
  final im.Image image = im.Image(
    width: width,
    height: height,
    numChannels: 4,
  );
  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      final int value = (x + y).isEven ? 0 : 255;
      image.setPixelRgba(x, y, value, value, value, 255);
    }
  }
  return image;
}

/// تدرّج رمادي ناعم (رمادي متساوٍ في القنوات) — يقيس انزياح اللون.
im.Image _gradientImage(int width, int height) {
  final im.Image image = im.Image(
    width: width,
    height: height,
    numChannels: 4,
  );
  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      final int value = (x * 255 / (width - 1)).round().clamp(0, 255);
      image.setPixelRgba(x, y, value, value, value, 255);
    }
  }
  return image;
}

/// أدنى وأقصى قيمة للقناة الحمراء في صورة.
(int, int) _redRange(im.Image image) {
  int min = 255;
  int max = 0;
  for (int y = 0; y < image.height; y++) {
    for (int x = 0; x < image.width; x++) {
      final int value = image.getPixel(x, y).r.toInt();
      if (value < min) min = value;
      if (value > max) max = value;
    }
  }
  return (min, max);
}
