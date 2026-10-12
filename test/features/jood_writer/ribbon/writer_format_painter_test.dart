/// العدّاسة (Format Painter) — منطق مستقلّ عن الواجهة: ضغطة واحدة تنسخ إلى
/// الكتلة التالية ثم تنطفئ، وضغطتان = نسخ مستمر، والإلغاء من الضغطة الثالثة.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/features/jood_writer/domain/jood_writer_block.dart';
import 'package:joodcraft/features/jood_writer/domain/jood_writer_document.dart';
import 'package:joodcraft/features/jood_writer/presentation/widgets/ribbon/writer_format_painter.dart';
import 'package:joodcraft/features/jood_writer/presentation/writer_document_controller.dart';

import 'ribbon_test_helpers.dart';

void main() {
  Future<WriterDocumentController> pumpHost(WidgetTester tester) async {
    final WriterDocumentController controller = WriterDocumentController(
      initialDocument: const JoodWriterDocument(
        title: 'عدّاسة',
        blocks: <JoodWriterBlock>[
          JoodWriterBlock(text: 'الأول', isBold: true, fontSize: 20),
          JoodWriterBlock(text: 'الثاني'),
        ],
      ),
    );
    await tester.pumpWidget(
      RibbonTestHost(controller: controller, child: const SizedBox.shrink()),
    );
    await tester.pump();
    return controller;
  }

  testWidgets('ضغططة واحدة: نسخ التنسيق إلى الكتلة التالية ثم إطفاء', (
    WidgetTester tester,
  ) async {
    final WriterDocumentController controller = await pumpHost(tester);
    final WriterFormatPainter painter = WriterFormatPainter(controller);

    expect(painter.mode, WriterPainterMode.off);
    expect(painter.isActive, isFalse);

    // الالتقاط من الكتلة النشطة (الأول: غامق 20).
    painter.press();
    expect(painter.mode, WriterPainterMode.once);
    expect(painter.isActive, isTrue);
    expect(painter.captured?.isBold, isTrue);
    expect(painter.captured?.fontSize, 20);

    // التبديل إلى الثانية ينسخ التنسيق وينطفئ العدّاسة.
    controller.setActiveBlock(1);
    await tester.pump();
    expect(controller.document.blocks[1].isBold, isTrue);
    expect(controller.document.blocks[1].fontSize, 20);
    expect(controller.document.blocks[1].text, 'الثاني'); // النصّ لم يتغيّر.
    expect(painter.mode, WriterPainterMode.off);

    painter.dispose();
  });

  testWidgets('ضغطتان: نسخ مستمر حتى الضغطة الثالثة', (
    WidgetTester tester,
  ) async {
    final WriterDocumentController controller = await pumpHost(tester);
    final WriterFormatPainter painter = WriterFormatPainter(controller);

    painter.press(); // once.
    painter.press(); // locked.
    expect(painter.mode, WriterPainterMode.locked);
    expect(painter.isActive, isTrue);

    controller.setActiveBlock(1);
    await tester.pump();
    expect(controller.document.blocks[1].isBold, isTrue);
    expect(painter.mode, WriterPainterMode.locked); // ما زال مستمراً.

    // الضغطة الثالثة تنطفئ.
    painter.press();
    expect(painter.mode, WriterPainterMode.off);
    expect(painter.captured, isNull);

    painter.dispose();
  });

  testWidgets('cancel() ينهي الالتقاط بلا نسخ', (
    WidgetTester tester,
  ) async {
    final WriterDocumentController controller = await pumpHost(tester);
    final WriterFormatPainter painter = WriterFormatPainter(controller);

    painter.press();
    expect(painter.isActive, isTrue);
    painter.cancel();
    expect(painter.mode, WriterPainterMode.off);

    // التبديل بعد الإلغاء لا ينسخ شيئاً.
    controller.setActiveBlock(1);
    await tester.pump();
    expect(controller.document.blocks[1].isBold, isFalse);
    expect(controller.document.blocks[1].fontSize, isNull);

    painter.dispose();
  });
}
