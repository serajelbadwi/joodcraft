/// تحقّق حقول التسجيل + **كل نصوص الصفحة العربية** في مكان واحد.
///
/// نصوص الصفحة ثابتة هنا لا في ملفات ARB عن قصد: هذه صفحة **عامة أحادية
/// اللغة** تُنشر مستقلة على الويب لأهل القرية، ولا معنى لتمريرها على دورة
/// الترجمة العشر لغات الخاصة بتطبيق JoodCraft. تجميعها في ثوابت واحدة يجعل
/// تعديل الكلام أو مراجعته مسألة سطر واحد.
library;

import 'national_id.dart';
import 'village_code.dart';

/// نصوص صفحة القرية.
abstract final class VillageText {
  const VillageText._();

  // ------------------------------ الهوية ------------------------------
  /// اسم القرية (البذرة الأولى — تُغيّر هنا أو من جدول `villages`).
  static const String villageName = 'منشأة الأمراء ومحلة حسن';

  /// كود القرية الافتراضي المعروض في التلميح.
  static const String villageCode = 'MAA-2026';

  /// المدينة/المركز للأرشفة والعرض.
  static const String villageRegion = 'مركز المحلة الكبرى — محافظة الغربية';

  /// العنوان الرئيسي في الترويسة.
  static const String appTitle = villageName;

  /// سطر تعريفي أسفل الاسم.
  static const String appSubtitle = 'بوابة تسجيل أهل القرية';

  /// وصف مختصر يظهر في الترويسة والشريط.
  static const String appTagline = 'سجل موحّد للأهالي: الاسم ورقم التليفون والرقم القومي';

  // ---------------------------- كلمة عن القرية ----------------------------
  static const String aboutTitle = 'كلمة عن القرية';

  /// فقرات التعريف الثلاث — تفصلها سطران فارغان فيُعرض كل منها ككتلة
  /// مستقلة بتباعد مريح للقراءة.
  static const String aboutParagraph =
      'قرية «منشأة الأمراء ومحلة حسن» من قرى $villageRegion، '
      'قريتان متجاورتان تجمعهما وحدة محلية واحدة ونَسَب واحد.\n\n'
      'هذه الصفحة مبادرة أهلية لتسجيل بيانات الأهالي: الاسم ورقم التليفون '
      'والرقم القومي، في سجل موحّد ودقيق يخدم مبادرات القرية ومشروعاتها.\n\n'
      'البيانات محفوظة في قاعدة مؤمَّنة، والاطّلاع عليها مقصور على أهالي '
      'القرية وحدهم.';

  // ------------------- مزايا «كلمة عن القرية» (قابلة للضغط) -------------------
  /// بطاقة 1 — السجل الموحّد. تُفتح نافذة تفاصيل عند الضغط.
  static const String aboutCard1Title = 'سجل موحّد وموثوق لأهل القرية';

  static const String aboutCard1Body =
      'ماذا يُسجَّل؟ الاسم رباعي، ورقم التليفون، والرقم القومي.\n'
      'لماذا؟ لتنظيم مبادرات القرية ودعواتها والتواصل مع أهلها.\n'
      'من يطلع عليها؟ المفوّضون من قِبل أهل القرية.';

  /// بطاقة 2 — الحماية.
  static const String aboutCard2Title = 'بيانات مؤمَّنة';

  static const String aboutCard2Body =
      'الحماية: اتصال مشفَّر على Supabase، وقواعد RLS تمنع كل ما لم يُصرَّح به.\n'
      'عدم المشاركة: لا تُشارك البيانات مع أي جهة خارجية.\n'
      'حق الحذف: يحق لكل مسجَّل حذف بياناته من السجل في أي وقت.';

  /// بطاقة 3 — التوسّع.
  static const String aboutCard3Title = 'قابل للتوسّع';

  static const String aboutCard3Body =
      'خدمة كل قرى مصر بنفس اللوحة وبنفس الدقّة.\n'
      'نظام كود موحّد يفتح لكل قرية صفحتها الخاصة.\n'
      'إمكانية ربط تطبيق فرح لتوسيع الخدمة عند الجاهزية.';

