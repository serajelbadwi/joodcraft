// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Urdu (`ur`).
class AppLocalizationsUr extends AppLocalizations {
  AppLocalizationsUr([String locale = 'ur']) : super(locale);

  @override
  String get appTagline => 'سرکاری سرٹیفکیٹ اور معاہدے آف لائن بنائیں';

  @override
  String get navDashboard => 'ڈیش بورڈ';

  @override
  String get navCertificates => 'سرٹیفکیٹ بلڈر';

  @override
  String get navContracts => 'معاہدہ بلڈر';

  @override
  String get navBatch => 'بیچ جنریشن';

  @override
  String get navTemplates => 'ٹیمپلیٹ لائبریری';

  @override
  String get navAssets => 'اثاثے اور دستخط';

  @override
  String get actionSignOut => 'سائن آؤٹ';

  @override
  String get actionBackToDashboard => 'ڈیش بورڈ پر واپس جائیں';

  @override
  String get offlineProcessingLabel => 'مقامی پروسیسنگ';

  @override
  String get themeTooltip => 'تھیم تبدیل کریں';

  @override
  String get themeSystem => 'سسٹم';

  @override
  String get themeLight => 'روشن';

  @override
  String get themeDark => 'گہرا';

  @override
  String get languageTooltip => 'زبان تبدیل کریں';

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
  String get configMissingKeysTitle => 'کنکشن کیز نہیں ملیں';

  @override
  String get configMissingKeysBody =>
      'ایپ آغاز پر تین ذرائع میں کیز تلاش کرتی ہے: --dart-define فلیگ، پھر ڈسک پر env.json فائل (روٹ یا assets/env/) اور پھر ایپ میں شامل کاپی — کوئی نہیں ملی۔ فائل بنائیں، ایک بار بھریں اور بغیر فلیگ چلائیں:';

  @override
  String get configEnvNote =>
      'بنڈل assets/env/ کو اثاثہ قرار دیتا ہے، اس لیے فائل کی عدم موجودگی صاف بلڈ کو نہیں توڑتی۔ env.example.json سے بنائیں یا چلائیں: dart run tool/ensure_env.dart — صرف anon/public کلید درکار ہے؛ service_role ایپ میں کبھی استعمال نہیں ہوتی۔';

  @override
  String get routeNotFoundTitle => 'صفحہ نہیں ملا';

  @override
  String get routeNotFoundBody => 'مطلوبہ راستہ ایپ میں متعین نہیں:';

  @override
  String get editorPrecisionTitle => 'درست کنٹرول';

  @override
  String get editorNudgeStep => 'حرکت کا مرحلہ';

  @override
  String get editorNudgeStepHint =>
      'کینوس کے تیر بھی Shift = 10px حرکت دیتے ہیں۔';

  @override
  String get editorNudgeUp => 'اوپر حرکت';

  @override
  String get editorNudgeLeft => 'بائیں حرکت';

  @override
  String get editorNudgeDown => 'نیچے حرکت';

  @override
  String get editorNudgeRight => 'دائیں حرکت';

  @override
  String get editorScale => 'پیمانہ';

  @override
  String get editorScaleHint =>
      'عنصر کے مرکز کے گرد نسبتی پیمانہ (باریک مرحلے کے لیے بٹنوں پر وہیل)۔';

  @override
  String get editorScaleUp => 'بڑا کریں';

  @override
  String get editorScaleDown => 'چھوٹا کریں';

  @override
  String get editorDecorTitle => 'ویکٹر سجاوٹ';

  @override
  String get editorDecorKind => 'سجاوٹ کی قسم';

  @override
  String get editorDecorPalette => 'رنگوں کی پٹی';

  @override
  String get editorDecorLayers => 'تہوں کی تعداد';

  @override
  String get editorDecorSeed => 'بیج';

  @override
  String get editorDecorThickness => 'موٹائی';

  @override
  String get editorDecorPrimary => 'بنیادی رنگ';

  @override
  String get editorDecorSecondary => 'دوسرا رنگ';

  @override
  String get editorDecorAccent => 'نمایاں رنگ';

  @override
  String get editorDecorGradient => 'تہوں کا گریڈینٹ';

