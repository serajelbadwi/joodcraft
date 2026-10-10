import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/constants/app_constants.dart';
import 'package:joodcraft/core/editor/template_editor_controller.dart';
import 'package:joodcraft/core/editor/widgets/accordion.dart';
import 'package:joodcraft/core/editor/widgets/editor_controls.dart';
import 'package:joodcraft/core/editor/widgets/property_toolbar.dart';
import 'package:joodcraft/core/models/template_document.dart';
import 'package:joodcraft/core/models/template_element.dart';
import 'package:joodcraft/core/theme/app_theme.dart';

/// اختبارات لوحة **التأثيرات والضبط اللوني** (Prompt 1.4):
/// الظل، التوهّج الخارجي والداخلي، الضبط اللوني للصور — ودخول القسم في
/// بطاقة «المظهر والمؤثرات» التي تجمع التعبئة والحدود أيضاً.
/// الأكورديون الحصري (فتحه يُغلق ما سواه).
void main() {
  const TextElement text = TextElement(
    id: 'text-1',
    box: ElementBox(x: 20, y: 20, width: 400, height: 80),
    text: 'شهادة',
  );
  const ShapeElement shape = ShapeElement(
    id: 'shape-1',
    kind: ShapeKind.rect,
    box: ElementBox(x: 0, y: 0, width: 120, height: 120),
    fillHex: '#FFFFFF',
  );
  const ImageElement image = ImageElement(
    id: 'image-1',
    box: ElementBox(x: 0, y: 0, width: 200, height: 100),
    sourceKind: ImageSourceKind.asset,
    path: 'assets/images/logo.png',
  );

  late TemplateEditorController controller;
  late String selectedId;

  void buildController(TemplateElement element) {
    selectedId = element.id;
    controller = TemplateEditorController(
      document: TemplateDocument(elements: <TemplateElement>[element]),
      category: TemplateCategory.certificate,
    );
    controller.select(selectedId);
  }

  tearDown(() => controller.dispose());

  Future<void> pumpToolbar(
    WidgetTester tester, {
    AccordionController? accordion,
  }) async {
    await tester.binding.setSurfaceSize(const Size(900, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final Widget toolbar = SingleChildScrollView(
      child: PropertyToolbar(controller: controller),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: accordion == null
              ? toolbar
              : AccordionScope(controller: accordion, child: toolbar),
        ),
      ),
    );
    await tester.pump();
  }

  Finder byKey(String key) => find.byKey(ValueKey<String>(key));

  TemplateElement selected() => controller.selected!;

  group('قسم التأثيرات للنص', () {
    testWidgets('العنوان والمجموعات ومفاتيح التوهّج ظاهرة',
        (WidgetTester tester) async {
      buildController(text);
      await pumpToolbar(tester);

      expect(find.text('المظهر والمؤثرات'), findsOneWidget);
      // عنوان ظل النص محفوظ كما كان (لا ينكسر ما يعرفه المستخدم).
      expect(find.text('ظل النص'), findsOneWidget);
      expect(find.text('توهّج خارجي'), findsOneWidget);
      expect(find.text('توهّج داخلي'), findsOneWidget);
      expect(byKey('text-shadow-add'), findsOneWidget);
      expect(byKey('outer-glow-add'), findsOneWidget);
      expect(byKey('inner-glow-add'), findsOneWidget);
      // والتوهّج الداخلي متاح للنص أيضاً (طبقة بحدّ مطموس للداخل).
      expect(byKey('outer-glow-radius'), findsNothing);
    });

    testWidgets('إضافة توهّج خارجي تُظهر حقوله وتُحدّث النموذج',
        (WidgetTester tester) async {
      buildController(text);
      await pumpToolbar(tester);

      await tester.ensureVisible(byKey('outer-glow-add'));
      await tester.tap(byKey('outer-glow-add'));
      await tester.pump();

      expect(byKey('outer-glow-radius'), findsOneWidget);
      expect(byKey('outer-glow-spread'), findsOneWidget);
      expect(byKey('outer-glow-opacity'), findsOneWidget);
      expect(byKey('outer-glow-color'), findsOneWidget);
      expect((selected() as TextElement).outerGlow, isNotNull);

      tester.widget<SliderField>(byKey('outer-glow-radius')).onChanged(22);
      await tester.pump();
      tester.widget<SliderField>(byKey('outer-glow-spread')).onChanged(6);
      await tester.pump();
      tester.widget<SliderField>(byKey('outer-glow-opacity')).onChanged(0.4);
      await tester.pump();
      tester.widget<ColorField>(byKey('outer-glow-color'))
          .onChanged('#00FF00');
      await tester.pump();

      final GlowEffect glow = (selected() as TextElement).outerGlow!;
      expect(glow.radius, 22);
      expect(glow.spread, 6);
      expect(glow.opacity, 0.4);
      expect(glow.colorHex, '#00FF00');
      // التوهّج الداخلي لم يُمسّ.
      expect((selected() as TextElement).innerGlow, isNull);
    });

    testWidgets('التوهّجان مستقلان ويمكن إزالة كل منهما وحده',
        (WidgetTester tester) async {
      buildController(text);
      await pumpToolbar(tester);

      await tester.ensureVisible(byKey('inner-glow-add'));
      await tester.tap(byKey('inner-glow-add'));
      await tester.pump();
      expect((selected() as TextElement).innerGlow, isNotNull);

      await tester.ensureVisible(byKey('outer-glow-add'));
      await tester.tap(byKey('outer-glow-add'));
      await tester.pump();

      tester
          .widget<SliderField>(byKey('inner-glow-radius'))
          .onChanged(9);
      await tester.pump();
      expect((selected() as TextElement).innerGlow!.radius, 9);
      expect((selected() as TextElement).outerGlow!.radius, 8,
          reason: 'الخارجي يبقى على قيمته الافتراضية');

      await tester.ensureVisible(byKey('outer-glow-remove'));
      await tester.tap(byKey('outer-glow-remove'));
      await tester.pump();

      expect((selected() as TextElement).outerGlow, isNull);
      expect((selected() as TextElement).innerGlow, isNotNull);
    });

    testWidgets('ظل النص المتوسّع له منزلق مستقلّ', (WidgetTester tester) async {
      buildController(text);
      await pumpToolbar(tester);

      await tester.ensureVisible(byKey('text-shadow-add'));
      await tester.tap(byKey('text-shadow-add'));
      await tester.pump();

      expect(byKey('text-shadow-spread'), findsOneWidget);
      tester.widget<SliderField>(byKey('text-shadow-spread')).onChanged(7);
      await tester.pump();
      expect((selected() as TextElement).shadow!.spread, 7);
    });
  });

  group('قسم التأثيرات للشكل', () {
    testWidgets('الظل بكل حقوله (بما فيها الشفافية والتوسيع)',
        (WidgetTester tester) async {
      buildController(shape);
      await pumpToolbar(tester);

      expect(find.text('المظهر والمؤثرات'), findsOneWidget);
      expect(find.text('الظل'), findsOneWidget);
      expect(byKey('inner-glow-add'), findsOneWidget);
      expect(byKey('outer-glow-add'), findsOneWidget);

      await tester.ensureVisible(byKey('shape-shadow-add'));
      await tester.tap(byKey('shape-shadow-add'));
      await tester.pump();

      tester.widget<SliderField>(byKey('shape-shadow-opacity')).onChanged(0.3);
      await tester.pump();
      tester.widget<SliderField>(byKey('shape-shadow-spread')).onChanged(5);
      await tester.pump();

      final ShapeShadow shadow = (selected() as ShapeElement).shadow!;
      expect(shadow.opacity, 0.3);
      expect(shadow.spread, 5);
    });
  });

  group('قسم التأثيرات للصورة', () {
    testWidgets('التوهّج الخارجي والظل متاحان والداخلي غير متاح',
        (WidgetTester tester) async {
      buildController(image);
      await pumpToolbar(tester);

      expect(byKey('outer-glow-add'), findsOneWidget);
      expect(byKey('inner-glow-add'), findsNothing);
      expect(byKey('image-shadow-add'), findsOneWidget);
      expect(byKey('adjust-brightness'), findsOneWidget);
    });

    testWidgets('الضبط اللوني يُحدّث النموذج والإعادة تُزيله',
        (WidgetTester tester) async {
      buildController(image);
      await pumpToolbar(tester);

      expect(find.text('الضبط اللوني'), findsOneWidget);
      expect(byKey('adjust-contrast'), findsOneWidget);
      expect(byKey('adjust-saturation'), findsOneWidget);
      expect(byKey('adjust-hue'), findsOneWidget);

      tester.widget<SliderField>(byKey('adjust-brightness')).onChanged(0.35);
      await tester.pump();
      tester.widget<SliderField>(byKey('adjust-hue')).onChanged(45);
      await tester.pump();
      tester.widget<SliderField>(byKey('adjust-saturation')).onChanged(-0.5);
      await tester.pump();

      final ImageElement current = selected() as ImageElement;
      expect(current.adjustments!.brightness, 0.35);
      expect(current.adjustments!.hue, 45);
      expect(current.adjustments!.saturation, -0.5);
      expect(current.hasAdjustments, isTrue);

      await tester.ensureVisible(byKey('adjust-reset'));
      await tester.tap(byKey('adjust-reset'));
      await tester.pump();

      expect((selected() as ImageElement).adjustments, isNull);
      expect((selected() as ImageElement).hasAdjustments, isFalse);
    });

    testWidgets('ظل الصورة يُحدّث النموذج بإزاحته', (WidgetTester tester) async {
      buildController(image);
      await pumpToolbar(tester);

      await tester.ensureVisible(byKey('image-shadow-add'));
      await tester.tap(byKey('image-shadow-add'));
      await tester.pump();

      tester.widget<NumberField>(byKey('image-shadow-offset-x')).onChanged(12);
      await tester.pump();
      expect((selected() as ImageElement).shadow!.offsetX, 12);

      await tester.ensureVisible(byKey('image-shadow-remove'));
      await tester.tap(byKey('image-shadow-remove'));
      await tester.pump();
      expect((selected() as ImageElement).shadow, isNull);
    });
  });

  group('التكامل مع الأكورديون', () {
    testWidgets('فتح «المظهر والمؤثرات» يُغلق بقية الأقسام',
        (WidgetTester tester) async {
      buildController(text);
      final AccordionController accordion = AccordionController();
      addTearDown(accordion.dispose);
      await pumpToolbar(tester, accordion: accordion);

      // البداية: بلا اختيار صريح فتظهر كل الأقسام (تنسيق النص مثلاً).
      expect(find.text('حجم الخط'), findsOneWidget);

      await tester.ensureVisible(find.text('المظهر والمؤثرات'));
      await tester.tap(find.text('المظهر والمؤثرات'));
      await tester.pump();

      expect(accordion.expandedId, 'effects');
      expect(accordion.isExpanded('effects'), isTrue);
      expect(find.text('حجم الخط'), findsNothing);
      expect(byKey('outer-glow-add'), findsOneWidget);

      // وفتح قسم آخر يُغلق التأثيرات.
      await tester.ensureVisible(find.text('تنسيق النص'));
      await tester.tap(find.text('تنسيق النص'));
      await tester.pump();

      expect(accordion.isExpanded('effects'), isFalse);
      expect(find.text('حجم الخط'), findsOneWidget);
    });
  });
}
