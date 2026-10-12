import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../domain/jood_writer_block.dart';

/// أنماط الخطوط لكتل «جود كاتب» — **مصدر واحد** يقرأه كلٌّ من القياس (التدفّق)
/// والرسم (المحرّر والمعاينة)، فلا يختلف ارتفاع السطر المحسوب عن المرسوم.
abstract final class JoodWriterTextStyles {
  /// كثافة البكسل لكل مليمتر — **المصدر الوحيد** لتحويل الهوامش والإزاحات.
  ///
  /// مأخوذة من الدقة المرجعية 96dpi بالضبط (96 ÷ 25.4 ≈ 3.7795)، فتظهر الورقة
  /// على الشاشة **بحجمها الورقي الفعلي** (A4 = 793.7 × 1122.5 بكسل منطقي).
  static const double pxPerMm = 96 / 25.4;

  /// لون الكتابة الافتراضي: أسود ناصع تماماً لكل الفقرات والعناوين.
  static const Color defaultTextColor = Colors.black;

  /// **هامش المؤشّر**: المسافة التي يخصمها `RenderEditable` من عرض سطرّه
  /// ليستديع موضعاً لرسم المؤشّر عند نهاية السطر —
  /// `_kCaretGap (1.0) + cursorWidth (2.0) = 3px` (ولم تُغيَّر اللوحة
  /// `cursorWidth` فهو افتراضي).
  ///
  /// أثره أنّ أسطر المحرّر كلّها تلتفّ عند `عرض الحقل − 3` ويقفز نصّها 3px
  /// (‏0.79mm) يساراً عمّا يرسمه المسار الثابت عند حافة المحتوى — أي أنّ
  /// النصّ «يتحرّك» عند الوقوف عليه.
  ///
  /// **الحشوة في مصدرٍ واحد، تخصم من المسار الثابت لا من المحرّر**: المحرّر
  /// يبقى بعرض المحتوى كاملاً (لا نمدّه ولا نُزّيه) بينما يخصم كلّ من
  /// [TextPainterBlockMeasurer.widthOfFirstLine] و
  /// [TextPainterBlockMeasurer.widthOfRemainingLines] هذه القيمة، ويخصمها
  /// الرسم الثابت من مربّع كلّ سطر (اللّوحات والمعاينة معاً). فمربّع
  /// الالتفاف في المسارين واحد بالضبط — بأيّ محاذاة — وتتطابق الحافة
  /// حرفياً ولا يتحرّك السطر عند الوقوف عليه أو مغادرته.
  static const double caretMargin = 3.0;

  /// أحجام الخط الافتراضية لكل نوع كتلة.
  static const double _h1Size = 24;
  static const double _h2Size = 18;
  static const double _paragraphSize = 13.5;

  /// الحجم الفعلي لخط الكتلة (مخصص أو افتراضي للنوع).
  static double fontSizeOf(JoodWriterBlock block) {
    if (block.fontSize != null) return block.fontSize!;
    switch (block.kind) {
      case JoodWriterBlockKind.heading1:
        return _h1Size;
      case JoodWriterBlockKind.heading2:
        return _h2Size;
      case JoodWriterBlockKind.paragraph:
      case JoodWriterBlockKind.bullet:
      case JoodWriterBlockKind.numbered:
        return _paragraphSize;
    }
  }

