/// تبويب «التهيئة»: إعداد الصفحة (مقاس/اتجاه/هوامش)، خلفية الصفحة (لون/
/// علامة مائية/إطار)، وترقيم الصفحات — كلّها إعدادات المستند الحقيقية.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/features/jood_writer/domain/jood_writer_document.dart';
import 'package:joodcraft/features/jood_writer/presentation/theme/writer_ribbon_theme.dart';
import 'package:joodcraft/features/jood_writer/presentation/widgets/ribbon/writer_ribbon_common.dart';
import 'package:joodcraft/features/jood_writer/presentation/writer_document_controller.dart';

import 'ribbon_test_helpers.dart';

void main() {
  testWidgets('أقسام التبويب الثلاثة ظاهرة', (WidgetTester tester) async {
    await pumpRibbon(tester, tab: 1);
    expect(ribbonSection('إعداد الصفحة'), findsOneWidget);
    expect(ribbonSection('خلفية الصفحة'), findsOneWidget);
    expect(ribbonSection('ترقيم الصفحات'), findsOneWidget);
  });

  testWidgets('مقاس الصفحة والاتجاه يُطبَّقان فوراً', (
    WidgetTester tester,
  ) async {
    final WriterDocumentController controller = await pumpRibbon(tester, tab: 1);

    // المقاس: A4 ⇒ A3 من القائمة.
    expect(controller.document.pageSize.label, 'A4');
    await tester.tap(find.byKey(const ValueKey<String>('ribbon-page-size')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('A3').last);
    await tester.pumpAndSettle();
    expect(controller.document.pageSize.label, 'A3');

    // الاتجاه من القائمة: طولي ⇒ عرضي.
    await tester.tap(find.byKey(const ValueKey<String>('ribbon-orientation')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('عرضي').last);
    await tester.pumpAndSettle();
    expect(controller.document.orientation, WriterOrientation.landscape);

    // زر التبديل السريع يعيده طولياً.
    await tester.tap(find.byKey(const ValueKey<String>('ribbon-landscape')));
    await tester.pump();
    expect(controller.document.orientation, WriterOrientation.portrait);
    expect(
      tester.widget<RibbonToggle>(find.byKey(const ValueKey<String>('ribbon-landscape'))).active,
      isFalse,
    );
  });

  testWidgets('الهوامش: جاهزة ومخصّصة عبر النافذة', (
    WidgetTester tester,
  ) async {
    final WriterDocumentController controller = await pumpRibbon(tester, tab: 1);

    // جاهزة ضيقة.
    await tester.tap(find.byKey(const ValueKey<String>('ribbon-margins')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ضيقة').last);
    await tester.pumpAndSettle();
    expect(controller.document.margins.top, 12.7);

    // مخصصة: 42 للأعلى.
    await tester.tap(find.byKey(const ValueKey<String>('ribbon-margins')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('مخصصة…').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('margins-ok')), findsOneWidget);

    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey<String>('margin-top')),
        matching: find.byType(TextFormField),
      ),
      '42',
    );
    await tester.tap(find.byKey(const ValueKey<String>('margins-ok')));
    await tester.pumpAndSettle();
    expect(controller.document.margins.top, 42.0);
  });

  testWidgets('لون الصفحة: اختيار عيّنة وإزالة', (WidgetTester tester) async {
    final WriterDocumentController controller = await pumpRibbon(tester, tab: 1);

    // عيّنة أولى من القائمة.
    await tester.tap(find.byKey(const ValueKey<String>('ribbon-page-color')));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(PopupMenuItem<Object>).at(1));
    await tester.pumpAndSettle();
    expect(controller.document.pageColor, isNotNull);
    expect(
      Color(controller.document.pageColor!),
      WriterRibbonTheme.swatches.first,
    );

    // الإزالة.
    await tester.tap(find.byKey(const ValueKey<String>('ribbon-page-color')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('أبيض (افتراضي)'));
    await tester.pumpAndSettle();
    expect(controller.document.pageColor, isNull);
  });

  testWidgets('العلامة المائية تُضبط وتُزال من نافذتها', (
    WidgetTester tester,
  ) async {
    final WriterDocumentController controller = await pumpRibbon(tester, tab: 1);
    expect(controller.document.watermark, isNull);

    await tester.tap(find.byKey(const ValueKey<String>('ribbon-watermark')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey<String>('watermark-text')),
      'مسودة',
    );
    await tester.tap(find.byKey(const ValueKey<String>('watermark-ok')));
    await tester.pumpAndSettle();
    expect(controller.document.watermark, 'مسودة');

    // إعادة الفتح ثم الإزالة.
    await tester.tap(find.byKey(const ValueKey<String>('ribbon-watermark')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('watermark-clear')));
    await tester.pumpAndSettle();
    expect(controller.document.watermark, isNull);
  });

  testWidgets('إطار الصفحة تبديل، وترقيم الصفحات كامل', (
    WidgetTester tester,
  ) async {
    final WriterDocumentController controller = await pumpRibbon(tester, tab: 1);

    // الإطار.
    expect(controller.document.pageBorder, isFalse);
    await tester.tap(find.byKey(const ValueKey<String>('ribbon-page-border')));
    await tester.pump();
    expect(controller.document.pageBorder, isTrue);
    await tester.tap(find.byKey(const ValueKey<String>('ribbon-page-border')));
    await tester.pump();
    expect(controller.document.pageBorder, isFalse);

    // نقطة البدء.
    expect(controller.document.pageNumbering.startPage, 1);
    await tester.tap(find.byKey(const ValueKey<String>('ribbon-page-number-start')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('5').last);
    await tester.pumpAndSettle();
    expect(controller.document.pageNumbering.startPage, 5);

    // تجاهل الصفحة الأولى.
    expect(controller.document.pageNumbering.excludeFirstN, 0);
    await tester.tap(find.byKey(const ValueKey<String>('ribbon-page-number-first')));
    await tester.pump();
    expect(controller.document.pageNumbering.excludeFirstN, 1);

    // تبديل الإظهار ثم الإزالة الكاملة.
    expect(controller.document.pageNumbering.enabled, isTrue);
    await tester.tap(find.byKey(const ValueKey<String>('ribbon-page-number-toggle')));
    await tester.pump();
    expect(controller.document.pageNumbering.enabled, isFalse);
    await tester.tap(find.byKey(const ValueKey<String>('ribbon-page-number-toggle')));
    await tester.pump();
    expect(controller.document.pageNumbering.enabled, isTrue);

    await tester.tap(find.byKey(const ValueKey<String>('ribbon-page-number-remove')));
    await tester.pump();
    expect(controller.document.pageNumbering.enabled, isFalse);
  });
}
