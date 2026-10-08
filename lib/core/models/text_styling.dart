import '../pdf/pdf_font_catalog.dart';

/// **تنسيق جزئي** يُطبَّق على مدى محدَّد من الحروف داخل عنصر نصّي واحد.
///
/// النموذج «تراكبي» (TIERED): كل حقل فيه اختياري، والقيمة المفقودة تعني
/// «ورِث من نمط العنصر الأساسي». وهكذا يبقى `TextElement` نفسه هو مصدر حقيقة
/// للخط واللون والحجم، وتضيف النطاقات ما يختلف عنه فقط — فلا يتكرّر التنسيق
/// في كل حرف، ولا ينكسر أي قالب قديم (غياب `spans` في الـ JSON يعني بلا تنسيق
/// جزئي، أي السلوك القديم حرفياً).
///
/// الإزاحات بوحدات **UTF-16** (فهرسة `String` في دارت) وهي نفسها التي يستعملها
/// `TextSelection` في فلاتر، فلا حاجة لتحويل بين عالمين.
final class StyledTextSpan {
  const StyledTextSpan({
    required this.start,
    required this.end,
    this.family,
    this.customFont,
    this.weight,
    this.italic,
    this.underline,
    this.size,
    this.colorHex,
    this.backgroundHex,
  });

  /// بداية المدى (**شاملة**).
  final int start;

  /// نهاية المدى (**غير شاملة**) — قراراً واحداً مع `TextSelection.end`.
  final int end;

  /// عائلة خط مستقلة تحلّ محل عائلة العنصر.
  final PdfFontFamily? family;

  /// خط مخصص رفعه المستخدم (يتقدّم على [family]).
  final String? customFont;

  /// سماكة مستقلة (عريض/متوسط/عادي).
  final PdfFontWeight? weight;

  /// مائل؟ `null` = يرث من العنصر الأساسي.
  final bool? italic;

  /// خط سفلي؟ `null` = يرث من العنصر الأساسي.
  final bool? underline;

  /// حجم مستقل بوحدات التصميم.
  final double? size;

  /// لون النص المستقل (‎`#RRGGBB` أو ‎`#AARRGGBB`‎).
  final String? colorHex;

  /// خلفية حروف مستقلة.
  final String? backgroundHex;

  /// هل يحمل أي تدخّل أصلاً؟ (المدى الفارغ يُرفض في [normalize])
  bool get isBase =>
      family == null &&
      customFont == null &&
      weight == null &&
      italic == null &&
      underline == null &&
      size == null &&
      colorHex == null &&
      backgroundHex == null;

  /// يعيد المدى بعد تطبيق [transform] على إزاحتيه ثم تقليم الناتج لـ[length].
  StyledTextSpan _map(int Function(int offset) mapStart, int Function(int offset) mapEnd, int length) {
    int s = mapStart(start).clamp(0, length);
    int e = mapEnd(end).clamp(0, length);
    if (e < s) {
      final int swap = s;
      s = e;
      e = swap;
    }
    return StyledTextSpan(
      start: s,
      end: e,
      family: family,
      customFont: customFont,
      weight: weight,
      italic: italic,
      underline: underline,
      size: size,
      colorHex: colorHex,
      backgroundHex: backgroundHex,
    );
  }

  StyledTextSpan scaled(double factor) => StyledTextSpan(
        start: start,
        end: end,
        family: family,
        customFont: customFont,
        weight: weight,
        italic: italic,
        underline: underline,
        size: size == null ? null : (size! * factor).clamp(1, 400).toDouble(),
        colorHex: colorHex,
        backgroundHex: backgroundHex,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        's': start,
        'e': end,
        if (family != null) 'font': family!.jsonValue,
        if (customFont != null) 'font_custom': customFont,
        if (weight != null) 'weight': weight!.jsonValue,
        if (italic != null) 'italic': italic,
        if (underline != null) 'underline': underline,
        if (size != null) 'size': size,
        if (colorHex != null) 'color': colorHex,
        if (backgroundHex != null) 'background': backgroundHex,
      };

