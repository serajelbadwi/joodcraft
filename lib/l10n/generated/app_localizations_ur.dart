// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Urdu (`ur`).
class AppLocalizationsUr extends AppLocalizations {
  AppLocalizationsUr([String locale = 'ur']) : super(locale);

  @override
  String get editorDone => 'مکمل';

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
  String get actionOpenMenu => 'مینو';

  @override
  String get editorFitToScreen => 'اسکرین پر فٹ کریں';

  @override
  String get editorNewTemplate => 'نیا ٹیمپلیٹ';

  @override
  String get editorNewConfirm =>
      'نیا ٹیمپلیٹ ڈیفالٹ ڈیزائن سے شروع ہوگا؛ غیر محفوظ تبدیلیاں انڈو ہسٹری میں رہیں گی۔ جاری رکھیں؟';

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
  String get destBrand => 'شناخت اور پروفائل';

  @override
  String get destBrandDesc => 'آپ کا لوگو، مہریں، دستخط اور برانڈ رنگ۔';

  @override
  String get brandTitle => 'شناخت اور پروفائل کی ترتیبات';

  @override
  String get brandTabVisuals => 'بصری شناخت';

  @override
  String get brandTabText => 'متن کی معلومات';

  @override
  String get brandTabColors => 'رنگ اور فونٹ';

  @override
  String get brandTabPreview => 'شناخت کا پیش منظر';

  @override
  String get brandPrimaryLogo => 'بنیادی لوگو';

  @override
  String get brandWatermarkLogo => 'واٹر مارک لوگو';

  @override
  String get brandSeals => 'سرکاری مہریں';

  @override
  String get brandAddSeal => 'مہر شامل کریں';

  @override
  String get brandSealName => 'مہر کا نام';

  @override
  String get brandSignatures => 'مجاز دستخط';

  @override
  String get brandAddSignature => 'دستخط شامل کریں';

  @override
  String get brandSignatureName => 'دستخط کرنے والے کا نام';

  @override
  String get brandSignatureTitle => 'عہدہ';

  @override
  String get brandRemove => 'ہٹائیں';

  @override
  String get brandNoSeals => 'ابھی کوئی مہر شامل نہیں کی گئی۔';

  @override
  String get brandNoSignatures => 'ابھی کوئی دستخط شامل نہیں کیے گئے۔';

  @override
  String get brandOrgNameAr => 'ادارے کا نام (عربی)';

  @override
  String get brandOrgNameEn => 'ادارے کا نام (انگریزی)';

  @override
  String get brandHeaderText => 'سرخی کا متن';

  @override
  String get brandFooterText => 'پیر کا متن';

  @override
  String get brandRegNumber => 'ٹیکس / رجسٹریشن نمبر';

  @override
  String get brandPrimaryColor => 'بنیادی رنگ';

  @override
  String get brandSecondaryColor => 'ثانوی رنگ';

  @override
  String get brandAccentColor => 'نمایاں رنگ';

  @override
  String get brandHeaderFont => 'سرخی کا فونٹ';

  @override
  String get brandBodyFont => 'متن کا فونٹ';

  @override
  String get brandClear => 'شناخت صاف کریں';

  @override
  String get brandClearConfirm =>
      'محفوظ تمام شناخت حذف ہو جائے گی۔ جاری رکھیں؟';

  @override
  String get brandSaved => 'شناخت محفوظ ہو گئی۔';

  @override
  String get brandPresets => 'شناخت کے عناصر';

  @override
  String get brandInsertHeader => 'معیاری سرخی شامل کریں';

  @override
  String get brandInsertFooter => 'معیاری پیر شامل کریں';

  @override
  String get brandApplyColors => 'رنگ لاگو کریں';

  @override
  String get brandQuickSeals => 'مہریں';

  @override
  String get brandQuickSignatures => 'دستخط';

  @override
  String get brandNoBrand => 'آپ کی شناخت ابھی ترتیب نہیں دی گئی۔';

  @override
  String get brandOpenSettings => 'شناخت کی ترتیبات کھولیں';

  @override
  String get brandHeaderInserted => 'معیاری سرخی شامل ہو گئی۔';

  @override
  String get brandFooterInserted => 'معیاری پیر شامل ہو گیا۔';

  @override
  String get brandColorsApplied => 'رنگ لاگو ہو گئے۔';

  @override
  String get brandSealInserted => 'مہر شامل ہو گئی۔';

  @override
  String get brandSignatureInserted => 'دستخط شامل ہو گیا۔';

  @override
  String get brandFontDefault => 'طے شدہ';

  @override
  String get paletteShapes => 'اشکال';

  @override
  String get paletteRoundedRect => 'گول کونوں والا مستطیل';

  @override
  String get paletteEllipse => 'دائرہ / بیضوی';

  @override
  String get editorFillOpacity => 'بھرائی کی شفافیت';

  @override
  String get editorCollapsePanel => 'سائیڈ پینل سمیٹیں';

  @override
  String get editorExpandPanel => 'سائیڈ پینل دکھائیں';

  @override
  String get editorCustomSize => 'اپنی مرضی کا سائز';

  @override
  String get editorStandardSize => 'معیاری سائز';

  @override
  String get editorBackgroundTitle => 'ورق کا پس منظر';

  @override
  String get editorGradientFrom => 'سے';

  @override
  String get editorGradientTo => 'تک';

  @override
  String get editorGradientDirection => 'سمت';

  @override
  String get editorGradientNone => 'تدریج نہیں';

  @override
  String get editorGradientVertical => 'عمودی';

  @override
  String get editorGradientHorizontal => 'افقی';

  @override
  String get editorGradientDiagonal => 'ترچھا';

  @override
  String get editorLayersTitle => 'تہیں';

  @override
  String get editorLayerShow => 'عنصر دکھائیں';

  @override
  String get editorLayerHide => 'عنصر چھپائیں';

  @override
  String get editorLayerLock => 'عنصر مقفل کریں';

  @override
  String get editorLayerUnlock => 'عنصر کی قفل کشائی کریں';

  @override
  String get editorLayersEmpty => 'اس صفحے پر ابھی کوئی عنصر نہیں۔';

  @override
  String get editorGroupSelected => 'انتخاب گروپ کریں';

  @override
  String get editorUngroupSelected => 'گروپ ختم کریں';

  @override
  String get editorAlignLeft => 'بائیں سیدھ';

  @override
  String get editorAlignCenterH => 'افقی مرکز';

  @override
  String get editorAlignRight => 'دائیں سیدھ';

  @override
  String get editorAlignTop => 'اوپر سیدھ';

  @override
  String get editorAlignCenterV => 'عمودی مرکز';

  @override
  String get editorAlignBottom => 'نیچے سیدھ';

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
  String get editorImageTint => 'تصویر کی رنگت';

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

  @override
  String get amCacheLabel => 'ڈسک پر تصویروں کا کیش';

  @override
  String amCacheUsage(Object count, Object size) {
    return '$count فائل · $size';
  }

  @override
  String amCacheUsageOf(Object count, Object used, Object limit) {
    return '$count فائلیں · $used میں سے $limit';
  }

  @override
  String get amCacheEmpty => 'ابھی کوئی ڈسک کیش نہیں';

  @override
  String get amCacheClear => 'کیش صاف کریں';

