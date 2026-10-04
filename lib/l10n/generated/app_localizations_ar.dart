// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTagline => 'منصة توليد الشهادات والعقود الرسمية';

  @override
  String get navDashboard => 'لوحة التحكم';

  @override
  String get navCertificates => 'محـرّك الشهادات';

  @override
  String get navContracts => 'محـرّك العقود';

  @override
  String get navBatch => 'التوليد الجماعي';

  @override
  String get navTemplates => 'مكتبة القوالب';

  @override
  String get navAssets => 'الأصول والتوقيعات';

  @override
  String get actionSignOut => 'تسجيل الخروج';

  @override
  String get actionBackToDashboard => 'العودة إلى لوحة التحكم';

  @override
  String get offlineProcessingLabel => 'معالجة محلية';

  @override
  String get themeTooltip => 'تبديل المظهر';

  @override
  String get themeSystem => 'حسب النظام';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeDark => 'داكن';

  @override
  String get languageTooltip => 'تغيير اللغة';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageFrench => 'Français';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languageTurkish => 'Türkçe';

  @override
  String get languageUrdu => 'اردو';

  @override
  String get languageGerman => 'Deutsch';

  @override
  String get languageIndonesian => 'Bahasa Indonesia';

  @override
  String get languageRussian => 'Русский';

  @override
  String get languageChinese => '简体中文';

  @override
  String get configMissingKeysTitle => 'لم يُعثر على مفاتيح الاتصال';

  @override
  String get configMissingKeysBody =>
      'يبحث التطبيق تلقائياً وقت التشغيل في ثلاثة مصادر: علامة --dart-define، ثم ملف env.json على القرص (الجذر أو assets/env/)، ثم النسخة المحزومة داخل التطبيق — ولم يُعثر على أيٍّ منها. أنشئ الملف واملأه مرة واحدة ثم شغّل بلا أي علامة:';

  @override
  String get configEnvNote =>
      'الحزمة تُعلن مجلد assets/env/ كأصل، لذا غياب الملف لا يُسقط البناء من نسخة نظيفة. أنشئه من env.example.json أو شغّل: dart run tool/ensure_env.dart — والمفتاح المطلوب anon/public فقط، وservice_role لا يُستخدم في التطبيق إطلاقاً.';

  @override
  String get routeNotFoundTitle => 'الصفحة غير موجودة';

  @override
  String get routeNotFoundBody => 'المسار المطلوب غير معرّف في التطبيق:';

  @override
  String get editorPrecisionTitle => 'الضبط الدقيق';

  @override
  String get editorNudgeStep => 'خطوة النقل';

  @override
  String get editorNudgeStepHint =>
      'الأسهم في اللوحة تنقل بـ Shift = 10px أيضاً.';

  @override
  String get editorNudgeUp => 'نقل لأعلى';

  @override
  String get editorNudgeLeft => 'نقل لليسار';

  @override
  String get editorNudgeDown => 'نقل لأسفل';

  @override
  String get editorNudgeRight => 'نقل لليمين';

  @override
  String get editorScale => 'التحجيم';

  @override
  String get editorScaleHint =>
      'تحجيم نسبي حول مركز العنصر (عجلة الفأرة فوق الزر تسرّع الخطوة).';

  @override
  String get editorScaleUp => 'تكبير';

  @override
  String get editorScaleDown => 'تصغير';

  @override
  String get editorDecorTitle => 'الزخرفة المتجهية';

  @override
  String get editorDecorKind => 'نوع الزخرفة';

  @override
  String get editorDecorPalette => 'لوحة الألوان';

  @override
  String get editorDecorLayers => 'عدد الطبقات';

  @override
  String get editorDecorSeed => 'البذرة';

  @override
  String get editorDecorThickness => 'السماكة';

  @override
  String get editorDecorPrimary => 'اللون الأساسي';

  @override
  String get editorDecorSecondary => 'اللون الثاني';

  @override
  String get editorDecorAccent => 'لون اللمسة';

  @override
  String get editorDecorGradient => 'تدرّج الطبقات';

  @override
  String get editorDecorGallery => 'معرض الوصفات';

  @override
  String get editorDecorGalleryTitle => 'معرض الزخارف الجاهزة';

  @override
  String get editorClose => 'إغلاق';

  @override
  String get editorDecorPaletteCustom => 'مخصصة';

  @override
  String get decorKindModernWave => 'موجات حديثة';

  @override
  String get decorKindPaperCut => 'قصّ ورقي متعدد الطبقات';

  @override
  String get decorKindClassicCorner => 'إطار كلاسيكي مزخرف';

  @override
  String get decorKindGuilloche => 'نمط غيوش الأمني';

  @override
  String get decorKindRibbonBanner => 'شريط/وسام';

  @override
  String get decorPaletteRoyalGold => 'ذهبي ملكي';

  @override
  String get decorPaletteRoyalBlue => 'أزرق ملكي';

  @override
  String get decorPaletteEmerald => 'زمردي';

  @override
  String get decorPaletteBurgundy => 'عنابي';

  @override
  String get decorPaletteMidnight => 'كحلي ليلي';

  @override
  String get decorPaletteMono => 'رمادي أحادي';

  @override
  String get editorSignatureTitle => 'كتلة التوقيعات';

  @override
  String get editorSignatureCount => 'عدد التوقيعات';

  @override
  String get signatureCountOne => 'توقيع واحد';

  @override
  String get signatureCountTwo => 'توقيعان';

  @override
  String get signatureCountThree => 'ثلاثة توقيعات';

  @override
  String get editorSignatureOrder => 'ترتيب الخانات';

  @override
  String get editorSignatureOrderHint =>
      'في المستندات العربية تقع الخانة الأولى في أقصى اليمين.';

  @override
  String get editorSignatureFirstRight => 'الأولى يميناً';

  @override
  String get editorSignatureFirstLeft => 'الأولى يساراً';

  @override
  String get editorDirectionAuto => 'تلقائي';

  @override
  String get editorSignatureImageAlign => 'محاذاة الصورة';

  @override
  String get editorAlignStart => 'بداية';

  @override
  String get editorAlignCenter => 'وسط';

  @override
  String get editorAlignEnd => 'نهاية';

  @override
  String get editorSignatureDivider => 'خط التوقيع';

  @override
  String get editorVisible => 'ظاهر';

  @override
  String get editorHidden => 'مخفي';

  @override
  String get editorSignatureNameSize => 'حجم الاسم';

  @override
  String get editorSignatureRoleSize => 'حجم الدور';

  @override
  String get editorSignatureSpacing => 'التباعد';

  @override
  String get editorSignatureImageSize => 'حجم الصورة';

  @override
  String get editorSignatureNameColor => 'لون الاسم';

  @override
  String get editorSignatureRoleColor => 'لون الدور';

  @override
  String get editorFont => 'الخط';

  @override
  String get editorImageSource => 'مصدر الصورة';

  @override
  String get imageSourceAppAssets => 'أصول التطبيق';

  @override
  String get imageSourceMyLibrary => 'مكتبة أصولي';

  @override
  String get imageSourceLocalFile => 'ملف محلي';

  @override
  String get imageSourceEmbedded => 'بيانات مضمّنة';

  @override
  String get editorSignatureChangeImage => 'تغيير صورة التوقيع';

  @override
  String get editorSignatureAddImage => 'إضافة صورة توقيع';

  @override
  String get editorSignatureRemoveImage => 'إزالة صورة التوقيع';

  @override
  String get editorSignaturePickImageTitle =>
      'اختر صورة التوقيع من مكتبة أصولي';

  @override
  String get editorSignatureSlot => 'الخانة';

  @override
  String get editorSignatureRoleField => 'الدور (مثل: المدير العام)';

  @override
  String get editorSignatureNameField => 'اسم المُوقّع (يقبل حقلاً ديناميكياً)';

  @override
  String get editorFromMyLibrary => 'من مكتبة أصولي';

  @override
  String get paletteSignatureBlock => 'توقيعات';

  @override
  String get editorInsertFromLibraryTooltip =>
      'إدراج إطار أو شعار مرفوع مباشرةً';

  @override
  String get unsupportedElementVersionNote =>
      'هذا العنصر من إصدار أحدث من المحرر — يُحفظ كما هو ولا يمكن تعديله هنا.';

  @override
  String editorSelectedCount(Object count) {
    return '$count عناصر محددة';
  }

  @override
  String get editorClearSelection => 'إلغاء التحديد';

  @override
  String get editorGroup => 'المجموعة';

  @override
  String get editorOpacity => 'الشفافية';

  @override
  String get editorBringToFront => 'إلى المقدمة';

  @override
  String get editorSendToBack => 'إلى الخلف';

  @override
  String get editorDuplicate => 'تكرار';

  @override
  String get editorDeleteSelected => 'حذف المحدد';

  @override
  String get editorGroupDragHint =>
      'اسحب المجموعة بالماوس، والأسهم للتحريك الدقيق (Shift = 10px)، و Ctrl + نقر لتعديل التحديد.';

  @override
  String get editorBringForward => 'إلى الأمام';

  @override
  String get editorDuplicateElement => 'تكرار العنصر';

  @override
  String get editorDeleteElement => 'حذف العنصر';

  @override
  String get editorPageSettings => 'إعدادات الصفحة';

  @override
  String get editorPageSize => 'المقاس';

  @override
  String get editorUnit => 'الوحدة';

  @override
  String get editorWidth => 'العرض';

  @override
  String get editorHeight => 'الارتفاع';

  @override
  String get editorLabelText => 'نص';

  @override
  String get editorLabelShape => 'شكل';

  @override
  String get editorLabelSeal => 'ختم';

  @override
  String get editorLabelDecoration => 'زخرفة متجهية';

  @override
  String get editorLabelSignature => 'كتلة توقيعات';

  @override
  String get editorLabelImage => 'صورة/شعار';

  @override
  String get editorLabelQr => 'رمز QR';

  @override
  String get editorLabelUnknown => 'عنصر غير مدعوم';

  @override
  String get editorLabelDynamicField => 'حقل ديناميكي';

  @override
  String get editorPositionAndSize => 'الموضع والحجم';

  @override
  String get editorPosX => 'س';

  @override
  String get editorPosY => 'ص';

  @override
  String get editorRotation => 'الدوران';

  @override
  String get editorTextFormat => 'تنسيق النص';

  @override
  String get editorConvertToField => 'تحويل إلى حقل ديناميكي';

  @override
  String get editorFontWeight => 'الوزن';

  @override
  String get editorWeightRegular => 'عادي';

  @override
  String get editorWeightSemiBold => 'متوسط';

  @override
  String get editorWeightBold => 'عريض';

  @override
  String get editorFontSize => 'حجم الخط';

  @override
  String get editorLetterSpacing => 'تباعد الحروف';

  @override
  String get editorLineHeight => 'ارتفاع السطر';

  @override
  String get editorTextColor => 'لون النص';

  @override
  String get editorTextBackground => 'خلفية النص';

  @override
  String get editorTextAlign => 'المحاذاة';

  @override
  String get editorAlignJustify => 'ضبط';

  @override
  String get editorJustifyMode => 'طريقة الضبط';

  @override
  String get editorJustifyHint =>
      'الكشيدة تُطبَّق في ملف PDF (المعاينة تُظهر ضبط الفراغات)';

  @override
  String get editorJustifySpaces => 'فراغات';

  @override
  String get editorJustifyKashida => 'كشيدة';

  @override
  String get editorVerticalAlign => 'المحاذاة الرأسية';

  @override
  String get editorVerticalTop => 'أعلى';

  @override
  String get editorVerticalBottom => 'أسفل';

  @override
  String get editorDirection => 'الاتجاه';

  @override
  String get editorDirectionHint => 'اختصار التبديل: Ctrl+Shift+D';

  @override
  String get editorDirectionRtl => 'عربي';

  @override
  String get editorDirectionLtr => 'لاتيني';

  @override
  String get editorImage => 'الصورة';

  @override
  String get editorSource => 'المصدر';

  @override
  String get editorImageFit => 'ملاءمة الصورة';

  @override
  String get editorFitContain => 'احتواء كامل';

  @override
  String get editorFitCover => 'تغطية';

  @override
  String get editorFitFill => 'تمديد';

  @override
  String get assetPickerEmptyHint =>
      'لم ترفع أصولاً بعد. ارفع شعاراً أو توقيعاً أو ختماً لتستخدمه هنا وفي الطباعة.';

  @override
  String get assetPickerNoneOption => 'بلا (مصدر آخر)';

  @override
  String get assetPickerTitle => 'اختر صورة من مكتبة أصولي';

  @override
  String assetUploadType(Object type) {
    return 'رفع $type';
  }

  @override
  String get editorSeal => 'الختم';

  @override
  String get editorSealColor => 'لون الختم';

  @override
  String get editorSealRingColor => 'لون الحلقة';

  @override
  String get editorSealStarColor => 'لون النجمة';

  @override
  String get editorSealStarSize => 'حجم النجمة';

  @override
  String get editorShape => 'الشكل';

  @override
  String get editorFillColor => 'لون التعبئة';

  @override
  String get editorBorderColor => 'لون الحدود';

  @override
  String get editorBorderWidth => 'سماكة الحدود';

  @override
  String get editorCornerRadius => 'استدارة الزوايا';

  @override
  String get editorQrVerify => 'رمز التحقق';

  @override
  String get editorQrData => 'بيانات الرمز';

  @override
  String get editorQrColor => 'لون الرمز';

  @override
  String get editorQrBackground => 'خلفية الرمز';

  @override
  String editorConvertDialogMessage(Object text) {
    return 'التحويل يغيّر النص «$text» إلى علامة ديناميكية قابلة للربط في التوليد الجماعي.';
  }

  @override
  String get editorFieldKeyHint => 'مفتاح الحقل (مثل: الاسم، التاريخ، المرجع)';

  @override
  String get editorCustomKeyHint =>
      'أدخل مفتاحاً مخصصاً (بدون أقواس — سيُضاف تلقائياً)';

  @override
  String get editorCancel => 'إلغاء';

  @override
  String get editorConvert => 'تحويل';

  @override
  String get editorPath => 'المسار';

  @override
  String get editorTextContent => 'محتوى النص';

  @override
  String editorInsertFieldToken(Object token) {
    return 'إدراج $token';
  }

  @override
  String editorAddLabel(Object label) {
    return 'إضافة $label';
  }

  @override
  String assetInsertedSnack(Object name) {
    return 'أُدرج «$name» في القالب.';
  }

  @override
  String get paletteHeading => 'عنوان';

  @override
  String get paletteFrame => 'مستطيل/برواز';

  @override
  String get paletteDivider => 'خط فاصل';

  @override
  String get paletteLogo => 'شعار/توقيع';

  @override
  String get evSignatureEmptyLabel => 'توقيعات فارغة';

  @override
  String get evSignatureEmptyDetail => 'أضف دوراً واسماً وصورة توقيع';

  @override
  String get evSignatureMissingLabel => 'توقيع محذوف';

  @override
  String get evUploadToLibraryDetail => 'ارفع الصورة إلى مكتبة الأصول';

  @override
  String get evImageNotFoundLabel => 'صورة غير موجودة';

  @override
  String get evNoFileLabel => 'لم يُحدَّد ملف';

  @override
  String get evChooseFromAssetsDetail => 'اختر صورة من مكتبة الأصول';

  @override
  String get evAssetMissingLabel => 'أصل محذوف';

  @override
  String get evReselectAssetDetail => 'أعد اختيار الإطار/الأصل من المكتبة';

  @override
  String get evInvalidImageLabel => 'صورة غير صالحة';

  @override
  String get evRenderDataFailedDetail => 'تعذّر عرض البيانات';

  @override
  String get evInvalidDataLabel => 'بيانات غير صالحة';

  @override
  String get evDecodeFailedDetail => 'تعذّر فك ترميز الصورة';

  @override
  String get evEmptyQrLabel => 'رمز فارغ';

  @override
  String get evEmptyQrDetail => 'أدخل قيمة الرمز في شريط الخصائص';

  @override
  String evUnknownElementLabel(Object type) {
    return 'عنصر غير مدعوم: $type';
  }

  @override
  String get alpFilterAll => 'الكل';

  @override
  String get alpEmptyHint =>
      'لا توجد أصول مرفوعة من الأنواع المطلوبة. ارفع إطاراً أو شعاراً من قسم «الأصول والتوقيعات» ثم أعد المحاولة.';

  @override
  String alpNoFilteredAssets(Object type) {
    return 'لا توجد أصول من النوع «$type».';
  }

  @override
  String get authWelcomeBack => 'مرحباً بك في جودكرافت.';

  @override
  String get authResetLinkSent =>
      'تم إرسال رابط الاستعادة. تحقّق من بريدك الإلكتروني.';

  @override
  String get authLogin => 'تسجيل الدخول';

  @override
  String get authLoginSubtitle =>
      'بريدك الإلكتروني وكلمة المرور للمتابعة إلى لوحة التحكم.';

  @override
  String get authNoAccount => 'ليس لديك حساب؟';

  @override
  String get authCreateAccountLink => 'أنشئ حساباً جديداً';

  @override
  String get authConfirmEmailThenLogin =>
      'تم إنشاء حسابك. يرجى تأكيد بريدك الإلكتروني أولاً ثم تسجيل الدخول.';

  @override
  String get authEmail => 'البريد الإلكتروني';

  @override
  String get authPassword => 'كلمة المرور';

  @override
  String get authForgotPassword => 'نسيت كلمة المرور؟';

  @override
  String get authEnterDashboard => 'دخول إلى اللوحة';

  @override
  String get authResetPassword => 'استعادة كلمة المرور';

  @override
  String get authResetPasswordHint =>
      'أدخل بريدك الإلكتروني وسنرسل لك رابط إعادة تعيين كلمة المرور.';

  @override
  String get authSendLink => 'إرسال الرابط';

  @override
  String get authConfirmEmailMessage =>
      'تم إنشاء حسابك. تحقّق من بريدك الإلكتروني لتأكيد الحساب ثم سجّل الدخول.';

  @override
  String get authAccountCreatedWelcome =>
      'تم إنشاء حسابك. أهلاً بك في جودكرافت.';

  @override
  String get authCreateAccount => 'إنشاء حساب';

  @override
  String get authRegisterSubtitle =>
      'حسابك يحفظ قوالبك وأصولك (الشعار، التوقيع، الختم) لإعادة استخدامها في كل مشاريعك.';

  @override
  String get authHaveAccount => 'لديك حساب بالفعل؟';

  @override
  String get authFullName => 'الاسم الكامل';

  @override
  String get authFullNameHint => 'مثال: عبدالله الأحمد';

  @override
  String get authName => 'الاسم';

  @override
  String get authOrgName => 'اسم الجهة / المؤسسة (اختياري)';

  @override
  String get authOrgNameHint => 'مثال: جمعية جود الخيرية';

  @override
  String get authOrgHelper => 'يُطبع على الشهادات والعقود تلقائياً.';

  @override
  String get authOrgNameShort => 'اسم الجهة';

  @override
  String get authPasswordHint => '8 أحرف على الأقل';

  @override
  String authPasswordRule(Object min) {
    return 'استخدم $min أحرف أو أكثر مع أرقام ورموز.';
  }

  @override
  String get authConfirmPassword => 'تأكيد كلمة المرور';

  @override
  String get authCreateAccountButton => 'إنشاء الحساب';

  @override
  String get authFeatureLocalExcel =>
      'معالجة محلية كاملة لملفات Excel — بياناتك لا تغادر جهازك';

  @override
  String get authFeaturePdf =>
      'توليد PDF بخطوط عربية عالية الجودة مع دعم كامل للاتجاه RTL';

  @override
  String get authFeatureTemplates =>
      'قوالبك محفوظة في حسابك وجاهزة لإعادة الاستخدام';

  @override
  String get authTagline => 'شهاداتك وعقودك الرسمية… بجودة تُطبع بثقة.';

  @override
  String authVersion(Object name, Object version) {
    return '$name • الإصدار $version';
  }

  @override
  String get dashModules => 'وحدات المنصة';

  @override
  String dashWelcome(Object name) {
    return 'أهلاً بك، $name';
  }

  @override
  String dashSubscription(Object tier) {
    return 'الاشتراك: $tier';
  }

  @override
  String dashOrg(Object name) {
    return 'الجهة: $name';
  }

  @override
  String get dashOrgMissing =>
      'لم تُسجّل اسم جهتك بعد — سيُطبع تلقائياً على الشهادات والعقود.';

  @override
  String get dashOpenModule => 'فتح الوحدة';

  @override
  String get dashRoadmapSupabase =>
      'تأسيس قاعدة بيانات Supabase (جداول + RLS + Triggers)';

  @override
  String get dashRoadmapModular => 'هيكل Modular Feature-First قابل للتوسّع';

  @override
  String get dashRoadmapTheme => 'الثيم البصري للهوية ودعم RTL بخط Cairo';

  @override
  String get dashRoadmapAuth =>
      'المصادقة: تسجيل الدخول وإنشاء الحساب واستعادة كلمة المرور';

  @override
  String get dashPhaseOneDone => 'المرحلة الأولى مكتملة';

  @override
  String get dashNextPhase =>
      'التالية: محرك PDF والخطوط العربية أوفلاين، ثم محرر القوالب البصري.';

  @override
  String get destDashboard => 'لوحة التحكم';

  @override
  String get destDashboardDesc => 'نظرة عامة على مشاريعك وقوالبك.';

  @override
  String get destCertificates => 'محـرّك الشهادات';

  @override
  String get destCertificatesDesc =>
      'تصميم شهادات أفقية (Landscape) من قالب قابل للتعديل.';

  @override
  String get destContracts => 'محـرّك العقود';

  @override
  String get destContractsDesc =>
      'صياغة عقود رأسية (Portrait) بحقول ديناميكية.';

  @override
  String get destBatch => 'التوليد الجماعي';

  @override
  String get destBatchDesc =>
      'قراءة ملف Excel محلياً وتوليد مئات الشهادات دفعة واحدة.';

  @override
  String get destTemplates => 'مكتبة القوالب';

  @override
  String get destTemplatesDesc =>
      'إدارة قوالبك المحفوظة وتصنيفها وإعادة استخدامها.';

  @override
  String get destAssets => 'الأصول والتوقيعات';

  @override
  String get destAssetsDesc => 'الشعار والختم والتوقيع والإطارات الخاصة بك.';

  @override
  String get dashUser => 'مستخدم';

  @override
  String get dashLogoutSuccess => 'تم تسجيل الخروج بنجاح.';

  @override
  String get dashLogoutError => 'تعذّر تسجيل الخروج. حاول مرة أخرى.';

  @override
  String get commonSave => 'حفظ';

  @override
  String get commonPreview => 'معاينة';

  @override
  String get commonOptions => 'خيارات';

  @override
  String get tplDelete => 'حذف';

  @override
  String get tplSortRecentlyUpdated => 'الأحدث تعديلاً';

  @override
  String get tplSortTitleAsc => 'الاسم (أ - ي)';

  @override
  String get tplSortLabel => 'الترتيب';

  @override
  String get tplSubtitle =>
      'قوالب جاهزة احترافية + قوالبك المحفوظة — بحث وتصفية وفتح واستيراد، أوفلاين بالكامل.';

  @override
  String get tplRefreshTooltip => 'تحديث القائمة';

  @override
  String get tplSearchHint => 'بحث في القوالب…';

  @override
  String get tplNoResultsTitle => 'لا نتائج مطابقة';

  @override
  String get tplNoResultsMessage =>
      'جرّب كلمة بحث أخرى أو أعد ضبط عامل التصفية.';

  @override
  String tplAddedToLocal(Object title) {
    return 'أُضيف «$title» إلى قوالبك المحلية.';
  }

  @override
  String get tplCloudRequiresConnection =>
      'حفظ القوالب في السحابة يتطلب الاتصال بمشروع Supabase. احفظه محلياً بدل ذلك.';

  @override
  String tplSavedToCloud(Object title) {
    return 'حُفظ «$title» في السحابة.';
  }

  @override
  String get tplRenamed => 'أُعيد تسمية القالب.';

  @override
  String tplCopySuffix(Object title) {
    return '$title (نسخة)';
  }

  @override
  String tplCopyCreated(Object title) {
    return 'أُنشئت نسخة من «$title».';
  }

  @override
  String get tplNowPrivate => 'القالب الآن خاص.';

  @override
  String get tplNowPublic => 'القالب الآن عام (قراءة فقط للآخرين).';

  @override
  String tplConfirmCloudDelete(Object title) {
    return 'سيُحذف «$title» من السحابة نهائياً. لا يمكن التراجع.';
  }

  @override
  String tplCloudDeleted(Object title) {
    return 'حُذف القالب «$title».';
  }

  @override
  String tplConfirmLocalDelete(Object title) {
    return 'سيُحذف «$title» من هذا الجهاز. القالب الجاهز الأصلي يبقى متاحاً في المكتبة.';
  }

  @override
  String tplLocalDeleted(Object title) {
    return 'حُذف القالب المحلي «$title».';
  }

  @override
  String get tplDeleteTitle => 'حذف القالب';

  @override
  String get tplRenameTitle => 'عنوان القالب';

  @override
  String get tplFieldTitle => 'العنوان';

  @override
  String tplPreviewLabel(Object title) {
    return 'معاينة: $title';
  }

  @override
  String tplCount(Object count) {
    return '$count قالب';
  }

  @override
  String tplCloudLoadError(Object message) {
    return 'تعذّر تحميل القوالب السحابية: $message';
  }

  @override
  String get tplPublicBadge => 'قالب عام';

  @override
  String get tplOrientationLandscape => 'أفقي';

  @override
  String get tplOrientationPortrait => 'رأسي';

  @override
  String get tplPresetOffline => 'قالب جاهز • متاح أوفلاين';

  @override
  String tplSchemaVersion(Object version) {
    return 'مخطط v$version';
  }

  @override
  String get tplOpenAsTemplate => 'فتح كقالب';

  @override
  String get tplOpen => 'فتح';

  @override
  String get tplUseInBatch => 'استخدام في التوليد الجماعي';

  @override
  String get tplImportLocal => 'استيراد محلياً';

  @override
  String get tplSaveToCloud => 'حفظ في السحابة';

  @override
  String get tplDeleteLocal => 'حذف محلياً';

  @override
  String get tplRename => 'إعادة التسمية';

  @override
  String get tplMakePrivate => 'جعله خاصاً';

  @override
  String get tplMakePublic => 'جعله عاماً';

  @override
  String get tplNoDate => 'بلا تاريخ';

  @override
  String get amSubtitle =>
      'ارفع شعارك وختمك وتوقيعك مرة واحدة، ثم أدرجه في أي قالب — يُحفظ على جهازك ويُستعاد أوفلاين.';

  @override
  String get amSearchHint => 'بحث في الأصول…';

  @override
  String get amTypeLabel => 'النوع';

  @override
  String get amUploadTooltip => 'رفع أصل جديد';

  @override
  String get amUpload => 'رفع أصل';

  @override
  String get amEmptyTitle => 'لا توجد أصول بعد';

  @override
  String get amEmptyMessage =>
      'ارفع شعار مؤسستك أو توقيعك أو ختمك، ثم أدرجه في أي قالب من شريط خصائص الصورة.';

  @override
  String get amNoResultsMessage => 'جرّب اسماً آخر أو أعد ضبط عامل التصفية.';

  @override
  String get amRenamed => 'أُعيدت تسمية الأصل.';

  @override
  String amMovedToType(Object type) {
    return 'نُقل الأصل إلى «$type».';
  }

  @override
  String get amDeleteTitle => 'حذف الأصل';

  @override
  String amConfirmDelete(Object name) {
    return 'سيُحذف «$name» من هذا الجهاز. القوالب التي تستخدمه ستفقد الصورة (دون فشل الطباعة).';
  }

  @override
  String amDeleted(Object name) {
    return 'حُذف الأصل «$name».';
  }

  @override
  String get amRenameTitle => 'إعادة تسمية الأصل';

  @override
  String amCount(Object count) {
    return '$count أصل';
  }

  @override
  String amMakeType(Object type) {
    return 'اجعل النوع: $type';
  }
}
