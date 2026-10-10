import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import '../../domain/jood_writer_block.dart';
import '../../domain/jood_writer_document.dart';
import '../../domain/writer_shape.dart';
import '../../domain/flow_paginator.dart';
import '../jood_writer_text_styles.dart';
import '../text_painter_measurer.dart';
import '../writer_document_controller.dart';

/// محرّر «جود كاتب» بنظام صفحات A4 ثابتة الأبعاد.
///
/// يستخدم [FlowPaginator] لتوزيع الكتل على صفحات، وكل صفحة ترسم فقط
/// الأسطر المخصصة لها (Slices). الكتلة النشطة تُعرض كحقل إدخال قابل للتحرير
/// والباقي كنصوص ثابتة. عند تجاوز الكتلة للصفحة يتم تقسيمها تلقائياً.
class WriterCanvas extends StatefulWidget {
  const WriterCanvas({super.key, required this.controller});

  final WriterDocumentController controller;

  /// كثافة البكسل لكل مليمتر — مأخوذة من مصدر واحد لا تتغيّر إلا من هناك.
  static const double pxPerMm = JoodWriterTextStyles.pxPerMm;

  /// لون التحديد (Selection) ومؤشر الكتابة: أزرق ناعم شفاف جداً (20%)
  /// حتى يبقى النص واضحاً وقابلاً للقراءة أثناء التحديد.
  static final Color selectionBlue = Colors.blue.withValues(alpha: 0.2);

  /// مسافة الفاصل بين صفحتَي القائمة (ببكسل).
  static const double pageGap = 24;

  /// الحشو العلوي لقائمة الصفحات.
  static const double listTopPadding = 40;

  /// حشو مساحة العمل حول صفحتها.
  static const EdgeInsets canvasPadding = EdgeInsets.symmetric(
    horizontal: 20,
    vertical: listTopPadding,
  );

  @override
  State<WriterCanvas> createState() => _WriterCanvasState();
}

class _WriterCanvasState extends State<WriterCanvas> {
  WriterDocumentController get controller => widget.controller;

  final ScrollController _pagesScroll = ScrollController();

  /// حاجز من التداخل: لا يُعاد فحص الشطر أثناء تنفيذه.
  bool _isSplitting = false;

  /// معامل «الحجم الحقيقي» الأخير: 1 حين تتّسع النافذة للورقة، وأصغر منها
  /// حين تكون أضيق. الطلاء فقط هو الذي يُصغَّر — تخطيط الورقة يبقى A4.
  double _pageFit = 1.0;

  /// مقياس تكبير النص الفعّال من `MediaQuery` (تكبير النظام أو اليدوي)؛
  /// يُقرأ في كل إطار ويُمرَّر إلى المُقاس، فلا يُقاس النص أصغر ممّا يُرسم.
  TextScaler _textScaler = TextScaler.noScaling;

  /// آخر نسخة نصّية رأتها الطبقة الرسومية. الشطر الآلي مربوط بها لا بإشعارات
  /// المتحكّم عامّةً، فلا يُعاد الترقيم عند التنقّل/التكبير (انظر
  /// [_onControllerChanged]).
  int _lastSeenTextRevision = 0;

  @override
  void initState() {
    super.initState();
    controller.addListener(_onControllerChanged);
    controller.onEdited = _autoSplitIfNeeded;
  }

