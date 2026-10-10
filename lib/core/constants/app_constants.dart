/// ثوابت المنصة المشتركة بين جميع الميزات.
abstract final class AppConstants {
  const AppConstants._();

  // ------------------------------- الهوية --------------------------------
  static const String appName = 'JoodCraft';
  static const String appNameAr = 'جودكرافت';
  static const String appTagline = 'منصة توليد الشهادات والعقود الرسمية';
  static const String appVersion = '1.0.0';

  // ---------------------------- عقد القوالب -----------------------------
  /// إصدار مخطط الـ JSON الحالي. موجود داخل `layout_data.schema_version`
  /// وهو إلزامي منذ اليوم الأول لتمكين ترحيل القوالب القديمة مستقبلاً.
  static const int layoutSchemaVersion = 1;

  // --------------------------- تخزين Supabase ---------------------------
  static const String templatesTable = 'templates';
  static const String profilesTable = 'profiles';
  static const String userAssetsTable = 'user_assets';
  static const String userAssetsBucket = 'user-assets';

  // ------------------------------- قيود --------------------------------
  /// الحد الأدنى لطول كلمة المرور (مطابق لسياسة Supabase الافتراضية).
  static const int minPasswordLength = 8;

  /// أقصى طول مقبول لاسم المستخدم/المؤسسة.
  static const int maxNameLength = 120;
}

/// تصنيفات القوالب — مطابقة لقيود `CHECK` في قاعدة البيانات.
enum TemplateCategory {
  certificate('certificate', 'شهادة'),
  contract('contract', 'عقد');

  const TemplateCategory(this.dbValue, this.labelAr);

  final String dbValue;
  final String labelAr;

  /// الاتجاه القياسي لهذا التصنيف (الشهادات أفقية والعقود رأسية).
  PageOrientation get defaultOrientation => this == TemplateCategory.certificate
      ? PageOrientation.landscape
      : PageOrientation.portrait;

  /// تحويل آمن من قيمة قاعدة البيانات (مع الافتراضي `certificate`).
  static TemplateCategory fromDb(String? value) {
    final String needle = (value ?? '').trim().toLowerCase();
    return switch (needle) {
      'contract' || 'عقد' => TemplateCategory.contract,
      _ => TemplateCategory.certificate,
    };
  }
}

/// اتجاه الصفحة — الشهادات أفقية والعقود رأسية.
enum PageOrientation {
  landscape('landscape', 'أفقي (Landscape)'),
  portrait('portrait', 'رأسي (Portrait)');

  const PageOrientation(this.dbValue, this.labelAr);

  final String dbValue;
  final String labelAr;

  /// اتجاه الصفحة المقابل لمحرّك الـ PDF.
  bool get isLandscape => this == PageOrientation.landscape;

  /// تحويل آمن من قيمة قاعدة البيانات (مع الافتراضي `landscape`).
  static PageOrientation fromDb(String? value) {
    final String needle = (value ?? '').trim().toLowerCase();
    return needle == 'portrait' || needle == 'رأسي'
        ? PageOrientation.portrait
        : PageOrientation.landscape;
  }
}

/// أنواع أصول المستخدم — مطابقة لقيود `CHECK` في قاعدة البيانات.
enum AssetType {
  logo('logo', 'شعار'),
  signature('signature', 'توقيع'),
  stamp('stamp', 'ختم'),
  border('border', 'إطار');

  const AssetType(this.dbValue, this.labelAr);

  final String dbValue;
  final String labelAr;
}

/// وحدات القياس المتاحة للدخول المخصص.
enum MeasurementUnit {
  /// سنتيمتر — الوحدة القياسية المستخدمة عند إدخال الأبعاد المخصصة.
  cm('cm', 'سم'),

  /// مليمتر.
  mm('mm', 'ملم'),

  /// بوصة.
  inch('in', 'بوصة'),

  /// نقطة طباعة (72 نقطة = 1 بوصة).
  pt('pt', 'نقطة'),

  /// بكسل (عند 96dpi) — وحدة الشاشة والأبعاد الرقمية كقصص الحالة والمنشورات
  /// المربّعة. `1px = 72/96 نقطة`، وهي نفس النسبة التي يعتمدها المستند لاشتقاق
  /// مساحة التصميم (`designWidth = pageWidthPt × 96/72`)، فتعود الأبعاد الرقمية
  /// الدقيقة كما أُدخلت بلا أي انزياح.
  px('px', 'بكسل');

  const MeasurementUnit(this.jsonValue, this.labelAr);

  final String jsonValue;
  final String labelAr;

  /// تحويل من قيمة قاعدة بيانات (مع الافتراض `cm`).
  static MeasurementUnit fromJson(Object? value) {
    final String needle = '${value ?? 'cm'}'.trim().toLowerCase();
    return switch (needle) {
      'mm' || 'مم' => MeasurementUnit.mm,
      'in' || 'بوصة' || 'inch' => MeasurementUnit.inch,
      'pt' || 'نقطة' => MeasurementUnit.pt,
      'px' || 'بكسل' => MeasurementUnit.px,
      _ => MeasurementUnit.cm,
    };
  }