  @override
  String get editorDecorGallery => 'تیار ترتیبات';

  @override
  String get editorDecorGalleryTitle => 'تیار سجاوٹ کی گیلری';

  @override
  String get editorClose => 'بند کریں';

  @override
  String get editorDecorPaletteCustom => 'حسب ضرورت';

  @override
  String get decorKindModernWave => 'جدید لہریں';

  @override
  String get decorKindPaperCut => 'کئی تہوں والا کاغذی کٹ';

  @override
  String get decorKindClassicCorner => 'کلاسیکی مزین فریم';

  @override
  String get decorKindGuilloche => 'گلوش نمونہ';

  @override
  String get decorKindRibbonBanner => 'ربن / بینر';

  @override
  String get decorPaletteRoyalGold => 'شاہی سنہری';

  @override
  String get decorPaletteRoyalBlue => 'شاہی نیلا';

  @override
  String get decorPaletteEmerald => 'زمردی';

  @override
  String get decorPaletteBurgundy => 'عنابی';

  @override
  String get decorPaletteMidnight => 'رات کا نیلا';

  @override
  String get decorPaletteMono => 'ایک رنگ سرمئی';

  @override
  String get editorSignatureTitle => 'دستخطوں کا بلاک';

  @override
  String get editorSignatureCount => 'دستخطوں کی تعداد';

  @override
  String get signatureCountOne => 'ایک دستخط';

  @override
  String get signatureCountTwo => 'دو دستخط';

  @override
  String get signatureCountThree => 'تین دستخط';

  @override
  String get editorSignatureOrder => 'خانوں کی ترتیب';

  @override
  String get editorSignatureOrderHint =>
      'عربی دستاویزات میں پہلا خانہ بالکل دائیں جانب ہوتا ہے۔';

  @override
  String get editorSignatureFirstRight => 'پہلی دائیں';

  @override
  String get editorSignatureFirstLeft => 'پہلی بائیں';

  @override
  String get editorDirectionAuto => 'خودکار';

  @override
  String get editorSignatureImageAlign => 'تصویر کی سیدھ';

  @override
  String get editorAlignStart => 'آغاز';

  @override
  String get editorAlignCenter => 'درمیان';

  @override
  String get editorAlignEnd => 'اختتام';

  @override
  String get editorSignatureDivider => 'دستخط کی لکیر';

  @override
  String get editorVisible => 'نمایاں';

  @override
  String get editorHidden => 'پوشیدہ';

  @override
  String get editorSignatureNameSize => 'نام کا سائز';

  @override
  String get editorSignatureRoleSize => 'عہدے کا سائز';

  @override
  String get editorSignatureSpacing => 'فاصلہ';

  @override
  String get editorSignatureImageSize => 'تصویر کا سائز';

  @override
  String get editorSignatureNameColor => 'نام کا رنگ';

  @override
  String get editorSignatureRoleColor => 'عہدے کا رنگ';

  @override
  String get editorFont => 'فونٹ';

  @override
  String get editorImageSource => 'تصویر کا ماخذ';

  @override
  String get imageSourceAppAssets => 'ایپ کے اثاثے';

  @override
  String get imageSourceMyLibrary => 'میرا اثاثہ کتب خانہ';

  @override
  String get imageSourceLocalFile => 'مقامی فائل';

  @override
  String get imageSourceEmbedded => 'شامل شدہ ڈیٹا';

  @override
  String get editorSignatureChangeImage => 'دستخط کی تصویر بدلیں';

  @override
  String get editorSignatureAddImage => 'دستخط کی تصویر شامل کریں';

  @override
  String get editorSignatureRemoveImage => 'دستخط کی تصویر ہٹائیں';

  @override
  String get editorSignaturePickImageTitle =>
      'میرے اثاثہ کتب خانے سے دستخط کی تصویر منتخب کریں';

  @override
  String get editorSignatureSlot => 'خانہ';

  @override
  String get editorSignatureRoleField => 'عہدہ (مثلاً جنرل منیجر)';

  @override
  String get editorSignatureNameField =>
      'دستخط کرنے والے کا نام (متحرک خانہ قبول کرتا ہے)';

