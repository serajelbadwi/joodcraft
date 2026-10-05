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

  @override
  String get amCacheLabel => 'ذاكرة الصور على القرص';

  @override
  String amCacheUsage(Object count, Object size) {
    return '$count ملف · $size';
  }

  @override
  String amCacheUsageOf(Object count, Object used, Object limit) {
    return '$count ملف · $used من $limit';
  }

  @override
  String get amCacheEmpty => 'لا ذاكرة قرصية بعد';

  @override
  String get amCacheClear => 'مسح الذاكرة';

  @override
  String get amCacheCleared => 'تم مسح ذاكرة الصور على القرص.';

  @override
  String get commonRetry => 'إعادة المحاولة';

  @override
  String get commonPrint => 'طباعة';

  @override
  String get commonExportPdf => 'تصدير PDF';

  @override
  String get commonExportFailed => 'تعذّر تصدير ملف PDF.';

  @override
  String get commonPrintFailed => 'تعذّر إرسال الملف إلى الطابعة.';

  @override
  String commonExportReady(Object name) {
    return 'تم تجهيز الملف للحفظ باسم $name.';
  }

  @override
  String get commonGenerating => 'جارٍ التوليد…';

  @override
  String get commonDataPanelTitle => 'بيانات تجريبية';

  @override
  String evElementCount(Object count) {
    return '$count عنصراً';
  }

  @override
  String get evStatusDynamicFields => ' • حقول ديناميكية';

  @override
  String get evStatusUnsaved => ' • تعديلات غير محفوظة';

  @override
  String get tevNewTemplateTitle => 'قالب جديد';

  @override
  String get tevUnsavedTitle => 'تعديلات غير محفوظة';

  @override
  String tevUnsavedMessage(Object title) {
    return 'لديك تعديلات على «$title» لم تُحفَظ بعد. هل تريد حفظها قبل المغادرة؟';
  }

  @override
  String get tevLeaveWithoutSaving => 'المغادرة دون حفظ';

  @override
  String get tevSaveAndLeave => 'حفظ والمغادرة';

  @override
  String get tevViewMode => 'طريقة العرض';

  @override
  String get tevModeEditor => 'المحرر';

  @override
  String get tevModePreview => 'معاينة PDF';

  @override
  String get tevPaperDirection => 'اتجاه الورقة';

  @override
  String get tevWidthCm => 'العرض (cm)';

  @override
  String get tevHeightCm => 'الارتفاع (cm)';

  @override
  String get tevUndo => 'تراجع (Ctrl+Z)';

  @override
  String get tevRedo => 'إعادة (Ctrl+Y)';

  @override
  String get tevSnapGrid => 'شبكة التوجيه';

  @override
  String get tevGuidesOn => 'خطوط الإرشاد الذكية: مُفعّلة (إيقاف)';

  @override
  String get tevGuidesOff => 'خطوط الإرشاد الذكية: معطّلة (تشغيل)';

  @override
  String get tevZoom => 'التكبير';

  @override
  String get tevDocumentBackground => 'خلفية المستند';

  @override
  String get tevFrameFromLibrary => 'إطار من مكتبة أصولي';

  @override
  String get tevChangeTitle => 'تغيير عنوان القالب';

  @override
  String get tevMyTemplates => 'قوالبي';

  @override
  String get tevSaveAs => 'حفظ باسم';

  @override
  String get tevSaveTemplate => 'حفظ القالب';

  @override
  String get tevSaveUnavailable => 'الحفظ غير متاح';

  @override
  String get tevSaveNeedsSupabase =>
      'الحفظ يتطلب الاتصال بمشروع Supabase. شغّل التطبيق بمفاتيح مشروعك (env.json) لتتمكن من حفظ القوالب.';

  @override
  String tevMissingAssets(Object list) {
    return 'أصول مفقودة: $list — أعد اختيار الإطار/الأصل من «مكتبة أصولي» لتفادي ظهورها فارغة.';
  }

  @override
  String get tevTemplateLibraryNeedsSupabase =>
      'مكتبة القوالب تتطلب الاتصال بمشروع Supabase.';

  @override
  String tevOpenedTemplate(Object title) {
    return 'تم فتح «$title».';
  }

  @override
  String get tevTitleHint => 'مثال: شهادة إتمام دورة إدارة المشاريع';

  @override
  String get tevContinue => 'متابعة';

  @override
  String get tevSavedTemplates => 'قوالبي المحفوظة';

  @override
  String get tevNoSavedTemplates =>
      'لا توجد قوالب محفوظة بعد. احفظ قالباً من الزر «حفظ القالب».';

  @override
  String get ecIncrease => 'زيادة';

  @override
  String get ecDecrease => 'إنقاص';

  @override
  String get ecQuickPalette => 'لوحة سريعة';

  @override
  String get ecFullPicker => 'منتقي ألوان كامل';

  @override
  String get ecRemoveColor => 'إزالة اللون';

  @override
  String get ecNone => 'بلا';

  @override
  String get ecPickColorTitle => 'اختيار لون';

  @override
  String get ecApply => 'تطبيق';

  @override
  String tevBackgroundAdded(Object name) {
    return 'أُضيف «$name» كخلفية للمستند.';
  }

  @override
  String get cfpUploadTooltip => 'رفع خط مخصص (.ttf / .otf)';

  @override
  String get cfpManageTooltip => 'إدارة الخطوط المرفوعة';

  @override
  String get cfpNotice =>
      'الخطوط المرفوعة تُحفظ على جهازك فقط وتُستخدم فوراً هنا وفي الطباعة — بلا إنترنت.';

  @override
  String get cfpMyFonts => 'خطوطي المخصصة';

  @override
  String get cfpNoFonts => 'لم ترفع خطوطاً بعد';

  @override
  String get cfpBuiltinOption => 'بلا (الخط المضمّن)';

  @override
  String get cfpGroupBuiltin => 'الخطوط المضمّنة';

  @override
  String get cfpGroupUploaded => 'خطوطي المرفوعة';

  @override
  String get cfpGroupSystem => 'خطوط النظام';

  @override
  String get cfpSearchHint => 'ابحث في الخطوط…';

  @override
  String get cfpNoMatch => 'لا توجد خطوط مطابقة.';

  @override
  String get cfpPickTitle => 'اختر ملف خط (TTF أو OTF)';

  @override
  String cfpPickerError(Object error) {
    return 'تعذّر فتح منتقي الملفات: $error';
  }

  @override
  String cfpReadError(Object name, Object error) {
    return 'تعذّر قراءة \"$name\": $error';
  }

  @override
  String get cfpFontAdded => 'أُضيف الخط واستُخدم فوراً.';

  @override
  String cfpFontsAdded(Object count) {
    return 'أُضيف $count خطوط.';
  }

  @override
  String get cfpLibraryTitle => 'مكتبة خطوطي المخصصة';

  @override
  String get cfpLibraryNotice =>
      'كل الخطوط محفوظة على جهازك فقط. تحذير: حذف خط يستخدمه قالب يُرجع ذلك القالب إلى الخط المضمّن بدل الفشل.';

  @override
  String get cfpEmpty => 'لا توجد خطوط مرفوعة بعد.';

  @override
  String get cfpCoverageFull => 'تغطية عربية كاملة';

  @override
  String get cfpCoveragePartial => 'تغطية عربية ناقصة';

  @override
  String get cfpUploadNew => 'رفع خط جديد';

  @override
  String get ptpPrepError => 'تعذّر تحضير المعاينة. تحقّق من ملف القالب.';

  @override
  String ptpElapsedSize(Object ms, Object kb) {
    return '$ms م.ث — $kb ك.ب';
  }

  @override
  String get ptpGeneratingNote => '— تُحدَّث المعاينة تلقائياً';

  @override
  String get ptpGenerateFailedTitle => 'تعذّر توليد المعاينة';

  @override
  String get ptpPreparingTitle => 'جارٍ تحضير المحرك…';

  @override
  String get ptpPreparingMessage =>
      'يتم تحميل الخطوط المحزومة وتوليد أول نسخة من الملف.';

  @override
  String get ptpShowFailedTitle => 'تعذّر عرض المعاينة';

  @override
  String cfgOverride(Object override) {
    return 'بديل لبناء بقيم محددة يتفوق على الملف: $override';
  }

  @override
  String get tevBackgroundTitle => 'خلفية المستند من مكتبة أصولي';

  @override
  String get tevAddElement => 'إضافة عنصر';

  @override
  String get commonUndo => 'تراجع';

  @override
  String get bpTitle => 'التوليد الجماعي من Excel';

  @override
  String get bpSubtitle =>
      'استورد ملف .xlsx أو .csv، اربط أعمدته بحقول القالب، ثم ولّد ملف PDF بصفحة لكل سجل — كل ذلك على جهازك بلا إنترنت.';

  @override
  String get bpStepTemplate => '1) القالب';

  @override
  String get bpLoadingSampleTemplate => 'جارٍ تحميل القالب النموذجي…';

  @override
  String bpTemplateInfo(Object name) {
    return 'القالب: $name • الحقول المطلوبة:';
  }

  @override
  String get bpLoadingTemplates => 'جارٍ تحميل قوالبك…';

  @override
  String get bpNoTemplates =>
      'لا توجد قوالب محفوظة بعد — أنشئ قالباً في المحرّر أو استورده من مكتبة القوالب ليظهر هنا.';

  @override
  String get bpTemplateFromMine => 'قالب من قوالبي';

  @override
  String get bpSampleTemplatesHeader => '— القوالب النموذجية —';

  @override
  String bpTemplateEntry(Object title, Object source) {
    return '$title  •  $source';
  }

  @override
  String get bpSourceCloud => 'سحابي';

  @override
  String get bpSourceLocal => 'محلي';

  @override
  String get bpStepDataFile => '2) ملف البيانات';

  @override
  String get bpReadingFile => 'جارٍ قراءة الملف…';

  @override
  String get bpNoFileChosen => 'لم يُختَر ملف بعد — الصيغ المدعومة:';

  @override
  String bpFileSummary(Object name, Object rows, Object cols) {
    return '$name — $rows صفاً، $cols عموداً';
  }

  @override
  String bpSheetSuffix(Object name) {
    return ' (ورقة: $name)';
  }

  @override
  String get bpChooseFile => 'اختيار ملف';

  @override
  String get bpRemove => 'إزالة';

  @override
  String get bpHeaderRow => 'صف العناوين';

  @override
  String bpAutoRow(Object n) {
    return 'تلقائي (الصف $n)';
  }

  @override
  String bpRow(Object n) {
    return 'الصف $n';
  }

  @override
  String bpAutoRowLong(Object n) {
    return 'تلقائي — الصف $n';
  }

  @override
  String bpRowPreview(Object n, Object preview) {
    return 'الصف $n: $preview';
  }

  @override
  String get bpEmptyRow => '(صف فارغ)';

  @override
  String get bpWorksheet => 'ورقة العمل';

  @override
  String get bpPickDataFile => 'اختر ملف البيانات (Excel أو CSV)';

  @override
  String bpReadFileError(Object error) {
    return 'تعذّر قراءة الملف: $error';
  }

  @override
  String bpFileReadRows(Object rows, Object cols) {
    return 'قُرئ الملف محلياً: $rows صفاً و$cols عموداً.';
  }

  @override
  String bpSaveError(Object error) {
    return 'تعذّر حفظ التعديل في القالب: $error';
  }

  @override
  String get bpMapFieldTitle => 'تعيين حقل ديناميكي لهذا العنصر';

  @override
  String get bpMapFieldBody =>
      'سيُستبدل نص هذا العنصر وحده بحقل، ولن يُمسّ أي عنصر آخر.';

  @override
  String get bpUndoConvert => 'تم التراجع عن التحويل.';

  @override
  String get bpUndoConvertSaved =>
      'تم التراجع عن التحويل واستعادة النص في القالب.';

  @override
  String bpRestoreError(Object error) {
    return 'تعذّر استعادة النص في القالب: $error';
  }

  @override
  String bpGeneratedReport(Object count) {
    return 'تم توليد $count سجل';
  }

  @override
  String bpSkippedSuffix(Object count) {
    return ' وتخطّي $count';
  }

  @override
  String get bpReadyToSave => 'تم تجهيز الملف للحفظ.';

  @override
  String get bpStepMapping => '3) ربط الأعمدة بالحقول';

  @override
  String get bpChooseFileFirst => 'اختر ملفاً أولاً ليظهر جدول الربط.';

  @override
  String get bpNoDynamicFields => 'لا حقول ديناميكية في القالب الحالي.';

  @override
  String bpMappedCount(Object mapped, Object total) {
    return 'مرتبط $mapped من $total عموداً';
  }

  @override
  String get bpAutoMapHint =>
      'بعد اختيار الملف سيُقترح ربط تلقائي ذكي، ويمكنك تعديل كل عمود.';

  @override
  String get bpNoFieldsHelp =>
      'القالب المختار لا يحتوي حقولاً ديناميكية، فلا شيء ليُربط بأعمدة الملف. افتح القالب في المحرّر وأدرج «حقل ديناميكي» في خانة الاسم ثم احفظ القالب ثم أعد المحاولة.';

  @override
  String get bpAutoMap => 'ربط تلقائي';

  @override
  String get bpClearMapping => 'مسح الربط';

  @override
  String get bpNameFieldWarning =>
      'هذا القالب لا يحتوي على حقل اسم ديناميكي — لا تربط عمود الاسم بحقل تاريخ أو رقم إشعار، فقد يُطبع الاسم في مكانه الخطأ. اختر مفتاح الاسم من قائمة العمود، أو حوّل نص الاسم الثابت من المحرّر إلى حقل ديناميكي.';

  @override
  String bpStaticNameHints(Object preview) {
    return 'نصّ ثابت يشبه الاسم: «$preview» — لا يستبدله أي حقل ديناميكي.';
  }

  @override
  String get bpConvertToNameField => 'حوّله إلى حقل اسم المتدرب';

  @override
  String bpDuplicateField(Object field) {
    return 'الحقل «$field» مرتبط بأكثر من عمود. اجعل كل حقل بعمود واحد.';
  }

  @override
  String bpUnmappedColumns(Object count) {
    return '$count عموداً بلا ربط — لن تُستخدم بياناته في الشهادات.';
  }

  @override
  String bpColumn(Object n) {
    return 'عمود $n';
  }

  @override
  String get bpEmptyCell => '(فارغ)';

  @override
  String get bpUnmapped => '— غير مربوط —';

  @override
  String get bpStepMissing => '4) الخلايا الفارغة والبيانات الناقصة';

  @override
  String get bpNoNotes => 'لا ملاحظات قبل اختيار الملف.';

  @override
  String get bpStepGenerate => '5) التوليد';

  @override
  String bpGenerating(Object progress) {
    return 'جارٍ التوليد… $progress';
  }

  @override
  String get bpGenerateHint => 'ملف PDF واحد، صفحة لكل سجل مُصدر.';

  @override
  String get bpGeneratePickFile => 'اختر ملف بيانات أولاً ليُفعَّل التوليد.';

  @override
  String get bpMappingInvalid =>
      'الربط غير صالح — لا تُربط الحقل نفسه بعمودين.';

  @override
  String get bpMapAtLeastOne =>
      'اربط عموداً واحداً على الأقل بحقل من القالب ليُفعَّل التوليد.';

  @override
  String get bpGenerateCertificates => 'توليد الشهادات';

  @override
  String get bpRegenerate => 'إعادة التوليد';

  @override
  String get bpStatGenerated => 'مُصدرة';

  @override
  String get bpStatSkipped => 'متخطّاة';

  @override
  String get bpStatPages => 'صفحات';

  @override
  String get bpStatSize => 'الحجم';

  @override
  String bpKilobytes(Object value) {
    return '$value ك.ب';
  }

  @override
  String get bpStatTime => 'الزمن';

  @override
  String bpMilliseconds(Object value) {
    return '$value م.ث';
  }

  @override
  String bpCompletion(Object pct, Object total) {
    return 'اكتمال $pct% من $total صفاً.';
  }

  @override
  String get bpSkippedRows => 'صفوف لم تُصدر:';

  @override
  String bpRowSkipReason(Object n, Object reason) {
    return 'صف $n: $reason';
  }

  @override
  String get bpPreviewHere => 'المعاينة تظهر هنا';

  @override
  String get bpPreviewHint =>
      'اختر ملف البيانات، اضبط الربط، ثم اضغط «توليد الشهادات» — سترى أول صفحة من الملف الناتج هنا مباشرة.';

  @override
  String get bpAssignByTapTitle => 'تعيين الحقول بالنقر';

  @override
  String get bpAssignByTapBody =>
      'انقر أي نص في القالب لتعيينه إلى حقل ديناميكي بنفسك. لن يُمسّ أي عنصر آخر — لا التاريخ ولا اسم المدير ولا أي نص ثابت.';

  @override
  String get bpNoTexts => 'لا نصوص في هذا القالب.';

  @override
  String get bpEmptyText => '(نص فارغ)';

  @override
  String get bpDynamicFieldTap => 'حقل ديناميكي — انقر لتغييره';

  @override
  String get bpStaticTextTap => 'نص ثابت — انقر للتعيين';

  @override
  String get bpAssignField => 'تعيين حقل';

  @override
  String get bpKindCertificate => 'شهادة';

  @override
  String get bpKindContract => 'عقد';

  @override
  String bpLoadSampleError(Object error) {
    return 'تعذّر تحميل القالب النموذجي: $error';
  }

  @override
  String bpReadSheetError(Object error) {
    return 'تعذّر قراءة الورقة: $error';
  }

  @override
  String bpUpdateHeaderRowError(Object error) {
    return 'تعذّر تحديث صف العناوين: $error';
  }

  @override
  String get bpChooseTemplateFirst => 'اختر قالباً (شهادة أو عقد) قبل التوليد.';

  @override
  String bpBatchTitle(Object kind) {
    return '$kind جماعية — JoodCraft';
  }

  @override
  String bpGenerateError(Object error) {
    return 'تعذّر التوليد الجماعي: $error';
  }

  @override
  String get bpWarnNoDynamicFields =>
      'هذا القالب بلا حقول ديناميكية — لن تتغيّر البيانات بين السجلات. أضف حقل «اسم المتدرب» من شريط المحرّر ثم احفظ القالب.';

  @override
  String get bpWarnNoNameField =>
      'هذا القالب لا يحتوي على حقل اسم ديناميكي — قد يربط عمود الاسم بحقل تاريخ أو رقم إشعار فيظهر الاسم في مكانه الخطأ. حوّل نص الاسم الثابت إلى حقل أو أعد تصميم القالب.';

  @override
  String bpAssignedTemp(Object token) {
    return 'عُيّن هذا العنصر إلى $token للتوليد الحالي — بقية العناصر لم تُمسّ. احفظ القالب لتثبيت التعديل دائماً.';
  }

  @override
  String bpAssignedSaved(Object token) {
    return 'عُيّن هذا العنصر إلى $token وحُفظ التعديل في القالب. بقية العناصر لم تُمسّ.';
  }

  @override
  String get commonShow => 'إظهار';

  @override
  String get commonHide => 'إخفاء';

  @override
  String get themeSwitchToLight => 'التبديل إلى المظهر الفاتح';

  @override
  String get themeSwitchToDark => 'التبديل إلى المظهر الداكن';

  @override
  String commonComingSoonPhase(Object phase) {
    return 'قيد التنفيذ — المرحلة $phase';
  }

  @override
  String get cbNewCertificateTitle => 'شهادة جديدة';

  @override
  String get cbNewContractTitle => 'عقد جديد';

  @override
  String get cbBeneficiaryDataTitle => 'بيانات المستفيد (تجريبية)';

  @override
  String get cbContractDataTitle => 'بيانات العقد (تجريبية)';
}
