import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/constants/app_constants.dart';
import 'package:joodcraft/core/editor/template_editor_controller.dart';
import 'package:joodcraft/core/editor/widgets/element_view.dart';
import 'package:joodcraft/core/editor/widgets/template_canvas.dart';
import 'package:joodcraft/core/models/template_document.dart';
import 'package:joodcraft/core/models/template_element.dart';
import 'package:joodcraft/core/theme/app_theme.dart';

/// **اختبارات التحرير المباشر على اللوحة** — النقر المزدوج، اختفاء الإطار أثناء
/// الكتابة، ملاءمة الارتفاع، الشريط العائم، وتطبيق التنسيق على المقطع المظلل
/// وحده.
void main() {
  const String inlineFieldKey = 'canvas-inline-text';
  const String toolbarKey = 'canvas-text-toolbar';
  const String sample = 'شهادة تقدير';

  late TemplateEditorController controller;

  setUp(() {
    controller = TemplateEditorController(
      document: const TemplateDocument(
        orientation: PageOrientation.landscape,
        elements: <TemplateElement>[
          TextElement(
            id: 'text-1',
            box: ElementBox(x: 200, y: 200, width: 300, height: 60),
            text: sample,
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
        home: Scaffold(
          body: TemplateCanvas(controller: controller),
        ),
      ),
    );
    await tester.pump();
  }

  Offset elementCenter(WidgetTester tester) =>
      tester.getCenter(find.byType(ElementView));

  TextField inlineField(WidgetTester tester) => tester.widget<TextField>(
      find.byKey(const ValueKey<String>(inlineFieldKey)));

  TextElement element() => controller.document.elements.first as TextElement;

  /// يفتح التحرير المباشر للعنصر الوحيد (نقر ثم نقر مزدوج).
  Future<void> startEditing(WidgetTester tester) async {
    await tester.tapAt(elementCenter(tester));
    await tester.pump(const Duration(milliseconds: 60));
    await tester.tapAt(elementCenter(tester));
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('النقر المزدوج يفتح حقل تحرير مباشر داخل موضع العنصر', (tester) async {
    await pumpCanvas(tester);

    await startEditing(tester);

    expect(find.byKey(const ValueKey<String>(inlineFieldKey)), findsOneWidget);
    expect(inlineField(tester).controller!.text, sample);
    // لا لوحة جانبية ولا نسخة ثانية من النصّ: حقل واحد في اللوحة.
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('الإطار والمقابس يختفيان أثناء الكتابة ويعودان بعدها', (tester) async {
    await pumpCanvas(tester);

    // تحديد العنصر يُظهر مقابس التحجيم — النقرة تُزارَ بعد مهلة النقر المزدوج
    // (‎~300ms‎) لأن البوابة تمازح بين النقر والندב المزدوج.
    await tester.tapAt(elementCenter(tester));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('handle-topLeft')), findsOneWidget);

    // نقر مزدوج حقيقي يفتح التحرير المباشر ويُخفي الإطار والمقابس تماماً.
    await tester.tapAt(elementCenter(tester));
    await tester.pump(const Duration(milliseconds: 60));
    await tester.tapAt(elementCenter(tester));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey<String>(inlineFieldKey)), findsOneWidget);
    expect(find.byKey(const Key('handle-topLeft')), findsNothing,
        reason: 'لا يجوز أن تظهر مقابس أثناء الكتابة');

    // النقر على فراغ خارج الورقة يُلغي التحرير ويعيد الإطار لعناصره
    // (العنصر الذي انتهى تحريره يبقى محدَّداً كما في Word).
    await tester.tapAt(const Offset(5, 5));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey<String>(inlineFieldKey)), findsNothing);
    expect(find.byKey(const Key('handle-topLeft')), findsOneWidget);
  });

  testWidgets('الكتابة تُلتزم في المستند عند النقر خارج مع ملاءمة الارتفاع',
      (tester) async {
    await pumpCanvas(tester);
    final double heightBefore = element().box.height;
    expect(heightBefore, 60);

    await startEditing(tester);
    await tester.enterText(
      find.byKey(const ValueKey<String>(inlineFieldKey)),
      'شهادة تقدير دولية مميزة للفائزين في المسابقة الوطنية', // أطول بوضوح
    );
    await tester.pump(const Duration(milliseconds: 120));

    // الارتفاع يتجه للملاءمة داخل الحقل نفسه قبل الالتزام.
    expect(element().box.height, 60,
        reason: 'لا يُمسّ المستند أثناء الكتابة (خطوة تراجع واحدة عند الالتزام)');

    await tester.tapAt(const Offset(5, 5));
    await tester.pump(const Duration(milliseconds: 300));

    expect(element().text, 'شهادة تقدير دولية مميزة للفائزين في المسابقة الوطنية');
    expect(element().box.height, greaterThan(heightBefore),
        reason: 'الصندوق يجب أن يتمدد مع طول النص');
    expect(element().box.width, 300, reason: 'العرض الثابت لا يتغيّر (النص يلتفّ)');
    expect(find.byKey(const ValueKey<String>(inlineFieldKey)), findsNothing);
  });

  testWidgets('تظليل مقطع يُظهر الشريط العائم فوق النص', (tester) async {
    await pumpCanvas(tester);
    await startEditing(tester);

    expect(find.byKey(const ValueKey<String>(toolbarKey)), findsNothing);

    inlineField(tester).controller!.selection =
        const TextSelection(baseOffset: 0, extentOffset: 4);
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.byKey(const ValueKey<String>(toolbarKey)), findsOneWidget,
        reason: 'الشريط العائم يظهر فور تظليل مقطع صالح');
    // عناصر الشريط المطلوبة في المواصفة.
    expect(find.byTooltip('نوع الخط'), findsOneWidget);
    expect(find.byTooltip('حجم الخط'), findsOneWidget);
    expect(find.byTooltip('لون النص'), findsOneWidget);
    expect(find.byTooltip('المحاذاة'), findsOneWidget);
    expect(find.byTooltip('عريض'), findsOneWidget);
    expect(find.byTooltip('مائل'), findsOneWidget);
    expect(find.byTooltip('خط سفلي'), findsOneWidget);

    // إلغاء التحديد يُخفي الشريط.
    inlineField(tester).controller!.selection =
        const TextSelection.collapsed(offset: -1);
    await tester.pump(const Duration(milliseconds: 120));
    expect(find.byKey(const ValueKey<String>(toolbarKey)), findsNothing);
  });

  testWidgets('تغيير لون الشريط العائم يُنسّق المقطع المظلل وحده', (tester) async {
    await pumpCanvas(tester);
    await startEditing(tester);

    // تظليل «تقدير» وحدها.
    final String text = inlineField(tester).controller!.text;
    final int start = text.indexOf('تقدير');
    inlineField(tester).controller!.selection =
        TextSelection(baseOffset: start, extentOffset: start + 'تقدير'.length);
    await tester.pump(const Duration(milliseconds: 120));

    await tester.tap(find.byTooltip('لون النص'));
    await tester.pumpAndSettle(const Duration(milliseconds: 300));
    // لوحة الشريط تنشر ‎#E53935‎ كأحمر أساسي.
    await tester.tap(find.text('#E53935'));
    await tester.pumpAndSettle(const Duration(milliseconds: 300));

    expect(element().hasSpans, isTrue, reason: 'يجب أن يُحفظ نطاق تنسيق جزئي');
    expect(element().spans, hasLength(1));
    expect(element().spans.single.start, start);
    expect(element().spans.single.end, start + 'تقدير'.length,
        reason: 'التنسيق يُطبَّق على المقطع المظلل وحده');
    expect(element().spans.single.colorHex, '#E53935');
    expect(element().text, text, reason: 'النصّ نفسه لم يتغيّر');
  });

  testWidgets('زر العريض يبدّل تنسيق المقطع ويُقيَّد في النطاق', (tester) async {
    await pumpCanvas(tester);
    await startEditing(tester);

    inlineField(tester).controller!.selection =
        const TextSelection(baseOffset: 0, extentOffset: 4);
    await tester.pump(const Duration(milliseconds: 120));

    await tester.tap(find.byTooltip('عريض'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(element().hasSpans, isTrue);
    expect(element().spans.single.start, 0);
    expect(element().spans.single.end, 4);
    expect(element().spans.single.weight, isNotNull);

    // الضغطة الثانية تُعيد الوزن إلى الوضع الطبيعي (تبديل لا تراكم).
    await tester.tap(find.byTooltip('عريض'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(element().spans.single.weight, isNotNull,
        reason: 'يبقى تدخّلاً صريحاً معاكساً لا مجرد إلغاء');
  });
}
