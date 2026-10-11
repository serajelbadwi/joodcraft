import 'package:flutter/material.dart';

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

  /// نمط الكتلة. [scale] مضاعف حجم يُستخدم لتصغير الخطوط مع تصغير الورقة في
  /// المعاينة (1 = الحجم الطبيعي للتحرير).
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
      fontFamily: block.fontFamily,
      fontSize: block.fontSize != null ? block.fontSize! * scale : null,
      // أسود ناصع افتراضياً؛ لون مخصّص فقط إذا اختاره المستخدم صراحةً.
      color: block.fontColor ?? defaultTextColor,
      fontWeight: block.isBold ? FontWeight.bold : base.fontWeight,
      fontStyle: block.isItalic ? FontStyle.italic : null,
      decoration: block.isUnderline ? TextDecoration.underline : null,
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
