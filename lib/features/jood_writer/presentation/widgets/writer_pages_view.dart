import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/flow_paginator.dart';
import '../../domain/jood_writer_block.dart';
import '../../domain/jood_writer_document.dart';
import '../jood_writer_text_styles.dart';
import '../text_painter_measurer.dart';
import '../writer_text_scale.dart';

/// معاينة صفحات مستند «جود كاتب»: يدفّق كتل المستند على صفحات A4 ويولّد صفحة
/// جديدة تلقائياً عند الفيض، فلا يفقد النص سطراً.
class JoodWriterPagesView extends StatelessWidget {
  const JoodWriterPagesView({
    super.key,
    required this.document,
    this.padding = const EdgeInsets.all(AppTheme.space16),
  });

  final JoodWriterDocument document;
  final EdgeInsets padding;

  /// كثافة بكسل مرجعية (96dpi): يبقى حجم الخط 1 عند العرض الطبيعي ويتصغّر مع
  /// تصغير الورقة على الشاشات الضيقة.
  static const double _referencePxPerMm = 96 / 25.4;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double available = math.max(
          120,
          constraints.maxWidth - padding.horizontal,
        );
        // «الحجم الحقيقي»: لا نصغّر الورقة عن مقاسها الورقي (96dpi) إلا حين
        // تكون الشاشة أضيق منها فعلاً.
        final double pxPerMm = math.min(
          _referencePxPerMm,
          available / document.pageSize.widthMm,
        );
        final double pageWidth = document.pageSize.widthMm * pxPerMm;
        final double pageHeight = document.pageSize.heightMm * pxPerMm;
        final double scale = pxPerMm / _referencePxPerMm;
        final double contentWidth =
            document.margins.contentWidthMm(document.pageSize) * pxPerMm;
        final double contentHeight =
            document.margins.contentHeightMm(document.pageSize) * pxPerMm;

        final TextPainterBlockMeasurer measurer = TextPainterBlockMeasurer(
          contentWidth: contentWidth,
          scale: scale,
          // نفس مقياس التكبير الذي تستخدمه ودجات النص أدناه ضمناً من
          // `MediaQuery` — ومن المصدر الوحيد ذاته (`context.writerTextScaler`)،
          // فتمريره صريحاً هنا هو ما يجعل القياس = العرض في هذا المسار أيضاً.
          textScaler: context.writerTextScaler,
        );
        final List<JoodPage> pages = FlowPaginator.paginate(
          blocks: document.blocks,
          contentHeight: contentHeight,
          measurer: measurer,
        );

        return ListView.separated(
          key: const ValueKey<String>('writer-pages'),
          padding: padding,
          itemCount: pages.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppTheme.space20),
          itemBuilder: (BuildContext context, int index) => Center(
            child: _pageCard(
              context,
              page: pages[index],
              pageNumber: index + 1,
              total: pages.length,
              pageWidth: pageWidth,
              pageHeight: pageHeight,
              pxPerMm: pxPerMm,
              contentHeight: contentHeight,
              scale: scale,
              measurer: measurer,
            ),
          ),
        );
      },
    );
  }

  Widget _pageCard(
    BuildContext context, {
    required JoodPage page,
    required int pageNumber,
    required int total,
    required double pageWidth,
    required double pageHeight,
    required double pxPerMm,
    required double contentHeight,
    required double scale,
    required BlockMeasurer measurer,
  }) {
    final JoodWriterMargins margins = document.margins;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          key: ValueKey<String>('writer-page-$pageNumber'),
          width: pageWidth,
          height: pageHeight,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(2),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          // الهوامش بالضبط كما حُسبت في التدفّق: مساحة المحتوى الفعلية =
          // (العرض − الهوامش) = contentWidth تماماً، فلا يفيض النص عن الورقة.
          padding: EdgeInsets.fromLTRB(
            margins.left * pxPerMm,
            margins.top * pxPerMm,
            margins.right * pxPerMm,
            margins.bottom * pxPerMm,
          ),
          child: ClipRect(
            child: SizedBox(
              height: contentHeight,
              width: double.infinity,
              child: _pageContent(page, measurer, scale),
            ),
          ),
        ),
        const SizedBox(height: AppTheme.space6),
        Text(
          'صفحة $pageNumber من $total',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _pageContent(JoodPage page, BlockMeasurer measurer, double scale) {
    final List<Widget> children = <Widget>[];

    for (final JoodPageSlice slice in page.slices) {
      // المسافة قبل الكتلة تُهمَل في رأس الصفحة، وتُضاف لِبقيّة الكتل.
      if (slice.isBlockStart && children.isNotEmpty) {
        children.add(SizedBox(height: measurer.spacingBeforeOf(slice.block)));
      }

      final List<String> lines = measurer.linesOf(slice.block);
      final TextStyle style = JoodWriterTextStyles.of(
        slice.block,
        scale: scale,
      );
      final TextAlign align = JoodWriterTextStyles.textAlign(slice.block.align);
      final bool isBullet = slice.block.kind == JoodWriterBlockKind.bullet;

      for (
        int line = slice.lineStart;
        line < slice.lineEnd && line < lines.length;
        line++
      ) {
        final bool first = line == 0;
        // المسافة البادئة للسطر الأول فقط — بنفس ما قاسه محرّك التدفّق.
        final double firstIndent = first
            ? JoodWriterTextStyles.firstLineIndentPx(slice.block, scale: scale)
            : 0.0;
        children.add(
          Padding(
            padding: EdgeInsets.only(right: firstIndent),
            child: isBullet
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (first) ...[
                        Text('•', style: style),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Padding(
                          // **هامش المؤشّر**: نفس ما يخصمه المحرّر من كل سطر
                          // يرسمه (caretMargin × scale) — فمربّع الالتفاف هنا
                          // = مربّعه على اللوحة = مربّع المحرّر بالضبط.
                          padding: EdgeInsets.only(
                            right: JoodWriterTextStyles.caretMargin * scale,
                          ),
                          child: Text(
                            lines[line],
                            style: style,
                            textAlign: align,
                            textDirection: TextDirection.rtl,
                            softWrap: false,
                            overflow: TextOverflow.clip,
                          ),
                        ),
                      ),
                    ],
                  )
                : Padding(
                    // هامش المؤشّر هنا أيضاً (لا مقدّمة أمامه فينضمّ للإزاحة).
                    padding: EdgeInsets.only(
                      right: JoodWriterTextStyles.caretMargin * scale,
                    ),
                    child: Text(
                      lines[line],
                      style: style,
                      textAlign: align,
                      textDirection: TextDirection.rtl,
                      // كل سطر مقيس مسبقاً ⇒ يمنع التفافاً ثانياً يُفسد الترقيم.
                      softWrap: false,
                      overflow: TextOverflow.clip,
                    ),
                  ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }
}
