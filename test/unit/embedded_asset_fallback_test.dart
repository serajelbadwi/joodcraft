import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/assets/asset_image_cache.dart';
import 'package:joodcraft/core/assets/asset_store.dart';
import 'package:joodcraft/core/assets/assets_controller.dart';
import 'package:joodcraft/core/assets/embedded_assets.dart';
import 'package:joodcraft/core/assets/user_asset.dart';
import 'package:joodcraft/core/constants/app_constants.dart';
import 'package:joodcraft/core/editor/element_factory.dart';
import 'package:joodcraft/core/editor/template_editor_controller.dart';
import 'package:joodcraft/core/models/template_document.dart';
import 'package:joodcraft/core/models/template_element.dart';
import 'package:joodcraft/core/services/pdf_generator_service.dart';

import '../support/sample_image.dart';

/// النسخة المضمّنة (Base64) من الأصول: القراءة/الكتابة في النموذج، حفظ
/// القالب، وحلّها في المحرر ومحرّك الـ PDF عند فقدان الأصل من المكتبة.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AssetsController previousAssets;

  setUp(() {
    previousAssets = AssetsController.instance;
    // مكتبة فارغة: كل مرجع `userAsset` يبدو مفقوداً حتى نُضيفه يدوياً.
    AssetsController.instance = AssetsController(store: InMemoryAssetStore());
    AssetImageCache.instance.clear();
  });

  tearDown(() => AssetsController.instance = previousAssets);

  TemplateDocument documentWith(
    List<TemplateElement> elements, {
    Map<String, String> assets = const <String, String>{},
  }) =>
      TemplateDocument(
        orientation: PageOrientation.landscape,
        elements: elements,
        assets: assets,
      );

  // -------------------------------------------------------------------------
  //  1) النموذج: Base64 مضمّن في العنصر وعلى القالب
  // -------------------------------------------------------------------------
  group('النموذج يحفظ النسخة المضمّنة', () {
    test('ImageElement يحفظ/يقرأ حقل data', () {
      const ImageElement element = ImageElement(
        id: 'i1',
        box: ElementBox(x: 0, y: 0, width: 100, height: 100),
        sourceKind: ImageSourceKind.userAsset,
        path: 'asset_x',
        data: 'QUJD',
      );
      expect(element.hasEmbeddedData, isTrue);

      final Map<String, dynamic> json = element.toJson();
      expect(json['data'], 'QUJD');

      final ImageElement restored = ImageElement.fromJson(json, 'i1');
      expect(restored.data, 'QUJD');
      expect(restored.path, 'asset_x');

      // نسخة بلا بيانات مضمّنة لا تكتب الحقل.
      final ImageElement stripped = element.copyWith(data: null);
      expect(stripped.data, isNull);
      expect(stripped.toJson().containsKey('data'), isFalse);
    });

    test('TemplateDocument يحفظ/يقرأ خريطة assets ويتجاهل الفارغ', () {
      final TemplateDocument document = TemplateDocument.fromJson(<String, dynamic>{
        'schema_version': 1,
        'assets': <String, dynamic>{
          'asset_a': 'QUJD',
          'asset_empty': '   ',
          'asset_bad': 42,
        },
        'elements': <Map<String, dynamic>>[],
      });

      expect(document.assets, <String, String>{'asset_a': 'QUJD'});
      expect(document.toJson()['assets'], <String, String>{'asset_a': 'QUJD'});
    });

    test('ElementFactory يضمّن Base64 عند الإدراج ما لم يُعطَّل', () {
      const Size design = Size(1123, 794);
      final UserAsset asset = UserAsset(
        id: 'asset_img',
        type: AssetType.border,
        name: 'إطار',
        fileName: 'frame.png',
        base64Data: samplePngBase64(),
        addedAt: DateTime(2026),
      );

      final ImageElement embedded =
          ElementFactory.fromUserAsset(asset: asset, design: design);
      expect(embedded.data, samplePngBase64());
      expect(embedded.hasEmbeddedData, isTrue);

      final ImageElement plain = ElementFactory.fromUserAsset(
        asset: asset,
        design: design,
        embedData: false,
      );
      expect(plain.data, isNull);
    });
  });

  // -------------------------------------------------------------------------
  //  2) المُرحّل: النسخة المضمّنة احتياطاً
  // -------------------------------------------------------------------------
  group('AssetPdfImageResolver يقرأ النسخة المضمّنة', () {
    test('يحلّ Base64 المضمّن عند غياب الأصل من المكتبة', () async {
      final AssetPdfImageResolver resolver = AssetPdfImageResolver(
        userAssetsProvider: (String id) => null,
      );

      expect(
        await resolver.resolve('asset_missing', ImageSourceKind.userAsset),
        isNull,
      );
      expect(
        await resolver.resolve(
          'asset_missing',
          ImageSourceKind.userAsset,
          inlineData: samplePngBase64(),
        ),
        isNotNull,
      );
    });

    test('يتجاهل Base64 تالفاً بلا فشل', () async {
      final AssetPdfImageResolver resolver = AssetPdfImageResolver(
        userAssetsProvider: (String id) => null,
      );
      expect(
        await resolver.resolve(
          'asset_missing',
          ImageSourceKind.userAsset,
          inlineData: 'not-base64!!!',
        ),
        isNull,
      );
    });
  });

  // -------------------------------------------------------------------------
  //  3) المحرّك: الرسم من المضمّن + التحذير عند الفقد
  // -------------------------------------------------------------------------
  group('محرّك الـ PDF يرسم النسخة المضمّنة', () {
    test('إطار مفقود بـ data مضمّن يُرسم بدل صفحة بيضاء', () async {
      final TemplateDocument base = documentWith(const <TemplateElement>[]);
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
            path: 'asset_deleted',
            fit: ImageFit.fill,
            data: samplePngBase64(),
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

    test('أصل مفقود بلا نسخة مضمّنة يُسجَّل تحذيراً واضحاً', () async {
      final TemplateDocument document = documentWith(<TemplateElement>[
        const ImageElement(
          id: 'frame',
          box: ElementBox(x: 0, y: 0, width: 200, height: 200),
          sourceKind: ImageSourceKind.userAsset,
          path: 'asset_gone',
        ),
      ]);

      final PdfGeneratorService service =
          await PdfGeneratorService.create(compress: false);
      final PdfGenerationReport report =
          await service.generate(document: document);

      expect(report.warnings, isNotEmpty);
      expect(report.warnings.first, contains('أصل محذوف'));
      expect(report.warnings.first, contains('asset_gone'));
    });

    test('خريطة assets على القالب تُستخدم كاحتياط', () async {
      final TemplateDocument base = documentWith(const <TemplateElement>[]);
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
            path: 'asset_shared',
            fit: ImageFit.fill,
          ),
        ],
        assets: <String, String>{'asset_shared': samplePngBase64()},
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
  });

  // -------------------------------------------------------------------------
  //  4) كشف المراجع المفقودة نهائياً
  // -------------------------------------------------------------------------
  group('missingAssetReferences', () {
    test('يُبلّغ عن المرجع المفقود بلا نسخة مضمّنة فقط', () {
      final TemplateDocument document = documentWith(<TemplateElement>[
        const ImageElement(
          id: 'a',
          box: ElementBox(x: 0, y: 0, width: 10, height: 10),
          sourceKind: ImageSourceKind.userAsset,
          path: 'lost_a',
        ),
        const ImageElement(
          id: 'b',
          box: ElementBox(x: 0, y: 0, width: 10, height: 10),
          sourceKind: ImageSourceKind.userAsset,
          path: 'lost_b',
          data: 'QUJD',
        ),
        // مرجع مكرَّر لا يُحتسب مرتين.
        const ImageElement(
          id: 'c',
          box: ElementBox(x: 0, y: 0, width: 10, height: 10),
          sourceKind: ImageSourceKind.userAsset,
          path: 'lost_a',
        ),
      ]);

      expect(missingAssetReferences(document), <String>['lost_a']);
    });

    test('يعيد قائمة فارغة عندما يكون الأصل موجوداً في المكتبة', () async {
      final AssetsController controller =
          AssetsController(store: InMemoryAssetStore());
      AssetsController.instance = controller;
      final UserAsset asset = await controller.addAsset(
        type: AssetType.border,
        name: 'إطار',
        fileName: 'frame.png',
        bytes: samplePngBytes(),
      );
      final TemplateDocument document = documentWith(<TemplateElement>[
        ImageElement(
          id: 'a',
          box: const ElementBox(x: 0, y: 0, width: 10, height: 10),
          sourceKind: ImageSourceKind.userAsset,
          path: asset.id,
        ),
      ]);

      // الأصل موجود في المكتبة ⇒ لا مراجع مفقودة رغم غياب Base64 مضمّن.
      expect(missingAssetReferences(document), isEmpty);
    });

    test('hasInlineFallback يمنع التحذير', () {
      const ImageElement element = ImageElement(
        id: 'a',
        box: ElementBox(x: 0, y: 0, width: 10, height: 10),
        sourceKind: ImageSourceKind.userAsset,
        path: 'lost',
        data: 'QUJD',
      );
      final TemplateDocument document = documentWith(<TemplateElement>[element]);
      expect(hasInlineFallback(element, document), isTrue);
      expect(missingAssetReferences(document), isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  //  5) قبول صيغتين للبيانات المضمّنة (سلسلة أو كائن {base64})
  // -------------------------------------------------------------------------
  group('النموذج يقبل صيغتين للبيانات المضمّنة', () {
    test('يقرأ Base64 من كائن {"base64": ...}', () {
      final ImageElement parsed = ImageElement.fromJson(<String, dynamic>{
        'type': 'image',
        'source': 'user_asset',
        'path': 'asset_x',
        'data': <String, dynamic>{'base64': 'QUJD'},
      }, 'i1');
      expect(parsed.data, 'QUJD');
      expect(parsed.hasEmbeddedData, isTrue);
    });

    test('يزيل بادئة data URI عند القراءة', () {
      final ImageElement parsed = ImageElement.fromJson(<String, dynamic>{
        'type': 'image',
        'source': 'user_asset',
        'path': 'asset_x',
        'data': 'data:image/png;base64,QUJD',
      }, 'i1');
      expect(parsed.data, 'QUJD');
    });

    test('يقرأ المفتاح البديل data_base64', () {
      final ImageElement parsed = ImageElement.fromJson(<String, dynamic>{
        'type': 'image',
        'source': 'user_asset',
        'path': 'asset_x',
        'data_base64': 'QUJD',
      }, 'i1');
      expect(parsed.data, 'QUJD');
    });

    test('المُرحّل يفكّ Base64 مسبوقاً ببادئة data URI', () async {
      final AssetPdfImageResolver resolver =
          AssetPdfImageResolver(userAssetsProvider: (String id) => null);
      expect(
        await resolver.resolve(
          'asset_missing',
          ImageSourceKind.userAsset,
          inlineData: 'data:image/png;base64,${samplePngBase64()}',
        ),
        isNotNull,
      );
    });

    test('يستعيد البايتات المعروضة على اللوحة عند غياب الأصل من المكتبة',
        () async {
      const String id = 'asset_ghost';
      // نحاكي رسم اللوحة: البايتات مخزّنة في AssetImageCache من قبل.
      AssetImageCache.instance.bytesForAsset(
        UserAsset(
          id: id,
          type: AssetType.logo,
          name: 'شعار',
          fileName: 'logo.png',
          base64Data: samplePngBase64(),
          addedAt: DateTime(2026),
        ),
      );
      final AssetPdfImageResolver resolver =
          AssetPdfImageResolver(userAssetsProvider: (String id) => null);
      expect(
        await resolver.resolve(id, ImageSourceKind.userAsset),
        isNotNull,
      );
    });
  });

  // -------------------------------------------------------------------------
  //  6) المحرر يضمّن الأصول تلقائياً (ختام حلّ «أصل محذوف»)
  // -------------------------------------------------------------------------
  group('المحرر يضمّن الأصول تلقائياً', () {
    TemplateEditorController controllerWith(List<TemplateElement> elements) =>
        TemplateEditorController(
          document: documentWith(elements),
          category: TemplateCategory.certificate,
        );

    Future<UserAsset> addAsset() => AssetsController.instance.addAsset(
          type: AssetType.logo,
          name: 'شعار',
          fileName: 'logo.png',
          bytes: samplePngBytes(),
        );

    test('assignSelectedUserAsset يضمّن Base64 داخل العنصر المحدد', () async {
      final UserAsset asset = await addAsset();
      final TemplateEditorController controller =
          controllerWith(<TemplateElement>[
        const ImageElement(
          id: 'img1',
          box: ElementBox(x: 0, y: 0, width: 100, height: 100),
          sourceKind: ImageSourceKind.asset,
          path: '',
        ),
      ]);
      controller.select('img1');
      controller.assignSelectedUserAsset(asset);

      final ImageElement updated =
          controller.document.elements.first as ImageElement;
      expect(updated.path, asset.id);
      expect(updated.sourceKind, ImageSourceKind.userAsset);
      expect(updated.data, asset.base64Data);
    });

    test('التكرار يحافظ على النسخة المضمّنة', () {
      final TemplateEditorController controller =
          controllerWith(<TemplateElement>[
        const ImageElement(
          id: 'img1',
          box: ElementBox(x: 0, y: 0, width: 100, height: 100),
          sourceKind: ImageSourceKind.userAsset,
          path: 'asset_x',
          data: 'QUJD',
        ),
      ]);
      controller.select('img1');
      controller.duplicateSelected();

      expect(controller.document.elements.length, 2);
      final ImageElement copy =
          controller.document.elements.last as ImageElement;
      expect(copy.id, isNot('img1'));
      expect(copy.data, 'QUJD');
      expect(copy.hasEmbeddedData, isTrue);
    });

    test('loadDocument يضمّن Base64 من المكتبة للأصول القديمة بلا data',
        () async {
      final UserAsset asset = await addAsset();
      final TemplateEditorController controller =
          controllerWith(const <TemplateElement>[]);
      controller.loadDocument(
        documentWith(<TemplateElement>[
          ImageElement(
            id: 'old',
            box: const ElementBox(x: 0, y: 0, width: 100, height: 100),
            sourceKind: ImageSourceKind.userAsset,
            path: asset.id,
          ),
        ]),
      );

      final ImageElement backfilled =
          controller.document.elements.first as ImageElement;
      expect(backfilled.hasEmbeddedData, isTrue);
      expect(backfilled.data, asset.base64Data);
    });
  });
}
