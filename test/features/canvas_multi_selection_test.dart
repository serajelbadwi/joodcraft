import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/constants/app_constants.dart';
import 'package:joodcraft/core/editor/template_editor_controller.dart';
import 'package:joodcraft/core/editor/widgets/element_view.dart';
import 'package:joodcraft/core/editor/widgets/template_canvas.dart';
import 'package:joodcraft/core/models/template_document.dart';
import 'package:joodcraft/core/models/template_element.dart';
import 'package:joodcraft/core/theme/app_theme.dart';

/// التحكم بالماوس في اللوحة: التحديد المتعدد بـ Ctrl والنقر، وصندوق التحديد بالسحب.
void main() {
  late TemplateEditorController controller;

  setUp(() {
    controller = TemplateEditorController(
      document: const TemplateDocument(
        orientation: PageOrientation.landscape,
        elements: <TemplateElement>[
          TextElement(
            id: 'text-1',
            box: ElementBox(x: 100, y: 100, width: 200, height: 80),
            text: 'الأول',
          ),
          TextElement(
            id: 'text-2',
            box: ElementBox(x: 400, y: 100, width: 200, height: 80),
            text: 'الثاني',
          ),
          QrElement(
            id: 'qr-1',
            box: ElementBox(x: 500, y: 450, width: 120, height: 120),
            data: 'x',
          ),
        ],
      ),
      category: TemplateCategory.certificate,
    );
  });

  tearDown(() => controller.dispose());

  Future<void> pumpCanvas(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: TemplateCanvas(controller: controller)),
      ),
    );
    await tester.pump();
  }

  testWidgets('Ctrl + نقر يُحدّد أكثر من عنصر معاً',
      (WidgetTester tester) async {
    await pumpCanvas(tester);
    expect(find.byType(ElementView), findsNWidgets(3));

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.tap(find.byType(ElementView).at(0));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byType(ElementView).at(1));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);

    expect(controller.selectionCount, 2);
    expect(controller.isSelected('text-1'), isTrue);
    expect(controller.isSelected('text-2'), isTrue);
  });

  testWidgets('النقر بلا Ctrl يُفرد التحديد على عنصر واحد',
      (WidgetTester tester) async {
    await pumpCanvas(tester);
    controller.selectAll();
    await tester.pump();

    await tester.tap(find.byType(ElementView).at(2));
    await tester.pump(const Duration(milliseconds: 400));

    expect(controller.selectionCount, 1);
    expect(controller.selectedId, 'qr-1');
  });

  testWidgets('السحب على الفراغ يرسم صندوق تحديد ويحدّد المتقاطع',
      (WidgetTester tester) async {
    await pumpCanvas(tester);

    final Offset start =
        tester.getTopLeft(find.byType(ElementView).at(0)) - const Offset(24, 24);
    final Offset end =
        tester.getBottomRight(find.byType(ElementView).at(1)) + const Offset(24, 24);

    final TestGesture gesture = await tester.startGesture(start);
    await gesture.moveBy(const Offset(30, 20));
    await tester.pump();
    await gesture.moveTo(end);
    await tester.pump();
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 400));

    expect(controller.isSelected('text-1'), isTrue);
    expect(controller.isSelected('text-2'), isTrue);
    // رمز QR أسفل الصفحة لم يتقاطع مع المستطيل.
    expect(controller.isSelected('qr-1'), isFalse);
  });

  testWidgets('سحب مجموعة يحرّك كل العناصر المحددة معاً',
      (WidgetTester tester) async {
    await pumpCanvas(tester);
    controller.selectMany(<String>['text-1', 'text-2']);
    await tester.pump();

    final ElementBox before1 = controller.document.elements[0].box;
    final ElementBox before2 = controller.document.elements[1].box;

    final TestGesture gesture =
        await tester.startGesture(tester.getCenter(find.byType(ElementView).at(0)));
    await gesture.moveBy(const Offset(30, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(60, 0));
    await tester.pump();
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 400));

    final double delta1 =
        controller.document.elements[0].box.x - before1.x;
    final double delta2 =
        controller.document.elements[1].box.x - before2.x;
    expect(delta1, greaterThan(0));
    // كتلة واحدة: الإزاحتان متساويتان تقريباً.
    expect(delta2, closeTo(delta1, 0.001));
    expect(controller.selectionCount, 2);
  });
}
