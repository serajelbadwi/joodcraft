import 'template_element.dart';

/// الموضع الفيزيائي الذي يستقرّ عنده النص أفقيّاً بعد حلّ المحاذاة المنطقية
/// (`start`/`end`) والاتجاه (`rtl`/`ltr`).
///
/// نستخدم تمثيلاً محايداً واحداً حتى **لا** ترحّل محاذاة النص بين محرّر اللوحة
/// (يُرسم بـ Flutter) ومخرجات الـ PDF (تُرسم بمكتبة `pdf`): كل مسار يحوّل هذا
/// الموضع إلى نوع المحاذاة الذي يفهمه محرّكه، ويُفحَص الاتساق في
/// `test/unit/text_alignment_parity_test.dart`.
enum TextAnchor { left, center, right }

/// حلّ اتجاه النص ومحاذاته بشكل موحّد بين محرّر اللوحة ومحرّك الطباعة.
///
/// وجود هذا الحلّ في مكان واحد يمنع الانحدار الصامت: أي تعديل على قاعدة
/// `rtl`/`auto` أو على محاذاة `start`/`end` ينعكس فوراً على المسارين معاً.
abstract final class TextFlow {
  const TextFlow._();

  /// الاتجاه الفعلي للعنصر بعد حلّ `auto` حسب محتوى النص.
  static bool resolvesRtl(ElementDirection direction, String text) =>
      switch (direction) {
        ElementDirection.ltr => false,
        ElementDirection.rtl => true,
        ElementDirection.auto => looksRightToLeft(text),
      };

  /// هل يحتوي النص محارف من النطاقات التي تُكتب من اليمين إلى اليسار؟
  ///
  /// يغطّي العربية (U+0600..U+06FF وما حولها)، العبرية، وصيغ العرض العربية
  /// المتصلة (U+FB1D..U+FEFF) حتى يعمل الكشف على النص البصري المسبق أيضاً.
  static bool looksRightToLeft(String text) {
    for (final int rune in text.runes) {
      if ((rune >= 0x0590 && rune <= 0x08FF) ||
          (rune >= 0xFB1D && rune <= 0xFEFF)) {
        return true;
      }
    }
    return false;
  }

  /// الموضع الفيزيائي للمحاذاة المنطقية حسب اتجاه النص.
  ///
  /// ملاحظة «ضبط»: محرّك الطباعة لا ينفّذ `justify` فعلاً (انظر
  /// `ArabicTextEngine` الذي يمدّ الأسطر يدوياً)، لذلك يُعامَل السطر الأخير
  /// غير الممدَّد كأنه `start` — يميناً للعربية ويساراً للاتينية.
  static TextAnchor anchorFor(ElementTextAlign align, bool rtl) =>
      switch (align) {
        ElementTextAlign.center => TextAnchor.center,
        ElementTextAlign.start ||
        ElementTextAlign.justify =>
          rtl ? TextAnchor.right : TextAnchor.left,
        ElementTextAlign.end => rtl ? TextAnchor.left : TextAnchor.right,
      };
}
