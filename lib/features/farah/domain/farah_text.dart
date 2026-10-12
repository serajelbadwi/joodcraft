/// كل نصوص تطبيق «فرح» العربية في ملف واحد — كصفحة القرية، هذه واجهة
/// **عربية أحادية اللغة** لأهل القرية، فلا معنى لتمريرها على دورة الترجمة.
library;

/// نصوص تطبيق «فرح».
abstract final class FarahText {
  const FarahText._();

  // ------------------------------ الهوية ------------------------------
  static const String appName = 'تطبيق فرح';

  /// سطر تعريفي أسفل الاسم في شاشة الدخول.
  static const String appTagline = 'تواصل أهل القرية — رسائل قصيرة بين المدعوين';

  // ------------------------------ النافذة في JoodCraft ------------------------------
  /// زرّ الإغلاق X في ترويسة «فرح» حين تُفتح من برنامج JoodCraft.
  static const String closeDialog = 'إغلاق';

  // ------------------------------ التذييل (الفوتر) ------------------------------
  /// بجوار شعار JoodCraft في جهة يمين الفوتر.
  static const String footerFrom = 'من أعمال';

  static const String footerDeveloperLabel = 'المطور';

  static const String footerDeveloperName = 'سراج عبدالله البدوي';

  static const String footerPhone = '+20 01020005439';

  static const String footerCopyright = '© 2026 القرية — جميع الحقوق محفوظة';

  // ------------------------------ الدخول ------------------------------
  static const String loginTitle = 'تسجيل الدخول';

  static const String loginHint =
      'اكتب رقم تليفونك المسجَّل في صفحة القرية — التسجيل بالرقم فقط.';

  static const String phoneLabel = 'رقم التليفون';

  static const String loginSubmit = 'تسجيل';

  static const String loginSubmitting = 'جارٍ الدخول…';

  static const String notRegistered =
      'هذا الرقم غير مسجَّل — سجّل في صفحة القرية أولاً';

  static const String welcomeBack = 'أهلاً بعودتك';

  // ------------------------------ الرئيسية ------------------------------
  static const String homeTitle = 'أهل القرية';

  static const String homeHint =
      'اضغط على أي اسم لتراسل صاحبه — وكل أهل القرية هنا.';

  static const String messagesButton = 'الرسائل';

  static const String invitationsButton = 'الدعوات';

  static const String licenseButton = 'كود التفعيل';

  static const String ownerBadge = 'صاحب الفرح';

  static const String ownerActive = 'مُفعَّل ✓';

  static const String membersEmpty =
      'لا يوجد أهل مسجَّلون بعد في هذه القرية — كن أول من يدخل.';

  static const String signOut = 'خروج';

  // ------------------------------ الرسائل ------------------------------
  static const String conversationsTitle = 'الرسائل';

  static const String conversationsEmpty =
      'لا محادثات بعد — اختر اسماً من «أهل القرية» وابدأ التهنئة.';

  static const String lastMessageEmpty = 'ابدأ المحادثة — لم تُرسل رسائل بعد';

  static const String refresh = 'تحديث';

  /// «المتبقي لك اليوم: 500 حرف» / «المتبقي لهذا المدعو: 100 حرف».
  static String remainingToday(int n) => 'المتبقي لك اليوم: $n حرف';

  static String remainingToPartner(int n) => 'المتبقي لهذا المدعو: $n حرف';

  /// عدّاد الحقل: «12 / 100».
  static String charCounter(int used, int max) => '$used / $max';

  static const String send = 'إرسال';

  static const String inputHint = 'اكتب رسالتك…';

  static const String sentEmptyHint =
      'اكتب رسالة قصيرة (100 حرف) واضغط إرسال';

  static const String limitReachedToday =
      'انتهى حدّ رسائلك اليوم — يتجدد غداً بإذن الله';

  static const String limitReachedToPartner =
      'انتهى حدّ الرسائل لهذا المدعو — راسل مدعواً آخر';

  static const String threadEmpty =
      'لا رسائل بينكما بعد — كن أول من يبدأ التهنئة.';

  // ------------------------------ التراخيص ------------------------------
  static const String licenseTitle = 'كود تفعيل صاحب الفرح';

  static const String licenseHint =
      'اكتب الكود الذي تسلّمته من مكتب القرية ليصبح لك حدّ 100 حرف لكل مدعو '
      'بلا حدّ يومي.';

  static const String licenseLabel = 'كود التفعيل';

  static const String licenseSubmit = 'تفعيل';

  static const String licenseActivating = 'جارٍ التفعيل…';

  static const String licenseActivated =
      'تم التفعيل — أنت الآن صاحب الفرح. 100 حرف لكل مدعو.';

  static const String licenseAlreadyOwner =
      'حسابك مُفعَّل أصلاً كصاحب فرح.';

  // ------------------------------ الدعوات ------------------------------
  static const String invitationsTitle = 'الدعوات';

  static const String invitationsBody =
      'قسم الدعوات قيد التجهيز: من هنا تصمم دعوة فرحك باسم كل مدعو وترسلها '
      'له — بمحرّك الدعوات في JoodCraft.';

  static const String invitationsCta = 'العودة إلى الرئيسية';

  // ------------------------------ الأخطاء ------------------------------
  static const String genericError =
      'تعذّر إتمام الطلب — تحقّق من الاتصال بالإنترنت وأعد المحاولة';

  static const String networkError =
      'لا يوجد اتصال بقاعدة بيانات القرية — راجع الشبكة وأعد المحاولة';

  static const String serviceUnavailable =
      'لم تُضبط مفاتيح الاتصال بقاعدة بيانات القرية بعد — تواصل مع المطوّر.';
}
