import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../domain/flow_paginator.dart';
import '../domain/jood_writer_block.dart';
import 'jood_writer_text_styles.dart';

/// يقيس الكتل بـ`TextPainter` عند عرض محتوى معيّن — التنفيذ الحقيقي لواجهة
/// [BlockMeasurer] الذي يستهلكه [FlowPaginator] في المعاينة والطباعة.
///
/// ## التوحيد مع العارض (Renderer)
///
/// القياس والعرض توأمان: كل معامل يدخل القياس هنا يدخل الرسم في
/// `writer_canvas.dart` / `writer_pages_view.dart` بالقيمة **نفسها**، وإلا
/// اختلف عدد الأسطر المحسوب عن المرسوم فتغيّر النص أو فيض أو قُطع.
///
/// | المعامل | المصدر المشترك |
/// |---------|----------------|
/// | `TextStyle` | [JoodWriterTextStyles.of] — مصدر واحد، بلا أي تجاوز في القياس |
/// | `TextScaler` | إلزامي تمريره الطبقة الرسومية من `MediaQuery.textScalerOf` |
/// | `textDirection` | `TextDirection.rtl` — نفس ما تمرّره كل العارضات |
/// | `textAlign` | [JoodWriterTextStyles.textAlign] |
/// | `maxWidth` | [_lineWidthOf] — أضيق العرضين، وهو ما يلتفّ عنده المحرّر لكل الأسطر |
///
/// ## ضمان عدم التجاوز
///
/// العارض يرسم **كل سطر مقيساً مسبقاً** بـ`softWrap: false` و`overflow: clip`،
/// فأي سطر يتجاوز عرضه المتاح **يُقطع بلا رجعة**. لذلك يُنجَز التخطيط هنا بأضيق
/// عرض يمنحه العارض لأي سطر — وهو [widthOfFirstLine] (إزاحة السطر الأول ومقدمة
/// القائمة تُضافان إلى إزاحة الفقرة العامة نفسها، ولا تنتقص من أي عرض). فمحصّلة
/// الطرح هي **الحدّ الأدنى** المضمون:
///
/// ```
/// widthOfFirstLine      = contentWidth − indent − firstLineIndent − prefix
/// widthOfRemainingLines = contentWidth − indent − prefix
/// ```
///
/// وبما أن `firstLineIndent ≥ 0` و`prefix ≥ 0`، فـ`widthOfFirstLine` أضيق دائماً
/// (أو تساويه). التخطيط عندها يضمن أن **كل سطر مرسوم** يبقى داخل عرضه — بلا قطع
/// وبلا فيض — لأن المرسوم يحصل على قدر من العرض لا يقلّ عمّا قِيس.
class TextPainterBlockMeasurer implements BlockMeasurer {
  TextPainterBlockMeasurer({
    required this.contentWidth,
    this.scale = 1,
    required this.textScaler,
    this.textDirection = TextDirection.rtl,
  });

  final double contentWidth;
  final double scale;

  /// مقياس تكبير النص **الفعّال** (من `MediaQuery`): تكبير نظام التشغيل أو
  /// اليدوي. يُمرَّر إلى `TextPainter` نفسه، فيتطابق عدد الأسطر وارتفاعها
  /// مع الرسم حرفياً — وإلا قيس نصٌّ أصغر ممّا يُرسم فتفيض الصفحة.
  ///
  /// **إلزامي بلا افتراض:** العارضات (`Text` / `TextField`) تأخذه ضمناً من
  /// `MediaQuery.textScalerOf(context)`. كان افتراض `TextScaler.noScaling` هنا
  /// يجعل القياس أصغر من الرسم متى شغّل المستخدم تكبيراً (إعداد نظام أو يدوي)
  /// فيختلف الالتفاف **ويتغيّر النص**. تمرير صريح يجعل الاختلاف مستحيلاً.
  final TextScaler textScaler;
  final TextDirection textDirection;

  /// النمط المستخدَم في القياس — **بالقيمة نفسها** التي يمرّرها العارض إلى
  /// `Text`/`TextField`. لا تجاوز لعائلة الخط هنا ولا لقائمة الاحتياط: أي حرف
  /// يخصمه القياس دون الرسم (أو العكس) يُنتج أسطراً مختلفة.
  TextStyle _styleOf(JoodWriterBlock block) =>
      JoodWriterTextStyles.of(block, scale: scale);

