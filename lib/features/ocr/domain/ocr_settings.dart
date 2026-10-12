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
///
/// **القيم الافتراضية هي ناتج قياس لا اجتهاد:** راجع
/// `report/ocr_improvement.md`. الافتراضي القديم (لغة `ara+eng`، PSM 6، بلا
/// عتبة) أعطى على نصّ عربي إسلامي نتائج يملك فيها النصّ اللاتيني الوهمي
/// (`ABN`، `gle`، `BI`) محلّ كلمات عربية. القياس يقول: اللغة العربية وحدها
/// حينها أدقّ، لأنّ نموذج `eng` يُنتج مرشّحات لاتينية لِأشكال عربية.
class OcrSettings {
  const OcrSettings({
    this.language = OcrLanguage.arabic,
    this.psm = OcrPsm.auto,
    this.scale = 1.5,
    this.grayscale = true,
    this.binarize = true,
    this.denoise = true,
    this.deskew = true,
    this.multiPass = true,
    this.contrast = true,
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
  /// بالصور ذات التدرّجات، فTrich optional افتراضياً.
  ///
  /// ⚠️ **قياسياً: مُفعَّل افتراضياً.** على نصّ عربي مطبوع نظيف رفع العتبة
  /// الدقة وأزاحت جذوراً للكلمات الوهمية (`ABN` ← بقعة رمادية). أمّا الصور
  /// الفوتوغرافيّة الغائرة في التدرّج فيمكن إيقافها بضغطة.
  final bool binarize;

  /// إزالة الضوضاء ذات النقطة الواحدة (تنظيف قبل العتبة).
  ///
  /// 🌟 **آمنة افتراضياً:** مرشّح متوسّط على البكسلات المنفردة لا يمسّ حواف
  /// الحروف — لكنه يُزيل بقع الغبار ونقاط الماسح التي تُقرأ أحرفاً زائفة.
  final bool denoise;

  /// رفع التباين بمدّ القيم على كامل المدى (0..255) قبل العتبة.
  ///
  /// 🔆 **ينقذ الصور الباهتة:** حبر خفيف أو ظلّ أو كاميرا قديمة يجمع النصّ
  /// في شريحة رمادية ضيّقة، فلا يفصل Otsu شيئاً فيها فتخرج النتيجة فارغة.
  /// مدّ المدى يفصل الاثنين قبل أن تُبنى العتبة.
  final bool contrast;

  /// تصحيح الميل بالملف الإسقاطي (projection profile).
  ///
  /// 📐 **لا يمسّ الصورة المستقيمة:** يُطبَّق فقط إن تجاوز الميل المقيس
  /// حدّ [_deskewThreshold]، وإلا يعود `0` فلا دوران ولا فقدان دقة.
  final bool deskew;

  /// تشغيل عدّة مرورات بأوضاع تقطيع مختلفة واختيار الأفضل.
  ///
  /// 🔁 **الافتراضي مفعّل، والزمن محفوظ:** الوضع المطلوب أوّلاً، وإن كانت
  /// نتيجته **جديدة كافية** (ثقة ‎≥ 80%‎ و‎3‎ كلمات فأكثر) يُقبل فوراً
  /// بمرور واحد. البدائل (‎PSM 3/4/6‎) لا تُشغَّل إلاّ عند الضعف — فالصورة
  /// الجيدة تبقى سريعة (مرور واحد)، والصعبة وحدها تدفع ثمناً.
  final bool multiPass;

  /// حدود آمنة للتكبير في الواجهة.
  static const double minScale = 1.0;
  static const double maxScale = 3.0;

  /// حدّ إثارة تصحيح الميل (درجات). الميلان الطبيعي للمسح الضوئي أقلّ من
  /// ذلك وعادةً يكون داخل احتمال أخطاء القياس نفسه — والتدوير عندها يُضيف
  /// ضبابية بلا فائدة.
  static const double deskewThreshold = 0.4;

  /// أقصى ميل يُصحَّح (درجات) — ما زاد يُعتبر صورةً قُطعت أو مُدارة عمداً.
  static const double maxDeskewDegrees = 12.0;

  OcrSettings copyWith({
    OcrLanguage? language,
    OcrPsm? psm,
    double? scale,
    bool? grayscale,
    bool? binarize,
    bool? denoise,
    bool? deskew,
    bool? multiPass,
    bool? contrast,
  }) {
    return OcrSettings(
      language: language ?? this.language,
      psm: psm ?? this.psm,
      scale: scale ?? this.scale,
      grayscale: grayscale ?? this.grayscale,
      binarize: binarize ?? this.binarize,
      denoise: denoise ?? this.denoise,
      deskew: deskew ?? this.deskew,
      multiPass: multiPass ?? this.multiPass,
      contrast: contrast ?? this.contrast,
    );
  }

  /// هل المعالجة قبلية مطلوبة فعلاً؟ (بلا معالجة = نسخ البايتات كما هي).
  bool get needsPreprocessing =>
      scale != 1.0 || grayscale || binarize || denoise || deskew;
}
