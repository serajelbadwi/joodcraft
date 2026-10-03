import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/assets/asset_store.dart';
import 'package:joodcraft/core/assets/asset_type_ui.dart';
import 'package:joodcraft/core/assets/assets_controller.dart';
import 'package:joodcraft/core/constants/app_constants.dart';
import 'package:joodcraft/core/editor/template_editor_controller.dart';
import 'package:joodcraft/core/editor/widgets/property_toolbar.dart';
import 'package:joodcraft/core/models/template_document.dart';
import 'package:joodcraft/core/models/template_element.dart';
import 'package:joodcraft/core/theme/app_theme.dart';

import '../support/sample_image.dart';

/// يثبت أن اختيار أصل من المكتبة يربطه بعنصر الصورة (`userAsset`) — وهو ما
/// يقرأه محرّك الطباعة لاحقاً.
void main() {
  testWidgets('اختيار أصل من المكتبة يضبط عنصر الصورة على userAsset',
      (WidgetTester tester) async {
    final AssetsController assets = AssetsController(store: InMemoryAssetStore());
    AssetsController.instance = assets;
    await assets.addAsset(
      type: AssetType.logo,
      name: 'شعار الشركة',
      fileName: 'logo.png',
      bytes: samplePngBytes(),
    );

    final TemplateEditorController controller = TemplateEditorController(
      document: TemplateDocument(
        elements: <TemplateElement>[
          ImageElement(
            id: 'img',
            box: const ElementBox(x: 20, y: 20, width: 160, height: 160),
            sourceKind: ImageSourceKind.asset,
            path: '',
          ),
        ],
      ),
      category: TemplateCategory.certificate,
    );
    controller.select('img');
    addTearDown(controller.dispose);

    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            child: PropertyToolbar(controller: controller),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // المنتقي مفتاحه `asset-picker` — نفتحه ونختار الأصل.
    final Finder picker = find.descendant(
      of: find.byKey(const ValueKey<String>('asset-picker')),
      matching: find.byType(DropdownButton<String>),
    );
    expect(picker, findsOneWidget);

    await tester.tap(picker);
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('شعار الشركة').last);
    await tester.pumpAndSettle();

    final ImageElement selected = controller.selected! as ImageElement;
    expect(selected.sourceKind, ImageSourceKind.userAsset);
    expect(selected.path, assets.assets.single.id);
    expect(selected.fit, AssetType.logo.defaultFit);
  });
}