  /// ## عائلة الخط (P1)
  ///
  /// هذا النمط **هو** مصدر الخط الوحيد للقياس والرسم معاً، ولذلك يحمله صريحاً
  /// لا بالميراث:
  ///
  /// * **العارض** (`Text` / `TextField`) يرث `DefaultTextStyle` الذي يضع
  ///   `ThemeData.fontFamily: AppAssets.cairoFont` + `fontFamilyFallback`
  ///   (`app_theme.dart:159‑162`) — فإذا حمل النمط `fontFamily: null` بقي
  ///   ميراثه سليماً لا بأس به.
  /// * **المُقاس** `TextPainter` **مُنعزل عن الشجرة فلا يرث شيئاً**: `null`
  ///   عنده تعني أن يسقط المحرّك على خطّه الافتراضي (Segoe UI على ويندوز،
  ///   Roboto على أندرويد)، وعروض المحارف تختلف جذّاً عن Cairo ⇒ تختلف نقطة
  ///   الالتفاف ⇒ يختلف عدد الأسطر ⇒ **يتغيّر شكل الفقرة عند كل نقرة**.
  ///
  /// فتثبيت القيمتين هنا يجعل خطّي القياس والرسم **متطابقين بالبناء** على كل
  /// المسارات الخمسة (المُقاس، الكتلة الساكنة، المحرّر، صفحات العرض، الطباعة)
  /// دون أن يلزم أي موقع استدعاء أن يمرّرهما — فلا يستطيع أحد أن ينسى أحدهما.
  ///
  /// خطّ cairoFont يغطي العربية واللاتينية؛ وأي محرف يغيب عنه يسقط على
  /// [AppAssets.uiFontFallback] (محزومة داخل الحزمة، بلا شبكة وقت التشغيل).
  static TextStyle of(JoodWriterBlock block, {double scale = 1}) {
    TextStyle base;
    switch (block.kind) {
      case JoodWriterBlockKind.heading1:
        base = TextStyle(
          fontSize: _h1Size * scale,
          fontWeight: FontWeight.w700,
        );
        break;
      case JoodWriterBlockKind.heading2:
        base = TextStyle(
          fontSize: _h2Size * scale,
          fontWeight: FontWeight.w700,
        );
        break;
      case JoodWriterBlockKind.paragraph:
      case JoodWriterBlockKind.bullet:
      case JoodWriterBlockKind.numbered:
        base = TextStyle(fontSize: _paragraphSize * scale);
        break;
    }

    return base.copyWith(
      // خطّ الرسم والمُقاس واحد (P1): خط الكتلة المختار صراحةً إن وُجد، وإلا
      // Cairo — نفس ما يرثه العارض من الثيم. راجع توثيق [of].
      fontFamily: block.fontFamily ?? AppAssets.cairoFont,
      fontFamilyFallback: AppAssets.uiFontFallback,
      fontSize: block.fontSize != null ? block.fontSize! * scale : null,
      // أسود ناصع افتراضياً؛ لون مخصّص فقط إذا اختاره المستخدم صراحةً.
      color: block.fontColor ?? defaultTextColor,
      fontWeight: block.isBold ? FontWeight.bold : base.fontWeight,
      fontStyle: block.isItalic ? FontStyle.italic : null,
      // تسطير و/أو شطب — يُدمجان معاً إن اجتمعتا (كما في وورد).
      decoration: (block.isUnderline || block.isStrikethrough)
          ? TextDecoration.combine(<TextDecoration>[
              if (block.isUnderline) TextDecoration.underline,
              if (block.isStrikethrough) TextDecoration.lineThrough,
            ])
          : null,
      backgroundColor: block.highlightColor,
      height: block.lineSpacing,
      // **تباعد الحروف مُثبَّت صفر هنا** لأنّ كل نمطٍ يُدمج مع سياقه ويوارث ما
      // لم يُحدَّد فيه: النصّ الثابت يرث `letterSpacing: 0.25` من `bodyMedium`
      // عبر `DefaultTextStyle`، ومحرّر الحقول يرث `letterSpacing: 0.5` من
      // `bodyLarge` عبر `InputDecorator`، والقياس بـ`TextPainter` لا يرث شيئاً.
      // لولا تثبيته هنا لاحتسب كلٌّ من المسارين عرضاً مختلفاً للحرف الواحد
      // (13.75 / 14.0 / 13.5 بحجم 13.5) فتختلف حدود التفاف الأسطر بين
      // المحرّر والنصّ الثابت ويبدو النصّ **متحرّكاً** عند الوقوف عليه.
      letterSpacing: 0,
    );
  }

  /// عرض الإزاحة الكاملة للقطة بالبكسل.
  static double indentPx(JoodWriterBlock block, {double scale = 1}) =>
      block.indentCm * 10 * pxPerMm * scale;

  /// عرض المسافة البادئة للسطر الأول بالبكسل.
  ///
  /// **في القياس** يُخصم من عرض السطر كله: قياسٌ محافظ لا يسمح أبداً بتجاوز
  /// ارتفاع الكتلة المحسوب ولا بفيض إطار الصفحة.
  ///
  /// **في الرسم** يُطبَّق على السطر الأول وحده: في المحرّر عبر `WidgetSpan` واحد
  /// في أوله، وفي صفحات العرض على أول سطر من الشريحة. الأسطر التالية تبدأ من
  /// حافة الهامش (بعد إزاحة الفقرة العامّة [indentPx] إن وُجدت).
  static double firstLineIndentPx(JoodWriterBlock block, {double scale = 1}) =>
      block.firstLineIndentCm * 10 * pxPerMm * scale;

  /// عرض مقدمة القائمة (• أو 12.) بالبكسل — يُخصم من عرض السطر في القياس
  /// والرسم معاً حتى لا يختلف الالتفاف بين المحرّر والمعاينة.
  static double listPrefixWidth(JoodWriterBlock block, {double scale = 1}) {
    switch (block.kind) {
      case JoodWriterBlockKind.bullet:
        return fontSizeOf(block) * 1.5 * scale;
      case JoodWriterBlockKind.numbered:
        return fontSizeOf(block) * 2.5 * scale;
      case JoodWriterBlockKind.heading1:
      case JoodWriterBlockKind.heading2:
      case JoodWriterBlockKind.paragraph:
        return 0;
    }
  }

  /// المسافة قبل الكتلة (تُهمَل في رأس الصفحة).
  static double spacingBefore(JoodWriterBlockKind kind, {double scale = 1}) {
    switch (kind) {
      case JoodWriterBlockKind.heading1:
        return 4 * scale;
      case JoodWriterBlockKind.heading2:
        return 14 * scale;
      case JoodWriterBlockKind.paragraph:
      case JoodWriterBlockKind.bullet:
      case JoodWriterBlockKind.numbered:
        return 8 * scale;
    }
  }

  /// المسافة بعد الكتلة.
  static double spacingAfter(JoodWriterBlockKind kind, {double scale = 1}) {
    switch (kind) {
      case JoodWriterBlockKind.heading1:
        return 16 * scale;
      case JoodWriterBlockKind.heading2:
        return 10 * scale;
      case JoodWriterBlockKind.paragraph:
      case JoodWriterBlockKind.bullet:
      case JoodWriterBlockKind.numbered:
        return 8 * scale;
    }
  }

  /// محاذاة فلوتر النص من محاذاة الكتلة.
  static TextAlign textAlign(JoodWriterAlign align) {
    switch (align) {
      case JoodWriterAlign.start:
        return TextAlign.start;
      case JoodWriterAlign.center:
        return TextAlign.center;
      case JoodWriterAlign.end:
        return TextAlign.end;
      case JoodWriterAlign.justify:
        return TextAlign.justify;
    }
  }
}
