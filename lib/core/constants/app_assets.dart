/// مسارات الأصول المحزومة داخل التطبيق.
///
/// قاعدة المشروع: **لا يُجلب أي أصل أو خط عبر الشبكة**. كل ما يلي مُضمَّن في
/// حزمة التطبيق ويعمل بلا إنترنت بالكامل.
abstract final class AppAssets {
  const AppAssets._();

  // ==========================================================================
  //                          أيقونة البرنامج (Program Icon)
  // ==========================================================================
  /// أيقونة البرنامج المحزومة — تُستخدم أيضاً كلوجو بجوار اسم البرنامج في
  /// الشريط العلوي وشاشات الدخول والتهيئة، وكذلك لأيقونات المنصّات عبر
  /// `flutter_launcher_icons`. المصدر الوحيد في `assets/images/`.
  static const String appIconImage = 'assets/images/icon.png';

  /// شعار صفحة القرية — خطّ العربي المذهّب لاسم القرية، يحلّ محلّ عنوان
  /// النصّ في ترويسة الصفحة العامة (`village_header.dart`).
  static const String villageLogoImage = 'assets/images/logo.png';

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

  /// خط الصينية الاحتياطي — **محزوم داخل الحزمة** (لا شبكة وقت التشغيل).
  ///
  /// ملف مُصغَّر من Noto Sans SC يغطي كل ترجمات `app_zh.arb` ورموز GB2312
  /// كاملة. أعد توليده بـ `python tool/subset_cjk_font.py`.
  static const String notoScFont = 'Noto Sans SC';

  /// ملف خط الصينية داخل الحزمة (‎TrueType — يُقرأ بنفس بقية خطوط الواجهة).
  static const String notoScFontFile =
      'assets/fonts/noto_sans_sc/NotoSansSC-Regular.ttf';

  /// خط السيريلية الاحتياطي — **محزوم داخل الحزمة** ومُصغَّر من `Noto Sans`.
  ///
  /// لماذا خط منفصل؟ خط الصينية أعلاه لا يملك إلا الأبجدية الروسية الأساسية
  /// (‎66 محرفاً)، ولا خط عربي محزوم يغطي السيريلية إطلاقاً. هذا الملف يغطي كامل
  /// الكتلة السيريلية `U+0400..U+052F` واللاتيني والتنقيط. أعد توليده بـ
  /// `python tool/subset_cyrillic_font.py`.
  static const String notoCyrillicFont = 'Noto Sans';
  static const String notoCyrillicFontFile =
      'assets/fonts/noto_sans/NotoSans-Cyrillic.ttf';

  /// خطوط احتياطية عالمية للواجهة (`fontFamilyFallback`).
  /// الخط الافتراضي **Cairo** يغطي العربية واللاتينية، لكن أي محرف يغيب عنه قد
  /// يظهر مربعاً فارغاً (□□□)، فنمرّر خطوط نظام تغطي الحالتين: Tahoma/Arial
  /// للعربي واللاتيني، ثم خطوط CJK لأن فلاتر لا تحزم خطاً صينياً ولا نستطيع
  /// حزم خط كامل (‎~10MB‎) بلا شبكة.
  static const List<String> uiFontFallback = <String>[
    // خط صيني محزوم داخل الحزمة — الوحيد المضمون على كل منصة بما فيها الويب،
    // لذا يتصدّر القائمة فتُرسم ترجمات zh كلها بلا مربعات فارغة (□□□).
    notoScFont,
    // سيريلية كاملة (Noto Sans) — خط الصينية يغطي الروسية الأساسية فقط، فلا
    // مربعات فارغة في الأوكرانية/الصربية/البلغارية ولا في نص سيريلي مخلوط.
    notoCyrillicFont,
    'Tahoma', // ويندوز/ماك — يغطي العربي واللاتيني
    'Arial',
    'Microsoft YaHei', // ويندوز (CJK) إن وُجد
    'PingFang SC', // ماك إن وجد
    'Noto Sans CJK SC', // لينكس إن وجد
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
