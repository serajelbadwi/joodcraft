import 'dart:math' as math;

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
/// One rendered line: the ink span it covers and the caret line it sits on.
///
/// Raw glyph boxes are deliberately **not** compared as rectangles: the two
/// renderers report different boxes for the same glyphs — the editable
/// merges a trailing space into the line's box and measures the box from the
/// line's metrics (18.6–20.3px tall), the paragraph splits the space into its
/// own box and measures it from the glyph's metrics (13.5px). Those are
/// painting artifacts of each renderer, identical whether or not the block
/// is focused. What is *layout* — and must therefore be identical in both
/// paths — is where a line's ink starts and ends and where its caret line
/// sits. A re-wrap, an indent change or the caret-margin 3px all move those;
/// renderer noise does not.
typedef InkLine = ({double left, double right, double top});

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

  /// Ink geometry of every rendered line of the document, in screen
  /// coordinates, sorted like the text is painted.
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
  List<InkLine> inkLines(WidgetTester tester) {
    final Set<String> blockTexts = blocks
        .map((JoodWriterBlock b) => b.text)
        .toSet();

    bool isBlockText(String text) {
      // The first-line indent travels as a `\uFFFC` placeholder span; the
      // document's own text carries none, so drop it before matching.
      final String normalized = text.replaceAll('￼', '');
      if (normalized.trim().isEmpty) return false;
      return blockTexts.any(
        (String blockText) => blockText.contains(normalized),
      );
    }

    final List<InkLine> lines = <InkLine>[];

    void addLines(RenderBox renderer, String text) {
      // Characters that carry ink: spaces are skipped (the two renderers
      // split and merge their boxes differently) and so is the indent
      // placeholder, which is a widget, not a glyph.
      final List<int> glyphs = <int>[
        for (int i = 0; i < text.length; i++)
          if (text[i] != ' ' && text[i] != '￼') i,
      ];
      if (glyphs.isEmpty) return;

      Offset caretOf(int i) {
        final TextPosition position = TextPosition(offset: i);
        if (renderer is RenderParagraph) {
          return renderer.getOffsetForCaret(position, Rect.zero);
        }
        if (renderer is RenderEditable) {
          // Same semantics as the paragraph's `getOffsetForCaret`: the top
          // of the caret at that character. (`getEndpointsForSelection`
          // would return the caret's *bottom* for a collapsed selection.)
          return renderer.getLocalRectForCaret(position).topLeft;
        }
        return Offset.zero;
      }

      List<TextBox> boxesOf(int i) {
        final TextSelection selection = TextSelection(
          baseOffset: i,
          extentOffset: i + 1,
        );
        if (renderer is RenderParagraph) {
          return renderer.getBoxesForSelection(selection);
        }
        if (renderer is RenderEditable) {
          return renderer.getBoxesForSelection(selection);
        }
        return const <TextBox>[];
      }

      // The caret line a character sits on identifies its rendered line —
      // the editable paints a whole block in one render object.
      final Map<double, List<double>> byCaretLine = <double, List<double>>{};
      for (final int i in glyphs) {
        final List<TextBox> boxes = boxesOf(i);
        if (boxes.isEmpty) continue;
        double left = double.infinity;
        double right = double.negativeInfinity;
        for (final TextBox box in boxes) {
          final Rect rect = box.toRect();
          left = math.min(left, renderer.localToGlobal(rect.topLeft).dx);
          right = math.max(right, renderer.localToGlobal(rect.bottomRight).dx);
        }
        final double top = renderer.localToGlobal(caretOf(i)).dy;
        final List<double> span = byCaretLine.putIfAbsent(
          top,
          () => <double>[left, right],
        );
        span[0] = math.min(span[0], left);
        span[1] = math.max(span[1], right);
      }

      for (final MapEntry<double, List<double>> entry in byCaretLine.entries) {
        lines.add((
          left: entry.value[0],
          right: entry.value[1],
          top: entry.key,
        ));
      }
    }

    void collect(RenderObject root) {
      if (root is RenderParagraph) {
        final String text = root.text.toPlainText();
        if (isBlockText(text)) addLines(root, text);
        return;
      }
      if (root is RenderEditable) {
        final String text = root.text?.toPlainText() ?? '';
        if (text.isNotEmpty && isBlockText(text)) addLines(root, text);
        return;
      }
      root.visitChildren(collect);
    }

    collect(tester.renderObject(find.byType(MaterialApp)));

    lines.sort((InkLine a, InkLine b) {
      final int dy = a.top.compareTo(b.top);
      if (dy != 0) return dy;
      return b.left.compareTo(a.left);
    });
    return lines;
  }

  String describe(List<InkLine> lines) => lines
      .map(
        (InkLine l) =>
            '(${l.left.toStringAsFixed(1)}‥${l.right.toStringAsFixed(1)} '
            'at ${l.top.toStringAsFixed(1)})',
      )
      .join('\n');

  /// Every line must keep its ink and its place — within a fraction of a
  /// pixel, which is pure float noise from the page scaling.
  void expectSameLines(List<InkLine> before, List<InkLine> after, String what) {
    final String report =
        '$what\nbefore:\n${describe(before)}\nafter:\n${describe(after)}';
    expect(after.length, before.length, reason: 'line count changed\n$report');
    for (int i = 0; i < before.length; i++) {
      expect(
        after[i].left,
        closeTo(before[i].left, 0.5),
        reason: 'line $i ink start\n$report',
      );
      expect(
        after[i].right,
        closeTo(before[i].right, 0.5),
        reason: 'line $i ink end\n$report',
      );
      expect(
        after[i].top,
        closeTo(before[i].top, 0.5),
        reason: 'line $i caret line\n$report',
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

    final List<InkLine> before = inkLines(tester);
    expect(before.length, greaterThan(4), reason: 'paragraph wraps lines');

    await tester.tapAt(visibleLineToTap(tester));
    await tester.pump();
    await tester.pump();

    expect(controller.activeBlockIndex, 1, reason: 'tap must activate block 1');
    expect(find.byType(TextField), findsOneWidget);

    expectSameLines(before, inkLines(tester), 'focus');
  });

  testWidgets('leaving the text (blur) moves no line at all', (
    WidgetTester tester,
  ) async {
    final WriterDocumentController controller = makeController();
    addTearDown(controller.dispose);
    await pumpCanvas(tester, controller);

    final List<InkLine> before = inkLines(tester);

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

    expectSameLines(before, inkLines(tester), 'blur');
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

    final List<InkLine> settled = inkLines(tester);

    for (int round = 0; round < 2; round++) {
      await tester.tapAt(line);
      await tester.pump();
      await tester.pump();
      expectSameLines(settled, inkLines(tester), 'focus round $round');

      controller.focusNodes[controller.activeBlockIndex].unfocus();
      await tester.pump();
      await tester.pump();
      expectSameLines(settled, inkLines(tester), 'blur round $round');
    }
  });
}