  /// تلميح أسفل عنوان كل بطاقة يدلّ على قابلية الضغط.
  static const String aboutCardHint = 'اضغط لمعرفة التفاصيل';

  /// زر إغلاق نافذة تفاصيل البطاقة.
  static const String aboutCardClose = 'إغلاق';

  // ------------------------------- الخريطة -------------------------------
  static const String mapTitle = 'موقع القرية';

  /// استعلام الخريطة المُضمَّنة (جوجل مابز) — يمكن استبداله بإحداثيات دقيقة
  /// مثل `31.0409,31.3800` بلا أي تعديل على الكود.
  static const String mapQuery =
      'منشأة الأمراء ومحلة حسن، المحلة الكبرى، الغربية، مصر';

  static const String mapCaption = 'خريطة تفاعلية — للوصول أدقّ: افتحها في خرائط جوجل';

  /// زرّ فتح الخريطة المطويّة (القسم يبدأ مُغلقاً).
  static const String villageMapShow = 'عرض الخريطة';

  /// زرّ إغلاق الخريطة بعد فتحها.
  static const String villageMapHide = 'إغلاق الخريطة';

  // ----------------------------- فيديوهات القرية -----------------------------
  static const String videosTitle = 'فيديوهات القرية';

  static const String videosSubtitle = 'من أخبار القرية ومبادراتها — على يوتيوب';

  /// زر الفتح على يوتيوب أسفل كل فيديو.
  static const String videosOpenOnYoutube = 'افتح على يوتيوب';

  /// بطاقة بديلة حين تعذّر تضمين الفيديو (معرّف غير صالح في بيانات الصف).
  static const String videosEmbedUnavailable =
      'تعذّر تضمين هذا الفيديو — افتحه على يوتيوب';

  // ----------------------------- خطوة الكود -----------------------------
  static const String codeTitle = 'ادخل كود القرية';

  static const String codeHint =
      'الكود تتسلّمه من مسؤول القرية: ثلاثة حروف وشرطة والسنة — مثل '
      '$villageCode';

  static const String codeLabel = 'كود القرية';
  static const String codeSubmit = 'دخول';
  static const String codeChecking = 'جارٍ التحقق…';

  static const String codeNotFound =
      'الكود غير صحيح أو غير مسجَّل — تأكّد من الكود مع مسؤول القرية';

  /// ترحيب بعد قبول الكود: «قرية … — التسجيل مفتوح».
  static String welcomeVillage(String name) => 'قرية $name — التسجيل مفتوح';

  // ------------------------------- النموذج -------------------------------
  static const String formTitle = 'بيانات التسجيل';

  static const String formHint =
      'اكتب بياناتك بدقة. الرقم القومي يُتحقَّق منه آلياً، ويجب أن يكون '
      'المُسجَّل قد أتمّ 18 سنة.';

  static const String nameLabel = 'الاسم بالكامل';
  static const String phoneLabel = 'رقم التليفون';
  static const String nationalIdLabel = 'الرقم القومي (14 رقماً)';
  static const String submit = 'تسجيل';
  static const String submitting = 'جارٍ التسجيل…';

  /// «تاريخ الميلاد: … — العمر: … سنة»
  static const String nationalIdPreviewPrefix = 'بيانات مستخرجة من الرقم';

  // ------------------------------- النجاح -------------------------------
  static const String successTitle = 'تم التسجيل بنجاح';

  /// رسالة النجاح باسم المُسجَّل واسم القرية.
  static String successBody(String name, String village) =>
      'أهلاً $name — سُجِّلت بياناتك في سجل قرية $village، وصار اسمك ضمن أهلها '
      'في قاعدة البيانات.';

  static const String createAnother = 'تسجيل فرد آخر';

  // ----------------------------- تطبيق «فرح» -----------------------------
  static const String farahTitle = 'تطبيق «فرح»';

  static const String farahBody =
      'حمّل تطبيق «فرح» لتتابع مناسبات القرية وأفراحها وتبقى على اطلاع بكل '
      'جديد — وتصلك الدعوات أينما كنت.';

  static const String farahCta = 'تحميل تطبيق فرح';

  static const String farahSoon =
      'رابط التحميل قيد التجهيز — سيتوفّر قريباً بإذن الله';

