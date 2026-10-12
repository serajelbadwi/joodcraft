/// اختبارات شريط Ribbon المُطوَّر: التبويبات الخمسة، التبديل، الطيّ،
/// الارتفاع، وألوان التبويب النشط — مع الغلاف القديم `WriterRibbonBar`.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/features/jood_writer/domain/jood_writer_block.dart';
import 'package:joodcraft/features/jood_writer/domain/jood_writer_document.dart';
import 'package:joodcraft/features/jood_writer/presentation/theme/writer_ribbon_theme.dart';
import 'package:joodcraft/features/jood_writer/presentation/widgets/ribbon/writer_ribbon_bar.dart';
import 'package:joodcraft/features/jood_writer/presentation/widgets/writer_ribbon_bar.dart' as legacy;
import 'package:joodcraft/features/jood_writer/presentation/writer_document_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ribbon_test_helpers.dart';

void main() {
  testWidgets('خمسة تبويبات بمفاتيح واتجاه البداية «الرئيسية»', (
    WidgetTester tester,
  ) async {
    await pumpRibbon(tester);

    for (final String key in kRibbonTabKeys) {
      expect(find.byKey(ValueKey<String>(key)), findsOneWidget, reason: key);
    }
    // أسماء التبويبات بالعربية (بلا مندوبي ترجمة فالقيمة الافتراضية تظهر).
    for (final String label in <String>[
      'الرئيسية',
      'التهيئة',
      'التصميم',
      'الحفظ',
      'المراجعة',
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }

    // محتوى التبويب النشط وحده ظاهر.
    expect(find.byKey(const ValueKey<String>('ribbon-content-0')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('ribbon-content-1')), findsNothing);
  });

  testWidgets('ارتفاع الشريط بين 90 و120 بكسل', (WidgetTester tester) async {
    await pumpRibbon(tester);
    final Size size = tester.getSize(
      find.byKey(const ValueKey<String>('writer-ribbon')),
    );
    expect(size.height, inInclusiveRange(90, 120));
    expect(size.width, 2400); // بعرض السطح كاملاً.
  });

  testWidgets('التبويب النشط ذهبي وغير النشط رمادي داكن', (
    WidgetTester tester,
  ) async {
    await pumpRibbon(tester);

    Color colorOf(String key) {
      final Finder container = find
          .descendant(
            of: find.byKey(ValueKey<String>(key)),
            matching: find.byType(Container),
          )
          .first;
      final Container c = tester.widget<Container>(container);
      return (c.decoration! as BoxDecoration).color!;
    }

    expect(colorOf('ribbon-tab-home'), WriterRibbonTheme.tabActive);
    expect(colorOf('ribbon-tab-setup'), WriterRibbonTheme.tabInactive);

    await selectRibbonTab(tester, 1);
    expect(colorOf('ribbon-tab-setup'), WriterRibbonTheme.tabActive);
    expect(colorOf('ribbon-tab-home'), WriterRibbonTheme.tabInactive);
  });

  testWidgets('التنقل بين التبويبات الخمسة يبدّل المحتوى', (
    WidgetTester tester,
  ) async {
    await pumpRibbon(tester);

    // التهيئة.
    await selectRibbonTab(tester, 1);
    expect(find.byKey(const ValueKey<String>('ribbon-content-1')), findsOneWidget);
    expect(ribbonSection('إعداد الصفحة'), findsOneWidget);
    expect(find.text('A4'), findsOneWidget); // زر المقاس يعرض A4.

    // التصميم.
    await selectRibbonTab(tester, 2);
    expect(find.byKey(const ValueKey<String>('ribbon-content-2')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('ribbon-shapes')), findsOneWidget);
    expect(ribbonSection('القوالب'), findsOneWidget);

    // الحفظ.
    await selectRibbonTab(tester, 3);
    expect(find.byKey(const ValueKey<String>('ribbon-content-3')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('file-undo')), findsOneWidget);
    expect(ribbonSection('التصدير'), findsOneWidget);

    // المراجعة.
    await selectRibbonTab(tester, 4);
    expect(find.byKey(const ValueKey<String>('ribbon-content-4')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('ribbon-find')), findsOneWidget);
    expect(ribbonSection('التعليقات'), findsOneWidget);

    // العودة للرئيسية.
    await selectRibbonTab(tester, 0);
    expect(find.byKey(const ValueKey<String>('ribbon-content-0')), findsOneWidget);
    expect(ribbonSection('الخطوط'), findsOneWidget);
  });

  testWidgets('الضغط على التبويب النشط يطوي المحتوى ويعيده', (
    WidgetTester tester,
  ) async {
    await pumpRibbon(tester);

    // طيّ.
    await tester.tap(find.byKey(const ValueKey<String>('ribbon-tab-home')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('ribbon-content-0')), findsNothing);

    // فتح.
    await tester.tap(find.byKey(const ValueKey<String>('ribbon-tab-home')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('ribbon-content-0')), findsOneWidget);
  });

  testWidgets('الغلاف القديم: مفتاح واحد، يختفي بلا كتلة نشطة', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(1400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final WriterDocumentController controller = WriterDocumentController(
      initialDocument: JoodWriterDocument(
        title: 'فارغ',
        blocks: const <JoodWriterBlock>[],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RibbonTestHost(
            controller: controller,
            child: legacy.WriterRibbonBar(controller: controller),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // بلا كتل ⇒ لا شريط إطلاقاً.
    expect(find.byKey(const ValueKey<String>('writer-ribbon')), findsNothing);

    // مستند بكتلة واحدة ⇒ الشريط ظاهر مرة واحدة فقط.
    controller.createNewDocument();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('writer-ribbon')), findsOneWidget);
  });
}
