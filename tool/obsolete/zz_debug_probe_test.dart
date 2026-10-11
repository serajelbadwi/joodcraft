import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/features/jood_writer/domain/jood_writer_block.dart';
import 'package:joodcraft/features/jood_writer/domain/jood_writer_document.dart';
import 'package:joodcraft/features/jood_writer/presentation/widgets/writer_canvas.dart';
import 'package:joodcraft/features/jood_writer/presentation/writer_document_controller.dart';

List<Rect> editorLines(RenderEditable editable, String text) {
  final Map<int, Rect> byLine = <int, Rect>{};
  for (int i = 0; i <= text.length; i++) {
    final Rect r = editable.getLocalRectForCaret(TextPosition(offset: i));
    final Offset g = editable.localToGlobal(r.topLeft);
    byLine.putIfAbsent(g.dy.round(), () => Rect.fromLTWH(g.dx, g.dy, r.width, r.height));
  }
  final List<Rect> lines = byLine.values.toList()
    ..sort((Rect a, Rect b) => a.top.compareTo(b.top));
  return lines;
}

List<Rect> staticLines(RenderParagraph p) {
  final String text = p.text.toPlainText();
  if (text.isEmpty) return const <Rect>[];
  return p
      .getBoxesForSelection(
        TextSelection(baseOffset: 0, extentOffset: text.length),
      )
      .map((TextBox b) {
        final Rect local = b.toRect();
        final Offset g = p.localToGlobal(local.topLeft);
        return Rect.fromLTWH(g.dx, g.dy, local.width, local.height);
      })
      .toList();
}

String fmt(List<Rect> rs) => rs
    .map(
      (Rect r) =>
          'top=${r.top.toStringAsFixed(1)} left=${r.left.toStringAsFixed(1)} '
          'w=${r.width.toStringAsFixed(1)} h=${r.height.toStringAsFixed(1)}',
    )
    .join(' | ');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('probe editor vs static', (WidgetTester tester) async {
    const String text =
        'one two three four five six seven eight nine ten eleven twelve';
    final WriterDocumentController controller = WriterDocumentController(
      initialDocument: const JoodWriterDocument(
        title: 't',
        blocks: <JoodWriterBlock>[
          JoodWriterBlock(text: text, firstLineIndentCm: 1),
          JoodWriterBlock(text: text),
        ],
      ),
    );
    controller.setAutosaveEnabled(false);
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: WriterCanvas(controller: controller)),
      ),
    );
    await tester.pump();

    debugPrint(
      'renderEditables=${find.byType(RenderEditable).evaluate().length}',
    );
    final RenderEditable editable = tester.renderObject<RenderEditable>(
      find.byType(RenderEditable),
    );

    debugPrint(
      'EDITOR lines (${text.length} chars): ${fmt(editorLines(editable, text))}',
    );
    debugPrint('editor offset=${editable.localToGlobal(Offset.zero)}');

    for (final Element e in find.byType(RichText).evaluate()) {
      if (e.renderObject is! RenderParagraph) continue;
      final RenderParagraph p = e.renderObject as RenderParagraph;
      final String t = p.text.toPlainText();
      if (!t.startsWith('one two')) continue;
      debugPrint('STATIC: ${fmt(staticLines(p))} offset=${p.localToGlobal(Offset.zero)}');
    }
  });
}
