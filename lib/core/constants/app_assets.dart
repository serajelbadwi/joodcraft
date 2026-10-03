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