  @override
  String get amCacheCleared => 'ڈسک پر تصویروں کا کیش صاف کر دیا گیا۔';

  @override
  String get commonRetry => 'دوبارہ کوشش کریں';

  @override
  String get commonPrint => 'پرنٹ کریں';

  @override
  String get commonExportPdf => 'PDF برآمد کریں';

  @override
  String get commonExportFailed => 'PDF فائل برآمد نہیں ہو سکی۔';

  @override
  String get commonPrintFailed => 'فائل پرنٹر کو نہیں بھیجی جا سکی۔';

  @override
  String commonExportReady(Object name) {
    return 'فائل «$name» کے طور پر محفوظ کرنے کے لیے تیار ہے۔';
  }

  @override
  String get commonGenerating => 'پیداوار جاری…';

  @override
  String get commonDataPanelTitle => 'نمونہ ڈیٹا';

  @override
  String evElementCount(Object count) {
    return '$count عنصر';
  }

  @override
  String get evStatusDynamicFields => ' • متحرک خانے';

  @override
  String get evStatusUnsaved => ' • غیر محفوظ تبدیلیاں';

  @override
  String get tevNewTemplateTitle => 'نیا ٹیمپلیٹ';

  @override
  String get tevUnsavedTitle => 'غیر محفوظ تبدیلیاں';

  @override
  String tevUnsavedMessage(Object title) {
    return '«$title» میں آپ کی غیر محفوظ تبدیلیاں ہیں۔ جانے سے پہلے محفوظ کرنا چاہیں گے؟';
  }

  @override
  String get tevLeaveWithoutSaving => 'بغیر محفوظ کیے جائیں';

  @override
  String get tevSaveAndLeave => 'محفوظ کریں اور جائیں';

  @override
  String get tevViewMode => 'منظر کا انداز';

  @override
  String get tevModeEditor => 'ایڈیٹر';

  @override
  String get tevModePreview => 'PDF پیش نظارہ';

  @override
  String get tevPaperDirection => 'کاغذ کی سمت';

  @override
  String get tevWidthCm => 'چوڑائی (cm)';

  @override
  String get tevHeightCm => 'اونچائی (cm)';

  @override
  String get tevUndo => 'واپس (Ctrl+Z)';

  @override
  String get tevRedo => 'دوبارہ (Ctrl+Y)';

  @override
  String get tevSnapGrid => 'سنیپ گرڈ';

  @override
  String get tevGuidesOn => 'سمارٹ گائیڈز: فعال (بند کریں)';

  @override
  String get tevGuidesOff => 'سمارٹ گائیڈز: غیر فعال (چالو کریں)';

  @override
  String get tevZoom => 'زوم';

  @override
  String get tevDocumentBackground => 'دستاویز کا پس منظر';

  @override
  String get tevFrameFromLibrary => 'میرے اثاثہ کتب خانے سے فریم';

  @override
  String get tevChangeTitle => 'ٹیمپلیٹ کا عنوان تبدیل کریں';

  @override
  String get tevMyTemplates => 'میرے ٹیمپلیٹس';

  @override
  String get tevSaveAs => 'بطور محفوظ کریں';

  @override
  String get tevSaveTemplate => 'ٹیمپلیٹ محفوظ کریں';

  @override
  String get tevSaveUnavailable => 'محفوظ کرنا دستیاب نہیں';

  @override
  String get tevSaveNeedsSupabase =>
      'محفوظ کرنے کے لیے Supabase پروجیکٹ سے رابطہ درکار ہے۔ ٹیمپلیٹس محفوظ کرنے کے لیے ایپ کو اپنی کلیدوں (env.json) کے ساتھ چلائیں۔';

  @override
  String tevMissingAssets(Object list) {
    return 'گمشدہ اثاثے: $list — خالی ظاہر ہونے سے بچنے کے لیے «میرا کتب خانہ» سے فریم/اثاثہ دوبارہ منتخب کریں۔';
  }

  @override
  String get tevTemplateLibraryNeedsSupabase =>
      'ٹیمپلیٹ کتب خانہ Supabase پروجیکٹ سے رابطہ درکار کرتا ہے۔';

  @override
  String tevOpenedTemplate(Object title) {
    return '«$title» کھول دیا گیا۔';
  }

  @override
  String get tevTitleHint => 'مثلاً: پروجیکٹ مینجمنٹ کورس کی تکمیل کا سرٹیفکیٹ';

  @override
  String get tevContinue => 'جاری رکھیں';

  @override
  String get tevSavedTemplates => 'میرے محفوظ شدہ ٹیمپلیٹس';

  @override
  String get tevNoSavedTemplates =>
      'ابھی کوئی محفوظ ٹیمپلیٹ نہیں۔ «ٹیمپلیٹ محفوظ کریں» بٹن سے ایک محفوظ کریں۔';

  @override
  String get ecIncrease => 'بڑھائیں';

  @override
  String get ecDecrease => 'کم کریں';

  @override
  String get ecQuickPalette => 'فوری پٹی';

  @override
  String get ecFullPicker => 'مکمل رنگ منتخب کنندہ';

  @override
  String get ecRemoveColor => 'رنگ ہٹائیں';

  @override
  String get ecNone => 'کوئی نہیں';

  @override
  String get ecPickColorTitle => 'رنگ منتخب کریں';

  @override
  String get ecApply => 'لاگو کریں';

  @override
  String tevBackgroundAdded(Object name) {
    return '«$name» دستاویز کے پس منظر کے طور پر شامل کیا گیا۔';
  }

  @override
  String get cfpUploadTooltip => 'حسب ضرورت فونٹ اپلوڈ کریں (.ttf / .otf)';

  @override
  String get cfpManageTooltip => 'اپلوڈ شدہ فونٹس کا انتظام';

  @override
  String get cfpNotice =>
      'اپلوڈ شدہ فونٹس صرف آپ کے آلے پر محفوظ ہوتے ہیں اور یہاں اور پرنٹ میں فوراً استعمال ہوتے ہیں — بغیر انٹرنیٹ۔';

  @override
  String get cfpMyFonts => 'میرے حسب ضرورت فونٹس';

  @override
  String get cfpNoFonts => 'ابھی کوئی فونٹ اپلوڈ نہیں ہوا';

  @override
  String get cfpBuiltinOption => 'کوئی نہیں (بلٹ اِن فونٹ)';

  @override
  String get cfpGroupBuiltin => 'بلٹ اِن فونٹس';

  @override
  String get cfpGroupUploaded => 'میرے اپلوڈ کردہ فونٹس';

  @override
  String get cfpGroupSystem => 'سسٹم فونٹس';

  @override
  String get cfpSearchHint => 'فونٹ تلاش کریں…';

  @override
  String get cfpNoMatch => 'کوئی مماثل فونٹ نہیں۔';

  @override
  String get cfpPickTitle => 'فونٹ فائل منتخب کریں (TTF یا OTF)';

  @override
  String cfpPickerError(Object error) {
    return 'فائل منتخب کنندہ نہیں کھل سکا: $error';
  }

  @override
  String cfpReadError(Object name, Object error) {
    return '«$name» پڑھی نہیں جا سکی: $error';
  }

  @override
  String get cfpFontAdded => 'فونٹ شامل کر دیا گیا اور فوراً لاگو ہوا۔';

