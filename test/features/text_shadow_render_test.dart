import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/constants/app_constants.dart';
import 'package:joodcraft/core/editor/template_editor_controller.dart';
import 'package:joodcraft/core/editor/widgets/editor_controls.dart';
import 'package:joodcraft/core/editor/widgets/element_view.dart';
import 'package:joodcraft/core/editor/widgets/property_toolbar.dart';
import 'package:joodcraft/core/models/template_document.dart';
import 'package:joodcraft/core/models/template_element.dart';
import 'package:joodcraft/core/theme/app_theme.dart';
import 'package:joodcraft/core/utils/hex_color.dart';

/// اختبارات ظل النص: تحويله إلى `TextStyle.shadows` في اللوحة، وأدوات ضبطه
/// في اللوحة الجانبية (إضافة/لون/شفافية/تمويه/إزاحة/إزالة).
void main() {
  const TextElement shadowed = TextElement(
    id: 'text-1',
    box: ElementBox(x: 20, y: 20, width: 400, height: 80),
    text: 'مرحباً {{اسم_المتدرب}}',
    fontSize: 20,
    shadow: TextShadow(
      colorHex: '#C7A26B',
      opacity: 0.4,
      blurRadius: 6,
      offsetX: 3,
      offsetY: -2,
    ),
  );

  group('تحويل الظل إلى TextStyle', () {
    test('الظل يصير Shadow واحداً بإزاحة وتمويه مقياسين', () {
      final TextStyle style = editorTextStyle(shadowed, 2);
      expect(style.shadows, hasLength(1));
      final Shadow shadow = style.shadows!.single;
      expect(shadow.offset, const Offset(6, -4));
      expect(shadow.blurRadius, 12);
      expect(shadow.color.a, closeTo(0.4, 0.01));
    });

    test('بلا ظل (أو ظل غير مرئي) لا تُضاف أي ظلال', () {
      const TextElement plain = TextElement(
        id: 't',
        box: ElementBox(),
        text: 'نص',
      );
      expect(editorTextStyle(plain, 1).shadows, isNull);
      expect(editorTextShadows(null, 1), isNull);
      expect(
        editorTextShadows(const TextShadow(opacity: 0), 1),
        isNull,
        reason: 'الشفافية صفر تعني ظلاً غير مرئي.',
      );
      expect(
        editorTextShadows(
          const TextShadow(blurRadius: 0, offsetX: 0, offsetY: 0),
          1,
        ),
        isNull,
        reason: 'بلا تمويه ولا إزاحة لا يوجد ظل يُرسم.',
      );
    });

    test('ترتيب الظل مع بقية الخصائص (خط/حجم/لون) لا يتغيّر', () {
      final TextStyle style = editorTextStyle(shadowed, 1);
      expect(style.fontSize, 20);
      expect(style.color, colorFromHex('#1B2539', fallback: Colors.black));
      expect(style.shadows, hasLength(1));
    });
  });

  group('رسم العنصر على اللوحة', () {
    Widget host(TextElement element) => MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 200,
              child: ElementView(
                element: element,
                document: TemplateDocument(
                  elements: <TemplateElement>[element],
                ),
                scale: 1,
              ),
            ),
          ),
        );

    testWidgets('النص المظلّل يُرسم بظل محمول في النمط',
        (WidgetTester tester) async {
      await tester.pumpWidget(host(shadowed));
      await tester.pump();

      final Text rendered = tester.widget<Text>(
        find.text('مرحباً {{اسم_المتدرب}}'),
      );
      expect(rendered.style!.shadows, hasLength(1));
      expect(rendered.style!.shadows!.single.offset, const Offset(3, -2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('نص بلا ظل يُرسم بلا ظلال', (WidgetTester tester) async {
      const TextElement plain = TextElement(
        id: 'p',
        box: ElementBox(x: 20, y: 20, width: 400, height: 80),
        text: 'نص بسيط',
        fontSize: 20,
      );
      await tester.pumpWidget(host(plain));
      await tester.pump();

      final Text rendered = tester.widget<Text>(find.text('نص بسيط'));
      expect(rendered.style!.shadows, isNull);
    });

    testWidgets('الحقول الديناميكية المظللة تُرسم بالظل نفسه',
        (WidgetTester tester) async {
      const TextElement field = TextElement(
        id: 'f',
        box: ElementBox(x: 20, y: 20, width: 400, height: 80),
        text: '{{اسم_المتدرب}}',
        shadow: TextShadow(),
      );
      await tester.pumpWidget(host(field));
      await tester.pump();

      final Text rendered = tester.widget<Text>(find.text('{{اسم_المتدرب}}'));
      expect(rendered.style!.shadows, hasLength(1));
    });
  });

  group('أدوات ظل النص في اللوحة الجانبية', () {
    late TemplateEditorController controller;

    setUp(() {
      controller = TemplateEditorController(
        document: const TemplateDocument(
          elements: <TemplateElement>[shadowed],
        ),
        category: TemplateCategory.certificate,
      );
      controller.select('text-1');
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

    Finder byKey(String key) => find.byKey(ValueKey<String>(key));
    TextElement element() => controller.selected! as TextElement;

    testWidgets('قسم «ظل النص» يعرض أدوات الضبط كاملة',
        (WidgetTester tester) async {
      await pumpToolbar(tester);

      expect(find.text('ظل النص'), findsOneWidget);
      expect(byKey('text-shadow-color'), findsOneWidget);
      expect(byKey('text-shadow-opacity'), findsOneWidget);
      expect(byKey('text-shadow-blur'), findsOneWidget);
      expect(byKey('text-shadow-offset-x'), findsOneWidget);
      expect(byKey('text-shadow-offset-y'), findsOneWidget);
      expect(byKey('text-shadow-remove'), findsOneWidget);
      // الظل قائم ⇒ لا زرّ إضافة.
      expect(byKey('text-shadow-add'), findsNothing);
    });

    testWidgets('بلا ظل يظهر زرّ الإضافة وحده', (WidgetTester tester) async {
      controller.setSelectedTextShadow(null);
      await pumpToolbar(tester);

      expect(byKey('text-shadow-add'), findsOneWidget);
      expect(byKey('text-shadow-color'), findsNothing);

      await tester.ensureVisible(byKey('text-shadow-add'));
      await tester.tap(byKey('text-shadow-add'));
      await tester.pump();

      expect(element().shadow, isNotNull);
      expect(byKey('text-shadow-color'), findsOneWidget);
    });

    testWidgets('حقول اللون والشفافية والتمويه والإزاحة تُحدّث النموذج',
        (WidgetTester tester) async {
      await pumpToolbar(tester);

      // كل تعديل يُتبعه إطار (كما يحدث في الاستخدام الفعلي) فيُبنى التعديل
      // التالي على القيم المحفوظة بعد التعديل السابق.
      tester.widget<SliderField>(byKey('text-shadow-opacity')).onChanged(0.9);
      await tester.pump();
      tester.widget<SliderField>(byKey('text-shadow-blur')).onChanged(14);
      await tester.pump();
      tester.widget<NumberField>(byKey('text-shadow-offset-x')).onChanged(-8);
      await tester.pump();
      tester.widget<NumberField>(byKey('text-shadow-offset-y')).onChanged(5);
      await tester.pump();
      tester.widget<ColorField>(byKey('text-shadow-color'))
          .onChanged('#1B2539');
      await tester.pump();

      final TextShadow shadow = element().shadow!;
      expect(shadow.opacity, 0.9);
      expect(shadow.blurRadius, 14);
      expect(shadow.offsetX, -8);
      expect(shadow.offsetY, 5);
      expect(shadow.colorHex, '#1B2539');
    });

    testWidgets('زرّ الإزالة يُنظّف الظل تماماً', (WidgetTester tester) async {
      await pumpToolbar(tester);

      await tester.ensureVisible(byKey('text-shadow-remove'));
      await tester.tap(byKey('text-shadow-remove'));
      await tester.pump();

      expect(element().shadow, isNull);
      expect(byKey('text-shadow-add'), findsOneWidget);
    });
  });
}
