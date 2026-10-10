import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/assets/asset_store.dart';
import 'package:joodcraft/core/assets/assets_controller.dart';
import 'package:joodcraft/core/constants/app_constants.dart';
import 'package:joodcraft/core/editor/template_editor_controller.dart';
import 'package:joodcraft/core/editor/widgets/editor_controls.dart';
import 'package:joodcraft/core/editor/widgets/element_view.dart';
import 'package:joodcraft/core/editor/widgets/property_toolbar.dart';
import 'package:joodcraft/core/editor/widgets/template_canvas.dart';
import 'package:joodcraft/core/models/template_document.dart';
import 'package:joodcraft/core/models/template_element.dart';
import 'package:joodcraft/core/theme/app_colors.dart';
import 'package:joodcraft/core/theme/app_theme.dart';
import 'package:joodcraft/core/utils/hex_color.dart';

import '../support/sample_image.dart';

/// تلوين العناصر في المحرّر: طبقة `ColorFiltered` بـ`BlendMode.srcIn` تُغلّف
/// صورة العنصر وحده، وتتحوّل البكسلات المرسومة إلى اللون المختار مع بقاء
/// الشفاف شفافاً، وزرّ الإزالة يعيد البكسلات الأصلية.
void main() {
  late TemplateEditorController controller;
  late AssetsController previousAssets;

  setUp(() {
    previousAssets = AssetsController.instance;
    AssetsController.instance = AssetsController(store: InMemoryAssetStore());
  });

  tearDown(() {
    AssetsController.instance = previousAssets;
  });

  TemplateDocument document({String? tintHex}) => TemplateDocument(
        elements: <TemplateElement>[
          ImageElement(
            id: 'img-1',
            box: const ElementBox(x: 100, y: 100, width: 200, height: 120),
            sourceKind: ImageSourceKind.dataUri,
            path: samplePngBase64(),
            tintHex: tintHex,
          ),
        ],
      );

  TemplateEditorController build({String? tintHex}) {
    final TemplateEditorController built = TemplateEditorController(
      document: document(tintHex: tintHex),
      category: TemplateCategory.certificate,
    );
    addTearDown(built.dispose);
    return built;
  }

  ColorFilter srcIn(String hex) =>
      ColorFilter.mode(colorFromHex(hex), BlendMode.srcIn);

  group('ElementView', () {
    Future<void> pumpElement(WidgetTester tester, {String? tintHex}) async {
      controller = build(tintHex: tintHex);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: ElementView(
              element: controller.document.elements.single,
              document: controller.document,
              scale: 1,
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('العنصر الملوّن يُغلَّف بـColorFiltered(srcIn)', (WidgetTester tester) async {
      await pumpElement(tester, tintHex: '#C7A26B');

      final ColorFiltered filtered =
          tester.widget<ColorFiltered>(find.byType(ColorFiltered));
      expect(filtered.colorFilter, srcIn('#C7A26B'));
    });

    testWidgets('بلا لون: لا طبقة تلوين إطلاقاً (البكسلات الأصلية)', (WidgetTester tester) async {
      await pumpElement(tester, tintHex: null);
      expect(find.byType(ColorFiltered), findsNothing);
    });
  });

  group('اللوحة', () {
    testWidgets('تغيير اللون يُحدّث اللوحة فوراً والإزالة تُعيد الأصل',
        (WidgetTester tester) async {
      controller = build();
      controller.select('img-1');
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(body: TemplateCanvas(controller: controller)),
        ),
      );
      await tester.pump();
      expect(find.byType(ColorFiltered), findsNothing);

      // كأن المستخدم اختار لوناً من شريط الخصائص.
      controller.setSelectedImageTint('#FF0000');
      await tester.pump();
      expect(
        tester.widget<ColorFiltered>(find.byType(ColorFiltered)).colorFilter,
        srcIn('#FF0000'),
      );

      controller.clearSelectedImageTint();
      await tester.pump();
      expect(find.byType(ColorFiltered), findsNothing);
    });
  });

  group('شريط الخصائص', () {
    Future<void> pumpToolbar(WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 900));
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
      await tester.pump();
    }

    testWidgets('منتقي الألوان يضبط التلوين وزرّ الإزالة يمسحه',
        (WidgetTester tester) async {
      controller = build();
      controller.select('img-1');
      await pumpToolbar(tester);

      // حقل التلوين وحده (الشريط قد يحمل حقول ألوان أخرى كالخلفية).
      final Finder tintField = find.ancestor(
        of: find.text('تلوين الصورة'),
        matching: find.byType(ColorField),
      );
      expect(tintField, findsOneWidget);

      // حقل اللوحة السريعة يحمل تلميحين (Tooltip + PopupMenuButton) — نكتفي بأوله.
      final Finder picker = find
          .descendant(of: tintField, matching: find.byTooltip('لوحة سريعة'))
          .first;
      await tester.ensureVisible(picker);
      await tester.pumpAndSettle();
      await tester.tap(picker);
      await tester.pumpAndSettle();

      final String gold = hexFromColor(AppColors.gold);
      await tester.tap(find.text(gold).last);
      await tester.pumpAndSettle();

      expect((controller.selected! as ImageElement).tintHex, gold);
      expect(
        controller.document.elements.single.toJson()['tint'],
        gold,
        reason: 'اللون يُحفظ في المستند كي يخرج به الـ PDF.',
      );

      // زرّ الإزالة (بلا) يُعيد البكسلات الأصلية.
      final Finder reset = find
          .descendant(of: tintField, matching: find.byTooltip('إزالة اللون'))
          .first;
      await tester.ensureVisible(reset);
      await tester.pumpAndSettle();
      await tester.tap(reset);
      await tester.pumpAndSettle();

      expect((controller.selected! as ImageElement).tintHex, isNull);
      expect(
        controller.document.elements.single.toJson().containsKey('tint'),
        isFalse,
      );
    });
  });
}