  @override
  void didUpdateWidget(covariant WriterCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      oldWidget.controller.onEdited = null;
      widget.controller.addListener(_onControllerChanged);
      widget.controller.onEdited = _autoSplitIfNeeded;
    }
  }

  @override
  void dispose() {
    if (identical(controller.onEdited, _autoSplitIfNeeded)) {
      controller.onEdited = null;
    }
    controller.removeListener(_onControllerChanged);
    _pagesScroll.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    // تفعيل التقسيم الآلي بعد كل تعديل نصّي **فحسْب**.
    //
    // ⚠️ كان يُستدعى عند **كل** `notifyListeners()` — بما فيها التنقّل بين
    // الكتل، تغيير التكبير، وتبديل وضع العرض. والشطر يُعيد ترقيم الصفحات،
    // وبطاقاتها مفتاحها `writer-page-<فهرس>`، فتُبنى البطاقة التي أمام
    // المستخدم من جديد بمحتوى صفحة أخرى ⇒ **يبدو أنّ نصف الكتابة اختفى**.
    // الآن: الشطر عند تغيّر النصّ فقط (يتتبّعه `textRevision`)، والتنقّل
    // والتكبير والعرض لا يُحرّكون شيئاً.
    final int revision = controller.textRevision;
    if (revision == _lastSeenTextRevision) return;
    _lastSeenTextRevision = revision;
    _autoSplitIfNeeded();
  }

  /// يقيس الكتلة النشطة ويقسمها إذا تجاوزت المساحة المتاحة في صفحتها.
  ///
  /// يُستدعى من **مستمع تغيير النص** في المتحكّم (`onEdited`) فور كتابة أي
  /// حرف، فيُقطَع النص الزائد وتُنشأ صفحة جديدة أسفلها **قبل** رسم الإطار،
  /// فلا يظهر خطأ `RenderFlex Overflow` أبداً.
  void _autoSplitIfNeeded() {
    if (_isSplitting) return;
    _isSplitting = true;
    try {
      // قد يتجاوز النص المساحة بعدة صفحات دفعةً واحدة (لصق طويل) ⇒
      // نشطر حتى يستقر التدفّق على صفحات كلها تتّسع لمحتواها.
      //
      // الحدّ الأقصى سقفٌ أماني لا هدفٌ: الحلقة تتوقّف من تلقاء نفسها حين
      // لم يبقَ كتلة متجاوزة (`_splitOnce` يُعيد null). كان 100 — وهو لا
      // يكفي لصق مئات الصفحات من Word فيتوقّف الشطر في منتصفه.
      int? lastSplitIndex;
      for (int guard = 0; guard < 2000; guard++) {
        final int? splitIndex = _splitOnce();
        if (splitIndex == null) break;
        lastSplitIndex = splitIndex;
      }
      // النص المنقول والمؤشر ينتقلان فوراً إلى صفحتهما الجديدة.
      if (lastSplitIndex != null) _scrollToBlockPage(lastSplitIndex);
    } finally {
      _isSplitting = false;
    }
  }

  /// موضع الحرف في النصّ الأصلي الذي يبدأ عنده السطر [lineEnd].
  ///
  /// `BlockMeasurer.linesOf` يعيد السطور **بلا** فواصلها (`getLineBoundary`
  /// يستثني '\n')، فالجمع المباشر للأطوال يمحو الفواصل الصريحة. هنا — بعد كل
  /// سطر مَرسوم — نتحقّق من النصّ الأصلي: إن وُجد '\n' فهو فاصل ذلك السطر
  /// فيتخطّاه المؤشر، وإلا فالانتقال التفافٌ طبيعي بلا فاصل.
  ///
  /// تبقى الفواصل في مواضعها بعد التقسيم ⇒ لا يضيع سطر ولا تُدمج الفقرات.
  static int _offsetAfterLine(String text, List<String> lines, int lineEnd) {
    int offset = 0;
    final int bounded = lineEnd > lines.length ? lines.length : lineEnd;
    for (int i = 0; i < bounded; i++) {
      offset += lines[i].length;
      while (offset < text.length && text[offset] == '\n') {
        offset++; // الفاصل الصريح يلي السطر مباشرةً.
      }
    }
    // حماية: موضع غير صالح يُرجِع حدّاً آمناً.
    if (offset < 0) return 0;
    if (offset > text.length) return text.length;
    return offset;
  }

  /// قسْم واحد إن وُجد كتلة متجاوزة لصفحتها، ويُعيد فهرس الكتلة المُنشأة
  /// أو `null` حين يستقر التدفّق.
  int? _splitOnce() {
    final doc = controller.document;
    final double pageWidth =
        doc.effectivePageSize.widthMm * WriterCanvas.pxPerMm;
    final double pageHeight =
        doc.effectivePageSize.heightMm * WriterCanvas.pxPerMm;
    final double marginT = doc.margins.top * WriterCanvas.pxPerMm;
    final double marginB = doc.margins.bottom * WriterCanvas.pxPerMm;
    final double marginL = doc.margins.left * WriterCanvas.pxPerMm;
    final double marginR = doc.margins.right * WriterCanvas.pxPerMm;
    final double contentWidth = pageWidth - marginL - marginR;
    final double contentHeight = pageHeight - marginT - marginB;

    final measurer = TextPainterBlockMeasurer(
      contentWidth: contentWidth,
      scale: 1.0,
      textScaler: _textScaler,
    );

    // حساب الصفحات
    final pages = FlowPaginator.paginate(
      blocks: doc.blocks,
      contentHeight: contentHeight,
      measurer: measurer,
    );

    // البحث عن كتلة مُقسّمة عبر صفحتين (الكتلة نفسها تظهر في أكثر من صفحة)
    // وإجراء عملية التقسيم الفعلية على مستوى الـ blocks
    for (int pageIdx = 0; pageIdx < pages.length; pageIdx++) {
      final page = pages[pageIdx];
      for (final slice in page.slices) {
        // إذا كانت هذه الشريحة لا تنتهي عند آخر سطر من الكتلة الأصلية
        // فهذا يعني أن هناك أسطر تجاوزت هذه الصفحة
        if (!slice.isBlockEnd && slice.isBlockStart) {
          // نحتاج لتقسيم هذه الكتلة عند lineEnd
          final block = slice.block;
          final lines = measurer.linesOf(block);
          if (slice.lineEnd < lines.length && slice.lineEnd > 0) {
            // حساب نقطة القطع في النص الأصلي.
            //
            // ⚠️ لم يكن يجوز `lines.sublist(...).join('')`: `getLineBoundary`
            // يعيد السطر **بلا** فاصل أسطره، فكان `.join('')` يمحو كل '\n'
            // صريحة في النصّ. أثر ذلك كارثي على لصق Word: آلاف الفقرات
            // المفصولة بـ'\n' كانت تُدمج في سطر واحد متّصل ⇒ عدد الأسطر
            // المَرسومة يهبط ⇒ الصفحات الزائدة **تختفي** فيبدو المستند
            // صفحةً واحدة. الصحيح: القصّ بموضع حرفيّ في النصّ الأصلي مع
            // حفظ الفاصل، فيبقى كل سطر صريح كما كتبه المستخدم.
            final int breakAt = _offsetAfterLine(block.text, lines, slice.lineEnd);
            final String textBefore = block.text.substring(0, breakAt);
            final String textAfter = block.text.substring(breakAt);

            if (textAfter.isNotEmpty && textBefore != block.text) {
              controller.splitBlockAt(slice.blockIndex, textBefore, textAfter);
              return slice.blockIndex + 1; // فهرس الكتلة الجديدة
            }
          }
        }
      }
    }
    return null;
  }

  /// يمرّر مساحة العمل إلى الصفحة التي تحمل الكتلة [blockIndex] بعد الشطر.
  void _scrollToBlockPage(int blockIndex) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_pagesScroll.hasClients) return;
      final doc = controller.document;
      final double pageHeight =
          doc.effectivePageSize.heightMm * WriterCanvas.pxPerMm;
      final double contentWidth =
          (doc.effectivePageSize.widthMm -
              doc.margins.left -
              doc.margins.right) *
          WriterCanvas.pxPerMm;
      final double contentHeight =
          (doc.effectivePageSize.heightMm -
              doc.margins.top -
              doc.margins.bottom) *
          WriterCanvas.pxPerMm;
      final pages = FlowPaginator.paginate(
        blocks: doc.blocks,
        contentHeight: contentHeight,
        measurer: TextPainterBlockMeasurer(
          contentWidth: contentWidth,
          scale: 1.0,
          textScaler: _textScaler,
        ),
      );
      int pageIndex = pages.indexWhere(
        (page) => page.slices.any((slice) => slice.blockIndex == blockIndex),
      );
      if (pageIndex < 0) pageIndex = pages.length - 1;

      // طي الكتاب: الصفّ يضم صفحتين متقابلتين ⇒ الهدف هو صفّ الصفحة لا
      // موضع صفحتها وحدها.
      final bool spread = controller.viewMode == WriterViewMode.spread;
      final int row = spread ? pageIndex ~/ 2 : pageIndex;
      final double target =
          (WriterCanvas.listTopPadding +
                  row *
                      (pageHeight * _pageFit * controller.zoomLevel +
                          WriterCanvas.pageGap))
              .clamp(0.0, _pagesScroll.position.maxScrollExtent);
      _pagesScroll.animateTo(
        target,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // لون التحديد: أزرق ناعم شفاف (20%) — يظل النص واضحاً وقابلاً للقراءة
    // أثناء تحديد النص، ومقابض التحكم أزرق ممتلئ ليبقى واضحاً.
    final ThemeData themed = Theme.of(context).copyWith(
      textSelectionTheme: TextSelectionThemeData(
        selectionColor: WriterCanvas.selectionBlue,
        selectionHandleColor: Colors.blue,
      ),
    );
    return Theme(
      data: themed,
      child: Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final doc = controller.document;
            final double pageWidth =
                doc.effectivePageSize.widthMm * WriterCanvas.pxPerMm;
            final double pageHeight =
                doc.effectivePageSize.heightMm * WriterCanvas.pxPerMm;
            final double marginT = doc.margins.top * WriterCanvas.pxPerMm;
            final double marginB = doc.margins.bottom * WriterCanvas.pxPerMm;
            final double marginL = doc.margins.left * WriterCanvas.pxPerMm;
            final double marginR = doc.margins.right * WriterCanvas.pxPerMm;
            final double contentWidth = pageWidth - marginL - marginR;
            final double contentHeight = pageHeight - marginT - marginB;

            // مقياس تكبير النص الفعّال في هذا الإطار: نفس ما يُطبَّق على
            // الرسم، فيقيس المحرّر ما يُرسم بالضبط (لا فيض مهما كبّر المستخدم).
            _textScaler = MediaQuery.textScalerOf(context);

            final measurer = TextPainterBlockMeasurer(
              contentWidth: contentWidth,
              scale: 1.0,
              textScaler: _textScaler,
            );

            final List<JoodPage> pages = FlowPaginator.paginate(
              blocks: doc.blocks,
              contentHeight: contentHeight,
              measurer: measurer,
            );

            // «الحجم الحقيقي»: الورقة تُرسم بمقاسها الورقي الفعلي (96dpi)، ولا
            // تُصغَّر إلا حين تكون مساحة العمل أضيق منها — وبقياسٍ على الطلاء
            // فقط، فيبقى تخطيط الورقة وقياسها A4 تماماً فلا يختلف التفاف النص
            // عن القياس أبداً.
            return LayoutBuilder(
              builder: (context, constraints) {
                // طي الكتاب: صفحتان متقابلتان في الصف ⇒ مقاسهما المشترك هو
                // المحدِّد لمعامل التصغير.
                final bool spread =
                    controller.viewMode == WriterViewMode.spread;
                final double pagesPerRow = spread ? 2.0 : 1.0;
                final double fit = constraints.hasBoundedWidth
                    ? math.min(
                        1.0,
                        (constraints.maxWidth -
                                WriterCanvas.canvasPadding.horizontal -
                                (spread ? WriterCanvas.pageGap : 0)) /
                            (pageWidth * pagesPerRow),
                      )
                    : 1.0;
                _pageFit = fit;

                // بطاقة صفحة واحدة بمقاسها الورقي الحقيقي: تُخطَّط A4 تماماً
                // ثم تُطلَى بالمعامل — تُستعمل في الوضع المفرد وطي الكتاب.
                Widget pageCard(int index) {
                  return SizedBox(
                    width: pageWidth * fit,
                    height: pageHeight * fit,
                    child: OverflowBox(
                      minWidth: pageWidth,
                      maxWidth: pageWidth,
                      minHeight: pageHeight,
                      maxHeight: pageHeight,
                      alignment: Alignment.topCenter,
                      child: Transform.scale(
                        scale: fit * controller.zoomLevel,
                        alignment: Alignment.topCenter,
                        child: _PageCard(
                          key: ValueKey<String>('writer-page-${index + 1}'),
                          controller: controller,
                          doc: doc,
                          page: pages[index],
                          pageNum: index + 1,
                          totalPages: pages.length,
                          pageWidth: pageWidth,
                          pageHeight: pageHeight,
                          marginT: marginT,
                          marginB: marginB,
                          marginL: marginL,
                          marginR: marginR,
                          contentHeight: contentHeight,
                          measurer: measurer,
                        ),
                      ),
                    ),
                  );
                }

                return Listener(
                  onPointerSignal: (event) {
                    if (event is PointerScrollEvent) {
                      final keys = HardwareKeyboard.instance.logicalKeysPressed;
                      if (keys.contains(LogicalKeyboardKey.altLeft) ||
                          keys.contains(LogicalKeyboardKey.altRight) ||
                          keys.contains(LogicalKeyboardKey.controlLeft)) {
                        final double scrollDelta = event.scrollDelta.dy;
                        if (scrollDelta > 0) {
                          controller.zoomOut();
                        } else if (scrollDelta < 0) {
                          controller.zoomIn();
                        }
                      }
                    }
                  },
                  child: ListView.separated(
                    controller: _pagesScroll,
                    padding: WriterCanvas.canvasPadding,
                    // طي الكتاب: صفّ واحد يحمل صفحتين متقابلتين (الفردية يميناً
                    // في الاتجاه العربي، والزوجية إلى يسارها كالكتاب المطبوع).
                    itemCount: spread ? (pages.length + 1) ~/ 2 : pages.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: WriterCanvas.pageGap),
                    itemBuilder: (context, index) {
                      if (!spread) {
                        return Center(child: pageCard(index));
                      }
                      final int rightIndex = index * 2;
                      final int leftIndex = rightIndex + 1;
                      return Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          // «جود كاتب» عربيّ-first: الصفحة الفردية يمين والزوجية
                          // إلى يسارها كالكتاب المطبوع، بلا اعتماد على اتجاه
                          // الواجهة المحيطة (كما تُرسم الأسطر بـrtl صراحةً).
                          textDirection: TextDirection.rtl,
                          children: [
                            pageCard(rightIndex),
                            const SizedBox(width: WriterCanvas.pageGap),
                            if (leftIndex < pages.length)
                              pageCard(leftIndex)
                            else
                              // عدد الصفحات فردي: فراغ بمقدار الورقة يحفظ
                              // توازن الصفّ المتقابل.
                              SizedBox(
                                width: pageWidth * fit,
                                height: pageHeight * fit,
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// بطاقة صفحة A4 واحدة ثابتة الأبعاد.
class _PageCard extends StatelessWidget {
  const _PageCard({
    super.key,
    required this.controller,
    required this.doc,
    required this.page,
    required this.pageNum,
    required this.totalPages,
    required this.pageWidth,
    required this.pageHeight,
    required this.marginT,
    required this.marginB,
    required this.marginL,
    required this.marginR,
    required this.contentHeight,
    required this.measurer,
  });

  final WriterDocumentController controller;
  final JoodWriterDocument doc;
  final JoodPage page;
  final int pageNum;
  final int totalPages;
  final double pageWidth;
  final double pageHeight;
  final double marginT;
  final double marginB;
  final double marginL;
  final double marginR;
  final double contentHeight;
  final TextPainterBlockMeasurer measurer;

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = [];
    final double contentWidth = pageWidth - marginL - marginR;

    for (final slice in page.slices) {
      // مسافة قبل الكتلة (تُهمَل في رأس الصفحة)
      if (slice.isBlockStart && children.isNotEmpty) {
        children.add(SizedBox(height: slice.block.spaceBefore));
      }

      final int blockIndex = slice.blockIndex;
      final bool isActiveBlock = controller.activeBlockIndex == blockIndex;

      if (isActiveBlock && slice.isBlockStart) {
        // الكتلة النشطة: حقل إدخال قابل للتحرير
        children.add(
          _BlockEditor(
            index: blockIndex,
            block: slice.block,
            controller: controller,
          ),
        );
      } else {
        // كتلة غير نشطة أو شريحة مكملة: نص ثابت قابل للنقر
        final lines = measurer.linesOf(slice.block);
        final style = JoodWriterTextStyles.of(slice.block);
        final align = JoodWriterTextStyles.textAlign(slice.block.align);
        final isBullet = slice.block.kind == JoodWriterBlockKind.bullet;

        for (
          int line = slice.lineStart;
          line < slice.lineEnd && line < lines.length;
          line++
        ) {
          final bool isFirst = line == 0;
          // المسافة البادئة للسطر **الأول فقط**؛ بقية الأسطر على حافة الهامش.
          final double firstIndent = isFirst
              ? JoodWriterTextStyles.firstLineIndentPx(slice.block)
              : 0.0;

          final Widget lineText = isBullet
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isFirst) ...[
                      Text('•', style: style),
                      const SizedBox(width: 4),
                    ],
                    Expanded(
                      child: Text(
                        lines[line],
                        style: style,
                        textAlign: align,
                        textDirection: TextDirection.rtl,
                        softWrap: false,
                        overflow: TextOverflow.clip,
                      ),
                    ),
                  ],
                )
              : Text(
                  lines[line],
                  style: style,
                  textAlign: align,
                  textDirection: TextDirection.rtl,
                  softWrap: false,
                  overflow: TextOverflow.clip,
                );

          children.add(
            GestureDetector(
              onTap: () {
                controller.setActiveBlock(blockIndex);
                if (blockIndex < controller.focusNodes.length) {
                  controller.focusNodes[blockIndex].requestFocus();
                }
              },
              child: Padding(
                padding: EdgeInsets.only(
                  right:
                      slice.block.indentCm * 10 * WriterCanvas.pxPerMm +
                      firstIndent,
                ),
                child: lineText,
              ),
            ),
          );
        }
      }
    }

    return Container(
      width: pageWidth,
      height: pageHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // المحتوى: صندوق محتوى بمقياس الصفحة تماماً، **مقتصّ** فلا يُرسم
          // شيء خارجه أبداً، وبداخله `OverflowBox` يمنح العمود ارتفاعاً غير
          // محدود — فيُخطَّط العمود بمدى محتواه فلا يُبلَّغ `RenderFlex`
          // فيضاً (ولا شريط أصفر/أسود) مهما طال النص ولو لِحظة واحدة أثناء
          // القياس. والشطر الآلي هو وحده الذي يقتطع الأسطر الزائدة.
          Padding(
            padding: EdgeInsets.fromLTRB(marginL, marginT, marginR, marginB),
            child: SizedBox(
              width: contentWidth,
              height: contentHeight,
              child: ClipRect(
                child: OverflowBox(
                  minWidth: contentWidth,
                  maxWidth: contentWidth,
                  minHeight: 0,
                  maxHeight: double.infinity,
                  alignment: Alignment.topCenter,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: children,
                  ),
                ),
              ),
            ),
          ),

          // ترقيم الصفحات الذكي: يظهر إذا كان مفعّلاً، مع احترام الصفحات
          // المستثناة، وبنمط وحجم ولون ومحاذاة كما اختارها المستخدم.
          Positioned(
            bottom: marginB / 3,
            left: marginL,
            right: marginR,
            child: _PageNumberFooter(
              key: ValueKey<String>('writer-page-number-$pageNum'),
              numbering: doc.pageNumbering,
              pageIndex: pageNum - 1,
              totalPages: totalPages,
            ),
          ),

          // فاصل صفحات يدوي: خط منقّط خفيف في هامش الصفحة العليا يدل على أن
          // هذه الصفحة بدأت بفاصل يدوي — يُرسم في الهامش لا في المحتوى فلا
          // يستهلك من ارتفاعه شيئاً.
          if (pageNum > 1 &&
              page.slices.isNotEmpty &&
              page.slices.first.isBlockStart &&
              page.slices.first.block.pageBreakBefore)
            Positioned(
              top: marginT / 2 - 1,
              left: marginL,
              right: marginR,
              child: _PageBreakMarker(
                key: ValueKey<String>('writer-page-break-marker-$pageNum'),
              ),
            ),

          // الأشكال (إن وُجدت)
          ...doc.shapes.asMap().entries.map(
            (e) => _ShapeOverlay(
              shape: e.value,
              index: e.key,
              pxPerMm: WriterCanvas.pxPerMm,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ترقيم الصفحات الذكي
// ─────────────────────────────────────────────────────────────────────────────

/// تذييل ترقيم صفحة واحدة: «صفحة X من Y».
///
/// لا يُعرض شيء إذا كان الترقيم معطّلاً أو كانت الصفحة مستثناة (الغلاف أو أول
/// N صفحات)، وعندئذٍ يُعدّ «من Y» الصفحات المرقّمة فقط.
class _PageNumberFooter extends StatelessWidget {
  const _PageNumberFooter({
    super.key,
    required this.numbering,
    required this.pageIndex,
    required this.totalPages,
  });

  final PageNumberingConfig numbering;
  final int pageIndex;
  final int totalPages;

  @override
  Widget build(BuildContext context) {
    if (!numbering.shouldNumberPage(pageIndex)) {
      return const SizedBox.shrink();
    }
    final Alignment alignment = switch (numbering.align) {
      PageNumberAlign.right => Alignment.centerRight,
      PageNumberAlign.center => Alignment.center,
      PageNumberAlign.left => Alignment.centerLeft,
    };
    return Align(
      alignment: alignment,
      child: Text(
        numbering.labelFor(pageIndex, totalPages),
        key: const ValueKey<String>('writer-page-number-label'),
        style: TextStyle(
          fontSize: numbering.fontSize,
          color: numbering.color != null
              ? Color(numbering.color!)
              : Colors.grey.shade500,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// فاصل الصفحات اليدوي
// ─────────────────────────────────────────────────────────────────────────────

/// خط منقّط خفيف يُرسم في هامش الصفحة العليا حين تبدأ بفاصل صفحات يدوي —
/// دلالة بصرية كصفحة الوورد، لا يستهلك من ارتفاع المحتوى شيئاً.
class _PageBreakMarker extends StatelessWidget {
  const _PageBreakMarker({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1,
      child: CustomPaint(painter: _DashedLinePainter()),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  _DashedLinePainter();

  static final Paint _paint = Paint()
    ..color = Colors.blueGrey.withValues(alpha: 0.35)
    ..strokeWidth = 1;

  static const double _dash = 6;
  static const double _gap = 5;

  @override
  void paint(Canvas canvas, Size size) {
    final double y = size.height / 2;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, y),
        Offset(math.min(x + _dash, size.width), y),
        _paint,
      );
      x += _dash + _gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// محرّر الكتلة (TextField)
// ─────────────────────────────────────────────────────────────────────────────

class _BlockEditor extends StatelessWidget {
  const _BlockEditor({
    required this.index,
    required this.block,
    required this.controller,
  });

  final int index;
  final JoodWriterBlock block;
  final WriterDocumentController controller;

  @override
  Widget build(BuildContext context) {
    if (index >= controller.controllers.length) return const SizedBox.shrink();

    final TextStyle style = JoodWriterTextStyles.of(block);
    final bool isBullet = block.kind == JoodWriterBlockKind.bullet;
    final bool isNumbered = block.kind == JoodWriterBlockKind.numbered;

    int listIndex = 1;
    if (isNumbered) {
      for (int i = index - 1; i >= 0; i--) {
        if (controller.document.blocks[i].kind ==
            JoodWriterBlockKind.numbered) {
          listIndex++;
        } else {
          break;
        }
      }
    }

    return Padding(
      padding: EdgeInsets.only(
        bottom: block.spaceAfter,
        top: index == 0 ? 0 : block.spaceBefore,
        right: block.indentCm * 10 * WriterCanvas.pxPerMm,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isBullet)
              Padding(
                padding: const EdgeInsets.only(top: 2, left: 6, right: 6),
                child: Text('•', style: style),
              ),
            if (isNumbered)
              Padding(
                padding: const EdgeInsets.only(top: 2, left: 6, right: 6),
                child: Text('$listIndex.', style: style),
              ),
            Expanded(
              child: Focus(
                onKeyEvent: (node, event) {
                  // Enter → كتلة جديدة
                  if (event.logicalKey == LogicalKeyboardKey.enter ||
                      event.logicalKey == LogicalKeyboardKey.numpadEnter) {
                    final keys = HardwareKeyboard.instance.logicalKeysPressed;
                    if (keys.contains(LogicalKeyboardKey.shiftLeft) ||
                        keys.contains(LogicalKeyboardKey.shiftRight)) {
                      return KeyEventResult.ignored;
                    } else if (event is KeyDownEvent) {
                      controller.addBlockAfterActive();
                      return KeyEventResult.handled;
                    }
                    if (event is KeyUpEvent) {
                      return KeyEventResult.handled;
                    }
                  }

                  // Backspace في بداية الكتلة → دمج مع السابقة
                  if (event.logicalKey == LogicalKeyboardKey.backspace &&
                      event is KeyDownEvent) {
                    final tc = controller.controllers[index];
                    if (tc.selection.baseOffset == 0 &&
                        tc.selection.extentOffset == 0 &&
                        index > 0) {
                      controller.mergeWithPreviousBlock(index);
                      return KeyEventResult.handled;
                    }
                  }

                  return KeyEventResult.ignored;
                },
                child: TextField(
                  key: ValueKey('writer-field-$index'),
                  controller: controller.controllers[index],
                  focusNode: controller.focusNodes[index],
                  maxLines: null,
                  minLines: 1,
                  style: style,
                  textAlign: JoodWriterTextStyles.textAlign(block.align),
                  textDirection: TextDirection.rtl,
                  // أزرق ناعم: شفاف بما يكفي لقراءة النص 100% أثناء التحديد
                  // (لون التحديد نفسه يأتي من Theme الموضّح على اللوحة).
                  cursorColor: WriterCanvas.selectionBlue,
                  decoration: InputDecoration(
                    isDense: true,
                    // ورقة بيضاء ناصعة: بلا خلفيات أو ظلال رمادية حول النص.
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    // ⚠️ لا `prefix` هنا: كان يُرسم مرة واحدة قبل منطقة النص
                    // بأكملها فيُضيّق نطاق الالتفاف، فتبدو كل الأسطر مُزاحة لا
                    // أولها. الإزاحة تُضاف إلى تدفّق النص نفسه (WidgetSpan واحد
                    // في أوله — راجع [WriterTextEditingController.buildTextSpan])
                    // فيأخذها السطر الأول وحده.
                    hintText: block.kind == JoodWriterBlockKind.paragraph
                        ? 'اكتب...'
                        : block.kind.labelAr,
                    hintStyle: style.copyWith(
                      color: Colors.grey.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// طبقة الأشكال
// ─────────────────────────────────────────────────────────────────────────────

class _ShapeOverlay extends StatelessWidget {
  const _ShapeOverlay({
    required this.shape,
    required this.index,
    required this.pxPerMm,
  });

  final int index;
  final WriterShape shape;
  final double pxPerMm;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: shape.xMm * pxPerMm,
      top: shape.yMm * pxPerMm,
      width: shape.widthMm * pxPerMm,
      height: shape.heightMm * pxPerMm,
      child: IgnorePointer(
        child: CustomPaint(painter: _ShapePainter(shape: shape)),
      ),
    );
  }
}

class _ShapePainter extends CustomPainter {
  _ShapePainter({required this.shape});
  final WriterShape shape;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint strokePaint = Paint()
      ..color = shape.strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = shape.strokeWidth;

    final Paint? fillPaint = shape.fillColor != null
        ? (Paint()
            ..color = shape.fillColor!
            ..style = PaintingStyle.fill)
        : null;

    final Rect rect = Offset.zero & size;

    switch (shape.kind) {
      case WriterShapeKind.rectangle:
        if (fillPaint != null) canvas.drawRect(rect, fillPaint);
        canvas.drawRect(rect, strokePaint);
        break;
      case WriterShapeKind.circle:
        if (fillPaint != null) canvas.drawOval(rect, fillPaint);
        canvas.drawOval(rect, strokePaint);
        break;
      case WriterShapeKind.line:
        canvas.drawLine(rect.topLeft, rect.bottomRight, strokePaint);
        break;
      case WriterShapeKind.arrow:
        canvas.drawLine(rect.topLeft, rect.bottomRight, strokePaint);
        canvas.drawCircle(
          rect.bottomRight,
          shape.strokeWidth * 2,
          strokePaint..style = PaintingStyle.fill,
        );
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _ShapePainter oldDelegate) =>
      oldDelegate.shape != shape;
}