  @override
  String cfpFontsAdded(Object count) {
    return '$count فونٹس شامل کیے گئے۔';
  }

  @override
  String get cfpLibraryTitle => 'میرے حسب ضرورت فونٹس کا کتب خانہ';

  @override
  String get cfpLibraryNotice =>
      'تمام فونٹس صرف آپ کے آلے پر محفوظ ہیں۔ انتباہ: کسی ٹیمپلیٹ کا استعمال کرنے والا فونٹ حذف کرنا اُس ٹیمپلیٹ کو ناکامی کے بجائے بلٹ اِن فونٹ پر واپس لے جاتا ہے۔';

  @override
  String get cfpEmpty => 'ابھی کوئی اپلوڈ شدہ فونٹ نہیں۔';

  @override
  String get cfpCoverageFull => 'مکمل عربی کوریج';

  @override
  String get cfpCoveragePartial => 'جزوی عربی کوریج';

  @override
  String get cfpUploadNew => 'نیا فونٹ اپلوڈ کریں';

  @override
  String get ptpPrepError =>
      'پیش نظارہ تیار نہیں ہو سکا۔ ٹیمپلیٹ فائل چیک کریں۔';

  @override
  String ptpElapsedSize(Object ms, Object kb) {
    return '$ms م.ث — $kb ک.ب';
  }

  @override
  String get ptpGeneratingNote => '— پیش نظارہ خودکار طور پر اپ ڈیٹ ہوتا ہے';

  @override
  String get ptpGenerateFailedTitle => 'پیش نظارہ بنایا نہیں جا سکا';

  @override
  String get ptpPreparingTitle => 'انجن تیار ہو رہا ہے…';

  @override
  String get ptpPreparingMessage =>
      'بنڈل شدہ فونٹس لوڈ ہو رہے ہیں اور فائل کا پہلا ورژن بنایا جا رہا ہے۔';

  @override
  String get ptpShowFailedTitle => 'پیش نظارہ دکھایا نہیں جا سکا';

  @override
  String cfgOverride(Object override) {
    return 'واضح قدروں کے ساتھ متبادل بلڈ فائل کو اوور رائیڈ کرتا ہے: $override';
  }

  @override
  String get tevBackgroundTitle => 'میرے اثاثہ کتب خانے سے دستاویز کا پس منظر';

  @override
  String get tevAddElement => 'عنصر شامل کریں';

  @override
  String get commonUndo => 'واپس';

  @override
  String get bpTitle => 'Excel سے اجتماعی پیداوار';

  @override
  String get bpSubtitle =>
      'ایک .xlsx یا .csv فائل درآمد کریں، اس کے کالموں کو ٹیمپلیٹ خانوں سے منسلک کریں، پھر ہر ریکارڈ کے لیے ایک صفحے والا PDF بنائیں — سب آپ کے آلے پر، آف لائن۔';

  @override
  String get bpStepTemplate => '1) ٹیمپلیٹ';

  @override
  String get bpLoadingSampleTemplate => 'نمونہ ٹیمپلیٹ لوڈ ہو رہا ہے…';

  @override
  String bpTemplateInfo(Object name) {
    return 'ٹیمپلیٹ: $name • مطلوبہ خانے:';
  }

  @override
  String get bpLoadingTemplates => 'آپ کے ٹیمپلیٹس لوڈ ہو رہے ہیں…';

  @override
  String get bpNoTemplates =>
      'ابھی کوئی محفوظ ٹیمپلیٹ نہیں — ایڈیٹر میں بنائیں یا ٹیمپلیٹ کتب خانے سے درآمد کریں۔';

  @override
  String get bpTemplateFromMine => 'میرے ٹیمپلیٹس سے ٹیمپلیٹ';

  @override
  String get bpSampleTemplatesHeader => '— نمونہ ٹیمپلیٹس —';

  @override
  String bpTemplateEntry(Object title, Object source) {
    return '$title  •  $source';
  }

  @override
  String get bpSourceCloud => 'کلاؤڈ';

  @override
  String get bpSourceLocal => 'مقامی';

  @override
  String get bpStepDataFile => '2) ڈیٹا فائل';

  @override
  String get bpReadingFile => 'فائل پڑھی جا رہی ہے…';

  @override
  String get bpNoFileChosen => 'ابھی کوئی فائل منتخب نہیں — معاون فارمیٹس:';

  @override
  String bpFileSummary(Object name, Object rows, Object cols) {
    return '$name — $rows قطاریں، $cols کالم';
  }

  @override
  String bpSheetSuffix(Object name) {
    return ' (ورقہ: $name)';
  }

  @override
  String get bpChooseFile => 'فائل منتخب کریں';

  @override
  String get bpRemove => 'ہٹائیں';

  @override
  String get bpHeaderRow => 'ہیڈر قطار';

  @override
  String bpAutoRow(Object n) {
    return 'خودکار (قطار $n)';
  }

  @override
  String bpRow(Object n) {
    return 'قطار $n';
  }

  @override
  String bpAutoRowLong(Object n) {
    return 'خودکار — قطار $n';
  }

  @override
  String bpRowPreview(Object n, Object preview) {
    return 'قطار $n: $preview';
  }

  @override
  String get bpEmptyRow => '(خالی قطار)';

  @override
  String get bpWorksheet => 'ورک شیٹ';

  @override
  String get bpPickDataFile => 'ڈیٹا فائل منتخب کریں (Excel یا CSV)';

  @override
  String bpReadFileError(Object error) {
    return 'فائل پڑھی نہیں جا سکی: $error';
  }

  @override
  String bpFileReadRows(Object rows, Object cols) {
    return 'فائل مقامی طور پر پڑھی گئی: $rows قطاریں اور $cols کالم۔';
  }

  @override
  String bpSaveError(Object error) {
    return 'تبدیلی ٹیمپلیٹ میں محفوظ نہیں ہو سکی: $error';
  }

  @override
  String get bpMapFieldTitle => 'اس عنصر کو متحرک خانہ تفویض کریں';

  @override
  String get bpMapFieldBody =>
      'صرف اس عنصر کا متن ایک خانے سے بدلے گا؛ کوئی اور عنصر متاثر نہیں ہوگا۔';

  @override
  String get bpUndoConvert => 'تبدیلی واپس کر دی گئی۔';

  @override
  String get bpUndoConvertSaved =>
      'تبدیلی واپس کر دی گئی اور متن ٹیمپلیٹ میں بحال ہو گیا۔';

  @override
  String bpRestoreError(Object error) {
    return 'متن ٹیمپلیٹ میں بحال نہیں ہو سکا: $error';
  }

  @override
  String bpGeneratedReport(Object count) {
    return '$count ریکارڈ بنائے گئے';
  }

  @override
  String bpSkippedSuffix(Object count) {
    return ' اور $count چھوڑے گئے';
  }

  @override
  String get bpReadyToSave => 'فائل محفوظ کرنے کے لیے تیار ہے۔';

  @override
  String get bpStepMapping => '3) کالموں کو خانوں سے منسلک کریں';

  @override
  String get bpChooseFileFirst =>
      'نقشہ جدول دکھانے کے لیے پہلے فائل منتخب کریں۔';

  @override
  String get bpNoDynamicFields => 'موجودہ ٹیمپلیٹ میں کوئی متحرک خانہ نہیں۔';

