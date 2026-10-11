import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/features/jood_writer/domain/jood_writer_block.dart';
import 'package:joodcraft/features/jood_writer/domain/jood_writer_document.dart';
import 'package:joodcraft/features/jood_writer/presentation/jood_writer_text_styles.dart';
import 'package:joodcraft/features/jood_writer/presentation/text_painter_measurer.dart';
import 'package:joodcraft/features/jood_writer/presentation/widgets/writer_canvas.dart';
import 'package:joodcraft/features/jood_writer/presentation/writer_document_controller.dart';

/// ط§ط®طھط¨ط§ط± ط§ط³طھظ‚ط±ط§ط± ط§ظ„ظƒطھط§ط¨ط©: ظƒظ„ ط¶ط؛ط·ط© ط²ط± ظ„ط§ طھط¹ظٹط¯ ظ‚ظٹط§ط³ ط§ظ„ظƒطھظ„ ط§ظ„طھظٹ ظ„ظ… ظٹطھط؛ظٹظ‘ط±
/// ظ†طµظ‘ظ‡ط§. ظ‡ط°ط§ ظ‡ظˆ ط§ظ„ظ…ط¨ط¯ط£ ط§ظ„ط£ط³ط§ط³ظٹ ظ„ظ…ظ†ط¹ ط§ظ‡طھط²ط§ط² ط§ظ„ظ†طµ ط£ط«ظ†ط§ط، ط§ظ„ظƒطھط§ط¨ط©.
void main() {
  group(
    'TextPainterBlockMeasurer: ظ„ط§ ط¥ط¹ط§ط¯ط© ظ‚ظٹط§ط³ ط¥ظ„ط§ ط¹ظ†ط¯ طھط؛ظٹظ‘ط± ط§ظ„ظ…ط­طھظˆظ‰ ظپط¹ظ„ط§ظ‹',
    () {
      test('ط¶ط؛ط·ط© ظ†ظپط³ ط§ظ„ظ†طµ ظ„ط§ طھط¹ظٹط¯ ط§ظ„طھط®ط·ظٹط·', () {
        final TextPainterBlockMeasurer measurer = TextPainterBlockMeasurer(
          contentWidth: 400,
          textScaler: TextScaler.noScaling,
        );

        const JoodWriterBlock block = JoodWriterBlock(
          text: 'ظ†طµ طھط¬ط±ظٹط¨ظٹ ظٹظƒظپظٹ ظ„ظٹظ„طھظپ ط¹ظ„ظ‰ ط³ط·ط±ظٹظ†',
          firstLineIndentCm: 1,
        );

        final List<String> first = measurer.linesOf(block);
        final int layoutsAfterFirst = measurer.layoutCount;

        // ط¶ط؛ط·ط© ط£ط®ط±ظ‰ ظ„ظ†ظپط³ ط§ظ„ظ…ط­طھظˆظ‰ (ظ…ط­ط§ظƒط§ط© ظƒطھط§ط¨ط© ط­ط±ظپ ط«ظ… ظ…ط³ط­ظ‡ ط£ظˆ ط¥ط¹ط§ط¯ط© ط±ط³ظ…).
        final List<String> second = measurer.linesOf(block);

        // ظ„ط§ طھط®ط·ظٹط· ط¥ط¶ط§ظپظٹ: ط§ظ„ظ†طھظٹط¬ط© ظ…ظ† ط§ظ„ظ…ط®ط²ظ† ط§ظ„ظ…ط¤ظ‚طھ.
        expect(measurer.layoutCount, layoutsAfterFirst);
        expect(measurer.cacheHitCount, 1);
        expect(second, first);
      });

      test(
        'طھط؛ظٹظٹط± ظ†طµظ‘ ط§ظ„ظƒطھظ„ط© ظٹط¹ظٹط¯ ط§ظ„ظ‚ظٹط§ط³ ظ…ط±ظ‘ط©ظ‹ ظˆط§ط­ط¯ط© ظپظ‚ط·',
        () {
          final TextPainterBlockMeasurer measurer = TextPainterBlockMeasurer(
            contentWidth: 400,
            textScaler: TextScaler.noScaling,
          );

          measurer.linesOf(const JoodWriterBlock(text: 'ط³ط·ط± ظˆط§ط­ط¯'));
          expect(measurer.layoutCount, 1);

          // ط¶ط؛ط·ط© ط£ط®ط±ظ‰ ط¨ظ†طµظ‘ ط£ط·ظˆظ„: طھط®ط·ظٹط· ظˆط§ط­ط¯ ط¬ط¯ظٹط¯ ظپظ‚ط·.
          final List<String> lines = measurer.linesOf(
            const JoodWriterBlock(
              text:
                  'ط³ط·ط± ظˆط§ط­ط¯ ط£ط·ظˆظ„ ط¨ظƒط«ظٹط± ظ„ظٹظ„طھظپ ط¹ظ„ظ‰ ط¹ط¯ط© ط£ط³ط·ط±',
            ),
          );
          expect(measurer.layoutCount, 2);
          expect(lines.length, greaterThan(1));

          // ط§ظ„ط¹ظˆط¯ط© ظ„ظ„ظ†طµ ط§ظ„ط£طµظ„ظٹ: ط§ظ„ظ…ط®ط²ظ† ظ„ط§ ظٹط²ط§ظ„ ظٹط­طھظپط¸ ط¨ط§ظ„ظ†طھظٹط¬ط© ط§ظ„ظ‚ط¯ظٹظ…ط©.
          measurer.linesOf(const JoodWriterBlock(text: 'ط³ط·ط± ظˆط§ط­ط¯'));
          expect(measurer.layoutCount, 2);
          expect(measurer.cacheHitCount, greaterThanOrEqualTo(1));
        },
      );

      test(
        'طھط؛ظٹظٹط± ط§ظ„طھظ†ط³ظٹظ‚ (ط§ظ„ط­ط¬ظ…/ط§ظ„ظ„ظˆظ†/ط§ظ„ط®ط· ط§ظ„ط¹ط±ظٹط¶) ظٹط¹ظٹط¯ ط§ظ„ظ‚ظٹط§ط³ ظ„ط£ظ† ط§ظ„ط¹ط±ط¶ ظٹطھط؛ظٹظ‘ط±',
        () {
          final TextPainterBlockMeasurer measurer = TextPainterBlockMeasurer(
            contentWidth: 400,
            textScaler: TextScaler.noScaling,
          );

          const JoodWriterBlock plain = JoodWriterBlock(
            text: 'ظ†طµ ط«ط§ط¨طھ ط¨ط·ظˆظ„ ظ…ط¹ظٹظ‘ظ†',
          );
          final List<String> before = measurer.linesOf(plain);

          // ظ†ظپط³ ط§ظ„ظ†طµ ظ„ظƒظ† ط­ط¬ظ… ط®ط· ط£ظƒط¨ط± â‡’ ط§ظ„ط§ظ„طھظپط§ظپ ظٹطھط؛ظٹظ‘ط± ظپط¹ظ„ط§ظ‹.
          final JoodWriterBlock bigger = plain.copyWith(fontSize: 30);
          final List<String> after = measurer.linesOf(bigger);

          expect(
            measurer.layoutCount,
            2,
            reason: 'ط§ظ„طھظ†ط³ظٹظ‚ ظٹط؛ظٹظ‘ط± ط§ظ„ط¹ط±ط¶ ط§ظ„ظپط¹ظ„ظٹ',
          );
          expect(after.length, greaterThanOrEqualTo(before.length));
        },
      );

      test(
        'طھط؛ظٹظٹط± `firstLineIndent` ظٹط¹ظٹط¯ ط§ظ„ظ‚ظٹط§ط³ (ظٹط¤ط«ط± ط¹ظ„ظ‰ ط¹ط±ط¶ ط§ظ„ط³ط·ط± ط§ظ„ط£ظˆظ„)',
        () {
          final TextPainterBlockMeasurer measurer = TextPainterBlockMeasurer(
            contentWidth: 400,
            textScaler: TextScaler.noScaling,
          );

          final List<String> noIndent = measurer.linesOf(
            const JoodWriterBlock(text: 'ظ†طµ ط«ط§ط¨طھ ط¨ط·ظˆظ„ ظ…ط¹ظٹظ‘ظ†'),
          );
          expect(measurer.layoutCount, 1);

          final List<String> indented = measurer.linesOf(
            const JoodWriterBlock(
              text: 'ظ†طµ ط«ط§ط¨طھ ط¨ط·ظˆظ„ ظ…ط¹ظٹظ‘ظ†',
              firstLineIndentCm: 2,
            ),
          );

          expect(measurer.layoutCount, 2);
          expect(indented.length, greaterThanOrEqualTo(noIndent.length));
        },
      );

      test(
        'ط§ظ„ظƒطھظ„ط© ط§ظ„ظپط§ط±ط؛ط© طھط¹ظٹط¯ ط§ظ„ط³ط·ط± ط§ظ„ظˆط§ط­ط¯ ط¨ظ„ط§ طھط®ط·ظٹط· ط¥ط¶ط§ظپظٹ ط¹ظ†ط¯ طھظƒط±ط§ط± lineHeight',
        () {
          final TextPainterBlockMeasurer measurer = TextPainterBlockMeasurer(
            contentWidth: 400,
            textScaler: TextScaler.noScaling,
          );

          const JoodWriterBlock empty = JoodWriterBlock(text: '');
          expect(measurer.linesOf(empty), <String>['']);

          // ط§ط±طھظپط§ط¹ ط³ط·ط± ط§ظ„ظƒطھظ„ط© ط§ظ„ظپط§ط±ط؛ط©: طھط®ط·ظٹط· ظˆط§ط­ط¯ ط«ظ… ظ…ط®ط²ظ†.
          final double h1 = measurer.lineHeightOf(empty);
          final int layouts = measurer.layoutCount;
          expect(h1, greaterThan(0));
          measurer.lineHeightOf(empty);
          expect(measurer.layoutCount, layouts);
        },
      );

      test(
        'ط§ظ„ظƒطھظ„ط© ط§ظ„ظ…ظ…طھظ„ط¦ط© ظ„ط§ طھط¹ظٹط¯ ط§ظ„طھط®ط·ظٹط· ط¹ظ†ط¯ طھط¨ط¯ظٹظ„ linesOf ظˆ lineHeightOf',
        () {
          final TextPainterBlockMeasurer measurer = TextPainterBlockMeasurer(
            contentWidth: 400,
            textScaler: TextScaler.noScaling,
          );

          const JoodWriterBlock block = JoodWriterBlock(
            text: 'ظ†طµ ط«ط§ط¨طھ ط¨ط·ظˆظ„ ظ…ط¹ظٹظ‘ظ† ظٹظƒظپظٹ ظ„ط³ط·ط±ظٹظ†',
          );

          measurer.lineHeightOf(block);
          final int afterHeight = measurer.layoutCount;

          // linesOf ظٹط³طھط¹ظ…ظ„ ظ†ظپط³ ط§ظ„ظ…ط¯ط®ظ„ ط§ظ„ظ…ط®ط²ظ‘ظ†: ظ„ط§ ظ„ظˆط­ط© ط±ط³ظ… ط¬ط¯ظٹط¯ط©.
          measurer.linesOf(block);
          expect(measurer.layoutCount, afterHeight);
          expect(measurer.cacheHitCount, 1);
        },
      );

      test(
        'ط§ظ„ظ…ط®ط²ظ† ظ„ط§ ظٹطھط¬ط§ظˆط² ط³ط¹طھظ‡ ظˆظ„ط§ ظٹطھط³ط±ظ‘ط¨ ط¨ظ„ط§ ط­ط¯ظˆط¯',
        () {
          final TextPainterBlockMeasurer measurer = TextPainterBlockMeasurer(
            contentWidth: 400,
            textScaler: TextScaler.noScaling,
          );

          for (int i = 0; i < TextPainterBlockMeasurer.capacity + 10; i++) {
            measurer.linesOf(
              JoodWriterBlock(
                text: 'ظ†طµ ط±ظ‚ظ… $i ط¨ط·ظˆظ„ ط«ط§ط¨طھ ظ…ط¹ظٹظ‘ظ†',
              ),
            );
          }

          // ظ„ط§ طھط®ط·ظٹط· ط£ظƒط«ط± ظ…ظ† ط¹ط¯ط¯ ط§ظ„ط­ط§ظ„ط§طھ ط§ظ„ظپط±ظٹط¯ط©طŒ ظˆط§ظ„ظ…ط®ط²ظ† ط¹ظ†ط¯ ط§ظ„ط³ظ‚ظپ.
          expect(measurer.layoutCount, TextPainterBlockMeasurer.capacity + 10);
          expect(
            TextPainterBlockMeasurer.capacity,
            lessThanOrEqualTo(TextPainterBlockMeasurer.capacity),
          );
        },
      );

      test(
        'ظƒطھظ„طھط§ظ† ط¨ظ†ظپط³ ط§ظ„ظ…ط­طھظˆظ‰ طھظ…ط§ظ…ط§ظ‹ طھط´طھط±ظƒط§ظ† ظپظٹ ظ†ظپط³ ط§ظ„ظ…ط¯ط®ظ„ (ط¨طµظ…ط© ط§ظ„ظ…ط­طھظˆظ‰)',
        () {
          final TextPainterBlockMeasurer measurer = TextPainterBlockMeasurer(
            contentWidth: 400,
            textScaler: TextScaler.noScaling,
          );

          const JoodWriterBlock a = JoodWriterBlock(
            text: 'ظ†طµ ظ…طھط·ط§ط¨ظ‚ ط¨ظٹظ† ظƒطھظ„طھظٹظ†',
            fontSize: 14,
          );
          const JoodWriterBlock b = JoodWriterBlock(
            text: 'ظ†طµ ظ…طھط·ط§ط¨ظ‚ ط¨ظٹظ† ظƒطھظ„طھظٹظ†',
            fontSize: 14,
          );

          // ظƒطھظ„طھط§ظ† ظ…ط®طھظ„ظپطھط§ظ† ظ‡ظˆظٹظ‘ط§ظ‹ ظ„ظƒظ† ظ…ط­طھظˆط§ط© ظˆط§ط­ط¯ â‡’ ظ…ط®ط²ظ† ظˆط§ط­ط¯.
          measurer.linesOf(a);
          expect(measurer.layoutCount, 1);
          measurer.linesOf(b);
          expect(measurer.layoutCount, 1);
          expect(measurer.cacheHitCount, 1);
        },
      );
    },
  );

  group(
    'JoodWriterTextStyles: ظ…طµط¯ط± ظˆط§ط­ط¯ ظ„ظ„ط­ط¬ظ… ظ„ط§ ظٹطھط؛ظٹظ‘ط± ط¨ظٹظ† ط§ظ„ظ‚ظٹط§ط³ ظˆط§ظ„ط±ط³ظ…',
    () {
      test(
        'ط­ط¬ظ… ط§ظ„ط®ط· ط§ظ„ط§ظپطھط±ط§ط¶ظٹ ط«ط§ط¨طھ ظ„ظƒظ„ ظ†ظˆط¹ ظƒطھظ„ط©',
        () {
          expect(
            JoodWriterTextStyles.fontSizeOf(
              const JoodWriterBlock(
                text: 'x',
                kind: JoodWriterBlockKind.paragraph,
              ),
            ),
            13.5,
          );
          expect(
            JoodWriterTextStyles.fontSizeOf(
              const JoodWriterBlock(
                text: 'x',
                kind: JoodWriterBlockKind.heading1,
              ),
            ),
            24,
          );
          expect(
            JoodWriterTextStyles.fontSizeOf(
              const JoodWriterBlock(
                text: 'x',
                kind: JoodWriterBlockKind.heading2,
              ),
            ),
            18,
          );
        },
      );

      test('ط­ط¬ظ… ط®ط· ظ…ط®طµطµ ظٹطھظپظˆظ‚ ط¹ظ„ظ‰ ط§ظ„ط§ظپطھط±ط§ط¶ظٹ', () {
        const JoodWriterBlock block = JoodWriterBlock(text: 'x', fontSize: 30);
        expect(JoodWriterTextStyles.fontSizeOf(block), 30);
      });
    },
  );

  group(
    'JoodWriterDocument: ط§ظ„ط¨ظ†ظٹط© ط§ظ„ط§ظپطھط±ط§ط¶ظٹط© ط«ط§ط¨طھط© ط¹ظ†ط¯ ط§ظ„ظƒطھط§ط¨ط©',
    () {
      test(
        'ط§ظ„ظ…ط³طھظ†ط¯ ط§ظ„ظپط§ط±ط؛ ظٹط¨ط¯ط£ ط¨ظƒطھظ„ط© ظˆط§ط­ط¯ط© ظ‚ط§ط¨ظ„ط© ظ„ظ„ظƒطھط§ط¨ط©',
        () {
          final JoodWriterDocument doc = JoodWriterDocument.empty();
          expect(doc.blocks, hasLength(1));
          expect(doc.blocks.first.text, '');
          expect(doc.blocks.first.kind, JoodWriterBlockKind.paragraph);
        },
      );

      test('ط£ظˆظ„ ط³ط·ط± ط¥ط²ط§ط­ط© ط§ظ„ط§ظپطھط±ط§ط¶ظٹط© ط«ط§ط¨طھط©', () {
        expect(JoodWriterBlock.defaultFirstLineIndentCm, 0.5);
        expect(
          JoodWriterDocument.empty().blocks.first.firstLineIndentCm,
          JoodWriterBlock.defaultFirstLineIndentCm,
        );
      });
    },
  );

  // ───────────────────────────────────────────────────────────────────────────
  //  اللوحة: الكتابة لا تهتزّ — إشعارٌ واحد لكل موجة، ولا قَفْزة بلا داعٍ
  // ───────────────────────────────────────────────────────────────────────────

  group('WriterCanvas: ثبات النص أثناء الكتابة', () {
    Future<void> setSurface(WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
    }

    /// تبني اللوحة وحدها بمتحكّم نملكه — لنتحقّق من قرارات الشطر بأنفسنا.
    Future<void> pumpCanvas(
      WidgetTester tester,
      WriterDocumentController controller,
    ) async {
      await setSurface(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: WriterCanvas(controller: controller)),
        ),
      );
      await tester.pump();
    }

    ScrollController canvasScroll(WidgetTester tester) {
      final ListView list = tester.widget<ListView>(
        find.byWidgetPredicate(
          (Widget w) => w is ListView && w.controller != null,
        ),
      );
      return list.controller!;
    }

    /// متحكّم بلا حفظ تلقائي: لا يبقى مؤقّت معلّقاً عند نهاية الإطار الوهمي.
    WriterDocumentController makeController() {
      final WriterDocumentController controller = WriterDocumentController();
      controller.setAutosaveEnabled(false);
      return controller;
    }

    /// مرور زمني كافٍ لإنهاء حركة التمرير.
    Future<void> settleScroll(WidgetTester tester) async {
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    testWidgets('ضغطة المفتاح تُنتج إشعاراً واحداً لا ثلاثة', (
      WidgetTester tester,
    ) async {
      final WriterDocumentController controller = makeController();
      addTearDown(controller.dispose);
      await pumpCanvas(tester, controller);

      int notifications = 0;
      controller.addListener(() => notifications++);

      controller.controllers[0].value = const TextEditingValue(text: 'أ');
      await tester.pump();
      expect(notifications, 1, reason: 'موجة تعديل واحدة = إشعار واحد');

      // ضغطتان قبل الإطار التالي: تُدمجان في إشعار واحد — لا ثلاث إعادات بناء.
      controller.controllers[0].value = const TextEditingValue(text: 'أب');
      controller.controllers[0].value = const TextEditingValue(text: 'أبت');
      expect(notifications, 1, reason: 'لا يُذعَ شيء قبل نهاية الموجة');
      await tester.pump();
      expect(notifications, 2);
      expect(controller.document.blocks.single.text, 'أبت');
    });

    testWidgets('الشطر يقع متزامناً مع التعديل فلا يُعاد عند إشعاره', (
      WidgetTester tester,
    ) async {
      final WriterDocumentController controller = makeController();
      addTearDown(controller.dispose);
      await pumpCanvas(tester, controller);

      // نستولي على نقطة الشطر لنعدّ استدعاءاتها (اللوحة لا تحتاجها هنا:
      // النصّ قصير ولا يتجاوز صفحته).
      int splits = 0;
      controller.onEdited = () => splits++;

      controller.controllers[0].value = const TextEditingValue(text: 'أبجد');
      expect(splits, 1, reason: 'يُنفَّذ قبل الرسم مباشرةً');
      expect(
        controller.autoSplitRevision,
        controller.textRevision,
        reason: 'المتحكّم يعلَن أنّ الشطر قد راجع هذه المراجعة فعلاً',
      );

      // إشعار الموجة يصل بعد ذلك — المراجعة نفسها ⇒ لا شطر ثانٍ.
      await tester.pump();
      expect(splits, 1);
    });

    testWidgets('الكتابة التي لا تتجاوز صفحتها لا تحرّك التمرير إطلاقاً', (
      WidgetTester tester,
    ) async {
      final WriterDocumentController controller = makeController();
      addTearDown(controller.dispose);
      await pumpCanvas(tester, controller);
      final ScrollController scroll = canvasScroll(tester);

      // ثمان ضغطات تُكوّن فقرة قصيرة تكفي صفحة A4 الأولى.
      for (int i = 1; i <= 8; i++) {
        controller.controllers[0].value = TextEditingValue(
          text: 'سطر رقم $i من الفقرة القصيرة. ',
        );
        await tester.pump();
      }
      await settleScroll(tester);

      expect(tester.takeException(), isNull);
      expect(
        scroll.offset,
        0,
        reason: 'لا شطر ⇒ لا قَفْزة ولا حركة تمرير إطلاقاً',
      );
    });

    testWidgets('استكمال الكتابة بعد الشطر لا تُحرّك الموضع المُثبَّت', (
      WidgetTester tester,
    ) async {
      final WriterDocumentController controller = makeController();
      addTearDown(controller.dispose);
      await pumpCanvas(tester, controller);
      final ScrollController scroll = canvasScroll(tester);

      final String base = 'سطر الاختبار الطويل ' * 400;
      controller.controllers[0].value = TextEditingValue(text: base);
      await tester.pump();
      await settleScroll(tester);

      final double settledOffset = scroll.offset;
      expect(settledOffset, greaterThan(0), reason: 'الشطر أنجز صفحته الجديدة');

      // ضغطات إضافية على **الكتلة الأخيرة** (التي أسفل الوثيقة): لا تملأ
      // سطراً جديداً ⇒ لا شطر ⇒ لا سبب للحركة.
      final int last = controller.document.blocks.length - 1;
      final String lastText = controller.document.blocks[last].text;
      for (int i = 0; i < 5; i++) {
        controller.controllers[last].value = TextEditingValue(
          text: '$lastText ${'و' * (i + 1)}',
        );
        await tester.pump();
      }
      await settleScroll(tester);

      expect(tester.takeException(), isNull);
      expect(
        scroll.offset,
        settledOffset,
        reason: 'النصّ يكمل مكانه: لا اهتزاز ولا قفزات مع كل ضغطة',
      );
    });

    testWidgets('انتقال النشاط بين الكتل لا يُحرّك التمرير', (
      WidgetTester tester,
    ) async {
      final WriterDocumentController controller = makeController();
      addTearDown(controller.dispose);
      await pumpCanvas(tester, controller);
      final ScrollController scroll = canvasScroll(tester);

      controller.controllers[0].value = TextEditingValue(
        text: 'سطر الاختبار الطويل ' * 400,
      );
      await tester.pump();
      await settleScroll(tester);
      expect(controller.document.blocks.length, greaterThan(1));

      final double offset = scroll.offset;
      // الوقوف على نصٍّ آخر (أو مغادرته) تغيير نشاطٍ فقط: لا ترقيم ولا حركة.
      controller.setActiveBlock(0);
      await tester.pump();
      await settleScroll(tester);
      expect(scroll.offset, offset);

      controller.setActiveBlock(controller.document.blocks.length - 1);
      await tester.pump();
      await settleScroll(tester);
      expect(scroll.offset, offset);
    });
  });
}