  @override
  String get editorFromMyLibrary => 'میرے اثاثہ کتب خانے سے';

  @override
  String get paletteSignatureBlock => 'دستخط';

  @override
  String get editorInsertFromLibraryTooltip =>
      'اپلوڈ شدہ فریم یا لوگو براہِ راست داخل کریں';

  @override
  String get unsupportedElementVersionNote =>
      'یہ عنصر ایڈیٹر کے نئے ورژن سے ہے — ویسے ہی محفوظ رہتا ہے اور یہاں تبدیل نہیں ہو سکتا۔';

  @override
  String editorSelectedCount(Object count) {
    return '$count منتخب';
  }

  @override
  String get editorClearSelection => 'انتخاب صاف کریں';

  @override
  String get editorGroup => 'گروپ';

  @override
  String get editorOpacity => 'دھندلاپن';

  @override
  String get editorBringToFront => 'سامنے لائیں';

  @override
  String get editorSendToBack => 'پیچھے بھیجیں';

  @override
  String get editorDuplicate => 'نقل کریں';

  @override
  String get editorDeleteSelected => 'منتخب حذف کریں';

  @override
  String get editorGroupDragHint =>
      'گروپ کو ماؤس سے کھینچیں، باریک حرکت کے لیے تیر استعمال کریں (Shift = 10px)، اور انتخاب میں تبدیلی کے لیے Ctrl + کلک کریں۔';

  @override
  String get editorBringForward => 'آگے لائیں';

  @override
  String get editorDuplicateElement => 'عنصر نقل کریں';

  @override
  String get editorDeleteElement => 'عنصر حذف کریں';

  @override
  String get editorPageSettings => 'صفحہ کی ترتیبات';

  @override
  String get editorPageSize => 'سائز';

  @override
  String get editorUnit => 'اکائی';

  @override
  String get editorWidth => 'چوڑائی';

  @override
  String get editorHeight => 'اونچائی';

  @override
  String get editorLabelText => 'متن';

  @override
  String get editorLabelShape => 'شکل';

  @override
  String get editorLabelSeal => 'مہر';

  @override
  String get editorLabelDecoration => 'ویکٹر سجاوٹ';

  @override
  String get editorLabelSignature => 'دستخطوں کا بلاک';

  @override
  String get editorLabelImage => 'تصویر / لوگو';

  @override
  String get editorLabelQr => 'QR کوڈ';

  @override
  String get editorLabelUnknown => 'غیر معاون عنصر';

  @override
  String get editorLabelDynamicField => 'متحرک خانہ';

  @override
  String get editorPositionAndSize => 'پوزیشن اور سائز';

  @override
  String get editorPosX => 'X';

  @override
  String get editorPosY => 'Y';

  @override
  String get editorRotation => 'گردش';

  @override
  String get editorTextFormat => 'متن کی فارمیٹنگ';

  @override
  String get editorConvertToField => 'متحرک خانے میں تبدیل کریں';

  @override
  String get editorFontWeight => 'موٹائی';

  @override
  String get editorWeightRegular => 'عام';

  @override
  String get editorWeightSemiBold => 'درمیانہ';

  @override
  String get editorWeightBold => 'موٹا';

  @override
  String get editorFontSize => 'فونٹ کا سائز';

  @override
  String get editorLetterSpacing => 'حروف کا فاصلہ';

  @override
  String get editorLineHeight => 'سطر کی اونچائی';

  @override
  String get editorTextColor => 'متن کا رنگ';

  @override
  String get editorTextBackground => 'متن کا پس منظر';

  @override
  String get editorTextAlign => 'سیدھ';

  @override
  String get editorAlignJustify => 'دونوں طرف';

  @override
  String get editorJustifyMode => 'سیدھ کا طریقہ';

  @override
  String get editorJustifyHint =>
      'کشیدہ PDF فائل میں لاگو ہوتا ہے (پیش نظارہ خالی جگہوں کی سیدھ دکھاتا ہے)';

  @override
  String get editorJustifySpaces => 'خالی جگہیں';

  @override
  String get editorJustifyKashida => 'کشیدہ';