  // ------------------------------- الفوتر -------------------------------
  static const String footerBrand = 'من أعمال JoodCraft';

  static const String footerDeveloper = 'سراج عبدالله البدوي';

  static const String footerRole = 'مطوّر المنصة';

  static const String footerRights = '© 2026 القرية — جميع الحقوق محفوظة';

  /// نص بديل لصورة الإمضاء (يُعرض حتى تُضاف الصورة).
  static const String signatureAssetPath = 'assets/images/serag_signature.jpeg';

  // ------------------------------ الأخطاء ------------------------------
  static const String duplicateNationalId =
      'هذا الرقم القومي مسجَّل بالفعل في القرية';

  static const String genericError =
      'تعذّر إتمام التسجيل — تحقّق من الاتصال بالإنترنت وأعد المحاولة';

  static const String networkError =
      'لا يوجد اتصال بقاعدة بيانات القرية — راجع الشبكة وأعد المحاولة';

  // --------------------------- حالة الخدمة ---------------------------
  static const String serviceTitle = 'الخدمة غير مُهيّأة';

  static const String serviceBody =
      'لم تُضبط مفاتيح الاتصال بقاعدة بيانات القرية بعد.\n'
      'أضف SUPABASE_URL و SUPABASE_ANON_KEY في ملف assets/env/env.json '
      'ثم أعد تشغيل الصفحة.';
}

/// تحقّق حقول التسجيل — يُعيد رسالة عربية واحدة أو `null` عند الصحة.
abstract final class VillageValidators {
  const VillageValidators._();

  /// أقصى طول مقبول للاسم.
  static const int maxNameLength = 60;

  /// أقل طول مقبول للاسم.
  static const int minNameLength = 3;

  /// طول رقم التليفون المصري.
  static const int phoneLength = 11;

  /// بادئات التليفون المحمول المقبولة في مصر.
  static const List<String> phonePrefixes = <String>['010', '011', '012', '015'];

  /// الأرقام العربية-الهندية ← لاتينية، وحذف المسافات/الشرطات.
  static String normalizeDigits(String raw) => NationalIdValidator.normalize(raw);

  /// الاسم: حروف عربية (مع المسافة والشرطة) بلا أرقام أو رموز.
  static String? name(String raw) {
    final String value = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (value.isEmpty) return 'اكتب الاسم بالكامل';
    if (value.length < minNameLength) return 'الاسم قصير جداً';
    if (value.length > maxNameLength) return 'الاسم طويل جداً';
    if (RegExp(r'[0-9٠-٩]').hasMatch(value)) {
      return 'الاسم لا يحتوي أرقاماً';
    }
    if (!RegExp(r'^[\u0621-\u064A\u0660-\u0669\u066E-\u06D3\s\-]+$')
        .hasMatch(value)) {
      return 'اكتب الاسم بحروف عربية';
    }
    return null;
  }

  /// التليفون: 11 رقماً يبدأ بـ 010/011/012/015.
  static String? phone(String raw) {
    final String value = normalizeDigits(raw);
    if (value.isEmpty) return 'اكتب رقم التليفون';
    if (!NationalIdValidator.isAllDigits(value)) {
      return 'رقم التليفون أرقام فقط';
    }
    if (value.length != phoneLength) {
      return 'رقم التليفون $phoneLength رقماً بالضبط';
    }
    final bool startsOk =
        phonePrefixes.any((String prefix) => value.startsWith(prefix));
    if (!startsOk) {
      return 'رقم غير صحيح — يبدأ بـ ${phonePrefixes.join(' أو ')}';
    }
    return null;
  }

  /// كود القرية: صيغة `AAA-0000` بعد التطبيع.
  static String? code(String raw) {
    if (raw.trim().isEmpty) return 'اكتب كود القرية';
    if (!VillageCode.isValid(raw)) {
      return 'صيغة الكود غير صحيحة — مثال: ${VillageText.villageCode}';
    }
    return null;
  }

  /// الكود بصورته المعيارية (حروف كبيرة وأرقام لاتينية) — مرجع واحد للتحويل.
  static String canonicalCode(String raw) => VillageCode.canonical(raw);
}