  @override
  String bpMappedCount(Object mapped, Object total) {
    return '$total کالموں میں سے $mapped منسلک';
  }

  @override
  String get bpAutoMapHint =>
      'فائل منتخب کرنے کے بعد ذہین خودکار نقشہ تجویز ہوگا؛ آپ ہر کالم میں ترمیم کر سکتے ہیں۔';

  @override
  String get bpNoFieldsHelp =>
      'منتخب ٹیمپلیٹ میں کوئی متحرک خانہ نہیں، اس لیے فائل کالموں سے منسلک کرنے کو کچھ نہیں۔ ٹیمپلیٹ ایڈیٹر میں کھولیں، نام کی جگہ میں «متحرک خانہ» درج کریں، محفوظ کریں، پھر دوبارہ کوشش کریں۔';

  @override
  String get bpAutoMap => 'خودکار نقشہ';

  @override
  String get bpClearMapping => 'نقشہ صاف کریں';

  @override
  String get bpNameFieldWarning =>
      'اس ٹیمپلیٹ میں متحرک نام کا خانہ نہیں — نام کے کالم کو تاریخ یا حوالہ خانے سے نہ منسلک کریں، ورنہ نام غلط جگہ چھپ سکتا ہے۔ کالم فہرست سے نام کی کلید منتخب کریں، یا ایڈیٹر میں مستقل نام کے متن کو متحرک خانے میں بدلیں۔';

  @override
  String bpStaticNameHints(Object preview) {
    return 'نام جیسا مستقل متن: «$preview» — کوئی متحرک خانہ اسے تبدیل نہیں کرتا۔';
  }

  @override
  String get bpConvertToNameField => 'اسے تربیت یافتہ کے نام کے خانے میں بدلیں';

  @override
  String bpDuplicateField(Object field) {
    return 'خانہ «$field» ایک سے زیادہ کالموں سے منسلک ہے۔ ہر خانے کو ایک کالم سے منسلک کریں۔';
  }

  @override
  String bpUnmappedColumns(Object count) {
    return '$count غیر منسلک کالم — ان کا ڈیٹا سرٹیفکیٹس میں استعمال نہیں ہوگا۔';
  }

  @override
  String bpColumn(Object n) {
    return 'کالم $n';
  }

  @override
  String get bpEmptyCell => '(خالی)';

  @override
  String get bpUnmapped => '— غیر منسلک —';

  @override
  String get bpStepMissing => '4) خالی خلیے اور غائب ڈیٹا';

  @override
  String get bpNoNotes => 'فائل منتخب کرنے سے پہلے کوئی نوٹ نہیں۔';

  @override
  String get bpStepGenerate => '5) پیداوار';

  @override
  String bpGenerating(Object progress) {
    return 'پیداوار جاری… $progress';
  }

  @override
  String get bpGenerateHint =>
      'ایک PDF فائل، ہر بنائے گئے ریکارڈ کے لیے ایک صفحہ۔';

  @override
  String get bpGeneratePickFile =>
      'پیداوار فعال کرنے کے لیے پہلے ڈیٹا فائل منتخب کریں۔';

  @override
  String get bpMappingInvalid =>
      'نقشہ غلط ہے — ایک ہی خانہ دو کالموں سے منسلک ہے۔';

  @override
  String get bpMapAtLeastOne =>
      'پیداوار فعال کرنے کے لیے کم از کم ایک کالم ٹیمپلیٹ خانے سے منسلک کریں۔';

  @override
  String get bpGenerateCertificates => 'سرٹیفکیٹس بنائیں';

  @override
  String get bpRegenerate => 'دوبارہ بنائیں';

  @override
  String get bpStatGenerated => 'بنائے گئے';

  @override
  String get bpStatSkipped => 'چھوڑے گئے';

  @override
  String get bpStatPages => 'صفحات';

  @override
  String get bpStatSize => 'سائز';

  @override
  String bpKilobytes(Object value) {
    return '$value ک.ب';
  }

  @override
  String get bpStatTime => 'وقت';

  @override
  String bpMilliseconds(Object value) {
    return '$value م.ث';
  }

  @override
  String bpCompletion(Object pct, Object total) {
    return '$total قطاروں کا $pct% مکمل۔';
  }

  @override
  String get bpSkippedRows => 'نہ بنائی گئی قطاریں:';

  @override
  String bpRowSkipReason(Object n, Object reason) {
    return 'قطار $n: $reason';
  }

  @override
  String get bpPreviewHere => 'پیش نظارہ یہاں ظاہر ہوتا ہے';

  @override
  String get bpPreviewHint =>
      'ڈیٹا فائل منتخب کریں، نقشہ درست کریں، پھر «سرٹیفکیٹس بنائیں» دبائیں — بنائی گئی فائل کا پہلا صفحہ یہاں نظر آئے گا۔';

  @override
  String get bpAssignByTapTitle => 'خانوں کو ٹیپ کر کے تفویض کریں';

  @override
  String get bpAssignByTapBody =>
      'ٹیمپلیٹ میں کسی بھی متن کو ٹیپ کریں تاکہ خود اسے متحرک خانے سے منسلک کریں۔ کوئی اور عنصر متاثر نہیں — نہ تاریخ، نہ منیجر کا نام، نہ کوئی مستقل متن۔';

  @override
  String get bpNoTexts => 'اس ٹیمپلیٹ میں کوئی متن نہیں۔';

  @override
  String get bpEmptyText => '(خالی متن)';

  @override
  String get bpDynamicFieldTap => 'متحرک خانہ — تبدیل کرنے کے لیے ٹیپ کریں';

  @override
  String get bpStaticTextTap => 'مستقل متن — تفویض کے لیے ٹیپ کریں';

  @override
  String get bpAssignField => 'خانہ تفویض کریں';

  @override
  String get bpKindCertificate => 'سرٹیفکیٹ';

  @override
  String get bpKindContract => 'معاہدہ';

  @override
  String bpLoadSampleError(Object error) {
    return 'نمونہ ٹیمپلیٹ لوڈ نہیں ہو سکا: $error';
  }

  @override
  String bpReadSheetError(Object error) {
    return 'ورقہ پڑھا نہیں جا سکا: $error';
  }

  @override
  String bpUpdateHeaderRowError(Object error) {
    return 'ہیڈر قطار اپ ڈیٹ نہیں ہو سکی: $error';
  }

  @override
  String get bpChooseTemplateFirst =>
      'پیداوار سے پہلے ٹیمپلیٹ (سرٹیفکیٹ یا معاہدہ) منتخب کریں۔';

  @override
  String bpBatchTitle(Object kind) {
    return '$kind اجتماعی — JoodCraft';
  }

  @override
  String bpGenerateError(Object error) {
    return 'اجتماعی پیداوار نہیں چل سکی: $error';
  }

  @override
  String get bpWarnNoDynamicFields =>
      'اس ٹیمپلیٹ میں متحرک خانہ نہیں — ریکارڈز کے درمیان ڈیٹا تبدیل نہیں ہوگا۔ ایڈیٹر پٹی سے «ٹرینی نام» کا خانہ شامل کریں، پھر ٹیمپلیٹ محفوظ کریں۔';

