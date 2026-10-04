import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/constants/app_constants.dart';
import 'package:joodcraft/core/editor/template_editor_controller.dart';
import 'package:joodcraft/core/editor/widgets/property_toolbar.dart';
import 'package:joodcraft/core/models/template_document.dart';
import 'package:joodcraft/core/models/template_element.dart';
import 'package:joodcraft/core/pdf/pdf_font_catalog.dart';
import 'package:joodcraft/core/theme/app_theme.dart';

void main() {
  late TemplateEditorController controller;

  TemplateDocument document() => TemplateDocument(
        elements: <TemplateElement>[
          const TextElement(
            id: 'text-1',
            box: ElementBox(x: 100, y: 100, width: 300, height: 60),
            text: '',
            fontSize: 16,
          ),
          const SealElement(
            id: 'seal-1',
            box: ElementBox(x: 500, y: 300, width: 120, height: 120),
          ),
          const ShapeElement(
            id: 'shape-1',
            box: ElementBox(x: 40, y: 40, width: 400, height: 300),
            kind: ShapeKind.rect,
            strokeHex: '#C7A26B',
            strokeWidth: 2,
          ),
          const QrElement(
            id: 'qr-1',
            box: ElementBox(x: 800, y: 600, width: 80, height: 80),
            data: 'https://joodcraft.app',
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

  Future<void> pumpToolbar(WidgetTester tester) async {
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

  /// ينقل عرض الشريط إلى العنصر ثم ينقر عليه.
  ///
  /// لزم ذلك بعد إضافة قسم «خطوطي المخصصة»: الشريط صار أطول من نافذة الاختبار
  /// فيقع القسم السفلي خارج المنطقة القابلة للنقر (المحرر الحقيقي يضع الشريط
  /// داخل قائمة قابلة للتمرير).
  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pump();
  }

  /// زر "زيادة" الخاص بحقل رقمي بعنوان معيّن.
  Finder stepUpFor(String label) {
    return find.descendant(
      of: find.ancestor(of: find.text(label), matching: find.byType(Row)).first,
      matching: find.byTooltip('زيادة'),
    );
  }

  group('العرض حسب نوع العنصر', () {
    testWidgets('لا يظهر أي شريط قبل تحديد عنصر', (WidgetTester tester) async {
      await pumpToolbar(tester);

      expect(find.text('الموضع والحجم'), findsNothing);
      expect(find.text('تنسيق النص'), findsNothing);
    });

    testWidgets('تحديد نص يُظهر أدوات النص والموضع', (WidgetTester tester) async {
      await pumpToolbar(tester);
      controller.select('text-1');
      await tester.pump();

      expect(find.text('نص'), findsOneWidget);
      expect(find.text('الموضع والحجم'), findsOneWidget);
      expect(find.text('تنسيق النص'), findsOneWidget);
      expect(find.text('محتوى النص'), findsOneWidget);
      expect(find.text('الختم'), findsNothing);
    });

    testWidgets('تحديد ختم يُظهر أدوات الختم فقط', (WidgetTester tester) async {
      await pumpToolbar(tester);
      controller.select('seal-1');
      await tester.pump();

      expect(find.text('الختم'), findsOneWidget);
      expect(find.text('لون الختم'), findsOneWidget);
      expect(find.text('لون النجمة'), findsOneWidget);
      expect(find.text('تنسيق النص'), findsNothing);
    });

    testWidgets('تحديد شكل يُظهر أدوات الشكل', (WidgetTester tester) async {
      await pumpToolbar(tester);
      controller.select('shape-1');
      await tester.pump();

      expect(find.text('الشكل'), findsOneWidget);
      expect(find.text('لون التعبئة'), findsOneWidget);
      expect(find.text('سماكة الحدود'), findsOneWidget);
    });

    testWidgets('تحديد رمز QR يُظهر أدوات الرمز', (WidgetTester tester) async {
      await pumpToolbar(tester);
      controller.select('qr-1');
      await tester.pump();

      expect(find.text('رمز التحقق'), findsOneWidget);
      expect(find.text('بيانات الرمز'), findsOneWidget);
    });

    testWidgets('إلغاء التحديد يُخفي الشريط', (WidgetTester tester) async {
      await pumpToolbar(tester);
      controller.select('text-1');
      await tester.pump();
      expect(find.text('الموضع والحجم'), findsOneWidget);

      controller.clearSelection();
      await tester.pump();
      expect(find.text('الموضع والحجم'), findsNothing);
    });
  });

  group('تعديل الخصائص', () {
    testWidgets('زر الزيادة يكبّر حجم الخط', (WidgetTester tester) async {
      await pumpToolbar(tester);
      controller.select('text-1');
      await tester.pump();

      await tapVisible(tester, stepUpFor('حجم الخط'));

      expect((controller.selected! as TextElement).fontSize, 17);
    });

    testWidgets('زر الإنقاص يُصغّر حجم الخط بلا نزول تحت الحد الأدنى',
        (WidgetTester tester) async {
      await pumpToolbar(tester);
      controller.select('text-1');
      await tester.pump();

      final Finder stepDown = find.descendant(
        of: find
            .ancestor(of: find.text('حجم الخط'), matching: find.byType(Row))
            .first,
        matching: find.byTooltip('إنقاص'),
      );
      await tester.ensureVisible(stepDown);
      await tester.pumpAndSettle();
      for (int i = 0; i < 30; i++) {
        await tester.tap(stepDown);
        await tester.pump();
      }

      expect((controller.selected! as TextElement).fontSize, 4);
    });

    testWidgets('تغيير الموضع من الحقل الرقمي يُحدّث الصندوق',
        (WidgetTester tester) async {
      await pumpToolbar(tester);
      controller.select('text-1');
      await tester.pump();

      await tester.tap(stepUpFor('س'));
      await tester.pump();

      expect(controller.selected!.box.x, 101);
    });

    testWidgets('اختيار الخط من القائمة يُطبّق على النص',
        (WidgetTester tester) async {
      await pumpToolbar(tester);
      controller.select('text-1');
      await tester.pump();

      expect((controller.selected! as TextElement).family, PdfFontFamily.plex);

      await tester.tap(find.byType(DropdownButton<PdfFontFamily>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Amiri').last);
      await tester.pumpAndSettle();

      expect((controller.selected! as TextElement).family, PdfFontFamily.amiri);
    });

    testWidgets('المحاذاة تُختار من الأزرار المدمجة', (WidgetTester tester) async {
      await pumpToolbar(tester);
      controller.select('text-1');
      await tester.pump();

      await tapVisible(
        tester,
        find.byIcon(Icons.format_align_center_rounded),
      );

      expect((controller.selected! as TextElement).align, ElementTextAlign.center);
    });

    testWidgets('طريقة الضبط تظهر عند «ضبط» وتُبدَّل إلى كشيدة',
        (WidgetTester tester) async {
      await pumpToolbar(tester);
      controller.select('text-1');
      await tester.pump();

      // لا تظهر طريقة الضبط إلا بعد اختيار «ضبط».
      expect(find.text('طريقة الضبط'), findsNothing);

      await tapVisible(
        tester,
        find.byIcon(Icons.format_align_justify_rounded),
      );
      await tester.pump();
      expect(find.text('طريقة الضبط'), findsOneWidget);

      await tapVisible(tester, find.text('كشيدة'));
      expect(
        (controller.selected! as TextElement).justifyMode,
        JustifyMode.kashida,
      );

      await tapVisible(tester, find.text('فراغات'));
      expect(
        (controller.selected! as TextElement).justifyMode,
        JustifyMode.spaces,
      );
    });

    testWidgets('الاتجاه يتحول إلى لاتيني عند الطلب', (WidgetTester tester) async {
      await pumpToolbar(tester);
      controller.select('text-1');
      await tester.pump();

      await tapVisible(tester, find.text('لاتيني'));

      expect(
        (controller.selected! as TextElement).direction,
        ElementDirection.ltr,
      );
    });

    testWidgets('شفافية الختم تُعدّل بمنزلق', (WidgetTester tester) async {
      await pumpToolbar(tester);
      controller.select('seal-1');
      await tester.pump();

      // منزلق الشفافية هو الثاني في قسم الموضع (بعد الدوران).
      final Finder opacitySlider = find.byType(Slider).at(1);
      await tester.drag(opacitySlider, const Offset(-60, 0));
      await tester.pump();

      expect((controller.selected! as SealElement).opacity, lessThan(1));
      expect((controller.selected! as SealElement).opacity, greaterThanOrEqualTo(0));
    });

    testWidgets('الدوران يُعدّل من المنزلق', (WidgetTester tester) async {
      await pumpToolbar(tester);
      controller.select('seal-1');
      await tester.pump();

      await tester.drag(find.byType(Slider).first, const Offset(60, 0));
      await tester.pump();

      expect(controller.selected!.rotation, isNot(0));
    });
  });

  group('الحقول الديناميكية', () {
    testWidgets('النقر على حقل يُدرج صيغته في النص', (WidgetTester tester) async {
      await pumpToolbar(tester);
      controller.select('text-1');
      await tester.pump();

      await tester.tap(find.text('اسم_المتدرب'));
      await tester.pump();

      expect(
        (controller.selected! as TextElement).text,
        '{{اسم_المتدرب}}',
      );
    });

    testWidgets('الإدراج مرتين يُنتج صيغتين متجاورتين', (WidgetTester tester) async {
      await pumpToolbar(tester);
      controller.select('text-1');
      await tester.pump();

      await tester.tap(find.text('اسم_الدورة'));
      await tester.pump();
      await tester.tap(find.text('التاريخ'));
      await tester.pump();

      final String text = (controller.selected! as TextElement).text;
      expect(text, '{{اسم_الدورة}} {{التاريخ}}');
    });

    testWidgets('تعديل محتوى النص مباشرةً يُحدّث العنصر',
        (WidgetTester tester) async {
      await pumpToolbar(tester);
      controller.select('text-1');
      await tester.pump();

      await tester.enterText(
        find.widgetWithText(TextField, 'محتوى النص'),
        'شهادة إتمام الدورة',
      );
      await tester.pump();

      expect((controller.selected! as TextElement).text, 'شهادة إتمام الدورة');
    });

    testWidgets('اتجاه حقل النص يتبع العنصر (rtl عربي، ltr لاتيني)',
        (WidgetTester tester) async {
      await pumpToolbar(tester);
      controller.select('text-1');
      await tester.pump();

      TextField field = tester.widget<TextField>(
        find.widgetWithText(TextField, 'محتوى النص'),
      );
      expect(field.textDirection, TextDirection.rtl);

      // تحويل الاتجاه للاتيني يحوّل تحريك المؤشر إلى ltr تبعاً لذلك.
      await tapVisible(tester, find.text('لاتيني'));
      field = tester.widget<TextField>(
        find.widgetWithText(TextField, 'محتوى النص'),
      );
      expect(field.textDirection, TextDirection.ltr);
    });

    testWidgets('تغيير التحديد يُعيد مزامنة حقل النص مع العنصر الجديد',
        (WidgetTester tester) async {
      await pumpToolbar(tester);
      controller.select('text-1');
      await tester.pump();
      await tester.enterText(find.widgetWithText(TextField, 'محتوى النص'), 'أ');
      await tester.pump();

      // عنصر آخر بلا حقل نصي…
      controller.select('seal-1');
      await tester.pump();
      expect(find.widgetWithText(TextField, 'محتوى النص'), findsNothing);

      // …ثم العودة ⇒ الحقل يُعيد بناء قيمته من العنصر.
      controller.select('text-1');
      await tester.pump();

      final TextField field = tester.widget<TextField>(
        find.widgetWithText(TextField, 'محتوى النص'),
      );
      expect(field.controller!.text, 'أ');
    });
  });

  group('أدوات العنصر', () {
    testWidgets('زر التكرار يضيف نسخة', (WidgetTester tester) async {
      await pumpToolbar(tester);
      controller.select('text-1');
      await tester.pump();

      await tester.tap(find.byTooltip('تكرار العنصر'));
      await tester.pump();

      expect(controller.document.elements.length, 5);
      expect(controller.selectedId, isNot('text-1'));
    });

    testWidgets('زر الحذف يُزيل العنصر ويُخفي الشريط',
        (WidgetTester tester) async {
      await pumpToolbar(tester);
      controller.select('shape-1');
      await tester.pump();

      await tester.tap(find.byTooltip('حذف العنصر'));
      await tester.pump();

      expect(controller.document.elements.length, 3);
      expect(find.text('الموضع والحجم'), findsNothing);
    });

    testWidgets('أزرار ترتيب الرسم تعمل', (WidgetTester tester) async {
      await pumpToolbar(tester);
      controller.select('text-1');
      await tester.pump();

      await tester.tap(find.byTooltip('إلى الأمام'));
      await tester.pump();

      expect(controller.document.elements.first.id, 'seal-1');
    });
  });

  group('شريط إضافة العناصر', () {
    testWidgets('كل زر يُضيف عنصراً من نوعه', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: SingleChildScrollView(
              child: ElementPaletteBar(controller: controller),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('نص'));
      await tester.pump();
      expect(controller.selected, isA<TextElement>());

      await tester.tap(find.text('ختم'));
      await tester.pump();
      expect(controller.selected, isA<SealElement>());

      await tester.tap(find.text('حقل ديناميكي'));
      await tester.pump();
      expect((controller.selected! as TextElement).text, contains('{{'));

      await tester.tap(find.text('رمز QR'));
      await tester.pump();
      expect(controller.selected, isA<QrElement>());

      expect(controller.document.elements.length, 8);
    });
  });
}
