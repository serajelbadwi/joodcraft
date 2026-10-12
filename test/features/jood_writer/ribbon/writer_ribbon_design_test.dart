/// تبويب «التصميم»: القوالب (21 قالباً في 4 فئات + نافذة الكل)، الإدراج
/// (أشكال/جداول/رموز/صورة)، وتنسيق الأشكال الابتدائي.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/features/jood_writer/presentation/widgets/ribbon/writer_ribbon_common.dart';
import 'package:joodcraft/features/jood_writer/presentation/widgets/ribbon/writer_ribbon_design.dart';
import 'package:joodcraft/features/jood_writer/presentation/widgets/ribbon/writer_templates_catalog.dart';
import 'package:joodcraft/features/jood_writer/presentation/writer_document_controller.dart';

import 'ribbon_test_helpers.dart';

void main() {
  testWidgets('الأقسام الثلاثة والكتالوج: 21 قالباً في 4 فئات', (
    WidgetTester tester,
  ) async {
    await pumpRibbon(tester, tab: 2);
    expect(ribbonSection('القوالب'), findsOneWidget);
    expect(ribbonSection('الإدراج'), findsOneWidget);
    expect(ribbonSection('تنسيق الأشكال'), findsOneWidget);

    expect(WriterTemplatesCatalog.all.length, 21);
    expect(WriterTemplateCategory.values.length, 4);
    expect(WriterTemplatesCatalog.all.where(
      (WriterDocumentTemplate t) => t.category == WriterTemplateCategory.educational,
    ).isNotEmpty, isTrue);
    // كل قالب يبني مستنداً بعنوانه لا فارغاً.
    for (final WriterDocumentTemplate t in WriterTemplatesCatalog.all) {
      expect(t.build().title, t.nameAr, reason: t.id);
      expect(t.build().blocks, isNotEmpty, reason: t.id);
    }
  });

  testWidgets('شريحة قالب تُطبَّق على المستند', (WidgetTester tester) async {
    final WriterDocumentController controller = await pumpRibbon(tester, tab: 2);
    expect(controller.document.title, isNot('مذكرة دراسية'));

    await tester.tap(find.byKey(const ValueKey<String>('ribbon-template-study-note')));
    await tester.pumpAndSettle();
    expect(controller.document.title, 'مذكرة دراسية');
    expect(controller.document.blocks.length, greaterThan(1));
  });

  testWidgets('مرشِّح الفئات يقيّد الشرائح المعروضة', (
    WidgetTester tester,
  ) async {
    await pumpRibbon(tester, tab: 2);
    expect(
      find.byKey(const ValueKey<String>('ribbon-template-study-note')),
      findsOneWidget,
    );

    // فلترة على «شخصي».
    await tester.tap(find.byKey(const ValueKey<String>('ribbon-template-category')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('شخصي').last);
    await tester.pumpAndSettle();

    final RibbonMenu<String> menu = tester.widget<RibbonMenu<String>>(
      find.byKey(const ValueKey<String>('ribbon-template-category')),
    );
    expect(menu.buttonLabel, 'شخصي');
    expect(
      find.byKey(const ValueKey<String>('ribbon-template-study-note')),
      findsNothing,
    );
  });

  testWidgets('نافذة كل القوالب: تصفية وبطاقة تُطبَّق وتُغلق', (
    WidgetTester tester,
  ) async {
    final WriterDocumentController controller = await pumpRibbon(tester, tab: 2);

    await tester.tap(find.byKey(const ValueKey<String>('ribbon-template-all')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('template-cat-all')), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('template-card-research')),
      findsOneWidget,
    );

    // تصفية ثم عودة.
    await tester.tap(find.byKey(const ValueKey<String>('template-cat-personal')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('template-card-research')),
      findsNothing,
    );
    await tester.tap(find.byKey(const ValueKey<String>('template-cat-all')));
    await tester.pumpAndSettle();

    // تطبيق بطاقة: تغلق النافذة وتستبدل المستند.
    await tester.tap(find.byKey(const ValueKey<String>('template-card-research')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('template-cat-all')), findsNothing);
    expect(controller.document.title, 'بحث علمي');
  });

  testWidgets('إدراج أشكال وجداول ورموز', (WidgetTester tester) async {
    final WriterDocumentController controller = await pumpRibbon(tester, tab: 2);

    // شكل: قائمة الأشكال ⇒ مستطيل.
    await tester.tap(find.byKey(const ValueKey<String>('ribbon-shapes')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('مستطيل').last);
    await tester.pumpAndSettle();
    expect(controller.document.shapes.length, 1);

    // جدول 2×2 يضيف صفّين.
    await tester.tap(find.byKey(const ValueKey<String>('ribbon-insert-table')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2 × 2').last);
    await tester.pumpAndSettle();
    expect(controller.document.blocks.length, 3);
    expect(controller.document.blocks[1].text, contains('خانة'));

    // رمز في الكتلة النشطة.
    await tester.tap(find.byKey(const ValueKey<String>('ribbon-symbols')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('★').last);
    await tester.pumpAndSettle();
    expect(controller.document.blocks[controller.activeBlockIndex].text, contains('★'));
  });

  testWidgets('سماكة الحدّ من القائمة تظهر على الزر', (
    WidgetTester tester,
  ) async {
    await pumpRibbon(tester, tab: 2);
    await tester.tap(find.byKey(const ValueKey<String>('ribbon-shape-stroke')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('3.0').last);
    await tester.pumpAndSettle();

    final RibbonMenu<double> menu = tester.widget<RibbonMenu<double>>(
      find.byKey(const ValueKey<String>('ribbon-shape-stroke')),
    );
    expect(menu.buttonLabel, '3.0');
  });

  testWidgets('إدراج صورة: فشل المنتقي يظهر تنبيهاً بلا انهيار', (
    WidgetTester tester,
  ) async {
    await pumpRibbon(tester, tab: 2);
    await tester.tap(find.byKey(const ValueKey<String>('ribbon-insert-image')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      find.text('تعذّر فتح منتقي الصور في هذه البيئة'),
      findsOneWidget,
    );
  });
}
