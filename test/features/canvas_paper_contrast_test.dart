import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/constants/app_constants.dart';
import 'package:joodcraft/core/editor/template_editor_controller.dart';
import 'package:joodcraft/core/editor/widgets/template_canvas.dart';
import 'package:joodcraft/core/models/template_document.dart';
import 'package:joodcraft/core/models/template_element.dart';
import 'package:joodcraft/core/theme/app_theme.dart';

/// حدود ورقة التصميم: تظل متباينة عن مساحة العمل في الوضعين.
///
/// في الوضع الداكن يكفي تباين الألوان (ورقة بيضاء فوق خلفية داكنة)، وفي
/// الوضع الفاتح (خلفية شبه بيضاء) تُضمن الحدود بحدٍّ مرسوم حول الورقة وظل
/// يرفعها عن الخلفية.
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
    // الظل يرفع الورقة عن مساحة العمل الفاتحة.
    expect(decoration.boxShadow, isNotEmpty);
    expect(
      contrast(paperColor, AppTheme.light.colorScheme.surfaceContainerHighest),
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
    final Color workspace = AppTheme.dark.colorScheme.surfaceContainerHighest;

    // WCAG AA: التباين ≥ 4.5 بين الورقة وخلفية البرنامج الداكنة.
    expect(contrast(paperColor, workspace), greaterThanOrEqualTo(4.5));
    // وظل داكن يبرزها أكثر.
    expect(decoration.boxShadow, isNotEmpty);
    expect(
      decoration.boxShadow!.first.color.a,
      greaterThan(AppColorsLike.darkShadowAlpha),
    );
  });
}

/// قيمة ألفا مميزة للظل الداكن (أسود شبه معتم) — لفحص أن الظل تحوّل ليلاً.
abstract final class AppColorsLike {
  static const double darkShadowAlpha = 0.4;
}
