import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:joodcraft/core/assets/asset_store.dart';
import 'package:joodcraft/core/assets/assets_controller.dart';
import 'package:joodcraft/core/constants/app_constants.dart';
import 'package:joodcraft/core/templates/local_template_store.dart';
import 'package:joodcraft/core/templates/preset_catalog.dart';
import 'package:joodcraft/core/theme/app_theme.dart';
import 'package:joodcraft/features/assets_manager/presentation/screens/assets_manager_screen.dart';
import 'package:joodcraft/features/batch_processor/presentation/screens/batch_processor_screen.dart';
import 'package:joodcraft/features/certificate_builder/presentation/screens/template_editor_screen.dart';
import 'package:joodcraft/features/templates/presentation/screens/template_library_screen.dart';

import '../support/sample_image.dart';

/// اختبار تجاوبي للواجهة المكتبية (المرحلة 6): يُثبت أن الشاشات الرئيسية تُبنى
/// بلا تجاوز تخطيط (RenderFlex overflow) على أحجام نوافذ سطح المكتب الشائعة.
///
/// أي `RenderFlex overflowed` يُسقط الاختبار تلقائياً في `flutter_test`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AssetsController assets;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    assets = AssetsController(store: InMemoryAssetStore());
    AssetsController.instance = assets;
  });

  // 1440×900 و1180×780: أحجام نوافذ شائعة. ‎1024×680‎: الحد الأدنى الذي
  // تفرضه نافذة Windows (‎WM_GETMINMAXINFO‎) فيجب أن يبقى بلا تجاوز تخطيط.
  const List<Size> desktopSizes = <Size>[
    Size(1440, 900),
    Size(1180, 780),
    Size(1024, 680),
  ];

  Future<void> pumpAt(
    WidgetTester tester,
    Size size,
    Widget child,
  ) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: child),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('مكتبة القوالب تتجاوب مع أحجام النوافذ', (WidgetTester tester) async {
    for (final Size size in desktopSizes) {
      await pumpAt(
        tester,
        size,
        TemplateLibraryScreen(localStore: InMemoryLocalTemplateStore()),
      );
      expect(find.text('مكتبة القوالب'), findsOneWidget);
    }
  });

  testWidgets('مدير الأصول يتجاوب مع أحجام النوافذ', (WidgetTester tester) async {
    await assets.addAsset(
      type: AssetType.logo,
      name: 'شعار الشركة',
      fileName: 'logo.png',
      bytes: samplePngBytes(),
    );
    for (final Size size in desktopSizes) {
      await pumpAt(tester, size, AssetsManagerScreen(controller: assets));
      expect(find.text('الأصول والتوقيعات'), findsOneWidget);
    }
  });

  testWidgets('محرّر الشهادات يتجاوب مع أحجام النوافذ', (WidgetTester tester) async {
    for (final Size size in desktopSizes) {
      await pumpAt(
        tester,
        size,
        CertificateTemplateEditorScreen(
          draft: PresetCatalog.byId('appreciation_certificate')!.toDraft(),
        ),
      );
      // لوحة التصميم مرسومة دائماً (وصف حالة القالب صار داخل قائمة الشريط
      // عند ضيق المساحة، فلا يصلح دليلاً على البناء).
      expect(
        find.byKey(const ValueKey<String>('editor-canvas-viewport')),
        findsOneWidget,
      );
    }
  });

  testWidgets('التوليد الجماعي يتجاوب مع أحجام النوافذ',
      (WidgetTester tester) async {
    for (final Size size in desktopSizes) {
      await pumpAt(tester, size, const BatchProcessorScreen());
      expect(find.text('التوليد الجماعي من Excel'), findsOneWidget);
    }
  });
}
