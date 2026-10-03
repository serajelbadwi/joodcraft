import '../models/template_document.dart';
import '../models/template_element.dart';

/// الكتابة (Script) التي قد يحويها نص القالب.
///
/// التصنيف مقصود ومحدود: نكتشف فقط الكتابات التي **تختلف** تغطيتها بين
/// الخطوط المحزومة — العربية/الأوردو واللاتينية مغطّاة، والسيريلية والصينية
/// (CJK) ليست كذلك. أي رموز أو ترقيم آخر يُتجاهل (يعود `null`) لأن الخطوط
/// المحزومة تغطّيه، فلا نُطلق تحذيرات كاذبة على كل قالب.
enum PdfScript {
  /// العربية والأوردو وكل ما يكتب بالحرف العربي (يشمل ملحقاته).
  arabic('العربية والأوردو'),

  /// اللاتينية وملحقاتها (الأكسنت والأوملاوت: é, ü, ñ, ğ…).
  latin('اللاتينية'),

  /// السيريلية (الروسية وغيرها).
  cyrillic('السيريلية'),

  /// الصينية وغيرها من كتابات شرق آسيا (Han وKana وHangul).
  cjk('الصينية/الآسيوية');

  const PdfScript(this.labelAr);

  /// الوصف العربي للعرض في التحذيرات.
  final String labelAr;
}

/// فحص تغطية الخطوط المحزومة لكتابات النص.
///
/// **الغرض:** منع ظهور مربعات فارغة أو `?` عند التوليد بلغة لا يغطّيها خط
/// محزوم، بدل فشل صامت. الطبقة هنا مستقلّة عن `pdf` وقابلة للاختبار وحدها،
/// ويكفي إضافة ملف خط (Noto Sans SC للصينية، خط سيريلي للروسية، …) إلى
/// `assets/fonts/` ووصله في `PdfFontSet._sources` ليصير مدعوماً تلقائياً.
abstract final class PdfScriptCoverage {
  const PdfScriptCoverage._();

  /// الكتابات التي تغطّيها الخطوط المحزومة فعلاً اليوم.
  static const Set<PdfScript> bundledScripts = <PdfScript>{
    PdfScript.arabic,
    PdfScript.latin,
  };

  /// كتابات كلها مغطّاة — تُستخدم لإخبار المستدعي أن الخط المطلوب آمن.
  static bool covers(Iterable<PdfScript> scripts) =>
      scripts.every(bundledScripts.contains);

  /// الكتابات المكتشَفة في نص واحد.
  static Set<PdfScript> scriptsIn(String text) {
    final Set<PdfScript> found = <PdfScript>{};
    for (final int rune in text.runes) {
      final PdfScript? script = scriptOf(rune);
      if (script != null) found.add(script);
    }
    return found;
  }

  /// الكتابات في [text] التي **لا** يغطّيها أي خط محزوم (قد تُرسم مربعات).
  static Set<PdfScript> unsupportedIn(String text) {
    final Set<PdfScript> missing = scriptsIn(text)
        .where((PdfScript s) => !bundledScripts.contains(s))
        .toSet();
    return missing;
  }

  /// الكتابات غير المغطّاة في كل نصوص القالب وبياناته التجريبية.
  ///
  /// يشمل نصوص `TextElement`، ومحتوى `QrElement` (قد يحمل اسم صيني مثلاً)،
  /// وقيم المعاينة — فالتوليد يستخدمها كلها.
  static Set<PdfScript> unsupportedInDocument(TemplateDocument document) {
    final Set<PdfScript> missing = <PdfScript>{};
    void scan(String? value) {
      if (value == null || value.isEmpty) return;
      missing.addAll(unsupportedIn(value));
    }

    for (final TemplateElement element in document.elements) {
      switch (element) {
        case TextElement(:final String text):
          scan(text);
        case QrElement(:final String data):
          scan(data);
        default:
          break;
      }
    }
    document.sampleData.forEach((String _, String value) => scan(value));
    return missing;
  }

  /// رسالة تحذير عربية واضحة لكتابة لا يغطّيها أي خط محزوم.
  static String warningFor(PdfScript script) =>
      'النص يحتوي كتابة «${script.labelAr}» لا يغطّيها أي خط محزوم، فقد تُرسم '
      'مربعات فارغة. أضف ملف خط مناسب (مثل Noto Sans للسيريلية أو Noto Sans SC '
      'للصينية) إلى assets/fonts/ ثم أعد التوليد.';

  /// يحوّل رقم المحرف إلى كتابته، أو `null` لرمز/ترقيم لا نصنّفه (لتجنّب
  /// تحذيرات كاذبة).
  static PdfScript? scriptOf(int rune) {
    if (rune < 0x80) return PdfScript.latin; // ASCII — لاتيني مغطّى.

    // ------------------------------- العربية -------------------------------
    if ((rune >= 0x0600 && rune <= 0x06FF) ||
        (rune >= 0x0750 && rune <= 0x077F) ||
        (rune >= 0x08A0 && rune <= 0x08FF) ||
        (rune >= 0xFB50 && rune <= 0xFDFF) ||
        (rune >= 0xFE70 && rune <= 0xFEFF)) {
      return PdfScript.arabic;
    }

    // ------------------------------ السيريلية ------------------------------
    if (rune >= 0x0400 && rune <= 0x04FF) return PdfScript.cyrillic;

    // ------------------------ الصينية/شرق آسيا (CJK) -----------------------
    if ((rune >= 0x3000 && rune <= 0x303F) || // ترقيم CJK
        (rune >= 0x3040 && rune <= 0x30FF) || // Hiragana / Katakana
        (rune >= 0x3400 && rune <= 0x4DBF) || // Han Ext A
        (rune >= 0x4E00 && rune <= 0x9FFF) || // Han
        (rune >= 0xAC00 && rune <= 0xD7AF) || // Hangul
        (rune >= 0xF900 && rune <= 0xFAFF)) {
      return PdfScript.cjk;
    }

    // ---------------------- اللاتينية وملحقاتها ----------------------
    if ((rune >= 0x00A0 && rune <= 0x024F) || // Latin-1 Sup + Extended A/B
        (rune >= 0x1E00 && rune <= 0x1EFF)) {
      return PdfScript.latin;
    }

    // رموز وترقيم عام (‎— • …) وبقية النطاقات — لا تُصنَّف (تجنّباً لتحذيرات
    // كاذبة على الرموز المشتركة بين كل الخطوط).
    return null;
  }
}
