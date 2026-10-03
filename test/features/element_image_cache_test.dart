import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/assets/asset_image_cache.dart';
import 'package:joodcraft/core/assets/asset_store.dart';
import 'package:joodcraft/core/assets/assets_controller.dart';
import 'package:joodcraft/core/assets/user_asset.dart';
import 'package:joodcraft/core/constants/app_constants.dart';
import 'package:joodcraft/core/editor/widgets/element_view.dart';
import 'package:joodcraft/core/models/template_document.dart';
import 'package:joodcraft/core/models/template_element.dart';

import '../support/sample_image.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AssetsController previous;

  setUp(() {
    AssetImageCache.instance.clear();
    previous = AssetsController.instance;
  });

  tearDown(() {
    AssetsController.instance = previous;
    AssetImageCache.instance.clear();
  });

  testWidgets(
      'صورة أصل المستخدم تعيد استخدام موفّرها المخزّن عبر إعادات البناء',
      (WidgetTester tester) async {
    final AssetsController controller =
        AssetsController(store: InMemoryAssetStore());
    AssetsController.instance = controller;
    final UserAsset asset = await controller.addAsset(
      type: AssetType.border,
      name: 'إطار',
      fileName: 'border.png',
      bytes: samplePngBytes(),
    );

    const TemplateDocument document = TemplateDocument(
      orientation: PageOrientation.landscape,
      elements: <TemplateElement>[],
    );
    final ImageElement element = ImageElement(
      id: 'img-1',
      box: const ElementBox(x: 0, y: 0, width: 200, height: 100),
      sourceKind: ImageSourceKind.userAsset,
      path: asset.id,
      fit: ImageFit.fill,
    );

    Widget build() => MaterialApp(
          home: Scaffold(
            body: ElementView(
              element: element,
              document: document,
              scale: 1,
            ),
          ),
        );

    await tester.pumpWidget(build());
    final ImageProvider first =
        tester.widget<Image>(find.byType(Image)).image;
    await tester.pump();
    final ImageProvider second =
        tester.widget<Image>(find.byType(Image)).image;

    // نفس الموفّر = لا فكّ Base64 ولا بناء `MemoryImage` في كل إطار.
    expect(identical(first, second), isTrue);
    expect(find.byType(Image), findsOneWidget);
    controller.dispose();
  });

  testWidgets('صورة مضمّنة (Base64) تُعرض من الذاكرة',
      (WidgetTester tester) async {
    const TemplateDocument document = TemplateDocument(
      orientation: PageOrientation.landscape,
      elements: <TemplateElement>[],
    );
    final ImageElement element = ImageElement(
      id: 'img-2',
      box: const ElementBox(x: 0, y: 0, width: 200, height: 100),
      sourceKind: ImageSourceKind.dataUri,
      path: samplePngBase64(),
      fit: ImageFit.contain,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ElementView(element: element, document: document, scale: 1),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(Image), findsOneWidget);
    expect(AssetImageCache.instance.length, 1);
  });

  testWidgets('بيانات Base64 تالفة تُظهر تنبيهاً بلا انهيار',
      (WidgetTester tester) async {
    const TemplateDocument document = TemplateDocument(
      orientation: PageOrientation.landscape,
      elements: <TemplateElement>[],
    );
    final ImageElement element = ImageElement(
      id: 'img-3',
      box: const ElementBox(x: 0, y: 0, width: 200, height: 100),
      sourceKind: ImageSourceKind.dataUri,
      path: '!!!not-base64!!!',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ElementView(element: element, document: document, scale: 1),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(Image), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
