import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:joodcraft/core/assets/asset_store.dart';
import 'package:joodcraft/core/assets/assets_controller.dart';
import 'package:joodcraft/core/templates/preset_catalog.dart';
import 'package:joodcraft/core/theme/app_colors.dart';
import 'package:joodcraft/core/theme/app_theme.dart';
import 'package:joodcraft/features/certificate_builder/presentation/screens/template_editor_screen.dart';

/// **راحة العين على مساحة العمل**: خلفية اللوحة المحيطة بورقة التصميم يجب أن
/// تكون **أفتح من الهيكل الموحّد** في المظهر الداكن (رمادي `#4A4A4A` مقابل
/// هيكل سليت `#3E3E3E`)، كما في أدوات التصميم الاحترافية — فينخفض التباين
/// الحادّ حول الورقة البيضاء. وفي المظهر الفاتح تبقى غسيلاً كحلياً باهتاً
/// بلا تراجع.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    AssetsController.instance = AssetsController(store: InMemoryAssetStore());
  });

  Future<void> pumpEditor(
    WidgetTester tester, {
    required ThemeMode themeMode,
  }) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeMode,
        home: Scaffold(
          body: CertificateTemplateEditorScreen(
            draft: PresetCatalog.byId('appreciation_certificate')!.toDraft(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// لون خلفية مساحة عمل اللوحة (الحاوية المحيطة بالورقة).
  Color viewportColor(WidgetTester tester) {
    final DecoratedBox viewport = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey<String>('editor-canvas-viewport')),
    );
    return (viewport.decoration as BoxDecoration).color!;
  }

  testWidgets('ليلًا: مساحة العمل فحمي أفتح من اللوحات والخلفية العامة',
      (WidgetTester tester) async {
    await pumpEditor(tester, themeMode: ThemeMode.dark);

    final Color canvas = viewportColor(tester);
    final ColorScheme scheme = AppTheme.dark.colorScheme;

    expect(canvas, AppColors.darkCanvas);
    expect(canvas, isNot(AppColors.darkBackground));

    // الترتيب المقصود: الهيكل الموحّد (‎#3E3E3E‎، وهو الخلفية العامة
    // واللوحات معاً) < مساحة العمل (‎#4A4A4A‎) — فالورقة لا تصطدم بمحيط غامق.
    final double canvasLuminance = canvas.computeLuminance();
    expect(
      canvasLuminance,
      greaterThan(scheme.surface.computeLuminance()),
      reason: 'مساحة العمل يجب أن تكون أفتح من الهيكل الموحّد (‎#3E3E3E‎).',
    );
    expect(
      canvasLuminance,
      greaterThan(scheme.surfaceContainerHighest.computeLuminance()),
      reason: 'مساحة العمل يجب أن تكون أفتح من الخلفية العامة (‎#3E3E3E‎).',
    );
  });

  testWidgets('نهارًا: مساحة العمل غسيل كحلي باهت (لا تراجع)',
      (WidgetTester tester) async {
    await pumpEditor(tester, themeMode: ThemeMode.light);

    final Color canvas = viewportColor(tester);

    // ليست بيضاء صريحة (فتبقى حدود الورقة ظاهرة) وليست الفحمية الداكنة.
    expect(canvas, isNot(AppColors.surface));
    expect(canvas, isNot(AppColors.darkCanvas));
    expect(canvas.computeLuminance(), greaterThan(0.8));
  });
}
