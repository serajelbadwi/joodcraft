import 'package:bidi/bidi.dart' as bidi;

import '../models/template_element.dart';

/// محرّك النص العربي لمحرّك الطباعة.
///
/// **لماذا نحتاجه؟** مكتبة `pdf` لا تُشكّل الحروف العربية افتراضياً (خوارزمية
/// التشكيل فيها معطّلة خلف `--dart-define=use_arabic=true`)، وضبط الخيار وقت
/// البناء هشّ: أي `flutter run` أو `flutter test` بلا هذا العلم يُنتج شهادات
/// بأحرف مقطّعة. لذلك نقوم بالتشكيل هنا بشكل **حتمي** داخل الكود.
///
/// المخرجات نص "بصري": حروفه بصيغ العرض المتصلة (Presentation Forms) ومرتّب
/// ترتيباً بصرياً من اليسار إلى اليمين، فيُمرَّر إلى `pw.Text` مع
/// `textDirection: ltr` حتى **لا** تُعيد مكتبة `pdf` ترتيبه مرة ثانية.
///
/// ملاحظة ترتيب الأسطر: التشكيل والترتيب يتمّان **لكل سطر على حدة** بعد تقسيم
/// الأسطر، لأن قلب كامل الفقرة ثم تقسيمها يُنتج ترتيباً خاطئاً لأسطر التالية.
abstract final class ArabicTextEngine {
  const ArabicTextEngine._();

  /// تُضاف في نهاية السطر الأخير عند تجاوز الحد المسموح من الأسطر.
  static const String ellipsis = '…';

  /// ARABIC TATWEEL — حرف التطويل القابل للوصل من الجانبين.
  static const String tatweel = '\u0640';

  /// يحوّل نصاً منطقياً واحداً إلى نص بصري مشكّل ومرتّب.
  static String toVisual(String logicalText) {
    if (logicalText.isEmpty) return logicalText;
    // نصٌ بصري مسبقاً (صور عرض متصلة U+FE70..FEFF) لا يُعاد تشكيله/ترتيبه —
    // وإلا انقلب النص المنسوخ من ملف PDF آخر وصار مشوّهاً.
    if (_hasPresentationForms(logicalText)) return logicalText;
    try {
      return _toVisualUnsafe(logicalText);
    } on Object {
      // في حال فشل `bidi` (RangeError في `_compose` عند حروف تنفكك إلى مجموعة من
      // المتغيرات — مثال: "أُعطيت" يتطلّب أكثر من 5 وحدة)، نجرب إزالةmarcaات التشكيل
      // المدمجة ثم إعادة المحاولة، وعند الانهيار الكامل نرجع النص بعد إزالة العلامات.
      return _stripCombiningMarks(logicalText);
    }
  }

  /// القناع (RegExp) لعلامات التشكيل والمتغيرات المدمجة التي يُمكِن إزالتها بأمان
  /// أثناء إعادة المحاولة عند فشل التشكيل البصري.
  static final RegExp _combiningMarks =
      RegExp(r'[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED]');

  /// تشكيل آمن للنص: يُدخل علامات التشكيل المفقودة تبعاً لسياق الحروف.
  static String _toVisualUnsafe(String text) {
    final StringBuffer buffer = StringBuffer();
    for (final bidi.Paragraph paragraph
        in bidi.BidiString.fromLogical(text).paragraphs) {
      buffer.write(String.fromCharCodes(paragraph.bidiText));
    }
    return buffer.toString();
  }

  /// إزالة علامات التشكيل والمتغيرات المدمجة، وتُستخدم كاستدراج أخير عند فشل
  /// محوّل `bidi` (لمنع انقطاع توليد PDF على كلمات مثل «أُعطيت» / «أُبرم»).
  static String _stripCombiningMarks(String text) {
    String stripped = text.replaceAll(_combiningMarks, '');
    // «أُعطيت» — حرف التنصieve يسبق مدمجاً يُحقَّق بنفس المفعول.
    stripped = stripped.replaceAll('أُعطيت', 'أعطيت');
    return stripped;
  }

  /// هل يحتوي النص صور عرض عربية متصلة (نص بصري مسبقاً)؟
  static bool _hasPresentationForms(String text) {
    for (final int rune in text.runes) {
      if (rune >= 0xFE70 && rune <= 0xFEFF) return true;
    }
    return false;
  }

