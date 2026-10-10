import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/assets/asset_store.dart';
import 'package:joodcraft/core/assets/assets_controller.dart';
import 'package:joodcraft/core/assets/user_asset.dart';
import 'package:joodcraft/core/brand/brand_profile_controller.dart';
import 'package:joodcraft/core/brand/brand_store.dart';
import 'package:joodcraft/core/constants/app_constants.dart';
import 'package:joodcraft/core/editor/template_editor_controller.dart';
import 'package:joodcraft/core/editor/widgets/brand_presets_panel.dart';
import 'package:joodcraft/core/models/template_document.dart';
import 'package:joodcraft/core/models/template_element.dart';
import 'package:joodcraft/core/theme/app_theme.dart';
import 'package:joodcraft/features/brand/presentation/screens/brand_settings_screen.dart';

import '../support/sample_image.dart';

/// اختبارات شاشة الهوية وقسم «عناصر الهوية الجاهزة» في المحرّر.
void main() {
  late BrandProfileController brand;
  late AssetsController assets;

  setUp(() {
    brand = BrandProfileController(store: InMemoryBrandStore());
    assets = AssetsController(store: InMemoryAssetStore());
  });

  tearDown(() => brand.dispose());

  Widget host(Widget child) => MaterialApp(
        theme: AppTheme.light,
        home: child,
      );

  testWidgets('الشاشة تعرض التبويبات وتحفظ البيانات النصية',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      host(BrandSettingsScreen(controller: brand, assets: assets)),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey<String>('brand-tab-visuals')),
        findsOneWidget);
    expect(find.byKey(const ValueKey<String>('brand-tab-colors')),
        findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('brand-tab-text')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey<String>('brand-org-name-ar')),
      'شركة الأمل',
    );
    await tester.pumpAndSettle();
    expect(brand.profile.orgNameAr, 'شركة الأمل');
  });

  testWidgets('زر مسح الهوية يمسح البروفايل بعد التأكيد',
      (WidgetTester tester) async {
    await brand.setOrgNameAr('شركة الأمل');
    await tester.pumpWidget(
      host(BrandSettingsScreen(controller: brand, assets: assets)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('brand-clear')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'مسح الهوية'));
    await tester.pumpAndSettle();

    expect(brand.isEmpty, isTrue);
  });

  testWidgets('قسم الهوية يُدرج ختماً محفوظاً على اللوحة',
      (WidgetTester tester) async {
    final TemplateEditorController editor = TemplateEditorController(
      document: const TemplateDocument(elements: <TemplateElement>[]),
      category: TemplateCategory.certificate,
    );
    addTearDown(editor.dispose);

    final UserAsset seal = await assets.addAsset(
      type: AssetType.stamp,
      name: 'ختم',
      fileName: 'seal.png',
      bytes: samplePngBytes(),
    );
    await brand.setSeal('ختم الشركة', seal.id);

    await tester.pumpWidget(
      host(
        Scaffold(
          body: SingleChildScrollView(
            child: BrandPresetsPanel(
              controller: editor,
              brand: brand,
              assets: assets,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(
      find.byKey(const ValueKey<String>('brand-seal-quick-ختم الشركة')),
    );
    await tester.pump();

    expect(editor.document.elements.length, 1);
    expect(editor.document.elements.first, isA<ImageElement>());
  });

  testWidgets('قسم الهوية يُدرج الترويسة القياسية ككتلة', (WidgetTester tester) async {
    final TemplateEditorController editor = TemplateEditorController(
      document: const TemplateDocument(elements: <TemplateElement>[]),
      category: TemplateCategory.certificate,
    );
    addTearDown(editor.dispose);

    final UserAsset logo = await assets.addAsset(
      type: AssetType.logo,
      name: 'شعار',
      fileName: 'logo.png',
      bytes: samplePngBytes(),
    );
    await brand.setPrimaryLogo(logo.id);
    await brand.setOrgNameAr('شركة الأمل');
    await brand.setTaxOrRegNumber('12345');

    await tester.pumpWidget(
      host(
        Scaffold(
          body: SingleChildScrollView(
            child: BrandPresetsPanel(
              controller: editor,
              brand: brand,
              assets: assets,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey<String>('brand-insert-header')));
    await tester.pump();

    // شعار + اسم + رقم تسجيل ⇒ ثلاث عناصر في مجموعة واحدة.
    expect(editor.document.elements.length, 3);
    expect(editor.selectionIsGrouped, isTrue);
  });

  testWidgets('قسم الهوية الفارغ يعرض دعوة لفتح الإعدادات',
      (WidgetTester tester) async {
    final TemplateEditorController editor = TemplateEditorController(
      document: const TemplateDocument(elements: <TemplateElement>[]),
      category: TemplateCategory.certificate,
    );
    addTearDown(editor.dispose);

    await tester.pumpWidget(
      host(
        Scaffold(
          body: SingleChildScrollView(
            child: BrandPresetsPanel(
              controller: editor,
              brand: brand,
              assets: assets,
              onOpenSettings: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey<String>('brand-open-settings')),
        findsOneWidget);
    expect(find.byKey(const ValueKey<String>('brand-insert-header')),
        findsNothing);
  });
}