  @override
  String get editorVerticalAlign => 'عمودی سیدھ';

  @override
  String get editorVerticalTop => 'اوپر';

  @override
  String get editorVerticalBottom => 'نیچے';

  @override
  String get editorDirection => 'سمت';

  @override
  String get editorDirectionHint => 'تبدیلی کا شارٹ کٹ: Ctrl+Shift+D';

  @override
  String get editorDirectionRtl => 'عربی (RTL)';

  @override
  String get editorDirectionLtr => 'لاطینی (LTR)';

  @override
  String get editorImage => 'تصویر';

  @override
  String get editorSource => 'ماخذ';

  @override
  String get editorImageFit => 'تصویر کی موافقت';

  @override
  String get editorFitContain => 'مکمل احاطہ';

  @override
  String get editorFitCover => 'احاطہ';

  @override
  String get editorFitFill => 'پھیلائیں';

  @override
  String get assetPickerEmptyHint =>
      'آپ نے ابھی کوئی اثاثہ اپلوڈ نہیں کیا۔ یہاں اور پرنٹ میں استعمال کے لیے لوگو، دستخط یا مہر اپلوڈ کریں۔';

  @override
  String get assetPickerNoneOption => 'کوئی نہیں (دوسرا ماخذ)';

  @override
  String get assetPickerTitle => 'میرے اثاثہ کتب خانے سے تصویر منتخب کریں';

  @override
  String assetUploadType(Object type) {
    return '$type اپلوڈ کریں';
  }

  @override
  String get editorSeal => 'مہر';

  @override
  String get editorSealColor => 'مہر کا رنگ';

  @override
  String get editorSealRingColor => 'حلقے کا رنگ';

  @override
  String get editorSealStarColor => 'ستارے کا رنگ';

  @override
  String get editorSealStarSize => 'ستارے کا سائز';

  @override
  String get editorShape => 'شکل';

  @override
  String get editorFillColor => 'بھرنے کا رنگ';

  @override
  String get editorBorderColor => 'بارڈر کا رنگ';

  @override
  String get editorBorderWidth => 'بارڈر کی موٹائی';

  @override
  String get editorCornerRadius => 'کونوں کی گولائی';

  @override
  String get editorQrVerify => 'تصدیقی کوڈ';

  @override
  String get editorQrData => 'کوڈ ڈیٹا';

  @override
  String get editorQrColor => 'کوڈ کا رنگ';

  @override
  String get editorQrBackground => 'کوڈ کا پس منظر';

  @override
  String editorConvertDialogMessage(Object text) {
    return 'تبدیلی متن «$text» کو ایک متحرک نشان میں بدل دیتی ہے جو اجتماعی پیداوار میں منسلک ہو سکتا ہے۔';
  }

  @override
  String get editorFieldKeyHint => 'خانے کی کلید (مثلاً نام، تاریخ، حوالہ)';

  @override
  String get editorCustomKeyHint =>
      'حسب ضرورت کلید درج کریں (بغیر بریکٹ — خودکار شامل ہو جائے گی)';

  @override
  String get editorCancel => 'منسوخ کریں';

  @override
  String get editorConvert => 'تبدیل کریں';

  @override
  String get editorPath => 'راستہ';

  @override
  String get editorTextContent => 'متن کا مواد';

  @override
  String editorInsertFieldToken(Object token) {
    return '$token درج کریں';
  }

  @override
  String editorAddLabel(Object label) {
    return '$label شامل کریں';
  }

  @override
  String assetInsertedSnack(Object name) {
    return '«$name» ٹیمپلیٹ میں داخل کر دیا گیا۔';
  }

  @override
  String get paletteHeading => 'عنوان';

  @override
  String get paletteFrame => 'مستطیل / فریم';

  @override
  String get paletteDivider => 'تقسیم کنندہ';

  @override
  String get paletteLogo => 'لوگو / دستخط';

  @override
  String get evSignatureEmptyLabel => 'خالی دستخط';

  @override
  String get evSignatureEmptyDetail => 'عہدہ، نام اور دستخط کی تصویر شامل کریں';

  @override
  String get evSignatureMissingLabel => 'غائب دستخط';

