import 'dart:ui' show Rect, Size;

import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/constants/app_constants.dart';
import 'package:joodcraft/core/editor/template_editor_controller.dart';
import 'package:joodcraft/core/models/template_document.dart';
import 'package:joodcraft/core/models/template_element.dart';

/// اختبارات **محرّك إعادة التخطيط التلقائي** (§2): عند تبديل اتجاه الورقة أو
/// مقاسها تُحدَّث أبعاد مساحة التصميم فوراً، وتُعاد مواءمة كل العناصر لتملأ
/// المقاس الجديد بلا خروج عن الحدود ولا انكسار للتركيبة.
void main() {
  TemplateDocument document() => const TemplateDocument(
        paperSize: PaperSize.a4,
        orientation: PageOrientation.landscape,
        elements: <TemplateElement>[
          TextElement(
            id: 'text-1',
            box: ElementBox(x: 200, y: 200, width: 400, height: 80),
            text: '{{اسم_المتدرب}}',
            fontSize: 32,
          ),
          SealElement(
            id: 'seal-1',
            box: ElementBox(x: 480, y: 520, width: 120, height: 120),
          ),
        ],
      );

  group('TemplateDocument.refit', () {
    test('تبديل الاتجاه يقلب مساحة التصميم ويعيد تخطيط العناصر', () {
      final TemplateDocument landscape = document();
      final double oldDesignW = landscape.designWidth;
      final double oldDesignH = landscape.designHeight;

      final TemplateDocument portrait =
          landscape.refit(orientation: PageOrientation.portrait);

      expect(portrait.orientation, PageOrientation.portrait);
      // مساحة التصميم تتبع الورقة الجديدة (المقلوبة).
      expect(portrait.designWidth, closeTo(oldDesignH, 0.01));
      expect(portrait.designHeight, closeTo(oldDesignW, 0.01));

      // العنصر الأول: صندوقه تحجّم محورياً مع النسبة الجديدة.
      final ElementBox box = portrait.elements.first.box;
      final double sx = portrait.designWidth / oldDesignW;
      final double sy = portrait.designHeight / oldDesignH;
      expect(box.x, closeTo(200 * sx, 0.01));
      expect(box.y, closeTo(200 * sy, 0.01));
      expect(box.width, closeTo(400 * sx, 0.01));
      expect(box.height, closeTo(80 * sy, 0.01));
    });

    test('النص يبقى بمقاسه تقريباً عند تبديل الاتجاه (تحويل يحفظ المساحة)', () {
      final TextElement before = document().elements.first as TextElement;
      final TextElement after = document()
          .refit(orientation: PageOrientation.portrait)
          .elements
          .first as TextElement;

      // المتوسط الهندسي لـ sx·sy = 1 عند تبديل الاتجاه ⇒ حجم الخط شبه ثابت.
      expect(after.fontSize, closeTo(before.fontSize, 0.5));
    });

    test('تغيير المقاس (A4→A5) يُحجّم المواضع والأحجام بنسبة موحّدة', () {
      final TemplateDocument a4 = document();
      final TemplateDocument a5 = a4.refit(paperSize: PaperSize.a5);

      expect(a5.paperSize, PaperSize.a5);
      final double factor = a5.pageWidthPt / a4.pageWidthPt;
      expect(a5.designWidth, closeTo(a4.designWidth * factor, 0.01));

      final ElementBox box = a5.elements.first.box;
      expect(box.x, closeTo(200 * factor, 0.01));
      expect(box.width, closeTo(400 * factor, 0.01));
      // حجم الخط يتحجّم بنفس النسبة لأن التحويل موحّد على المحورين.
      final TextElement text = a5.elements.first as TextElement;
      expect(text.fontSize, closeTo(32 * factor, 0.5));
    });

    test('كل العناصر تبقى داخل حدود الصفحة الجديدة', () {
      final TemplateDocument portrait = document()
          .refit(orientation: PageOrientation.portrait);
      for (final TemplateElement element in portrait.elements) {
        final Rect rect = portrait.boxToPdfRect(element.box);
        expect(rect.left, greaterThanOrEqualTo(-0.01));
        expect(rect.top, greaterThanOrEqualTo(-0.01));
        expect(rect.right, lessThanOrEqualTo(portrait.pageWidthPt + 0.01));
        expect(rect.bottom, lessThanOrEqualTo(portrait.pageHeightPt + 0.01));
      }
      // إزاحة التوسيط تبقى صفراً (تطابق المحرّر مع الـ PDF).
      expect(portrait.offsetX.abs(), lessThan(0.01));
      expect(portrait.offsetY.abs(), lessThan(0.01));
    });

    test('بلا تغيير فعلي لا يُحجَّم شيء', () {
      final TemplateDocument same =
          document().refit(orientation: PageOrientation.landscape);
      expect(same.elements.first.box.width, 400);
    });
  });

  group('TemplateEditorController — إعادة التخطيط عبر أدوات المحرّر', () {
    test('تبديل الاتجاه من الشريط يُعيد تخطيط العناصر ويُسجَّل للتراجع', () {
      final TemplateEditorController controller = TemplateEditorController(
        document: document(),
        category: TemplateCategory.certificate,
      );
      addTearDown(controller.dispose);

      final Size before = controller.designSize;
      controller.setOrientation(PageOrientation.portrait);

      expect(controller.document.orientation, PageOrientation.portrait);
      final Size after = controller.designSize;
      expect(after.width, closeTo(before.height, 0.01));
      expect(after.height, closeTo(before.width, 0.01));

      // العملية خطوة تراجع واحدة تُعيد المستند كما كان.
      expect(controller.canUndo, isTrue);
      controller.undo();
      expect(controller.document.orientation, PageOrientation.landscape);
      expect(controller.document.elements.first.box.width, 400);
    });

    test('تغيير المقاس القياسي يُعاد تخطيط العناصر تبعاً', () {
      final TemplateEditorController controller = TemplateEditorController(
        document: document(),
        category: TemplateCategory.certificate,
      );
      addTearDown(controller.dispose);

      controller.setPaperSize(PaperSize.a5);
      expect(controller.document.paperSize, PaperSize.a5);
      expect(controller.document.elements.first.box.width, lessThan(400));
    });

    test('المقاس المخصّص والعودة للمقاس القياسي يعيدان التخطيط', () {
      final TemplateEditorController controller = TemplateEditorController(
        document: document(),
        category: TemplateCategory.certificate,
      );
      addTearDown(controller.dispose);

      controller.setCustomPageSize(10, 10, MeasurementUnit.cm);
      expect(controller.document.hasCustomSize, isTrue);
      final double customWidth = controller.document.designWidth;

      controller.clearCustomPageSize();
      expect(controller.document.hasCustomSize, isFalse);
      // عاد إلى A4، فاتّسعت مساحة التصميم من جديد.
      expect(controller.document.designWidth, greaterThan(customWidth));
    });
  });
}