  /// نسبة تكبير النص: مقدمة القائمة (• / 12.) تُرسم بخط مكبّر ⇒ عرضها
  /// المخصّص يتكبّر معها، فتُخصم بالحجم المرسوم لا بالمحسوب.
  double _prefixRatio(JoodWriterBlock block) {
    final double fontSize = JoodWriterTextStyles.fontSizeOf(block);
    if (fontSize <= 0) return 1;
    return textScaler.scale(fontSize) / fontSize;
  }

  /// عرض مقدّمة القائمة (`•` أو `12.`) بالبكسل **وبالحجم المرسوم فعلاً**.
  ///
  /// **مصدر واحد للعرضين:** القياس يخصمه من كل سطر، والعارض يحجزه أمامه.
  /// توليد القيمة مرتين (أو اشتقاقها من مكانين) يكفي لينزاح النصّ عن موضعه
  /// المقيس فيبدو السطر الأول غير مصطفّ مع ما بعده. ولذلك يُطلب العارض هذه
  /// القيمة من هنا لا من حسابه.
  double prefixWidthOf(JoodWriterBlock block) =>
      JoodWriterTextStyles.listPrefixWidth(block, scale: scale) *
      _prefixRatio(block);

  /// العرض الذي يمنحه العارض **للسطر الأول** من الكتلة.
  double widthOfFirstLine(JoodWriterBlock block) {
    final double used =
        JoodWriterTextStyles.indentPx(block, scale: scale) +
        JoodWriterTextStyles.firstLineIndentPx(block, scale: scale) +
        prefixWidthOf(block);
    return math.max(contentWidth - used, 8.0);
  }

  /// العرض الذي يمنحه العارض **لبقيّة الأسطر** (بعد الأول).
  double widthOfRemainingLines(JoodWriterBlock block) {
    final double used =
        JoodWriterTextStyles.indentPx(block, scale: scale) +
        prefixWidthOf(block);
    return math.max(contentWidth - used, 8.0);
  }

  /// العرض الذي يُنجَز به التخطيط **لكل الأسطر**: أضيق عرضٍ يمنحه العارض
  /// لأي سطر.
  ///
  /// لماذا الأضيق لكل السطور لا الأضيق للأول والواسع لِما بعده؟ لأنّ
  /// محرّر الكتلة يفعل الشيء نفسه: `WidgetSpan` إزاحة السطر الأول يقع في
  /// تدفّق النصّ فيخصم عرضه من **كل** سطر لا من أوله فحسب (قِيس رؤوساً في
  /// `RenderEditable`: السطر الثاني ضيّقٌ بمقدار الإزاحة بالضبط). لو قيس
  /// النصّ الثابت عند عرضين لالتفّ االتفافاً آخر من الالتفاف المحرّري فتبدّل
  /// شكل النصّ عند الوقوف عليه وعند مغادرته.
  ///
  /// والعرضان متساويان في الغالبة (`firstLineIndent == 0` بلا مقدّمة قائمة).
  /// وكل سطرٍ مرسوم يُمنح عرضاً لا يقلّ عمّا قِيس عنده، فلا يُقطع ولا يفيض.
  double _lineWidthOf(JoodWriterBlock block) =>
      math.min(widthOfFirstLine(block), widthOfRemainingLines(block));

  // ───────────────────────────────────────────────────────────────────────────
  //  تخزين القياس: لا `TextPainter.layout` إلا عند اختلاف التخطيط فعلاً
  // ───────────────────────────────────────────────────────────────────────────

  /// سقف عدد مدخلات التخزين المؤقّت. الكتابة تولّد مدخلاً جديداً لكل حالة
  /// نصّية، فيُسقَف العدد ويُطرد الأقدم استخداماً (LRU): الكتلة النشطة تبقى
  /// حارّةً دائماً، والثابتة لا تُقاس ثانيةً أبداً.
  static const int _cacheCapacity = 512;

  /// السقف الفعلي للتخزين المؤقّت — يُقرأ في الاختبارات للتحقق من أنّ
  /// المخزن لا يتسرّب بلا حدود أثناء جلسات كتابة طويلة.
  static int get capacity => _cacheCapacity;

  /// نتائج التخطيط مفهرسة ببصمة المحتوى، مرتّبة بالأقدم استخداماً أولاً.
  final LinkedHashMap<String, _BlockLayout> _cache =
      LinkedHashMap<String, _BlockLayout>();

