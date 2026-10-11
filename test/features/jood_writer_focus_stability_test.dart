import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/features/jood_writer/domain/jood_writer_block.dart';
import 'package:joodcraft/features/jood_writer/domain/jood_writer_document.dart';
import 'package:joodcraft/features/jood_writer/presentation/widgets/writer_canvas.dart';
import 'package:joodcraft/features/jood_writer/presentation/writer_document_controller.dart';

/// Focus / blur must never reshape the text in "Jood Writer".
///
/// The rule: standing on the text (or leaving it) must not change a single
/// line — not its count, not its position, not its width. Any geometric
/// difference between the two frames means the focus rebuild reshaped the
/// text, which is the bug users see as "the text jumps when I click it".
///
/// Both rendering paths are inventoried — the static per-line `Text`
/// (a `RenderParagraph` per line) and the focused `TextField` (a single
/// `RenderEditable` painting the whole block) — because the bug is exactly
/// the geometric difference **between those two paths**: the same block is
/// painted by one in one frame and by the other in the next.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const String longLine =
      'This paragraph is long enough to wrap into several rendered lines so we '
      'can compare every line position before and after focusing.';

  /// Both blocks carry the same words but different first-line indents, so
  /// every wrap decision the editor makes is checked against the static path.
  const List<JoodWriterBlock> blocks = <JoodWriterBlock>[
    // First-line indent narrows the first line of the block only — the
    // historical source of the reshape on focus.
    JoodWriterBlock(
      text: longLine,
      firstLineIndentCm: 1,
      spaceBefore: 6,
      spaceAfter: 12,
    ),
    JoodWriterBlock(text: longLine, spaceBefore: 10, spaceAfter: 14),
  ];

  WriterDocumentController makeController() {
    final WriterDocumentController controller = WriterDocumentController(
      initialDocument: const JoodWriterDocument(title: 't', blocks: blocks),
    );
    controller.setAutosaveEnabled(false);
    return controller;
  }

  Future<void> pumpCanvas(
    WidgetTester tester,
    WriterDocumentController controller,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: WriterCanvas(controller: controller)),
      ),
    );
    await tester.pump();
  }

  /// Boxes of every rendered line of the document, in screen coordinates.
  ///
  /// Walks the render tree directly: `find.byType(RenderParagraph)` never
  /// matches (a `RenderObjectWidget` element's runtime type is
  /// `_RenderObjectElement`), and searching through widget types alone would
  /// miss the editable's lines — the very lines that must not move.
  ///
  /// Two renderers are deliberately ignored:
  ///  * the decorator's hint (`اكتب...`), which is painted even while the
  ///    block holds text and travels with the field;
  ///  * the page number, which is text but not document text.
  /// Both are filtered by matching the document's own block texts.
  List<Rect> lineBoxes(WidgetTester tester) {
    final Set<String> blockTexts = blocks
        .map((JoodWriterBlock b) => b.text)
        .toSet();

    final List<RenderBox> textRenderers = <RenderBox>[];

    void collect(RenderObject root) {
      if (root is RenderParagraph || root is RenderEditable) {
        textRenderers.add(root as RenderBox);
        return;
      }
      root.visitChildren(collect);
    }

    collect(tester.renderObject(find.byType(MaterialApp)));

    final List<Rect> boxes = <Rect>[];
    for (final RenderBox renderer in textRenderers) {
      final String text;
      final List<TextBox> rects;
      if (renderer is RenderParagraph) {
        text = renderer.text.toPlainText();
        rects = renderer.getBoxesForSelection(
          TextSelection(baseOffset: 0, extentOffset: text.length),
        );
      } else {
        final RenderEditable editable = renderer as RenderEditable;
        text = editable.text?.toPlainText() ?? '';
        rects = text.isEmpty
            ? const <TextBox>[]
            : editable.getBoxesForSelection(
                TextSelection(baseOffset: 0, extentOffset: text.length),
              );
      }
      // The editor paints a whole block in one render object (its text may
      // carry the first-line-indent placeholder); the static path paints one
      // `Text` per line. The decorator's hint and the page number are text
      // too — keep only what belongs to a block of this document.
      final String normalized = text.replaceAll('￼', '');
      final bool isBlockText = blockTexts.any(
        (String blockText) => blockText.contains(normalized),
      );
      if (!isBlockText) continue;
      for (final TextBox box in rects) {
        final Rect local = box.toRect();
        // Zero-height boxes come from placeholder spans, not from text lines.
        if (local.height <= 0.5 || local.width <= 0) continue;
        // Both corners global: the page is scaled to fit the surface, so a
        // global origin with a local size would measure a phantom rectangle.
        final Offset topLeft = renderer.localToGlobal(local.topLeft);
        final Offset bottomRight = renderer.localToGlobal(local.bottomRight);
        boxes.add(Rect.fromPoints(topLeft, bottomRight));
      }
    }
    boxes.sort((Rect a, Rect b) {
      final int dy = a.top.compareTo(b.top);
      if (dy != 0) return dy;
      return a.left.compareTo(b.left);
    });
    return boxes;
  }

  String describeBoxes(List<Rect> boxes) => boxes
      .map(
        (Rect r) =>
            '(${r.left.toStringAsFixed(1)},${r.top.toStringAsFixed(1)} '
            '${r.width.toStringAsFixed(1)}x${r.height.toStringAsFixed(1)})',
      )
      .join('\n');

  /// Every line must keep its place and its width — within a fraction of a
  /// pixel, which is pure float noise from the page scaling.
  ///
  /// The box *height* is not compared: the two renderers report it
  /// differently for the same glyphs (the editable reports the line box, the
  /// paragraph reports the glyph box), and that difference exists whether or
  /// not the block is focused.
  void expectSameLines(
    List<Rect> before,
    List<Rect> after,
    String what,
  ) {
    final String report =
        '$what\nbefore:\n${describeBoxes(before)}\nafter:\n${describeBoxes(after)}';
    expect(after.length, before.length, reason: 'line count changed\n$report');
    for (int i = 0; i < before.length; i++) {
      expect(
        after[i].left,
        closeTo(before[i].left, 0.5),
        reason: 'line $i left\n$report',
      );
      expect(
        after[i].top,
        closeTo(before[i].top, 0.5),
        reason: 'line $i top\n$report',
      );
      expect(
        after[i].width,
        closeTo(before[i].width, 0.5),
        reason: 'line $i width\n$report',
      );
    }
  }

  /// Taps a real, visible static line of the second block.
  ///
  /// The obvious "last box in the tree" is the page number at the bottom of
  /// the page — far outside the surface, so tapping it silently does nothing
  /// and the block never becomes editable.
  Offset visibleLineToTap(WidgetTester tester) {
    const Size surface = Size(1280, 900);
    for (final Element element in find.byType(Text).evaluate()) {
      final Text widget = element.widget as Text;
      final String? data = widget.data;
      if (data == null) continue;
      final String line = data.trim();
      if (line.isEmpty || !longLine.contains(line)) continue;
      final RenderBox box = element.renderObject! as RenderBox;
      final Offset center = box.localToGlobal(box.size.center(Offset.zero));
      if (center.dx < 0 ||
          center.dy < 0 ||
          center.dx > surface.width ||
          center.dy > surface.height) {
        continue;
      }
      return center;
    }
    fail('no visible static line of block 1 to tap');
  }

  testWidgets('only the first block starts editable', (
    WidgetTester tester,
  ) async {
    final WriterDocumentController controller = makeController();
    addTearDown(controller.dispose);
    await pumpCanvas(tester, controller);

    expect(find.byType(TextField), findsOneWidget);
    expect(controller.activeBlockIndex, 0);
  });

  testWidgets('standing on another block moves no line at all', (
    WidgetTester tester,
  ) async {
    final WriterDocumentController controller = makeController();
    addTearDown(controller.dispose);
    await pumpCanvas(tester, controller);

    final List<Rect> before = lineBoxes(tester);
    expect(before.length, greaterThan(4), reason: 'paragraph wraps lines');

    await tester.tapAt(visibleLineToTap(tester));
    await tester.pump();
    await tester.pump();

    expect(controller.activeBlockIndex, 1, reason: 'tap must activate block 1');
    expect(find.byType(TextField), findsOneWidget);

    expectSameLines(before, lineBoxes(tester), 'focus');
  });

  testWidgets('leaving the text (blur) moves no line at all', (
    WidgetTester tester,
  ) async {
    final WriterDocumentController controller = makeController();
    addTearDown(controller.dispose);
    await pumpCanvas(tester, controller);

    final List<Rect> before = lineBoxes(tester);

    await tester.tapAt(visibleLineToTap(tester));
    await tester.pump();
    await tester.pump();

    // Leave the text entirely. Blur is deliberately a no-op in the
    // controller: no activity switch, no rebuild — so the field stays where
    // it is, unfocused, and the block it left becomes a static paragraph.
    controller.focusNodes[controller.activeBlockIndex].unfocus();
    await tester.pump();
    await tester.pump();

    expect(controller.activeBlockIndex, 1, reason: 'blur moves no activity');
    expect(
      controller.focusNodes[1].hasFocus,
      isFalse,
      reason: 'the field really lost focus',
    );

    expectSameLines(before, lineBoxes(tester), 'blur');
  });

  testWidgets('focusing and blurring twice still moves nothing', (
    WidgetTester tester,
  ) async {
    final WriterDocumentController controller = makeController();
    addTearDown(controller.dispose);
    await pumpCanvas(tester, controller);

    // Start from a settled "all static" reference: focus block 1, then blur.
    final Offset line = visibleLineToTap(tester);
    await tester.tapAt(line);
    await tester.pump();
    await tester.pump();
    controller.focusNodes[controller.activeBlockIndex].unfocus();
    await tester.pump();
    await tester.pump();

    final List<Rect> settled = lineBoxes(tester);

    for (int round = 0; round < 2; round++) {
      await tester.tapAt(line);
      await tester.pump();
      await tester.pump();
      expectSameLines(settled, lineBoxes(tester), 'focus round $round');

      controller.focusNodes[controller.activeBlockIndex].unfocus();
      await tester.pump();
      await tester.pump();
      expectSameLines(settled, lineBoxes(tester), 'blur round $round');
    }
  });
}
