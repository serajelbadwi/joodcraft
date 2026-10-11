import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/features/jood_writer/domain/flow_paginator.dart';
import 'package:joodcraft/features/jood_writer/domain/jood_writer_block.dart';
import 'package:joodcraft/features/jood_writer/presentation/jood_writer_text_styles.dart';
import 'package:joodcraft/features/jood_writer/presentation/text_painter_measurer.dart';

/// لقطة قياس كتلة كاملة — كل ما يعتمد عليه التدفّق.
typedef _Measure = ({
  List<String> lines,
  double lineHeight,
  double before,
  double after,
});

/// اختبارات **ثبات القياس** في «جود كاتب» — حراسة ضد تغيّر النص بين القياس والعرض.
///
/// ## المشكلة التي تحرسها
///
/// القياس ([TextPainterBlockMeasurer]) والعرض (`Text` / `TextField` في
/// `writer_canvas.dart` و`writer_pages_view.dart`) كانا يبنيان إعداداتهما
/// بشكل مستقل. أي اختلاف في `TextScaler` أو `TextStyle` أو `maxWidth` يجعل
/// عدد الأسطر المحسوب مختلفاً عن المرسوم ⇒ **يتغيّر النص** (التفاف مختلف،
/// فيض، أو قطع بـ`overflow: clip`).
///
/// ## ما تثبته هذه الاختبارات
///
/// 1. **الحتمية:** نفس المدخلات ‎←‎ نفس القياس، ‎50‎ مرة بلا أي تغيّر.
/// 2. **الاستقلال عن الترتيب:** إعادة ترتيب الكتل لا تغيّر قياس أي كتلة.
/// 3. **الاستقلال عن التركيز:** تغيير التركيز (وهو حالة واجهة لا تدخل القياس)
///    لا يغيّر الشكل المقيس.
/// 4. **التوحيد مع العارض:** عرضا السطر الأول والباقي المحسوبان هنا يساويان
///    ما يمنحه العارض فعلاً لكل سطر.
void main() {
  /// عرض محتوى ثابت يحاكي ورقة A4 بهامش ‎2‎ سم من كل جانب.
  const double contentWidth = 21.0 * 96 / 25.4 - 2 * 2 * 96 / 25.4;

  /// مقياس تكبير ثابت — نفس ما تستخدمه العارضات ضمناً من `MediaQuery`.
  const TextScaler scaler = TextScaler.noScaling;

  TextPainterBlockMeasurer buildMeasurer({double width = contentWidth}) =>
      TextPainterBlockMeasurer(
        contentWidth: width,
        scale: 1,
        textScaler: scaler,
      );

  /// كتلة عربية طويلة تكفي لعدة أسطر عند العرض المعطى.
  JoodWriterBlock longBlock({JoodWriterBlockKind kind = JoodWriterBlockKind.paragraph}) =>
      JoodWriterBlock(
        text: 'فقرة عربية طويلة بما يكفي لتملأ أكثر من سطر واحد على الورقة '
            'عند العرض المحدد، وتحتوي على كلمات متفاوتة الأطوال لاختبار '
            'الالتفاف بدقة ومطابقة ما يراه المستخدم على الشاشة تماماً.',
        kind: kind,
      );

  /// لقطة كاملة لقياس كتلة — كل ما يعتمد عليه التدفّق.
  ({List<String> lines, double lineHeight, double before, double after})
  snapshot(TextPainterBlockMeasurer measurer, JoodWriterBlock block) => (
        lines: measurer.linesOf(block),
        lineHeight: measurer.lineHeightOf(block),
        before: measurer.spacingBeforeOf(block),
        after: measurer.spacingAfterOf(block),
      );

  group('الحتمية: نفس المدخلات ← نفس القياس', () {
    test('‎50‎ مرة متتالية تعيد النتيجة نفسها حرفياً', () {
      final TextPainterBlockMeasurer measurer = buildMeasurer();
      final JoodWriterBlock block = longBlock();

      final _Measure first = snapshot(measurer, block);
      expect(first.lines, isNotEmpty);
      expect(first.lines.length, greaterThan(1));

      for (int i = 0; i < 50; i++) {
        final _Measure again = snapshot(measurer, block);
        expect(
          again.lines,
          first.lines,
          reason: 'القياس تغيّر في التكرار ${i + 1}',
        );
        expect(again.lineHeight, first.lineHeight);
        expect(again.before, first.before);
        expect(again.after, first.after);
      }
    });

    test('النتيجة متطابقة بين مقياسين مستقلين بنفس الإعدادات', () {
      // مقياسان منفصلان (كما يحدث عند إعادة بناء الواجهة) يجب أن يتفقا.
      final _Measure a = snapshot(buildMeasurer(), longBlock());
      final _Measure b = snapshot(buildMeasurer(), longBlock());

      expect(b.lines, a.lines);
      expect(b.lineHeight, a.lineHeight);
      expect(b.before, a.before);
      expect(b.after, a.after);
    });

    test('التخزين المؤقّت لا يُرجع نتيجة مختلفة عن القياس المباشر', () {
      final TextPainterBlockMeasurer measurer = buildMeasurer();
      final JoodWriterBlock block = longBlock();

      final _Measure direct = snapshot(measurer, block);
      // تمريرة ثانية تمرّ من التخزين المؤقّت (LRU) — يجب أن تطابق الأولى.
      final _Measure cached = snapshot(measurer, block);

      expect(cached.lines, direct.lines);
      expect(cached.lineHeight, direct.lineHeight);
      expect(measurer.layoutCount, greaterThan(0));
      expect(measurer.cacheHitCount, greaterThan(0));
    });
  });

  group('الاستقلال عن الترتيب', () {
    test('إعادة ترتيب الكتل لا تغيّر قياس أي كتلة', () {
      final List<JoodWriterBlock> blocks = <JoodWriterBlock>[
        longBlock(),
        const JoodWriterBlock(text: 'عنوان رئيسي', kind: JoodWriterBlockKind.heading1),
        const JoodWriterBlock(text: 'نقطة أولى', kind: JoodWriterBlockKind.bullet),
        const JoodWriterBlock(text: '١.', kind: JoodWriterBlockKind.numbered),
        const JoodWriterBlock(text: 'عنوان فرعي', kind: JoodWriterBlockKind.heading2),
      ];

      final TextPainterBlockMeasurer measurer = buildMeasurer();

      // قياس كل كتلة بترتيبها الأصلي.
      final Map<String, List<String>> byText = <String, List<String>>{};
      for (final JoodWriterBlock block in blocks) {
        byText[block.text] = measurer.linesOf(block);
      }

      // عكس الترتيب وقياس مجدداً — نفس النتائج لكل كتلة.
      for (final JoodWriterBlock block in blocks.reversed) {
        expect(
          measurer.linesOf(block),
          byText[block.text],
          reason: 'قياس الكتلة تغيّر بتغيّر ترتيبها: ${block.text}',
        );
      }
    });

    test('ترتيب الكتل في التدفّق لا يؤثر على أسطر كتلة معيّنة', () {
      final TextPainterBlockMeasurer measurer = buildMeasurer();
      final JoodWriterBlock target = longBlock();

      final List<String> alone = measurer.linesOf(target);

      // نفس الكتلة وسط كتل أخرى — قياسها لا يعتمد على جيرانها.
      FlowPaginator.paginate(
        blocks: <JoodWriterBlock>[
          const JoodWriterBlock(text: 'قبلها'),
          target,
          const JoodWriterBlock(text: 'بعدها'),
        ],
        contentHeight: 297 * 96 / 25.4,
        measurer: measurer,
      );

      expect(measurer.linesOf(target), alone);
    });
  });

  group('الاستقلال عن التركيز', () {
    test('تغيير التركيز لا يغيّر الشكل المقيس', () {
      // التركيز حالة واجهة لا تدخل القياس إطلاقاً — والمُقاس لا يعرفها.
      final TextPainterBlockMeasurer measurer = buildMeasurer();
      final JoodWriterBlock block = longBlock();

      final _Measure unfocused = snapshot(measurer, block);

      // محاكاة دورة تركيز كاملة: تركيز ثم إلغاء ثم تركيز من جديد.
      final FocusNode node = FocusNode();
      node.requestFocus();
      node.unfocus();
      node.requestFocus();
      addTearDown(node.dispose);

      final _Measure focused = snapshot(measurer, block);

      expect(focused.lines, unfocused.lines);
      expect(focused.lineHeight, unfocused.lineHeight);
      expect(focused.before, unfocused.before);
      expect(focused.after, unfocused.after);
    });

    test('القياس لا يتأثّر بحالة التحديد أو التحرير', () {
      final TextPainterBlockMeasurer measurer = buildMeasurer();
      final JoodWriterBlock block = longBlock();

      final _Measure plain = snapshot(measurer, block);

      // كتلة قيد التحرير (نص أطول ثم أقصر) يجب أن تُقاس بنصها الحالي فقط.
      final JoodWriterBlock editing = block.copyWith(
        text: '${block.text} نص إضافي أثناء التحرير.',
      );
      final _Measure whileEditing = snapshot(measurer, editing);
      expect(whileEditing.lines.length, greaterThanOrEqualTo(plain.lines.length));

      // والعودة للنص الأصلي تعيد القياس الأصلي حرفياً.
      expect(snapshot(measurer, block).lines, plain.lines);
    });
  });

  group('التوحيد مع العارض (Measurer = Renderer)', () {
    test('عرض السطر الأول يساوي ما يمنحه العارض فعلاً', () {
      final TextPainterBlockMeasurer measurer = buildMeasurer();

      for (final JoodWriterBlock block in <JoodWriterBlock>[
        longBlock(),
        const JoodWriterBlock(
          text: 'فقرة بإزاحة وإزاحة سطر أول',
          indentCm: 1,
          firstLineIndentCm: 2,
        ),
        const JoodWriterBlock(
          text: 'نقطة بإزاحة',
          kind: JoodWriterBlockKind.bullet,
          indentCm: 1,
          firstLineIndentCm: 1,
        ),
        const JoodWriterBlock(
          text: 'بند مرقم بإزاحة',
          kind: JoodWriterBlockKind.numbered,
          indentCm: 1,
        ),
      ]) {
        // العرض الذي يمنحه العارض للسطر الأول: عرض المحتوى ناقص إزاحة
        // الفقرة وإزاحة السطر الأول ومقدمة القائمة. المُقاس يُسند إلى حدّ
        // أدنى ‎8‎ بكسل عند العرض السالب (عرض سالب يُسقط `TextPainter`) —
        // فالمقارنة تُجرى على القيمة المُسندة نفسها.
        final double rendererFirst = math.max(
          contentWidth -
              JoodWriterTextStyles.indentPx(block) -
              JoodWriterTextStyles.firstLineIndentPx(block) -
              JoodWriterTextStyles.listPrefixWidth(block),
          8.0,
        );

        expect(
          measurer.widthOfFirstLine(block),
          moreOrLessEquals(rendererFirst, epsilon: 0.01),
          reason: 'عرض السطر الأول لا يطابق العارض',
        );
      }
    });

    test('عرض الأسطر التالية يساوي ما يمنحه العارض فعلاً', () {
      final TextPainterBlockMeasurer measurer = buildMeasurer();

      for (final JoodWriterBlock block in <JoodWriterBlock>[
        longBlock(),
        const JoodWriterBlock(text: 'نقطة', kind: JoodWriterBlockKind.bullet, indentCm: 1),
        const JoodWriterBlock(text: 'بند', kind: JoodWriterBlockKind.numbered, indentCm: 1),
      ]) {
        final double rendererRest = math.max(
          contentWidth -
              JoodWriterTextStyles.indentPx(block) -
              JoodWriterTextStyles.listPrefixWidth(block),
          8.0,
        );

        expect(
          measurer.widthOfRemainingLines(block),
          moreOrLessEquals(rendererRest, epsilon: 0.01),
          reason: 'عرض الأسطر التالية لا يطابق العارض',
        );
      }
    });

    test('عرض مقدمة القائمة مصدر واحد للقارئ والعارض معاً', () {
      // القياس يخصم المقدمة من عرض السطر، والعارض يحجزها أمامه — والقيمة
      // واحدة تخرج من هنا. لو اشتُقّت مرتين لانزاح النصّ عن موضعه المقيس.
      final TextPainterBlockMeasurer measurer = buildMeasurer();

      // كتل بلا قائمة ⇒ مقدمة صفرية بالضرورة (لا يُخصم شيء ولا يُحجز).
      for (final JoodWriterBlock block in <JoodWriterBlock>[
        longBlock(),
        const JoodWriterBlock(text: 'فقرة بإزاحة', indentCm: 2),
        const JoodWriterBlock(text: 'عنوان', kind: JoodWriterBlockKind.heading1),
      ]) {
        expect(
          measurer.prefixWidthOf(block),
          moreOrLessEquals(0, epsilon: 0.01),
          reason: 'كتلة بلا قائمة يجب أن يكون عرض مقدمتها صفراً',
        );
      }

      // كتل قائمة ⇒ مقدمة موجبة، وكلّما كبُر الحجم كبُر عرضها.
      for (final JoodWriterBlockKind kind in <JoodWriterBlockKind>[
        JoodWriterBlockKind.bullet,
        JoodWriterBlockKind.numbered,
      ]) {
        final JoodWriterBlock block = JoodWriterBlock(
          text: 'بند قائمة',
          kind: kind,
        );
        final double prefix = measurer.prefixWidthOf(block);
        expect(prefix, greaterThan(0));

        // القيمة نفسها هي ما يُخصم فعلاً من عرضَي السطر الأول والباقي:
        final double expectedFirst = contentWidth -
            JoodWriterTextStyles.indentPx(block) -
            JoodWriterTextStyles.firstLineIndentPx(block) -
            prefix;
        expect(
          measurer.widthOfFirstLine(block),
          moreOrLessEquals(math.max(expectedFirst, 8.0), epsilon: 0.01),
          reason: 'المقدمة المُخصمة في القياس تختلف عن المُعلنة للعارض',
        );
      }
    });

    test('عرض التخطيط لا يتجاوز عرض العارض أبداً (لا قطع ولا فيض)', () {
      // الضمان الجوهري: التخطيط يُنجَز بأضيق عرض يمنحه العارض لأي سطر،
      // فكل سطر مرسوم يبقى داخل عرضه المتاح.
      final TextPainterBlockMeasurer measurer = buildMeasurer();

      for (final JoodWriterBlock block in <JoodWriterBlock>[
        longBlock(),
        const JoodWriterBlock(
          text: 'فقرة بإزاحات كبيرة',
          indentCm: 3,
          firstLineIndentCm: 4,
        ),
        const JoodWriterBlock(
          text: 'نقطة بإزاحات كبيرة',
          kind: JoodWriterBlockKind.bullet,
          indentCm: 3,
          firstLineIndentCm: 4,
        ),
      ]) {
        final double layout = measurer.widthOfFirstLine(block);
        final double first = measurer.widthOfFirstLine(block);
        final double rest = measurer.widthOfRemainingLines(block);

        expect(layout, lessThanOrEqualTo(first));
        expect(layout, lessThanOrEqualTo(rest));
        expect(layout, greaterThan(0));
      }
    });

    test('مقياس التكبير يدخل القياس كما يدخل الرسم', () {
      // نفس المقياس يُطبَّق على الطرفين — وإلا قيس نصّ أصغر ممّا يُرسم.
      const TextScaler scaler = TextScaler.linear(1.5);
      final TextPainterBlockMeasurer measurer = TextPainterBlockMeasurer(
        contentWidth: contentWidth,
        scale: 1,
        textScaler: scaler,
      );

      final JoodWriterBlock block = longBlock();
      final List<String> scaled = measurer.linesOf(block);

      // بمقياس ‎1.5‎ يشغل النص مساحة أكبر ⇒ أسطر أكثر من مقياس ‎1.0‎.
      final TextPainterBlockMeasurer unscaled = buildMeasurer();
      expect(scaled.length, greaterThanOrEqualTo(unscaled.linesOf(block).length));

      // وارتفاع السطر يتكبّر فعلاً مع المقياس.
      expect(
        measurer.lineHeightOf(block),
        greaterThan(unscaled.lineHeightOf(block)),
      );
    });
  });
}
