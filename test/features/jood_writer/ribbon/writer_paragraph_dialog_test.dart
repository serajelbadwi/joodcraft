/// نافذة «الفقرة»: الإزاحات والتباعد والمحاذاة وتباعد الأسطر — تُطبَّق عند
/// «موافق» على الكتلة النشطة فقط، وتُتجاهل التغييرات عند الإلغاء.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/features/jood_writer/domain/jood_writer_block.dart';
import 'package:joodcraft/features/jood_writer/domain/jood_writer_document.dart';
import 'package:joodcraft/features/jood_writer/presentation/writer_document_controller.dart';

import 'ribbon_test_helpers.dart';

void main() {
  Future<void> openDialog(WidgetTester tester) async {
    await tester.tap(
      find.byKey(const ValueKey<String>('ribbon-paragraph-dialog')),
    );
    await tester.pumpAndSettle();
  }

  Finder numberField(String key) => find.descendant(
    of: find.byKey(ValueKey<String>(key)),
    matching: find.byType(TextFormField),
  );

  testWidgets('موافق: تُطبَّق كل القيم على الكتلة النشطة', (
    WidgetTester tester,
  ) async {
    final WriterDocumentController controller = await pumpRibbon(tester);
    await openDialog(tester);

    await tester.enterText(numberField('paragraph-indent-general'), '2.5');
    await tester.enterText(numberField('paragraph-indent-first'), '-1');
    await tester.enterText(numberField('paragraph-space-before'), '12');
    await tester.enterText(numberField('paragraph-space-after'), '18');

    // تباعد الأسطر من القائمة المنسدلة.
    await tester.tap(find.byKey(const ValueKey<String>('paragraph-line-spacing')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2.0').last);
    await tester.pumpAndSettle();

    // المحاذاة: توسيط عبر شريحة الأزرار.
    await tester.tap(
      find.descendant(
        of: find.byType(SegmentedButton<JoodWriterAlign>),
        matching: find.byTooltip('وسط'),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey<String>('paragraph-ok')));
    await tester.pumpAndSettle();

    final JoodWriterBlock block = controller.document.blocks[0];
    expect(block.indentCm, 2.5);
    expect(block.firstLineIndentCm, -1.0);
    expect(block.spaceBefore, 12);
    expect(block.spaceAfter, 18);
    expect(block.lineSpacing, 2.0);
    expect(block.align, JoodWriterAlign.center);
  });

  testWidgets('إلغاء: لا يغيّر الكتلة شيئاً', (WidgetTester tester) async {
    final WriterDocumentController controller = await pumpRibbon(tester);
    final JoodWriterBlock before = controller.document.blocks[0];

    await openDialog(tester);
    await tester.enterText(numberField('paragraph-indent-general'), '9');
    await tester.tap(find.byKey(const ValueKey<String>('paragraph-cancel')));
    await tester.pumpAndSettle();

    final JoodWriterBlock after = controller.document.blocks[0];
    expect(after.indentCm, before.indentCm);
    expect(after.spaceBefore, before.spaceBefore);
    expect(after.lineSpacing, before.lineSpacing);
    expect(after.align, before.align);
  });

  testWidgets('القيم الابتدائية تعكس الكتلة النشطة', (
    WidgetTester tester,
  ) async {
    final WriterDocumentController controller = await pumpRibbon(
      tester,
      initialDocument: const JoodWriterDocument(
        title: 'فقرة',
        blocks: <JoodWriterBlock>[
          JoodWriterBlock(
            text: 'نصّ',
            indentCm: 1.5,
            spaceBefore: 6,
            spaceAfter: 3,
            lineSpacing: 2.5,
            align: JoodWriterAlign.justify,
          ),
        ],
      ),
    );
    await openDialog(tester);

    expect(
      tester
          .widget<TextFormField>(
            find.descendant(
              of: find.byKey(const ValueKey<String>('paragraph-indent-general')),
              matching: find.byType(TextFormField),
            ),
          )
          .controller!
          .text,
      '1.5',
    );
    expect(
      tester
          .widget<TextFormField>(numberField('paragraph-space-before'))
          .controller!
          .text,
      '6',
    );

    // القائمة مختارة على 2.5.
    expect(
      tester
          .widget<DropdownButtonFormField<double>>(
            find.byKey(const ValueKey<String>('paragraph-line-spacing')),
          )
          .initialValue,
      2.5,
    );

    // المحاذاة الابتدائية «ضبط».
    await tester.tap(find.byKey(const ValueKey<String>('paragraph-ok')));
    await tester.pumpAndSettle();
    expect(controller.document.blocks[0].align, JoodWriterAlign.justify);
  });
}
