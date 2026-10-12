/// تبويب «المراجعة»: الإحصاء والتدقيق، البحث والاستبدال والانتقال،
/// الإدراج (تاريخ/وقت/رموز/معادلة/حاشية)، والتعليقات وسجل التغييرات.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/features/jood_writer/domain/jood_writer_block.dart';
import 'package:joodcraft/features/jood_writer/domain/jood_writer_document.dart';
import 'package:joodcraft/features/jood_writer/presentation/widgets/ribbon/writer_ribbon_common.dart';
import 'package:joodcraft/features/jood_writer/presentation/widgets/ribbon/writer_ribbon_insert.dart';
import 'package:joodcraft/features/jood_writer/presentation/writer_document_controller.dart';

import 'ribbon_test_helpers.dart';

/// مستند اختباري: كتلتان للبحث والإحصاء.
JoodWriterDocument _reviewDoc() => const JoodWriterDocument(
  title: 'مراجعة',
  blocks: <JoodWriterBlock>[
    JoodWriterBlock(text: 'مرحبا بالعالم مرحبا'),
    JoodWriterBlock(text: 'كتلة ثانية للبحث'),
  ],
);

void main() {
  testWidgets('أقسام التبويب الأربعة', (WidgetTester tester) async {
    await pumpRibbon(tester, tab: 4);
    expect(ribbonSection('التدقيق'), findsOneWidget);
    expect(ribbonSection('البحث'), findsOneWidget);
    expect(ribbonSection('الإدراج'), findsOneWidget);
    expect(ribbonSection('التعليقات'), findsOneWidget);
  });

  testWidgets('بلاطات الإحصاء تحسب كلمات المستند لحظياً', (
    WidgetTester tester,
  ) async {
    await pumpRibbon(tester, tab: 4, initialDocument: _reviewDoc());
    final WriterDocumentStats stats = WriterDocumentStats.of(
      <String>['مرحبا بالعالم مرحبا', 'كتلة ثانية للبحث'],
    );
    expect(stats.words, 6);

    expect(
      find.descendant(
        of: find.byKey(const ValueKey<String>('ribbon-word-count')),
        matching: find.text('${stats.words}'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey<String>('ribbon-char-count')),
        matching: find.text('${stats.characters}'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('ribbon-reading-time')),
      findsOneWidget,
    );
  });

  testWidgets('نافذة التدقيق تُفتح وتُغلق', (WidgetTester tester) async {
    await pumpRibbon(tester, tab: 4, initialDocument: _reviewDoc());
    await tester.tap(find.byKey(const ValueKey<String>('ribbon-spelling')));
    await tester.pumpAndSettle();

    expect(find.text('التدقيق والإحصاء'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('stats-close')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('stats-close')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('stats-close')), findsNothing);
  });

  testWidgets('البحث: عدّاد النتائج وزر التالي', (
    WidgetTester tester,
  ) async {
    await pumpRibbon(tester, tab: 4, initialDocument: _reviewDoc());
    await tester.tap(find.byKey(const ValueKey<String>('ribbon-find')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey<String>('find-query')),
      'مرحبا',
    );
    await tester.pump();

    final Finder count = find.byKey(const ValueKey<String>('find-count'));
    expect(tester.widget<Text>(count).data, 'النتيجة 1 من 2');

    await tester.tap(find.byKey(const ValueKey<String>('find-next')));
    await tester.pump();
    expect(tester.widget<Text>(count).data, 'النتيجة 2 من 2');

    await tester.tap(find.text('إغلاق'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('find-query')), findsNothing);
  });

  testWidgets('استبدال الكل يغيّر كل الكتل المطابقة', (
    WidgetTester tester,
  ) async {
    final WriterDocumentController controller = await pumpRibbon(
      tester,
      tab: 4,
      initialDocument: _reviewDoc(),
    );
    await tester.tap(find.byKey(const ValueKey<String>('ribbon-replace')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey<String>('find-query')),
      'مرحبا',
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('find-replace')),
      'أهلين',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey<String>('find-replace-all')));
    await tester.pump();

    expect(controller.document.blocks[0].text, 'أهلين بالعالم أهلين');
    expect(find.textContaining('كُتل مبدَلة'), findsOneWidget);

    await tester.tap(find.text('إغلاق'));
    await tester.pumpAndSettle();
  });

  testWidgets('الانتقال إلى كتلة رقمية', (WidgetTester tester) async {
    final WriterDocumentController controller = await pumpRibbon(
      tester,
      tab: 4,
      initialDocument: _reviewDoc(),
    );
    expect(controller.activeBlockIndex, 0);

    await tester.tap(find.byKey(const ValueKey<String>('ribbon-goto')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey<String>('goto-number')),
      '2',
    );
    await tester.tap(find.byKey(const ValueKey<String>('goto-ok')));
    await tester.pumpAndSettle();

    expect(controller.activeBlockIndex, 1);
  });

  testWidgets('التالي/السابق بلا استعلام يفتحان النافذة', (
    WidgetTester tester,
  ) async {
    await pumpRibbon(tester, tab: 4, initialDocument: _reviewDoc());

    await tester.tap(find.byKey(const ValueKey<String>('ribbon-find-next')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('find-query')), findsOneWidget);
    await tester.tap(find.text('إغلاق'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('ribbon-find-prev')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('find-query')), findsOneWidget);
  });

  testWidgets('إدراج التاريخ والوقت والمعادلة والحاشية', (
    WidgetTester tester,
  ) async {
    final WriterDocumentController controller = await pumpRibbon(
      tester,
      tab: 4,
      initialDocument: _reviewDoc(),
    );

    await tester.tap(find.byKey(const ValueKey<String>('ribbon-insert-date')));
    await tester.pump();
    expect(
      controller.document.blocks[0].text,
      contains('${DateTime.now().year}'),
    );

    await tester.tap(find.byKey(const ValueKey<String>('ribbon-insert-time')));
    await tester.pump();
    expect(controller.document.blocks[0].text, contains(':'));

    await tester.tap(
      find.byKey(const ValueKey<String>('ribbon-insert-equation')),
    );
    await tester.pump();
    expect(
      controller.document.blocks[0].text,
      contains('ناتج = ( ) × ( )'),
    );

    // الحاشية: علامة في النشطة + كتلة «١) » جديدة أخيرة.
    final int before = controller.document.blocks.length;
    await tester.tap(
      find.byKey(const ValueKey<String>('ribbon-insert-footnote')),
    );
    await tester.pump();
    expect(controller.document.blocks.length, before + 1);
    expect(controller.document.blocks[controller.activeBlockIndex].text, '١) ');
    expect(controller.document.blocks[0].text, contains('¹'));
  });

  testWidgets('التعليقات: إضافة وإظهار وحذف', (WidgetTester tester) async {
    await pumpRibbon(tester, tab: 4, initialDocument: _reviewDoc());

    // بلا تعليقات: زر الحذف معطّل.
    expect(
      tester
          .widget<RibbonToolButton>(
            find.byKey(const ValueKey<String>('ribbon-delete-comment')),
          )
          .onPressed,
      isNull,
    );

    // إضافة تعليق على الكتلة النشطة (0).
    await tester.tap(find.byKey(const ValueKey<String>('ribbon-new-comment')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey<String>('comment-text')),
      'مراجعة لاحقة',
    );
    await tester.tap(find.byKey(const ValueKey<String>('comment-save')));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<RibbonToolButton>(
            find.byKey(const ValueKey<String>('ribbon-delete-comment')),
          )
          .onPressed,
      isNotNull,
    );

    // الإظهار: التعليق مثبت على الكتلة الأولى.
    await tester.tap(
      find.byKey(const ValueKey<String>('ribbon-show-comments')),
    );
    await tester.pumpAndSettle();
    expect(find.text('مراجعة لاحقة'), findsOneWidget);
    expect(find.textContaining('الكتلة 1'), findsOneWidget);
    await tester.tap(find.text('إغلاق'));
    await tester.pumpAndSettle();

    // الحذف لكتلة الكتلة النشطة.
    await tester.tap(
      find.byKey(const ValueKey<String>('ribbon-delete-comment')),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<RibbonToolButton>(
            find.byKey(const ValueKey<String>('ribbon-delete-comment')),
          )
          .onPressed,
      isNull,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('ribbon-show-comments')),
    );
    await tester.pumpAndSettle();
    expect(find.text('لا توجد تعليقات بعد.'), findsOneWidget);
    await tester.tap(find.text('إغلاق'));
    await tester.pumpAndSettle();
  });

  testWidgets('سجل التغييرات يفتح من زر التتبّع', (WidgetTester tester) async {
    await pumpRibbon(tester, tab: 4, initialDocument: _reviewDoc());

    await tester.tap(find.byKey(const ValueKey<String>('ribbon-track-changes')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('history-close')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('history-close')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('history-close')), findsNothing);
  });
}
