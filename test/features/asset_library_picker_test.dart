import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/assets/asset_store.dart';
import 'package:joodcraft/core/assets/assets_controller.dart';
import 'package:joodcraft/core/assets/user_asset.dart';
import 'package:joodcraft/core/constants/app_assets.dart';
import 'package:joodcraft/core/constants/app_constants.dart';
import 'package:joodcraft/core/editor/element_factory.dart';
import 'package:joodcraft/core/editor/template_editor_controller.dart';
import 'package:joodcraft/core/editor/widgets/asset_library_picker.dart';
import 'package:joodcraft/core/editor/widgets/element_view.dart';
import 'package:joodcraft/core/editor/widgets/property_toolbar.dart';
import 'package:joodcraft/core/editor/widgets/template_canvas.dart';
import 'package:joodcraft/core/editor/widgets/template_editor_view.dart';
import 'package:joodcraft/core/models/template_document.dart';
import 'package:joodcraft/core/models/template_element.dart';
import 'package:joodcraft/core/theme/app_theme.dart';

import '../support/sample_image.dart';

/// يثبت أن أصل «إطار» مرفوعاً يمكن اختياره من داخل المحرّر وإدراجه كعنصر صورة
/// بمرجع `userAsset` — وهذا ما يجعل الإطار يظهر على اللوحة وفي الـ PDF.
void main() {
  late AssetsController assets;

  setUp(() {
    assets = AssetsController(store: InMemoryAssetStore());
    AssetsController.instance = assets;
  });

  Future<UserAsset> add(AssetType type, String name) => assets.addAsset(
        type: type,
        name: name,
        fileName: '$name.png',
        bytes: samplePngBytes(),
      );

  Widget host(Widget child) => MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: child),
      );

  testWidgets('زر «من مكتبة أصولي» في شريط الإضافة يُدرج الإطار كخلفية كاملة',
      (WidgetTester tester) async {
    final UserAsset frame = await add(AssetType.border, 'إطار ذهبي');
    final TemplateEditorController controller = TemplateEditorController(
      document: const TemplateDocument(
        elements: <TemplateElement>[
          TextElement(
            id: 't1',
            box: ElementBox(x: 40, y: 40, width: 300, height: 60),
            text: 'شهادة',
          ),
        ],
      ),
      category: TemplateCategory.certificate,
    );
    addTearDown(controller.dispose);

    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(host(ElementPaletteBar(controller: controller)));
    await tester.tap(find.text('من مكتبة أصولي'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey<String>('asset-filter-border')), findsOneWidget);
    await tester.tap(find.byKey(ValueKey<String>('asset-option-${frame.id}')));
    await tester.pumpAndSettle();

    final TemplateElement first = controller.document.elements.first;
    expect(first, isA<ImageElement>());
    final ImageElement image = first as ImageElement;
    expect(image.sourceKind, ImageSourceKind.userAsset);
    expect(image.path, frame.id);
    expect(image.fit, ImageFit.fill);
    expect(image.box.x, 0);
    expect(image.box.y, 0);
    expect(image.box.width, controller.designSize.width);
    expect(image.box.height, controller.designSize.height);
    // بقيت عناصر القالب بعد الإدراج (الإطار في الخلف).
    expect(controller.document.elements.length, 2);
    expect(controller.selectedId, image.id);
  });

  testWidgets('المنتقي يصفّي الأنواع المطلوبة ويستبعد غيرها',
      (WidgetTester tester) async {
    await add(AssetType.border, 'إطار رسمي');
    await add(AssetType.logo, 'شعار المؤسسة');
    final UserAsset stamp = await add(AssetType.stamp, 'ختم الإدارة');

    await tester.pumpWidget(
      host(
        Builder(
          builder: (BuildContext context) => TextButton(
            onPressed: () => showAssetLibraryPicker(
              context,
              filterTypes: const <AssetType>[AssetType.border, AssetType.logo],
            ),
            child: const Text('افتح'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('افتح'));
    await tester.pumpAndSettle();

    expect(find.text('إطار رسمي'), findsOneWidget);
    expect(find.text('شعار المؤسسة'), findsOneWidget);
    expect(find.text('ختم الإدارة'), findsNothing);
    expect(find.byKey(ValueKey<String>('asset-option-${stamp.id}')), findsNothing);

    // شريحة «شعار» تعرض الشعار فقط.
    await tester.tap(find.byKey(const ValueKey<String>('asset-filter-logo')));
    await tester.pumpAndSettle();
    expect(find.text('شعار المؤسسة'), findsOneWidget);
    expect(find.text('إطار رسمي'), findsNothing);
  });

  testWidgets('زر خلفية المستند في المحرّر يُدرج الإطار خلف كل العناصر',
      (WidgetTester tester) async {
    final UserAsset frame = await add(AssetType.border, 'إطار المستند');

    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      host(
        TemplateEditorView(
          category: TemplateCategory.certificate,
          initialTemplateAsset: AppAssets.sampleCertificateTemplate,
          exportFileName: 'joodcraft-certificate.pdf',
          document: const TemplateDocument(
            elements: <TemplateElement>[
              TextElement(
                id: 't1',
                box: ElementBox(x: 40, y: 40, width: 300, height: 60),
                text: 'شهادة',
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('إطار من مكتبة أصولي'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey<String>('asset-option-${frame.id}')));
    await tester.pumpAndSettle();

    final TemplateCanvas canvas =
        tester.widget<TemplateCanvas>(find.byType(TemplateCanvas));
    final List<TemplateElement> elements = canvas.controller.document.elements;
    expect(elements.first, isA<ImageElement>());
    final ImageElement image = elements.first as ImageElement;
    expect(image.sourceKind, ImageSourceKind.userAsset);
    expect(image.path, frame.id);

    // الإطار يُرسم فعلاً على اللوحة.
    expect(find.byType(ElementView), findsNWidgets(2));

    await tester.pump(const Duration(seconds: 5));
  });

  test('ElementFactory.fromUserAsset يضبط الملاءمة حسب النوع', () {
    const Size design = Size(1123, 794);
    final UserAsset logo = UserAsset(
      id: 'a1',
      type: AssetType.logo,
      name: 'شعار',
      fileName: 'logo.png',
      base64Data: '',
      addedAt: DateTime(2026),
    );
    final UserAsset frame = UserAsset(
      id: 'a2',
      type: AssetType.border,
      name: 'إطار',
      fileName: 'frame.png',
      base64Data: '',
      addedAt: DateTime(2026),
    );

    final ImageElement logoElement =
        ElementFactory.fromUserAsset(asset: logo, design: design);
    expect(logoElement.sourceKind, ImageSourceKind.userAsset);
    expect(logoElement.path, 'a1');
    expect(logoElement.fit, ImageFit.contain);
    expect(logoElement.box.width, lessThan(design.width));

    final ImageElement frameElement =
        ElementFactory.fromUserAsset(asset: frame, design: design);
    expect(frameElement.fit, ImageFit.fill);
    expect(frameElement.box.width, design.width);
    expect(frameElement.box.height, design.height);
  });
}