  @override
  String get evUploadToLibraryDetail => 'تصویر اثاثہ کتب خانے میں اپلوڈ کریں';

  @override
  String get evImageNotFoundLabel => 'تصویر نہیں ملی';

  @override
  String get evNoFileLabel => 'کوئی فائل منتخب نہیں';

  @override
  String get evChooseFromAssetsDetail => 'اثاثہ کتب خانے سے تصویر منتخب کریں';

  @override
  String get evAssetMissingLabel => 'غائب اثاثہ';

  @override
  String get evReselectAssetDetail =>
      'فریم/اثاثہ کتب خانے سے دوبارہ منتخب کریں';

  @override
  String get evInvalidImageLabel => 'غلط تصویر';

  @override
  String get evRenderDataFailedDetail => 'ڈیٹا دکھایا نہیں جا سکا';

  @override
  String get evInvalidDataLabel => 'غلط ڈیٹا';

  @override
  String get evDecodeFailedDetail => 'تصویر ڈی کوڈ نہیں ہو سکی';

  @override
  String get evEmptyQrLabel => 'خالی کوڈ';

  @override
  String get evEmptyQrDetail => 'کوڈ کی قدر خصوصیات کی پٹی میں درج کریں';

  @override
  String evUnknownElementLabel(Object type) {
    return 'غیر معاون عنصر: $type';
  }

  @override
  String get alpFilterAll => 'سب';

  @override
  String get alpEmptyHint =>
      'مطلوبہ اقسام کے اپلوڈ شدہ اثاثے نہیں۔ «اثاثے اور دستخط» کے حصے سے فریم یا لوگو اپلوڈ کریں، پھر دوبارہ کوشش کریں۔';

  @override
  String alpNoFilteredAssets(Object type) {
    return '«$type» قسم کے اثاثے نہیں۔';
  }

  @override
  String get authWelcomeBack => 'JoodCraft میں خوش آمدید۔';

  @override
  String get authResetLinkSent =>
      'ری سیٹ لنک بھیج دیا گیا ہے۔ اپنا ای میل چیک کریں۔';

  @override
  String get authLogin => 'سائن ان';

  @override
  String get authLoginSubtitle =>
      'ڈیش بورڈ پر جانے کے لیے اپنا ای میل اور پاس ورڈ۔';

  @override
  String get authNoAccount => 'کیا آپ کا اکاؤنٹ نہیں ہے؟';

  @override
  String get authCreateAccountLink => 'نیا اکاؤنٹ بنائیں';

  @override
  String get authConfirmEmailThenLogin =>
      'آپ کا اکاؤنٹ بن گیا۔ پہلے اپنا ای میل کی تصدیق کریں، پھر سائن ان کریں۔';

  @override
  String get authEmail => 'ای میل';

  @override
  String get authPassword => 'پاس ورڈ';

  @override
  String get authForgotPassword => 'پاس ورڈ بھول گئے؟';

  @override
  String get authEnterDashboard => 'ڈیش بورڈ میں داخل ہوں';

  @override
  String get authResetPassword => 'پاس ورڈ ری سیٹ کریں';

  @override
  String get authResetPasswordHint =>
      'اپنا ای میل درج کریں اور ہم آپ کو پاس ورڈ ری سیٹ لنک بھیجیں گے۔';

  @override
  String get authSendLink => 'لنک بھیجیں';

  @override
  String get authConfirmEmailMessage =>
      'آپ کا اکاؤنٹ بن گیا۔ تصدیق کے لیے اپنا ای میل چیک کریں، پھر سائن ان کریں۔';

  @override
  String get authAccountCreatedWelcome =>
      'آپ کا اکاؤنٹ بن گیا۔ JoodCraft میں خوش آمدید۔';

  @override
  String get authCreateAccount => 'اکاؤنٹ بنائیں';

  @override
  String get authRegisterSubtitle =>
      'آپ کا اکاؤنٹ آپ کے ٹیمپلیٹس اور اثاثے (لوگو، دستخط، مہر) تمام منصوبوں میں دوبارہ استعمال کے لیے محفوظ کرتا ہے۔';

