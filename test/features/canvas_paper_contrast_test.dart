import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/constants/app_constants.dart';
import 'package:joodcraft/core/editor/template_editor_controller.dart';
import 'package:joodcraft/core/editor/widgets/template_canvas.dart';
import 'package:joodcraft/core/models/template_document.dart';
import 'package:joodcraft/core/models/template_element.dart';
import 'package:joodcraft/core/theme/app_colors.dart';
import 'package:joodcraft/core/theme/app_theme.dart';

/// حدود ورقة التصميم: تظل متباينة عن مساحة العمل في الوضعين.
///
/// في الوضع الداكن تكون مساحة العمل **أفتح من الهيكل الموحّد**
/// (رمادي ‎#4A4A4A‎ فوق هيكل سليت ‎#3E3E3E‎)، فيقلّ التباين الحادّ حول
/// الورقة البيضاء ويقلّ إجهاد العين، ويرفعها ظل ناعم منتشر (مُقوّى قليلاً
/// على الطنّ الأفتح). وفي الوضع الفاتح (خلفية شبه بيضاء) تُضمن الحدود بحدٍّ
/// مرسوم حول الورقة وظل يرفعها عن الخلفية.
void main() {
  /// السطوع النسبي (WCAG) للون.
  double luminance(Color color) {
    double channel(double value) =>
        value <= 0.03928 ? value / 12.92 : math.pow((value + 0.055) / 1.055, 2.4).toDouble();
    return 0.2126 * channel(color.r) +
        0.7152 * channel(color.g) +
        0.0722 * channel(color.b);
  }

  /// نسبة التباين بين لونين (1 = بلا تباين، 21 = أبيض/أسود).
  double contrast(Color a, Color b) {
    final double la = luminance(a);
    final double lb = luminance(b);
    final double hi = math.max(la, lb);
    final double lo = math.min(la, lb);
    return (hi + 0.05) / (lo + 0.05);
  }

  late TemplateEditorController controller;

  setUp(() {
    controller = TemplateEditorController(
      document: const TemplateDocument(
        orientation: PageOrientation.landscape,
        elements: <TemplateElement>[
          TextElement(
            id: 'text-1',
            box: ElementBox(x: 200, y: 200, width: 300, height: 80),
            text: 'شهادة إتمام',
          ),
        ],
      ),
      category: TemplateCategory.certificate,
    );
  });

  tearDown(() => controller.dispose());

  Future<void> pumpCanvas(WidgetTester tester, ThemeData theme) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        darkTheme: AppTheme.dark,
        home: Scaffold(body: TemplateCanvas(controller: controller)),
      ),
    );
    await tester.pump();
  }

  /// طبقة خلفية الورقة: الصندوق الوحيد الحامل لحدٍّ مرسوم مع ظل.
  Finder paperLayer() => find.descendant(
        of: find.byType(TemplateCanvas),
        matching: find.byWidgetPredicate(
          (Widget widget) =>
              widget is DecoratedBox &&
              widget.decoration is BoxDecoration &&
              (widget.decoration as BoxDecoration).border != null &&
              (widget.decoration as BoxDecoration).boxShadow != null,
        ),
      );

  testWidgets('الورقة محدّدة بحدٍّ وظل في الوضع الفاتح', (
    WidgetTester tester,
  ) async {
    await pumpCanvas(tester, AppTheme.light);

    final Finder paper = paperLayer();
    expect(paper, findsOneWidget);

    final BoxDecoration decoration =
        tester.widget<DecoratedBox>(paper).decoration as BoxDecoration;
    final Color paperColor = decoration.color!;
    final Color borderColor = decoration.border!.top.color;

    // الحدّ يختلف عن لون الورقة فلا تلتصق ألوان التصميم بالخلفية.
    expect(contrast(paperColor, borderColor), greaterThan(1.1));
    // الظل الناعم يرفع الورقة عن مساحة العمل الفاتحة.
    expect(decoration.boxShadow, isNotEmpty);
    expect(decoration.boxShadow!.first.blurRadius, greaterThanOrEqualTo(10));
    expect(
      contrast(paperColor, AppTheme.light.colorScheme.canvasViewport),
      greaterThan(1.0),
    );
  });

  testWidgets('الورقة البيضاء تتباين بشدة مع مساحة العمل الداكنة', (
    WidgetTester tester,
  ) async {
    await pumpCanvas(tester, AppTheme.dark);
    // تطبيق الثيم الداكن فعلياً عبر themeMode.
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.dark,
        home: Scaffold(body: TemplateCanvas(controller: controller)),
      ),
    );
    await tester.pump();

    final Finder paper = paperLayer();
    expect(paper, findsOneWidget);

    final BoxDecoration decoration =
        tester.widget<DecoratedBox>(paper).decoration as BoxDecoration;
    final Color paperColor = decoration.color!;
    final ColorScheme scheme = AppTheme.dark.colorScheme;
    final Color workspace = scheme.canvasViewport;

    // مساحة العمل فحمي أفتح من اللوحات المحيطة (فحمي متوسط لا أسود).
    expect(workspace, AppColors.darkCanvas);
    expect(
      workspace.computeLuminance(),
      greaterThan(scheme.surface.computeLuminance()),
      reason: 'مساحة عمل اللوحة يجب أن تكون أفتح من اللوحات والأشرطة.',
    );

    // WCAG AA: التباين ≥ 4.5 بين الورقة وخلفية البرنامج الداكنة.
    expect(contrast(paperColor, workspace), greaterThanOrEqualTo(4.5));

    // ظل أسود شفّاف ناعم منشر (لا حدّ صلب) يبرز الورقة.
    expect(decoration.boxShadow, isNotEmpty);
    final BoxShadow shadow = decoration.boxShadow!.first;
    expect(shadow.color.a, greaterThanOrEqualTo(0.24));
    expect(shadow.blurRadius, greaterThanOrEqualTo(10));
    expect(shadow.spreadRadius, greaterThanOrEqualTo(1));
  });
}
