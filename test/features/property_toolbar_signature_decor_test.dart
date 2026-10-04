import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/constants/app_constants.dart';
import 'package:joodcraft/core/editor/element_factory.dart';
import 'package:joodcraft/core/editor/template_editor_controller.dart';
import 'package:joodcraft/core/editor/widgets/editor_controls.dart';
import 'package:joodcraft/core/editor/widgets/property_toolbar.dart';
import 'package:joodcraft/core/models/decor_presets.dart';
import 'package:joodcraft/core/models/decoration.dart';
import 'package:joodcraft/core/models/template_document.dart';
import 'package:joodcraft/core/models/template_element.dart';
import 'package:joodcraft/core/theme/app_theme.dart';

/// اختبارات أدوات شريط الخصائص الجديدة: الزخرفة المتجهية، كتلة التوقيعات،
/// والضبط الدقيق (خطوات + عجلة الفأرة + تحجيم).
void main() {
  late TemplateEditorController controller;

  const DecorationElement decoration = DecorationElement(
    id: 'decor-1',
    box: ElementBox(x: 40, y: 40, width: 400, height: 300),
    spec: DecorSpec(kind: DecorKind.paperCut, layers: 2, seed: 3),
  );

  const SignatureElement signature = SignatureElement(
    id: 'sig-1',
    box: ElementBox(x: 60, y: 800, width: 600, height: 160),
    slots: <SignatureSlot>[
      SignatureSlot(role: 'المدير العام', name: 'أحمد حمدي'),
      SignatureSlot(role: 'الموارد البشرية'),
    ],
  );

  TemplateDocument document() => const TemplateDocument(
        elements: <TemplateElement>[decoration, signature],
      );

  setUp(() {
    controller = TemplateEditorController(
      document: document(),
      category: TemplateCategory.certificate,
    );
  });

  tearDown(() => controller.dispose());

  /// شريط الخصائص في مساحة واسعة حتى لا تقع الأدوات خارج نافذة الاختبار.
  Future<void> pumpToolbar(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 2800));
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

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  group('أدوات الزخرفة المتجهية', () {
    testWidgets('تحديد زخرفة يُظهر قسمها مع نوعها ولوحتها', (tester) async {
      await pumpToolbar(tester);
      controller.select('decor-1');
      await tester.pump();

      expect(find.text('الزخرفة المتجهية'), findsOneWidget);
      expect(find.text('نوع الزخرفة'), findsOneWidget);
      expect(find.text('لوحة الألوان'), findsOneWidget);
      expect(find.text('عدد الطبقات'), findsOneWidget);
      expect(find.text('البذرة'), findsOneWidget);
      expect(find.text('معرض الوصفات'), findsOneWidget);
      // اللوحة الافتراضية تطابق الألوان الافتراضية للوصفة.
      expect(find.text('ذهبي ملكي'), findsOneWidget);
    });

    testWidgets('تغيير النوع من القائمة يُحدّث الوصفة', (tester) async {
      await pumpToolbar(tester);
      controller.select('decor-1');
      await tester.pump();

      await tapVisible(tester, find.byKey(const ValueKey<String>('decor-kind')));
      await tester.tap(find.text('نمط غيوش الأمني').last);
      await tester.pumpAndSettle();

      final DecorationElement updated =
          controller.selected! as DecorationElement;
      expect(updated.spec.kind, DecorKind.guilloche);
      // بقية الوصفة محفوظة (الطبقات والبذرة).
      expect(updated.spec.layers, 2);
      expect(updated.spec.seed, 3);
    });

    testWidgets('اختيار لوحة ألوان يستبدل الألوان الثلاثة', (tester) async {
      await pumpToolbar(tester);
      controller.select('decor-1');
      await tester.pump();

      await tapVisible(
        tester,
        find.byKey(const ValueKey<String>('decor-palette')),
      );
      await tester.tap(find.text('زمردي').last);
      await tester.pumpAndSettle();

      final DecorationElement updated =
          controller.selected! as DecorationElement;
      final DecorPalette emerald = DecorPalette.byId('emerald');
      expect(updated.spec.primaryHex, emerald.primaryHex);
      expect(updated.spec.secondaryHex, emerald.secondaryHex);
      expect(updated.spec.accentHex, emerald.accentHex);
    });

    testWidgets('معرض الوصفات يُطبّق وصفة بنقرة واحدة', (tester) async {
      await pumpToolbar(tester);
      controller.select('decor-1');
      await tester.pump();

      await tapVisible(
        tester,
        find.byKey(const ValueKey<String>('decor-preset-gallery')),
      );
      expect(find.text('معرض الزخارف الجاهزة'), findsOneWidget);

      final DecorPreset preset = DecorPreset.forKind(DecorKind.ribbonBanner)
          .firstWhere((DecorPreset p) => p.id.endsWith('_emerald'));
      // بطاقات المعرض في قائمة قابلة للتمرير داخل الحوار، فتُمرَّر أولاً.
      await tapVisible(
        tester,
        find.byKey(ValueKey<String>('decor-preset-${preset.id}')),
      );

      // الحوار أُغلق ووُصِّفت الوصفة على العنصر.
      expect(find.text('معرض الزخارف الجاهزة'), findsNothing);
      final DecorationElement updated =
          controller.selected! as DecorationElement;
      expect(updated.spec.kind, DecorKind.ribbonBanner);
      expect(updated.spec.primaryHex, preset.spec.primaryHex);
    });

    testWidgets('ألوان الزخرفة تُعدّل من الحقول', (tester) async {
      await pumpToolbar(tester);
      controller.select('decor-1');
      await tester.pump();

      final Finder accentField = find.byWidgetPredicate(
        (Widget widget) => widget is ColorField && widget.label == 'لون اللمسة',
      );
      expect(accentField, findsOneWidget);
      final ColorField field = tester.widget<ColorField>(accentField);
      expect(field.hex, '#F4D58D');

      // زر «بلا لوحة» لا يُغيّر شيئاً هنا، لكن الحقل يقبل قيمة جديدة مباشرة.
      controller.setSelectedDecorSpec(
        (controller.selected! as DecorationElement)
            .spec
            .copyWith(accentHex: '#123456'),
      );
      await tester.pump();
      expect(
        (controller.selected! as DecorationElement).spec.accentHex,
        '#123456',
      );
    });
  });

  group('أدوات كتلة التوقيعات', () {
    testWidgets('تحديد كتلة توقيعات يُظهر محرّرات كل خانة', (tester) async {
      await pumpToolbar(tester);
      controller.select('sig-1');
      await tester.pump();

      expect(find.text('كتلة التوقيعات'), findsOneWidget);
      expect(find.text('عدد التوقيعات'), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('signature-role-0')),
          findsOneWidget);
      expect(find.byKey(const ValueKey<String>('signature-name-0')),
          findsOneWidget);
      // الخانات الثلاث مضبوطة افتراضياً لكل عنصر توقيعات.
      expect(find.byKey(const ValueKey<String>('signature-role-2')),
          findsOneWidget);
    });

    testWidgets('تعديل اسم المُوقّع يُحدّث العنصر فوراً', (tester) async {
      await pumpToolbar(tester);
      controller.select('sig-1');
      await tester.pump();

      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey<String>('signature-name-1')),
          matching: find.byType(TextField),
        ),
        'ليلى حسن',
      );
      await tester.pump();

      final SignatureElement updated =
          controller.selected! as SignatureElement;
      expect(updated.slots[1].name, 'ليلى حسن');
      expect(updated.slots[1].role, 'الموارد البشرية');
    });

    testWidgets('تعديل الدور يُحدّث العنصر', (tester) async {
      await pumpToolbar(tester);
      controller.select('sig-1');
      await tester.pump();

      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey<String>('signature-role-0')),
          matching: find.byType(TextField),
        ),
        'رئيس مجلس الإدارة',
      );
      await tester.pump();

      expect(
        (controller.selected! as SignatureElement).slots.first.role,
        'رئيس مجلس الإدارة',
      );
    });

    testWidgets('تغيير عدد التوقيعات يضبط slotCount', (tester) async {
      await pumpToolbar(tester);
      controller.select('sig-1');
      await tester.pump();

      await tapVisible(
        tester,
        find.byKey(const ValueKey<String>('signature-count')),
      );
      await tester.tap(find.text('توقيع واحد').last);
      await tester.pumpAndSettle();

      final SignatureElement updated =
          controller.selected! as SignatureElement;
      expect(updated.slotCount, 1);
      // محتوى الخانات الأخرى محفوظ (لا يُحذف بتصغير العدد).
      expect(updated.slots[1].name, '');
      expect(updated.activeSlots.length, 1);
    });

    testWidgets('المصنع الحقيقي يُدرج كتلة بثلاث خانات قابلة للتعديل',
        (tester) async {
      await pumpToolbar(tester);
      final TemplateElement created = controller.addElement(
        NewElementKind.signature,
      );
      controller.select(created.id);
      await tester.pump();

      expect(find.text('كتلة التوقيعات'), findsOneWidget);
      final SignatureElement element =
          controller.selected! as SignatureElement;
      expect(element.slots.length, 3);
      expect(element.hasDynamicFields, isTrue);
    });
  });

  group('الضبط الدقيق', () {
    testWidgets('أزرار النقل تحرّك العنصر بخطوة 1 افتراضياً', (tester) async {
      await pumpToolbar(tester);
      controller.select('decor-1');
      await tester.pump();

      final double startX = controller.selected!.box.x;
      await tapVisible(
        tester,
        find.byKey(const ValueKey<String>('nudge-right')),
      );
      expect(controller.selected!.box.x, closeTo(startX + 1, 0.001));

      await tapVisible(
        tester,
        find.byKey(const ValueKey<String>('nudge-up')),
      );
      expect(controller.selected!.box.y, closeTo(40 - 1, 0.001));
    });

    testWidgets('اختيار خطوة أكبر ينقل مسافة أكبر', (tester) async {
      await pumpToolbar(tester);
      controller.select('decor-1');
      await tester.pump();

      await tapVisible(tester, find.text('25'));
      final double startX = controller.selected!.box.x;
      await tapVisible(
        tester,
        find.byKey(const ValueKey<String>('nudge-right')),
      );

      expect(controller.selected!.box.x, closeTo(startX + 25, 0.001));
    });

    testWidgets('زر التحجيم يكبر الصندوق ويُبقي النسبة', (tester) async {
      await pumpToolbar(tester);
      controller.select('decor-1');
      await tester.pump();

      final ElementBox before = controller.selected!.box;
      await tapVisible(tester, find.byKey(const ValueKey<String>('scale-up')));
      await tapVisible(tester, find.byKey(const ValueKey<String>('scale-up')));

      final ElementBox after = controller.selected!.box;
      expect(after.width, closeTo(before.width * 1.1, 0.01));
      expect(after.height, closeTo(before.height * 1.1, 0.01));
      expect(find.text('110%'), findsOneWidget);
    });

    testWidgets('تحجيم نص يُكبّر حجم خطه أيضاً', (tester) async {
      await pumpToolbar(tester);
      final TemplateElement text = controller.addElement(NewElementKind.text);
      controller.select(text.id);
      await tester.pump();

      final double before = (controller.selected! as TextElement).fontSize;
      await tapVisible(tester, find.byKey(const ValueKey<String>('scale-up')));

      expect(
        (controller.selected! as TextElement).fontSize,
        closeTo(before * 1.05, 0.001),
      );
    });

    testWidgets('عجلة الفأرة فوق الحقل الرقمي تُعدّل القيمة بخطوة واحدة',
        (tester) async {
      await pumpToolbar(tester);
      controller.select('decor-1');
      await tester.pump();

      final Finder xField = find.byWidgetPredicate(
        (Widget widget) => widget is NumberField && widget.label == 'س',
      );
      expect(xField, findsOneWidget);

      final Offset center = tester.getCenter(xField);
      final TestGesture mouse =
          await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: center);
      addTearDown(mouse.removePointer);
      await tester.pump();
      await mouse.moveTo(center);
      await tester.pump();

      final double startX = controller.selected!.box.x;

      // دورة للأعلى ⇒ زيادة بخطوة واحدة.
      await tester.sendEventToBinding(
        PointerScrollEvent(position: center, scrollDelta: const Offset(0, -20)),
      );
      await tester.pump();
      expect(controller.selected!.box.x, closeTo(startX + 1, 0.001));

      // دورة للأسفل ⇒ إنقاص بخطوة واحدة (عودة للقيمة الأصلية).
      await tester.sendEventToBinding(
        PointerScrollEvent(position: center, scrollDelta: const Offset(0, 20)),
      );
      await tester.pump();
      expect(controller.selected!.box.x, closeTo(startX, 0.001));
    });
  });
}