  @override
  String get authHaveAccount => 'پہلے سے اکاؤنٹ ہے؟';

  @override
  String get authFullName => 'پورا نام';

  @override
  String get authFullNameHint => 'مثلاً: عبداللہ الاحمد';

  @override
  String get authName => 'نام';

  @override
  String get authOrgName => 'ادارے کا نام (اختیاری)';

  @override
  String get authOrgNameHint => 'مثلاً: جود خیراتی انجمن';

  @override
  String get authOrgHelper =>
      'سرٹیفکیٹس اور معاہدوں پر خودکار طور پر چھپتا ہے۔';

  @override
  String get authOrgNameShort => 'ادارے کا نام';

  @override
  String get authPasswordHint => 'کم از کم 8 حروف';

  @override
  String authPasswordRule(Object min) {
    return '$min یا زیادہ حروف مع اعداد و علامات استعمال کریں۔';
  }

  @override
  String get authConfirmPassword => 'پاس ورڈ کی تصدیق کریں';

  @override
  String get authCreateAccountButton => 'اکاؤنٹ بنائیں';

  @override
  String get authFeatureLocalExcel =>
      'Excel فائلوں کی مکمل مقامی پروسیسنگ — آپ کا ڈیٹا آپ کے آلے سے باہر نہیں جاتا';

  @override
  String get authFeaturePdf =>
      'اعلیٰ معیار کے عربی فونٹس کے ساتھ PDF پیداوار اور مکمل RTL سپورٹ';

  @override
  String get authFeatureTemplates =>
      'آپ کے ٹیمپلیٹس آپ کے اکاؤنٹ میں محفوظ اور دوبارہ استعمال کے لیے تیار ہیں';

  @override
  String get authTagline =>
      'آپ کے سرکاری سرٹیفکیٹ اور معاہدے… اعتماد کے ساتھ چھپتے ہیں۔';

  @override
  String authVersion(Object name, Object version) {
    return '$name • ورژن $version';
  }

  @override
  String get dashModules => 'پلیٹ فارم ماڈیولز';

  @override
  String dashWelcome(Object name) {
    return 'خوش آمدید، $name';
  }

  @override
  String dashSubscription(Object tier) {
    return 'سبسکرپشن: $tier';
  }

  @override
  String dashOrg(Object name) {
    return 'ادارہ: $name';
  }

  @override
  String get dashOrgMissing =>
      'آپ نے ابھی اپنے ادارے کا نام مقرر نہیں کیا — یہ سرٹیفکیٹس اور معاہدوں پر خودکار چھپے گا۔';

  @override
  String get dashOpenModule => 'ماڈیول کھولیں';

  @override
  String get dashRoadmapSupabase =>
      'Supabase ڈیٹا بیس کی تشکیل (ٹیبلز + RLS + ٹرگرز)';

  @override
  String get dashRoadmapModular => 'قابلِ توسیع ماڈیولر فیچر-فرسٹ ڈھانچہ';

  @override
  String get dashRoadmapTheme =>
      'Cairo فونٹ میں RTL سپورٹ کے ساتھ برانڈ کا بصری تھیم';

  @override
  String get dashRoadmapAuth =>
      'تصدیق: سائن ان، اکاؤنٹ بنانا اور پاس ورڈ ری سیٹ';

  @override
  String get dashPhaseOneDone => 'پہلا مرحلہ مکمل';

  @override
  String get dashNextPhase =>
      'اگلا: آف لائن PDF انجن اور عربی فونٹس، پھر بصری ٹیمپلیٹ ایڈیٹر۔';

  @override
  String get destDashboard => 'ڈیش بورڈ';

  @override
  String get destDashboardDesc => 'آپ کے منصوبوں اور ٹیمپلیٹس کا جائزہ۔';

  @override
  String get destCertificates => 'سرٹیفکیٹ انجن';

  @override
  String get destCertificatesDesc =>
      'قابلِ ترمیم ٹیمپلیٹ سے افقی (Landscape) سرٹیفکیٹ ڈیزائن کریں۔';

  @override
  String get destContracts => 'معاہدہ انجن';