  static StyledTextSpan? fromJson(Object? json) {
    if (json is! Map) return null;
    final Object? rawStart = json['s'] ?? json['start'];
    final Object? rawEnd = json['e'] ?? json['end'];
    if (rawStart is! num || rawEnd is! num) return null;
    final int start = rawStart.toInt();
    final int end = rawEnd.toInt();
    if (end <= start) return null;
    return StyledTextSpan(
      start: start,
      end: end,
      family: json['font'] is String ? PdfFontFamily.fromJson(json['font'] as String?) : null,
      customFont: (json['font_custom'] as String?)?.trim().isEmpty ?? true
          ? null
          : (json['font_custom'] as String).trim(),
      weight: json['weight'] is String
          ? PdfFontWeight.fromJson(json['weight'])
          : null,
      italic: json['italic'] is bool ? json['italic'] as bool : null,
      underline: json['underline'] is bool ? json['underline'] as bool : null,
      size: json['size'] is num ? (json['size'] as num).toDouble() : null,
      colorHex: json['color'] as String?,
      backgroundHex: json['background'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is StyledTextSpan &&
      other.start == start &&
      other.end == end &&
      other.family == family &&
      other.customFont == customFont &&
      other.weight == weight &&
      other.italic == italic &&
      other.underline == underline &&
      other.size == size &&
      other.colorHex == colorHex &&
      other.backgroundHex == backgroundHex;

  @override
  int get hashCode => Object.hash(start, end, family, customFont, weight, italic,
      underline, size, colorHex, backgroundHex);

  // ==========================================================================
  //                              عمليات المجموعة
  // ==========================================================================

  /// **يطهّر قائمة النطاقات** قبل العرض أو الحفظ:
  ///
  /// 1. يرمي النطاقات الفارغة أو المقلوبة أو خارج حدود النص.
  /// 2. يقيّم الإزاحات داخل حدود [textLength] (وبلا قطع لأزواج الـ surrogate).
  /// 3. يرتّبها، وعند التداخل **اللاحق يسبق** — أي أن تحديد المستخدم الأحدث
  ///    يطغى على ما قبله تماماً كما في محررات Word.
  ///
  /// الناتج مضمون: متصاعد، غير متداخل، وضمن الحدود.
  static List<StyledTextSpan> normalize(
    List<StyledTextSpan> spans,
    int textLength,
  ) {
    if (spans.isEmpty || textLength <= 0) return const <StyledTextSpan>[];

    final List<StyledTextSpan> cleaned = <StyledTextSpan>[];
    for (final StyledTextSpan span in spans) {
      final int start = span.start.clamp(0, textLength);
      final int end = span.end.clamp(0, textLength);
      if (end <= start) continue;
      cleaned.add(StyledTextSpan(
        start: start,
        end: end,
        family: span.family,
        customFont: span.customFont,
        weight: span.weight,
        italic: span.italic,
        underline: span.underline,
        size: span.size,
        colorHex: span.colorHex,
        backgroundHex: span.backgroundHex,
      ));
    }
    if (cleaned.isEmpty) return const <StyledTextSpan>[];

    // فرز تصاعدي: بالبداية ثم بالنهاية.
    cleaned.sort((StyledTextSpan a, StyledTextSpan b) =>
        a.start != b.start ? a.start.compareTo(b.start) : a.end.compareTo(b.end));

    // قصّ التداخل: ما يغطّيه المدى السابق يُمنع عن التالي، واللاحق هو الأسبق
    // لالتقاط حدود التحديد الأحدث.
    final List<StyledTextSpan> result = <StyledTextSpan>[];
    int covered = 0;
    for (final StyledTextSpan span in cleaned) {
      final int start = span.start < covered ? covered : span.start;
      if (start >= span.end) continue;
      covered = span.end;
      if (start == span.start) {
        result.add(span);
      } else {
        result.add(StyledTextSpan(
          start: start,
          end: span.end,
          family: span.family,
          customFont: span.customFont,
          weight: span.weight,
          italic: span.italic,
          underline: span.underline,
          size: span.size,
          colorHex: span.colorHex,
          backgroundHex: span.backgroundHex,
        ));
      }
    }
    return result;
  }

  /// يعيد النطاقات بعد تأويلها لـ[length] من دون تداخل.
  static List<StyledTextSpan> fromJsonList(Object? json, int textLength) {
    if (json is! List) return const <StyledTextSpan>[];
    final List<StyledTextSpan> spans = <StyledTextSpan>[];
    for (final Object? item in json) {
      final StyledTextSpan? span = StyledTextSpan.fromJson(item);
      if (span != null) spans.add(span);
    }
    return normalize(spans, textLength);
  }

  static List<Map<String, dynamic>> toJsonList(List<StyledTextSpan> spans, int textLength) =>
      <Map<String, dynamic>>[
        for (final StyledTextSpan span in normalize(spans, textLength))
          span.toJson(),
      ];

  /// يُزاح المدى ليطابق نصاً **عُدِّل** — يُستدعى بعد التحرير المباشر.
  ///
  /// الخوارزمية تحدّد منطقة التعديل بأقصر بادئة وأقصر لاحقة متطابقتين بين
  /// [oldText] و[newText]، ثم:
  ///
  /// * ما انتهى قبل التعديل يبقى كما هو.
  /// * ما بدأ بعد التعديل يزيح بمقدار فارق الطول.
  /// * ما يقع داخل منطقة التعديل يتمدد/ينكمش معها فلا ينفلت عن كلماته.
  static List<StyledTextSpan> remapAfterEdit({
    required String oldText,
    required String newText,
    required List<StyledTextSpan> spans,
  }) {
    if (spans.isEmpty) return const <StyledTextSpan>[];
    if (oldText == newText) return normalize(spans, newText.length);

    final int oldLength = oldText.length;
    final int newLength = newText.length;

    int prefix = 0;
    final int limit = oldLength < newLength ? oldLength : newLength;
    while (prefix < limit && oldText.codeUnitAt(prefix) == newText.codeUnitAt(prefix)) {
      prefix++;
    }
    // لا نتجاوز منتصف النص حتى لا يبتلع الاحتفاظ باللاحقة منطقة التعديل.
    int suffix = 0;
    while (suffix < limit - prefix &&
        oldText.codeUnitAt(oldLength - 1 - suffix) ==
            newText.codeUnitAt(newLength - 1 - suffix)) {
      suffix++;
    }
    // لا نقطع زوجاً عند حدّ اللاحقة.
    while (suffix > 0 &&
        _isLowSurrogate(oldText.codeUnitAt(oldLength - suffix)) &&
        _isHighSurrogate(oldText.codeUnitAt(oldLength - suffix - 1))) {
      suffix--;
    }

    final int delta = newLength - oldLength;
    final int oldEnd = oldLength - suffix;
    final int newEnd = newLength - suffix;

    int mapStart(int offset) {
      if (offset < prefix) return offset;
      if (offset >= oldEnd) return offset + delta;
      return prefix;
    }

    int mapEnd(int offset) {
      if (offset <= prefix) return offset;
      if (offset >= oldEnd) return offset + delta;
      return newEnd;
    }

    final List<StyledTextSpan> mapped = <StyledTextSpan>[
      for (final StyledTextSpan span in spans)
        span._map(mapStart, mapEnd, newLength),
    ];
    return normalize(mapped, newLength);
  }

  static bool _isHighSurrogate(int unit) => unit >= 0xD800 && unit <= 0xDBFF;
  static bool _isLowSurrogate(int unit) => unit >= 0xDC00 && unit <= 0xDFFF;
}

/// **تنسيق مُحلًى** لجزء واحد من النص: مدى + قيم الخيارات بعد دمج كل ما يغطّيه.
///
/// ينتج عن [splitStyledRuns] دائماً تغطية كاملة بلا فجوات ولا تداخل، وهو ما
/// يستهلكه مرسما فلاتر والـ PDF معاً — فال.segmentation واحدة في الطرفين، فيكون
/// التصدير مطابقاً للوحة بالضرورة لا بالصدفة.
final class ResolvedSpanStyle {
  const ResolvedSpanStyle({
    this.family,
    this.customFont,
    this.weight,
    this.italic = false,
    this.underline = false,
    this.size,
    this.colorHex,
    this.backgroundHex,
  });

  final PdfFontFamily? family;
  final String? customFont;
  final PdfFontWeight? weight;
  final bool italic;
  final bool underline;
  final double? size;
  final String? colorHex;
  final String? backgroundHex;

  /// لم يُطبَّق عليه أي تدخّل: يتبع نمط العنصر الأساسي حرفياً.
  bool get isBase =>
      family == null &&
      customFont == null &&
      weight == null &&
      !italic &&
      !underline &&
      size == null &&
      colorHex == null &&
      backgroundHex == null;

  /// يدمج [span] فوق هذا التنسيق: حقوله غير الفارغة تطغى، والفارغة تُورَّث.
  ResolvedSpanStyle merge(StyledTextSpan span) => ResolvedSpanStyle(
        family: span.family ?? family,
        customFont: span.customFont ?? customFont,
        weight: span.weight ?? weight,
        italic: span.italic ?? italic,
        underline: span.underline ?? underline,
        size: span.size ?? size,
        colorHex: span.colorHex ?? colorHex,
        backgroundHex: span.backgroundHex ?? backgroundHex,
      );

  @override
  bool operator ==(Object other) =>
      other is ResolvedSpanStyle &&
      other.family == family &&
      other.customFont == customFont &&
      other.weight == weight &&
      other.italic == italic &&
      other.underline == underline &&
      other.size == size &&
      other.colorHex == colorHex &&
      other.backgroundHex == backgroundHex;

  @override
  int get hashCode => Object.hash(family, customFont, weight, italic, underline,
      size, colorHex, backgroundHex);
}

/// قطعة نصّ واحدة لها تنسيق واحد موحّد — وحدة الرسم في فلاتر وفي الـ PDF.
final class StyledTextRun {
  const StyledTextRun({
    required this.start,
    required this.end,
    required this.style,
  });

  final int start;
  final int end;
  final ResolvedSpanStyle style;

  String textOf(String source) => source.substring(start, end);

  bool get isBase => style.isBase;
}

/// يقسّم [text] إلى قطع متجاورة، كل قطعة بتنسيق واحد.
///
/// الناتج **يغطّي [text] بالكامل** من ‎0‎ إلى ‎text.length‎ بلا فراغات وبلا
/// تداخل؛ المواقع التي لا يغطّيها أي نطاق تحصل على [ResolvedSpanStyle] فارغ
/// (أي نمط العنصر الأساسي).
List<StyledTextRun> splitStyledRuns(
  String text,
  List<StyledTextSpan> spans, {
  ResolvedSpanStyle base = const ResolvedSpanStyle(),
}) {
  if (text.isEmpty) return const <StyledTextRun>[];
  if (spans.isEmpty) {
    return <StyledTextRun>[
      StyledTextRun(start: 0, end: text.length, style: base),
    ];
  }

  final List<StyledTextSpan> normalized =
      StyledTextSpan.normalize(spans, text.length);

  // حلٌّ بسيط وسليم لطول الشهادات: نُحلّ كل وحدة، ثم ندمج المتتاليات المتطابقة.
  // النطاقات مرتّبة أصلاً، فالحلّ خطي ولا يُكلَّف.
  final List<ResolvedSpanStyle> perUnit =
      List<ResolvedSpanStyle>.filled(text.length, base);
  for (final StyledTextSpan span in normalized) {
    final ResolvedSpanStyle merged = base.merge(span);
    for (int i = span.start; i < span.end && i < text.length; i++) {
      perUnit[i] = merged;
    }
  }

  final List<StyledTextRun> runs = <StyledTextRun>[];
  int runStart = 0;
  for (int i = 1; i <= text.length; i++) {
    final bool boundary =
        i == text.length || perUnit[i] != perUnit[i - 1];
    if (!boundary) continue;
    // لا نبدأ قطعة داخل زوج surrogate.
    if (i < text.length && _isLow(text.codeUnitAt(i))) continue;
    runs.add(StyledTextRun(start: runStart, end: i, style: perUnit[runStart]));
    runStart = i;
  }
  if (runStart < text.length) {
    runs.add(StyledTextRun(
        start: runStart, end: text.length, style: perUnit[runStart]));
  }
  return runs;
}

bool _isLow(int unit) => unit >= 0xDC00 && unit <= 0xDFFF;
