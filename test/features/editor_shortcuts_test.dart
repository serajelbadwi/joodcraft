import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/constants/app_assets.dart';
import 'package:joodcraft/core/constants/app_constants.dart';
import 'package:joodcraft/core/editor/widgets/element_view.dart';
import 'package:joodcraft/core/editor/widgets/template_canvas.dart';
import 'package:joodcraft/core/editor/widgets/template_editor_view.dart';
import 'package:joodcraft/core/models/template_document.dart';
import 'package:joodcraft/core/models/template_element.dart';
import 'package:joodcraft/core/theme/app_theme.dart';

/// اختصارات لوحة المفاتيح داخل المحرر (أعراف الفوتوشوب) + حماية حقول النص.
void main() {
  Future<void> pumpEditor(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: TemplateEditorView(
            category: TemplateCategory.certificate,
            initialTemplateAsset: AppAssets.sampleCertificateTemplate,
            exportFileName: 'joodcraft-certificate.pdf',
            document: const TemplateDocument(
              orientation: PageOrientation.landscape,
              elements: <TemplateElement>[
                TextElement(
                  id: 'text-1',
                  box: ElementBox(x: 100, y: 100, width: 200, height: 80),
                  text: 'مرحباً',
                ),
                TextElement(
                  id: 'text-2',
                  box: ElementBox(x: 400, y: 100, width: 200, height: 80),
                  text: 'الثاني',
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  TemplateCanvas canvas(WidgetTester tester) =>
      tester.widget<TemplateCanvas>(find.byType(TemplateCanvas));

  Future<void> pressCtrl(WidgetTester tester, LogicalKeyboardKey key) async {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(key);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
  }

  Future<void> pressCtrlShift(
    WidgetTester tester,
    LogicalKeyboardKey key,
  ) async {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(key);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
  }

  testWidgets('Delete يحذف العنصر المحدد', (WidgetTester tester) async {
    await pumpEditor(tester);
    final canvasWidget = canvas(tester);
    canvasWidget.controller.select('text-1');
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await tester.pump();

    expect(canvasWidget.controller.document.elements.length, 1);
    expect(canvasWidget.controller.hasSelection, isFalse);
  });

  testWidgets('Backspace يحذف العنصر المحدد', (WidgetTester tester) async {
    await pumpEditor(tester);
    final canvasWidget = canvas(tester);
    canvasWidget.controller.select('text-1');
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pump();

    expect(canvasWidget.controller.document.elements.length, 1);
    expect(canvasWidget.controller.hasSelection, isFalse);
  });

  testWidgets('الحذف بـ Delete ثم Ctrl+Z يُعيد العنصر',
      (WidgetTester tester) async {
    await pumpEditor(tester);
    final canvasWidget = canvas(tester);
    canvasWidget.controller.select('text-1');
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await tester.pump();
    expect(canvasWidget.controller.document.elements.length, 1);

    await pressCtrl(tester, LogicalKeyboardKey.keyZ);
    expect(canvasWidget.controller.document.elements.length, 2);
  });

  testWidgets('جلسة أسهم مستمرة (تكرار المفتاح) تُسجَّل كخطوة تراجع واحدة',
      (WidgetTester tester) async {
    await pumpEditor(tester);
    final canvasWidget = canvas(tester);
    final controller = canvasWidget.controller;
    controller.select('text-1');
    await tester.pump();
    final double x0 = controller.selected!.box.x;

    // ضغط مستمر على السهم: هبوط + تكراران + إفلات.
    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();

    expect(controller.selected!.box.x, x0 + 3);
    expect(controller.canUndo, isTrue);

    // تراجع واحد يكفي لإرجاع الحركة كاملة (لا حركة لكل تكرار).
    await pressCtrl(tester, LogicalKeyboardKey.keyZ);

    expect(controller.selected!.box.x, x0);
    expect(controller.canUndo, isFalse);
  });

  testWidgets('سهم واحد قابل للتراجع خطوة بخطوة', (WidgetTester tester) async {
    await pumpEditor(tester);
    final canvasWidget = canvas(tester);
    final controller = canvasWidget.controller;
    controller.select('text-1');
    await tester.pump();
    final double x0 = controller.selected!.box.x;

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(controller.selected!.box.x, x0 + 1);

    await pressCtrl(tester, LogicalKeyboardKey.keyZ);
    expect(controller.selected!.box.x, x0);

    await pressCtrlShift(tester, LogicalKeyboardKey.keyZ);
    expect(controller.selected!.box.x, x0 + 1);
  });

  testWidgets('Ctrl+D يُكرّر العنصر المحدد', (WidgetTester tester) async {
    await pumpEditor(tester);
    final canvasWidget = canvas(tester);
    canvasWidget.controller.select('text-1');
    await tester.pump();

    await pressCtrl(tester, LogicalKeyboardKey.keyD);

    expect(canvasWidget.controller.document.elements.length, 3);
    expect(canvasWidget.controller.selectionCount, 1);
  });

  testWidgets('Ctrl+C ثم Ctrl+V ينسخ ويلصق العنصر', (WidgetTester tester) async {
    await pumpEditor(tester);
    final canvasWidget = canvas(tester);
    canvasWidget.controller.select('text-1');
    await tester.pump();

    await pressCtrl(tester, LogicalKeyboardKey.keyC);
    await pressCtrl(tester, LogicalKeyboardKey.keyV);

    expect(canvasWidget.controller.document.elements.length, 3);
    expect(canvasWidget.controller.selectedId, isNot('text-1'));
  });

  testWidgets('Ctrl+] يجلب العنصر للأمام و Ctrl+Shift+[ يُرسله للخلف',
      (WidgetTester tester) async {
    await pumpEditor(tester);
    final canvasWidget = canvas(tester);
    canvasWidget.controller.select('text-1');
    await tester.pump();

    await pressCtrl(tester, LogicalKeyboardKey.bracketRight);
    expect(canvasWidget.controller.document.elements.last.id, 'text-1');

    await pressCtrl(tester, LogicalKeyboardKey.bracketLeft);
    expect(canvasWidget.controller.document.elements.first.id, 'text-1');
  });

  testWidgets('الأسهم تُحرّك العنصر، و Shift يضاعف الخطوة',
      (WidgetTester tester) async {
    await pumpEditor(tester);
    final canvasWidget = canvas(tester);
    canvasWidget.controller.select('text-1');
    await tester.pump();
    final double x0 = canvasWidget.controller.selected!.box.x;

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(canvasWidget.controller.selected!.box.x, x0 + 1);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();
    expect(canvasWidget.controller.selected!.box.x, x0 + 11);
  });

  testWidgets('Esc يُلغي التحديد', (WidgetTester tester) async {
    await pumpEditor(tester);
    final canvasWidget = canvas(tester);
    canvasWidget.controller.selectAll();
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();

    expect(canvasWidget.controller.hasSelection, isFalse);
  });

  testWidgets('الاختصارات لا تُطبّق أثناء الكتابة داخل حقل النص',
      (WidgetTester tester) async {
    await pumpEditor(tester);
    final canvasWidget = canvas(tester);
    canvasWidget.controller.select('text-1');
    await tester.pump();

    // تحديد عنصر نصي يُظهر حقل المحتوى؛ نركّز عليه ثم نحاول الحذف.
    // البطاقات الجماعية أطول من الشريط السابق، فحقل المحتوى يقع أسفل
    // الطيّة — نُمرّر إليه أولاً كما يفعل المستخدم بعجلة الفأرة.
    await tester.ensureVisible(
      find.widgetWithText(TextField, 'محتوى النص'),
    );
    await tester.pump();
    await tester.tap(find.widgetWithText(TextField, 'محتوى النص'));
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await tester.pump();

    expect(canvasWidget.controller.document.elements.length, 2);
  });

  testWidgets('الأسهم وBackspace لا تحرّك ولا تحذف أثناء الكتابة، ويُحذف الحرف أصلاً',
      (WidgetTester tester) async {
    await pumpEditor(tester);
    final canvasWidget = canvas(tester);
    final controller = canvasWidget.controller;
    controller.select('text-1');
    await tester.pump();

    // البطاقات الجماعية أطول من الشريط السابق، فحقل المحتوى يقع أسفل
    // الطيّة — نُمرّر إليه أولاً كما يفعل المستخدم بعجلة الفأرة.
    await tester.ensureVisible(
      find.widgetWithText(TextField, 'محتوى النص'),
    );
    await tester.pump();
    await tester.tap(find.widgetWithText(TextField, 'محتوى النص'));
    await tester.pump();

    final Finder field = find.widgetWithText(TextField, 'محتوى النص');
    final EditableText editable = tester.widget<EditableText>(
      find.descendant(of: field, matching: find.byType(EditableText)),
    );
    editable.controller.selection =
        const TextSelection.collapsed(offset: 2);
    await tester.pump();
    final int length0 = editable.controller.text.length;
    final double x0 = controller.selected!.box.x;
    final double y0 = controller.selected!.box.y;

    // أسهم (عادية وسريعة مع Shift) + Backspace + Delete أثناء الكتابة:
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await tester.pump();

    // اللوحة لم تتأثر إطلاقاً:
    expect(controller.selected!.box.x, x0);
    expect(controller.selected!.box.y, y0);
    expect(controller.document.elements.length, 2);
    expect(controller.hasSelection, isTrue);

    // أما داخل الحقل فقد عمل الحذف بشكل طبيعي (حرف أو أكثر من المفاتيح):
    final EditableText after = tester.widget<EditableText>(
      find.descendant(of: field, matching: find.byType(EditableText)),
    );
    expect(after.controller.text.length, lessThan(length0));
  });

  group('ضمان التركيز على اللوحة', () {
    testWidgets('النقر على عنصر ينقل التركيز للوحة فتعمل الاختصارات فوراً',
        (WidgetTester tester) async {
      await pumpEditor(tester);
      final canvasWidget = canvas(tester);
      canvasWidget.controller.select('text-1');
      await tester.pump();

      // سرق التركيز: حقل المحتوى في شريط الخصائص.
      // البطاقات الجماعية أطول من الشريط السابق، فحقل المحتوى يقع أسفل
      // الطيّة — نُمرّر إليه أولاً كما يفعل المستخدم بعجلة الفأرة.
      await tester.ensureVisible(
        find.widgetWithText(TextField, 'محتوى النص'),
      );
      await tester.pump();
      await tester.tap(find.widgetWithText(TextField, 'محتوى النص'));
      await tester.pump();
      expect(
        FocusManager.instance.primaryFocus?.debugLabel,
        isNot('editor-canvas'),
      );

      // النقر على عنصر داخل اللوحة يعيد التركيز إلى عقدة اللوحة.
      await tester.tapAt(
        tester.getRect(find.byType(ElementView).first).center,
      );
      await tester.pump();
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'editor-canvas');

      // واختصارات اللوحة تلتقط مباشرةً بعد النقر.
      canvasWidget.controller.select('text-1');
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.delete);
      await tester.pump();
      expect(canvasWidget.controller.document.elements.length, 1);
      expect(canvasWidget.controller.hasSelection, isFalse);

      // تجاوز مؤقّت العدّاد المزدوج المتبقي من نقر اللوحة.
      await tester.pump(const Duration(milliseconds: 400));
    });

    testWidgets('النقر على مساحة فارغة ينقل التركيز للوحة',
        (WidgetTester tester) async {
      await pumpEditor(tester);
      final canvasWidget = canvas(tester);
      final controller = canvasWidget.controller;
      controller.select('text-1');
      await tester.pump();

      // البطاقات الجماعية أطول من الشريط السابق، فحقل المحتوى يقع أسفل
      // الطيّة — نُمرّر إليه أولاً كما يفعل المستخدم بعجلة الفأرة.
      await tester.ensureVisible(
        find.widgetWithText(TextField, 'محتوى النص'),
      );
      await tester.pump();
      await tester.tap(find.widgetWithText(TextField, 'محتوى النص'));
      await tester.pump();
      expect(
        FocusManager.instance.primaryFocus?.debugLabel,
        isNot('editor-canvas'),
      );

      final Rect canvasRect = tester.getRect(find.byType(TemplateCanvas));
      await tester.tapAt(Offset(canvasRect.left + 8, canvasRect.bottom - 8));
      await tester.pump();
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'editor-canvas');

      // والاختصارات تعمل فوراً بعد النقر على المساحة الفارغة.
      controller.select('text-1');
      await tester.pump();
      final double x0 = controller.selected!.box.x;
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(controller.selected!.box.x, x0 + 1);

      await tester.pump(const Duration(milliseconds: 400));
    });
  });

  group('Ctrl+Shift+D يبدّل اتجاه النص', () {
    testWidgets('يقلب العنصر المحدد من عربي إلى لاتيني والعكس',
        (WidgetTester tester) async {
      await pumpEditor(tester);
      final canvasWidget = canvas(tester);
      canvasWidget.controller.select('text-1');
      await tester.pump();

      await pressCtrlShift(tester, LogicalKeyboardKey.keyD);
      expect(
        (canvasWidget.controller.selected! as TextElement).direction,
        ElementDirection.ltr,
      );

      await pressCtrlShift(tester, LogicalKeyboardKey.keyD);
      expect(
        (canvasWidget.controller.selected! as TextElement).direction,
        ElementDirection.rtl,
      );
    });

    testWidgets(
        'أثناء الكتابة: يقلب الاتجاه ويحدّث اتجاه حقل النص ومؤشره فوراً',
        (WidgetTester tester) async {
      await pumpEditor(tester);
      final canvasWidget = canvas(tester);
      canvasWidget.controller.select('text-1');
      await tester.pump();

      // تركيز حقل المحتوى ثم وضع المؤشر داخل النص.
      final Finder field = find.widgetWithText(TextField, 'محتوى النص');
      await tester.tap(field);
      await tester.pump();

      final Finder editableFinder = find.descendant(
        of: field,
        matching: find.byType(EditableText),
      );
      final EditableText editable =
          tester.widget<EditableText>(editableFinder);
      editable.controller.selection =
          const TextSelection.collapsed(offset: 2);
      await tester.pump();
      expect(editable.textDirection, TextDirection.rtl);

      // الاختصار يجب أن يعمل رغم التركيز داخل الحقل.
      await pressCtrlShift(tester, LogicalKeyboardKey.keyD);

      expect(
        (canvasWidget.controller.selected! as TextElement).direction,
        ElementDirection.ltr,
      );
      // الحقل انقلب فوراً بلا حاجة للخروج منه أو الكتابة.
      final EditableText updated =
          tester.widget<EditableText>(editableFinder);
      expect(updated.textDirection, TextDirection.ltr);
      // والمؤشر بقي في مكانه المنطقي.
      expect(updated.controller.selection.baseOffset, 2);
    });
  });
}
