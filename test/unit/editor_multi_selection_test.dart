import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/constants/app_constants.dart';
import 'package:joodcraft/core/editor/template_editor_controller.dart';
import 'package:joodcraft/core/models/template_document.dart';
import 'package:joodcraft/core/models/template_element.dart';

void main() {
  late TemplateEditorController controller;

  /// ثلاثة عناصر: نصان ورمز QR — ترتيب الرسم: text-1, text-2, qr-1.
  TemplateDocument document() => const TemplateDocument(
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
            box: ElementBox(x: 500, y: 400, width: 120, height: 120),
            data: 'x',
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

  List<String> order() => controller.document.elements
      .map((TemplateElement element) => element.id)
      .toList(growable: false);

  group('التحديد المتعدد', () {
    test('Ctrl + نقر يُضيف ويُزيل دون فقدان الباقي', () {
      controller.select('text-1');
      controller.toggleSelection('text-2');

      expect(controller.selectionCount, 2);
      expect(controller.isSelected('text-1'), isTrue);
      expect(controller.isSelected('text-2'), isTrue);
      expect(controller.selectedId, 'text-2');

      controller.toggleSelection('text-1');
      expect(controller.selectionCount, 1);
      expect(controller.isSelected('text-1'), isFalse);
      expect(controller.selectedId, 'text-2');
    });

    test('selectMany يستبدل التحديد، وselectAll يُحدّد الكل', () {
      controller.selectMany(<String>['text-1', 'qr-1']);
      expect(controller.selectionCount, 2);

      controller.selectAll();
      expect(controller.selectionCount, 3);

      controller.selectMany(<String>['ghost', 'text-1']);
      expect(controller.selectionCount, 1);
      expect(controller.selectedId, 'text-1');
    });

    test('selectWithin يُحدّد العناصر المتقاطعة مع المستطيل فقط', () {
      controller.selectWithin(const Rect.fromLTWH(0, 0, 250, 250));
      expect(controller.selectedIds, <String>['text-1']);
    });

    test('selectWithin الإضافي يُضيف إلى التحديد الحالي', () {
      controller.select('qr-1');
      controller.selectWithin(
        const Rect.fromLTWH(0, 0, 250, 250),
        additive: true,
      );
      expect(controller.selectionCount, 2);
      expect(controller.isSelected('qr-1'), isTrue);
      expect(controller.isSelected('text-1'), isTrue);
    });

    test('إلغاء التحديد يُفرغ المجموعة', () {
      controller.selectAll();
      controller.clearSelection();
      expect(controller.hasSelection, isFalse);
      expect(controller.selectionCount, 0);
    });
  });

  group('عمليات المجموعة', () {
    test('الحذف يُزيل كل المحدد، والتراجع يُعيده', () {
      controller.selectAll();
      controller.deleteSelected();
      expect(controller.document.elements, isEmpty);
      expect(controller.hasSelection, isFalse);

      controller.undo();
      expect(controller.document.elements.length, 3);
    });

    test('التحريك يزيح كل المحدد بنفس المقدار', () {
      controller.selectMany(<String>['text-1', 'text-2']);
      controller.moveSelectedBy(10, 5, snap: false);

      expect(controller.document.elements[0].box.x, closeTo(110, 0.001));
      expect(controller.document.elements[0].box.y, closeTo(105, 0.001));
      expect(controller.document.elements[1].box.x, closeTo(410, 0.001));
      // غير المحدد لا يتحرك.
      expect(controller.document.elements[2].box.x, closeTo(500, 0.001));
    });

    test('التكرار يُنسخ كل المحدد ويُحدّد النسخ', () {
      controller.selectMany(<String>['text-1', 'text-2']);
      controller.duplicateSelected();

      expect(controller.document.elements.length, 5);
      expect(controller.selectionCount, 2);
      final List<String> copies = controller.selectedIds;
      expect(copies, isNot(contains('text-1')));
      expect(copies, isNot(contains('text-2')));
      // النسخ مُزاحة بـ 18 وحدة.
      final TextElement copy =
          controller.selectedElements.first as TextElement;
      expect(copy.box.x, closeTo(118, 0.001));
    });

    test('النسخ واللصق بمعرّفات جديدة وإزاحة وتحديد', () {
      controller.select('text-1');
      controller.copySelection();
      expect(controller.hasClipboard, isTrue);

      controller.pasteClipboard();
      expect(controller.document.elements.length, 4);
      expect(controller.selectionCount, 1);
      final TextElement pasted = controller.selected! as TextElement;
      expect(pasted.id, isNot('text-1'));
      expect(pasted.box.x, closeTo(118, 0.001));
      expect(pasted.text, 'الأول');
    });

    test('القص يُزيل الأصل ويُلصق نسخة لاحقاً', () {
      controller.select('text-2');
      controller.cutSelection();

      expect(controller.document.elements.length, 2);
      expect(controller.hasSelection, isFalse);

      controller.pasteClipboard();
      expect(controller.document.elements.length, 3);
      expect((controller.selected! as TextElement).text, 'الثاني');
    });

    test('الترتيب: إلى المقدمة والخلف يُعيدان المجموعة كاملة', () {
      controller.select('text-1');
      controller.sendToBack();
      expect(order(), <String>['text-1', 'text-2', 'qr-1']);

      controller.select('qr-1');
      controller.sendToBack();
      expect(order(), <String>['qr-1', 'text-1', 'text-2']);

      controller.select('qr-1');
      controller.bringToFront();
      expect(order(), <String>['text-1', 'text-2', 'qr-1']);
    });

    test('الشفافية تُطبّق على كل المحدد', () {
      controller.selectMany(<String>['text-1', 'text-2']);
      controller.setSelectedOpacity(0.4);

      expect((controller.document.elements[0] as TextElement).opacity, 0.4);
      expect((controller.document.elements[1] as TextElement).opacity, 0.4);
      expect(controller.document.elements[2], isA<QrElement>());
    });

    test('ترتيب خطوة يحفظ الترتيب النسبي داخل المجموعة', () {
      // تحديد العنصر الأول والثالث ثم تمريرهما خطوة للأمام.
      controller.selectMany(<String>['text-1', 'qr-1']);
      controller.bringForward();
      // text-1 يتقدّم خطوة، وqr-1 في المقدمة أصلاً فلا يتجاوز حدّه.
      expect(order(), <String>['text-2', 'text-1', 'qr-1']);
    });
  });
}