  @override
  String get bpWarnNoNameField =>
      'اس ٹیمپلیٹ میں متحرک نام کا خانہ نہیں — نام کا کالم تاریخ یا حوالہ خانے سے منسلک ہو کر نام غلط جگہ چھپ سکتا ہے۔ مستقل نام کے متن کو خانے میں بدلیں یا ٹیمپلیٹ دوبارہ ڈیزائن کریں۔';

  @override
  String bpAssignedTemp(Object token) {
    return 'یہ عنصر موجودہ پیداوار کے لیے $token سے منسلک کیا گیا — دیگر عناصر متاثر نہیں۔ تبدیلی مستقل رکھنے کے لیے ٹیمپلیٹ محفوظ کریں۔';
  }

  @override
  String bpAssignedSaved(Object token) {
    return 'یہ عنصر $token سے منسلک کیا گیا اور تبدیلی ٹیمپلیٹ میں محفوظ کر دی گئی۔ دیگر عناصر متاثر نہیں۔';
  }

  @override
  String get commonShow => 'دکھائیں';

  @override
  String get commonHide => 'چھپائیں';

  @override
  String get themeSwitchToLight => 'روشن تھیم پر جائیں';

  @override
  String get themeSwitchToDark => 'گہرے تھیم پر جائیں';

  @override
  String commonComingSoonPhase(Object phase) {
    return 'جاری ہے — مرحلہ $phase';
  }

  @override
  String get cbNewCertificateTitle => 'نیا سرٹیفکیٹ';

  @override
  String get cbNewContractTitle => 'نیا معاہدہ';

  @override
  String get cbBeneficiaryDataTitle => 'مستفید کے اعداد و شمار (نمونہ)';

  @override
  String get cbContractDataTitle => 'معاہدے کے اعداد و شمار (نمونہ)';

  @override
  String get editorSendBackward => 'پیچھے بھیجیں';

  @override
  String get editorRotateLeft => '90° بائیں گھمائیں';

  @override
  String get editorRotateRight => '90° دائیں گھمائیں';

  @override
  String get editorFlipH => 'افقی پلٹیں';

  @override
  String get editorFlipV => 'عمودی پلٹیں';

  @override
  String get editorTransform => 'تبدیلیاں';

  @override
  String get editorToolSelect => 'انتخاب';

  @override
  String get editorToolShapes => 'اشکال';

  @override
  String get editorFillType => 'بھرائی کی قسم';

  @override
  String get editorFillSolid => 'ٹھوس';

  @override
  String get editorGradientLinear => 'لکیری گریڈینٹ';

  @override
  String get editorGradientRadial => 'ریڈیل گریڈینٹ';

  @override
  String get editorGradientAngle => 'گریڈینٹ زاویہ';

  @override
  String get editorShadowEnable => 'سایہ شامل کریں';

  @override
  String get editorShadowColor => 'سائے کا رنگ';

  @override
  String get editorShadowBlur => 'سائے کی دھندلاہٹ';

  @override
  String get editorShadowOffsetX => 'افقی ہٹاؤ';

  @override
  String get editorShadowOffsetY => 'عمودی ہٹاؤ';

  @override
  String get editorShadowSpread => 'پھیلاؤ';

  @override
  String get editorShadowRemove => 'سایہ ہٹائیں';

  @override
  String get editorPoints => 'نوک';

  @override
  String get editorInnerRadius => 'اندرونی رداس';

  @override
  String get editorCornerTopLeft => 'اوپر بائیں';

  @override
  String get editorCornerTopRight => 'اوپر دائیں';

  @override
  String get editorCornerBottomRight => 'نیچے دائیں';

  @override
  String get editorCornerBottomLeft => 'نیچے بائیں';

  @override
  String get editorDashPattern => 'ڈیش پیٹرن';

  @override
  String get editorBooleanOps => 'بولین عمل';

  @override
  String get editorBooleanUnion => 'ضم کریں';

  @override
  String get editorBooleanSubtract => 'تفریق';

  @override
  String get editorBooleanIntersect => 'تقاطع';

  @override
  String get editorBooleanUngroup => 'الگ کریں';

  @override
  String get paletteStar => 'ستارہ';

  @override
  String get palettePolygon => 'کثیرالاضلاع';

  @override
  String get editorBooleanExclude => 'استثناء';

  @override
  String get editorBooleanHint =>
      'ملحق شدہ راستہ ایک ہی بولین نتیجہ ہے (اندرونی حدود کے بغیر) اور کسی بھی وقت الگ کیا جا سکتا ہے۔';

  @override
  String get editorDockTools => 'ٹول پینل';

  @override
  String get editorDockAnchor => 'ڈاک کی جگہ';

  @override
  String get editorDockTopBar => 'اوپری پٹی';

  @override
  String get editorDockInspector => 'سائیڈ پینل';

  @override
  String get editorDockLeftRail => 'سائیڈ ریل';

  @override
  String get editorDockFloating => 'تیرتا ہوا';

  @override
  String get editorDockCollapse => 'ٹولز سکیڑیں';

  @override
  String get editorDockExpand => 'ٹولز پھیلائیں';

  @override
  String get editorDockResize => 'سائز بدلنے کے لیے کھینچیں';

  @override
  String get editorDockDropHint => 'یہاں چھوڑ کر منسلک کریں';

  @override
  String get editorMoreTools => 'مزید ٹولز';

  @override
  String get editorDocumentProperties => 'دستاویز کی خصوصیات';

  @override
  String get editorDockReset => 'ڈیفالٹ ڈاکنگ بحال کریں';

  @override
  String get editorTextShadow => 'متن کا سایہ';

  @override
  String get editorTextShadowAdd => 'متن پر سایہ شامل کریں';

  @override
  String get editorShadowOpacity => 'سائے کی شفافیت';

  @override
  String get genderMale => 'مذکر';

  @override
  String get genderFemale => 'مؤنث';

  @override
  String get genderPreviewAutoHint => 'جبر ہٹانے کے لیے کلک کریں (خودکار)';

  @override
  String get genderPresetCompleted => '”completed“ (مذکر/مؤنث)';

  @override
  String get genderPresetPassed => '”passed“ (مذکر/مؤنث)';

  @override
  String get genderPresetForStudent => '”for the student“ (مذکر/مؤنث)';

  @override
  String get genderPresetStudent => '”the student“ (مذکر/مؤنث)';

  @override
  String get genderPresetToHim => '”to him / to her“';

  @override
  String get genderPresetHonoring => '”the outstanding trainee“ (مذکر/مؤنث)';

  @override
  String get editorGenderSnippet => 'مشروط جملہ شامل کریں';

  @override
  String get editorGenderSnippetHint =>
      'ایک جملہ شامل کرتا ہے جو وصول کنندہ کی جنس کے مطابق خود بدلتا ہے۔';

  @override
  String get bpGenderReviewTitle => 'جنس کا جائزہ (مذکر/مؤنث)';

  @override
  String get bpGenderReviewSubtitle =>
      'جنس نام یا ”جنس“ کالم سے معلوم ہوتی ہے — چھاپنے سے پہلے غیر معمولی کیس درست کریں۔';

  @override
  String get bpGenderRow => 'قطار';

  @override
  String get bpGenderDetected => 'معلوم شدہ';

  @override
  String get bpGenderEffective => 'لاگو';

