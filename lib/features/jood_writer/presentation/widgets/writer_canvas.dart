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
import '../writer_text_scale.dart';

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

  /// تحويل مليمتر إلى بكسل **مقتصّاً عند الصفر**.
  ///
  /// المقاس والهوامش قابلة للضبط من المستخدم، وقد تتعارض فعلياً (ورقة صغيرة
  /// بهوامش أكبر منها، أو هامش سالب بلوحة المفاتيح). حينها يصير الفرق سالباً
  /// ويسقط **البناء كله** بـ`ErrorWidget`:
  ///
  /// * `EdgeInsets` سالب ⇒ شهادة `padding.isNonNegative` من `RenderPadding`.
  /// * `SizedBox` سالب ⇒ `BoxConstraints` سالبة غير مُطبَّعة.
  ///
  /// القَصّ يُبقي الورقة صالحة في الحالتين — ولا يمسّ القياس الافتراضي إطلاقاً.
  static double mmToPx(double millimeters) =>
      math.max(0, millimeters * pxPerMm);

  /// عرض (أو ارتفاع) منطقة المحتوى داخل الورقة — **لا يقلّ عن صفر أبداً**،
  /// فالهوامش قد تفوق الورقة نفسها فيصير الطرح سالباً. انظر [mmToPx].
  static double contentOf(double pagePx, double startPx, double endPx) =>
      math.max(0, pagePx - startPx - endPx);

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

  /// مقياس تكبير النص الفعّال من **المصدر الوحيد**
  /// (`context.writerTextScaler` → `MediaQuery.textScalerOf`)؛
  /// يُقرأ مرّة واحدة عند كل بناء فيُثبَّت للاستعمال في كل مسارات القياس
  /// (البناء، الشطر الآلي، التمرير)، فلا يُقاس النص أصغر ممّا يُرسم.
  TextScaler _textScaler = TextScaler.noScaling;

  /// آخر نسخة نصّية رأتها الطبقة الرسومية. الشطر الآلي مربوط بها لا بإشعارات
  /// المتحكّم عامّةً، فلا يُعاد الترقيم عند التنقّل/التكبير (انظر
  /// [_onControllerChanged]).
  int _lastSeenTextRevision = 0;

  /// بصمة كلّ ما يعيد تخطيط الصفحات: المستند، التكبير، وضع العرض.
  ///
  /// **تغيّر الكتلة النشطة ليس فيها**: الوقوف على نصٍّ (أو مغادرته) يغيّر
  /// النشاط فقط، فلا يُعاد بناء الصفحات ولا يُعاد ترقيمها — والنصّ يبقى
  /// ثابتاً. الكتل تقرأ النشاط من [_activeBlockSignal] فحسب.
  Object? _layoutSignature;

  // ───────────────────────────────────────────────────────────────────────────
  //  مقياس مشترك: مخزن القياس يعمل فعلاً فقط إذا عاش بين الاستدعاءات
  // ───────────────────────────────────────────────────────────────────────────

  /// آخر مقياس بُنِي، ولـ [TextPainterBlockMeasurer] مخزّنٌ داخليّ (بصمة
  /// المحتوى) لا يعمل إن أُنشئ مقياساً جديداً في كل استدعاء: كان كل حرف
  /// يُنشئ مقياساً في `_splitOnce` وآخر في التمرير وثالثاً في `build`
  /// ⇒ تُقاس كل كتل المستند من جديد في كل إطار. هنا مقياسٌ واحد يبقى
  /// حيّاً بين الإطارات، فتُعاد قياس الكتلة التي تغيّر نصّها فقط.
  TextPainterBlockMeasurer? _sharedMeasurer;
  double? _sharedMeasurerWidth;
  TextScaler? _sharedMeasurerScaler;

  /// يعيد المقياس الموحّد لعرض [contentWidth] الحالي — يُعاد بناؤه فقط إن
  /// تغيّر العرض أو مقياس الخط (أي تغيّر تخطيط فعلاً).
  TextPainterBlockMeasurer measurerFor(double contentWidth) {
    final TextScaler scaler = _textScaler;
    final TextPainterBlockMeasurer? current = _sharedMeasurer;
    if (current != null &&
        _sharedMeasurerWidth == contentWidth &&
        _sharedMeasurerScaler == scaler) {
      return current;
    }
    _sharedMeasurerWidth = contentWidth;
    _sharedMeasurerScaler = scaler;
    return _sharedMeasurer = TextPainterBlockMeasurer(
      contentWidth: contentWidth,
      scale: 1.0,
      textScaler: scaler,
    );
  }

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
    if (revision != _lastSeenTextRevision) {
      _lastSeenTextRevision = revision;
      // الشطر الآلي يقع **متزامناً** داخل المتحكّم نفسه مع التعديل
      // (`onEdited` → `_requestAutoSplit`)، ويعلَن عن ذلك بـ
      // [WriterDocumentController.autoSplitRevision]. هذا الإشعار يصل بعد
      // ذلك مباشرةً ⇒ المراجعة نفسها، فلا يُعاد الشطر ثانيةً (كان كل حرف
      // يُشغّل التدفّق الكامل مرّتين: مرة مع التعديل ومرة مع إشعاره).
      if (revision != controller.autoSplitRevision) {
        _autoSplitIfNeeded();
      }
    }

    // إعادة بناء الصفحات **فقط** عند تغيّر بصمة التخطيط. التركيز على نصٍّ
    // (أو مغادرته) لا يغيّرها ⇒ لا يُعاد بناء الصفحات ولا يُعاد ترقيمها.
    final Object signature = Object.hash(
      controller.document,
      controller.zoomLevel,
      controller.viewMode,
    );
    if (signature == _layoutSignature) return;
    _layoutSignature = signature;
    if (mounted) setState(() {});
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
    final double pageWidth = WriterCanvas.mmToPx(doc.effectivePageSize.widthMm);
    final double pageHeight = WriterCanvas.mmToPx(
      doc.effectivePageSize.heightMm,
    );
    final double marginT = WriterCanvas.mmToPx(doc.margins.top);
    final double marginB = WriterCanvas.mmToPx(doc.margins.bottom);
    final double marginL = WriterCanvas.mmToPx(doc.margins.left);
    final double marginR = WriterCanvas.mmToPx(doc.margins.right);
    final double contentWidth = WriterCanvas.contentOf(
      pageWidth,
      marginL,
      marginR,
    );
    final double contentHeight = WriterCanvas.contentOf(
      pageHeight,
      marginT,
      marginB,
    );

    // مقياسٌ مشترك حيٌّ بين الإطارات: الكتل الثابتة لا تُقاس من جديد
    // (انظر [measurerFor]).
    final measurer = measurerFor(contentWidth);

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
            final int breakAt = _offsetAfterLine(
              block.text,
              lines,
              slice.lineEnd,
            );
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
        // مقياسٌ مشترك حيّ: لا تُعاد قياس كل كتل المستند لتحديد الهدف.
        measurer: measurerFor(contentWidth),
      );
      int pageIndex = pages.indexWhere(
        (page) => page.slices.any((slice) => slice.blockIndex == blockIndex),
      );
      if (pageIndex < 0) pageIndex = pages.length - 1;

      // طي الكتاب: الصفّ يضم صفحتين متقابلتين ⇒ الهدف هو صفّ الصفحة لا
      // موضع صفحتها وحدها.
      final bool spread = controller.viewMode == WriterViewMode.spread;
      final int row = spread ? pageIndex ~/ 2 : pageIndex;
      final double rowHeight = pageHeight * _pageFit * controller.zoomLevel;
      final double rowTop =
          WriterCanvas.listTopPadding +
          row * (rowHeight + WriterCanvas.pageGap);
      final double target = rowTop.clamp(
        0.0,
        _pagesScroll.position.maxScrollExtent,
      );

      // ⚠️ كان يُستدعى **دائماً** بأنيميشن 220ms — حتى لو كانت الصفحة
      // الهدف معروضة أصلاً، وحتى أثناء حركة تمرير جارية. النتيجة: كل ضغطة
      // تُنفّذ شطرًاً قصيراً كانتباهات في موضع المستخدم («قفز/اهتزاز»
      // النص). الآن: لا قَفْزة إن كان المستخدم ينظر إلى صفّ الهدف نفسه، ولا
      // قَفْزة فوق حركةٍ جارية (سحب/انطلاق/أنيميشن) تؤجّل نفسها.
      //
      // ملاحظة: الورقة (A4 ≈ 1122px) أطول من شاشة العرض عادةً، فلا يكفي
      // فحص «الهدف ظاهرٌ بالكامل» — الصحيح أنّ الهدف هو **الصفّ الذي ينظر
      // إليه المستخدم أصلاً**، فلا يُحرَّك شيء.
      final ScrollPosition position = _pagesScroll.position;
      if (position.isScrollingNotifier.value) return;
      final double pitch = rowHeight + WriterCanvas.pageGap;
      // صفّ «سطح النظر» — يُصفَّر للبداية قبل أول بادئة.
      final int currentRow = math.max(
        0,
        ((position.pixels - WriterCanvas.listTopPadding) / pitch).floor(),
      );
      if (currentRow == row) return; // صفّ الهدف تحت سطح النظر بالفعل.
      final double viewBottom = position.pixels + position.viewportDimension;
      if (rowTop >= position.pixels && rowTop + rowHeight <= viewBottom) {
        return; // الهدف ظاهرٌ بالكامل — النصّ ثابتٌ في مكانه.
      }
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
        child: _buildPages(context),
      ),
    );
  }

  /// تبني قائمة الصفحات — تُستدعى من [build] فقط.
  ///
  /// لا تستمع للمتحكّم مباشرةً: إعادة البناء تمرّ عبر [setState] في
  /// [_onControllerChanged] عند تغيّر بصمة التخطيط فقط، فالوقوف على نصٍّ
  /// (أو مغادرته) لا يُعيد بناء الصفحات ولا يُعيد ترقيمها — والنصّ يبقى
  /// ثابتاً كما هو.
  Widget _buildPages(BuildContext context) {
    final doc = controller.document;
    final double pageWidth = WriterCanvas.mmToPx(doc.effectivePageSize.widthMm);
    final double pageHeight = WriterCanvas.mmToPx(
      doc.effectivePageSize.heightMm,
    );
    final double marginT = WriterCanvas.mmToPx(doc.margins.top);
    final double marginB = WriterCanvas.mmToPx(doc.margins.bottom);
    final double marginL = WriterCanvas.mmToPx(doc.margins.left);
    final double marginR = WriterCanvas.mmToPx(doc.margins.right);
    final double contentWidth = WriterCanvas.contentOf(
      pageWidth,
      marginL,
      marginR,
    );
    final double contentHeight = WriterCanvas.contentOf(
      pageHeight,
      marginT,
      marginB,
    );

    // مقياس تكبير النص الفعّال في هذا الإطار — من المصدر الوحيد،
    // فالقيمة نفسها التي تأخذها ودجات الرسم ضمناً من `MediaQuery`؛
    // يُثبَّت هنا عند البناء ويُمرَّر إلى كل المُقاسات، فيقيس المحرّر
    // ما يُرسم بالضبط (لا فيض مهما كبّر المستخدم).
    _textScaler = context.writerTextScaler;

    // مقياسٌ مشترك حيّ بين الإطارات: الكتل التي لم يتغيّر نصّها لا تُقاس
    // من جديد عند كل ضغطة (انظر [measurerFor]).
    final measurer = measurerFor(contentWidth);

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
        final bool spread = controller.viewMode == WriterViewMode.spread;
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
    final double contentWidth = WriterCanvas.contentOf(
      pageWidth,
      marginL,
      marginR,
    );

    for (final slice in page.slices) {
      final int blockIndex = slice.blockIndex;
      final JoodWriterBlock block = slice.block;

      // «موضع» واحد لكل شريحة: الشريحة الأولى تتحوّل إلى محرّر حين تكتسب
      // كتلتها التركيز، وتبقى الشرائح المكملة أسطراً ثابتة — فلا يختفي نصٌّ
      // من الصفحة ولا يُعاد ترقيمها عند الوقوف على نصٍّ (أو مغادرته).
      //
      // المسافة قبل الكتلة تُرسم هنا (وهي موضع مشترك بين المسارين) ولا
      // تُرسم في رأس الصفحة — كما يقيسها التدفّق تماماً.
      children.add(
        _BlockSlot(
          key: ValueKey<String>('writer-block-$blockIndex-${slice.lineStart}'),
          index: blockIndex,
          controller: controller,
          block: block,
          lines: measurer.linesOf(block),
          lineStart: slice.lineStart,
          lineEnd: slice.lineEnd,
          editable: slice.isBlockStart,
          showSpaceBefore: slice.isBlockStart && children.isNotEmpty,
          prefixWidth: measurer.prefixWidthOf(block),
          prefixLabel: _prefixLabel(controller, blockIndex),
        ),
      );
    }

    return Container(
      width: pageWidth,
      height: pageHeight,
      decoration: BoxDecoration(
        // لون الورق: أبيض افتراضياً، أو لون المستند إن اختار المستخدم.
        color: doc.pageColor != null ? Color(doc.pageColor!) : Colors.white,
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
          // العلامة المائية: نصّ شفّاف مائل خلف المحتوى — كعلامة وورد.
          if (doc.watermark != null && doc.watermark!.isNotEmpty)
            Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: Transform.rotate(
                    angle: -0.52,
                    child: Opacity(
                      opacity: 0.09,
                      child: Text(
                        doc.watermark!,
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          fontSize: pageWidth / 6,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          // إطار الطباعة داخل الهوامش — خط رفيع يحدّد منطقة المحتوى.
          if (doc.pageBorder)
            Positioned.fill(
              child: IgnorePointer(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    marginL,
                    marginT,
                    marginR,
                    marginB,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.black.withValues(alpha: 0.55),
                        width: 0.8,
                      ),
                    ),
                  ),
                ),
              ),
            ),
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

// موضع الكتلة: محرّر حين تكتسب كتلتها التركيز، وأسطر ثابتة حين لا تكتبه
// ─────────────────────────────────────────────────────────────────────────────

/// موضع شريحة من كتلة داخل الصفحة.
///
/// **الوقوف على النصّ لا يغيّر شكله**: هذا الموضع يستمع إلى
/// [WriterDocumentController.activeBlockSignal] — إشارة النشاط وحدها — لا إلى
/// إشعارات المتحكّم العامة، فلا تُعاد بناء الصفحة ولا يُعاد ترقيمها عند
/// التركيز أو عند مغادرته؛ يتبدّل شكل **هذا الموضع** فحسب، بحرفين متطابقين.
class _BlockSlot extends StatefulWidget {
  const _BlockSlot({
    super.key,
    required this.index,
    required this.controller,
    required this.block,
    required this.lines,
    required this.lineStart,
    required this.lineEnd,
    required this.editable,
    required this.showSpaceBefore,
    required this.prefixWidth,
    required this.prefixLabel,
  });

  /// فهرس الكتلة في المستند — مفتاح النشاط وموضع عقدة التركيز والمحرّق.
  final int index;
  final WriterDocumentController controller;
  final JoodWriterBlock block;

  /// الأسطر **المقيسة مسبقاً** لكل الكتلة — نفس التي يلتفّ عندها المحرّر.
  final List<String> lines;
  final int lineStart;
  final int lineEnd;

  /// الشريحة الأولى من الكتلة هي وحدها التي تتحوّل إلى محرّر؛ فتشترك في
  /// عقدة التركيز والمحرّق والنداء للكتلة كاملة.
  final bool editable;

  /// تُرسم قبل أول شريحة من الكتلة — ولا تُرسم في رأس الصفحة.
  final bool showSpaceBefore;

  /// عرض مقدّمة القائمة بالبكسل — من المُقاس نفسه، لا من تقدير العارض.
  final double prefixWidth;

  /// مقدّمة القائمة (• / 1.) إن كانت الكتلة قائمة.
  final String? prefixLabel;

  @override
  State<_BlockSlot> createState() => _BlockSlotState();
}

class _BlockSlotState extends State<_BlockSlot> {
  /// هل تملك هذه الشريحة التركيز الآن؟ تُشتقّ من الإشارة لا من الإشعار العام.
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _isActive = _computeActive();
    widget.controller.activeBlockSignal.addListener(_onActiveChanged);
  }

  @override
  void didUpdateWidget(covariant _BlockSlot oldWidget) {
    super.didUpdateWidget(oldWidget);
    // الودجة قد تُستعمل لكتلة أخرى بعد شطر أو دمج (يتحدّث مفتاحها) ⇒ تُعاد
    // اشتقاق النشاط، وإلا بقيت الكتلة القديمة «نشطةً» بمحرّر لا كتلة له.
    if (oldWidget.index != widget.index ||
        oldWidget.editable != widget.editable) {
      _isActive = _computeActive();
    }
  }

  @override
  void dispose() {
    widget.controller.activeBlockSignal.removeListener(_onActiveChanged);
    super.dispose();
  }

  bool _computeActive() =>
      widget.editable && widget.controller.activeBlockIndex == widget.index;

  void _onActiveChanged() {
    if (!mounted) return;
    final bool active = _computeActive();
    if (active == _isActive) return;
    setState(() => _isActive = active);
  }

  @override
  Widget build(BuildContext context) {
    if (_isActive) {
      return _BlockEditor(
        index: widget.index,
        block: widget.block,
        controller: widget.controller,
        showSpaceBefore: widget.showSpaceBefore,
        prefixWidth: widget.prefixWidth,
        prefixLabel: widget.prefixLabel,
      );
    }
    return _BlockLines(
      block: widget.block,
      lines: widget.lines,
      lineStart: widget.lineStart,
      lineEnd: widget.lineEnd,
      showSpaceBefore: widget.showSpaceBefore,
      prefixWidth: widget.prefixWidth,
      prefixLabel: widget.prefixLabel,
      onActivate: () {
        widget.controller.setActiveBlock(widget.index);
        widget.controller.requestBlockFocus(widget.index);
      },
    );
  }
}

/// مقدّمة القائمة (• أو 1.) في صندوق **عرضه ثابت** — بالعرض ذاته الذي يخصمه
/// المُقاس من عرض كل سطر ([TextPainterBlockMeasurer.prefixWidthOf]).
///
/// لماذا عرض ثابت؟ لأنّ المحرّر يلتفّ عند عرضٍ يخصم فيه هذا الصندوق، فلو
/// اختلف عرضه في النصّ الثابت لالتفّت الأسطر عند موضع آخر ويبدو النصّ
/// «متحرّكاً» عند الوقوف عليه. ذات الصندوق يُرسم في المسارين، وفراغه (بلا
/// نصّ) يُرسم في أسطر القائمة التالية كي يطابق عرض مربعة المحرّر تماماً.
class _BlockPrefix extends StatelessWidget {
  const _BlockPrefix({
    required this.block,
    required this.width,
    required this.label,
  });

  final JoodWriterBlock block;
  final double width;

  /// `null` لسطرٍ لا مقدّمة له (أسطر القائمة بعد الأول) — يُرسم الصندوق
  /// فارغاً ليبقى عرض السطر نفسه.
  final String? label;

  @override
  Widget build(BuildContext context) {
    // متغيّر محليّ: الحقل العام لا يُرقَّم في Dart بعد فحص `null`.
    final String? text = label;
    if (text == null) return SizedBox(width: width);
    return SizedBox(
      width: width,
      child: Text(
        text,
        style: JoodWriterTextStyles.of(block),
        textDirection: TextDirection.rtl,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.clip,
      ),
    );
  }
}

/// أسطر كتلة ثابتة — تُرسم سطراً سطراً **كما قِيست بالضبط**.
///
/// كل سطر ودجة `Text` مستقلة بـ`softWrap: false` فلا يُعاد التفافه أبداً؛
/// والمحرّر يلتفّ عند الموضع نفسه (نفس العرض المتاح لكل سطر، ونفس مقدّمة
/// القائمة ومسافة السطر الأول) — فيبدو النصّ واحداً قبل الوقوف عليه وبعده.
class _BlockLines extends StatelessWidget {
  const _BlockLines({
    required this.block,
    required this.lines,
    required this.lineStart,
    required this.lineEnd,
    required this.showSpaceBefore,
    required this.prefixWidth,
    required this.prefixLabel,
    required this.onActivate,
  });

  final JoodWriterBlock block;
  final List<String> lines;
  final int lineStart;
  final int lineEnd;
  final bool showSpaceBefore;
  final double prefixWidth;
  final String? prefixLabel;

  /// النقر على أي سطر من السطرين ينشّط الكتلة ويطلب تركيز حقلها.
  final VoidCallback onActivate;

  @override
  Widget build(BuildContext context) {
    final TextStyle style = JoodWriterTextStyles.of(block);
    final TextAlign align = JoodWriterTextStyles.textAlign(block.align);
    final double indent = JoodWriterTextStyles.indentPx(block);
    final double firstIndent = JoodWriterTextStyles.firstLineIndentPx(block);

    return Padding(
      // نفس المسافة قبل الكتلة التي يرسمها المحرّر — فلا ينزلق نصّ الصفحة
      // عند الوقوف على كتلةٍ ولا عند مغادرتها.
      // المسافة قبل الكتلة قابلة للضبط وقد تبلغ سالباً بلوحة المفاتيح،
      // وقيمة سالبة تسقط البناء كلّه بشهادة `padding.isNonNegative`.
      // القَصّ لا يمسّ القيم الافتراضية إطلاقاً (‏`spaceBefore = 0`).
      padding: EdgeInsets.only(
        top: showSpaceBefore ? math.max(0, block.spaceBefore) : 0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (
            int line = lineStart;
            line < lineEnd && line < lines.length;
            line++
          )
            GestureDetector(
              onTap: onActivate,
              child: Padding(
                padding: EdgeInsets.only(
                  // الإزاحتان قابلتان للضبط وقد تبلغا سالباً ⇒ قَصّ عند الصفر
                  // (انظر `padding.isNonNegative` في `RenderPadding`).
                  right: math.max(0, indent + (line == 0 ? firstIndent : 0)),
                ),
                child: prefixLabel == null
                    ? Padding(
                        // **هامش المؤشّر في المسار الثابت**: `RenderEditable`
                        // يخصم 3px من كل سطرٍ يرسمه ليستديع موضعاً للمؤشّر،
                        // فتُخصم هنا من مربّع السطر نفسه — لا من صندوقه
                        // (المحفظة) كي لا ينزاح عنه — فيصير مربّع الالتفاف
                        // واحداً في المسارين ولا يقفز النصّ 3px عند الوقوف.
                        padding: const EdgeInsets.only(
                          right: JoodWriterTextStyles.caretMargin,
                        ),
                        child: _text(lines[line], style, align),
                      )
                    : Row(
                        textDirection: TextDirection.rtl,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          _BlockPrefix(
                            block: block,
                            width: prefixWidth,
                            label: line == 0 ? prefixLabel : null,
                          ),
                          Expanded(
                            // هامش المؤشّر: يخصم من مربّع النصّ دون أن يمسّ
                            // المقدّمة (فهي تبقى على حافة المحتوى كما في
                            // المحرّر تماماً).
                            child: Padding(
                              padding: const EdgeInsets.only(
                                right: JoodWriterTextStyles.caretMargin,
                              ),
                              child: _text(lines[line], style, align),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
        ],
      ),
    );
  }

  static Widget _text(String line, TextStyle style, TextAlign align) => Text(
    line,
    style: style,
    textAlign: align,
    textDirection: TextDirection.rtl,
    // كل سطر مقيس مسبقاً ⇒ يمنع تكافّاً ثانياً يُفسد الترقيم.
    softWrap: false,
    overflow: TextOverflow.clip,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// محرّر الكتلة (TextField)
// ─────────────────────────────────────────────────────────────────────────────

class _BlockEditor extends StatelessWidget {
  const _BlockEditor({
    required this.index,
    required this.block,
    required this.controller,
    required this.showSpaceBefore,
    required this.prefixWidth,
    required this.prefixLabel,
  });

  final int index;
  final JoodWriterBlock block;
  final WriterDocumentController controller;
  final bool showSpaceBefore;
  final double prefixWidth;
  final String? prefixLabel;

  @override
  Widget build(BuildContext context) {
    if (index >= controller.controllers.length) return const SizedBox.shrink();

    final TextStyle style = JoodWriterTextStyles.of(block);

    return Padding(
      padding: EdgeInsets.only(
        // **لا مسافة بعد الكتلة هنا**: المسار الثابت لا يرسمها، فكانت
        // إضافتها في المحرّر وحده تنزق كل ما تحت الكتلة 8px عند الوقوف
        // عليه وتعيده عند المغادرة. المسافة محجوزة في التدفّق لا في الرسم.
        top: showSpaceBefore ? math.max(0, block.spaceBefore) : 0,
        right: math.max(0, JoodWriterTextStyles.indentPx(block)),
      ),
      child: IntrinsicHeight(
        child: Row(
          textDirection: TextDirection.rtl,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (prefixLabel != null)
              _BlockPrefix(
                block: block,
                width: prefixWidth,
                label: prefixLabel,
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
                // **لا نمدّ صندوق الحقل** لتعويض هامش المؤشّر 3px الذي يخصمه
                // `RenderEditable` من كل سطرٍ يرسمه. كل محاولة توسيعٍ لصندوق
                // الحقل عن خانته تنهار: `Padding` بقيمة سالبة يُسقطه
                // `padding.isNonNegative`، و`OverflowBox` لا يرث الأبعاد، و`Stack`
                // بابنٍ مُحدَّد (Positioned) يعطي `IntrinsicHeight` ارتفاع صفر —
                // فيختفي صندوق الكتلة ويتراكب النصّ الثابت الذي تحتها.
                // التعويض إذن على **المسار الثابت**: يخصم المُقاس هامش
                // المؤشّر من عرضَيه، ويخصم رسم الأسطر 3px من مربّع كل سطر
                // (اللّوحات والمعاينة معاً) — فمربّع الالتفاف واحدٌ بالضبط في
                // المسارين وبأيّ محاذاة، ولا يتحرّك السطر عند الوقوف.
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

// ─────────────────────────────────────────────────────────────────────────────
// مقدّمات القائمة (تُشتقّ من المستند نفسه في المسارين)
// ─────────────────────────────────────────────────────────────────────────────

/// الرقم التسلسلي لكتلة مرقّمة داخل سلسلتها المتصلة: يعدّ الكتل المرقّمة التي
/// تسبقها متجاورةً حتى ينقطع الصفّ.
///
/// **من المستند لا من الودجات**: المسار الثابت والمحرّر يقرأان المقدّمة من
/// هنا معاً، فلا تختلف «1.» عن «2.» بين الحالتين.
int _numberedIndex(WriterDocumentController controller, int blockIndex) {
  int index = 1;
  for (int i = blockIndex - 1; i >= 0; i--) {
    if (controller.document.blocks[i].kind == JoodWriterBlockKind.numbered) {
      index++;
    } else {
      break;
    }
  }
  return index;
}

/// مقدّمة القائمة المرسومة قبل نصّ الكتلة: «•» للنقاط و«1.» للمرقّمة،
/// و`null` لبقية الأنواع.
String? _prefixLabel(WriterDocumentController controller, int blockIndex) {
  if (blockIndex < 0 || blockIndex >= controller.document.blocks.length) {
    return null;
  }
  switch (controller.document.blocks[blockIndex].kind) {
    case JoodWriterBlockKind.bullet:
      return '•';
    case JoodWriterBlockKind.numbered:
      return '${_numberedIndex(controller, blockIndex)}.';
    case JoodWriterBlockKind.heading1:
    case JoodWriterBlockKind.heading2:
    case JoodWriterBlockKind.paragraph:
      return null;
  }
}
