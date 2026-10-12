/// تبويب «الرئيسية»: الأقسام الخمسة، وأدواتها الفعلية على الكتلة النشطة
/// (تنسيق/محاذاة/قوائم/إزاحات) + الكتل السريع + نافذة الفقرة والعدّاسة.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/features/jood_writer/domain/jood_writer_block.dart';
import 'package:joodcraft/features/jood_writer/presentation/widgets/ribbon/writer_ribbon_common.dart';
import 'package:joodcraft/features/jood_writer/presentation/writer_document_controller.dart';

import 'ribbon_test_helpers.dart';

void main() {
  testWidgets('الأقسام الخمسة ظاهرة وأدوات النصّ السريعة في متناول اليد', (
    WidgetTester tester,
  ) async {
    await pumpRibbon(tester);

    // أقسام الصفحة (عناوين RichText) — «الفقرة» يشترك اسمها مع زر النافذة.
    for (final String section in <String>[
      'الكتل',
      'الخطوط',
      'المحاذاة',
      'القوائم والمسافات',
      'الفقرة',
    ]) {
      expect(
        ribbonSection(section),
        findsAtLeastNWidgets(1),
        reason: section,
      );
    }
    // عنوان قسم الفقرة نفسه موجود (maxLines: 1).
    expect(
      find.byWidgetPredicate(
        (Widget w) =>
            w is RichText &&
            w.text.toPlainText() == 'الفقرة' &&
            w.maxLines == 1,
      ),
      findsOneWidget,
    );

    // تلميحات الأدوات الأساسية كما في الشاشة القائمة (عقد الاختبار القديم).
    expect(find.byTooltip('إضافة كتلة'), findsOneWidget);
    expect(find.byTooltip('حذف كتلة'), findsOneWidget);
    expect(find.byTooltip('فاصل صفحات (صفحة جديدة عند المؤشر)'), findsOneWidget);
    expect(find.byTooltip('عرض صفحتين متقابلتين (طي الكتاب)'), findsOneWidget);

    // قسم الكتل أول قسم (يظهر دون تمرير أفقي على عرض 1280).
    final double blocksX =
        tester.getTopLeft(find.byKey(const ValueKey<String>('ribbon-add-block')))
            .dx;
    final double fontsX =
        tester.getTopLeft(find.byKey(const ValueKey<String>('ribbon-bold'))).dx;
    expect(blocksX, lessThan(fontsX));
  });

  testWidgets('الغامق/المائل/التسطير/الشطب تعمل وتعاكس', (
    WidgetTester tester,
  ) async {
    final WriterDocumentController controller = await pumpRibbon(tester);
    expect(controller.document.blocks[0].isBold, isFalse);

    await tester.tap(find.byKey(const ValueKey<String>('ribbon-bold')));
    await tester.pump();
    expect(controller.document.blocks[0].isBold, isTrue);
    expect(
      tester.widget<RibbonToggle>(find.byKey(const ValueKey<String>('ribbon-bold'))).active,
      isTrue,
    );

    await tester.tap(find.byKey(const ValueKey<String>('ribbon-bold')));
    await tester.pump();
    expect(controller.document.blocks[0].isBold, isFalse);

    await tester.tap(find.byKey(const ValueKey<String>('ribbon-italic')));
    await tester.tap(find.byKey(const ValueKey<String>('ribbon-underline')));
    await tester.tap(find.byKey(const ValueKey<String>('ribbon-strikethrough')));
    await tester.pump();
    final JoodWriterBlock block = controller.document.blocks[0];
    expect(block.isItalic, isTrue);
    expect(block.isUnderline, isTrue);
    expect(block.isStrikethrough, isTrue);
  });

  testWidgets('حجم الخط: تكبير/تصغير ومنتقي القائمة', (
    WidgetTester tester,
  ) async {
    final WriterDocumentController controller = await pumpRibbon(tester);
    expect(controller.document.blocks[0].fontSize, isNull); // 13.5 افتراضي.

    await tester.tap(find.byKey(const ValueKey<String>('ribbon-font-size-up')));
    await tester.pump();
    expect(controller.document.blocks[0].fontSize, 14);

    await tester.tap(find.byKey(const ValueKey<String>('ribbon-font-size-down')));
    await tester.pump();
    expect(controller.document.blocks[0].fontSize, 13.5);

    // اختيار 16 من القائمة.
    await tester.tap(find.byKey(const ValueKey<String>('ribbon-font-size')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('16').last);
    await tester.pumpAndSettle();
    expect(controller.document.blocks[0].fontSize, 16);
  });

  testWidgets('عائلة الخط منتقي تعمل', (WidgetTester tester) async {
    final WriterDocumentController controller = await pumpRibbon(tester);
    await tester.tap(find.byKey(const ValueKey<String>('ribbon-font-family')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Amiri').last);
    await tester.pumpAndSettle();
    expect(controller.document.blocks[0].fontFamily, 'Amiri');
  });

  testWidgets('المحاذاة والقوائم والإزاحات تُطبَّق على الكتلة', (
    WidgetTester tester,
  ) async {
    final WriterDocumentController controller = await pumpRibbon(tester);

    await tester.tap(find.byKey(const ValueKey<String>('ribbon-align-center')));
    await tester.pump();
    expect(controller.document.blocks[0].align, JoodWriterAlign.center);

    await tester.tap(find.byKey(const ValueKey<String>('ribbon-bullet-list')));
    await tester.pump();
    expect(controller.document.blocks[0].kind, JoodWriterBlockKind.bullet);

    await tester.tap(find.byKey(const ValueKey<String>('ribbon-numbered-list')));
    await tester.pump();
    expect(controller.document.blocks[0].kind, JoodWriterBlockKind.numbered);

    await tester.tap(find.byKey(const ValueKey<String>('ribbon-indent-increase')));
    await tester.pump();
    expect(controller.document.blocks[0].indentCm, 0.5);

    await tester.tap(find.byKey(const ValueKey<String>('ribbon-first-line-increase')));
    await tester.pump();
    expect(controller.document.blocks[0].firstLineIndentCm, 1.0); // الابتدائي 0.5.

    await tester.tap(find.byKey(const ValueKey<String>('ribbon-hanging-indent')));
    await tester.pump();
    expect(controller.document.blocks[0].indentCm, 1.0);
    expect(controller.document.blocks[0].firstLineIndentCm, 0.0);
  });

  testWidgets('تباعد الأسطر والفقرة منقوائهما من القوائم', (
    WidgetTester tester,
  ) async {
    final WriterDocumentController controller = await pumpRibbon(tester);
    expect(controller.document.blocks[0].lineSpacing, 1.5);

    await tester.tap(find.byKey(const ValueKey<String>('ribbon-line-spacing')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2').last);
    await tester.pumpAndSettle();
    expect(controller.document.blocks[0].lineSpacing, 2.0);

    await tester.tap(find.byKey(const ValueKey<String>('ribbon-paragraph-spacing')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('تباعد 6').last);
    await tester.pumpAndSettle();
    expect(controller.document.blocks[0].spaceBefore, 6);
    expect(controller.document.blocks[0].spaceAfter, 6);
  });

  testWidgets('الكتل: إضافة/حذف/فاصل صفحات/طي الكتاب', (
    WidgetTester tester,
  ) async {
    final WriterDocumentController controller = await pumpRibbon(tester);

    // كتلة واحدة فقط: الحذف معطّل.
    expect(
      tester.widget<RibbonToolButton>(find.byKey(const ValueKey<String>('ribbon-delete-block'))).onPressed,
      isNull,
    );

    await tester.tap(find.byKey(const ValueKey<String>('ribbon-add-block')));
    await tester.pump();
    expect(controller.document.blocks.length, 2);
    expect(
      tester.widget<RibbonToolButton>(find.byKey(const ValueKey<String>('ribbon-delete-block'))).onPressed,
      isNotNull,
    );

    await tester.tap(find.byKey(const ValueKey<String>('ribbon-delete-block')));
    await tester.pump();
    expect(controller.document.blocks.length, 1);

    // فاصل صفحات.
    await tester.tap(find.byKey(const ValueKey<String>('ribbon-page-break')));
    await tester.pump();
    expect(controller.document.blocks.length, 2);

    // طي الكتاب: تبديل العرض.
    expect(controller.viewMode, WriterViewMode.single);
    await tester.tap(find.byKey(const ValueKey<String>('ribbon-spread-view')));
    await tester.pump();
    expect(controller.viewMode, WriterViewMode.spread);
    expect(
      tester.widget<RibbonToggle>(find.byKey(const ValueKey<String>('ribbon-spread-view'))).active,
      isTrue,
    );
    await tester.tap(find.byKey(const ValueKey<String>('ribbon-spread-view')));
    await tester.pump();
    expect(controller.viewMode, WriterViewMode.single);
  });

  testWidgets('علامات الاتجاه تُدرج في النصّ', (WidgetTester tester) async {
    final WriterDocumentController controller = await pumpRibbon(tester);
    final int before = controller.document.blocks[0].text.length;

    await tester.tap(find.byKey(const ValueKey<String>('ribbon-direction-rtl')));
    await tester.pump();
    expect(controller.document.blocks[0].text.length, before + 1);
    expect(controller.document.blocks[0].text, contains('‏')); // RLM.

    await tester.tap(find.byKey(const ValueKey<String>('ribbon-direction-ltr')));
    await tester.pump();
    expect(controller.document.blocks[0].text, contains('‎')); // LRM.
  });

  testWidgets('العصا السحرية عبر الواجهة: ضغطة/ضغطتان/إيقاف', (
    WidgetTester tester,
  ) async {
    await pumpRibbon(tester);
    final Finder key = find.byKey(const ValueKey<String>('ribbon-format-painter'));

    expect(tester.widget<RibbonToggle>(key).active, isFalse); // off.
    await tester.tap(key);
    await tester.pump();
    expect(tester.widget<RibbonToggle>(key).active, isTrue); // once.

    await tester.tap(key);
    await tester.pump();
    expect(tester.widget<RibbonToggle>(key).active, isTrue); // locked.

    await tester.tap(key);
    await tester.pump();
    expect(tester.widget<RibbonToggle>(key).active, isFalse); // off.
  });

  testWidgets('نافذة الفقرة تُفتح وتُغلق', (WidgetTester tester) async {
    await pumpRibbon(tester);
    await tester.tap(find.byKey(const ValueKey<String>('ribbon-paragraph-dialog')));
    await tester.pumpAndSettle();

    expect(find.text('إعدادات الفقرة'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('paragraph-ok')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('paragraph-cancel')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('paragraph-ok')), findsNothing);
  });
}