  /// عدد مرات تنفيذ `TextPainter.layout` فعلياً — يُقرأ في اختبارات ثبات
  /// الكتابة ليثبت أنّ الضغطة الواحدة لا تُعيد قياس الكتل الثابتة.
  int _layoutCount = 0;
  int get layoutCount => _layoutCount;

  /// عدد المرات التي أُعيد فيها استعمال نتيجة مخزّنة بلا أي قياس.
  int _cacheHitCount = 0;
  int get cacheHitCount => _cacheHitCount;

  /// بصمة ما يؤثّر في التخطيط: النصّ وكلّ ما تقرأه [_styleOf] و[widthOfFirstLine] و[widthOfRemainingLines]
  /// و[JoodWriterTextStyles.textAlign].
  ///
  /// [JoodWriterBlock] بلا `==` مُعاد تعريفه، وكل `copyWith` يبني نسخة جديدة —
  /// فالمقارنة بالهوية لا تنفع: ضغطةٌ واحدة على لوحة المفاتيح تبني كتلةً
  /// جديدة فيبدو «تغيّر النصّ» ولو لم يتغيّر شيء. البصمة تقارن **المحتوى**.
  /// (إعدادات المُقاس نفسها ثابتة بعد البناء — كلّ حقوله `final` — فلا تدخل
  /// في المفتاح.)
  String _specOf(JoodWriterBlock block) =>
      '${block.text.length}\u0000${block.text}'
      '\u0000${block.kind.index}\u0000${block.align.index}'
      '\u0000${block.fontFamily}'
      '\u0000${block.fontSize}'
      '\u0000${block.isBold ? 1 : 0}${block.isItalic ? 1 : 0}'
      '${block.isUnderline ? 1 : 0}'
      '\u0000${block.lineSpacing}'
      '\u0000${block.indentCm}\u0000${block.firstLineIndentCm}'
      '\u0000${block.spaceBefore}\u0000${block.spaceAfter}'
      '\u0000${block.fontColor?.toARGB32() ?? -1}'
      '\u0000${block.highlightColor?.toARGB32() ?? -1}';

  /// تخطيط الكتلة — من التخزين المؤقّت إن وُجد، وإلاً يُحسب مرّةً واحدة.
  _BlockLayout _layoutOf(JoodWriterBlock block) {
    final String spec = _specOf(block);
    final _BlockLayout? cached = _cache.remove(spec);
    if (cached != null) {
      _cache[spec] = cached; // LRU: الأحدث استخداماً ينتقل إلى الذيل.
      _cacheHitCount++;
      return cached;
    }

    final _BlockLayout layout = _measure(block);
    _layoutCount++;
    if (_cache.length >= _cacheCapacity) {
      _cache.remove(_cache.keys.first); // إسقاط الأقدم استخداماً.
    }
    _cache[spec] = layout;
    return layout;
  }

  /// ينفّذ القياس فعلاً: لوحة واحدة لكلّ من `linesOf` و`lineHeightOf`
  /// (كان كلٌّ منهما يبني لوحته ⇒ ضعف العمل في كل تمريرة)، ثم تُحرَّر
  /// مواردها الأصلية بعد استخراج النتيجة فلا تتسرّب مع كل ضغطة حرف.
  /// ينفّذ القياس فعلاً: لوحة واحدة لكلّ من `linesOf` و`lineHeightOf`
  /// (كان كلٌّ منهما يبني لوحته ⇒ ضعف العمل في كل تمريرة)، ثم تُحرَّر
  /// مواردها الأصلية بعد استخراج النتيجة فلا تتسرّب مع كل ضغطة حرف.
  ///
  /// **عند أضيق عرض** لا عند عرضين: محرّر الكتلة يلتفّ عند
  /// [widthOfFirstLine] لكل أسطره — إزاحة السطر الأول `WidgetSpan` في تدفّق
  /// النصّ تحتلّ عرضها من **كل** سطر لا من أوله فحسب (قِيس رؤوساً في
  /// `RenderEditable`: سطرٌ ثانٍ ضيّقٌ بمقدار الإزاحة تماماً) — فالقياس عند
  /// الأضيق هو وحده الذي يُطابق حدود أسطر المحرّر حرفاً حرفاً، ويمنع
  /// تكافّاً ثانياً في النصّ الثابت عند الوقوف عليه.
  _BlockLayout _measure(JoodWriterBlock block) {
    final TextPainter painter = _painterOf(
      block,
      block.text.isEmpty ? ' ' : block.text,
    )..layout(maxWidth: _lineWidthOf(block));

    // يُقرأ قبل الإتلاف: `preferredLineHeight` خاصية محسوبة من الفقرة.
    final double lineHeight = painter.preferredLineHeight;
    final _BlockLayout layout = block.text.isEmpty
        ? _BlockLayout.blank(lineHeight)
        : _BlockLayout.of(painter, block.text, lineHeight);
    painter.dispose();
    return layout;
  }