  /// مليمتر واحد = ‎72/25.4‎ نقطة ‎≈ 2.8346‎، فالوحدات المطبوعة (بطاقة 90×55
  /// ملم مثلاً) تخرج بالمقاس الحقيقي نفسه لا بمقاس مُضاعف.
  static const double _ptPerMm = 72 / 25.4;

  /// التحويل من وحدة إلى نقطة فاحصة (نقطة). هذه النقاط هي ما يطعمه
  /// محرّك الـ PDF فعلياً.
  double toPoints(double value) => switch (this) {
    MeasurementUnit.mm => value * _ptPerMm,
    MeasurementUnit.inch => value * 72,
    MeasurementUnit.pt => value,
    MeasurementUnit.px => value * 72 / 96,
    MeasurementUnit.cm => value / 2.54 * 72,
  };

  /// التحويل من نقطة فاحصة إلى هذه الوحدة.
  double fromPoints(double value) => switch (this) {
    MeasurementUnit.mm => value / _ptPerMm,
    MeasurementUnit.inch => value / 72,
    MeasurementUnit.pt => value,
    MeasurementUnit.px => value * 96 / 72,
    MeasurementUnit.cm => value * 2.54 / 72,
  };
}

/// وحدة دقّة الطباعة — تُعرض في نافذة المستند الجديد بجانب حقل الدقّة.
///
/// التخزين الداخلي للنقاط/بوصة (PPI) لأن محرّك الـ PDF والصور يفهم هذه الوحدة
/// وحدها؛ أما الوحدة المعروضة (PPI/PPCM) فهي **طبقة عرض** تُحوَّل عند الحفظ
/// والعرض بلا أي تغيير في هندسة المستند.
enum ResolutionUnit {
  /// بكسل لكل بوصة — الوحدة الافتراضية في الطباعة والشاشة.
  ppi('ppi', 'بكسل/بوصة (PPI)'),

  /// بكسل لكل سنتيمتر — مألوفة في أوروبا ووحدات ما قبل الطباعة.
  ppcm('ppcm', 'بكسل/سنتيمتر (PPCM)');

  const ResolutionUnit(this.jsonValue, this.labelAr);

  final String jsonValue;
  final String labelAr;

  /// تحويل آمن من قيمة مخزّنة (مع الافتراض `ppi`).
  static ResolutionUnit fromJson(Object? value) {
    final String needle = '${value ?? 'ppi'}'.trim().toLowerCase();
    return switch (needle) {
      'ppcm' || 'dpcm' || 'بكسل/سنتيمتر' => ResolutionUnit.ppcm,
      _ => ResolutionUnit.ppi,
    };
  }

  /// قيمة الوحدة محوَّلة إلى نقطة/بوصة (وحدة المستند الداخلية).
  double toDpi(double value) =>
      this == ResolutionUnit.ppcm ? value * 2.54 : value;

  /// قيمة النقاط/بوصة محوَّلة إلى هذه الوحدة.
  double fromDpi(double dpi) =>
      this == ResolutionUnit.ppcm ? dpi / 2.54 : dpi;
}

/// نمط لون المستند — **نيّة طباعة** تُحفظ مع القالب وتُعرض للمستخدم.
///
/// لا يغيّر هندسة المستند ولا ألوان العناصر (تلك تبقى RGBA في المحرّك): دوره
/// أن يجعل القالب يعلن صراحةً هل هو معدّ للعرض على الشاشة/الويب أم لمطبعة
/// احترافية، فيقرأه المصمّم والـ PDF والتسعير لاحقاً ويُبنى عليه ما يلزم.
enum DocumentColorMode {
  rgb('rgb', 'RGB — 8 بت (شاشة وويب)'),
  cmyk('cmyk', 'CMYK — طباعة احترافية');

  const DocumentColorMode(this.jsonValue, this.labelAr);

  final String jsonValue;
  final String labelAr;

  /// هل هو نمط طباعة؟ (يساعد الواجهة على اختيار دقّة افتراضية مناسبة).
  bool get isPrint => this == DocumentColorMode.cmyk;

  /// تحويل آمن من قيمة مخزّنة (مع الافتراض `rgb`).
  static DocumentColorMode fromJson(Object? value) {
    final String needle = '${value ?? 'rgb'}'.trim().toLowerCase();
    return switch (needle) {
      'cmyk' || 'طباعة' => DocumentColorMode.cmyk,
      _ => DocumentColorMode.rgb,
    };
  }
}

/// مستويات الاشتراك — مطابقة لقيود `CHECK` في قاعدة البيانات.
enum SubscriptionTier {
  free('free', 'مجاني'),
  pro('pro', 'احترافي'),
  enterprise('enterprise', 'مؤسسي');

  const SubscriptionTier(this.dbValue, this.labelAr);

  final String dbValue;
  final String labelAr;

  /// تحويل آمن من قيمة قاعدة البيانات إلى النوع (مع الافتراضي `free`).
  static SubscriptionTier fromDb(String? value) {
    return SubscriptionTier.values.firstWhere(
      (tier) => tier.dbValue == value,
      orElse: () => SubscriptionTier.free,
    );
  }
}
