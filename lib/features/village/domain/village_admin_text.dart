/// **كل نصوص لوحة تحكم القرى** العربية في مكان واحد.
///
/// كالنصّ في `VillageText`: ثوابت هنا لا في ملفات ARB عن قصد — اللوحة
/// أداة داخلية أحادية اللغة لصاحب المكتب، تجميعها في ملف واحد يجعل تعديل
/// الكلام أو مراجعته مسألة سطر، وتُستورد من طبقة البيانات كذلك (رسائل
/// الأخطاء تُبنى حيث يُلتقط الخطأ).
library;

import 'village_validators.dart';

/// نصوص لوحة تحكم القرى.
abstract final class VillageAdminText {
  const VillageAdminText._();

  // ------------------------------ بوابة الدخول ------------------------------
  static const String gateTitle = 'لوحة تحكم القرى';

  static const String gateSubtitle =
      'دخول صاحب المكتب — إدارة كل القرى من مكان واحد: المحتوى والأعضاء '
      'والإعلانات والإحصائيات.';

  static const String emailLabel = 'البريد الإلكتروني';

  static const String passwordLabel = 'كلمة السر';

  static const String signIn = 'دخول';

  static const String signingIn = 'جارٍ التحقق…';

  static const String emailRequired = 'اكتب البريد الإلكتروني';

  static const String passwordRequired = 'اكتب كلمة السر';

  static const String invalidCredentials = 'بيانات الدخول غير صحيحة';

  static const String notAdmin =
      'هذا الحساب ليس مشرفاً على لوحة التحكم — راجع صاحب المكتب';

  static const String signInFailed =
      'تعذّر تسجيل الدخول — تحقّق من البيانات وأعد المحاولة';

  static const String networkError =
      'لا يوجد اتصال بقاعدة البيانات — راجع الشبكة وأعد المحاولة';

  static const String emailNotConfirmed = 'البريد الإلكتروني غير مُوثّق';

  // -------------------------------- اللوحة --------------------------------
  static const String panelTitle = 'لوحة تحكم القرى';

  static const String signOut = 'تسجيل الخروج';

  static const String statVillages = 'القرى';

  static const String statMembers = 'المسجَّلون';

  static const String statVideos = 'الفيديوهات';

  static const String statAds = 'إعلانات نشطة';

  static const String addVillage = 'إضافة قرية';

  static const String addVillageTitle = 'قرية جديدة';

  static const String villageNameLabel = 'اسم القرية';

  static const String villageCodeLabel = 'كود القرية';

  static const String villageCodeHint = 'ثلاثة حروف وشرطة والسنة — مثل MAA-2026';

  static const String villageCreated = 'أُضيفت القرية بنجاح';

  static const String codeInUse =
      'هذا الكود مستخدم لقرية أخرى — اختر كوداً آخر';

  static const String emptyVillages =
      'لا توجد قرى بعد — أضف أول قرية لتبدأ الإعداد.';

  static const String save = 'حفظ';

  static const String cancel = 'إلغاء';

  static const String delete = 'حذف';

  static const String confirm = 'تأكيد';

  static const String close = 'إغلاق';

  static const String loading = 'جارٍ التحميل…';

  static const String retry = 'إعادة المحاولة';

  // ------------------------------ الأقسام الثلاثة ------------------------------
  static const String sectionVideos = 'إدارة الفيديوهات';

  static const String sectionVideosDesc =
      'إضافة وتعديل وحذف فيديوهات يوتيوب لعرضها في صفحة القرية.';

  static const String sectionMembers = 'إدارة الأعضاء';

  static const String sectionMembersDesc =
      'قائمة المسجَّلين — بحث وفلترة بالجنس والسن وحذف وتصدير CSV.';

  static const String sectionAds = 'إدارة الإعلانات';

  static const String sectionAdsDesc =
      'إعلانات محلية بتواريخ سريان وصور وجهات تواصل.';

  // ------------------------------- الفيديوهات -------------------------------
  static const String videosTitle = 'فيديوهات القرية';

  static const String videosEmpty =
      'لا فيديوهات بعد — أضف أول فيديو من زر الإضافة.';

  static const String addVideo = 'إضافة فيديو';

  static const String editVideo = 'تعديل الفيديو';

  static const String videoTitleLabel = 'عنوان الفيديو';

  static const String videoUrlLabel = 'رابط يوتيوب';

  static const String videoUrlHint =
      'الصق الرابط — يُستخرج معرّف الفيديو تلقائياً';

  static const String videoDescLabel = 'الوصف (اختياري)';

  static String videoIdDetected(String id) => 'المعرّف المُستخرج: $id';

  static const String videoIdMissing =
      'الصق رابط يوتيوب صالحاً (youtu.be أو watch?v= أو shorts)';

  static const String videoTitleRequired = 'اكتب عنوان الفيديو';

  static const String videoSaved = 'تم حفظ الفيديو';

  static const String videoDeleted = 'حُذف الفيديو';

  static const String deleteVideoTitle = 'حذف الفيديو؟';

