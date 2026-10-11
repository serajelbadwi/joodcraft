/// إعدادات الاستخراج — لغة، وضع تقطيع (PSM)، ومعالجة قبلية.
///
/// **لماذا إعدادات صريحة؟** لأن التقرير المقيس يثبت أن ضبط `psm` والتكبير
/// يغيّران الدقة أكثر من تغيير المحرّك: `psm 6` لصفحة نصّية متعددة الأسطر،
/// والتكبير ×1.5 وحده أضاف ‎+7.6 نقاط على أصعب صورة. فالمستخدم يحتاج أن
/// يجرّب بضغطة زر لا أن يعدّل كوداً.
library;

/// لغة التعرّف — تُترجم مباشرةً إلى وسيط `-l` في Tesseract.
enum OcrLanguage {
  /// العربية فقط.
  arabic('ara'),

  /// الإنجليزية فقط.
  english('eng'),

  /// الاثنان — يقرأ الأرقام والتواريخ الإنجليزية داخل نصّ عربي.
  both('ara+eng');

  const OcrLanguage(this.tesseractCode);

  /// الوسيط الذي يُمرَّر إلى `tesseract -l`.
  final String tesseractCode;
}

/// وضع تقطيع الصفحة (Page Segmentation Mode) — أهم مفتاح جودة عملي.
enum OcrPsm {
  /// تقسيم تلقائي كامل (افتراضي Tesseract) — يصلح لصفحة مختلطة.
  auto(3, 'تقسيم تلقائي'),

  /// كتلة نصّية واحدة متعددة الأسطر — الأنسب لبطاقة/شهادة واحدة.
  singleBlock(6, 'كتلة نصّية واحدة'),

  /// سطر واحد — يصلح لعنوان أو رمز.
  singleLine(7, 'سطر واحد'),

  /// نص متفرّق (جدول/بطاقات متعددة).
  sparseText(11, 'نص متفرّق');

  const OcrPsm(this.value, this.labelAr);

  /// القيمة التي تُمرَّر إلى `--psm`.
  final int value;

  /// اسم عربي للعرض في الواجهة.
  final String labelAr;
}

/// إعدادات استخراج واحدة.
class OcrSettings {
  const OcrSettings({
    this.language = OcrLanguage.both,
    this.psm = OcrPsm.singleBlock,
    this.scale = 1.5,
    this.grayscale = true,
    this.binarize = false,
  });

  /// اللغة المطلوبة (الافتراضي: عربي + إنجليزي).
  final OcrLanguage language;

  /// وضع التقطيع (الافتراضي: كتلة واحدة — الأنسب لمستندات JoodCraft).
  final OcrPsm psm;

  /// معامل التكبير قبل الاستخراج (1.0–3.0). Tesseract يعمل أحسن ما يكون على
  /// نصّ بمدى ~300dpi، وصورة الجوال العادية أقلّ من ذلك.
  final double scale;

  /// تحويل إلى رمادي أولاً (يُبسّط البينايرة ويُنظّف التشويش اللوني).
  final bool grayscale;

  /// عتبة Otsu (أبيض/أسود صافي) — يرفع الدقة على الورق المصوّر ويضرّ
  /// بالصور ذات التدرّجات، ف Trich optional وليس افتراضياً.
  final bool binarize;

  /// حدود آمنة للتكبير في الواجهة.
  static const double minScale = 1.0;
  static const double maxScale = 3.0;

  OcrSettings copyWith({
    OcrLanguage? language,
    OcrPsm? psm,
    double? scale,
    bool? grayscale,
    bool? binarize,
  }) {
    return OcrSettings(
      language: language ?? this.language,
      psm: psm ?? this.psm,
      scale: scale ?? this.scale,
      grayscale: grayscale ?? this.grayscale,
      binarize: binarize ?? this.binarize,
    );
  }

  /// هل المعالجة قبلية مطلوبة فعلاً؟ (بلا معالجة = نسخ البايتات كما هي).
  bool get needsPreprocessing => scale != 1.0 || grayscale || binarize;
}