  @override
  String get destContractsDesc =>
      'متحرک خانوں کے ساتھ عمودی (Portrait) معاہدے تحریر کریں۔';

  @override
  String get destBatch => 'اجتماعی پیداوار';

  @override
  String get destBatchDesc =>
      'Excel فائل مقامی طور پر پڑھیں اور سینکڑوں سرٹیفکیٹ ایک ساتھ بنائیں۔';

  @override
  String get destTemplates => 'ٹیمپلیٹ کتب خانہ';

  @override
  String get destTemplatesDesc =>
      'اپنے محفوظ شدہ ٹیمپلیٹس کا انتظام، درجہ بندی اور دوبارہ استعمال کریں۔';

  @override
  String get destAssets => 'اثاثے اور دستخط';

  @override
  String get destAssetsDesc => 'آپ کا لوگو، مہر، دستخط اور فریم۔';

  @override
  String get dashUser => 'صارف';

  @override
  String get dashLogoutSuccess => 'آپ نے کامیابی سے سائن آؤٹ کر لیا۔';

  @override
  String get dashLogoutError => 'سائن آؤٹ نہیں ہو سکا۔ دوبارہ کوشش کریں۔';

  @override
  String get commonSave => 'محفوظ کریں';

  @override
  String get commonPreview => 'پیش نظارہ';

  @override
  String get commonOptions => 'اختیارات';

  @override
  String get tplDelete => 'حذف کریں';

  @override
  String get tplSortRecentlyUpdated => 'حال ہی میں تبدیل شدہ';

  @override
  String get tplSortTitleAsc => 'نام (A–Z)';

  @override
  String get tplSortLabel => 'ترتیب';

  @override
  String get tplSubtitle =>
      'پیشہ ورانہ تیار ٹیمپلیٹس + آپ کے محفوظ شدہ — تلاش، فلٹر، کھولیں اور درآمد، مکمل آف لائن۔';

  @override
  String get tplRefreshTooltip => 'فہرست تازہ کریں';

  @override
  String get tplSearchHint => 'ٹیمپلیٹس میں تلاش کریں…';

  @override
  String get tplNoResultsTitle => 'کوئی مماثل نتیجہ نہیں';

  @override
  String get tplNoResultsMessage =>
      'دوسری تلاش کی اصطلاح آزمائیں یا فلٹر ری سیٹ کریں۔';

  @override
  String tplAddedToLocal(Object title) {
    return '«$title» آپ کے مقامی ٹیمپلیٹس میں شامل کر دیا گیا۔';
  }

  @override
  String get tplCloudRequiresConnection =>
      'ٹیمپلیٹس کو کلاؤڈ میں محفوظ کرنے کے لیے Supabase پروجیکٹ سے رابطہ درکار ہے۔ اسے مقامی طور پر محفوظ کریں۔';

  @override
  String tplSavedToCloud(Object title) {
    return '«$title» کلاؤڈ میں محفوظ ہو گیا۔';
  }

  @override
  String get tplRenamed => 'ٹیمپلیٹ کا نام تبدیل کر دیا گیا۔';

  @override
  String tplCopySuffix(Object title) {
    return '$title (نقل)';
  }

  @override
  String tplCopyCreated(Object title) {
    return '«$title» کی نقل بنائی گئی۔';
  }

  @override
  String get tplNowPrivate => 'ٹیمپلیٹ اب نجی ہے۔';

  @override
  String get tplNowPublic =>
      'ٹیمپلیٹ اب عام ہے (دوسروں کے لیے صرف پڑھنے کے لیے)۔';

  @override
  String tplConfirmCloudDelete(Object title) {
    return '«$title» کلاؤڈ سے مستقل طور پر حذف ہو جائے گا۔ اسے واپس نہیں کیا جا سکتا۔';
  }

  @override
  String tplCloudDeleted(Object title) {
    return 'ٹیمپلیٹ «$title» حذف ہو گیا۔';
  }

  @override
  String tplConfirmLocalDelete(Object title) {
    return '«$title» اس آلے سے حذف ہو جائے گا۔ اصل تیار ٹیمپلیٹ کتب خانے میں دستیاب رہے گا۔';
  }

