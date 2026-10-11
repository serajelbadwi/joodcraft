import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
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
/// | `TextStyle` | [JoodWriterTextStyles.of] — مصدر واحد يحمل خطّ الرسم صريحاً (Cairo) |
/// | `TextScaler` | إلزامي تمريره الطبقة الرسومية من `MediaQuery.textScalerOf` |
/// | `textDirection` | `TextDirection.rtl` — نفس ما تمرّره كل العارضات |
/// | `textAlign` | [JoodWriterTextStyles.textAlign] |
/// | `maxWidth` | [widthOfFirstLine] للسطر الأول ثم [widthOfRemainingLines] لبقية الأسطر — نفس عرضَي المحرّر |
///
/// ## ضمان عدم التجاوز
///
/// العارض يرسم **كل سطر مقيساً مسبقاً** بـ`softWrap: false` و`overflow: clip`،
/// فأي سطر يتجاوز عرضه المتاح **يُقطع بلا رجعة**. لذلك يُقاس كل سطر عند **العرض
/// الذي يمنحه له عارضه هو** — لا عند عرضٍ واحد أصغر — فلا يزيد سطرٌ عن حصّته
/// ولا ينقص عندها:
///
/// ```
/// ت-text = contentWidth − caretMargin  (هامش المؤشّر 3px)
/// السطر الأول: widthOfFirstLine      = ت-text − indent − firstLineIndent − prefix
/// بقيّة الأسطر: widthOfRemainingLines = ت-text − indent − prefix
/// ```
///
/// وهذان هما بالضبط عرضا الالتفاف في محرّر الكتلة: `WidgetSpan` إزاحة السطر
/// الأول يقع في تدفّق النصّ فيخصم من **سطره الأول فقط** (قِيس: سطرٌ ثانٍ يلتفّ
/// عند العرض الكامل لا الضيّق)، و`RenderEditable` يخصم هامش المؤشّر 3px من
/// كل سطرٍ يرسمه — فنخصمها نحن من القياس **ومن مربّع كل سطر في الرسم الثابت**
/// بدل أن نمدّ حقل المحرّر (مدّه ينهار ارتفاعه: `RenderStack` لا يرث الارتفاع
/// من أبناءه المُحدَّدين، فتؤول السلسلة إلى `IntrinsicHeight` بارتفاع صفر).
/// بذلك يصير مربّع الالتفاف واحداً في المسارين وبأيّ محاذاة — لا يتحرّك
/// السطر عند الوقوف على الكتلة ولا عند مغادرتها.
class TextPainterBlockMeasurer implements BlockMeasurer {
  TextPainterBlockMeasurer({
    required this.contentWidth,
    this.scale = 1,
    required this.textScaler,
    this.textDirection = TextDirection.rtl,
    this.fontFamily = AppAssets.cairoFont,
    this.fontFamilyFallback = AppAssets.uiFontFallback,
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

  /// عائلة الخطّ المستخدَمة في القياس — **نفس عائلة الرسم**.
  ///
  /// العارضات (`Text` / `TextField`) ترث `Cairo` من `DefaultTextStyle`
  /// (`app_theme.dart:159`)، أمّا `TextPainter` فمنعزل عن الشجرة **فلا يرث**
  /// — لولا تثبيته هنا لقيس بخط النظام (Segoe UI / Roboto) وتختلف عروض
  /// المحارف ⇒ تختلف نقطة الالتفاف ⇒ **يتغيّر شكل الفقرة عند كل نقرة** (P1).
  final String? fontFamily;

  /// خطوط الاحتياطية — **نفس قائمة الرسم** (`AppAssets.uiFontFallback`).
  ///
  /// تُحمي من ظهور مربعات فارغة (□□□) عند محرف يغيب عن Cairo؛ ولأنّها
  /// تؤثّر في اختيار التحليل البديل، فإن غيابها عن القياس يُعيد اهتزاز
  /// الأسطر في اللغات التي لا يغطّيها Cairo كاملاً.
  final List<String>? fontFamilyFallback;

  /// النمط المستخدَم في القياس — **من المصدر نفسه** الذي يبني نمط العارض،
  /// مع تثبيت عائلة الخط صراحةً.
  ///
  /// تعليقٌ قديم هنا كان يمنع تجاوز عائلة الخط مطلقاً بحجّة «أي حرف يخصمه
  /// القياس دون الرسم يُنتج أسطراً مختلفة». والحجّة سليمة، لكن عكسُها هو
  /// الخاطئ: تركها `null` يجعل القياس **يرفض ميراث الثيم** ولا يملك بديلاً،
  /// فيقيس بخط النظام والعارض يرسم بـCairo — وهذا هو P1 بعينه.
  ///
  /// والحلّ ليس «تمرير الخط من كل موقع استدعاء» (خمسة مواقع، أحدها خارج
  /// نطاق هذا الإصلاح)، بل **تثبيته في المصدر المشترك** [JoodWriterTextStyles.of]
  /// الذي يقرأه القياس والرسم معاً. ما هنا تأكيدٌ إضافيّ لا تجاوز: إن بقي
  /// `fontFamily` غير مُعيَّناً في النمط الأساسي لأي سبب، سقط على نفس القيمتين
  /// الافتراضيتين اللتين يرثهما العارض — فلا يستطيع المساران أن يفترقا.
  ///
  /// و[block.fontFamily] يتصدّر دائماً: خط الكتلة الذي اختاره المستخدم هو
  /// ما يُرسم به وما يُقاس به، فلا يفرض Cairo على نصّ بخطّ آخر.
  TextStyle _styleOf(JoodWriterBlock block) {
    final TextStyle base = JoodWriterTextStyles.of(block, scale: scale);
    return base.copyWith(
      fontFamily: base.fontFamily ?? fontFamily,
      fontFamilyFallback: base.fontFamilyFallback ?? fontFamilyFallback,
    );
  }

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

  /// عرض منطقة الكتابة بعد هامش المؤشّر: `RenderEditable` يخصم
  /// [JoodWriterTextStyles.caretMargin] من عرض كلّ سطرٍ يرسمه ليستديع
  /// موضعاً للمؤشّر، فلو لم يُخصمها المسار الثابت لالتفّت أسطره عند عرضٍ
  /// أوسع بـ3px ويقفز نصّها عند الوقوف عليه. بالخصم من هنا (ومن مربّع
  /// كلّ سطر في الرسم الثابت) يصيران مربّعاً واحداً بالضبط.
  double get _textWidth =>
      math.max(contentWidth - JoodWriterTextStyles.caretMargin * scale, 8.0);

  /// العرض الذي يمنحه العارض **للسطر الأول** من الكتلة.
  double widthOfFirstLine(JoodWriterBlock block) {
    final double used =
        JoodWriterTextStyles.indentPx(block, scale: scale) +
        JoodWriterTextStyles.firstLineIndentPx(block, scale: scale) +
        prefixWidthOf(block);
    return math.max(_textWidth - used, 8.0);
  }

  /// العرض الذي يمنحه العارض **لبقيّة الأسطر** (بعد الأول).
  double widthOfRemainingLines(JoodWriterBlock block) {
    final double used =
        JoodWriterTextStyles.indentPx(block, scale: scale) +
        prefixWidthOf(block);
    return math.max(_textWidth - used, 8.0);
  }

  /// موضع نهاية السطر الأول في [text] كما يرسمه [painter] عند عرضه الضيّق،
  /// **مُقلّداً منطق [_BlockLayout.of] نفسه**: مدى `getLineBoundary` الأول غير
  /// الصفري. يُعيد `0` حين لا يُقسم النصّ (يبدأ بفاصل سطر، أو المدى صفري) —
  /// فيقاس النصّ كاملاً عند العرض الضيّق كما كان يُقاس قبل ازدواج القياس.
  static int _firstLineEnd(String text, TextPainter painter) {
    if (text.codeUnitAt(0) == 0x0A) return 0;
    final TextRange range = painter.getLineBoundary(
      const TextPosition(offset: 0),
    );
    final int end = range.end.clamp(0, text.length);
    return end > 0 ? end : 0;
  }

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
  ///
  /// **قياسٌ على مرحلتين** حين توجد إزاحة لأول سطر: السطر الأول عند
  /// [widthOfFirstLine] ثم بقيّة الأسطر عند [widthOfRemainingLines]، هما
  /// بالضبط عرضَا الالتفاف في محرّر الكتلة (إزاحة السطر الأول `WidgetSpan`
  /// تخصّ سطره وحده — قِيس: السطر الثاني من كتلة مزاحة يلتفّ عند العرض
  /// الكامل لا الضيّق). القياس بأضيق العرض **للأسطر كلّها** كان يجعل النصّ
  /// الثابت يلتفّ التفافاً غير محرّري فيتغيّر شكل الكتلة كلّها عند الوقوف
  /// عليها؛ والقياس بالعرضين يمنع ذلك حرفياً.
  _BlockLayout _measure(JoodWriterBlock block) {
    final String text = block.text;
    if (text.isEmpty) {
      final TextPainter blank = _painterOf(block, ' ')
        ..layout(maxWidth: widthOfRemainingLines(block));
      final double blankLineHeight = blank.preferredLineHeight;
      blank.dispose();
      return _BlockLayout.blank(blankLineHeight);
    }

    final double restWidth = widthOfRemainingLines(block);
    final double firstWidth = widthOfFirstLine(block);

    // الحال الغالبة: بلا إزاحة لأول سطر ⇒ لوحة واحدة عند العرض الكامل.
    if (firstWidth >= restWidth) {
      final TextPainter painter = _painterOf(block, text)
        ..layout(maxWidth: restWidth);
      final double lineHeight = painter.preferredLineHeight;
      final _BlockLayout layout = _BlockLayout.of(painter, text, lineHeight);
      painter.dispose();
      return layout;
    }

    final TextPainter head = _painterOf(block, text)
      ..layout(maxWidth: firstWidth);
    final double lineHeight = head.preferredLineHeight;
    final int split = _firstLineEnd(text, head);
    if (split <= 0 || split >= text.length) {
      // سطرٌ واحد لا يلتفّ عند العرض الضيّق (أو لا يُقسم): يكفي تخطيطه.
      final _BlockLayout layout = _BlockLayout.of(head, text, lineHeight);
      head.dispose();
      return layout;
    }

    // السطر الأول: النصّ حتى نهاية المدى، بطرح الفاصل الصريح إن كان المدى
    // يشمله — نفس ما تفعله [_BlockLayout.of] مع كل سطر.
    String firstLine = text.substring(0, split);
    if (firstLine.isNotEmpty &&
        firstLine.codeUnitAt(firstLine.length - 1) == 0x0A) {
      firstLine = firstLine.substring(0, firstLine.length - 1);
    }
    head.dispose();

    // بقيّة الأسطر عند عرضها الكامل. فاصل السطر المتروك في أول النصّ المتبقّي
    // يتخطّاه [_BlockLayout.of] تلقائياً.
    final String tail = text.substring(split);
    final TextPainter rest = _painterOf(block, tail)
      ..layout(maxWidth: restWidth);
    final List<String> restLines = _BlockLayout.of(
      rest,
      tail,
      lineHeight,
    ).lines;
    rest.dispose();

    return _BlockLayout(
      List<String>.unmodifiable(<String>[firstLine, ...restLines]),
      lineHeight,
    );
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
