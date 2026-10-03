/// مسارات التطبيق — مصدر واحد للحقيقة يمنع تكرار النصوص في الشاشات.
abstract final class AppRoutes {
  const AppRoutes._();

  // ------------------------------ المصادقة ------------------------------
  static const String login = '/login';
  static const String register = '/register';

  // ------------------------------- اللوحة -------------------------------
  static const String dashboard = '/dashboard';

  // ------------------------------ المحرّكات ------------------------------
  static const String certificateBuilder = '/certificate-builder';
  static const String contractBuilder = '/contract-builder';

  /// معاينة القالب النموذجي (المرحلة 2) — مفيدة للتأكد من الخطوط والتشكيل
  /// قبل أي تعديل على القالب.
  static const String certificateSamplePreview =
      '/certificate-builder/sample-preview';
  static const String contractSamplePreview = '/contract-builder/sample-preview';
  static const String batchProcessor = '/batch-processor';
  static const String templates = '/templates';
  static const String assets = '/assets';
}