  static const String deleteVideoBody =
      'سيُحذف الفيديو من قائمة القرية نهائياً.';

  static const String videoScheduled = 'مجدول — مخفي حتى موعده';

  // -------------------------------- الأعضاء --------------------------------
  static const String membersTitle = 'أعضاء القرية';

  static const String membersEmpty = 'لا يوجد أعضاء مطابقون للفلترة.';

  static const String memberSearchHint =
      'ابحث بالاسم أو التليفون أو الرقم القومي…';

  static const String filterGender = 'الجنس';

  static const String filterAge = 'السن';

  static const String filterAll = 'الكل';

  static const String genderMale = 'ذكور';

  static const String genderFemale = 'إناث';

  static const String ageAll = 'كل الأعمار';

  static const String age18to30 = '18 – 30';

  static const String age31to45 = '31 – 45';

  static const String age46to60 = '46 – 60';

  static const String age60plus = 'أكثر من 60';

  static const String exportCsv = 'تصدير CSV';

  static String exportSaved(String fileName) => 'حُفظ الملف: $fileName';

  static const String exportFailed =
      'تعذّر حفظ ملف CSV — أعد المحاولة أو اختر موقعاً آخر.';

  static const String deleteMemberTitle = 'حذف العضو؟';

  static String deleteMemberBody(String name) =>
      'سيُحذف «$name» من سجل القرية نهائياً — لا يمكن التراجع.';

  static const String memberDeleted = 'حُذف العضو';

  /// صيغة العدد: «عضو واحد / عضوان / 5 أعضاء / 23 عضواً».
  static String membersCount(int count) {
    if (count == 1) return 'عضو واحد';
    if (count == 2) return 'عضوان';
    if (count <= 10) return '$count أعضاء';
    return '$count عضواً';
  }

  /// صيغة عدد القرى: «قرية / قريتان / 5 قرى / 23 قرية».
  static String villagesCount(int count) {
    if (count == 1) return 'قرية واحدة';
    if (count == 2) return 'قريتان';
    if (count <= 10) return '$count قرى';
    return '$count قرية';
  }

  // ------------------------------- الإعلانات -------------------------------
  static const String adsTitle = 'إعلانات القرية';

  static const String adsEmpty =
      'لا إعلانات بعد — أضف أول إعلان من زر الإضافة.';

  static const String addAd = 'إضافة إعلان';

  static const String editAd = 'تعديل الإعلان';

  static const String adTitleLabel = 'عنوان الإعلان';

  static const String adImageLabel = 'صورة الإعلان';

  static const String adPickImage = 'اختيار صورة…';

  static const String adImageUploading = 'جارٍ رفع الصورة…';

  static const String adNoImage = 'بلا صورة';

  static const String adImageUrlLabel = 'أو الصق رابط الصورة (اختياري)';

  static const String adImageUrlHint =
      'رابط Google Drive أو رابط صورة مباشر — يُطبَّع آلياً عند الحفظ';

  /// رفض حفظ الإعلان حين يُلصق رابط **مجلد** بدل الصورة نفسها.
  static const String adImageFolderLink =
      'هذا رابط مجلد لا صورة — افتح الصورة نفسها ثم «مشاركة ← نسخ الرابط» والصقه هنا';

  static const String adPhoneLabel = 'رقم الهاتف (اختياري)';

  static const String adUrlLabel = 'رابط التواصل (اختياري)';

  static const String adStartLabel = 'من تاريخ';

  static const String adEndLabel = 'إلى تاريخ (اختياري)';

  static const String adActiveLabel = 'مفعَّل';

  static const String adTitleRequired = 'اكتب عنوان الإعلان';

  static const String adSaved = 'تم حفظ الإعلان';

  static const String adDeleted = 'حُذف الإعلان';

  static const String deleteAdTitle = 'حذف الإعلان؟';

  static const String deleteAdBody =
      'سيُحذف الإعلان من قائمة القرية نهائياً.';

  static const String adUploadFailed =
      'تعذّر رفع الصورة — تحقّق من الاتصال وأعد المحاولة.';

  // ------------------------------ رسوم مشتركة ------------------------------
  /// عنوان رفض الصلاحية (42501) من السيرفر.
  static const String notAuthorized =
      'ليست لديك صلاحية لهذه العملية — سجّل الدخول بصاحب المكتب';

  /// انتهت جلسة Supabase (JWT منتهي) — أعد الدخول.
  static const String sessionExpired = 'انتهت الجلسة — سجّل الدخول من جديد';

  /// زر الرجوع من صفحة مفقودة البيانات إلى اللوحة.
  static const String backToPanel = 'عد إلى لوحة التحكم';

  /// رسالة الخطأ العامّة لعمليات اللوحة.
  static const String genericError =
      'تعذّر إتمام العملية — تحقّق من الاتصال وأعد المحاولة';

  /// ملاحظة غياب تهيئة Supabase (نفس معنى حالة الصفحة العامة).
  static String get unavailableBody => VillageText.serviceBody;
}