  @override
  String get bpGenderNameColumn => 'نام';

  @override
  String get bpGenderEditName => 'نام میں ترمیم کریں';

  @override
  String get bpGenderNameHint => 'درست نام لکھیں';

  @override
  String get bpGenderClearOverrides => 'ترامیم صاف کریں';

  @override
  String get bpGenderOverridden => 'دستی طور پر درست';

  @override
  String get bpGenderUnknownName => '—';

  @override
  String get bpOutputTitle => 'سرٹیفکیٹ محفوظ کرنے کی جگہ';

  @override
  String get bpOutputHint =>
      'تیار کردہ PDF محفوظ کرنے کے لیے فولڈر منتخب کریں، یا طے شدہ مقام سے شروع کریں۔';

  @override
  String get bpOutputPickFolder => 'فولڈر منتخب کریں…';

  @override
  String get bpOutputStart => 'تیاری شروع کریں';

  @override
  String get bpOutputPathLabel => 'منتخب فولڈر';

  @override
  String get bpOutputNoFolder => 'کوئی فولڈر منتخب نہیں — صرف پرنٹ اور برآمد۔';

  @override
  String get bpOpenFolder => 'فولڈر کھولیں';

  @override
  String get bpOutputSavedTitle => 'PDF فائل محفوظ ہو گئی';

  @override
  String get bpOpenFolderFailed => 'فولڈر نہیں کھل سکا۔';

  @override
  String get bpOutputNameLabel => 'برآمد فائل کا نام';

  @override
  String get bpOutputNameHint => 'بغیر توسیع کے نام لکھیں';

  @override
  String get bpOutputNamePreviewLabel => 'اس نام سے محفوظ ہوگا';

  @override
  String get bpOutputModeLabel => 'محفوظ کرنے کا انداز';

  @override
  String get bpOutputModeCombined => 'ایک مرکب فائل';

  @override
  String get bpOutputModeIndividual => 'ہر شخص کے لیے الگ فائل';

  @override
  String get hubTitle => 'نیا پروجیکٹ';

  @override
  String get hubSubtitle =>
      'تیار سائز منتخب کریں یا اپنا مقرر کریں — کینوس بالکل درست سائز اور تناسب کے ساتھ کھلے گا۔';

  @override
  String get hubKindSingle => 'ایک ورق کی مطبوعات اور دستاویزات';

  @override
  String get hubKindMulti => 'کثیر الصفحات کتابیں اور مطبوعات';

  @override
  String get hubKindSingleHint =>
      'ایک ورق: سرٹیفکیٹ، معاہدے، کارڈ، نشست نمبر، مبارکبادی کارڈ۔';

  @override
  String get hubKindMultiHint =>
      'کثیر الصفحات: کتاب، رسالہ، کتابچہ، رپورٹ، کیٹلاگ۔';

  @override
  String get hubGroupCertificates => 'سرٹیفکیٹ اور معاہدے';

  @override
  String get hubGroupCards => 'کارڈ اور شناختی بیج';

  @override
  String get hubGroupSeat => 'نشست نمبر اور لیبل';

  @override
  String get hubGroupGreeting => 'مبارکبادی کارڈ';

  @override
  String get hubGroupPublications => 'کتابیں اور مطبوعات';

  @override
  String get hubGroupCustom => 'اپنی مرضی کا سائز';

  @override
  String get hubDigitalBadge => 'ڈیجیٹل';

  @override
  String get hubCreate => 'بنائیں';

  @override
  String get hubCustomCardBody =>
      'اپنے پیمانے کسی بھی اکائی میں درج کریں اور اپنے سائز کے کینوس سے آغاز کریں۔';

  @override
  String get hubCustomName => 'پروجیکٹ کا نام';

  @override
  String get hubCustomNameHint => 'مثلاً دعوتی کارڈ';

  @override
  String get hubCustomPreview => 'آخری سائز';

  @override
  String get hubCustomCreate => 'کینوس بنائیں';

  @override
  String get hubCustomType => 'پروجیکٹ کی قسم';

  @override
  String get hubSearchHint => 'سائز تلاش کریں…';

  @override
  String get hubNoResults => 'کوئی مماثل سائز نہیں — دوسرا لفظ آزمائیں۔';

  @override
  String get hubAspectRatio => 'تناسب';

  @override
  String get destNewProject => 'نیا پروجیکٹ';

  @override
  String get destNewProjectDesc =>
      'تیار یا اپنی مرضی کا سائز منتخب کریں اور فوراً ڈیزائن شروع کریں۔';

  @override
  String get ptpImpositionToggle => 'پرنٹ ترتیب';

  @override
  String get ptpImpositionNoFit =>
      'ورق اس آئٹم کے لیے بہت چھوٹا ہے — حاشیے کم کریں یا بڑا ورق منتخب کریں۔';

  @override
  String get editorEffectsTitle => 'اثرات اور رنگ کی ایڈجسٹمنٹ';

  @override
  String get editorShadowGroup => 'سایہ';

  @override
  String get editorOuterGlow => 'بیرونی چمک';

  @override
  String get editorInnerGlow => 'اندرونی چمک';

  @override
  String get editorGlowAdd => 'چمک شامل کریں';

  @override
  String get editorGlowRemove => 'چمک ہٹائیں';

  @override
  String get editorGlowColor => 'چمک کا رنگ';

  @override
  String get editorGlowRadius => 'چمک کا دائرہ';

  @override
  String get editorGlowSpread => 'چمک کا پھیلاؤ';

  @override
  String get editorGlowOpacity => 'چمک کی شفافیت';

  @override
  String get editorAdjustGroup => 'رنگ کی ایڈجسٹمنٹ';

  @override
  String get editorAdjustBrightness => 'روشنی';

  @override
  String get editorAdjustContrast => 'تضاد';

  @override
  String get editorAdjustSaturation => 'سیرابی';

  @override
  String get editorAdjustHue => 'رنگت';

  @override
  String get editorAdjustReset => 'ری سیٹ';

  @override
  String get bpOutputSavedFolderTitle => 'فائلیں الگ فولڈر میں محفوظ ہیں';

  @override
  String get hubDetailsTitle => 'سائز کی تفصیلات';

  @override
  String get hubDetailsHint =>
      'پیش فرض تفصیلات بھری ہوئی — گرڈ سے سائز چنیں یا پیمائش تبدیل کریں۔';

  @override
  String get hubFilterAll => 'سب';

  @override
  String get hubFilterRecent => 'حالیہ سائز';

  @override
  String get hubFilterSeat => 'نشست نمبر';

  @override
  String get hubFilterGreeting => 'مبارکبادیں اور اسکرینیں';

  @override
  String get hubRecentEmpty =>
      'ابھی کوئی حالیہ سائز نہیں — آپ کا بنایا ہوا کوئی بھی پروجیکٹ یہاں آئے گا۔';

  @override
  String get hubDocTitle => 'پروجیکٹ کا نام';

  @override
  String get hubDocTitleHint => 'نیا پروجیکٹ - 1';

  @override
  String get hubWidth => 'چوڑائی';

  @override
  String get hubHeight => 'اونچائی';

  @override
  String get hubUnitLabel => 'اکائی';

  @override
  String get hubOrientationLabel => 'رخ';

  @override
  String get hubPortrait => 'عمودی';