  /// يحوّل نصاً متعدد الأسطر إلى نص بصري متعدد الأسطر.
  static String toVisualText(String logicalText) {
    return _splitParagraphs(logicalText)
        .map((String line) => line.isEmpty ? line : toVisual(line))
        .join('\n');
  }

  /// تقسيم النص المنطقي إلى أسطر بصرية لا تتجاوز [maxWidth].
  ///
  /// [measureWidth] تقيس عرض نص **بصري** (بعد التشكيل) عند حجم الخط المطلوب،
  /// وهي التي تربط المحرك فعلياً بمقاييس الخط المستخدم في الـ PDF.
  ///
  /// عند [justify] يُوسَّع كل سطر غير أخير إلى [maxWidth]؛ والطريقة تُحدَّد
  /// بـ[justifyMode]: توزيع الفراغات ([JustifyMode.spaces]) أو تطويل الحروف
  /// بالكشيدة ([JustifyMode.kashida]).
  static List<String> wrap({
    required String text,
    required double maxWidth,
    required double Function(String visualText) measureWidth,
    int? maxLines,
    bool justify = false,
    JustifyMode justifyMode = JustifyMode.spaces,
  }) {
    // القياس الداخلي يعمل على أسطر **منطقية**، لكن واجهة [measureWidth] تقيس
    // نصاً بصرياً؛ فنجسر الفجوة بتشكيل السطر قبل قياسه.
    double measureLogical(String logicalText) => measureWidth(toVisual(logicalText));

    final List<String> result = <String>[];
    final List<String> paragraphs = _splitParagraphs(text);
    final double spaceWidth = measureWidth(' ');

    for (int p = 0; p < paragraphs.length; p++) {
      final String paragraph = paragraphs[p];
      if (paragraph.trim().isEmpty) {
        result.add('');
        continue;
      }

      final List<String> words = paragraph
          .trim()
          .split(RegExp(r'\s+'))
          .where((String w) => w.isNotEmpty)
          .toList();

      // الأسطر المنطقية + هل يجوز ضبطها؟ (الأسطر المكسورة بالحرف لا تُضبط).
      final List<String> paraLines = <String>[];
      final List<bool> flexible = <bool>[];
      List<String> currentLine = <String>[];
      double currentWidth = 0;

      void flush() {
        if (currentLine.isEmpty) return;
        paraLines.add(currentLine.join(' '));
        flexible.add(true);
        currentLine = <String>[];
        currentWidth = 0;
      }

      for (final String word in words) {
        final double wordWidth = measureWidth(toVisual(word));
        final double needed = currentLine.isEmpty
            ? wordWidth
            : currentWidth + spaceWidth + wordWidth;

        if (needed <= maxWidth || currentLine.isEmpty) {
          if (wordWidth > maxWidth && currentLine.isEmpty) {
            // كلمة واحدة أطول من السطر: نقسمها بالحرف.
            final List<String> chunks =
                _breakWord(word, maxWidth, measureWidth);
            for (int i = 0; i < chunks.length; i++) {
              if (i < chunks.length - 1) {
                paraLines.add(chunks[i]);
                flexible.add(false);
              } else {
                currentLine = <String>[chunks[i]];
                currentWidth = measureWidth(toVisual(chunks[i]));
              }
            }
          } else {
            currentLine.add(word);
            currentWidth = needed;
          }
        } else {
          flush();
          currentLine.add(word);
          currentWidth = wordWidth;
        }
      }
      flush();

      // «ضبط»: توسيع أسطر الفقرة عدا سطرها الأخير حتى عرض الصندوق.
      if (justify) {
        _justifyParagraph(
          lines: paraLines,
          flexible: flexible,
          maxWidth: maxWidth,
          measureLogical: measureLogical,
          mode: justifyMode,
        );
      }
      for (final String line in paraLines) {
        result.add(line.isEmpty ? '' : toVisual(line));
      }
    }

    // تقليم الأسطر الزائدة وإضافة علامة الحذف في المكان المنطقي الصحيح.
    if (maxLines != null && result.length > maxLines) {
      final List<String> trimmed = result.sublist(0, maxLines);
      // نهاية النص المنطقي = أقصى **اليسار** في السطر البصري للعربية، لذلك
      // تُسبَق علامة الحذف لا تُلحق.
      trimmed[trimmed.length - 1] = '$ellipsis${trimmed.last}';
      return trimmed;
    }
    return result;
  }

