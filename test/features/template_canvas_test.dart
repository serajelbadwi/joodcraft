import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/constants/app_constants.dart';
import 'package:joodcraft/core/editor/canvas_geometry.dart';
import 'package:joodcraft/core/editor/template_editor_controller.dart';
import 'package:joodcraft/core/editor/widgets/element_view.dart';
import 'package:joodcraft/core/editor/widgets/template_canvas.dart';
import 'package:joodcraft/core/models/template_document.dart';
import 'package:joodcraft/core/models/template_element.dart';
import 'package:joodcraft/core/theme/app_theme.dart';

void main() {
  /// مساحة الاختبار الافتراضية في `flutter_test` = 800×600.
  const Size viewport = Size(800, 600);

  /// نفس حساب اللوحة تماماً — لتوقّع الإحداثيات بلا أرقام سحرية.
  late Size design;
  late CanvasGeometry geometry;

  late TemplateEditorController controller;

  setUp(() {
    controller = TemplateEditorController(
      document: const TemplateDocument(
        orientation: PageOrientation.landscape,
        elements: <TemplateElement>[
          TextElement(
            id: 'text-1',
            box: ElementBox(x: 200, y: 200, width: 300, height: 80),
            text: 'شهادة إتمام',
          ),
        ],
      ),
      category: TemplateCategory.certificate,
    );
    design = controller.designSize;
    geometry = CanvasGeometry.fit(viewport: viewport, design: design);
  });

  tearDown(() => controller.dispose());

  Future<void> pumpCanvas(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: TemplateCanvas(controller: controller),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('الورقة تُعرض بنفس نِسب A4 الأفقي', (WidgetTester tester) async {
    await pumpCanvas(tester);

    final Size paper = geometry.pageSize(design);
    expect(paper.width / paper.height, closeTo(design.width / design.height, 0.01));
    expect(find.byType(ElementView), findsOneWidget);
  });

  testWidgets('النقر على العنصر يُحدّده', (WidgetTester tester) async {
    await pumpCanvas(tester);
    expect(controller.hasSelection, isFalse);

    await tester.tap(find.byType(ElementView));
    // الانتظار يتجاوز مهلة النقر المزدوج حتى يُحسم النقر المفرد.
    await tester.pump(const Duration(milliseconds: 400));

    expect(controller.selectedId, 'text-1');
  });

  testWidgets('النقر على فراغ الورقة يُلغي التحديد', (WidgetTester tester) async {
    await pumpCanvas(tester);
    controller.select('text-1');
    await tester.pump();

    await tester.tapAt(const Offset(10, 10));
    await tester.pump();

    expect(controller.hasSelection, isFalse);
  });

  /// إيماءة سحب على مرحلتين.
  ///
  /// المرحلة الأولى تستنفد "مسافة بدء الإيماءة" التي يستهلكها إطار العمل قبل
  /// اعتماد السحب، والثانية تُسلَّم كاملة — فيصبح القياس **حتمياً** لا يعتمد
  /// على تفاصيل تنفيذ إيماءات فلاتر.
  Future<ElementBox> dragAndMeasure(
    WidgetTester tester,
    Finder finder, {
    Offset prelude = const Offset(30, 0),
    Offset measured = const Offset(60, 0),
  }) async {
    final TestGesture gesture = await tester.startGesture(tester.getCenter(finder));
    await gesture.moveBy(prelude);
    await tester.pump();
    final ElementBox before = controller.selected!.box;
    await gesture.moveBy(measured);
    await tester.pump();
    await gesture.up();
    // الانتظار يتجاوز مؤقّت النقر المزدوج حتى لا تبقى مؤقّتات معلّقة في الاختبار.
    await tester.pump(const Duration(milliseconds: 400));
    return before;
  }

  testWidgets('السحب يُحرّك العنصر بإزاحة الشاشة مقسومة على معامل العرض',
      (WidgetTester tester) async {
    await pumpCanvas(tester);
    controller.select('text-1');
    await tester.pump();

    final ElementBox before = await dragAndMeasure(
      tester,
      find.byType(ElementView),
      measured: const Offset(60, 0),
    );

    expect(
      controller.selected!.box.x - before.x,
      closeTo(60 / geometry.scale, 1),
    );
    expect(controller.selected!.box.y, closeTo(before.y, 0.001));

    // الحركة تُسجَّل كتعديل كامل قابل للتراجع في خطوة واحدة.
    expect(controller.hasUnsavedChanges, isTrue);
    controller.undo();
    expect(controller.selected!.box.x, closeTo(200, 0.001));
  });

  testWidgets('إزاحة السحب تتحول إلى وحدات تصميم لا إلى بكسل',
      (WidgetTester tester) async {
    await pumpCanvas(tester);
    controller.select('text-1');
    await tester.pump();

    // المعامل أقل من 1 ⇒ إزاحة التصميم أكبر من إزاحة الشاشة.
    expect(geometry.scale, lessThan(1));

    final ElementBox before = await dragAndMeasure(
      tester,
      find.byType(ElementView),
      measured: const Offset(200, 0),
    );

    final double moved = controller.selected!.box.x - before.x;
    expect(moved, closeTo(200 / geometry.scale, 1));
    expect(moved, greaterThan(200));
  });

  testWidgets('مقبض التحجيم يغيّر عرض العنصر', (WidgetTester tester) async {
    await pumpCanvas(tester);
    controller.select('text-1');
    await tester.pump();

    expect(find.byKey(const Key('handle-right')), findsOneWidget);

    final ElementBox before = await dragAndMeasure(
      tester,
      find.byKey(const Key('handle-right')),
      measured: const Offset(80, 0),
    );

    expect(
      controller.selected!.box.width - before.width,
      closeTo(80 / geometry.scale, 1),
    );
    expect(controller.selected!.box.height, closeTo(80, 0.001));
    expect(controller.selected!.box.x, closeTo(200, 0.001));
  });

  testWidgets('مقبض التحجيم السفلي يغيّر الارتفاع فقط', (WidgetTester tester) async {
    await pumpCanvas(tester);
    controller.select('text-1');
    await tester.pump();

    final ElementBox before = await dragAndMeasure(
      tester,
      find.byKey(const Key('handle-bottom')),
      prelude: const Offset(0, 30),
      measured: const Offset(0, 40),
    );

    expect(controller.selected!.box.width, closeTo(300, 0.001));
    expect(
      controller.selected!.box.height - before.height,
      closeTo(40 / geometry.scale, 1),
    );
  });

  testWidgets('مقبض التحجيم لا يسمح بحجم أصغر من الحد الأدنى',
      (WidgetTester tester) async {
    await pumpCanvas(tester);
    controller.select('text-1');
    await tester.pump();

    await tester.drag(
      find.byKey(const Key('handle-right')),
      const Offset(-900, 0),
      touchSlopX: 0,
      touchSlopY: 0,
    );
    await tester.pump();

    expect(
      controller.selected!.box.width,
      greaterThanOrEqualTo(TemplateEditorController.minElementSize),
    );
  });

  testWidgets('مقبض التدوير يدوّر العنصر', (WidgetTester tester) async {
    await pumpCanvas(tester);
    controller.select('text-1');
    await tester.pump();

    expect(find.byKey(const Key('handle-rotate')), findsOneWidget);

    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const Key('handle-rotate'))),
    );
    await gesture.moveBy(const Offset(40, 20));
    await tester.pump();
    await gesture.moveBy(const Offset(40, 20));
    await tester.pump();
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 400));

    expect(controller.selected!.rotation, isNot(0));
    expect(controller.selected!.rotation.abs(), lessThanOrEqualTo(180));
  });

  testWidgets('مقابس التحديد كلها موجودة (8 تحجيم + تدوير)',
      (WidgetTester tester) async {
    await pumpCanvas(tester);
    controller.select('text-1');
    await tester.pump();

    for (final String handle in <String>[
      'topLeft',
      'top',
      'topRight',
      'right',
      'bottomRight',
      'bottom',
      'bottomLeft',
      'left',
      'rotate',
    ]) {
      expect(find.byKey(Key('handle-$handle')), findsOneWidget);
    }
  });

  testWidgets('النقر المزدوج على نص يطلب تحرير المحتوى', (WidgetTester tester) async {
    TextElement? requested;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: TemplateCanvas(
            controller: controller,
            onRequestTextEdit: (TextElement element) => requested = element,
          ),
        ),
      ),
    );
    await tester.pump();

    final Offset center = tester.getCenter(find.byType(ElementView));
    await tester.tapAt(center);
    await tester.pump(const Duration(milliseconds: 60));
    await tester.tapAt(center);
    await tester.pump(const Duration(milliseconds: 400));

    expect(requested?.id, 'text-1');
  });

  testWidgets('النقر المزدوج على فراغ الورقة يضيف نصاً في الموضع',
      (WidgetTester tester) async {
    await pumpCanvas(tester);
    final int before = controller.document.elements.length;

    final Offset position = geometry.toScreen(const Offset(600, 500));
    await tester.tapAt(position);
    await tester.pump(const Duration(milliseconds: 60));
    await tester.tapAt(position);
    await tester.pump(const Duration(milliseconds: 400));

    expect(controller.document.elements.length, before + 1);
    expect(controller.selectedId, isNotNull);
  });

  testWidgets('التكبير يكبّر الورقة بلا تغيير الإحداثيات المنطقية',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: TemplateCanvas(controller: controller, zoom: 1.5)),
      ),
    );
    await tester.pump();

    final Size paper = tester.getSize(find.byType(TemplateCanvas));
    expect(paper.width, viewport.width);
    expect(controller.selected, isNull);
  });

  // ==========================================================================
  //  اختبار الإصابة: العنصر الأصغر/الأدلى تحت المؤشر
  // ==========================================================================

  /// يُنشئ وثيقة جديدة ويُعيد ضبط المقياس ليطابق ما يبنيه المحرّر فعلياً.
  void useDocument(List<TemplateElement> elements) {
    controller.dispose();
    controller = TemplateEditorController(
      document: TemplateDocument(elements: elements),
      category: TemplateCategory.certificate,
    );
    design = controller.designSize;
    geometry = CanvasGeometry.fit(viewport: viewport, design: design);
  }

  ShapeElement solidRect(String id, ElementBox box) => ShapeElement(
        id: id,
        box: box,
        kind: ShapeKind.rect,
        fillHex: '#FFFFFFFF',
      );

  /// حاوية مفرغة: حدود فقط بلا تعبئة (كالإطار).
  ShapeElement outlineRect(String id, ElementBox box) => ShapeElement(
        id: id,
        box: box,
        kind: ShapeKind.rect,
        strokeHex: '#FF1B2539',
        strokeWidth: 6,
      );

  /// نقرة واحدة على نقطة بوحدات التصميم، مع تجاوز مؤقّت النقر المزدوج.
  Future<void> tapDesign(WidgetTester tester, Offset designPoint) async {
    await tester.tapAt(geometry.toScreen(designPoint));
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('نقرة أولى على عنصر صغير داخل عنصر أكبر تحدّد الصغير',
      (WidgetTester tester) async {
    // الأكبر **آخر** في القائمة ⇒ مرسوم فوق الصغير؛ ومع ذلك يفوز الأصغر.
    useDocument(<TemplateElement>[
      TextElement(
        id: 'small-1',
        box: const ElementBox(x: 350, y: 250, width: 120, height: 60),
        text: 'عنصر صغير',
      ),
      solidRect(
        'big-1',
        const ElementBox(x: 100, y: 100, width: 600, height: 400),
      ),
    ]);
    await pumpCanvas(tester);
    expect(controller.hasSelection, isFalse);

    // النقرة على مركز الصغير — من أول نقرة ودون تردد.
    await tapDesign(tester, const Offset(410, 280));
    expect(controller.selectedId, 'small-1');

    // والنقرة خارج الصغير داخل الكبير تُصيب الكبير (هو المرشّح الوحيد هناك).
    controller.clearSelection();
    await tester.pump();
    await tapDesign(tester, const Offset(150, 150));
    expect(controller.selectedId, 'big-1');
  });

  testWidgets('الحاوية المفرغة لا تسرق نقرة ما داخلها إلا على حدّها',
      (WidgetTester tester) async {
    useDocument(<TemplateElement>[
      TextElement(
        id: 'small-1',
        box: const ElementBox(x: 350, y: 250, width: 120, height: 60),
        text: 'عنصر صغير',
      ),
      outlineRect(
        'frame-1',
        const ElementBox(x: 100, y: 100, width: 600, height: 400),
      ),
    ]);
    await pumpCanvas(tester);

    // 1) النقرة على الصغير داخل الحاوية ⇒ الصغير من أول نقرة.
    await tapDesign(tester, const Offset(410, 280));
    expect(controller.selectedId, 'small-1');

    // 2) النقرة في قلب الحاوية المفرغة (بعيداً عن حدّها وعن الصغير) ⇒ لا شيء:
    //    لا تُخطِف الحاوية النقرة بل تمرّ إلى الورقة فتُلغى.
    await tapDesign(tester, const Offset(550, 400));
    expect(controller.hasSelection, isFalse);
    expect(controller.selectedId, isNot('frame-1'));

    // 3) النقرة على حدّ الحاوية ⇒ الحاوية هي المستهدف.
    await tapDesign(tester, const Offset(110, 400));
    expect(controller.selectedId, 'frame-1');
  });
}
