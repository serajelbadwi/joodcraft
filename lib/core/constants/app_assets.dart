/// مسارات الأصول المحزومة داخل التطبيق.
///
/// قاعدة المشروع: **لا يُجلب أي أصل أو خط عبر الشبكة**. كل ما يلي مُضمَّن في
/// حزمة التطبيق ويعمل بلا إنترنت بالكامل.
abstract final class AppAssets {
  const AppAssets._();

  // ==========================================================================
  //                            قوالب نموذجية (JSON)
  // ==========================================================================
  static const String sampleCertificateTemplate =
      'assets/templates/sample_certificate.json';
  static const String sampleContractTemplate =
      'assets/templates/sample_contract.json';

  // ==========================================================================
  //                        الخطوط: الواجهة (Flutter)
  // ==========================================================================
  static const String cairoFont = 'Cairo';
  static const String amiriFont = 'Amiri';
  static const String plexArabicFont = 'IBMPlexSansArabic';
  static const String tajawalFont = 'Tajawal';
  static const String notoArabicFont = 'NotoSansArabic';

  /// عائلات احتياطية لتغطية الكتابات غير العربية (الصينية/الآسيوية) في الواجهة.
  ///
  /// فلاتر لا تحزم خطاً صينياً، والخط الافتراضي (Cairo) لا يغطّي محارف CJK،
  /// فتظهر مربعات فارغة (□□□). لا نستطيع حزم خط CJK كامل (‎~10MB‎) ولا جلبه
  /// من الشبكة، لذا نُسنِد التغطية لخطوط النظام المتاحة على كل منصة:
  /// ويندوز (Microsoft YaHei / SimSun)، ماك (PingFang SC)، لينكس
  /// (Noto Sans CJK SC)، ثم `sans-serif` أخيراً.
  ///
  /// يُطبَّق على كل أنماط النصوص (راجع `AppTheme`) وعلى نمط نصوص المحرر
  /// (راجع `element_view.dart`) حتى لا تظهر المربعات لا في الواجهة ولا في
  /// معاينة القالب. **ملاحظة:** محرّك الـ PDF لا يستطيع استخدام خطوط النظام
  /// (يحتاج ملف TTF محزوم) — لذا يبقى هناك تحذير تغطية واضح، راجع
  /// `PdfScriptCoverage`.
  static const List<String> cjkFontFallback = <String>[
    'Microsoft YaHei', // ويندوز
    'PingFang SC', // ماك
    'Noto Sans CJK SC', // لينكس
    'Noto Sans SC',
    'SimSun',
    'sans-serif',
  ];

  // ==========================================================================
  //                     الخطوط: محرّك الـ PDF (تُقرأ بـ bytes)
  // ==========================================================================
  static const String pdfCairoRegular =
      'assets/fonts/cairo/Cairo-Regular.ttf';
  static const String pdfCairoSemiBold =
      'assets/fonts/cairo/Cairo-SemiBold.ttf';
  static const String pdfCairoBold = 'assets/fonts/cairo/Cairo-Bold.ttf';

  static const String pdfAmiriRegular = 'assets/fonts/amiri/Amiri-Regular.ttf';
  static const String pdfAmiriBold = 'assets/fonts/amiri/Amiri-Bold.ttf';

  static const String pdfPlexRegular =
      'assets/fonts/ibm_plex_sans_arabic/IBMPlexSansArabic-Regular.ttf';
  static const String pdfPlexSemiBold =
      'assets/fonts/ibm_plex_sans_arabic/IBMPlexSansArabic-SemiBold.ttf';
  static const String pdfPlexBold =
      'assets/fonts/ibm_plex_sans_arabic/IBMPlexSansArabic-Bold.ttf';

  static const String pdfTajawalRegular =
      'assets/fonts/tajawal/Tajawal-Regular.ttf';
  static const String pdfTajawalMedium =
      'assets/fonts/tajawal/Tajawal-Medium.ttf';
  static const String pdfTajawalBold = 'assets/fonts/tajawal/Tajawal-Bold.ttf';

  static const String pdfNotoArabicRegular =
      'assets/fonts/noto_sans_arabic/NotoSansArabic-Regular.ttf';
  static const String pdfNotoArabicSemiBold =
      'assets/fonts/noto_sans_arabic/NotoSansArabic-SemiBold.ttf';
  static const String pdfNotoArabicBold =
      'assets/fonts/noto_sans_arabic/NotoSansArabic-Bold.ttf';
}