  @override
  String get hubLandscape => 'افقی';

  @override
  String get hubVariantLabel => 'قسم';

  @override
  String get hubResolutionLabel => 'ریزولوشن';

  @override
  String get hubResolutionUnitLabel => 'ریزولوشن اکائی';

  @override
  String get hubColorModeLabel => 'رنگ موڈ';

  @override
  String get hubBackgroundLabel => 'پس منظر کا رنگ';

  @override
  String get hubBackgroundWhite => 'سفید';

  @override
  String get hubBackgroundTransparent => 'شفاف';

  @override
  String get hubBackgroundBlack => 'سیاہ';

  @override
  String get hubBackgroundCustom => 'اپنی رنگت';

  @override
  String get hubCreateProject => 'پروجیکٹ بنائیں';

  @override
  String get hubCustomFamilyTitle => 'اپنا سائز';

  @override
  String get newDocTitle => 'نیا دستاویز';

  @override
  String get newDocScopeSocial => 'اسکرینیں اور مبارکبادیں';

  @override
  String get newDocFilterCertificates => 'اسناد';

  @override
  String get newDocFilterCards => 'کارڈز';

  @override
  String get newDocFilterGreeting => 'مبارکبادیں';

  @override
  String get newDocFilterPublications => 'مطبوعات';

  @override
  String get menuFile => 'فائل';

  @override
  String get menuEdit => 'ترمیم';

  @override
  String get menuView => 'منظر';

  @override
  String get menuTools => 'اوزار';

  @override
  String get menuHelp => 'مدد';

  @override
  String get menuNewDocument => 'نیا دستاویز…';

  @override
  String get menuPurgeRecent => 'حالیہ سائز صاف کریں';

  @override
  String get menuPurgeImageCache => 'تصاویر کیشے صاف کریں';

  @override
  String get menuPreviewCertificate => 'نمونہ سرٹیفکیٹ دیکھیں';

  @override
  String get menuPreviewContract => 'نمونہ معاہدہ دیکھیں';

  @override
  String get menuAbout => 'JoodCraft کے بارے میں';

  @override
  String get actionNewShort => '+ نیا';

  @override
  String get dashLocalMode => 'مقامی';

  @override
  String get dashLocalStorage =>
      'اس ڈیوائس پر مقامی طور پر محفوظ — کوئی پروجیکٹ سرور پر اپلوڈ نہیں ہوتا۔';

  @override
  String get dashRecentProjects => 'حالیہ پروجیکٹس';

  @override
  String get dashRecentEmpty =>
      'اس ڈیوائس پر ابھی کوئی محفوظ پروجیکٹ نہیں — نیا دستاویز بنائیں، یہاں فوراً نظر آئے گا۔';

  @override
  String get dashRecentOpen => 'پروجیکٹ کھولیں';

  @override
  String get dashRoadmapLocal =>
      'مقامی پروجیکٹ ڈیٹا بیس (projects ٹیبل) کے ساتھ 100% آف لائن محفوظ';

  @override
  String get dashRoadmapOffline =>
      'مکمل آف لائن: پروجیکٹ اپلوڈ نہیں اور نیٹ ورک کی ضرورت نہیں';

  @override
  String get editorTransformPosition => 'تبدیلی اور پوزیشن';

  @override
  String get editorTransformPositionHint => 'پوزیشن، سائز اور گردش کا زاویہ';

  @override
  String get editorAppearanceEffects => 'ظاہری شکل اور اثرات';

  @override
  String get editorAppearanceEffectsHint => 'بھرائی، بارڈر، چمک اور سائے';

  @override
  String get editorTypographyHint => 'فونٹ، سائز، سیدھ اور وقفہ';

  @override
  String get editorPageSettingsHint => 'سائز اور پیمائش کی اکائی';

  @override
  String get editorBackgroundHint => 'صفحے کا رنگ یا گریڈینٹ';

  @override
  String get editorPrecisionHint => 'باریک حرکت اور پیمانہ';

  @override
  String get joodExportProject => 'پروجیکٹ برآمد کریں (.jood)';

  @override
  String get joodImportProject => 'پروجیکٹ کھولیں (.jood)';

  @override
  String get joodExportReady => 'پروجیکٹ فائل محفوظ کرنے کے لیے تیار ہے۔';

  @override
  String get joodExportFailed => 'پروجیکٹ فائل برآمد نہیں ہو سکی۔';

  @override
  String get joodImportOpened => 'درآمد شدہ پروجیکٹ کھل گیا۔';

  @override
  String get joodImportFailed => 'پروجیکٹ فائل کھولی نہیں جا سکی۔';

  @override
  String get joodRecoveryTitle => 'غیر محفوظ مسودہ';

  @override
  String get joodRecoveryMessage =>
      'پچھلی نشست سے ایک غیر محفوظ مسودہ موجود ہے۔ کیا آپ اسے بحال کرنا چاہتے ہیں؟';

  @override
  String get joodRecoveryRestore => 'بحال کریں';

  @override
  String get joodRecoveryDiscard => 'نظر انداز کریں';

  @override
  String get joodRecoveryRestored => 'مسودہ بحال ہو گیا۔';

  @override
  String get joodAutosaveSaved => 'خودکار محفوظ ہو گیا';

  @override
  String get joodAutosaveSaving => 'محفوظ ہو رہا ہے…';

  @override
  String get editorConfirm => 'تصدیق کریں';

  @override
  String get admTitle => 'مقامی منتظم کا انتظام';

  @override
  String get admRefresh => 'تازہ کریں';

  @override
  String get admTabAdmins => 'منتظمین';

  @override
  String get admTabTransfer => 'آلات کے درمیان منتقلی';

  @override
  String get admTabAudit => 'برآمد لاگ';

  @override
  String get admListTitle => 'اس آلے پر منتظم اکاؤنٹس';

  @override
  String get admAdd => 'منتظم شامل کریں';

  @override
  String get admNoAdmins => 'ابھی کوئی منتظم اکاؤنٹ نہیں۔';

  @override
  String get admLoading => 'اس ڈیوائس پر ایڈمن اکاؤنٹس لوڈ ہو رہے ہیں…';

  @override
  String get admRoleOwner => 'بنیادی منتظم';

  @override
  String get admCurrent => 'آپ';

  @override
  String get admCurrentCardTitle => 'اس ڈیوائس پر موجودہ اکاؤنٹ';

  @override
  String get admRoleAdmin => 'پرشفار';

  @override
  String get admSwitchTitle => 'تیز اکاؤنٹ تبدیلی';

  @override
  String get admSwitchPrompt =>
      'اس ڈیوائس پر کسی ذیلی ایڈمن کا مقامی صارف نام منتخب کریں اور اس کا مقامی پاس ورڈ درج کریں تاکہ فوراً اس کے سیشن میں جا سکیں — کھلے پروجیکٹ ڈرافٹ پہلے محفوظ ہو جاتے ہیں اور ماسٹر لائسنس متاثر نہیں ہوتا۔';

  @override
  String get admSwitchNoOthers =>
      'اس ڈیوائس پر کوئی دوسرا ذیلی ایڈمن نہیں۔ پہلے ایڈمن اسکرین سے نیا ایڈمن شامل کریں۔';

  @override
  String get admSwitchPick => 'مقامی صارف نام';