  @override
  String tplLocalDeleted(Object title) {
    return 'مقامی ٹیمپلیٹ «$title» حذف ہو گیا۔';
  }

  @override
  String get tplDeleteTitle => 'ٹیمپلیٹ حذف کریں';

  @override
  String get tplRenameTitle => 'ٹیمپلیٹ کا عنوان';

  @override
  String get tplFieldTitle => 'عنوان';

  @override
  String tplPreviewLabel(Object title) {
    return 'پیش نظارہ: $title';
  }

  @override
  String tplCount(Object count) {
    return '$count ٹیمپلیٹ';
  }

  @override
  String tplCloudLoadError(Object message) {
    return 'کلاؤڈ ٹیمپلیٹس لوڈ نہیں ہو سکے: $message';
  }

  @override
  String get tplPublicBadge => 'عام ٹیمپلیٹ';

  @override
  String get tplOrientationLandscape => 'افقی';

  @override
  String get tplOrientationPortrait => 'عمودی';

  @override
  String get tplPresetOffline => 'تیار ٹیمپلیٹ • آف لائن دستیاب';

  @override
  String tplSchemaVersion(Object version) {
    return 'اسکیما v$version';
  }

  @override
  String get tplOpenAsTemplate => 'بطور ٹیمپلیٹ کھولیں';

  @override
  String get tplOpen => 'کھولیں';

  @override
  String get tplUseInBatch => 'اجتماعی پیداوار میں استعمال کریں';

  @override
  String get tplImportLocal => 'مقامی طور پر درآمد کریں';

  @override
  String get tplSaveToCloud => 'کلاؤڈ میں محفوظ کریں';

  @override
  String get tplDeleteLocal => 'مقامی طور پر حذف کریں';

  @override
  String get tplRename => 'نام تبدیل کریں';

  @override
  String get tplMakePrivate => 'اسے نجی بنائیں';

  @override
  String get tplMakePublic => 'اسے عام بنائیں';

  @override
  String get tplNoDate => 'تاریخ نہیں';

  @override
  String get amSubtitle =>
      'اپنا لوگو، مہر اور دستخط ایک بار اپلوڈ کریں، پھر کسی بھی ٹیمپلیٹ میں درج کریں — آپ کے آلے پر محفوظ اور آف لائن دوبارہ استعمال ہوتے ہیں۔';

  @override
  String get amSearchHint => 'اثاثوں میں تلاش کریں…';

  @override
  String get amTypeLabel => 'قسم';

  @override
  String get amUploadTooltip => 'نیا اثاثہ اپلوڈ کریں';

  @override
  String get amUpload => 'اثاثہ اپلوڈ کریں';

  @override
  String get amEmptyTitle => 'ابھی کوئی اثاثہ نہیں';

  @override
  String get amEmptyMessage =>
      'اپنے ادارے کا لوگو، دستخط یا مہر اپلوڈ کریں، پھر تصویر کی خصوصیات کی پٹی سے کسی بھی ٹیمپلیٹ میں درج کریں۔';

  @override
  String get amNoResultsMessage => 'دوسرا نام آزمائیں یا فلٹر ری سیٹ کریں۔';

  @override
  String get amRenamed => 'اثاثے کا نام تبدیل کر دیا گیا۔';

  @override
  String amMovedToType(Object type) {
    return 'اثاثہ «$type» میں منتقل کر دیا گیا۔';
  }

  @override
  String get amDeleteTitle => 'اثاثہ حذف کریں';

  @override
  String amConfirmDelete(Object name) {
    return '«$name» اس آلے سے حذف ہو جائے گا۔ استعمال کرنے والے ٹیمپلیٹس تصویر کھو دیں گے (پرنٹ ناکامی کے بغیر)۔';
  }

  @override
  String amDeleted(Object name) {
    return 'اثاثہ «$name» حذف ہو گیا۔';
  }

  @override
  String get amRenameTitle => 'اثاثے کا نام تبدیل کریں';

  @override
  String amCount(Object count) {
    return '$count اثاثہ';
  }

  @override
  String amMakeType(Object type) {
    return 'قسم بنائیں: $type';
  }
}
