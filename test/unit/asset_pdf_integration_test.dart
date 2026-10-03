import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/assets/asset_store.dart';
import 'package:joodcraft/core/assets/assets_controller.dart';
import 'package:joodcraft/core/assets/user_asset.dart';
import 'package:joodcraft/core/constants/app_constants.dart';
import 'package:joodcraft/core/models/template_document.dart';
import 'package:joodcraft/core/models/template_element.dart';
import 'package:joodcraft/core/services/pdf_generator_service.dart';

import '../support/sample_image.dart';

/// يثبت ربط مكتبة الأصول بمحرّك الطباعة: الأصل المحلي يُضمَّن في الـ PDF بلا
/// شبكة، والأصل المحذوف يُنتج تحذيراً بأناقة بدل الفشل.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AssetsController assets;

  setUp(() {
    assets = AssetsController(store: InMemoryAssetStore());
    AssetsController.instance = assets;
  });

  TemplateDocument docWith(ImageSourceKind kind, String path) => TemplateDocument(
        elements: <TemplateElement>[
          ImageElement(
            id: 'img',
            box: const ElementBox(x: 40, y: 40, width: 200, height: 200),
            sourceKind: kind,
            path: path,
          ),
        ],
      );

  bool hasMissingWarning(PdfGenerationReport report) => report.warnings
      .any((String warning) => warning.contains('أصل محذوف'));

  test('صورة من مكتبة الأصول تُضمَّن في الـ PDF بلا تحذير', () async {
    final UserAsset asset = await assets.addAsset(
      type: AssetType.logo,
      name: 'شعاري',
      fileName: 'logo.png',
      bytes: samplePngBytes(),
    );

    final PdfGeneratorService service =
        await PdfGeneratorService.create(compress: false);
    final PdfGenerationReport report = await service.generate(
      document: docWith(ImageSourceKind.userAsset, asset.id),
    );

    expect(report.pageCount, 1);
    expect(hasMissingWarning(report), isFalse);
    expect(report.byteSize, greaterThan(0));
  });

  test('أصل محذوف يُنتج تحذيراً ولا يُسقط الطباعة', () async {
    final PdfGeneratorService service =
        await PdfGeneratorService.create(compress: false);
    final PdfGenerationReport report = await service.generate(
      document: docWith(ImageSourceKind.userAsset, 'asset_مفقود'),
    );

    expect(hasMissingWarning(report), isTrue);
    expect(report.pageCount, 1);
  });

  test('الصورة المضمّنة (dataUri) تُطبع أيضاً', () async {
    final PdfGeneratorService service =
        await PdfGeneratorService.create(compress: false);
    final PdfGenerationReport report = await service.generate(
      document: docWith(ImageSourceKind.dataUri, samplePngBase64()),
    );

    expect(hasMissingWarning(report), isFalse);
  });
}
