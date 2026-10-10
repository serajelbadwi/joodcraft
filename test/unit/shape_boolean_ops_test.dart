import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/constants/app_constants.dart';
import 'package:joodcraft/core/editor/template_editor_controller.dart';
import 'package:joodcraft/core/models/template_document.dart';
import 'package:joodcraft/core/models/template_element.dart';

/// اختبارات عمليات الدمج المنطقي على الأشكال في متحكّم المحرر.
void main() {
  TemplateEditorController buildController() => TemplateEditorController(
        document: const TemplateDocument(
          elements: <TemplateElement>[
            ShapeElement(
              id: 'a',
              kind: ShapeKind.rect,
              box: ElementBox(x: 0, y: 0, width: 100, height: 100),
              fillHex: '#C7A26B',
            ),
            ShapeElement(
              id: 'b',
              kind: ShapeKind.ellipse,
              box: ElementBox(x: 50, y: 50, width: 100, height: 100),
              fillHex: '#1B2539',
            ),
          ],
        ),
        category: TemplateCategory.certificate,
      );

  test('الدمج (union) يُنتج شكلاً مركّباً واحداً بأصل السفلي', () {
    final TemplateEditorController controller = buildController();
    addTearDown(controller.dispose);

    controller.select('a');
    controller.toggleSelection('b');
    expect(controller.selectionCount, 2);

    controller.applyShapeBoolean(ShapeBooleanOp.union);

    expect(controller.document.elements, hasLength(1));
    final ShapeElement compound =
        controller.document.elements.single as ShapeElement;
    expect(compound.isCompound, isTrue);
    expect(compound.booleanOp, ShapeBooleanOp.union);
    expect(compound.booleanParts, hasLength(2));
    // الصندوق يحيط بالشكلين (0..150).
    expect(compound.box.x, 0);
    expect(compound.box.y, 0);
    expect(compound.box.width, 150);
    expect(compound.box.height, 150);
    // الأجزاء بإحداثيات نسبية لأصل الشكل.
    expect(compound.booleanParts.first.box.x, 0);
    expect(compound.booleanParts.last.box.x, 50);
    // الحفظ يُحتفظ به في التعبئة.
    expect(compound.fillHex, '#C7A26B');
    expect(controller.selectionCount, 1);
  });

  test('الطرح والتقاطع والاستثناء يُخزَّنون كما هم', () {
    for (final ShapeBooleanOp op in <ShapeBooleanOp>[
      ShapeBooleanOp.subtract,
      ShapeBooleanOp.intersect,
      ShapeBooleanOp.exclude,
    ]) {
      final TemplateEditorController controller = buildController();
      controller.select('a');
      controller.toggleSelection('b');
      controller.applyShapeBoolean(op);
      final ShapeElement compound =
          controller.document.elements.single as ShapeElement;
      expect(compound.booleanOp, op);
      controller.dispose();
    }
  });

  test('الدمج يتطلّب تحديد شكلين على الأقل', () {
    final TemplateEditorController controller = buildController();
    addTearDown(controller.dispose);

    controller.select('a');
    controller.applyShapeBoolean(ShapeBooleanOp.union);
    expect(controller.document.elements, hasLength(2));
  });

  test('الفصل (ungroup) يُعيد الأشكال المكوّنة بإحداثيات مطلقة', () {
    final TemplateEditorController controller = buildController();
    addTearDown(controller.dispose);

    controller.select('a');
    controller.toggleSelection('b');
    controller.applyShapeBoolean(ShapeBooleanOp.union);
    controller.ungroupShapeBoolean();

    expect(controller.document.elements, hasLength(2));
    final ShapeElement first =
        controller.document.elements.first as ShapeElement;
    final ShapeElement last =
        controller.document.elements.last as ShapeElement;
    expect(first.isCompound, isFalse);
    expect(last.isCompound, isFalse);
    // الجزء الثاني كان عند (50,50) داخل الشكل المركّب أصله (0,0).
    expect(last.box.x, 50);
    expect(last.box.y, 50);
    expect(controller.selectionCount, 2);
  });

  test('القلب الأفقي/الرأسي يتبدّل على الأشكال المحددة', () {
    final TemplateEditorController controller = buildController();
    addTearDown(controller.dispose);

    controller.select('a');
    controller.flipSelectedHorizontal();
    expect((controller.selected! as ShapeElement).flipH, isTrue);
    controller.flipSelectedHorizontal();
    expect((controller.selected! as ShapeElement).flipH, isFalse);

    controller.flipSelectedVertical();
    expect((controller.selected! as ShapeElement).flipV, isTrue);
  });
}