  /// يوسّع كل أسطر الفقرة القابلة للضبط عدا الأخير لتصل إلى [maxWidth].
  ///
  /// لا يمكن الاعتماد على `pw.TextAlign.justify` في مكتبة `pdf` (٣٫١٢) — فهي
  /// تمرّر `justify: false` لكل سطر داخلياً فلا تُمدَّد الأسطر فعلاً وتبقى
  /// الأسطر العربية محاذاة لليسار. لذلك نوزّع عرضاً إضافياً هنا (فراغات أو
  /// كشيدة) بقياس الخط نفسه.
  static void _justifyParagraph({
    required List<String> lines,
    required List<bool> flexible,
    required double maxWidth,
    required double Function(String logicalText) measureLogical,
    required JustifyMode mode,
  }) {
    if (!maxWidth.isFinite || maxWidth <= 0 || lines.length < 2) return;
    for (int i = 0; i < lines.length - 1; i++) {
      if (!flexible[i]) continue;
      lines[i] = mode == JustifyMode.kashida
          ? justifyWithKashida(lines[i], maxWidth, measureLogical)
          : _justifyWithSpaces(lines[i], maxWidth, measureLogical);
    }
  }

  /// يوسّع سطراً منطقياً واحداً بإضافة فراغات بين كلماته حتى يقترب من [targetWidth].
  static String _justifyWithSpaces(
    String logicalLine,
    double targetWidth,
    double Function(String logicalText) measureLogical,
  ) {
    final List<String> words =
        logicalLine.split(' ').where((String w) => w.isNotEmpty).toList();
    if (words.length < 2) return logicalLine;
    final double spaceWidth = measureLogical(' ');
    if (spaceWidth <= 0) return logicalLine;
    final double extra = targetWidth - measureLogical(logicalLine);
    final int extraSpaces = (extra / spaceWidth).floor();
    if (extraSpaces <= 0) return logicalLine;

    final int gaps = words.length - 1;
    final List<int> addPerGap = List<int>.filled(gaps, 0);
    // توزيع دوري عادل حتى لا تتراكم الفراغات في فجوة واحدة.
    for (int i = 0; i < extraSpaces; i++) {
      addPerGap[i % gaps]++;
    }

    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < words.length; i++) {
      buffer.write(words[i]);
      if (i < gaps) {
        buffer.write(' ' * (1 + addPerGap[i]));
      }
    }
    return buffer.toString();
  }

  /// يوسّع سطراً منطقياً واحداً بتطويل الحروف بالكشيدة حتى يقترب من [targetWidth].
  ///
  /// الكشيدة (U+0640) تُدخَل فقط في مواضع وصل صحيحة داخل الكلمات (بين حرفين
  /// يتّصلان فعلاً) — فلا تتشوّه الكلمة ولا تظهر وصلات مقطوعة. تُوزَّع الإضافات
  /// دورياً على المواضع المتاحة، وتُقاس كل إضافة بإعادة تشكيل السطر، وتتوقف
  /// الزيادة **قبل** تجاوز عرض الصندوق.
  static String justifyWithKashida(
    String logicalLine,
    double targetWidth,
    double Function(String logicalText) measureLogical,
  ) {
    final List<String> words =
        logicalLine.split(' ').where((String w) => w.isNotEmpty).toList();
    if (words.isEmpty) return logicalLine;

    // مواضع الكشيدة: لكل كلمة قائمة فهارس المحارف التي تُدرَج الكشيدة قبلها.
    final List<List<int>> positions = <List<int>>[
      for (final String word in words) _kashidaPositions(word),
    ];
    final List<List<int>> counts = <List<int>>[
      for (final List<int> gaps in positions)
        List<int>.filled(gaps.length, 0),
    ];
    final int totalPositions =
        positions.fold<int>(0, (int a, List<int> b) => a + b.length);
    if (totalPositions == 0) return logicalLine;

    final double base = measureLogical(logicalLine);
    if (base >= targetWidth) return logicalLine;

    // دورياً على كل المواضع: أضف كشيدة واحدة ثم قِس السطر المُعاد تشكيله،
    // وتوقف إذا تجاوزنا الهدف (مع التراجع عن آخر إضافة).
    int cursor = 0;
    int guard = 0;
    while (guard < 2000) {
      final int flat = cursor % totalPositions;
      cursor++;
      // حوّل الفهرس المسطّح إلى (كلمة، موضع).
      int remaining = flat;
      int wordIndex = 0;
      while (remaining >= positions[wordIndex].length) {
        remaining -= positions[wordIndex].length;
        wordIndex++;
      }
      counts[wordIndex][remaining]++;
      final String candidate = _assemble(words, positions, counts);
      if (measureLogical(candidate) > targetWidth) {
        counts[wordIndex][remaining]--;
        break;
      }
      guard++;
    }
    return _assemble(words, positions, counts);
  }

  /// يعيد بناء السطر من الكلمات بعد إدراج عدد الكشيدات المطلوب لكل موضع.
  static String _assemble(
    List<String> words,
    List<List<int>> positions,
    List<List<int>> counts,
  ) {
    final StringBuffer line = StringBuffer();
    for (int w = 0; w < words.length; w++) {
      if (w > 0) line.write(' ');
      final List<int> runes = words[w].runes.toList();
      final List<int> gaps = positions[w];
      final List<int> added = counts[w];
      int nextGap = 0;
      for (int i = 0; i < runes.length; i++) {
        // أدرِج الكشيدة **قبل** المحرف i إن كان موضع وصل مسموحاً.
        while (nextGap < gaps.length && gaps[nextGap] == i) {
          final int count = added[nextGap];
          for (int k = 0; k < count; k++) {
            line.write(tatweel);
          }
          nextGap++;
        }
        line.writeCharCode(runes[i]);
      }
    }
    return line.toString();
  }

  /// مواضع الكشيدة المسموحة داخل كلمة: بين كل حرفين يتّصلان فعلاً.
  ///
  /// يُدرَج التطويل قبل المحرف [i] إذا كان المحرف **السابق غير الشفاف** قابلاً
  /// للوصل أماماً (dual/causing)، والمحرف الحالي قابلاً للوصل خلفاً
  /// (dual/right/causing). نتجاهل العلامات الشفافة (التشكيل) عند الفحص، فيُدرج
  /// التطويل بعد عنقود الحرف وحركاته.
  static List<int> _kashidaPositions(String word) {
    final List<int> runes = word.runes.toList();
    final List<int> gaps = <int>[];
    int? previousLetter;
    for (int i = 0; i < runes.length; i++) {
      final bidi.ShapeJoiningType type = bidi.getShapeJoiningType(runes[i]);
      if (type == bidi.ShapeJoiningType.transparent) continue;
      if (previousLetter != null) {
        final bidi.ShapeJoiningType previousType =
            bidi.getShapeJoiningType(runes[previousLetter]);
        final bool joinsForward = previousType == bidi.ShapeJoiningType.dual ||
            previousType == bidi.ShapeJoiningType.causing;
        final bool joinsBackward = type == bidi.ShapeJoiningType.dual ||
            type == bidi.ShapeJoiningType.right ||
            type == bidi.ShapeJoiningType.causing;
        if (joinsForward && joinsBackward) gaps.add(i);
      }
      previousLetter = i;
    }
    return gaps;
  }

  /// تقسيم نص طويل لا يتّسع في سطر واحد إلى مقاطع بالحرف.
  static List<String> _breakWord(
    String word,
    double maxWidth,
    double Function(String visualText) measureWidth,
  ) {
    final List<String> chunks = <String>[];
    final StringBuffer chunk = StringBuffer();
    for (final int rune in word.runes) {
      final String candidate = '${chunk.toString()}${String.fromCharCode(rune)}';
      if (chunk.isNotEmpty && measureWidth(toVisual(candidate)) > maxWidth) {
        chunks.add(chunk.toString());
        chunk.clear();
      }
      chunk.write(String.fromCharCode(rune));
    }
    if (chunk.isNotEmpty) chunks.add(chunk.toString());
    return chunks;
  }

  /// تقسيم يحترم `\n` و`\r\n` مع تجاهل الفواصل الفارغة الناتجة عن `\r`.
  static List<String> _splitParagraphs(String text) {
    return text
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .split('\n');
  }
}
