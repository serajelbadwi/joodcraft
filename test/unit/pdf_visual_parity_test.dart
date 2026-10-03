import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/assets/asset_store.dart';
import 'package:joodcraft/core/assets/assets_controller.dart';
import 'package:joodcraft/core/assets/user_asset.dart';
import 'package:joodcraft/core/constants/app_assets.dart';
import 'package:joodcraft/core/constants/app_constants.dart';
import 'package:joodcraft/core/editor/canvas_geometry.dart';
import 'package:joodcraft/core/fonts/custom_font_controller.dart';
import 'package:joodcraft/core/fonts/custom_font_store.dart';
import 'package:joodcraft/core/models/template_document.dart';
import 'package:joodcraft/core/models/template_element.dart';
import 'package:joodcraft/core/pdf/custom_pdf_fonts.dart';
import 'package:joodcraft/core/pdf/pdf_font_catalog.dart';
import 'package:joodcraft/core/services/pdf_generator_service.dart';

import '../support/sample_image.dart';

/// اتساق العرض بين المحرر (Canvas) ومحرّك الطباعة (PDF):
/// الأصول/الخلفيات، تضمين الخطوط المخصصة، وتحويل الإحداثيات.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AssetsController previousAssets;

  setUp(() {
    previousAssets = AssetsController.instance;
    CustomPdfFonts.clear();
  });

  tearDown(() {
    AssetsController.instance = previousAssets;
    CustomPdfFonts.clear();
  });

  Future<AssetsController> assetsWith(AssetType type) async {
    final AssetsController controller =
        AssetsController(store: InMemoryAssetStore());
    AssetsController.instance = controller;
    await controller.addAsset(
      type: type,
      name: 'أصل',
      fileName: 'asset.png',
      bytes: samplePngBytes(),
    );
    return controller;
  }

  TemplateDocument page(PageOrientation orientation) => TemplateDocument(
        orientation: orientation,
        elements: const <TemplateElement>[],
      );

  // -------------------------------------------------------------------------
  //  1) الأصول والخلفيات
  // -------------------------------------------------------------------------
  group('تضمين أصول المستخدم في الـ PDF', () {
    test('الإطار (userAsset) يُضمَّن كصورة حقيقية لا صفحة بيضاء', () async {
      final AssetsController controller = await assetsWith(AssetType.border);
      final UserAsset asset = controller.byType(AssetType.border).single;

      final TemplateDocument base = page(PageOrientation.landscape);
      final TemplateDocument document = base.copyWith(
        elements: <TemplateElement>[
          ImageElement(
            id: 'frame',
            box: ElementBox(
              x: 0,
              y: 0,
              width: base.designWidth,
              height: base.designHeight,
            ),
            sourceKind: ImageSourceKind.userAsset,
            path: asset.id,
            fit: ImageFit.fill,
          ),
        ],
      );

      final PdfGeneratorService service =
          await PdfGeneratorService.create(compress: false);
      final PdfGenerationReport report =
          await service.generate(document: document);

      final String raw = latin1.decode(report.bytes, allowInvalid: true);
      expect(report.warnings, isEmpty);
      // وجود كائن صورة مضمّن = الإطار رُسم فعلاً في الملف.
      expect(raw.contains('/Image'), isTrue);
      expect(report.bytes.lengthInBytes, greaterThan(1000));
    });

    test('الختم/الشعار (userAsset) يُضمَّن أيضاً', () async {
      final AssetsController controller = await assetsWith(AssetType.logo);
      final UserAsset asset = controller.byType(AssetType.logo).single;

      final TemplateDocument document = page(PageOrientation.portrait).copyWith(
        elements: <TemplateElement>[
          ImageElement(
            id: 'logo',
            box: const ElementBox(x: 40, y: 40, width: 160, height: 160),
            sourceKind: ImageSourceKind.userAsset,
            path: asset.id,
            fit: ImageFit.contain,
          ),
        ],
      );

      final PdfGeneratorService service =
          await PdfGeneratorService.create(compress: false);
      final PdfGenerationReport report =
          await service.generate(document: document);

      expect(report.warnings, isEmpty);
      expect(
        latin1.decode(report.bytes, allowInvalid: true).contains('/Image'),
        isTrue,
      );
    });

    test('فشل تحميل الأصل لا يُخزَّن نهائياً — يُعاد المحاولة لاحقاً', () async {
      UserAsset? available;
      final AssetPdfImageResolver resolver = AssetPdfImageResolver(
        userAssetsProvider: (String id) => available,
      );

      // المحاولة الأولى قبل توفّر الأصل: تفشل بلا تخزين الفشل.
      expect(
        await resolver.resolve('asset_x', ImageSourceKind.userAsset),
        isNull,
      );

      // بعد استعادة الأصل: يُحلّ بنجاح في نفس المُرحّل.
      available = UserAsset(
        id: 'asset_x',
        type: AssetType.border,
        name: 'إطار',
        fileName: 'border.png',
        base64Data: samplePngBase64(),
        addedAt: DateTime(2026),
      );
      expect(
        await resolver.resolve('asset_x', ImageSourceKind.userAsset),
        isNotNull,
      );
    });
  });

  // -------------------------------------------------------------------------
  //  1.b) النص العربي للتشكيل وتضمين الخط
  // -------------------------------------------------------------------------
  group('النص العربي يتشكّل ويُضمَّن خطه في ملف الـ PDF', () {
    test('الشهادة المجزومة تُصدر بخط عربي مضمَّن (لا خط افتراضي)', () async {
      final String json =
          await rootBundle.loadString(AppAssets.sampleCertificateTemplate);
      final TemplateDocument document = TemplateDocument.fromJsonString(json);

      final PdfGeneratorService service =
          await PdfGeneratorService.create(compress: false);
      final PdfGenerationReport report = await service.generate(
        document: document,
        data: document.sampleData,
      );

      final String raw = latin1.decode(report.bytes, allowInvalid: true);
      expect(raw.contains('IBMPlexSansArabic'), isTrue);
      expect(report.bytes.lengthInBytes, greaterThan(5000));
    });

    test('الإطار (أول عنصر) يُرسم خلف النص كطبقة سفلية', () async {
      final AssetsController controller = await assetsWith(AssetType.border);
      final UserAsset asset = controller.byType(AssetType.border).single;

      final TemplateDocument base = page(PageOrientation.landscape);
      // الإطار أولاً (طبقة سفلية)، ثم النص فوقه — ترتيب `pw.Stack`.
      final TemplateDocument document = base.copyWith(
        elements: <TemplateElement>[
          ImageElement(
            id: 'frame',
            box: ElementBox(
              x: 0,
              y: 0,
              width: base.designWidth,
              height: base.designHeight,
            ),
            sourceKind: ImageSourceKind.userAsset,
            path: asset.id,
            fit: ImageFit.fill,
          ),
          const TextElement(
            id: 'title',
            box: ElementBox(x: 100, y: 100, width: 800, height: 90),
            text: 'شهادة تقدير',
            fontSize: 40,
          ),
        ],
      );

      expect(document.elements.first, isA<ImageElement>());

      final PdfGeneratorService service =
          await PdfGeneratorService.create(compress: false);
      final PdfGenerationReport report =
          await service.generate(document: document);

      final String raw = latin1.decode(report.bytes, allowInvalid: true);
      expect(report.warnings, isEmpty);
      expect(raw.contains('/Image'), isTrue);
      expect(raw.contains('IBMPlexSansArabic'), isTrue);
    });

    test('محاذاة «ضبط» تُصدِر ملفاً سليماً بخط عربي مضمَّن', () async {
      final PdfGeneratorService service =
          await PdfGeneratorService.create(compress: false);
      final PdfGenerationReport report =
          await service.generate(document: page(PageOrientation.portrait).copyWith(
        elements: <TemplateElement>[
          const TextElement(
            id: 't',
            box: ElementBox(x: 40, y: 40, width: 500, height: 200),
            text: 'قد أتمّ بنجاح البرنامج التدريبي المكثّف في إدارة المشاريع '
                'وقيادة الفرق، ونال شهادة تقدير معتمدة.',
            align: ElementTextAlign.justify,
            fontSize: 20,
          ),
        ],
      ));

      final String raw = latin1.decode(report.bytes, allowInvalid: true);
      expect(raw.contains('IBMPlexSansArabic'), isTrue);
      expect(report.bytes.lengthInBytes, greaterThan(1000));
    });

    test('محاذاة «ضبط» بالكشيدة تُصدِر ملفاً بخط عربي وتُغيّر المحتوى فعلياً',
        () async {
      const String body =
          'قد أتمّ بنجاح البرنامج التدريبي المكثّف في إدارة المشاريع وقيادة '
          'الفرق، ونال شهادة تقدير معتمدة من الجهة المانحة.';

      Future<Uint8List> render(JustifyMode mode) async {
        final PdfGeneratorService service =
            await PdfGeneratorService.create(compress: false);
        final PdfGenerationReport report = await service.generate(
          document: const TemplateDocument(
            orientation: PageOrientation.portrait,
            elements: <TemplateElement>[],
          ).copyWith(
            elements: <TemplateElement>[
              TextElement(
                id: 't',
                box: const ElementBox(x: 40, y: 40, width: 500, height: 300),
                text: body,
                align: ElementTextAlign.justify,
                justifyMode: mode,
                fontSize: 20,
              ),
            ],
          ),
        );
        expect(report.warnings, isEmpty);
        return report.bytes;
      }

      final Uint8List kashida = await render(JustifyMode.kashida);
      final Uint8List spaces = await render(JustifyMode.spaces);

      final String raw = latin1.decode(kashida, allowInvalid: true);
      expect(raw.contains('IBMPlexSansArabic'), isTrue);
      expect(kashida.lengthInBytes, greaterThan(1000));
      // الطريقتان تُنتجان محتوى مختلفاً — فخيار الكشيدة ليس مهجوراً.
      expect(kashida, isNot(equals(spaces)));
    });
  });

  // -------------------------------------------------------------------------
  //  2) تضمين الخطوط المخصصة
  // -------------------------------------------------------------------------
  group('تضمين الخطوط المخصصة في الـ PDF', () {
    test('الخط المخصص المسجَّل من المخزن يُضمَّن بدل الخط الافتراضي', () async {
      final ByteData data = await rootBundle.load(AppAssets.pdfNotoArabicBold);
      final Uint8List bytes = data.buffer.asUint8List();
      const String family = 'custom_parity';
      CustomPdfFonts.register(family, bytes, weight: 700);

      PdfFontSet.resetCache();
      final PdfGeneratorService service =
          await PdfGeneratorService.create(compress: false);

      final PdfGenerationReport report = await service.generate(
        document: page(PageOrientation.landscape).copyWith(
          elements: <TemplateElement>[
            const TextElement(
              id: 't',
              box: ElementBox(x: 40, y: 40, width: 500, height: 80),
              text: 'نص بالخط المخصص',
              customFont: family,
              weight: PdfFontWeight.bold,
              fontSize: 28,
            ),
          ],
        ),
      );

      final String raw = latin1.decode(report.bytes, allowInvalid: true);
      // اسم الخط الداخلي (PostScript) يظهر عند التضمين الفعلي في الملف.
      final String compact = raw.replaceAll(RegExp(r'[\s\-_]'), '');
      expect(compact.contains('NotoSansArabic'), isTrue);
      expect(compact.contains('IBMPlexSansArabic'), isFalse);
    });

    test('المحرّك يضمّن خطاً مخصصاً من المخزن حتى لو لم يُسجَّل مسبقاً',
        () async {
      final ByteData data = await rootBundle.load(AppAssets.pdfNotoArabicBold);
      final CustomFontController controller = CustomFontController(
        store: InMemoryCustomFontStore(),
      );
      CustomFontController.instance = controller;
      final CustomFontAddResult result = await controller.addFont(
        fileName: 'NotoSansArabic-Bold.ttf',
        bytes: data.buffer.asUint8List(),
      );
      final String family = result.face.family;

      // نحاكي الحالة التي لم يُسجَّل فيها الخط في محرّك الطباعة بعد.
      CustomPdfFonts.clear();
      expect(CustomPdfFonts.contains(family), isFalse);

      PdfFontSet.resetCache();
      final PdfGeneratorService service =
          await PdfGeneratorService.create(compress: false);
      final PdfGenerationReport report = await service.generate(
        document: page(PageOrientation.landscape).copyWith(
          elements: <TemplateElement>[
            TextElement(
              id: 't',
              box: const ElementBox(x: 40, y: 40, width: 500, height: 80),
              text: 'نص بالخط المخصص',
              customFont: family,
              fontSize: 28,
            ),
          ],
        ),
      );

      final String compact = latin1
          .decode(report.bytes, allowInvalid: true)
          .replaceAll(RegExp(r'[\s\-_]'), '');
      expect(compact.contains('NotoSansArabic'), isTrue);
      expect(compact.contains('IBMPlexSansArabic'), isFalse);
      controller.dispose();
    });

    test('خط مخصص غير مسجَّل يرجع للخط المضمّن بلا فشل', () async {
      final PdfGeneratorService service =
          await PdfGeneratorService.create(compress: false);
      final PdfGenerationReport report = await service.generate(
        document: page(PageOrientation.landscape).copyWith(
          elements: <TemplateElement>[
            const TextElement(
              id: 't',
              box: ElementBox(x: 40, y: 40, width: 500, height: 80),
              text: 'نص',
              customFont: 'custom_missing',
              fontSize: 24,
            ),
          ],
        ),
      );
      expect(latin1.decode(report.bytes, allowInvalid: true),
          contains('IBMPlexSansArabic'));
    });
  });

  // -------------------------------------------------------------------------
  //  3) اتساق الإحداثيات (تصميم ← نقاط طباعة)
  // -------------------------------------------------------------------------
  group('اتساق تحويل الإحداثيات مع المحرر', () {
    test('الورقة الافتراضية: معامل 72/96 وإزاحة صفرية', () {
      final TemplateDocument document = page(PageOrientation.landscape);
      expect(document.scale, closeTo(72 / 96, 1e-9));
      expect(document.offsetX, closeTo(0, 1e-9));
      expect(document.offsetY, closeTo(0, 1e-9));
    });

    test('صندوق يُحوَّل خطّياً إلى نقاط الطباعة', () {
      final TemplateDocument document = page(PageOrientation.landscape);
      final Rect rect = document.boxToPdfRect(
        const ElementBox(x: 100, y: 100, width: 200, height: 50),
      );
      expect(rect.left, closeTo(75, 1e-6));
      expect(rect.top, closeTo(75, 1e-6));
      expect(rect.width, closeTo(150, 1e-6));
      expect(rect.height, closeTo(37.5, 1e-6));
    });

    test('عرض الصفر يمتد حتى نهاية الصفحة (كما في المحرر)', () {
      final TemplateDocument document = page(PageOrientation.landscape);
      final Rect rect =
          document.boxToPdfRect(const ElementBox(x: 200, y: 0, width: 0));
      expect(rect.right, closeTo(document.pageWidthPt, 1e-6));
    });

    test('نسبة الموضع إلى الورقة متطابقة بين المحرر والـ PDF', () {
      final TemplateDocument document = page(PageOrientation.landscape);
      final Size design = Size(document.designWidth, document.designHeight);
      final CanvasGeometry geometry =
          CanvasGeometry.fit(viewport: const Size(800, 600), design: design);

      const ElementBox box = ElementBox(x: 300, y: 200, width: 400, height: 100);

      // المحرر: صندوق على الشاشة.
      final Rect screen = Rect.fromLTWH(
        box.x * geometry.scale,
        box.y * geometry.scale,
        box.width * geometry.scale,
        box.height * geometry.scale,
      );
      final Size paper = geometry.pageSize(design);

      // PDF: صندوق بالنقاط.
      final Rect pdf = document.boxToPdfRect(box);

      // الكسر نفسه من الورقة ⇒ لا ترحّل محاذاة.
      expect(screen.left / paper.width, closeTo(pdf.left / document.pageWidthPt, 1e-6));
      expect(
        screen.top / paper.height,
        closeTo(pdf.top / document.pageHeightPt, 1e-6),
      );
      expect(
        screen.width / paper.width,
        closeTo(pdf.width / document.pageWidthPt, 1e-6),
      );
    });

    test('مربّع الختم بأصغر ضلعين (مطابقة المحرر)', () {
      const SealElement seal = SealElement(
        id: 's',
        box: ElementBox(x: 0, y: 0, width: 100, height: 60),
      );
      expect(seal.squareSide(), 60);
    });
  });
}
