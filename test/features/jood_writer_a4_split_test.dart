import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/print/imposition_calculator.dart';
import 'package:joodcraft/core/print/writer_imposition.dart';
import 'package:joodcraft/features/jood_writer/domain/flow_paginator.dart';
import 'package:joodcraft/features/jood_writer/domain/jood_writer_block.dart';
import 'package:joodcraft/features/jood_writer/domain/jood_writer_document.dart';
import 'package:joodcraft/features/jood_writer/presentation/jood_writer_text_styles.dart';
import 'package:joodcraft/features/jood_writer/presentation/text_painter_measurer.dart';

/// اختبارات «تقسيم A4 → 2 × A5» في «جود كاتب».
///
/// 1. **مقاس صفحة المحرّر**: تفعيل الخيار يصغّر الصفحة إلى نصف A4 بالضبط.
/// 2. **تدفّق النصّ**: النصّ يتدفّق من الصفحة الأولى إلى الثانية عبر
///    [FlowPaginator] بلا أي تعديل في خوارزمية الترقيم.
/// 3. **تجمع ورقة الطباعة**: صفحتان على ورقة A4 واحدة (عبر [ImpositionCalculator]).
/// 4. **الحفظ**: الوضع يُخزَّن ويُقرأ من JSON.
void main() {
  // -------------------------------------------------------------------------
  //  1) مقاس صفحة المحرّر بعد التقسيم
  // -------------------------------------------------------------------------
  group('مقاس صفحة المحرّر بعد التقسيم', () {
    test('عادي: لا تقسيم', () {
      const JoodWriterDocument doc = JoodWriterDocument(title: 'ت', blocks: <JoodWriterBlock>[]);
      expect(doc.pageLayout, WriterPageLayout.single);
      expect(doc.editorPageSize.widthMm, closeTo(210, 0.001));
      expect(doc.editorPageSize.heightMm, closeTo(297, 0.001));
    });

    test('A4 → 2 × A5 طولي: النصفان فوق بعض (A5 أفقي)', () {
      const JoodWriterDocument doc = JoodWriterDocument(
        title: 'ت',
        blocks: <JoodWriterBlock>[],
        pageLayout: WriterPageLayout.twoUpPortrait,
      );

      final JoodWriterPageSize page = doc.editorPageSize;
      // الشقّ أفقي: العرض كما هو، الارتفاع نصفه.
      expect(page.widthMm, closeTo(210, 0.001));
      expect(page.heightMm, closeTo(148.5, 0.001));
    });

    test('A4 → 2 × A5 عرضي: النصفان جنب بعض (A5 رأسي)', () {
      const JoodWriterDocument doc = JoodWriterDocument(
        title: 'ت',
        blocks: <JoodWriterBlock>[],
        pageLayout: WriterPageLayout.twoUpLandscape,
      );

      final JoodWriterPageSize page = doc.editorPageSize;
      // الشقّ عمودي: الارتفاع كما هو، العرض نصفه.
      expect(page.widthMm, closeTo(105, 0.001));
      expect(page.heightMm, closeTo(297, 0.001));
    });

    test('نصفا الورقة يعيدانان مقاس A4 عند التجميع', () {
      for (final WriterPageLayout layout in WriterPageLayout.values) {
        if (!layout.splitsPage) continue;
        final JoodWriterPageSize half = JoodWriterPageSize.halfOf(
          JoodWriterPageSize.a4,
          layout,
        );
        // مساحة النصفحتين = مساحة A4 (لا فراغ ولا فيض).
        expect(
          half.widthMm * half.heightMm * 2,
          closeTo(JoodWriterPageSize.a4.widthMm * JoodWriterPageSize.a4.heightMm, 0.001),
        );
      }
    });

    test('الاتجاه الأفقي يُقلب النصف أيضاً', () {
      const JoodWriterDocument doc = JoodWriterDocument(
        title: 'ت',
        blocks: <JoodWriterBlock>[],
        pageLayout: WriterPageLayout.twoUpPortrait,
        orientation: WriterOrientation.landscape,
      );
      // A4 أفقي (297×210) ⇒ النصف 297×105.
      expect(doc.editorPageSize.widthMm, closeTo(297, 0.001));
      expect(doc.editorPageSize.heightMm, closeTo(105, 0.001));
    });
  });

  // -------------------------------------------------------------------------
  //  2) تدفّق النصّ بين النصفين
  // -------------------------------------------------------------------------
  group('تدفّق النصّ بين النصفين', () {
    test('نصّ طويل على A5 يولّد صفحات متعدّدة (1 → 2)', () {
      final double pxPerMm = JoodWriterTextStyles.pxPerMm;
      const JoodWriterPageSize a5Portrait = JoodWriterPageSize(
        widthMm: 105,
        heightMm: 297,
        label: 'A4½',
      );

      final String longText = List<String>.generate(
        200,
        (int i) => 'فقرة $i نصّ عربي طويل بما يكفي ليملأ سطراً كاملاً على الورقة.',
      ).join('\n');

      final TextPainterBlockMeasurer measurer = TextPainterBlockMeasurer(
        contentWidth: (a5Portrait.widthMm - 40) * pxPerMm,
      );

      final List<JoodPage> pages = FlowPaginator.paginate(
        blocks: <JoodWriterBlock>[JoodWriterBlock(text: longText)],
        contentHeight: (a5Portrait.heightMm - 50) * pxPerMm,
        measurer: measurer,
      );

      expect(pages.length, greaterThan(1), reason: 'النصّ يجب أن يتدفّق لعدة صفحات');

      // ولا سطر مفقود: مجموع المقاطع = أسطر المصدر.
      final List<String> rendered = <String>[];
      for (final JoodPage page in pages) {
        for (final JoodPageSlice slice in page.slices) {
          rendered.addAll(
            measurer.linesOf(slice.block).sublist(slice.lineStart, slice.lineEnd),
          );
        }
      }
      expect(rendered.join('\n'), measurer.linesOf(JoodWriterBlock(text: longText)).join('\n'));
    });

    test('صفحة A5 واحدة تتّسع لأقلّ من A4 (المقصود من التقسيم)', () {
      const JoodWriterDocument a4 = JoodWriterDocument(title: 'ت', blocks: <JoodWriterBlock>[]);
      const JoodWriterDocument split = JoodWriterDocument(
        title: 'ت',
        blocks: <JoodWriterBlock>[],
        pageLayout: WriterPageLayout.twoUpPortrait,
      );

      expect(
        split.editorPageSize.heightMm,
        lessThan(a4.editorPageSize.heightMm),
      );
      expect(
        split.editorPageSize.heightMm * 2,
        closeTo(a4.editorPageSize.heightMm, 0.001),
      );
    });
  });

  // -------------------------------------------------------------------------
  //  3) تجمع ورقة الطباعة
  // -------------------------------------------------------------------------
  group('تجميع ورقة الطباعة', () {
    test('طيّ أفقي: صفحتان فوق بعض على A4 رأسية', () {
      final WriterSheetLayout layout = WriterImposition.build(
        pageWidthMm: 210,
        pageHeightMm: 148.5,
        fold: WriterSplitFold.horizontal,
      );

      expect(layout.slotsPerSheet, 2);
      expect(layout.imposition.sheetLandscape, isFalse);
      expect(layout.imposition.columns, 1);
      expect(layout.imposition.rows, 2);
      // ولا تدوير: صفحة المحرّر تحفظ اتجاهها.
      expect(layout.imposition.rotated, isFalse);
    });

    test('طيّ عمودي: صفحتان جنب بعض على A4 رأسية', () {
      final WriterSheetLayout layout = WriterImposition.build(
        pageWidthMm: 105,
        pageHeightMm: 297,
        fold: WriterSplitFold.vertical,
      );

      expect(layout.slotsPerSheet, 2);
      // الورقة رأسية في الوضعين: 105×297 جانب بعض = 210×297 = A4 رأسية.
      expect(layout.imposition.sheetLandscape, isFalse);
      expect(layout.imposition.columns, 2);
      expect(layout.imposition.rows, 1);
      // ولا تدوير: صفحة المحرّر تحفظ اتجاهها.
      expect(layout.imposition.rotated, isFalse);
    });

    test('مواضع النسخ لا تتداخل ولا تفيض', () {
      final WriterSheetLayout layout = WriterImposition.build(
        pageWidthMm: 210,
        pageHeightMm: 148.5,
        fold: WriterSplitFold.horizontal,
      );

      // أول نسخة أعلى الورقة، والثانية تحتها بلا تداخل.
      expect(layout.imposition.placements[0].topMm, 0);
      expect(layout.imposition.placements[1].topMm, greaterThanOrEqualTo(148.5));

      // لا تجاوز لحدود الورقة (A4 = 210×297).
      expect(layout.imposition.maxRightMm, lessThanOrEqualTo(210.001));
      expect(layout.imposition.maxBottomMm, lessThanOrEqualTo(297.001));
    });

    test('عدد الأوراق المحسوب لعدد الصفحات', () {
      final WriterSheetLayout layout = WriterImposition.build(
        pageWidthMm: 210,
        pageHeightMm: 148.5,
        fold: WriterSplitFold.horizontal,
      );

      expect(layout.sheetsFor(1), 1);
      expect(layout.sheetsFor(2), 1);
      expect(layout.sheetsFor(3), 2);
      expect(layout.sheetsFor(4), 2);
      expect(layout.sheetsFor(200), 100);
    });

    test('موضع كل صفحة على ورقتها', () {
      final WriterSheetLayout layout = WriterImposition.build(
        pageWidthMm: 210,
        pageHeightMm: 148.5,
        fold: WriterSplitFold.horizontal,
      );

      expect(layout.sheetOf(0), 0);
      expect(layout.sheetOf(1), 0);
      expect(layout.sheetOf(2), 1);
      expect(layout.placementOf(0)!.index, 0);
      expect(layout.placementOf(1)!.index, 1);
      expect(layout.placementOf(2)!.index, 0, reason: 'صفحة جديدة ⇒ أول خلية');
    });
  });

  // -------------------------------------------------------------------------
  //  4) الحفظ والقراءة
  // -------------------------------------------------------------------------
  group('حفظ الوضع', () {
    test('copyWith يحفظ الوضع', () {
      const JoodWriterDocument base = JoodWriterDocument(
        title: 'ت',
        blocks: <JoodWriterBlock>[],
      );
      final JoodWriterDocument updated = base.copyWith(
        pageLayout: WriterPageLayout.twoUpPortrait,
      );
      expect(updated.pageLayout, WriterPageLayout.twoUpPortrait);

      // ويبقى كما هو عند نسخ بلا تغيير.
      expect(updated.copyWith(title: 'آخر').pageLayout, WriterPageLayout.twoUpPortrait);
    });

    test('toJson / fromJson يحفظان الوضع', () {
      const JoodWriterDocument doc = JoodWriterDocument(
        title: 'ت',
        blocks: <JoodWriterBlock>[],
        pageLayout: WriterPageLayout.twoUpLandscape,
      );

      final Map<String, dynamic> json = doc.toJson();
      expect(json['pageLayout'], 'twoUpLandscape');

      final JoodWriterDocument restored = JoodWriterDocument.fromJson(json);
      expect(restored.pageLayout, WriterPageLayout.twoUpLandscape);
    });

    test('مستند قديم بلا pageLayout يُقرأ عادياً', () {
      final JoodWriterDocument restored = JoodWriterDocument.fromJson(
        <String, dynamic>{
          'title': 'قديم',
          'blocks': <dynamic>[],
        },
      );
      expect(restored.pageLayout, WriterPageLayout.single);
    });

    test('قيمة غير معروفة تسقط للوضع العادي', () {
      expect(WriterPageLayout.fromJson('لا-شيء'), WriterPageLayout.single);
    });
  });
}
