import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/features/jood_writer/domain/flow_paginator.dart';
import 'package:joodcraft/features/jood_writer/domain/jood_writer_block.dart';
import 'package:joodcraft/features/jood_writer/domain/jood_writer_document.dart';

/// مُقاس ثابت حتمي: أسطر الكتلة هي ما قبل كل `\n` في نصّها، بارتفاع ثابت.
///
/// يفصل القياس عن التدفّق فيُختبر الفيض وحدود الصفحات بلا خطوط ولا واجهة.
class _FixedMeasurer implements BlockMeasurer {
  const _FixedMeasurer({
    this.lineHeight = 20,
    this.before = 0,
    this.after = 0,
  });

  final double lineHeight;
  final double before;
  final double after;

  @override
  List<String> linesOf(JoodWriterBlock block) =>
      block.text.isEmpty ? const <String>[''] : block.text.split('\n');

  @override
  double lineHeightOf(JoodWriterBlock block) => lineHeight;

  @override
  double spacingBeforeOf(JoodWriterBlock block) => before;

  @override
  double spacingAfterOf(JoodWriterBlock block) => after;
}

JoodWriterBlock _block(String text) => JoodWriterBlock(text: text);

void main() {
  group('FlowPaginator: توزيع الكتل على الصفحات', () {
    test('كتل تتّسع كلها ⇒ صفحة واحدة بكل الكتل بترتيبها', () {
      final List<JoodPage> pages = FlowPaginator.paginate(
        blocks: <JoodWriterBlock>[_block('أ'), _block('ب'), _block('ج')],
        contentHeight: 100,
        measurer: const _FixedMeasurer(),
      );
      expect(pages, hasLength(1));
      expect(
        pages.first.slices.map((JoodPageSlice s) => s.blockIndex),
        <int>[0, 1, 2],
      );
    });

    test('فيض كتلة طويلة ⇒ شطرها على صفحتين بلا فقد سطر', () {
      // كتلة ٤ أسطر بعد كتلة ٣ أسطر، والسعة 5 أسطر/صفحة:
      // الصفحة 1: A(3) + B(2)، والصفحة 2: B(2).
      final List<JoodPage> pages = FlowPaginator.paginate(
        blocks: <JoodWriterBlock>[
          _block('a1\na2\na3'),
          _block('b1\nb2\nb3\nb4'),
        ],
        contentHeight: 100,
        measurer: const _FixedMeasurer(lineHeight: 20),
      );
      expect(pages, hasLength(2));

      final JoodPage first = pages[0];
      expect(first.slices, hasLength(2));
      expect(first.slices[0].blockIndex, 0);
      expect((first.slices[0].lineStart, first.slices[0].lineEnd), (0, 3));
      expect(first.slices[1].blockIndex, 1);
      expect((first.slices[1].lineStart, first.slices[1].lineEnd), (0, 2));

      final JoodPage second = pages[1];
      expect(second.slices, hasLength(1));
      expect((second.slices[0].lineStart, second.slices[0].lineEnd), (2, 4));
      expect(second.slices[0].isBlockEnd, isTrue);
    });

    test('كل الأسطر تُغطّى مرة واحدة بالضبط وبترتيبها', () {
      final List<JoodWriterBlock> blocks = <JoodWriterBlock>[
        _block('h1'),
        _block(List<String>.generate(7, (int i) => 'p$i').join('\n')),
        _block(List<String>.generate(13, (int i) => 'q$i').join('\n')),
        _block('tail'),
      ];
      final List<JoodPage> pages = FlowPaginator.paginate(
        blocks: blocks,
        contentHeight: 90,
        measurer: const _FixedMeasurer(lineHeight: 20),
      );

      // اجمع الأسطر كما ظهرت على الصفحات وطابقها مع المصدر.
      final List<String> rendered = <String>[];
      for (final JoodPage page in pages) {
        for (final JoodPageSlice slice in page.slices) {
          final List<String> lines = slice.block.text.split('\n');
          for (int i = slice.lineStart; i < slice.lineEnd; i++) {
            rendered.add('${slice.blockIndex}:$i:${lines[i]}');
          }
        }
      }

      final List<String> expected = <String>[];
      for (int b = 0; b < blocks.length; b++) {
        final List<String> lines = blocks[b].text.split('\n');
        for (int i = 0; i < lines.length; i++) {
          expected.add('$b:$i:${lines[i]}');
        }
      }
      expect(rendered, expected, reason: 'لا سطر مفقود ولا مكرّر ولا مُعاد ترتيبه');
    });

    test('المسافة قبل الكتلة تُهمَل في رأس الصفحة', () {
      final List<JoodPage> pages = FlowPaginator.paginate(
        blocks: <JoodWriterBlock>[_block('a'), _block('b')],
        contentHeight: 100,
        measurer: const _FixedMeasurer(lineHeight: 20, before: 100),
      );
      // A على الصفحة الأولى بلا مسافة قبلها، ثم المسافة الكبيرة تدفع B لصفحة جديدة.
      expect(pages, hasLength(2));
      expect(pages[0].slices.single.blockIndex, 0);
      expect(pages[1].slices.single.blockIndex, 1);
    });

    test('ارتفاع أصغر من سطر واحد لا يُدخل في حلقة لا نهائية', () {
      final List<JoodPage> pages = FlowPaginator.paginate(
        blocks: <JoodWriterBlock>[_block('x1\nx2\nx3')],
        contentHeight: 5,
        measurer: const _FixedMeasurer(lineHeight: 20),
      );
      expect(pages, hasLength(3), reason: 'سطر واحد لكل صفحة عند ضيق شديد');
      for (int i = 0; i < pages.length; i++) {
        expect(pages[i].slices.single.lineStart, i);
        expect(pages[i].slices.single.lineEnd, i + 1);
      }
    });

    test('مستند بلا كتل ⇒ صفحة واحدة فارغة', () {
      final List<JoodPage> pages = FlowPaginator.paginate(
        blocks: const <JoodWriterBlock>[],
        contentHeight: 100,
        measurer: const _FixedMeasurer(),
      );
      expect(pages, hasLength(1));
      expect(pages.first.isEmpty, isTrue);
    });

    test('المسافة بعد الكتلة تُخصم من السعة', () {
      // كتلتان بسطر واحد، وبعد كل كتلة 90 ⇒ سطر + 90 > 100 فينزل الثاني.
      final List<JoodPage> pages = FlowPaginator.paginate(
        blocks: <JoodWriterBlock>[_block('a'), _block('b')],
        contentHeight: 100,
        measurer: const _FixedMeasurer(lineHeight: 20, after: 90),
      );
      expect(pages, hasLength(2));
    });
  });

  group('JoodWriterBlock: الحفظ والقراءة', () {
    test('دورة JSON كاملة تحفظ النص والنوع والمحاذاة', () {
      const JoodWriterBlock block = JoodWriterBlock(
        text: 'عنوان',
        kind: JoodWriterBlockKind.heading2,
        align: JoodWriterAlign.center,
      );
      final JoodWriterBlock restored =
          JoodWriterBlock.fromJson(block.toJson());
      expect(restored.text, 'عنوان');
      expect(restored.kind, JoodWriterBlockKind.heading2);
      expect(restored.align, JoodWriterAlign.center);
    });

    test('قيم مجهولة ترجع للافتراضي (فقرة/بداية)', () {
      final JoodWriterBlock restored = JoodWriterBlock.fromJson(
        <String, dynamic>{'text': 'x', 'kind': '???', 'align': '???'},
      );
      expect(restored.kind, JoodWriterBlockKind.paragraph);
      expect(restored.align, JoodWriterAlign.start);
    });

    test('قائمة الكتل: ترميز وفك ترميز مع تجاهل المدخلات التالفة', () {
      final String encoded = JoodWriterBlock.encodeList(<JoodWriterBlock>[
        _block('one'),
        const JoodWriterBlock(
          text: 'two',
          kind: JoodWriterBlockKind.bullet,
        ),
      ]);
      final List<JoodWriterBlock> decoded = JoodWriterBlock.decodeList(encoded);
      expect(decoded, hasLength(2));
      expect(decoded[1].kind, JoodWriterBlockKind.bullet);
      expect(JoodWriterBlock.decodeList('ليس JSON'), isEmpty);
      expect(JoodWriterBlock.decodeList(null), isEmpty);
    });
  });

  group('JoodWriterDocument', () {
    test('مقاس A4 والهوامش تُعطي ارتفاع محتوى صحيحاً', () {
      const JoodWriterDocument doc = JoodWriterDocument(
        title: 't',
        blocks: <JoodWriterBlock>[],
      );
      expect(doc.pageSize, JoodWriterPageSize.a4);
      // 297 − 25 − 25 = 247
      expect(doc.margins.contentHeightMm(doc.pageSize), closeTo(247, 0.001));
      // 210 − 20 − 20 = 170
      expect(doc.margins.contentWidthMm(doc.pageSize), closeTo(170, 0.001));
    });

    test('المستند الفارغ يحمل فقرة واحدة قابلة للكتابة', () {
      final JoodWriterDocument doc = JoodWriterDocument.empty();
      expect(doc.blocks, hasLength(1));
      expect(doc.blocks.single.kind, JoodWriterBlockKind.paragraph);
    });

    test('المستند النموذجي يتجاوز كتلة واحدة ويحمل عناوين ونقاطاً', () {
      final JoodWriterDocument doc = JoodWriterDocument.sample();
      expect(doc.blocks.length, greaterThan(3));
      expect(
        doc.blocks.any(
          (JoodWriterBlock b) => b.kind == JoodWriterBlockKind.bullet,
        ),
        isTrue,
      );
    });

    test('دورة JSON للمستند تحفظ الكتل', () {
      final JoodWriterDocument doc = JoodWriterDocument.sample();
      final JoodWriterDocument restored =
          JoodWriterDocument.fromJson(doc.toJson());
      expect(restored.title, doc.title);
      expect(restored.blocks.length, doc.blocks.length);
      expect(restored.blocks.first.kind, doc.blocks.first.kind);
    });
  });
}
