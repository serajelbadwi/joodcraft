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