  /// لوحة قياس لنصّ [text] بنفس إعدادات [_measure] — بلا أي تجاوز في أسرة
  /// الخط ولا في المقياس ولا الاتجاه ولا المحاذاة.
  TextPainter _painterOf(JoodWriterBlock block, String text) => TextPainter(
    text: TextSpan(text: text, style: _styleOf(block)),
    textDirection: textDirection,
    textAlign: JoodWriterTextStyles.textAlign(block.align),
    // نفس مقياس تكبير النص الذي يُطبَّق في الرسم: القياس والعرض توأمان.
    textScaler: textScaler,
  );

  /// يفرّغ التخزين المؤقّت. المُقاس غير قابل للتغيير بعد بنائه (كلّ حقوله
  /// `final`) فالمدخلات لا تُبطَل أبداً — التفريغ للاختبارات فقط.
  void clearLayoutCache() => _cache.clear();

  @override
  List<String> linesOf(JoodWriterBlock block) =>
      block.text.isEmpty ? const <String>[''] : _layoutOf(block).lines;

  @override
  double lineHeightOf(JoodWriterBlock block) => _layoutOf(block).lineHeight;

  @override
  double spacingBeforeOf(JoodWriterBlock block) => block.spaceBefore * scale;

  @override
  double spacingAfterOf(JoodWriterBlock block) => block.spaceAfter * scale;
}

/// نتيجة تخطيط كتلة: أسطرها المحسوبة وارتفاع السطر الواحد.
///
/// [lines] للقراءة فقط: تُعاد من التخزين المؤقّت لعدّة مستدعين، فأيّ تعديل
/// عليها يُفسد المستند كلّه. لا تُحرَّر.
class _BlockLayout {
  const _BlockLayout(this.lines, this.lineHeight);

  /// كتلة فارغة: سطر واحد فارغ بارتفاع السطر الحقيقي (لا صفر).
  const _BlockLayout.blank(this.lineHeight) : lines = const <String>[''];

  /// يستخرج الأسطر من لوحة مخطّطة مسبقاً، و[lineHeight] مُمرَّراً لأنّ اللوحة
  /// تُتلف بعد الاستخراج مباشرةً.
  factory _BlockLayout.of(TextPainter painter, String text, double lineHeight) {
    final List<String> lines = <String>[];
    final int length = text.length;
    int start = 0;
    while (start < length) {
      // موقع فاصل أسطر صريح ('\n') لا يبدأ سطراً: `getLineBoundary` يُعيد
      // عنده مدىً صفريّاً (مدى فارغ)، فكان المحرّك يضيف سطراً فارغاً زائفاً
      // ثم يتوقّف — فيرى ‎«سطرين فقط»‎ لمستند كامل مليء بالفواصل.
      //
      // أثر ذلك كارثي: لصق مئات الصفحات من Word يُقاس سطرين ⇒ صفحة واحدة،
      // وكل ما بعدها «مخفي». التخطّي اليدوي يضمن مروراً على كل سطر حقيقي.
      if (text.codeUnitAt(start) == 0x0A) {
        start++;
        continue;
      }

      final TextRange range = painter.getLineBoundary(
        TextPosition(offset: start),
      );
      final int end = range.end.clamp(start, length);
      String line = text.substring(start, end);

      // الفاصل الصريح يلي السطر ولا يُرسم: يُطرح من آخره.
      if (line.isNotEmpty && line.codeUnitAt(line.length - 1) == 0x0A) {
        line = line.substring(0, line.length - 1);
      }

      lines.add(line);

      // حماية من التعليق إن لم يتقدّم المؤشر.
      if (end <= start) {
        start++;
        continue;
      }
      start = end;
    }
    if (lines.isEmpty) lines.add('');
    return _BlockLayout(List<String>.unmodifiable(lines), lineHeight);
  }

  final List<String> lines;
  final double lineHeight;
}
