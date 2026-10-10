import 'dart:ui' show Path, Rect;

import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/constants/app_constants.dart';
import 'package:joodcraft/core/editor/template_editor_controller.dart';
import 'package:joodcraft/core/editor/widgets/element_painters.dart';
import 'package:joodcraft/core/models/template_document.dart';
import 'package:joodcraft/core/models/template_element.dart';

/// اختبارات **المسار المدمَج الحقيقي** — تُبنى الأشكال المركّبة بـ
/// `Path.combine` فتنتج مساراً واحداً بالهندسة الصحيحة، لا مجرد أجزاء متجاورة.
void main() {
  /// مستطيل (0..100) وبيضاوي مركزه (100, 100) ونصف قطره 50 — متقاطعان في
  /// الربع (50..100) فيسهل التحقّق من كل عملية على نقاط معروفة.
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

  ShapeElement compoundWith(ShapeBooleanOp op) {
    final TemplateEditorController controller = buildController();
    addTearDown(controller.dispose);
    controller.select('a');
    controller.toggleSelection('b');
    controller.applyShapeBoolean(op);
    return controller.document.elements.single as ShapeElement;
  }

  Path pathOf(ShapeBooleanOp op) => compoundBooleanPath(compoundWith(op), 1);

  test('كل عملية تُخزَّن وتُقرأ من JSON كما هي', () {
    for (final ShapeBooleanOp op in ShapeBooleanOp.values) {
      final ShapeElement compound = compoundWith(op);
      expect(compound.isCompound, isTrue);
      expect(compound.booleanOp, op);
      expect(compound.booleanParts, hasLength(2));
      expect(
        ShapeBooleanOp.fromJson(compound.toJson()['boolean']),
        op,
        reason: 'العملية تُحفظ وتُقرأ من JSON بلا فقد',
      );
    }
  });

  test('الدمج (union) مسار واحد بالحدود الخارجية فقط', () {
    final Path path = pathOf(ShapeBooleanOp.union);
    expect(path.getBounds(), const Rect.fromLTRB(0, 0, 150, 150));
    // منطقة المستطيل وحدها، والبيضاوي وحده، والمنطقة المتقاطعة — كلها مملوءة.
    expect(path.contains(const Offset(25, 25)), isTrue);
    expect(path.contains(const Offset(120, 120)), isTrue);
    expect(path.contains(const Offset(75, 75)), isTrue);
    // **مسار واحد** لا مسارين متجاورين: لم تُرسم حدود داخلية.
    expect(path.computeMetrics().length, 1);
  });

  test('الطرح (subtract) يُفرِّغ المتقاطع من الشكل السفلي', () {
    final Path path = pathOf(ShapeBooleanOp.subtract);
    expect(path.getBounds(), const Rect.fromLTRB(0, 0, 100, 100));
    expect(path.contains(const Offset(25, 25)), isTrue);
    expect(path.contains(const Offset(75, 75)), isFalse);
    expect(path.contains(const Offset(120, 120)), isFalse);
    expect(path.computeMetrics().length, 1);
  });

  test('التقاطع (intersect) يُبقي المتقاطع وحده', () {
    final Path path = pathOf(ShapeBooleanOp.intersect);
    final Rect bounds = path.getBounds();
    expect(bounds.left, greaterThanOrEqualTo(50));
    expect(bounds.top, greaterThanOrEqualTo(50));
    expect(bounds.width, lessThanOrEqualTo(50));
    expect(bounds.height, lessThanOrEqualTo(50));
    expect(path.contains(const Offset(75, 75)), isTrue);
    expect(path.contains(const Offset(25, 25)), isFalse);
    expect(path.computeMetrics().length, 1);
  });

  test('الاستثناء (exclude) يحذف المتقاطع ويُبقي الأطراف', () {
    final Path path = pathOf(ShapeBooleanOp.exclude);
    expect(path.getBounds(), const Rect.fromLTRB(0, 0, 150, 150));
    expect(path.contains(const Offset(25, 25)), isTrue);
    expect(path.contains(const Offset(120, 120)), isTrue);
    expect(path.contains(const Offset(75, 75)), isFalse);
    // منطقتان منفصلتان بلا المتقاطع.
    expect(path.computeMetrics().length, 2);
  });

  test('فصل الشكل المركّب يُعيد الأجزاء ثم يُعاد دمجها بنفس النتيجة', () {
    final TemplateEditorController controller = buildController();
    addTearDown(controller.dispose);
    controller.select('a');
    controller.toggleSelection('b');
    controller.applyShapeBoolean(ShapeBooleanOp.exclude);
    final Path before = compoundBooleanPath(
      controller.document.elements.single as ShapeElement,
      1,
    );

    controller.ungroupShapeBoolean();
    expect(controller.document.elements, hasLength(2));
    controller.applyShapeBoolean(ShapeBooleanOp.exclude);
    final Path after = compoundBooleanPath(
      controller.document.elements.single as ShapeElement,
      1,
    );

    expect(after.getBounds(), before.getBounds());
    expect(after.contains(const Offset(75, 75)), isFalse);
  });

  test('قراءة العملية من JSON تقبل الأسماء البديلة', () {
    expect(ShapeBooleanOp.fromJson('xor'), ShapeBooleanOp.exclude);
    expect(ShapeBooleanOp.fromJson('EXCLUDE'), ShapeBooleanOp.exclude);
    expect(ShapeBooleanOp.fromJson('difference'), ShapeBooleanOp.subtract);
    expect(ShapeBooleanOp.fromJson('nonsense'), isNull);
  });

  test('كل عملية منطقية تقابل عملية `Path.combine` المقابلة', () {
    expect(pathOperationFor(ShapeBooleanOp.union).name, 'union');
    expect(pathOperationFor(ShapeBooleanOp.subtract).name, 'difference');
    expect(pathOperationFor(ShapeBooleanOp.intersect).name, 'intersect');
    expect(pathOperationFor(ShapeBooleanOp.exclude).name, 'xor');
  });
}
