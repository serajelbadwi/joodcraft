import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/features/jood_writer/domain/jood_writer_block.dart';
import 'package:joodcraft/features/jood_writer/domain/jood_writer_document.dart';
import 'package:joodcraft/features/jood_writer/presentation/widgets/writer_canvas.dart';
import 'package:joodcraft/features/jood_writer/presentation/writer_document_controller.dart';

/// Tests that focus / blur never reshape the text in "Jood Writer".
///
/// The rule: standing on the text (or leaving it) must not change a single
/// line — not its count, not its position, not its height. Any geometric
/// difference between the two frames means the focus rebuild reshaped the
/// text, which is the bug users see as "the text jumps when I click it".
///
/// Both rendering paths are inventoried — the static per-line `RichText`
/// (a `RenderParagraph` per line) and the focused `TextField` (a single
/// `RenderEditable` painting the whole block) — because the bug is exactly
/// the geometric difference **between those two paths**.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const String longLine =
      'This paragraph is long enough to wrap into several rendered lines so we '
      'can compare every line position before and after focusing.';

  WriterDocumentController makeController() {
    final WriterDocumentController controller = WriterDocumentController(
      initialDocument: const JoodWriterDocument(
        title: 't',
        blocks: <JoodWriterBlock>[
          // First-line indent makes the first line wrap narrower than the
          // rest — the historical source of the reshape on focus.
          JoodWriterBlock(
            text: longLine,
            firstLineIndentCm: 1,
            spaceBefore: 6,
            spaceAfter: 12,
          ),
          JoodWriterBlock(text: longLine, spaceBefore: 10, spaceAfter: 14),
        ],
      ),
    );
    controller.setAutosaveEnabled(false);
    return controller;
  }

  /// Boxes of every rendered text line in the whole tree (screen coordinates).
  ///
  /// Walks the render tree directly: `find.byType(RenderParagraph)` never
  /// matches (a `RenderObjectWidget` element's runtime type is
  /// `_RenderObjectElement`), and searching through widget types alone would
  /// miss the editable's lines — the very lines that must not move.
  List<Rect> lineBoxes(WidgetTester tester) {
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
      if (text.isEmpty) continue;
      for (final TextBox box in rects) {
        final Rect local = box.toRect();
        // Zero-height boxes come from placeholder spans, not from text lines.
        if (local.height <= 0.5 || local.width <= 0) continue;
        final Offset global = renderer.localToGlobal(local.topLeft);
        boxes.add(
          Rect.fromLTWH(global.dx, global.dy, local.width, local.height),
        );
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

  /// Every line must keep its place, its width and its height — within a
  /// fraction of a pixel, which is pure float noise from the page scaling.
  void expectSameLines(
    List<Rect> before,
    List<Rect> after,
    String what,
  ) {
    final String report =
        '$what\nbefore:\n${describeBoxes(before)}\nafter:\n${describeBoxes(after)}';
    expect(after.length, before.length, reason: 'line count changed\n$report');
    for (int i = 0; i < before.length; i++) {
      expect(after[i].left, closeTo(before[i].left, 0.5), reason: 'line $i left\n$report');
      expect(after[i].top, closeTo(before[i].top, 0.5), reason: 'line $i top\n$report');
      expect(
        after[i].width,
        closeTo(before[i].width, 0.5),
        reason: 'line $i width\n$report',
      );
      expect(
        after[i].height,
        closeTo(before[i].height, 0.5),
        reason: 'line $i height\n$report',
      );
    }
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

    // Tap the last rendered line — a static line of the second block.
    final Rect last = before.last;
    await tester.tapAt(Offset(last.center.dx, last.center.dy));
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

    final Rect last = before.last;
    await tester.tapAt(Offset(last.center.dx, last.center.dy));
    await tester.pump();
    await tester.pump();

    // Leave the text entirely: the editor unmounts and the static path
    // repaints the very same lines.
    controller.focusNodes[controller.activeBlockIndex].unfocus();
    await tester.pump();
    await tester.pump();

    expectSameLines(before, lineBoxes(tester), 'blur');
  });

  testWidgets('focusing and blurring twice still moves nothing', (
    WidgetTester tester,
  ) async {
    final WriterDocumentController controller = makeController();
    addTearDown(controller.dispose);
    await pumpCanvas(tester, controller);

    // Start from a settled "all static" reference: focus block 1, then blur.
    final Rect last = lineBoxes(tester).last;
    await tester.tapAt(Offset(last.center.dx, last.center.dy));
    await tester.pump();
    await tester.pump();
    controller.focusNodes[controller.activeBlockIndex].unfocus();
    await tester.pump();
    await tester.pump();

    final List<Rect> settled = lineBoxes(tester);

    for (int round = 0; round < 2; round++) {
      await tester.tapAt(Offset(last.center.dx, last.center.dy));
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