  @override
  String get admSwitchPassword => 'منتخب اکاؤنٹ کا مقامی پاس ورڈ';

  @override
  String get admSwitchPickPassword =>
      'صارف نام منتخب کریں اور پاس ورڈ درج کریں۔';

  @override
  String get admSwitchWrongPassword => 'پاس ورڈ غلط ہے۔';

  @override
  String get admSwitchFailed => 'اکاؤنٹ تبدیل نہیں ہو سکا۔ دوبارہ کوشش کریں۔';

  @override
  String get admSwitchSuccess => 'اکاؤنٹ کامیابی سے تبدیل ہو گیا۔';

  @override
  String get admSwitchAccount => 'اکاؤنٹ تبدیل کریں';

  @override
  String get admSwitchAction => 'ابھی تبدیل کریں';

  @override
  String get admColAdmin => 'ایڈمن';

  @override
  String get admColUsername => 'مقامی صارف نام';

  @override
  String get admColRole => 'کردار';

  @override
  String get admColCreated => 'شامل کرنے کی تاریخ';

  @override
  String get admColActions => 'اقدامات';

  @override
  String get destJoodWriter => 'جود رائٹر';

  @override
  String get destJoodWriterDesc =>
      'خودکار صفحہ بندی کے ساتھ متن دستاویزات اور رپورٹس۔';

  @override
  String get admCreatedAt => 'بنایا گیا';

  @override
  String get admEdit => 'تفصیلات میں ترمیم کریں';

  @override
  String get admChangePassword => 'پاس ورڈ تبدیل کریں';

  @override
  String get admPromote => 'بنیادی منتظم بنائیں';

  @override
  String get admDemote => 'منتظم بنا دیں';

  @override
  String get admDelete => 'اکاؤنٹ حذف کریں';

  @override
  String admDeleteConfirm(Object name) {
    return '“$name” اس آلے سے ہمیشہ کے لیے حذف کر دیا جائے گا۔ اسے واپس نہیں کیا جا سکتا۔';
  }

  @override
  String get admPromoted => 'بنیادی منتظم بنا دیا گیا۔';

  @override
  String get admDemoted => 'منتظم بنا دیا گیا۔';

  @override
  String get admDeleted => 'اکاؤنٹ حذف کر دیا گیا۔';

  @override
  String get admCreated => 'نیا منتظم شامل کر دیا گیا۔';

  @override
  String get admUpdated => 'منتظم کی تفصیلات اپ ڈیٹ ہو گئیں۔';

  @override
  String get admPasswordChanged => 'پاس ورڈ تبدیل ہو گیا۔';

  @override
  String get admTransferInfoTitle => 'منتقلی کیسے کام کرتی ہے؟';

  @override
  String get admTransferInfo1 =>
      'اکاؤنٹ کا جدول (پاس ورڈ ہیش کے ساتھ، کبھی پاس ورڈ کے ساتھ نہیں) آپ کی منتخب کردہ پاس فریز سے خفیہ کردہ فائل کے اندر برآمد کیا جاتا ہے۔';

  @override
  String get admTransferInfo2 =>
      'فائل یا کوڈ دوسرے آلے پر منتقل کریں اور وہاں اسی پاس فریز کے ساتھ درآمد کریں، اور اکاؤنٹس وہی اجازتوں کے ساتھ کام کریں گے۔';

  @override
  String get admTransferInfo3 =>
      'کسی سرور کو کچھ نہیں بھیجا جاتا: منتقلی مقامی آلات کے درمیان مکمل طور پر دستی ہے۔';

  @override
  String get admExport => 'اکاؤنٹس برآمد کریں';

  @override
  String get admExportPassphrase => 'برآمد پاس فریز';

  @override
  String get admPassphraseConfirm => 'پاس فریز کی تصدیق کریں';

  @override
  String get admExportRisk =>
      'میں سمجھتا ہوں کہ اس کوڈ اور اس کے پاس فریز کے حامل کوئی بھی شخص ان اکاؤنٹس سے سائن ان کر سکتا ہے، اس لیے میں اسے احتیاط سے شیئر کروں گا۔';

  @override
  String get admExportGenerate => 'خفیہ کوڈ بنائیں';

  @override
  String get admExportFile => 'مخصوص فائل میں محفوظ کریں';

  @override
  String get admExportDone =>
      'خفیہ کوڈ بن گیا۔ اسے کاپی کریں یا فائل میں محفوظ کریں۔';

  @override
  String get admExportFileSaved => 'اکاؤنٹس کی خفیہ فائل محفوظ ہو گئی۔';

  @override
  String get admPassphraseTooShort =>
      'پاس فریز کے لیے کم از کم 6 حروف استعمال کریں۔';

  @override
  String get admPassphraseMismatch => 'پاس فریز مماثل نہیں ہیں۔';

  @override
  String get admAcceptRiskRequired =>
      'پہلے تصدیق کریں کہ آپ کوڈ شیئر کرنے کے خطرے کو سمجھتے ہیں۔';

  @override
  String admFileError(Object error) {
    return 'فائل سنبھالی نہیں جا سکی: $error';
  }

  @override
  String get admImport => 'اکاؤنٹس درآمد کریں';

  @override
  String get admImportCode => 'اکاؤنٹ کوڈ';

  @override
  String get admImportPassphrase => 'فائل پاس فریز';

  @override
  String get admImportReplace => 'موجودہ اکاؤنٹس کے پاس ورڈ بدلیں';

  @override
  String get admImportPick => 'فائل منتخب کریں';

  @override
  String get admImportRun => 'ابھی درآمد کریں';

  @override
  String get admImportCodeRequired => 'پہلے کوڈ پیسٹ کریں یا فائل منتخب کریں۔';

  @override
  String get admImportPassphraseRequired => 'فائل کا پاس فریز درج کریں۔';

  @override
  String admImportDone(int added, int updated, int skipped) {
    return 'درآمد: $added نئے، $updated اپ ڈیٹ، $skipped نظرانداز۔';
  }

  @override
  String get admAuditTitle => 'جاری کردہ سرٹیفکیٹس اور دستاویزات کا لاگ';

  @override
  String get admAuditClear => 'لاگ صاف کریں';

  @override
  String get admAuditEmpty =>
      'ابھی کوئی برآمد نہیں۔ آپ جو بھی سرٹیفکیٹ یا معاہدہ برآمد کریں گے وہ اس کی تاریخ اور جاری کرنے والے منتظم کے ساتھ یہاں درج ہوگا۔';

  @override
  String get admAuditBy => 'از';

  @override
  String get admAuditPages => 'صفحات';

  @override
  String get admAuditClearConfirm =>
      'پورا برآمد لاگ اس آلے سے حذف کر دیا جائے گا۔ اسے واپس نہیں کیا جا سکتا۔';

  @override
  String get admAuditCleared => 'لاگ صاف ہو گیا۔';

  @override
  String get admUnavailableTitle => 'انتظام فی الحال دستیاب نہیں';

  @override
  String get admUnavailableBody =>
      'منتظم کا انتظام اس وقت کام کرتا ہے جب ایپ مقامی اکاؤنٹ (LocalAuthRepository) کے ساتھ چلتی ہے، تاکہ اکاؤنٹس اس آلے سے پڑھے جائیں۔';
}
