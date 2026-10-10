import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/constants/app_assets.dart';
import 'package:joodcraft/core/constants/app_constants.dart';
import 'package:joodcraft/core/editor/canvas_geometry.dart';
import 'package:joodcraft/core/editor/template_editor_controller.dart';
import 'package:joodcraft/core/editor/widgets/element_painters.dart';
import 'package:joodcraft/core/editor/widgets/element_view.dart';
import 'package:joodcraft/core/editor/widgets/template_canvas.dart';
import 'package:joodcraft/core/editor/widgets/template_editor_view.dart';
import 'package:joodcraft/core/models/template_document.dart';
import 'package:joodcraft/core/models/template_element.dart';
import 'package:joodcraft/core/theme/app_theme.dart';

void main() {
  const Size viewport = Size(800, 600);

  late TemplateEditorController controller;

  TemplateDocument document() => const TemplateDocument(
        orientation: PageOrientation.landscape,
        elements: <TemplateElement>[
          TextElement(
            id: 'a',
            box: ElementBox(x: 100, y: 100, width: 150, height: 80),
            text: 'الأول',
          ),
          TextElement(
            id: 'b',
            box: ElementBox(x: 500, y: 100, width: 150, height: 80),
            text: 'الثاني',
          ),
        ],
      );

  setUp(() {
    controller = TemplateEditorController(
      document: document(),
      category: TemplateCategory.certificate,
    );
  });

  tearDown(() => controller.dispose());

  bool isGuidePainter(Widget widget) =>
      widget is CustomPaint && widget.painter is SmartGuidesPainter;

  Future<void> pumpCanvas(WidgetTester tester, {bool snapToGuides = true}) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: TemplateCanvas(
            controller: controller,
            snapToGuides: snapToGuides,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  /// يسحب العنصر 'a' حتى تصبح حافته اليسرى على بعد [offset] وحدات من حافة 'b'.
  Future<TestGesture> dragLeftEdgeNear(
    WidgetTester tester, {
    double offset = 3,
  }) async {
    final double scale =
        CanvasGeometry.fit(viewport: viewport, design: controller.designSize).scale;
    final TestGesture gesture =
        await tester.startGesture(tester.getCenter(find.byType(ElementView).first));
    // استهلاك حدّ بدء الإيماءة.
    await gesture.moveBy(const Offset(30, 0));
    await tester.pump();

    final double currentX = controller.document.elements[0].box.x;
    final double targetX = controller.document.elements[1].box.x;
    await gesture.moveBy(Offset((targetX + offset - currentX) * scale, 0));
    await tester.pump();
    return gesture;
  }

  testWidgets('خط الإرشاد يظهر أثناء السحب ويختفي فور الإفلات',
      (WidgetTester tester) async {
    await pumpCanvas(tester);
    controller.select('a');
    await tester.pump();

    final TestGesture gesture = await dragLeftEdgeNear(tester);

    // التصاق تام بالحافة اليسرى للعنصر الآخر.
    expect(controller.document.elements[0].box.x, closeTo(500, 0.001));
    expect(find.byWidgetPredicate(isGuidePainter), findsOneWidget);

    await gesture.up();
    await tester.pump(const Duration(milliseconds: 400));

    // إخفاء كل الخطوط الإرشادية بعد الإفلات.
    expect(find.byWidgetPredicate(isGuidePainter), findsNothing);
  });

  testWidgets('تعطيل الخيار يُلغي الخطوط والالتصاق',
      (WidgetTester tester) async {
    await pumpCanvas(tester, snapToGuides: false);
    controller.select('a');
    await tester.pump();

    final TestGesture gesture = await dragLeftEdgeNear(tester, offset: 3);

    // بلا التصاق: العنصر يبقى على مسافة 3 وحدات من الحافة.
    final double x = controller.document.elements[0].box.x;
    expect((x - 500).abs(), closeTo(3, 0.5));
    expect(find.byWidgetPredicate(isGuidePainter), findsNothing);

    await gesture.up();
    await tester.pump(const Duration(milliseconds: 400));
  });

  testWidgets('زر التبديل في شريط المحرّر يُعطّل خطوط الإرشاد',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: TemplateEditorView(
            category: TemplateCategory.certificate,
            initialTemplateAsset: AppAssets.sampleCertificateTemplate,
            exportFileName: 'joodcraft-certificate.pdf',
            document: document(),
          ),
        ),
      ),
    );
    await tester.pump();

    TemplateCanvas canvas() =>
        tester.widget<TemplateCanvas>(find.byType(TemplateCanvas));
    expect(canvas().snapToGuides, isTrue);

    final Finder guides = find.byKey(const ValueKey<String>('toggle-snap-guides'));
    await tester.ensureVisible(guides);
    await tester.tap(guides);
    await tester.pump();
    expect(canvas().snapToGuides, isFalse);
  });
}
