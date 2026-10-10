import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:joodcraft/core/constants/app_constants.dart';
import 'package:joodcraft/core/editor/template_editor_controller.dart';
import 'package:joodcraft/core/editor/widgets/template_canvas.dart';
import 'package:joodcraft/core/models/template_document.dart';
import 'package:joodcraft/core/models/template_element.dart';
import 'package:joodcraft/core/pdf/pdf_color.dart';
import 'package:joodcraft/core/pdf/pdf_render_engine.dart';
import 'package:joodcraft/core/utils/hex_color.dart';

/// اختبارات الإصلاح الشامل للوحة: الطبقات والمجموعات والمحاذاة والأبعاد
/// المخصّصة وتدرّج الخلفية — كلها منطق نقيّ قابل للاختبار بلا واجهة.
void main() {
  TemplateDocument threeElements() => const TemplateDocument(
        orientation: PageOrientation.landscape,
        elements: <TemplateElement>[
          TextElement(
            id: 'a',
            box: ElementBox(x: 0, y: 0, width: 100, height: 50),
            text: 'أ',
          ),
          TextElement(
            id: 'b',
            box: ElementBox(x: 200, y: 300, width: 50, height: 50),
            text: 'ب',
          ),
          TextElement(
            id: 'c',
            box: ElementBox(x: 400, y: 100, width: 80, height: 40),
            text: 'ج',
          ),
        ],
      );

  group('حالة الطبقات', () {
    test('الإخفاء والقفل يُحفظان في المستند ويُستعادان من JSON', () {
      final TemplateEditorController controller = TemplateEditorController(
        document: threeElements(),
        category: TemplateCategory.certificate,
      );
      addTearDown(controller.dispose);

      controller.setElementHidden('a', true);
      controller.setElementLocked('b', true);

      expect(controller.document.isHidden('a'), isTrue);
      expect(controller.document.isVisible(controller.document.elements[1]),
          isTrue);
      expect(controller.document.isLocked('b'), isTrue);
      // المخفي خارج قائمة الرسم (لوحة وطباعة).
      expect(
        controller.document.visibleElements.map((TemplateElement e) => e.id),
        isNot(contains('a')),
      );

      final TemplateDocument restored =
          TemplateDocument.fromJson(controller.document.toJson());
      expect(restored.isHidden('a'), isTrue);
      expect(restored.isLocked('b'), isTrue);
      expect(restored.isLocked('a'), isFalse);
    });

    test('المخفي والمقفل يُستبعدان من تحديد الكل ومن مستطيل السحب', () {
      final TemplateEditorController controller = TemplateEditorController(
        document: threeElements(),
        category: TemplateCategory.certificate,
      );
      addTearDown(controller.dispose);

      controller.setElementHidden('a', true);
      controller.setElementLocked('c', true);

      controller.selectAll();
      expect(controller.selectionCount, 1);
      expect(controller.isSelected('b'), isTrue);

      controller.selectWithin(const Rect.fromLTWH(0, 0, 1000, 1000));
      expect(controller.selectionCount, 1);
      expect(controller.isSelected('b'), isTrue);
    });

    test('إخفاء عنصر محدد يُزيله من التحديد فوراً', () {
      final TemplateEditorController controller = TemplateEditorController(
        document: threeElements(),
        category: TemplateCategory.certificate,
      );
      addTearDown(controller.dispose);

      controller.select('a');
      controller.setElementHidden('a', true);
      expect(controller.hasSelection, isFalse);
    });

    test('نقل عنصر في الترتيب يُعيد ترتيب الرسم فعلاً', () {
      final TemplateEditorController controller = TemplateEditorController(
        document: threeElements(),
        category: TemplateCategory.certificate,
      );
      addTearDown(controller.dispose);

      controller.moveElementTo('a', 2);
      expect(
        controller.document.elements.map((TemplateElement e) => e.id).toList(),
        <String>['b', 'c', 'a'],
      );
    });

    test('ترتيب الطبقات المعروض من الأعلى إلى الأسفل', () {
      final TemplateEditorController controller = TemplateEditorController(
        document: threeElements(),
        category: TemplateCategory.certificate,
      );
      addTearDown(controller.dispose);
      expect(
        controller.layerOrder.map((TemplateElement e) => e.id).toList(),
        <String>['c', 'b', 'a'],
      );
    });
  });

  group('المجموعات والمحاذاة', () {
    test('التجميع يجعل نقر عضو يحدّد كل أعضاء المجموعة', () {
      final TemplateEditorController controller = TemplateEditorController(
        document: threeElements(),
        category: TemplateCategory.certificate,
      );
      addTearDown(controller.dispose);

      controller.selectMany(<String>['a', 'b']);
      controller.groupSelection();
      expect(controller.selectionIsGrouped, isTrue);

      controller.select('a');
      expect(controller.selectionCount, 2);
      expect(controller.isSelected('b'), isTrue);

      controller.ungroupSelection();
      expect(controller.selectionIsGrouped, isFalse);
      controller.select('a');
      expect(controller.selectionCount, 1);
    });

    test('المحاذاة لليسار تُصفّف الحد الأيسر لكل العناصر', () {
      final TemplateEditorController controller = TemplateEditorController(
        document: threeElements(),
        category: TemplateCategory.certificate,
      );
      addTearDown(controller.dispose);

      controller.selectMany(<String>['a', 'b']);
      controller.alignSelection(LayerAlign.left);
      expect(controller.document.elements[0].box.x, 0);
      expect(controller.document.elements[1].box.x, 0);
    });

    test('المحاذاة للأعلى تُصفّف الحد الأعلى لكل العناصر', () {
      final TemplateEditorController controller = TemplateEditorController(
        document: threeElements(),
        category: TemplateCategory.certificate,
      );
      addTearDown(controller.dispose);

      controller.selectMany(<String>['a', 'c']);
      controller.alignSelection(LayerAlign.top);
      expect(controller.document.elements[0].box.y, 0);
      expect(controller.document.elements[2].box.y, 0);
    });
  });

  group('التلوين الجماعي', () {
    TemplateDocument mixed() => const TemplateDocument(
          orientation: PageOrientation.landscape,
          elements: <TemplateElement>[
            ImageElement(
              id: 'img-1',
              box: ElementBox(x: 0, y: 0, width: 50, height: 50),
              sourceKind: ImageSourceKind.userAsset,
              path: 'asset-1',
            ),
            ImageElement(
              id: 'img-2',
              box: ElementBox(x: 100, y: 0, width: 50, height: 50),
              sourceKind: ImageSourceKind.userAsset,
              path: 'asset-2',
            ),
            TextElement(
              id: 'text-1',
              box: ElementBox(x: 0, y: 100, width: 80, height: 40),
              text: 'نص',
            ),
          ],
        );

    test('تلوين المحدد يطبّق اللون على كل الصور في خطوة تراجع واحدة', () {
      final TemplateEditorController controller = TemplateEditorController(
        document: mixed(),
        category: TemplateCategory.certificate,
      );
      addTearDown(controller.dispose);

      controller.selectMany(<String>['img-1', 'img-2', 'text-1']);
      controller.setSelectionImageTint('#FF0000');

      final Map<String, String?> tints = <String, String?>{
        for (final TemplateElement e in controller.document.elements)
          e.id: e is ImageElement ? e.tintHex : null,
      };
      expect(tints['img-1'], '#FF0000');
      expect(tints['img-2'], '#FF0000');
      // النص لا يتأثر بالتلوين.
      expect(controller.document.elements[2], isA<TextElement>());

      // خطوة تراجع واحدة تُعيد اللونين معاً.
      controller.undo();
      expect(
        controller.document.elements
            .whereType<ImageElement>()
            .every((ImageElement e) => e.tintHex == null),
        isTrue,
      );
    });

    test('إزالة التلوين الجماعي تُعيد البكسلات الأصلية للكل', () {
      final TemplateEditorController controller = TemplateEditorController(
        document: mixed(),
        category: TemplateCategory.certificate,
      );
      addTearDown(controller.dispose);

      controller.selectMany(<String>['img-1', 'img-2']);
      controller.setSelectionImageTint('#00AA00');
      controller.clearSelectionImageTint();

      expect(
        controller.document.elements
            .whereType<ImageElement>()
            .every((ImageElement e) => !e.hasTint),
        isTrue,
      );
    });
  });

  group('الأبعاد المخصّصة', () {
    test('السنتيمتر يُحوَّل إلى نقاط في الوضع الرأسي والأفقي', () {
      const TemplateDocument portrait = TemplateDocument(
        elements: <TemplateElement>[],
        orientation: PageOrientation.portrait,
        customPageSize:
            CustomPageSize(width: 10, height: 15, unit: MeasurementUnit.cm),
      );
      expect(portrait.hasCustomSize, isTrue);
      expect(portrait.pageWidthPt, closeTo(283.46, 0.05));
      expect(portrait.pageHeightPt, closeTo(425.20, 0.05));

      const TemplateDocument landscape = TemplateDocument(
        elements: <TemplateElement>[],
        orientation: PageOrientation.landscape,
        customPageSize:
            CustomPageSize(width: 10, height: 15, unit: MeasurementUnit.cm),
      );
      // الوضع الأفقي يبدّل العرض والارتفاع.
      expect(landscape.pageWidthPt, closeTo(425.20, 0.05));
      expect(landscape.pageHeightPt, closeTo(283.46, 0.05));
    });

    test('البوصة تُحوَّل بمعامل 72 نقطة', () {
      const TemplateDocument doc = TemplateDocument(
        elements: <TemplateElement>[],
        orientation: PageOrientation.portrait,
        customPageSize:
            CustomPageSize(width: 8.5, height: 11, unit: MeasurementUnit.inch),
      );
      expect(doc.pageWidthPt, closeTo(612, 0.001));
      expect(doc.pageHeightPt, closeTo(792, 0.001));
    });

    test('تفعيل المقاس المخصّص يحفظ الأبعاد ثم يُلغيها زر المقاس القياسي', () {
      final TemplateEditorController controller = TemplateEditorController(
        document: const TemplateDocument(
          elements: <TemplateElement>[],
          paperSize: PaperSize.a4,
          orientation: PageOrientation.portrait,
        ),
        category: TemplateCategory.certificate,
      );
      addTearDown(controller.dispose);

      final double width = controller.document.pageWidthPt;
      final double height = controller.document.pageHeightPt;

      controller.enableCustomPageSize();
      expect(controller.document.hasCustomSize, isTrue);
      // الشكل البصري لا يقفز: التحويل سم ↔ نقطة يعود لقيم قريبة جداً.
      expect(controller.document.pageWidthPt, closeTo(width, 0.2));
      expect(controller.document.pageHeightPt, closeTo(height, 0.2));

      controller.clearCustomPageSize();
      expect(controller.document.hasCustomSize, isFalse);
      expect(controller.document.paperSize, PaperSize.a4);
    });

    test('بلا مقاس مخصّص يعود المستند إلى مقاس الورق القياسي', () {
      const TemplateDocument doc = TemplateDocument(
        elements: <TemplateElement>[],
        orientation: PageOrientation.portrait,
        paperSize: PaperSize.a4,
      );
      expect(doc.hasCustomSize, isFalse);
      expect(doc.pageWidthPt, closeTo(PaperSize.a4.widthPt, 0.001));
    });
  });

  group('تدرّج الخلفية', () {
    test('التدرّج يُحفظ ويُستعاد من JSON', () {
      const TemplateDocument doc = TemplateDocument(
        elements: <TemplateElement>[],
        backgroundGradient: BackgroundGradient(
          startHex: '#112233',
          endHex: '#AABBCC',
          direction: GradientDirection.diagonal,
        ),
      );
      final TemplateDocument restored =
          TemplateDocument.fromJson(doc.toJson());
      expect(restored.backgroundGradient, isNotNull);
      expect(restored.backgroundGradient!.startHex, '#112233');
      expect(restored.backgroundGradient!.endHex, '#AABBCC');
      expect(restored.backgroundGradient!.direction, GradientDirection.diagonal);
    });

    test('اللوحة والـ PDF يرسمان نفس الألوان والاتجاه', () {
      const BackgroundGradient gradient = BackgroundGradient(
        startHex: '#112233',
        endHex: '#AABBCC',
        direction: GradientDirection.horizontal,
      );

      final LinearGradient? canvas = paperGradient(gradient);
      expect(canvas, isNotNull);
      expect(canvas!.begin, Alignment.centerLeft);
      expect(canvas.end, Alignment.centerRight);
      expect(canvas.colors.first, colorFromHex('#112233'));
      expect(canvas.colors.last, colorFromHex('#AABBCC'));
      expect(paperGradient(null), isNull);

      final pw.LinearGradient pdf = pdfPaperGradient(gradient);
      expect(pdf.begin, pw.Alignment.centerLeft);
      expect(pdf.end, pw.Alignment.centerRight);
      expect(pdf.colors.first, pdfColorFromHex('#112233'));
      expect(pdf.colors.last, pdfColorFromHex('#AABBCC'));
    });

    test('تعيين تدرّج الخلفية وإزالته يعملان عبر المتحكم', () {
      final TemplateEditorController controller = TemplateEditorController(
        document: threeElements(),
        category: TemplateCategory.certificate,
      );
      addTearDown(controller.dispose);

      controller.setBackgroundGradient(const BackgroundGradient(
        startHex: '#000000',
        endHex: '#FFFFFF',
        direction: GradientDirection.horizontal,
      ));
      expect(controller.document.backgroundGradient, isNotNull);
      expect(controller.document.backgroundGradient!.direction,
          GradientDirection.horizontal);

      controller.clearBackgroundGradient();
      expect(controller.document.backgroundGradient, isNull);
    });

    test('اتجاه التدرّج العمودي يبدأ من الأعلى', () {
      const BackgroundGradient vertical = BackgroundGradient(
        startHex: '#000000',
        endHex: '#FFFFFF',
      );
      final LinearGradient canvas = paperGradient(vertical)!;
      expect(canvas.begin, Alignment.topCenter);
      expect(canvas.end, Alignment.bottomCenter);
    });
  });
}
