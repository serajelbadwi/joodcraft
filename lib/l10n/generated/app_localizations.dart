import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_id.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_tr.dart';
import 'app_localizations_ur.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('id'),
    Locale('ru'),
    Locale('tr'),
    Locale('ur'),
    Locale('zh'),
  ];

  /// No description provided for @editorDone.
  ///
  /// In ar, this message translates to:
  /// **'تم'**
  String get editorDone;

  /// No description provided for @appTagline.
  ///
  /// In ar, this message translates to:
  /// **'منصة توليد الشهادات والعقود الرسمية'**
  String get appTagline;

  /// No description provided for @navDashboard.
  ///
  /// In ar, this message translates to:
  /// **'لوحة التحكم'**
  String get navDashboard;

  /// No description provided for @navCertificates.
  ///
  /// In ar, this message translates to:
  /// **'محـرّك الشهادات'**
  String get navCertificates;

  /// No description provided for @navContracts.
  ///
  /// In ar, this message translates to:
  /// **'محـرّك العقود'**
  String get navContracts;

  /// No description provided for @navBatch.
  ///
  /// In ar, this message translates to:
  /// **'التوليد الجماعي'**
  String get navBatch;

  /// No description provided for @navTemplates.
  ///
  /// In ar, this message translates to:
  /// **'مكتبة القوالب'**
  String get navTemplates;

  /// No description provided for @navAssets.
  ///
  /// In ar, this message translates to:
  /// **'الأصول والتوقيعات'**
  String get navAssets;

  /// No description provided for @actionSignOut.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج'**
  String get actionSignOut;

  /// No description provided for @actionOpenMenu.
  ///
  /// In ar, this message translates to:
  /// **'القائمة'**
  String get actionOpenMenu;

  /// No description provided for @editorFitToScreen.
  ///
  /// In ar, this message translates to:
  /// **'ملاءمة الشاشة'**
  String get editorFitToScreen;

  /// No description provided for @editorNewTemplate.
  ///
  /// In ar, this message translates to:
  /// **'قالب جديد'**
  String get editorNewTemplate;

  /// No description provided for @editorNewConfirm.
  ///
  /// In ar, this message translates to:
  /// **'سيبدأ قالب جديد من التصميم الافتراضي؛ أي تعديلات غير محفوظة ستبقى في سجل التراجع. متابعة؟'**
  String get editorNewConfirm;

  /// No description provided for @actionBackToDashboard.
  ///
  /// In ar, this message translates to:
  /// **'العودة إلى لوحة التحكم'**
  String get actionBackToDashboard;

  /// No description provided for @offlineProcessingLabel.
  ///
  /// In ar, this message translates to:
  /// **'معالجة محلية'**
  String get offlineProcessingLabel;

  /// No description provided for @themeTooltip.
  ///
  /// In ar, this message translates to:
  /// **'تبديل المظهر'**
  String get themeTooltip;

  /// No description provided for @themeSystem.
  ///
  /// In ar, this message translates to:
  /// **'حسب النظام'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In ar, this message translates to:
  /// **'فاتح'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In ar, this message translates to:
  /// **'داكن'**
  String get themeDark;

  /// No description provided for @languageTooltip.
  ///
  /// In ar, this message translates to:
  /// **'تغيير اللغة'**
  String get languageTooltip;

  /// No description provided for @languageArabic.
  ///
  /// In ar, this message translates to:
  /// **'العربية'**
  String get languageArabic;

  /// No description provided for @languageEnglish.
  ///
  /// In ar, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageFrench.
  ///
  /// In ar, this message translates to:
  /// **'Français'**
  String get languageFrench;

  /// No description provided for @languageSpanish.
  ///
  /// In ar, this message translates to:
  /// **'Español'**
  String get languageSpanish;

  /// No description provided for @languageTurkish.
  ///
  /// In ar, this message translates to:
  /// **'Türkçe'**
  String get languageTurkish;

  /// No description provided for @languageUrdu.
  ///
  /// In ar, this message translates to:
  /// **'اردو'**
  String get languageUrdu;

  /// No description provided for @languageGerman.
  ///
  /// In ar, this message translates to:
  /// **'Deutsch'**
  String get languageGerman;

  /// No description provided for @languageIndonesian.
  ///
  /// In ar, this message translates to:
  /// **'Bahasa Indonesia'**
  String get languageIndonesian;

  /// No description provided for @languageRussian.
  ///
  /// In ar, this message translates to:
  /// **'Русский'**
  String get languageRussian;

  /// No description provided for @languageChinese.
  ///
  /// In ar, this message translates to:
  /// **'简体中文'**
  String get languageChinese;

  /// No description provided for @configMissingKeysTitle.
  ///
  /// In ar, this message translates to:
  /// **'لم يُعثر على مفاتيح الاتصال'**
  String get configMissingKeysTitle;

  /// No description provided for @configMissingKeysBody.
  ///
  /// In ar, this message translates to:
  /// **'يبحث التطبيق تلقائياً وقت التشغيل في ثلاثة مصادر: علامة --dart-define، ثم ملف env.json على القرص (الجذر أو assets/env/)، ثم النسخة المحزومة داخل التطبيق — ولم يُعثر على أيٍّ منها. أنشئ الملف واملأه مرة واحدة ثم شغّل بلا أي علامة:'**
  String get configMissingKeysBody;

  /// No description provided for @configEnvNote.
  ///
  /// In ar, this message translates to:
  /// **'الحزمة تُعلن مجلد assets/env/ كأصل، لذا غياب الملف لا يُسقط البناء من نسخة نظيفة. أنشئه من env.example.json أو شغّل: dart run tool/ensure_env.dart — والمفتاح المطلوب anon/public فقط، وservice_role لا يُستخدم في التطبيق إطلاقاً.'**
  String get configEnvNote;

  /// No description provided for @routeNotFoundTitle.
  ///
  /// In ar, this message translates to:
  /// **'الصفحة غير موجودة'**
  String get routeNotFoundTitle;

  /// No description provided for @routeNotFoundBody.
  ///
  /// In ar, this message translates to:
  /// **'المسار المطلوب غير معرّف في التطبيق:'**
  String get routeNotFoundBody;

  /// No description provided for @editorPrecisionTitle.
  ///
  /// In ar, this message translates to:
  /// **'الضبط الدقيق'**
  String get editorPrecisionTitle;

  /// No description provided for @editorNudgeStep.
  ///
  /// In ar, this message translates to:
  /// **'خطوة النقل'**
  String get editorNudgeStep;

  /// No description provided for @editorNudgeStepHint.
  ///
  /// In ar, this message translates to:
  /// **'الأسهم في اللوحة تنقل بـ Shift = 10px أيضاً.'**
  String get editorNudgeStepHint;

  /// No description provided for @editorNudgeUp.
  ///
  /// In ar, this message translates to:
  /// **'نقل لأعلى'**
  String get editorNudgeUp;

  /// No description provided for @editorNudgeLeft.
  ///
  /// In ar, this message translates to:
  /// **'نقل لليسار'**
  String get editorNudgeLeft;

  /// No description provided for @editorNudgeDown.
  ///
  /// In ar, this message translates to:
  /// **'نقل لأسفل'**
  String get editorNudgeDown;

  /// No description provided for @editorNudgeRight.
  ///
  /// In ar, this message translates to:
  /// **'نقل لليمين'**
  String get editorNudgeRight;

  /// No description provided for @editorScale.
  ///
  /// In ar, this message translates to:
  /// **'التحجيم'**
  String get editorScale;

  /// No description provided for @editorScaleHint.
  ///
  /// In ar, this message translates to:
  /// **'تحجيم نسبي حول مركز العنصر (عجلة الفأرة فوق الزر تسرّع الخطوة).'**
  String get editorScaleHint;

  /// No description provided for @editorScaleUp.
  ///
  /// In ar, this message translates to:
  /// **'تكبير'**
  String get editorScaleUp;

  /// No description provided for @editorScaleDown.
  ///
  /// In ar, this message translates to:
  /// **'تصغير'**
  String get editorScaleDown;

  /// No description provided for @editorDecorTitle.
  ///
  /// In ar, this message translates to:
  /// **'الزخرفة المتجهية'**
  String get editorDecorTitle;

  /// No description provided for @editorDecorKind.
  ///
  /// In ar, this message translates to:
  /// **'نوع الزخرفة'**
  String get editorDecorKind;

  /// No description provided for @editorDecorPalette.
  ///
  /// In ar, this message translates to:
  /// **'لوحة الألوان'**
  String get editorDecorPalette;

  /// No description provided for @editorDecorLayers.
  ///
  /// In ar, this message translates to:
  /// **'عدد الطبقات'**
  String get editorDecorLayers;

  /// No description provided for @editorDecorSeed.
  ///
  /// In ar, this message translates to:
  /// **'البذرة'**
  String get editorDecorSeed;

  /// No description provided for @editorDecorThickness.
  ///
  /// In ar, this message translates to:
  /// **'السماكة'**
  String get editorDecorThickness;

  /// No description provided for @editorDecorPrimary.
  ///
  /// In ar, this message translates to:
  /// **'اللون الأساسي'**
  String get editorDecorPrimary;

  /// No description provided for @editorDecorSecondary.
  ///
  /// In ar, this message translates to:
  /// **'اللون الثاني'**
  String get editorDecorSecondary;

  /// No description provided for @editorDecorAccent.
  ///
  /// In ar, this message translates to:
  /// **'لون اللمسة'**
  String get editorDecorAccent;

  /// No description provided for @editorDecorGradient.
  ///
  /// In ar, this message translates to:
  /// **'تدرّج الطبقات'**
  String get editorDecorGradient;

  /// No description provided for @editorDecorGallery.
  ///
  /// In ar, this message translates to:
  /// **'معرض الوصفات'**
  String get editorDecorGallery;

  /// No description provided for @editorDecorGalleryTitle.
  ///
  /// In ar, this message translates to:
  /// **'معرض الزخارف الجاهزة'**
  String get editorDecorGalleryTitle;

  /// No description provided for @editorClose.
  ///
  /// In ar, this message translates to:
  /// **'إغلاق'**
  String get editorClose;

  /// No description provided for @editorDecorPaletteCustom.
  ///
  /// In ar, this message translates to:
  /// **'مخصصة'**
  String get editorDecorPaletteCustom;

  /// No description provided for @decorKindModernWave.
  ///
  /// In ar, this message translates to:
  /// **'موجات حديثة'**
  String get decorKindModernWave;

  /// No description provided for @decorKindPaperCut.
  ///
  /// In ar, this message translates to:
  /// **'قصّ ورقي متعدد الطبقات'**
  String get decorKindPaperCut;

  /// No description provided for @decorKindClassicCorner.
  ///
  /// In ar, this message translates to:
  /// **'إطار كلاسيكي مزخرف'**
  String get decorKindClassicCorner;

  /// No description provided for @decorKindGuilloche.
  ///
  /// In ar, this message translates to:
  /// **'نمط غيوش الأمني'**
  String get decorKindGuilloche;

  /// No description provided for @decorKindRibbonBanner.
  ///
  /// In ar, this message translates to:
  /// **'شريط/وسام'**
  String get decorKindRibbonBanner;

  /// No description provided for @decorPaletteRoyalGold.
  ///
  /// In ar, this message translates to:
  /// **'ذهبي ملكي'**
  String get decorPaletteRoyalGold;

  /// No description provided for @decorPaletteRoyalBlue.
  ///
  /// In ar, this message translates to:
  /// **'أزرق ملكي'**
  String get decorPaletteRoyalBlue;

  /// No description provided for @decorPaletteEmerald.
  ///
  /// In ar, this message translates to:
  /// **'زمردي'**
  String get decorPaletteEmerald;

  /// No description provided for @decorPaletteBurgundy.
  ///
  /// In ar, this message translates to:
  /// **'عنابي'**
  String get decorPaletteBurgundy;

  /// No description provided for @decorPaletteMidnight.
  ///
  /// In ar, this message translates to:
  /// **'كحلي ليلي'**
  String get decorPaletteMidnight;

  /// No description provided for @decorPaletteMono.
  ///
  /// In ar, this message translates to:
  /// **'رمادي أحادي'**
  String get decorPaletteMono;

  /// No description provided for @editorSignatureTitle.
  ///
  /// In ar, this message translates to:
  /// **'كتلة التوقيعات'**
  String get editorSignatureTitle;

  /// No description provided for @editorSignatureCount.
  ///
  /// In ar, this message translates to:
  /// **'عدد التوقيعات'**
  String get editorSignatureCount;

  /// No description provided for @signatureCountOne.
  ///
  /// In ar, this message translates to:
  /// **'توقيع واحد'**
  String get signatureCountOne;

  /// No description provided for @signatureCountTwo.
  ///
  /// In ar, this message translates to:
  /// **'توقيعان'**
  String get signatureCountTwo;

  /// No description provided for @signatureCountThree.
  ///
  /// In ar, this message translates to:
  /// **'ثلاثة توقيعات'**
  String get signatureCountThree;

  /// No description provided for @editorSignatureOrder.
  ///
  /// In ar, this message translates to:
  /// **'ترتيب الخانات'**
  String get editorSignatureOrder;

  /// No description provided for @editorSignatureOrderHint.
  ///
  /// In ar, this message translates to:
  /// **'في المستندات العربية تقع الخانة الأولى في أقصى اليمين.'**
  String get editorSignatureOrderHint;

  /// No description provided for @editorSignatureFirstRight.
  ///
  /// In ar, this message translates to:
  /// **'الأولى يميناً'**
  String get editorSignatureFirstRight;

  /// No description provided for @editorSignatureFirstLeft.
  ///
  /// In ar, this message translates to:
  /// **'الأولى يساراً'**
  String get editorSignatureFirstLeft;

  /// No description provided for @editorDirectionAuto.
  ///
  /// In ar, this message translates to:
  /// **'تلقائي'**
  String get editorDirectionAuto;

  /// No description provided for @editorSignatureImageAlign.
  ///
  /// In ar, this message translates to:
  /// **'محاذاة الصورة'**
  String get editorSignatureImageAlign;

  /// No description provided for @editorAlignStart.
  ///
  /// In ar, this message translates to:
  /// **'بداية'**
  String get editorAlignStart;

  /// No description provided for @editorAlignCenter.
  ///
  /// In ar, this message translates to:
  /// **'وسط'**
  String get editorAlignCenter;

  /// No description provided for @editorAlignEnd.
  ///
  /// In ar, this message translates to:
  /// **'نهاية'**
  String get editorAlignEnd;

  /// No description provided for @editorSignatureDivider.
  ///
  /// In ar, this message translates to:
  /// **'خط التوقيع'**
  String get editorSignatureDivider;

  /// No description provided for @editorVisible.
  ///
  /// In ar, this message translates to:
  /// **'ظاهر'**
  String get editorVisible;

  /// No description provided for @editorHidden.
  ///
  /// In ar, this message translates to:
  /// **'مخفي'**
  String get editorHidden;

  /// No description provided for @editorSignatureNameSize.
  ///
  /// In ar, this message translates to:
  /// **'حجم الاسم'**
  String get editorSignatureNameSize;

  /// No description provided for @editorSignatureRoleSize.
  ///
  /// In ar, this message translates to:
  /// **'حجم الدور'**
  String get editorSignatureRoleSize;

  /// No description provided for @editorSignatureSpacing.
  ///
  /// In ar, this message translates to:
  /// **'التباعد'**
  String get editorSignatureSpacing;

  /// No description provided for @editorSignatureImageSize.
  ///
  /// In ar, this message translates to:
  /// **'حجم الصورة'**
  String get editorSignatureImageSize;

  /// No description provided for @editorSignatureNameColor.
  ///
  /// In ar, this message translates to:
  /// **'لون الاسم'**
  String get editorSignatureNameColor;

  /// No description provided for @editorSignatureRoleColor.
  ///
  /// In ar, this message translates to:
  /// **'لون الدور'**
  String get editorSignatureRoleColor;

  /// No description provided for @editorFont.
  ///
  /// In ar, this message translates to:
  /// **'الخط'**
  String get editorFont;

  /// No description provided for @editorImageSource.
  ///
  /// In ar, this message translates to:
  /// **'مصدر الصورة'**
  String get editorImageSource;

  /// No description provided for @imageSourceAppAssets.
  ///
  /// In ar, this message translates to:
  /// **'أصول التطبيق'**
  String get imageSourceAppAssets;

  /// No description provided for @imageSourceMyLibrary.
  ///
  /// In ar, this message translates to:
  /// **'مكتبة أصولي'**
  String get imageSourceMyLibrary;

  /// No description provided for @imageSourceLocalFile.
  ///
  /// In ar, this message translates to:
  /// **'ملف محلي'**
  String get imageSourceLocalFile;

  /// No description provided for @imageSourceEmbedded.
  ///
  /// In ar, this message translates to:
  /// **'بيانات مضمّنة'**
  String get imageSourceEmbedded;

  /// No description provided for @editorSignatureChangeImage.
  ///
  /// In ar, this message translates to:
  /// **'تغيير صورة التوقيع'**
  String get editorSignatureChangeImage;

  /// No description provided for @editorSignatureAddImage.
  ///
  /// In ar, this message translates to:
  /// **'إضافة صورة توقيع'**
  String get editorSignatureAddImage;

  /// No description provided for @editorSignatureRemoveImage.
  ///
  /// In ar, this message translates to:
  /// **'إزالة صورة التوقيع'**
  String get editorSignatureRemoveImage;

  /// No description provided for @editorSignaturePickImageTitle.
  ///
  /// In ar, this message translates to:
  /// **'اختر صورة التوقيع من مكتبة أصولي'**
  String get editorSignaturePickImageTitle;

  /// No description provided for @editorSignatureSlot.
  ///
  /// In ar, this message translates to:
  /// **'الخانة'**
  String get editorSignatureSlot;

  /// No description provided for @editorSignatureRoleField.
  ///
  /// In ar, this message translates to:
  /// **'الدور (مثل: المدير العام)'**
  String get editorSignatureRoleField;

  /// No description provided for @editorSignatureNameField.
  ///
  /// In ar, this message translates to:
  /// **'اسم المُوقّع (يقبل حقلاً ديناميكياً)'**
  String get editorSignatureNameField;

  /// No description provided for @editorFromMyLibrary.
  ///
  /// In ar, this message translates to:
  /// **'من مكتبة أصولي'**
  String get editorFromMyLibrary;

  /// No description provided for @paletteSignatureBlock.
  ///
  /// In ar, this message translates to:
  /// **'توقيعات'**
  String get paletteSignatureBlock;

  /// No description provided for @editorInsertFromLibraryTooltip.
  ///
  /// In ar, this message translates to:
  /// **'إدراج إطار أو شعار مرفوع مباشرةً'**
  String get editorInsertFromLibraryTooltip;

  /// No description provided for @unsupportedElementVersionNote.
  ///
  /// In ar, this message translates to:
  /// **'هذا العنصر من إصدار أحدث من المحرر — يُحفظ كما هو ولا يمكن تعديله هنا.'**
  String get unsupportedElementVersionNote;

  /// No description provided for @editorSelectedCount.
  ///
  /// In ar, this message translates to:
  /// **'{count} عناصر محددة'**
  String editorSelectedCount(Object count);

  /// No description provided for @editorClearSelection.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء التحديد'**
  String get editorClearSelection;

  /// No description provided for @editorGroup.
  ///
  /// In ar, this message translates to:
  /// **'المجموعة'**
  String get editorGroup;

  /// No description provided for @editorOpacity.
  ///
  /// In ar, this message translates to:
  /// **'الشفافية'**
  String get editorOpacity;

  /// No description provided for @editorBringToFront.
  ///
  /// In ar, this message translates to:
  /// **'إلى المقدمة'**
  String get editorBringToFront;

  /// No description provided for @editorSendToBack.
  ///
  /// In ar, this message translates to:
  /// **'إلى الخلف'**
  String get editorSendToBack;

  /// No description provided for @editorDuplicate.
  ///
  /// In ar, this message translates to:
  /// **'تكرار'**
  String get editorDuplicate;

  /// No description provided for @editorDeleteSelected.
  ///
  /// In ar, this message translates to:
  /// **'حذف المحدد'**
  String get editorDeleteSelected;

  /// No description provided for @editorGroupDragHint.
  ///
  /// In ar, this message translates to:
  /// **'اسحب المجموعة بالماوس، والأسهم للتحريك الدقيق (Shift = 10px)، و Ctrl + نقر لتعديل التحديد.'**
  String get editorGroupDragHint;

  /// No description provided for @destBrand.
  ///
  /// In ar, this message translates to:
  /// **'الهوية والبروفايل'**
  String get destBrand;

  /// No description provided for @destBrandDesc.
  ///
  /// In ar, this message translates to:
  /// **'شعارك وأختامك وتوقيعاتك وألوان هويتك.'**
  String get destBrandDesc;

  /// No description provided for @brandTitle.
  ///
  /// In ar, this message translates to:
  /// **'إعدادات الهوية والبروفايل'**
  String get brandTitle;

  /// No description provided for @brandTabVisuals.
  ///
  /// In ar, this message translates to:
  /// **'الهوية والبصريات'**
  String get brandTabVisuals;

  /// No description provided for @brandTabText.
  ///
  /// In ar, this message translates to:
  /// **'البيانات النصية'**
  String get brandTabText;

  /// No description provided for @brandTabColors.
  ///
  /// In ar, this message translates to:
  /// **'الألوان والخطوط'**
  String get brandTabColors;

  /// No description provided for @brandTabPreview.
  ///
  /// In ar, this message translates to:
  /// **'معاينة الهوية'**
  String get brandTabPreview;

  /// No description provided for @brandPrimaryLogo.
  ///
  /// In ar, this message translates to:
  /// **'الشعار الرئيسي'**
  String get brandPrimaryLogo;

  /// No description provided for @brandWatermarkLogo.
  ///
  /// In ar, this message translates to:
  /// **'شعار العلامة المائية'**
  String get brandWatermarkLogo;

  /// No description provided for @brandSeals.
  ///
  /// In ar, this message translates to:
  /// **'الأختام الرسمية'**
  String get brandSeals;

  /// No description provided for @brandAddSeal.
  ///
  /// In ar, this message translates to:
  /// **'إضافة ختم'**
  String get brandAddSeal;

  /// No description provided for @brandSealName.
  ///
  /// In ar, this message translates to:
  /// **'اسم الختم'**
  String get brandSealName;

  /// No description provided for @brandSignatures.
  ///
  /// In ar, this message translates to:
  /// **'التوقيعات المعتمدة'**
  String get brandSignatures;

  /// No description provided for @brandAddSignature.
  ///
  /// In ar, this message translates to:
  /// **'إضافة توقيع'**
  String get brandAddSignature;

  /// No description provided for @brandSignatureName.
  ///
  /// In ar, this message translates to:
  /// **'اسم صاحب التوقيع'**
  String get brandSignatureName;

  /// No description provided for @brandSignatureTitle.
  ///
  /// In ar, this message translates to:
  /// **'المسمّى الوظيفي'**
  String get brandSignatureTitle;

  /// No description provided for @brandRemove.
  ///
  /// In ar, this message translates to:
  /// **'إزالة'**
  String get brandRemove;

  /// No description provided for @brandNoSeals.
  ///
  /// In ar, this message translates to:
  /// **'لم تُضف أختاماً بعد.'**
  String get brandNoSeals;

  /// No description provided for @brandNoSignatures.
  ///
  /// In ar, this message translates to:
  /// **'لم تُضف توقيعات بعد.'**
  String get brandNoSignatures;

  /// No description provided for @brandOrgNameAr.
  ///
  /// In ar, this message translates to:
  /// **'اسم المؤسسة (عربي)'**
  String get brandOrgNameAr;

  /// No description provided for @brandOrgNameEn.
  ///
  /// In ar, this message translates to:
  /// **'اسم المؤسسة (إنجليزي)'**
  String get brandOrgNameEn;

  /// No description provided for @brandHeaderText.
  ///
  /// In ar, this message translates to:
  /// **'نص الترويسة'**
  String get brandHeaderText;

  /// No description provided for @brandFooterText.
  ///
  /// In ar, this message translates to:
  /// **'نص التذييل'**
  String get brandFooterText;

  /// No description provided for @brandRegNumber.
  ///
  /// In ar, this message translates to:
  /// **'الرقم الضريبي/السجل التجاري'**
  String get brandRegNumber;

  /// No description provided for @brandPrimaryColor.
  ///
  /// In ar, this message translates to:
  /// **'اللون الأساسي'**
  String get brandPrimaryColor;

  /// No description provided for @brandSecondaryColor.
  ///
  /// In ar, this message translates to:
  /// **'اللون الثانوي'**
  String get brandSecondaryColor;

  /// No description provided for @brandAccentColor.
  ///
  /// In ar, this message translates to:
  /// **'لون التمييز'**
  String get brandAccentColor;

  /// No description provided for @brandHeaderFont.
  ///
  /// In ar, this message translates to:
  /// **'خط العناوين'**
  String get brandHeaderFont;

  /// No description provided for @brandBodyFont.
  ///
  /// In ar, this message translates to:
  /// **'خط المتن'**
  String get brandBodyFont;

  /// No description provided for @brandClear.
  ///
  /// In ar, this message translates to:
  /// **'مسح الهوية'**
  String get brandClear;

  /// No description provided for @brandClearConfirm.
  ///
  /// In ar, this message translates to:
  /// **'سيُحذف كل محتوى الهوية المحفوظ. هل تريد المتابعة؟'**
  String get brandClearConfirm;

  /// No description provided for @brandSaved.
  ///
  /// In ar, this message translates to:
  /// **'حُفظت الهوية.'**
  String get brandSaved;

  /// No description provided for @brandPresets.
  ///
  /// In ar, this message translates to:
  /// **'عناصر الهوية الجاهزة'**
  String get brandPresets;

  /// No description provided for @brandInsertHeader.
  ///
  /// In ar, this message translates to:
  /// **'إدراج الترويسة القياسية'**
  String get brandInsertHeader;

  /// No description provided for @brandInsertFooter.
  ///
  /// In ar, this message translates to:
  /// **'إدراج التذييل القياسي'**
  String get brandInsertFooter;

  /// No description provided for @brandApplyColors.
  ///
  /// In ar, this message translates to:
  /// **'تطبيق ألوان الهوية'**
  String get brandApplyColors;

  /// No description provided for @brandQuickSeals.
  ///
  /// In ar, this message translates to:
  /// **'أختام'**
  String get brandQuickSeals;

  /// No description provided for @brandQuickSignatures.
  ///
  /// In ar, this message translates to:
  /// **'توقيعات'**
  String get brandQuickSignatures;

  /// No description provided for @brandNoBrand.
  ///
  /// In ar, this message translates to:
  /// **'لم تُعدّ هويتك بعد.'**
  String get brandNoBrand;

  /// No description provided for @brandOpenSettings.
  ///
  /// In ar, this message translates to:
  /// **'فتح إعدادات الهوية'**
  String get brandOpenSettings;

  /// No description provided for @brandHeaderInserted.
  ///
  /// In ar, this message translates to:
  /// **'أُدرجت الترويسة القياسية.'**
  String get brandHeaderInserted;

  /// No description provided for @brandFooterInserted.
  ///
  /// In ar, this message translates to:
  /// **'أُدرج التذييل القياسي.'**
  String get brandFooterInserted;

  /// No description provided for @brandColorsApplied.
  ///
  /// In ar, this message translates to:
  /// **'طُبّقت ألوان الهوية.'**
  String get brandColorsApplied;

  /// No description provided for @brandSealInserted.
  ///
  /// In ar, this message translates to:
  /// **'أُدرج الختم.'**
  String get brandSealInserted;

  /// No description provided for @brandSignatureInserted.
  ///
  /// In ar, this message translates to:
  /// **'أُدرج التوقيع.'**
  String get brandSignatureInserted;

  /// No description provided for @brandFontDefault.
  ///
  /// In ar, this message translates to:
  /// **'الافتراضي'**
  String get brandFontDefault;

  /// No description provided for @paletteShapes.
  ///
  /// In ar, this message translates to:
  /// **'أشكال هندسية'**
  String get paletteShapes;

  /// No description provided for @paletteRoundedRect.
  ///
  /// In ar, this message translates to:
  /// **'مستطيل بحواف منحنية'**
  String get paletteRoundedRect;

  /// No description provided for @paletteEllipse.
  ///
  /// In ar, this message translates to:
  /// **'دائرة/بيضاوي'**
  String get paletteEllipse;

  /// No description provided for @editorFillOpacity.
  ///
  /// In ar, this message translates to:
  /// **'شفافية التعبئة'**
  String get editorFillOpacity;

  /// No description provided for @editorCollapsePanel.
  ///
  /// In ar, this message translates to:
  /// **'طيّ اللوحة الجانبية'**
  String get editorCollapsePanel;

  /// No description provided for @editorExpandPanel.
  ///
  /// In ar, this message translates to:
  /// **'إظهار اللوحة الجانبية'**
  String get editorExpandPanel;

  /// No description provided for @editorCustomSize.
  ///
  /// In ar, this message translates to:
  /// **'مقاس مخصّص'**
  String get editorCustomSize;

  /// No description provided for @editorStandardSize.
  ///
  /// In ar, this message translates to:
  /// **'مقاس قياسي'**
  String get editorStandardSize;

  /// No description provided for @editorBackgroundTitle.
  ///
  /// In ar, this message translates to:
  /// **'خلفية الورقة'**
  String get editorBackgroundTitle;

  /// No description provided for @editorGradientFrom.
  ///
  /// In ar, this message translates to:
  /// **'من'**
  String get editorGradientFrom;

  /// No description provided for @editorGradientTo.
  ///
  /// In ar, this message translates to:
  /// **'إلى'**
  String get editorGradientTo;

  /// No description provided for @editorGradientDirection.
  ///
  /// In ar, this message translates to:
  /// **'اتجاه'**
  String get editorGradientDirection;

  /// No description provided for @editorGradientNone.
  ///
  /// In ar, this message translates to:
  /// **'بلا تدرّج'**
  String get editorGradientNone;

  /// No description provided for @editorGradientVertical.
  ///
  /// In ar, this message translates to:
  /// **'رأسي'**
  String get editorGradientVertical;

  /// No description provided for @editorGradientHorizontal.
  ///
  /// In ar, this message translates to:
  /// **'أفقي'**
  String get editorGradientHorizontal;

  /// No description provided for @editorGradientDiagonal.
  ///
  /// In ar, this message translates to:
  /// **'قطري'**
  String get editorGradientDiagonal;

  /// No description provided for @editorLayersTitle.
  ///
  /// In ar, this message translates to:
  /// **'الطبقات'**
  String get editorLayersTitle;

  /// No description provided for @editorLayerShow.
  ///
  /// In ar, this message translates to:
  /// **'إظهار العنصر'**
  String get editorLayerShow;

  /// No description provided for @editorLayerHide.
  ///
  /// In ar, this message translates to:
  /// **'إخفاء العنصر'**
  String get editorLayerHide;

  /// No description provided for @editorLayerLock.
  ///
  /// In ar, this message translates to:
  /// **'قفل العنصر'**
  String get editorLayerLock;

  /// No description provided for @editorLayerUnlock.
  ///
  /// In ar, this message translates to:
  /// **'فك قفل العنصر'**
  String get editorLayerUnlock;

  /// No description provided for @editorLayersEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد عناصر على هذه الصفحة بعد.'**
  String get editorLayersEmpty;

  /// No description provided for @editorGroupSelected.
  ///
  /// In ar, this message translates to:
  /// **'تجميع المحدد'**
  String get editorGroupSelected;

  /// No description provided for @editorUngroupSelected.
  ///
  /// In ar, this message translates to:
  /// **'فك التجميع'**
  String get editorUngroupSelected;

  /// No description provided for @editorAlignLeft.
  ///
  /// In ar, this message translates to:
  /// **'محاذاة لليسار'**
  String get editorAlignLeft;

  /// No description provided for @editorAlignCenterH.
  ///
  /// In ar, this message translates to:
  /// **'توسيط أفقياً'**
  String get editorAlignCenterH;

  /// No description provided for @editorAlignRight.
  ///
  /// In ar, this message translates to:
  /// **'محاذاة لليمين'**
  String get editorAlignRight;

  /// No description provided for @editorAlignTop.
  ///
  /// In ar, this message translates to:
  /// **'محاذاة للأعلى'**
  String get editorAlignTop;

  /// No description provided for @editorAlignCenterV.
  ///
  /// In ar, this message translates to:
  /// **'توسيط رأسياً'**
  String get editorAlignCenterV;

  /// No description provided for @editorAlignBottom.
  ///
  /// In ar, this message translates to:
  /// **'محاذاة للأسفل'**
  String get editorAlignBottom;

  /// No description provided for @editorBringForward.
  ///
  /// In ar, this message translates to:
  /// **'إلى الأمام'**
  String get editorBringForward;

  /// No description provided for @editorDuplicateElement.
  ///
  /// In ar, this message translates to:
  /// **'تكرار العنصر'**
  String get editorDuplicateElement;

  /// No description provided for @editorDeleteElement.
  ///
  /// In ar, this message translates to:
  /// **'حذف العنصر'**
  String get editorDeleteElement;

  /// No description provided for @editorPageSettings.
  ///
  /// In ar, this message translates to:
  /// **'إعدادات الصفحة'**
  String get editorPageSettings;

  /// No description provided for @editorPageSize.
  ///
  /// In ar, this message translates to:
  /// **'المقاس'**
  String get editorPageSize;

  /// No description provided for @editorUnit.
  ///
  /// In ar, this message translates to:
  /// **'الوحدة'**
  String get editorUnit;

  /// No description provided for @editorWidth.
  ///
  /// In ar, this message translates to:
  /// **'العرض'**
  String get editorWidth;

  /// No description provided for @editorHeight.
  ///
  /// In ar, this message translates to:
  /// **'الارتفاع'**
  String get editorHeight;

  /// No description provided for @editorLabelText.
  ///
  /// In ar, this message translates to:
  /// **'نص'**
  String get editorLabelText;

  /// No description provided for @editorLabelShape.
  ///
  /// In ar, this message translates to:
  /// **'شكل'**
  String get editorLabelShape;

  /// No description provided for @editorLabelSeal.
  ///
  /// In ar, this message translates to:
  /// **'ختم'**
  String get editorLabelSeal;

  /// No description provided for @editorLabelDecoration.
  ///
  /// In ar, this message translates to:
  /// **'زخرفة متجهية'**
  String get editorLabelDecoration;

  /// No description provided for @editorLabelSignature.
  ///
  /// In ar, this message translates to:
  /// **'كتلة توقيعات'**
  String get editorLabelSignature;

  /// No description provided for @editorLabelImage.
  ///
  /// In ar, this message translates to:
  /// **'صورة/شعار'**
  String get editorLabelImage;

  /// No description provided for @editorLabelQr.
  ///
  /// In ar, this message translates to:
  /// **'رمز QR'**
  String get editorLabelQr;

  /// No description provided for @editorLabelUnknown.
  ///
  /// In ar, this message translates to:
  /// **'عنصر غير مدعوم'**
  String get editorLabelUnknown;

  /// No description provided for @editorLabelDynamicField.
  ///
  /// In ar, this message translates to:
  /// **'حقل ديناميكي'**
  String get editorLabelDynamicField;

  /// No description provided for @editorPositionAndSize.
  ///
  /// In ar, this message translates to:
  /// **'الموضع والحجم'**
  String get editorPositionAndSize;

  /// No description provided for @editorPosX.
  ///
  /// In ar, this message translates to:
  /// **'س'**
  String get editorPosX;

  /// No description provided for @editorPosY.
  ///
  /// In ar, this message translates to:
  /// **'ص'**
  String get editorPosY;

  /// No description provided for @editorRotation.
  ///
  /// In ar, this message translates to:
  /// **'الدوران'**
  String get editorRotation;

  /// No description provided for @editorTextFormat.
  ///
  /// In ar, this message translates to:
  /// **'تنسيق النص'**
  String get editorTextFormat;

  /// No description provided for @editorConvertToField.
  ///
  /// In ar, this message translates to:
  /// **'تحويل إلى حقل ديناميكي'**
  String get editorConvertToField;

  /// No description provided for @editorFontWeight.
  ///
  /// In ar, this message translates to:
  /// **'الوزن'**
  String get editorFontWeight;

  /// No description provided for @editorWeightRegular.
  ///
  /// In ar, this message translates to:
  /// **'عادي'**
  String get editorWeightRegular;

  /// No description provided for @editorWeightSemiBold.
  ///
  /// In ar, this message translates to:
  /// **'متوسط'**
  String get editorWeightSemiBold;

  /// No description provided for @editorWeightBold.
  ///
  /// In ar, this message translates to:
  /// **'عريض'**
  String get editorWeightBold;

  /// No description provided for @editorFontSize.
  ///
  /// In ar, this message translates to:
  /// **'حجم الخط'**
  String get editorFontSize;

  /// No description provided for @editorLetterSpacing.
  ///
  /// In ar, this message translates to:
  /// **'تباعد الحروف'**
  String get editorLetterSpacing;

  /// No description provided for @editorLineHeight.
  ///
  /// In ar, this message translates to:
  /// **'ارتفاع السطر'**
  String get editorLineHeight;

  /// No description provided for @editorTextColor.
  ///
  /// In ar, this message translates to:
  /// **'لون النص'**
  String get editorTextColor;

  /// No description provided for @editorTextBackground.
  ///
  /// In ar, this message translates to:
  /// **'خلفية النص'**
  String get editorTextBackground;

  /// No description provided for @editorTextAlign.
  ///
  /// In ar, this message translates to:
  /// **'المحاذاة'**
  String get editorTextAlign;

  /// No description provided for @editorAlignJustify.
  ///
  /// In ar, this message translates to:
  /// **'ضبط'**
  String get editorAlignJustify;

  /// No description provided for @editorJustifyMode.
  ///
  /// In ar, this message translates to:
  /// **'طريقة الضبط'**
  String get editorJustifyMode;

  /// No description provided for @editorJustifyHint.
  ///
  /// In ar, this message translates to:
  /// **'الكشيدة تُطبَّق في ملف PDF (المعاينة تُظهر ضبط الفراغات)'**
  String get editorJustifyHint;

  /// No description provided for @editorJustifySpaces.
  ///
  /// In ar, this message translates to:
  /// **'فراغات'**
  String get editorJustifySpaces;

  /// No description provided for @editorJustifyKashida.
  ///
  /// In ar, this message translates to:
  /// **'كشيدة'**
  String get editorJustifyKashida;

  /// No description provided for @editorVerticalAlign.
  ///
  /// In ar, this message translates to:
  /// **'المحاذاة الرأسية'**
  String get editorVerticalAlign;

  /// No description provided for @editorVerticalTop.
  ///
  /// In ar, this message translates to:
  /// **'أعلى'**
  String get editorVerticalTop;

  /// No description provided for @editorVerticalBottom.
  ///
  /// In ar, this message translates to:
  /// **'أسفل'**
  String get editorVerticalBottom;

  /// No description provided for @editorDirection.
  ///
  /// In ar, this message translates to:
  /// **'الاتجاه'**
  String get editorDirection;

  /// No description provided for @editorDirectionHint.
  ///
  /// In ar, this message translates to:
  /// **'اختصار التبديل: Ctrl+Shift+D'**
  String get editorDirectionHint;

  /// No description provided for @editorDirectionRtl.
  ///
  /// In ar, this message translates to:
  /// **'عربي'**
  String get editorDirectionRtl;

  /// No description provided for @editorDirectionLtr.
  ///
  /// In ar, this message translates to:
  /// **'لاتيني'**
  String get editorDirectionLtr;

  /// No description provided for @editorImage.
  ///
  /// In ar, this message translates to:
  /// **'الصورة'**
  String get editorImage;

  /// No description provided for @editorSource.
  ///
  /// In ar, this message translates to:
  /// **'المصدر'**
  String get editorSource;

  /// No description provided for @editorImageTint.
  ///
  /// In ar, this message translates to:
  /// **'تلوين الصورة'**
  String get editorImageTint;

  /// No description provided for @editorImageFit.
  ///
  /// In ar, this message translates to:
  /// **'ملاءمة الصورة'**
  String get editorImageFit;

  /// No description provided for @editorFitContain.
  ///
  /// In ar, this message translates to:
  /// **'احتواء كامل'**
  String get editorFitContain;

  /// No description provided for @editorFitCover.
  ///
  /// In ar, this message translates to:
  /// **'تغطية'**
  String get editorFitCover;

  /// No description provided for @editorFitFill.
  ///
  /// In ar, this message translates to:
  /// **'تمديد'**
  String get editorFitFill;

  /// No description provided for @assetPickerEmptyHint.
  ///
  /// In ar, this message translates to:
  /// **'لم ترفع أصولاً بعد. ارفع شعاراً أو توقيعاً أو ختماً لتستخدمه هنا وفي الطباعة.'**
  String get assetPickerEmptyHint;

  /// No description provided for @assetPickerNoneOption.
  ///
  /// In ar, this message translates to:
  /// **'بلا (مصدر آخر)'**
  String get assetPickerNoneOption;

  /// No description provided for @assetPickerTitle.
  ///
  /// In ar, this message translates to:
  /// **'اختر صورة من مكتبة أصولي'**
  String get assetPickerTitle;

  /// No description provided for @assetUploadType.
  ///
  /// In ar, this message translates to:
  /// **'رفع {type}'**
  String assetUploadType(Object type);

  /// No description provided for @editorSeal.
  ///
  /// In ar, this message translates to:
  /// **'الختم'**
  String get editorSeal;

  /// No description provided for @editorSealColor.
  ///
  /// In ar, this message translates to:
  /// **'لون الختم'**
  String get editorSealColor;

  /// No description provided for @editorSealRingColor.
  ///
  /// In ar, this message translates to:
  /// **'لون الحلقة'**
  String get editorSealRingColor;

  /// No description provided for @editorSealStarColor.
  ///
  /// In ar, this message translates to:
  /// **'لون النجمة'**
  String get editorSealStarColor;

  /// No description provided for @editorSealStarSize.
  ///
  /// In ar, this message translates to:
  /// **'حجم النجمة'**
  String get editorSealStarSize;

  /// No description provided for @editorShape.
  ///
  /// In ar, this message translates to:
  /// **'الشكل'**
  String get editorShape;

  /// No description provided for @editorFillColor.
  ///
  /// In ar, this message translates to:
  /// **'لون التعبئة'**
  String get editorFillColor;

  /// No description provided for @editorBorderColor.
  ///
  /// In ar, this message translates to:
  /// **'لون الحدود'**
  String get editorBorderColor;

  /// No description provided for @editorBorderWidth.
  ///
  /// In ar, this message translates to:
  /// **'سماكة الحدود'**
  String get editorBorderWidth;

  /// No description provided for @editorCornerRadius.
  ///
  /// In ar, this message translates to:
  /// **'استدارة الزوايا'**
  String get editorCornerRadius;

  /// No description provided for @editorQrVerify.
  ///
  /// In ar, this message translates to:
  /// **'رمز التحقق'**
  String get editorQrVerify;

  /// No description provided for @editorQrData.
  ///
  /// In ar, this message translates to:
  /// **'بيانات الرمز'**
  String get editorQrData;

  /// No description provided for @editorQrColor.
  ///
  /// In ar, this message translates to:
  /// **'لون الرمز'**
  String get editorQrColor;

  /// No description provided for @editorQrBackground.
  ///
  /// In ar, this message translates to:
  /// **'خلفية الرمز'**
  String get editorQrBackground;

  /// No description provided for @editorConvertDialogMessage.
  ///
  /// In ar, this message translates to:
  /// **'التحويل يغيّر النص «{text}» إلى علامة ديناميكية قابلة للربط في التوليد الجماعي.'**
  String editorConvertDialogMessage(Object text);

  /// No description provided for @editorFieldKeyHint.
  ///
  /// In ar, this message translates to:
  /// **'مفتاح الحقل (مثل: الاسم، التاريخ، المرجع)'**
  String get editorFieldKeyHint;

  /// No description provided for @editorCustomKeyHint.
  ///
  /// In ar, this message translates to:
  /// **'أدخل مفتاحاً مخصصاً (بدون أقواس — سيُضاف تلقائياً)'**
  String get editorCustomKeyHint;

  /// No description provided for @editorCancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get editorCancel;

  /// No description provided for @editorConvert.
  ///
  /// In ar, this message translates to:
  /// **'تحويل'**
  String get editorConvert;

  /// No description provided for @editorPath.
  ///
  /// In ar, this message translates to:
  /// **'المسار'**
  String get editorPath;

  /// No description provided for @editorTextContent.
  ///
  /// In ar, this message translates to:
  /// **'محتوى النص'**
  String get editorTextContent;

  /// No description provided for @editorInsertFieldToken.
  ///
  /// In ar, this message translates to:
  /// **'إدراج {token}'**
  String editorInsertFieldToken(Object token);

  /// No description provided for @editorAddLabel.
  ///
  /// In ar, this message translates to:
  /// **'إضافة {label}'**
  String editorAddLabel(Object label);

  /// No description provided for @assetInsertedSnack.
  ///
  /// In ar, this message translates to:
  /// **'أُدرج «{name}» في القالب.'**
  String assetInsertedSnack(Object name);

  /// No description provided for @paletteHeading.
  ///
  /// In ar, this message translates to:
  /// **'عنوان'**
  String get paletteHeading;

  /// No description provided for @paletteFrame.
  ///
  /// In ar, this message translates to:
  /// **'مستطيل/برواز'**
  String get paletteFrame;

  /// No description provided for @paletteDivider.
  ///
  /// In ar, this message translates to:
  /// **'خط فاصل'**
  String get paletteDivider;

  /// No description provided for @paletteLogo.
  ///
  /// In ar, this message translates to:
  /// **'شعار/توقيع'**
  String get paletteLogo;

  /// No description provided for @evSignatureEmptyLabel.
  ///
  /// In ar, this message translates to:
  /// **'توقيعات فارغة'**
  String get evSignatureEmptyLabel;

  /// No description provided for @evSignatureEmptyDetail.
  ///
  /// In ar, this message translates to:
  /// **'أضف دوراً واسماً وصورة توقيع'**
  String get evSignatureEmptyDetail;

  /// No description provided for @evSignatureMissingLabel.
  ///
  /// In ar, this message translates to:
  /// **'توقيع محذوف'**
  String get evSignatureMissingLabel;

  /// No description provided for @evUploadToLibraryDetail.
  ///
  /// In ar, this message translates to:
  /// **'ارفع الصورة إلى مكتبة الأصول'**
  String get evUploadToLibraryDetail;

  /// No description provided for @evImageNotFoundLabel.
  ///
  /// In ar, this message translates to:
  /// **'صورة غير موجودة'**
  String get evImageNotFoundLabel;

  /// No description provided for @evNoFileLabel.
  ///
  /// In ar, this message translates to:
  /// **'لم يُحدَّد ملف'**
  String get evNoFileLabel;

  /// No description provided for @evChooseFromAssetsDetail.
  ///
  /// In ar, this message translates to:
  /// **'اختر صورة من مكتبة الأصول'**
  String get evChooseFromAssetsDetail;

  /// No description provided for @evAssetMissingLabel.
  ///
  /// In ar, this message translates to:
  /// **'أصل محذوف'**
  String get evAssetMissingLabel;

  /// No description provided for @evReselectAssetDetail.
  ///
  /// In ar, this message translates to:
  /// **'أعد اختيار الإطار/الأصل من المكتبة'**
  String get evReselectAssetDetail;

  /// No description provided for @evInvalidImageLabel.
  ///
  /// In ar, this message translates to:
  /// **'صورة غير صالحة'**
  String get evInvalidImageLabel;

  /// No description provided for @evRenderDataFailedDetail.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر عرض البيانات'**
  String get evRenderDataFailedDetail;

  /// No description provided for @evInvalidDataLabel.
  ///
  /// In ar, this message translates to:
  /// **'بيانات غير صالحة'**
  String get evInvalidDataLabel;

  /// No description provided for @evDecodeFailedDetail.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر فك ترميز الصورة'**
  String get evDecodeFailedDetail;

  /// No description provided for @evEmptyQrLabel.
  ///
  /// In ar, this message translates to:
  /// **'رمز فارغ'**
  String get evEmptyQrLabel;

  /// No description provided for @evEmptyQrDetail.
  ///
  /// In ar, this message translates to:
  /// **'أدخل قيمة الرمز في شريط الخصائص'**
  String get evEmptyQrDetail;

  /// No description provided for @evUnknownElementLabel.
  ///
  /// In ar, this message translates to:
  /// **'عنصر غير مدعوم: {type}'**
  String evUnknownElementLabel(Object type);

  /// No description provided for @alpFilterAll.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get alpFilterAll;

  /// No description provided for @alpEmptyHint.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد أصول مرفوعة من الأنواع المطلوبة. ارفع إطاراً أو شعاراً من قسم «الأصول والتوقيعات» ثم أعد المحاولة.'**
  String get alpEmptyHint;

  /// No description provided for @alpNoFilteredAssets.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد أصول من النوع «{type}».'**
  String alpNoFilteredAssets(Object type);

  /// No description provided for @authWelcomeBack.
  ///
  /// In ar, this message translates to:
  /// **'مرحباً بك في جودكرافت.'**
  String get authWelcomeBack;

  /// No description provided for @authResetLinkSent.
  ///
  /// In ar, this message translates to:
  /// **'تم إرسال رابط الاستعادة. تحقّق من بريدك الإلكتروني.'**
  String get authResetLinkSent;

  /// No description provided for @authLogin.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول'**
  String get authLogin;

  /// No description provided for @authLoginSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'بريدك الإلكتروني وكلمة المرور للمتابعة إلى لوحة التحكم.'**
  String get authLoginSubtitle;

  /// No description provided for @authNoAccount.
  ///
  /// In ar, this message translates to:
  /// **'ليس لديك حساب؟'**
  String get authNoAccount;

  /// No description provided for @authCreateAccountLink.
  ///
  /// In ar, this message translates to:
  /// **'أنشئ حساباً جديداً'**
  String get authCreateAccountLink;

  /// No description provided for @authConfirmEmailThenLogin.
  ///
  /// In ar, this message translates to:
  /// **'تم إنشاء حسابك. يرجى تأكيد بريدك الإلكتروني أولاً ثم تسجيل الدخول.'**
  String get authConfirmEmailThenLogin;

  /// No description provided for @authEmail.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني'**
  String get authEmail;

  /// No description provided for @authPassword.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور'**
  String get authPassword;

  /// No description provided for @authForgotPassword.
  ///
  /// In ar, this message translates to:
  /// **'نسيت كلمة المرور؟'**
  String get authForgotPassword;

  /// No description provided for @authEnterDashboard.
  ///
  /// In ar, this message translates to:
  /// **'دخول إلى اللوحة'**
  String get authEnterDashboard;

  /// No description provided for @authResetPassword.
  ///
  /// In ar, this message translates to:
  /// **'استعادة كلمة المرور'**
  String get authResetPassword;

  /// No description provided for @authResetPasswordHint.
  ///
  /// In ar, this message translates to:
  /// **'أدخل بريدك الإلكتروني وسنرسل لك رابط إعادة تعيين كلمة المرور.'**
  String get authResetPasswordHint;

  /// No description provided for @authSendLink.
  ///
  /// In ar, this message translates to:
  /// **'إرسال الرابط'**
  String get authSendLink;

  /// No description provided for @authConfirmEmailMessage.
  ///
  /// In ar, this message translates to:
  /// **'تم إنشاء حسابك. تحقّق من بريدك الإلكتروني لتأكيد الحساب ثم سجّل الدخول.'**
  String get authConfirmEmailMessage;

  /// No description provided for @authAccountCreatedWelcome.
  ///
  /// In ar, this message translates to:
  /// **'تم إنشاء حسابك. أهلاً بك في جودكرافت.'**
  String get authAccountCreatedWelcome;

  /// No description provided for @authCreateAccount.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء حساب'**
  String get authCreateAccount;

  /// No description provided for @authRegisterSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'حسابك يحفظ قوالبك وأصولك (الشعار، التوقيع، الختم) لإعادة استخدامها في كل مشاريعك.'**
  String get authRegisterSubtitle;

  /// No description provided for @authHaveAccount.
  ///
  /// In ar, this message translates to:
  /// **'لديك حساب بالفعل؟'**
  String get authHaveAccount;

  /// No description provided for @authFullName.
  ///
  /// In ar, this message translates to:
  /// **'الاسم الكامل'**
  String get authFullName;

  /// No description provided for @authFullNameHint.
  ///
  /// In ar, this message translates to:
  /// **'مثال: عبدالله الأحمد'**
  String get authFullNameHint;

  /// No description provided for @authName.
  ///
  /// In ar, this message translates to:
  /// **'الاسم'**
  String get authName;

  /// No description provided for @authOrgName.
  ///
  /// In ar, this message translates to:
  /// **'اسم الجهة / المؤسسة (اختياري)'**
  String get authOrgName;

  /// No description provided for @authOrgNameHint.
  ///
  /// In ar, this message translates to:
  /// **'مثال: جمعية جود الخيرية'**
  String get authOrgNameHint;

  /// No description provided for @authOrgHelper.
  ///
  /// In ar, this message translates to:
  /// **'يُطبع على الشهادات والعقود تلقائياً.'**
  String get authOrgHelper;

  /// No description provided for @authOrgNameShort.
  ///
  /// In ar, this message translates to:
  /// **'اسم الجهة'**
  String get authOrgNameShort;

  /// No description provided for @authPasswordHint.
  ///
  /// In ar, this message translates to:
  /// **'8 أحرف على الأقل'**
  String get authPasswordHint;

  /// No description provided for @authPasswordRule.
  ///
  /// In ar, this message translates to:
  /// **'استخدم {min} أحرف أو أكثر مع أرقام ورموز.'**
  String authPasswordRule(Object min);

  /// No description provided for @authConfirmPassword.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد كلمة المرور'**
  String get authConfirmPassword;

  /// No description provided for @authCreateAccountButton.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء الحساب'**
  String get authCreateAccountButton;

  /// No description provided for @authFeatureLocalExcel.
  ///
  /// In ar, this message translates to:
  /// **'معالجة محلية كاملة لملفات Excel — بياناتك لا تغادر جهازك'**
  String get authFeatureLocalExcel;

  /// No description provided for @authFeaturePdf.
  ///
  /// In ar, this message translates to:
  /// **'توليد PDF بخطوط عربية عالية الجودة مع دعم كامل للاتجاه RTL'**
  String get authFeaturePdf;

  /// No description provided for @authFeatureTemplates.
  ///
  /// In ar, this message translates to:
  /// **'قوالبك محفوظة في حسابك وجاهزة لإعادة الاستخدام'**
  String get authFeatureTemplates;

  /// No description provided for @authTagline.
  ///
  /// In ar, this message translates to:
  /// **'شهاداتك وعقودك الرسمية… بجودة تُطبع بثقة.'**
  String get authTagline;

  /// No description provided for @authVersion.
  ///
  /// In ar, this message translates to:
  /// **'{name} • الإصدار {version}'**
  String authVersion(Object name, Object version);

  /// No description provided for @dashModules.
  ///
  /// In ar, this message translates to:
  /// **'وحدات المنصة'**
  String get dashModules;

  /// No description provided for @dashWelcome.
  ///
  /// In ar, this message translates to:
  /// **'أهلاً بك، {name}'**
  String dashWelcome(Object name);

  /// No description provided for @dashSubscription.
  ///
  /// In ar, this message translates to:
  /// **'الاشتراك: {tier}'**
  String dashSubscription(Object tier);

  /// No description provided for @dashOrg.
  ///
  /// In ar, this message translates to:
  /// **'الجهة: {name}'**
  String dashOrg(Object name);

  /// No description provided for @dashOrgMissing.
  ///
  /// In ar, this message translates to:
  /// **'لم تُسجّل اسم جهتك بعد — سيُطبع تلقائياً على الشهادات والعقود.'**
  String get dashOrgMissing;

  /// No description provided for @dashOpenModule.
  ///
  /// In ar, this message translates to:
  /// **'فتح الوحدة'**
  String get dashOpenModule;

  /// No description provided for @destDashboard.
  ///
  /// In ar, this message translates to:
  /// **'لوحة التحكم'**
  String get destDashboard;

  /// No description provided for @destDashboardDesc.
  ///
  /// In ar, this message translates to:
  /// **'نظرة عامة على مشاريعك وقوالبك.'**
  String get destDashboardDesc;

  /// No description provided for @destCertificates.
  ///
  /// In ar, this message translates to:
  /// **'محـرّك الشهادات'**
  String get destCertificates;

  /// No description provided for @destCertificatesDesc.
  ///
  /// In ar, this message translates to:
  /// **'تصميم شهادات أفقية (Landscape) من قالب قابل للتعديل.'**
  String get destCertificatesDesc;

  /// No description provided for @destContracts.
  ///
  /// In ar, this message translates to:
  /// **'محـرّك العقود'**
  String get destContracts;

  /// No description provided for @destContractsDesc.
  ///
  /// In ar, this message translates to:
  /// **'صياغة عقود رأسية (Portrait) بحقول ديناميكية.'**
  String get destContractsDesc;

  /// No description provided for @destBatch.
  ///
  /// In ar, this message translates to:
  /// **'التوليد الجماعي'**
  String get destBatch;

  /// No description provided for @destBatchDesc.
  ///
  /// In ar, this message translates to:
  /// **'قراءة ملف Excel محلياً وتوليد مئات الشهادات دفعة واحدة.'**
  String get destBatchDesc;

  /// No description provided for @destTemplates.
  ///
  /// In ar, this message translates to:
  /// **'مكتبة القوالب'**
  String get destTemplates;

  /// No description provided for @destTemplatesDesc.
  ///
  /// In ar, this message translates to:
  /// **'إدارة قوالبك المحفوظة وتصنيفها وإعادة استخدامها.'**
  String get destTemplatesDesc;

  /// No description provided for @destAssets.
  ///
  /// In ar, this message translates to:
  /// **'الأصول والتوقيعات'**
  String get destAssets;

  /// No description provided for @destAssetsDesc.
  ///
  /// In ar, this message translates to:
  /// **'الشعار والختم والتوقيع والإطارات الخاصة بك.'**
  String get destAssetsDesc;

  /// No description provided for @dashUser.
  ///
  /// In ar, this message translates to:
  /// **'مستخدم'**
  String get dashUser;

  /// No description provided for @dashLogoutSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم تسجيل الخروج بنجاح.'**
  String get dashLogoutSuccess;

  /// No description provided for @dashLogoutError.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تسجيل الخروج. حاول مرة أخرى.'**
  String get dashLogoutError;

  /// No description provided for @commonSave.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get commonSave;

  /// No description provided for @commonPreview.
  ///
  /// In ar, this message translates to:
  /// **'معاينة'**
  String get commonPreview;

  /// No description provided for @commonOptions.
  ///
  /// In ar, this message translates to:
  /// **'خيارات'**
  String get commonOptions;

  /// No description provided for @tplDelete.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get tplDelete;

  /// No description provided for @tplSortRecentlyUpdated.
  ///
  /// In ar, this message translates to:
  /// **'الأحدث تعديلاً'**
  String get tplSortRecentlyUpdated;

  /// No description provided for @tplSortTitleAsc.
  ///
  /// In ar, this message translates to:
  /// **'الاسم (أ - ي)'**
  String get tplSortTitleAsc;

  /// No description provided for @tplSortLabel.
  ///
  /// In ar, this message translates to:
  /// **'الترتيب'**
  String get tplSortLabel;

  /// No description provided for @tplSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'قوالب جاهزة احترافية + قوالبك المحفوظة — بحث وتصفية وفتح واستيراد، أوفلاين بالكامل.'**
  String get tplSubtitle;

  /// No description provided for @tplRefreshTooltip.
  ///
  /// In ar, this message translates to:
  /// **'تحديث القائمة'**
  String get tplRefreshTooltip;

  /// No description provided for @tplSearchHint.
  ///
  /// In ar, this message translates to:
  /// **'بحث في القوالب…'**
  String get tplSearchHint;

  /// No description provided for @tplNoResultsTitle.
  ///
  /// In ar, this message translates to:
  /// **'لا نتائج مطابقة'**
  String get tplNoResultsTitle;

  /// No description provided for @tplNoResultsMessage.
  ///
  /// In ar, this message translates to:
  /// **'جرّب كلمة بحث أخرى أو أعد ضبط عامل التصفية.'**
  String get tplNoResultsMessage;

  /// No description provided for @tplAddedToLocal.
  ///
  /// In ar, this message translates to:
  /// **'أُضيف «{title}» إلى قوالبك المحلية.'**
  String tplAddedToLocal(Object title);

  /// No description provided for @tplCloudRequiresConnection.
  ///
  /// In ar, this message translates to:
  /// **'حفظ القوالب في السحابة يتطلب الاتصال بمشروع Supabase. احفظه محلياً بدل ذلك.'**
  String get tplCloudRequiresConnection;

  /// No description provided for @tplSavedToCloud.
  ///
  /// In ar, this message translates to:
  /// **'حُفظ «{title}» في السحابة.'**
  String tplSavedToCloud(Object title);

  /// No description provided for @tplRenamed.
  ///
  /// In ar, this message translates to:
  /// **'أُعيد تسمية القالب.'**
  String get tplRenamed;

  /// No description provided for @tplCopySuffix.
  ///
  /// In ar, this message translates to:
  /// **'{title} (نسخة)'**
  String tplCopySuffix(Object title);

  /// No description provided for @tplCopyCreated.
  ///
  /// In ar, this message translates to:
  /// **'أُنشئت نسخة من «{title}».'**
  String tplCopyCreated(Object title);

  /// No description provided for @tplNowPrivate.
  ///
  /// In ar, this message translates to:
  /// **'القالب الآن خاص.'**
  String get tplNowPrivate;

  /// No description provided for @tplNowPublic.
  ///
  /// In ar, this message translates to:
  /// **'القالب الآن عام (قراءة فقط للآخرين).'**
  String get tplNowPublic;

  /// No description provided for @tplConfirmCloudDelete.
  ///
  /// In ar, this message translates to:
  /// **'سيُحذف «{title}» من السحابة نهائياً. لا يمكن التراجع.'**
  String tplConfirmCloudDelete(Object title);

  /// No description provided for @tplCloudDeleted.
  ///
  /// In ar, this message translates to:
  /// **'حُذف القالب «{title}».'**
  String tplCloudDeleted(Object title);

  /// No description provided for @tplConfirmLocalDelete.
  ///
  /// In ar, this message translates to:
  /// **'سيُحذف «{title}» من هذا الجهاز. القالب الجاهز الأصلي يبقى متاحاً في المكتبة.'**
  String tplConfirmLocalDelete(Object title);

  /// No description provided for @tplLocalDeleted.
  ///
  /// In ar, this message translates to:
  /// **'حُذف القالب المحلي «{title}».'**
  String tplLocalDeleted(Object title);

  /// No description provided for @tplDeleteTitle.
  ///
  /// In ar, this message translates to:
  /// **'حذف القالب'**
  String get tplDeleteTitle;

  /// No description provided for @tplRenameTitle.
  ///
  /// In ar, this message translates to:
  /// **'عنوان القالب'**
  String get tplRenameTitle;

  /// No description provided for @tplFieldTitle.
  ///
  /// In ar, this message translates to:
  /// **'العنوان'**
  String get tplFieldTitle;

  /// No description provided for @tplPreviewLabel.
  ///
  /// In ar, this message translates to:
  /// **'معاينة: {title}'**
  String tplPreviewLabel(Object title);

  /// No description provided for @tplCount.
  ///
  /// In ar, this message translates to:
  /// **'{count} قالب'**
  String tplCount(Object count);

  /// No description provided for @tplCloudLoadError.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تحميل القوالب السحابية: {message}'**
  String tplCloudLoadError(Object message);

  /// No description provided for @tplPublicBadge.
  ///
  /// In ar, this message translates to:
  /// **'قالب عام'**
  String get tplPublicBadge;

  /// No description provided for @tplOrientationLandscape.
  ///
  /// In ar, this message translates to:
  /// **'أفقي'**
  String get tplOrientationLandscape;

  /// No description provided for @tplOrientationPortrait.
  ///
  /// In ar, this message translates to:
  /// **'رأسي'**
  String get tplOrientationPortrait;

  /// No description provided for @tplPresetOffline.
  ///
  /// In ar, this message translates to:
  /// **'قالب جاهز • متاح أوفلاين'**
  String get tplPresetOffline;

  /// No description provided for @tplSchemaVersion.
  ///
  /// In ar, this message translates to:
  /// **'مخطط v{version}'**
  String tplSchemaVersion(Object version);

  /// No description provided for @tplOpenAsTemplate.
  ///
  /// In ar, this message translates to:
  /// **'فتح كقالب'**
  String get tplOpenAsTemplate;

  /// No description provided for @tplOpen.
  ///
  /// In ar, this message translates to:
  /// **'فتح'**
  String get tplOpen;

  /// No description provided for @tplUseInBatch.
  ///
  /// In ar, this message translates to:
  /// **'استخدام في التوليد الجماعي'**
  String get tplUseInBatch;

  /// No description provided for @tplImportLocal.
  ///
  /// In ar, this message translates to:
  /// **'استيراد محلياً'**
  String get tplImportLocal;

  /// No description provided for @tplSaveToCloud.
  ///
  /// In ar, this message translates to:
  /// **'حفظ في السحابة'**
  String get tplSaveToCloud;

  /// No description provided for @tplDeleteLocal.
  ///
  /// In ar, this message translates to:
  /// **'حذف محلياً'**
  String get tplDeleteLocal;

  /// No description provided for @tplRename.
  ///
  /// In ar, this message translates to:
  /// **'إعادة التسمية'**
  String get tplRename;

  /// No description provided for @tplMakePrivate.
  ///
  /// In ar, this message translates to:
  /// **'جعله خاصاً'**
  String get tplMakePrivate;

  /// No description provided for @tplMakePublic.
  ///
  /// In ar, this message translates to:
  /// **'جعله عاماً'**
  String get tplMakePublic;

  /// No description provided for @tplNoDate.
  ///
  /// In ar, this message translates to:
  /// **'بلا تاريخ'**
  String get tplNoDate;

  /// No description provided for @amSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'ارفع شعارك وختمك وتوقيعك مرة واحدة، ثم أدرجه في أي قالب — يُحفظ على جهازك ويُستعاد أوفلاين.'**
  String get amSubtitle;

  /// No description provided for @amSearchHint.
  ///
  /// In ar, this message translates to:
  /// **'بحث في الأصول…'**
  String get amSearchHint;

  /// No description provided for @amTypeLabel.
  ///
  /// In ar, this message translates to:
  /// **'النوع'**
  String get amTypeLabel;

  /// No description provided for @amUploadTooltip.
  ///
  /// In ar, this message translates to:
  /// **'رفع أصل جديد'**
  String get amUploadTooltip;

  /// No description provided for @amUpload.
  ///
  /// In ar, this message translates to:
  /// **'رفع أصل'**
  String get amUpload;

  /// No description provided for @amEmptyTitle.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد أصول بعد'**
  String get amEmptyTitle;

  /// No description provided for @amEmptyMessage.
  ///
  /// In ar, this message translates to:
  /// **'ارفع شعار مؤسستك أو توقيعك أو ختمك، ثم أدرجه في أي قالب من شريط خصائص الصورة.'**
  String get amEmptyMessage;

  /// No description provided for @amNoResultsMessage.
  ///
  /// In ar, this message translates to:
  /// **'جرّب اسماً آخر أو أعد ضبط عامل التصفية.'**
  String get amNoResultsMessage;

  /// No description provided for @amRenamed.
  ///
  /// In ar, this message translates to:
  /// **'أُعيدت تسمية الأصل.'**
  String get amRenamed;

  /// No description provided for @amMovedToType.
  ///
  /// In ar, this message translates to:
  /// **'نُقل الأصل إلى «{type}».'**
  String amMovedToType(Object type);

  /// No description provided for @amDeleteTitle.
  ///
  /// In ar, this message translates to:
  /// **'حذف الأصل'**
  String get amDeleteTitle;

  /// No description provided for @amConfirmDelete.
  ///
  /// In ar, this message translates to:
  /// **'سيُحذف «{name}» من هذا الجهاز. القوالب التي تستخدمه ستفقد الصورة (دون فشل الطباعة).'**
  String amConfirmDelete(Object name);

  /// No description provided for @amDeleted.
  ///
  /// In ar, this message translates to:
  /// **'حُذف الأصل «{name}».'**
  String amDeleted(Object name);

  /// No description provided for @amRenameTitle.
  ///
  /// In ar, this message translates to:
  /// **'إعادة تسمية الأصل'**
  String get amRenameTitle;

  /// No description provided for @amCount.
  ///
  /// In ar, this message translates to:
  /// **'{count} أصل'**
  String amCount(Object count);

  /// No description provided for @amMakeType.
  ///
  /// In ar, this message translates to:
  /// **'اجعل النوع: {type}'**
  String amMakeType(Object type);

  /// No description provided for @amCacheLabel.
  ///
  /// In ar, this message translates to:
  /// **'ذاكرة الصور على القرص'**
  String get amCacheLabel;

  /// No description provided for @amCacheUsage.
  ///
  /// In ar, this message translates to:
  /// **'{count} ملف · {size}'**
  String amCacheUsage(Object count, Object size);

  /// No description provided for @amCacheUsageOf.
  ///
  /// In ar, this message translates to:
  /// **'{count} ملف · {used} من {limit}'**
  String amCacheUsageOf(Object count, Object used, Object limit);

  /// No description provided for @amCacheEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا ذاكرة قرصية بعد'**
  String get amCacheEmpty;

  /// No description provided for @amCacheClear.
  ///
  /// In ar, this message translates to:
  /// **'مسح الذاكرة'**
  String get amCacheClear;

  /// No description provided for @amCacheCleared.
  ///
  /// In ar, this message translates to:
  /// **'تم مسح ذاكرة الصور على القرص.'**
  String get amCacheCleared;

  /// No description provided for @commonRetry.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get commonRetry;

  /// No description provided for @commonPrint.
  ///
  /// In ar, this message translates to:
  /// **'طباعة'**
  String get commonPrint;

  /// No description provided for @commonExportPdf.
  ///
  /// In ar, this message translates to:
  /// **'تصدير PDF'**
  String get commonExportPdf;

  /// No description provided for @commonExportFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تصدير ملف PDF.'**
  String get commonExportFailed;

  /// No description provided for @commonPrintFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر إرسال الملف إلى الطابعة.'**
  String get commonPrintFailed;

  /// No description provided for @commonExportReady.
  ///
  /// In ar, this message translates to:
  /// **'تم تجهيز الملف للحفظ باسم {name}.'**
  String commonExportReady(Object name);

  /// No description provided for @commonGenerating.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ التوليد…'**
  String get commonGenerating;

  /// No description provided for @commonDataPanelTitle.
  ///
  /// In ar, this message translates to:
  /// **'بيانات تجريبية'**
  String get commonDataPanelTitle;

  /// No description provided for @evElementCount.
  ///
  /// In ar, this message translates to:
  /// **'{count} عنصراً'**
  String evElementCount(Object count);

  /// No description provided for @evStatusDynamicFields.
  ///
  /// In ar, this message translates to:
  /// **' • حقول ديناميكية'**
  String get evStatusDynamicFields;

  /// No description provided for @evStatusUnsaved.
  ///
  /// In ar, this message translates to:
  /// **' • تعديلات غير محفوظة'**
  String get evStatusUnsaved;

  /// No description provided for @tevNewTemplateTitle.
  ///
  /// In ar, this message translates to:
  /// **'قالب جديد'**
  String get tevNewTemplateTitle;

  /// No description provided for @tevUnsavedTitle.
  ///
  /// In ar, this message translates to:
  /// **'تعديلات غير محفوظة'**
  String get tevUnsavedTitle;

  /// No description provided for @tevUnsavedMessage.
  ///
  /// In ar, this message translates to:
  /// **'لديك تعديلات على «{title}» لم تُحفَظ بعد. هل تريد حفظها قبل المغادرة؟'**
  String tevUnsavedMessage(Object title);

  /// No description provided for @tevLeaveWithoutSaving.
  ///
  /// In ar, this message translates to:
  /// **'المغادرة دون حفظ'**
  String get tevLeaveWithoutSaving;

  /// No description provided for @tevSaveAndLeave.
  ///
  /// In ar, this message translates to:
  /// **'حفظ والمغادرة'**
  String get tevSaveAndLeave;

  /// No description provided for @tevViewMode.
  ///
  /// In ar, this message translates to:
  /// **'طريقة العرض'**
  String get tevViewMode;

  /// No description provided for @tevModeEditor.
  ///
  /// In ar, this message translates to:
  /// **'المحرر'**
  String get tevModeEditor;

  /// No description provided for @tevModePreview.
  ///
  /// In ar, this message translates to:
  /// **'معاينة PDF'**
  String get tevModePreview;

  /// No description provided for @tevPaperDirection.
  ///
  /// In ar, this message translates to:
  /// **'اتجاه الورقة'**
  String get tevPaperDirection;

  /// No description provided for @tevWidthCm.
  ///
  /// In ar, this message translates to:
  /// **'العرض (cm)'**
  String get tevWidthCm;

  /// No description provided for @tevHeightCm.
  ///
  /// In ar, this message translates to:
  /// **'الارتفاع (cm)'**
  String get tevHeightCm;

  /// No description provided for @tevUndo.
  ///
  /// In ar, this message translates to:
  /// **'تراجع (Ctrl+Z)'**
  String get tevUndo;

  /// No description provided for @tevRedo.
  ///
  /// In ar, this message translates to:
  /// **'إعادة (Ctrl+Y)'**
  String get tevRedo;

  /// No description provided for @tevSnapGrid.
  ///
  /// In ar, this message translates to:
  /// **'شبكة التوجيه'**
  String get tevSnapGrid;

  /// No description provided for @tevGuidesOn.
  ///
  /// In ar, this message translates to:
  /// **'خطوط الإرشاد الذكية: مُفعّلة (إيقاف)'**
  String get tevGuidesOn;

  /// No description provided for @tevGuidesOff.
  ///
  /// In ar, this message translates to:
  /// **'خطوط الإرشاد الذكية: معطّلة (تشغيل)'**
  String get tevGuidesOff;

  /// No description provided for @tevZoom.
  ///
  /// In ar, this message translates to:
  /// **'التكبير'**
  String get tevZoom;

  /// No description provided for @tevDocumentBackground.
  ///
  /// In ar, this message translates to:
  /// **'خلفية المستند'**
  String get tevDocumentBackground;

  /// No description provided for @tevFrameFromLibrary.
  ///
  /// In ar, this message translates to:
  /// **'إطار من مكتبة أصولي'**
  String get tevFrameFromLibrary;

  /// No description provided for @tevChangeTitle.
  ///
  /// In ar, this message translates to:
  /// **'تغيير عنوان القالب'**
  String get tevChangeTitle;

  /// No description provided for @tevMyTemplates.
  ///
  /// In ar, this message translates to:
  /// **'قوالبي'**
  String get tevMyTemplates;

  /// No description provided for @tevSaveAs.
  ///
  /// In ar, this message translates to:
  /// **'حفظ باسم'**
  String get tevSaveAs;

  /// No description provided for @tevSaveTemplate.
  ///
  /// In ar, this message translates to:
  /// **'حفظ القالب'**
  String get tevSaveTemplate;

  /// No description provided for @tevSaveUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'الحفظ غير متاح'**
  String get tevSaveUnavailable;

  /// No description provided for @tevSaveNeedsSupabase.
  ///
  /// In ar, this message translates to:
  /// **'الحفظ المحلي غير متاح في هذه الجلسة — تعذّر فتح مخزن المشاريع على هذا الجهاز.'**
  String get tevSaveNeedsSupabase;

  /// No description provided for @tevMissingAssets.
  ///
  /// In ar, this message translates to:
  /// **'أصول مفقودة: {list} — أعد اختيار الإطار/الأصل من «مكتبة أصولي» لتفادي ظهورها فارغة.'**
  String tevMissingAssets(Object list);

  /// No description provided for @tevTemplateLibraryNeedsSupabase.
  ///
  /// In ar, this message translates to:
  /// **'مكتبة المشاريع المحلية غير متاحة في هذه الجلسة.'**
  String get tevTemplateLibraryNeedsSupabase;

  /// No description provided for @tevOpenedTemplate.
  ///
  /// In ar, this message translates to:
  /// **'تم فتح «{title}».'**
  String tevOpenedTemplate(Object title);

  /// No description provided for @tevTitleHint.
  ///
  /// In ar, this message translates to:
  /// **'مثال: شهادة إتمام دورة إدارة المشاريع'**
  String get tevTitleHint;

  /// No description provided for @tevContinue.
  ///
  /// In ar, this message translates to:
  /// **'متابعة'**
  String get tevContinue;

  /// No description provided for @tevSavedTemplates.
  ///
  /// In ar, this message translates to:
  /// **'قوالبي المحفوظة'**
  String get tevSavedTemplates;

  /// No description provided for @tevNoSavedTemplates.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد قوالب محفوظة بعد. احفظ قالباً من الزر «حفظ القالب».'**
  String get tevNoSavedTemplates;

  /// No description provided for @ecIncrease.
  ///
  /// In ar, this message translates to:
  /// **'زيادة'**
  String get ecIncrease;

  /// No description provided for @ecDecrease.
  ///
  /// In ar, this message translates to:
  /// **'إنقاص'**
  String get ecDecrease;

  /// No description provided for @ecQuickPalette.
  ///
  /// In ar, this message translates to:
  /// **'لوحة سريعة'**
  String get ecQuickPalette;

  /// No description provided for @ecFullPicker.
  ///
  /// In ar, this message translates to:
  /// **'منتقي ألوان كامل'**
  String get ecFullPicker;

  /// No description provided for @ecRemoveColor.
  ///
  /// In ar, this message translates to:
  /// **'إزالة اللون'**
  String get ecRemoveColor;

  /// No description provided for @ecNone.
  ///
  /// In ar, this message translates to:
  /// **'بلا'**
  String get ecNone;

  /// No description provided for @ecPickColorTitle.
  ///
  /// In ar, this message translates to:
  /// **'اختيار لون'**
  String get ecPickColorTitle;

  /// No description provided for @ecApply.
  ///
  /// In ar, this message translates to:
  /// **'تطبيق'**
  String get ecApply;

  /// No description provided for @tevBackgroundAdded.
  ///
  /// In ar, this message translates to:
  /// **'أُضيف «{name}» كخلفية للمستند.'**
  String tevBackgroundAdded(Object name);

  /// No description provided for @cfpUploadTooltip.
  ///
  /// In ar, this message translates to:
  /// **'رفع خط مخصص (.ttf / .otf)'**
  String get cfpUploadTooltip;

  /// No description provided for @cfpManageTooltip.
  ///
  /// In ar, this message translates to:
  /// **'إدارة الخطوط المرفوعة'**
  String get cfpManageTooltip;

  /// No description provided for @cfpNotice.
  ///
  /// In ar, this message translates to:
  /// **'الخطوط المرفوعة تُحفظ على جهازك فقط وتُستخدم فوراً هنا وفي الطباعة — بلا إنترنت.'**
  String get cfpNotice;

  /// No description provided for @cfpMyFonts.
  ///
  /// In ar, this message translates to:
  /// **'خطوطي المخصصة'**
  String get cfpMyFonts;

  /// No description provided for @cfpNoFonts.
  ///
  /// In ar, this message translates to:
  /// **'لم ترفع خطوطاً بعد'**
  String get cfpNoFonts;

  /// No description provided for @cfpBuiltinOption.
  ///
  /// In ar, this message translates to:
  /// **'بلا (الخط المضمّن)'**
  String get cfpBuiltinOption;

  /// No description provided for @cfpGroupBuiltin.
  ///
  /// In ar, this message translates to:
  /// **'الخطوط المضمّنة'**
  String get cfpGroupBuiltin;

  /// No description provided for @cfpGroupUploaded.
  ///
  /// In ar, this message translates to:
  /// **'خطوطي المرفوعة'**
  String get cfpGroupUploaded;

  /// No description provided for @cfpGroupSystem.
  ///
  /// In ar, this message translates to:
  /// **'خطوط النظام'**
  String get cfpGroupSystem;

  /// No description provided for @cfpSearchHint.
  ///
  /// In ar, this message translates to:
  /// **'ابحث في الخطوط…'**
  String get cfpSearchHint;

  /// No description provided for @cfpNoMatch.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد خطوط مطابقة.'**
  String get cfpNoMatch;

  /// No description provided for @cfpPickTitle.
  ///
  /// In ar, this message translates to:
  /// **'اختر ملف خط (TTF أو OTF)'**
  String get cfpPickTitle;

  /// No description provided for @cfpPickerError.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر فتح منتقي الملفات: {error}'**
  String cfpPickerError(Object error);

  /// No description provided for @cfpReadError.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر قراءة \"{name}\": {error}'**
  String cfpReadError(Object name, Object error);

  /// No description provided for @cfpFontAdded.
  ///
  /// In ar, this message translates to:
  /// **'أُضيف الخط واستُخدم فوراً.'**
  String get cfpFontAdded;

  /// No description provided for @cfpFontsAdded.
  ///
  /// In ar, this message translates to:
  /// **'أُضيف {count} خطوط.'**
  String cfpFontsAdded(Object count);

  /// No description provided for @cfpLibraryTitle.
  ///
  /// In ar, this message translates to:
  /// **'مكتبة خطوطي المخصصة'**
  String get cfpLibraryTitle;

  /// No description provided for @cfpLibraryNotice.
  ///
  /// In ar, this message translates to:
  /// **'كل الخطوط محفوظة على جهازك فقط. تحذير: حذف خط يستخدمه قالب يُرجع ذلك القالب إلى الخط المضمّن بدل الفشل.'**
  String get cfpLibraryNotice;

  /// No description provided for @cfpEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد خطوط مرفوعة بعد.'**
  String get cfpEmpty;

  /// No description provided for @cfpCoverageFull.
  ///
  /// In ar, this message translates to:
  /// **'تغطية عربية كاملة'**
  String get cfpCoverageFull;

  /// No description provided for @cfpCoveragePartial.
  ///
  /// In ar, this message translates to:
  /// **'تغطية عربية ناقصة'**
  String get cfpCoveragePartial;

  /// No description provided for @cfpUploadNew.
  ///
  /// In ar, this message translates to:
  /// **'رفع خط جديد'**
  String get cfpUploadNew;

  /// No description provided for @ptpPrepError.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تحضير المعاينة. تحقّق من ملف القالب.'**
  String get ptpPrepError;

  /// No description provided for @ptpElapsedSize.
  ///
  /// In ar, this message translates to:
  /// **'{ms} م.ث — {kb} ك.ب'**
  String ptpElapsedSize(Object ms, Object kb);

  /// No description provided for @ptpGeneratingNote.
  ///
  /// In ar, this message translates to:
  /// **'— تُحدَّث المعاينة تلقائياً'**
  String get ptpGeneratingNote;

  /// No description provided for @ptpGenerateFailedTitle.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر توليد المعاينة'**
  String get ptpGenerateFailedTitle;

  /// No description provided for @ptpPreparingTitle.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ تحضير المحرك…'**
  String get ptpPreparingTitle;

  /// No description provided for @ptpPreparingMessage.
  ///
  /// In ar, this message translates to:
  /// **'يتم تحميل الخطوط المحزومة وتوليد أول نسخة من الملف.'**
  String get ptpPreparingMessage;

  /// No description provided for @ptpShowFailedTitle.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر عرض المعاينة'**
  String get ptpShowFailedTitle;

  /// No description provided for @cfgOverride.
  ///
  /// In ar, this message translates to:
  /// **'بديل لبناء بقيم محددة يتفوق على الملف: {override}'**
  String cfgOverride(Object override);

  /// No description provided for @tevBackgroundTitle.
  ///
  /// In ar, this message translates to:
  /// **'خلفية المستند من مكتبة أصولي'**
  String get tevBackgroundTitle;

  /// No description provided for @tevAddElement.
  ///
  /// In ar, this message translates to:
  /// **'إضافة عنصر'**
  String get tevAddElement;

  /// No description provided for @commonUndo.
  ///
  /// In ar, this message translates to:
  /// **'تراجع'**
  String get commonUndo;

  /// No description provided for @bpTitle.
  ///
  /// In ar, this message translates to:
  /// **'التوليد الجماعي من Excel'**
  String get bpTitle;

  /// No description provided for @bpSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'استورد ملف .xlsx أو .csv، اربط أعمدته بحقول القالب، ثم ولّد ملف PDF بصفحة لكل سجل — كل ذلك على جهازك بلا إنترنت.'**
  String get bpSubtitle;

  /// No description provided for @bpStepTemplate.
  ///
  /// In ar, this message translates to:
  /// **'1) القالب'**
  String get bpStepTemplate;

  /// No description provided for @bpLoadingSampleTemplate.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ تحميل القالب النموذجي…'**
  String get bpLoadingSampleTemplate;

  /// No description provided for @bpTemplateInfo.
  ///
  /// In ar, this message translates to:
  /// **'القالب: {name} • الحقول المطلوبة:'**
  String bpTemplateInfo(Object name);

  /// No description provided for @bpLoadingTemplates.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ تحميل قوالبك…'**
  String get bpLoadingTemplates;

  /// No description provided for @bpNoTemplates.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد قوالب محفوظة بعد — أنشئ قالباً في المحرّر أو استورده من مكتبة القوالب ليظهر هنا.'**
  String get bpNoTemplates;

  /// No description provided for @bpTemplateFromMine.
  ///
  /// In ar, this message translates to:
  /// **'قالب من قوالبي'**
  String get bpTemplateFromMine;

  /// No description provided for @bpSampleTemplatesHeader.
  ///
  /// In ar, this message translates to:
  /// **'— القوالب النموذجية —'**
  String get bpSampleTemplatesHeader;

  /// No description provided for @bpTemplateEntry.
  ///
  /// In ar, this message translates to:
  /// **'{title}  •  {source}'**
  String bpTemplateEntry(Object title, Object source);

  /// No description provided for @bpSourceCloud.
  ///
  /// In ar, this message translates to:
  /// **'سحابي'**
  String get bpSourceCloud;

  /// No description provided for @bpSourceLocal.
  ///
  /// In ar, this message translates to:
  /// **'محلي'**
  String get bpSourceLocal;

  /// No description provided for @bpStepDataFile.
  ///
  /// In ar, this message translates to:
  /// **'2) ملف البيانات'**
  String get bpStepDataFile;

  /// No description provided for @bpReadingFile.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ قراءة الملف…'**
  String get bpReadingFile;

  /// No description provided for @bpNoFileChosen.
  ///
  /// In ar, this message translates to:
  /// **'لم يُختَر ملف بعد — الصيغ المدعومة:'**
  String get bpNoFileChosen;

  /// No description provided for @bpFileSummary.
  ///
  /// In ar, this message translates to:
  /// **'{name} — {rows} صفاً، {cols} عموداً'**
  String bpFileSummary(Object name, Object rows, Object cols);

  /// No description provided for @bpSheetSuffix.
  ///
  /// In ar, this message translates to:
  /// **' (ورقة: {name})'**
  String bpSheetSuffix(Object name);

  /// No description provided for @bpChooseFile.
  ///
  /// In ar, this message translates to:
  /// **'اختيار ملف'**
  String get bpChooseFile;

  /// No description provided for @bpRemove.
  ///
  /// In ar, this message translates to:
  /// **'إزالة'**
  String get bpRemove;

  /// No description provided for @bpHeaderRow.
  ///
  /// In ar, this message translates to:
  /// **'صف العناوين'**
  String get bpHeaderRow;

  /// No description provided for @bpAutoRow.
  ///
  /// In ar, this message translates to:
  /// **'تلقائي (الصف {n})'**
  String bpAutoRow(Object n);

  /// No description provided for @bpRow.
  ///
  /// In ar, this message translates to:
  /// **'الصف {n}'**
  String bpRow(Object n);

  /// No description provided for @bpAutoRowLong.
  ///
  /// In ar, this message translates to:
  /// **'تلقائي — الصف {n}'**
  String bpAutoRowLong(Object n);

  /// No description provided for @bpRowPreview.
  ///
  /// In ar, this message translates to:
  /// **'الصف {n}: {preview}'**
  String bpRowPreview(Object n, Object preview);

  /// No description provided for @bpEmptyRow.
  ///
  /// In ar, this message translates to:
  /// **'(صف فارغ)'**
  String get bpEmptyRow;

  /// No description provided for @bpWorksheet.
  ///
  /// In ar, this message translates to:
  /// **'ورقة العمل'**
  String get bpWorksheet;

  /// No description provided for @bpPickDataFile.
  ///
  /// In ar, this message translates to:
  /// **'اختر ملف البيانات (Excel أو CSV)'**
  String get bpPickDataFile;

  /// No description provided for @bpReadFileError.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر قراءة الملف: {error}'**
  String bpReadFileError(Object error);

  /// No description provided for @bpFileReadRows.
  ///
  /// In ar, this message translates to:
  /// **'قُرئ الملف محلياً: {rows} صفاً و{cols} عموداً.'**
  String bpFileReadRows(Object rows, Object cols);

  /// No description provided for @bpSaveError.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر حفظ التعديل في القالب: {error}'**
  String bpSaveError(Object error);

  /// No description provided for @bpMapFieldTitle.
  ///
  /// In ar, this message translates to:
  /// **'تعيين حقل ديناميكي لهذا العنصر'**
  String get bpMapFieldTitle;

  /// No description provided for @bpMapFieldBody.
  ///
  /// In ar, this message translates to:
  /// **'سيُستبدل نص هذا العنصر وحده بحقل، ولن يُمسّ أي عنصر آخر.'**
  String get bpMapFieldBody;

  /// No description provided for @bpUndoConvert.
  ///
  /// In ar, this message translates to:
  /// **'تم التراجع عن التحويل.'**
  String get bpUndoConvert;

  /// No description provided for @bpUndoConvertSaved.
  ///
  /// In ar, this message translates to:
  /// **'تم التراجع عن التحويل واستعادة النص في القالب.'**
  String get bpUndoConvertSaved;

  /// No description provided for @bpRestoreError.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر استعادة النص في القالب: {error}'**
  String bpRestoreError(Object error);

  /// No description provided for @bpGeneratedReport.
  ///
  /// In ar, this message translates to:
  /// **'تم توليد {count} سجل'**
  String bpGeneratedReport(Object count);

  /// No description provided for @bpSkippedSuffix.
  ///
  /// In ar, this message translates to:
  /// **' وتخطّي {count}'**
  String bpSkippedSuffix(Object count);

  /// No description provided for @bpReadyToSave.
  ///
  /// In ar, this message translates to:
  /// **'تم تجهيز الملف للحفظ.'**
  String get bpReadyToSave;

  /// No description provided for @bpStepMapping.
  ///
  /// In ar, this message translates to:
  /// **'3) ربط الأعمدة بالحقول'**
  String get bpStepMapping;

  /// No description provided for @bpChooseFileFirst.
  ///
  /// In ar, this message translates to:
  /// **'اختر ملفاً أولاً ليظهر جدول الربط.'**
  String get bpChooseFileFirst;

  /// No description provided for @bpNoDynamicFields.
  ///
  /// In ar, this message translates to:
  /// **'لا حقول ديناميكية في القالب الحالي.'**
  String get bpNoDynamicFields;

  /// No description provided for @bpMappedCount.
  ///
  /// In ar, this message translates to:
  /// **'مرتبط {mapped} من {total} عموداً'**
  String bpMappedCount(Object mapped, Object total);

  /// No description provided for @bpAutoMapHint.
  ///
  /// In ar, this message translates to:
  /// **'بعد اختيار الملف سيُقترح ربط تلقائي ذكي، ويمكنك تعديل كل عمود.'**
  String get bpAutoMapHint;

  /// No description provided for @bpNoFieldsHelp.
  ///
  /// In ar, this message translates to:
  /// **'القالب المختار لا يحتوي حقولاً ديناميكية، فلا شيء ليُربط بأعمدة الملف. افتح القالب في المحرّر وأدرج «حقل ديناميكي» في خانة الاسم ثم احفظ القالب ثم أعد المحاولة.'**
  String get bpNoFieldsHelp;

  /// No description provided for @bpAutoMap.
  ///
  /// In ar, this message translates to:
  /// **'ربط تلقائي'**
  String get bpAutoMap;

  /// No description provided for @bpClearMapping.
  ///
  /// In ar, this message translates to:
  /// **'مسح الربط'**
  String get bpClearMapping;

  /// No description provided for @bpNameFieldWarning.
  ///
  /// In ar, this message translates to:
  /// **'هذا القالب لا يحتوي على حقل اسم ديناميكي — لا تربط عمود الاسم بحقل تاريخ أو رقم إشعار، فقد يُطبع الاسم في مكانه الخطأ. اختر مفتاح الاسم من قائمة العمود، أو حوّل نص الاسم الثابت من المحرّر إلى حقل ديناميكي.'**
  String get bpNameFieldWarning;

  /// No description provided for @bpStaticNameHints.
  ///
  /// In ar, this message translates to:
  /// **'نصّ ثابت يشبه الاسم: «{preview}» — لا يستبدله أي حقل ديناميكي.'**
  String bpStaticNameHints(Object preview);

  /// No description provided for @bpConvertToNameField.
  ///
  /// In ar, this message translates to:
  /// **'حوّله إلى حقل اسم المتدرب'**
  String get bpConvertToNameField;

  /// No description provided for @bpDuplicateField.
  ///
  /// In ar, this message translates to:
  /// **'الحقل «{field}» مرتبط بأكثر من عمود. اجعل كل حقل بعمود واحد.'**
  String bpDuplicateField(Object field);

  /// No description provided for @bpUnmappedColumns.
  ///
  /// In ar, this message translates to:
  /// **'{count} عموداً بلا ربط — لن تُستخدم بياناته في الشهادات.'**
  String bpUnmappedColumns(Object count);

  /// No description provided for @bpColumn.
  ///
  /// In ar, this message translates to:
  /// **'عمود {n}'**
  String bpColumn(Object n);

  /// No description provided for @bpEmptyCell.
  ///
  /// In ar, this message translates to:
  /// **'(فارغ)'**
  String get bpEmptyCell;

  /// No description provided for @bpUnmapped.
  ///
  /// In ar, this message translates to:
  /// **'— غير مربوط —'**
  String get bpUnmapped;

  /// No description provided for @bpStepMissing.
  ///
  /// In ar, this message translates to:
  /// **'4) الخلايا الفارغة والبيانات الناقصة'**
  String get bpStepMissing;

  /// No description provided for @bpNoNotes.
  ///
  /// In ar, this message translates to:
  /// **'لا ملاحظات قبل اختيار الملف.'**
  String get bpNoNotes;

  /// No description provided for @bpStepGenerate.
  ///
  /// In ar, this message translates to:
  /// **'5) التوليد'**
  String get bpStepGenerate;

  /// No description provided for @bpGenerating.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ التوليد… {progress}'**
  String bpGenerating(Object progress);

  /// No description provided for @bpGenerateHint.
  ///
  /// In ar, this message translates to:
  /// **'ملف PDF واحد، صفحة لكل سجل مُصدر.'**
  String get bpGenerateHint;

  /// No description provided for @bpGeneratePickFile.
  ///
  /// In ar, this message translates to:
  /// **'اختر ملف بيانات أولاً ليُفعَّل التوليد.'**
  String get bpGeneratePickFile;

  /// No description provided for @bpMappingInvalid.
  ///
  /// In ar, this message translates to:
  /// **'الربط غير صالح — لا تُربط الحقل نفسه بعمودين.'**
  String get bpMappingInvalid;

  /// No description provided for @bpMapAtLeastOne.
  ///
  /// In ar, this message translates to:
  /// **'اربط عموداً واحداً على الأقل بحقل من القالب ليُفعَّل التوليد.'**
  String get bpMapAtLeastOne;

  /// No description provided for @bpGenerateCertificates.
  ///
  /// In ar, this message translates to:
  /// **'توليد الشهادات'**
  String get bpGenerateCertificates;

  /// No description provided for @bpRegenerate.
  ///
  /// In ar, this message translates to:
  /// **'إعادة التوليد'**
  String get bpRegenerate;

  /// No description provided for @bpStatGenerated.
  ///
  /// In ar, this message translates to:
  /// **'مُصدرة'**
  String get bpStatGenerated;

  /// No description provided for @bpStatSkipped.
  ///
  /// In ar, this message translates to:
  /// **'متخطّاة'**
  String get bpStatSkipped;

  /// No description provided for @bpStatPages.
  ///
  /// In ar, this message translates to:
  /// **'صفحات'**
  String get bpStatPages;

  /// No description provided for @bpStatSize.
  ///
  /// In ar, this message translates to:
  /// **'الحجم'**
  String get bpStatSize;

  /// No description provided for @bpKilobytes.
  ///
  /// In ar, this message translates to:
  /// **'{value} ك.ب'**
  String bpKilobytes(Object value);

  /// No description provided for @bpStatTime.
  ///
  /// In ar, this message translates to:
  /// **'الزمن'**
  String get bpStatTime;

  /// No description provided for @bpMilliseconds.
  ///
  /// In ar, this message translates to:
  /// **'{value} م.ث'**
  String bpMilliseconds(Object value);

  /// No description provided for @bpCompletion.
  ///
  /// In ar, this message translates to:
  /// **'اكتمال {pct}% من {total} صفاً.'**
  String bpCompletion(Object pct, Object total);

  /// No description provided for @bpSkippedRows.
  ///
  /// In ar, this message translates to:
  /// **'صفوف لم تُصدر:'**
  String get bpSkippedRows;

  /// No description provided for @bpRowSkipReason.
  ///
  /// In ar, this message translates to:
  /// **'صف {n}: {reason}'**
  String bpRowSkipReason(Object n, Object reason);

  /// No description provided for @bpPreviewHere.
  ///
  /// In ar, this message translates to:
  /// **'المعاينة تظهر هنا'**
  String get bpPreviewHere;

  /// No description provided for @bpPreviewHint.
  ///
  /// In ar, this message translates to:
  /// **'اختر ملف البيانات، اضبط الربط، ثم اضغط «توليد الشهادات» — سترى أول صفحة من الملف الناتج هنا مباشرة.'**
  String get bpPreviewHint;

  /// No description provided for @bpAssignByTapTitle.
  ///
  /// In ar, this message translates to:
  /// **'تعيين الحقول بالنقر'**
  String get bpAssignByTapTitle;

  /// No description provided for @bpAssignByTapBody.
  ///
  /// In ar, this message translates to:
  /// **'انقر أي نص في القالب لتعيينه إلى حقل ديناميكي بنفسك. لن يُمسّ أي عنصر آخر — لا التاريخ ولا اسم المدير ولا أي نص ثابت.'**
  String get bpAssignByTapBody;

  /// No description provided for @bpNoTexts.
  ///
  /// In ar, this message translates to:
  /// **'لا نصوص في هذا القالب.'**
  String get bpNoTexts;

  /// No description provided for @bpEmptyText.
  ///
  /// In ar, this message translates to:
  /// **'(نص فارغ)'**
  String get bpEmptyText;

  /// No description provided for @bpDynamicFieldTap.
  ///
  /// In ar, this message translates to:
  /// **'حقل ديناميكي — انقر لتغييره'**
  String get bpDynamicFieldTap;

  /// No description provided for @bpStaticTextTap.
  ///
  /// In ar, this message translates to:
  /// **'نص ثابت — انقر للتعيين'**
  String get bpStaticTextTap;

  /// No description provided for @bpAssignField.
  ///
  /// In ar, this message translates to:
  /// **'تعيين حقل'**
  String get bpAssignField;

  /// No description provided for @bpKindCertificate.
  ///
  /// In ar, this message translates to:
  /// **'شهادة'**
  String get bpKindCertificate;

  /// No description provided for @bpKindContract.
  ///
  /// In ar, this message translates to:
  /// **'عقد'**
  String get bpKindContract;

  /// No description provided for @bpLoadSampleError.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تحميل القالب النموذجي: {error}'**
  String bpLoadSampleError(Object error);

  /// No description provided for @bpReadSheetError.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر قراءة الورقة: {error}'**
  String bpReadSheetError(Object error);

  /// No description provided for @bpUpdateHeaderRowError.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تحديث صف العناوين: {error}'**
  String bpUpdateHeaderRowError(Object error);

  /// No description provided for @bpChooseTemplateFirst.
  ///
  /// In ar, this message translates to:
  /// **'اختر قالباً (شهادة أو عقد) قبل التوليد.'**
  String get bpChooseTemplateFirst;

  /// No description provided for @bpBatchTitle.
  ///
  /// In ar, this message translates to:
  /// **'{kind} جماعية — JoodCraft'**
  String bpBatchTitle(Object kind);

  /// No description provided for @bpGenerateError.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر التوليد الجماعي: {error}'**
  String bpGenerateError(Object error);

  /// No description provided for @bpWarnNoDynamicFields.
  ///
  /// In ar, this message translates to:
  /// **'هذا القالب بلا حقول ديناميكية — لن تتغيّر البيانات بين السجلات. أضف حقل «اسم المتدرب» من شريط المحرّر ثم احفظ القالب.'**
  String get bpWarnNoDynamicFields;

  /// No description provided for @bpWarnNoNameField.
  ///
  /// In ar, this message translates to:
  /// **'هذا القالب لا يحتوي على حقل اسم ديناميكي — قد يربط عمود الاسم بحقل تاريخ أو رقم إشعار فيظهر الاسم في مكانه الخطأ. حوّل نص الاسم الثابت إلى حقل أو أعد تصميم القالب.'**
  String get bpWarnNoNameField;

  /// No description provided for @bpAssignedTemp.
  ///
  /// In ar, this message translates to:
  /// **'عُيّن هذا العنصر إلى {token} للتوليد الحالي — بقية العناصر لم تُمسّ. احفظ القالب لتثبيت التعديل دائماً.'**
  String bpAssignedTemp(Object token);

  /// No description provided for @bpAssignedSaved.
  ///
  /// In ar, this message translates to:
  /// **'عُيّن هذا العنصر إلى {token} وحُفظ التعديل في القالب. بقية العناصر لم تُمسّ.'**
  String bpAssignedSaved(Object token);

  /// No description provided for @commonShow.
  ///
  /// In ar, this message translates to:
  /// **'إظهار'**
  String get commonShow;

  /// No description provided for @commonHide.
  ///
  /// In ar, this message translates to:
  /// **'إخفاء'**
  String get commonHide;

  /// No description provided for @themeSwitchToLight.
  ///
  /// In ar, this message translates to:
  /// **'التبديل إلى المظهر الفاتح'**
  String get themeSwitchToLight;

  /// No description provided for @themeSwitchToDark.
  ///
  /// In ar, this message translates to:
  /// **'التبديل إلى المظهر الداكن'**
  String get themeSwitchToDark;

  /// No description provided for @commonComingSoonPhase.
  ///
  /// In ar, this message translates to:
  /// **'قيد التنفيذ — المرحلة {phase}'**
  String commonComingSoonPhase(Object phase);

  /// No description provided for @cbNewCertificateTitle.
  ///
  /// In ar, this message translates to:
  /// **'شهادة جديدة'**
  String get cbNewCertificateTitle;

  /// No description provided for @cbNewContractTitle.
  ///
  /// In ar, this message translates to:
  /// **'عقد جديد'**
  String get cbNewContractTitle;

  /// No description provided for @cbBeneficiaryDataTitle.
  ///
  /// In ar, this message translates to:
  /// **'بيانات المستفيد (تجريبية)'**
  String get cbBeneficiaryDataTitle;

  /// No description provided for @cbContractDataTitle.
  ///
  /// In ar, this message translates to:
  /// **'بيانات العقد (تجريبية)'**
  String get cbContractDataTitle;

  /// No description provided for @editorSendBackward.
  ///
  /// In ar, this message translates to:
  /// **'إلى الخلف خطوة'**
  String get editorSendBackward;

  /// No description provided for @editorRotateLeft.
  ///
  /// In ar, this message translates to:
  /// **'تدوير ٩٠° يساراً'**
  String get editorRotateLeft;

  /// No description provided for @editorRotateRight.
  ///
  /// In ar, this message translates to:
  /// **'تدوير ٩٠° يميناً'**
  String get editorRotateRight;

  /// No description provided for @editorFlipH.
  ///
  /// In ar, this message translates to:
  /// **'قلب أفقي'**
  String get editorFlipH;

  /// No description provided for @editorFlipV.
  ///
  /// In ar, this message translates to:
  /// **'قلب رأسي'**
  String get editorFlipV;

  /// No description provided for @editorTransform.
  ///
  /// In ar, this message translates to:
  /// **'التحويلات'**
  String get editorTransform;

  /// No description provided for @editorToolSelect.
  ///
  /// In ar, this message translates to:
  /// **'تحديد'**
  String get editorToolSelect;

  /// No description provided for @editorToolShapes.
  ///
  /// In ar, this message translates to:
  /// **'أشكال'**
  String get editorToolShapes;

  /// No description provided for @editorFillType.
  ///
  /// In ar, this message translates to:
  /// **'نوع التعبئة'**
  String get editorFillType;

  /// No description provided for @editorFillSolid.
  ///
  /// In ar, this message translates to:
  /// **'لون موحّد'**
  String get editorFillSolid;

  /// No description provided for @editorGradientLinear.
  ///
  /// In ar, this message translates to:
  /// **'تدرّج خطي'**
  String get editorGradientLinear;

  /// No description provided for @editorGradientRadial.
  ///
  /// In ar, this message translates to:
  /// **'تدرّج شعاعي'**
  String get editorGradientRadial;

  /// No description provided for @editorGradientAngle.
  ///
  /// In ar, this message translates to:
  /// **'زاوية التدرّج'**
  String get editorGradientAngle;

  /// No description provided for @editorShadowEnable.
  ///
  /// In ar, this message translates to:
  /// **'إضافة ظل'**
  String get editorShadowEnable;

  /// No description provided for @editorShadowColor.
  ///
  /// In ar, this message translates to:
  /// **'لون الظل'**
  String get editorShadowColor;

  /// No description provided for @editorShadowBlur.
  ///
  /// In ar, this message translates to:
  /// **'تمويه الظل'**
  String get editorShadowBlur;

  /// No description provided for @editorShadowOffsetX.
  ///
  /// In ar, this message translates to:
  /// **'إزاحة أفقية'**
  String get editorShadowOffsetX;

  /// No description provided for @editorShadowOffsetY.
  ///
  /// In ar, this message translates to:
  /// **'إزاحة رأسية'**
  String get editorShadowOffsetY;

  /// No description provided for @editorShadowSpread.
  ///
  /// In ar, this message translates to:
  /// **'انتشار الظل'**
  String get editorShadowSpread;

  /// No description provided for @editorShadowRemove.
  ///
  /// In ar, this message translates to:
  /// **'إزالة الظل'**
  String get editorShadowRemove;

  /// No description provided for @editorPoints.
  ///
  /// In ar, this message translates to:
  /// **'عدد الرؤوس'**
  String get editorPoints;

  /// No description provided for @editorInnerRadius.
  ///
  /// In ar, this message translates to:
  /// **'نصف القطر الداخلي'**
  String get editorInnerRadius;

  /// No description provided for @editorCornerTopLeft.
  ///
  /// In ar, this message translates to:
  /// **'أعلى-يسار'**
  String get editorCornerTopLeft;

  /// No description provided for @editorCornerTopRight.
  ///
  /// In ar, this message translates to:
  /// **'أعلى-يمين'**
  String get editorCornerTopRight;

  /// No description provided for @editorCornerBottomRight.
  ///
  /// In ar, this message translates to:
  /// **'أسفل-يمين'**
  String get editorCornerBottomRight;

  /// No description provided for @editorCornerBottomLeft.
  ///
  /// In ar, this message translates to:
  /// **'أسفل-يسار'**
  String get editorCornerBottomLeft;

  /// No description provided for @editorDashPattern.
  ///
  /// In ar, this message translates to:
  /// **'نمط الشرطات'**
  String get editorDashPattern;

  /// No description provided for @editorBooleanOps.
  ///
  /// In ar, this message translates to:
  /// **'عمليات الدمج'**
  String get editorBooleanOps;

  /// No description provided for @editorBooleanUnion.
  ///
  /// In ar, this message translates to:
  /// **'دمج'**
  String get editorBooleanUnion;

  /// No description provided for @editorBooleanSubtract.
  ///
  /// In ar, this message translates to:
  /// **'طرح'**
  String get editorBooleanSubtract;

  /// No description provided for @editorBooleanIntersect.
  ///
  /// In ar, this message translates to:
  /// **'تقاطع'**
  String get editorBooleanIntersect;

  /// No description provided for @editorBooleanUngroup.
  ///
  /// In ar, this message translates to:
  /// **'فصل الشكل المركّب'**
  String get editorBooleanUngroup;

  /// No description provided for @paletteStar.
  ///
  /// In ar, this message translates to:
  /// **'نجمة'**
  String get paletteStar;

  /// No description provided for @palettePolygon.
  ///
  /// In ar, this message translates to:
  /// **'مضلّع'**
  String get palettePolygon;

  /// No description provided for @editorBooleanExclude.
  ///
  /// In ar, this message translates to:
  /// **'استثناء'**
  String get editorBooleanExclude;

  /// No description provided for @editorBooleanHint.
  ///
  /// In ar, this message translates to:
  /// **'يُبنى المسار المدمج كناتج عملية منطقية واحدة (بلا حدود متداخلة) ويمكن فكه في أي وقت.'**
  String get editorBooleanHint;

  /// No description provided for @editorDockTools.
  ///
  /// In ar, this message translates to:
  /// **'لوحة الأدوات'**
  String get editorDockTools;

  /// No description provided for @editorDockAnchor.
  ///
  /// In ar, this message translates to:
  /// **'موضع الإرساء'**
  String get editorDockAnchor;

  /// No description provided for @editorDockTopBar.
  ///
  /// In ar, this message translates to:
  /// **'الشريط العلوي'**
  String get editorDockTopBar;

  /// No description provided for @editorDockInspector.
  ///
  /// In ar, this message translates to:
  /// **'اللوحة الجانبية'**
  String get editorDockInspector;

  /// No description provided for @editorDockLeftRail.
  ///
  /// In ar, this message translates to:
  /// **'الشريط الجانبي'**
  String get editorDockLeftRail;

  /// No description provided for @editorDockFloating.
  ///
  /// In ar, this message translates to:
  /// **'عائمة'**
  String get editorDockFloating;

  /// No description provided for @editorDockCollapse.
  ///
  /// In ar, this message translates to:
  /// **'طيّ الأدوات'**
  String get editorDockCollapse;

  /// No description provided for @editorDockExpand.
  ///
  /// In ar, this message translates to:
  /// **'توسيع الأدوات'**
  String get editorDockExpand;

  /// No description provided for @editorDockResize.
  ///
  /// In ar, this message translates to:
  /// **'سحب لتغيير الحجم'**
  String get editorDockResize;

  /// No description provided for @editorDockDropHint.
  ///
  /// In ar, this message translates to:
  /// **'إفلات للالتقاط في'**
  String get editorDockDropHint;

  /// No description provided for @editorMoreTools.
  ///
  /// In ar, this message translates to:
  /// **'أدوات أخرى'**
  String get editorMoreTools;

  /// No description provided for @editorDocumentProperties.
  ///
  /// In ar, this message translates to:
  /// **'خصائص المستند'**
  String get editorDocumentProperties;

  /// No description provided for @editorDockReset.
  ///
  /// In ar, this message translates to:
  /// **'إعادة الإرساء الافتراضي'**
  String get editorDockReset;

  /// No description provided for @editorTextShadow.
  ///
  /// In ar, this message translates to:
  /// **'ظل النص'**
  String get editorTextShadow;

  /// No description provided for @editorTextShadowAdd.
  ///
  /// In ar, this message translates to:
  /// **'إضافة ظل للنص'**
  String get editorTextShadowAdd;

  /// No description provided for @editorShadowOpacity.
  ///
  /// In ar, this message translates to:
  /// **'شفافية الظل'**
  String get editorShadowOpacity;

  /// No description provided for @genderMale.
  ///
  /// In ar, this message translates to:
  /// **'ذكر'**
  String get genderMale;

  /// No description provided for @genderFemale.
  ///
  /// In ar, this message translates to:
  /// **'أنثى'**
  String get genderFemale;

  /// No description provided for @genderPreviewAutoHint.
  ///
  /// In ar, this message translates to:
  /// **'نقر لإلغاء الفرض (تلقائي)'**
  String get genderPreviewAutoHint;

  /// No description provided for @genderPresetCompleted.
  ///
  /// In ar, this message translates to:
  /// **'أتمّ / أتمّت'**
  String get genderPresetCompleted;

  /// No description provided for @genderPresetPassed.
  ///
  /// In ar, this message translates to:
  /// **'اجتاز / اجتازت'**
  String get genderPresetPassed;

  /// No description provided for @genderPresetForStudent.
  ///
  /// In ar, this message translates to:
  /// **'للطالب / للطالبة'**
  String get genderPresetForStudent;

  /// No description provided for @genderPresetStudent.
  ///
  /// In ar, this message translates to:
  /// **'الطالب / الطالبة'**
  String get genderPresetStudent;

  /// No description provided for @genderPresetToHim.
  ///
  /// In ar, this message translates to:
  /// **'له / لها'**
  String get genderPresetToHim;

  /// No description provided for @genderPresetHonoring.
  ///
  /// In ar, this message translates to:
  /// **'المتدرّب / المتدرّبة'**
  String get genderPresetHonoring;

  /// No description provided for @editorGenderSnippet.
  ///
  /// In ar, this message translates to:
  /// **'إدراج صيغة شرطية'**
  String get editorGenderSnippet;

  /// No description provided for @editorGenderSnippetHint.
  ///
  /// In ar, this message translates to:
  /// **'تُدرج صيغة تتبدّل تلقائياً حسب جنس المستفيد.'**
  String get editorGenderSnippetHint;

  /// No description provided for @bpGenderReviewTitle.
  ///
  /// In ar, this message translates to:
  /// **'مراجعة الجنس (تذكير/تأنيث)'**
  String get bpGenderReviewTitle;

  /// No description provided for @bpGenderReviewSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'الجنس مُكتشف من الاسم أو من عمود «الجنس» — صحّح أي حالة حدّية قبل الطباعة.'**
  String get bpGenderReviewSubtitle;

  /// No description provided for @bpGenderRow.
  ///
  /// In ar, this message translates to:
  /// **'الصف'**
  String get bpGenderRow;

  /// No description provided for @bpGenderDetected.
  ///
  /// In ar, this message translates to:
  /// **'المكتشف'**
  String get bpGenderDetected;

  /// No description provided for @bpGenderEffective.
  ///
  /// In ar, this message translates to:
  /// **'المطبَّق'**
  String get bpGenderEffective;

  /// No description provided for @bpGenderNameColumn.
  ///
  /// In ar, this message translates to:
  /// **'الاسم'**
  String get bpGenderNameColumn;

  /// No description provided for @bpGenderEditName.
  ///
  /// In ar, this message translates to:
  /// **'تعديل الاسم'**
  String get bpGenderEditName;

  /// No description provided for @bpGenderNameHint.
  ///
  /// In ar, this message translates to:
  /// **'اكتب الاسم الصحيح'**
  String get bpGenderNameHint;

  /// No description provided for @bpGenderClearOverrides.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء التصحيحات'**
  String get bpGenderClearOverrides;

  /// No description provided for @bpGenderOverridden.
  ///
  /// In ar, this message translates to:
  /// **'مُصحَّح يدوياً'**
  String get bpGenderOverridden;

  /// No description provided for @bpGenderUnknownName.
  ///
  /// In ar, this message translates to:
  /// **'—'**
  String get bpGenderUnknownName;

  /// No description provided for @bpOutputTitle.
  ///
  /// In ar, this message translates to:
  /// **'وجهة حفظ الشهادات'**
  String get bpOutputTitle;

  /// No description provided for @bpOutputHint.
  ///
  /// In ar, this message translates to:
  /// **'اختر المجلد الذي يُحفظ فيه ملف الـ PDF، أو ابدأ بالموقع الافتراضي.'**
  String get bpOutputHint;

  /// No description provided for @bpOutputPickFolder.
  ///
  /// In ar, this message translates to:
  /// **'اختيار مجلد…'**
  String get bpOutputPickFolder;

  /// No description provided for @bpOutputStart.
  ///
  /// In ar, this message translates to:
  /// **'بدء التوليد'**
  String get bpOutputStart;

  /// No description provided for @bpOutputPathLabel.
  ///
  /// In ar, this message translates to:
  /// **'المجلد المختار'**
  String get bpOutputPathLabel;

  /// No description provided for @bpOutputNoFolder.
  ///
  /// In ar, this message translates to:
  /// **'لم يُختَر مجلد — الطباعة والتصدير فقط.'**
  String get bpOutputNoFolder;

  /// No description provided for @bpOpenFolder.
  ///
  /// In ar, this message translates to:
  /// **'فتح المجلد'**
  String get bpOpenFolder;

  /// No description provided for @bpOutputSavedTitle.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ ملف الـ PDF'**
  String get bpOutputSavedTitle;

  /// No description provided for @bpOpenFolderFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر فتح المجلد.'**
  String get bpOpenFolderFailed;

  /// No description provided for @bpOutputNameLabel.
  ///
  /// In ar, this message translates to:
  /// **'اسم ملف التصدير'**
  String get bpOutputNameLabel;

  /// No description provided for @bpOutputNameHint.
  ///
  /// In ar, this message translates to:
  /// **'اكتب اسماً للملف بلا امتداد'**
  String get bpOutputNameHint;

  /// No description provided for @bpOutputNamePreviewLabel.
  ///
  /// In ar, this message translates to:
  /// **'سيُحفظ باسم'**
  String get bpOutputNamePreviewLabel;

  /// No description provided for @bpOutputModeLabel.
  ///
  /// In ar, this message translates to:
  /// **'نمط الحفظ'**
  String get bpOutputModeLabel;

  /// No description provided for @bpOutputModeCombined.
  ///
  /// In ar, this message translates to:
  /// **'ملف واحد مجمع'**
  String get bpOutputModeCombined;

  /// No description provided for @bpOutputModeIndividual.
  ///
  /// In ar, this message translates to:
  /// **'ملفات منفصلة لكل شخص'**
  String get bpOutputModeIndividual;

  /// No description provided for @hubTitle.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء مشروع جديد'**
  String get hubTitle;

  /// No description provided for @hubSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'اختر مقاساً جاهزاً أو حدّد أبعادك — تُفتح اللوحة بالمقاس والنسبة بالضبط.'**
  String get hubSubtitle;

  /// No description provided for @hubKindSingle.
  ///
  /// In ar, this message translates to:
  /// **'المطبوعات والوثائق المفردة'**
  String get hubKindSingle;

  /// No description provided for @hubKindMulti.
  ///
  /// In ar, this message translates to:
  /// **'الكتب والمنشورات متعددة الصفحات'**
  String get hubKindMulti;

  /// No description provided for @hubKindSingleHint.
  ///
  /// In ar, this message translates to:
  /// **'ورقة واحدة: شهادات وعقود، بطاقات، أرقام جلوس، كروت معايدة.'**
  String get hubKindSingleHint;

  /// No description provided for @hubKindMultiHint.
  ///
  /// In ar, this message translates to:
  /// **'متعدد الصفحات: كتاب، مجلة، كتيّب، تقرير، كتالوج.'**
  String get hubKindMultiHint;

  /// No description provided for @hubGroupCertificates.
  ///
  /// In ar, this message translates to:
  /// **'الشهادات والعقود'**
  String get hubGroupCertificates;

  /// No description provided for @hubGroupCards.
  ///
  /// In ar, this message translates to:
  /// **'الكروت وبطاقات الهوية'**
  String get hubGroupCards;

  /// No description provided for @hubGroupSeat.
  ///
  /// In ar, this message translates to:
  /// **'أرقام الجلوس والبطاقات'**
  String get hubGroupSeat;

  /// No description provided for @hubGroupGreeting.
  ///
  /// In ar, this message translates to:
  /// **'كروت المعايدات'**
  String get hubGroupGreeting;

  /// No description provided for @hubGroupPublications.
  ///
  /// In ar, this message translates to:
  /// **'الكتب والمنشورات'**
  String get hubGroupPublications;

  /// No description provided for @hubGroupCustom.
  ///
  /// In ar, this message translates to:
  /// **'مقاس مخصّص'**
  String get hubGroupCustom;

  /// No description provided for @hubDigitalBadge.
  ///
  /// In ar, this message translates to:
  /// **'رقمي'**
  String get hubDigitalBadge;

  /// No description provided for @hubCreate.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء'**
  String get hubCreate;

  /// No description provided for @hubCustomCardBody.
  ///
  /// In ar, this message translates to:
  /// **'أدخل أبعادك بالوحدة التي تريدها لتبدأ بلوحة على مقاسك.'**
  String get hubCustomCardBody;

  /// No description provided for @hubCustomName.
  ///
  /// In ar, this message translates to:
  /// **'اسم المشروع'**
  String get hubCustomName;

  /// No description provided for @hubCustomNameHint.
  ///
  /// In ar, this message translates to:
  /// **'مثال: بطاقة دعوة'**
  String get hubCustomNameHint;

  /// No description provided for @hubCustomPreview.
  ///
  /// In ar, this message translates to:
  /// **'المقاس النهائي'**
  String get hubCustomPreview;

  /// No description provided for @hubCustomCreate.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء اللوحة'**
  String get hubCustomCreate;

  /// No description provided for @hubCustomType.
  ///
  /// In ar, this message translates to:
  /// **'نوع المشروع'**
  String get hubCustomType;

  /// No description provided for @hubSearchHint.
  ///
  /// In ar, this message translates to:
  /// **'بحث في المقاسات…'**
  String get hubSearchHint;

  /// No description provided for @hubNoResults.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد مقاس مطابق — جرّب كلمة بحث أخرى.'**
  String get hubNoResults;

  /// No description provided for @hubAspectRatio.
  ///
  /// In ar, this message translates to:
  /// **'النسبة'**
  String get hubAspectRatio;

  /// No description provided for @destNewProject.
  ///
  /// In ar, this message translates to:
  /// **'مشروع جديد'**
  String get destNewProject;

  /// No description provided for @destNewProjectDesc.
  ///
  /// In ar, this message translates to:
  /// **'اختر مقاساً جاهزاً أو مخصّصاً وابدأ التصميم مباشرةً.'**
  String get destNewProjectDesc;

  /// No description provided for @ptpImpositionToggle.
  ///
  /// In ar, this message translates to:
  /// **'تجميع للطباعة'**
  String get ptpImpositionToggle;

  /// No description provided for @ptpImpositionNoFit.
  ///
  /// In ar, this message translates to:
  /// **'لا تتسع الورقة لهذه القطعة — صغّر الهوامش أو اختر ورقة أكبر.'**
  String get ptpImpositionNoFit;

  /// No description provided for @editorEffectsTitle.
  ///
  /// In ar, this message translates to:
  /// **'التأثيرات والضبط اللوني'**
  String get editorEffectsTitle;

  /// No description provided for @editorShadowGroup.
  ///
  /// In ar, this message translates to:
  /// **'الظل'**
  String get editorShadowGroup;

  /// No description provided for @editorOuterGlow.
  ///
  /// In ar, this message translates to:
  /// **'توهّج خارجي'**
  String get editorOuterGlow;

  /// No description provided for @editorInnerGlow.
  ///
  /// In ar, this message translates to:
  /// **'توهّج داخلي'**
  String get editorInnerGlow;

  /// No description provided for @editorGlowAdd.
  ///
  /// In ar, this message translates to:
  /// **'إضافة توهّج'**
  String get editorGlowAdd;

  /// No description provided for @editorGlowRemove.
  ///
  /// In ar, this message translates to:
  /// **'إزالة التوهّج'**
  String get editorGlowRemove;

  /// No description provided for @editorGlowColor.
  ///
  /// In ar, this message translates to:
  /// **'لون التوهّج'**
  String get editorGlowColor;

  /// No description provided for @editorGlowRadius.
  ///
  /// In ar, this message translates to:
  /// **'نطاق التوهّج'**
  String get editorGlowRadius;

  /// No description provided for @editorGlowSpread.
  ///
  /// In ar, this message translates to:
  /// **'توسّع التوهّج'**
  String get editorGlowSpread;

  /// No description provided for @editorGlowOpacity.
  ///
  /// In ar, this message translates to:
  /// **'شفافية التوهّج'**
  String get editorGlowOpacity;

  /// No description provided for @editorAdjustGroup.
  ///
  /// In ar, this message translates to:
  /// **'الضبط اللوني'**
  String get editorAdjustGroup;

  /// No description provided for @editorAdjustBrightness.
  ///
  /// In ar, this message translates to:
  /// **'السطوع'**
  String get editorAdjustBrightness;

  /// No description provided for @editorAdjustContrast.
  ///
  /// In ar, this message translates to:
  /// **'التباين'**
  String get editorAdjustContrast;

  /// No description provided for @editorAdjustSaturation.
  ///
  /// In ar, this message translates to:
  /// **'التشبّع'**
  String get editorAdjustSaturation;

  /// No description provided for @editorAdjustHue.
  ///
  /// In ar, this message translates to:
  /// **'تدوير اللون'**
  String get editorAdjustHue;

  /// No description provided for @editorAdjustReset.
  ///
  /// In ar, this message translates to:
  /// **'إعادة الضبط'**
  String get editorAdjustReset;

  /// No description provided for @bpOutputSavedFolderTitle.
  ///
  /// In ar, this message translates to:
  /// **'حُفظت الملفات في مجلد مخصص'**
  String get bpOutputSavedFolderTitle;

  /// No description provided for @hubDetailsTitle.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل المقاس'**
  String get hubDetailsTitle;

  /// No description provided for @hubDetailsHint.
  ///
  /// In ar, this message translates to:
  /// **'مواصفة افتراضية معبّأة مسبقاً — اختر مقاساً من الشبكة أو عدّل الأبعاد لتبدأ.'**
  String get hubDetailsHint;

  /// No description provided for @hubFilterAll.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get hubFilterAll;

  /// No description provided for @hubFilterRecent.
  ///
  /// In ar, this message translates to:
  /// **'الأبعاد الأخيرة'**
  String get hubFilterRecent;

  /// No description provided for @hubFilterSeat.
  ///
  /// In ar, this message translates to:
  /// **'أرقام الجلوس'**
  String get hubFilterSeat;

  /// No description provided for @hubFilterGreeting.
  ///
  /// In ar, this message translates to:
  /// **'المعايدات والشاشات'**
  String get hubFilterGreeting;

  /// No description provided for @hubRecentEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا مقاسات أخيرة بعد — أي مشروع تنشئه يظهر هنا.'**
  String get hubRecentEmpty;

  /// No description provided for @hubDocTitle.
  ///
  /// In ar, this message translates to:
  /// **'اسم المشروع'**
  String get hubDocTitle;

  /// No description provided for @hubDocTitleHint.
  ///
  /// In ar, this message translates to:
  /// **'مشروع جديد - 1'**
  String get hubDocTitleHint;

  /// No description provided for @hubWidth.
  ///
  /// In ar, this message translates to:
  /// **'العرض'**
  String get hubWidth;

  /// No description provided for @hubHeight.
  ///
  /// In ar, this message translates to:
  /// **'الارتفاع'**
  String get hubHeight;

  /// No description provided for @hubUnitLabel.
  ///
  /// In ar, this message translates to:
  /// **'الوحدة'**
  String get hubUnitLabel;

  /// No description provided for @hubOrientationLabel.
  ///
  /// In ar, this message translates to:
  /// **'الاتجاه'**
  String get hubOrientationLabel;

  /// No description provided for @hubPortrait.
  ///
  /// In ar, this message translates to:
  /// **'رأسي'**
  String get hubPortrait;

  /// No description provided for @hubLandscape.
  ///
  /// In ar, this message translates to:
  /// **'أفقي'**
  String get hubLandscape;

  /// No description provided for @hubVariantLabel.
  ///
  /// In ar, this message translates to:
  /// **'النوع'**
  String get hubVariantLabel;

  /// No description provided for @hubResolutionLabel.
  ///
  /// In ar, this message translates to:
  /// **'الدقّة'**
  String get hubResolutionLabel;

  /// No description provided for @hubResolutionUnitLabel.
  ///
  /// In ar, this message translates to:
  /// **'وحدة الدقّة'**
  String get hubResolutionUnitLabel;

  /// No description provided for @hubColorModeLabel.
  ///
  /// In ar, this message translates to:
  /// **'نمط اللون'**
  String get hubColorModeLabel;

  /// No description provided for @hubBackgroundLabel.
  ///
  /// In ar, this message translates to:
  /// **'لون الخلفية'**
  String get hubBackgroundLabel;

  /// No description provided for @hubBackgroundWhite.
  ///
  /// In ar, this message translates to:
  /// **'أبيض'**
  String get hubBackgroundWhite;

  /// No description provided for @hubBackgroundTransparent.
  ///
  /// In ar, this message translates to:
  /// **'شفاف'**
  String get hubBackgroundTransparent;

  /// No description provided for @hubBackgroundBlack.
  ///
  /// In ar, this message translates to:
  /// **'أسود'**
  String get hubBackgroundBlack;

  /// No description provided for @hubBackgroundCustom.
  ///
  /// In ar, this message translates to:
  /// **'لون مخصّص'**
  String get hubBackgroundCustom;

  /// No description provided for @hubCreateProject.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء المشروع'**
  String get hubCreateProject;

  /// No description provided for @hubCustomFamilyTitle.
  ///
  /// In ar, this message translates to:
  /// **'مقاس مخصّص'**
  String get hubCustomFamilyTitle;

  /// No description provided for @newDocTitle.
  ///
  /// In ar, this message translates to:
  /// **'مستند جديد'**
  String get newDocTitle;

  /// No description provided for @newDocScopeSocial.
  ///
  /// In ar, this message translates to:
  /// **'الشاشات والمعايدات'**
  String get newDocScopeSocial;

  /// No description provided for @newDocFilterCertificates.
  ///
  /// In ar, this message translates to:
  /// **'الشهادات'**
  String get newDocFilterCertificates;

  /// No description provided for @newDocFilterCards.
  ///
  /// In ar, this message translates to:
  /// **'الكروت'**
  String get newDocFilterCards;

  /// No description provided for @newDocFilterGreeting.
  ///
  /// In ar, this message translates to:
  /// **'المعايدات'**
  String get newDocFilterGreeting;

  /// No description provided for @newDocFilterPublications.
  ///
  /// In ar, this message translates to:
  /// **'المنشورات'**
  String get newDocFilterPublications;

  /// No description provided for @menuFile.
  ///
  /// In ar, this message translates to:
  /// **'ملف'**
  String get menuFile;

  /// No description provided for @menuEdit.
  ///
  /// In ar, this message translates to:
  /// **'تعديل'**
  String get menuEdit;

  /// No description provided for @menuView.
  ///
  /// In ar, this message translates to:
  /// **'عرض'**
  String get menuView;

  /// No description provided for @menuTools.
  ///
  /// In ar, this message translates to:
  /// **'أدوات'**
  String get menuTools;

  /// No description provided for @menuHelp.
  ///
  /// In ar, this message translates to:
  /// **'مساعدة'**
  String get menuHelp;

  /// No description provided for @menuNewDocument.
  ///
  /// In ar, this message translates to:
  /// **'مستند جديد…'**
  String get menuNewDocument;

  /// No description provided for @menuPurgeRecent.
  ///
  /// In ar, this message translates to:
  /// **'تفريغ قائمة الأبعاد الأخيرة'**
  String get menuPurgeRecent;

  /// No description provided for @menuPurgeImageCache.
  ///
  /// In ar, this message translates to:
  /// **'تفريغ ذاكرة الصور المؤقتة'**
  String get menuPurgeImageCache;

  /// No description provided for @menuPreviewCertificate.
  ///
  /// In ar, this message translates to:
  /// **'معاينة الشهادة النموذجية'**
  String get menuPreviewCertificate;

  /// No description provided for @menuPreviewContract.
  ///
  /// In ar, this message translates to:
  /// **'معاينة العقد النموذجي'**
  String get menuPreviewContract;

  /// No description provided for @menuAbout.
  ///
  /// In ar, this message translates to:
  /// **'حول JoodCraft'**
  String get menuAbout;

  /// No description provided for @actionNewShort.
  ///
  /// In ar, this message translates to:
  /// **'+ جديد'**
  String get actionNewShort;

  /// No description provided for @dashLocalMode.
  ///
  /// In ar, this message translates to:
  /// **'محلي'**
  String get dashLocalMode;

  /// No description provided for @dashLocalStorage.
  ///
  /// In ar, this message translates to:
  /// **'الحفظ محلي على هذا الجهاز — لا يُرفع أي مشروع إلى سيرفر.'**
  String get dashLocalStorage;

  /// No description provided for @dashRecentProjects.
  ///
  /// In ar, this message translates to:
  /// **'المشاريع الأخيرة'**
  String get dashRecentProjects;

  /// No description provided for @dashRecentEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مشاريع محفوظة على هذا الجهاز بعد — أنشئ مستنداً جديداً وستجده هنا فوراً.'**
  String get dashRecentEmpty;

  /// No description provided for @dashRecentOpen.
  ///
  /// In ar, this message translates to:
  /// **'فتح المشروع'**
  String get dashRecentOpen;

  /// No description provided for @editorTransformPosition.
  ///
  /// In ar, this message translates to:
  /// **'التحويل والموضع'**
  String get editorTransformPosition;

  /// No description provided for @editorTransformPositionHint.
  ///
  /// In ar, this message translates to:
  /// **'الإحداثيات والأبعاد وزاوية الدوران'**
  String get editorTransformPositionHint;

  /// No description provided for @editorAppearanceEffects.
  ///
  /// In ar, this message translates to:
  /// **'المظهر والمؤثرات'**
  String get editorAppearanceEffects;

  /// No description provided for @editorAppearanceEffectsHint.
  ///
  /// In ar, this message translates to:
  /// **'التعبئة والحدود والتوهّج والظلال'**
  String get editorAppearanceEffectsHint;

  /// No description provided for @editorTypographyHint.
  ///
  /// In ar, this message translates to:
  /// **'الخط والحجم والمحاذاة والتباعد'**
  String get editorTypographyHint;

  /// No description provided for @editorPageSettingsHint.
  ///
  /// In ar, this message translates to:
  /// **'المقاس ووحدة القياس'**
  String get editorPageSettingsHint;

  /// No description provided for @editorBackgroundHint.
  ///
  /// In ar, this message translates to:
  /// **'لون الورقة أو تدرّجها'**
  String get editorBackgroundHint;

  /// No description provided for @editorPrecisionHint.
  ///
  /// In ar, this message translates to:
  /// **'النقل الدقيق والتحجيم'**
  String get editorPrecisionHint;

  /// No description provided for @joodExportProject.
  ///
  /// In ar, this message translates to:
  /// **'تصدير مشروع (.jood)'**
  String get joodExportProject;

  /// No description provided for @joodImportProject.
  ///
  /// In ar, this message translates to:
  /// **'فتح مشروع (.jood)'**
  String get joodImportProject;

  /// No description provided for @joodExportReady.
  ///
  /// In ar, this message translates to:
  /// **'تم تجهيز ملف المشروع للحفظ.'**
  String get joodExportReady;

  /// No description provided for @joodExportFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تصدير ملف المشروع.'**
  String get joodExportFailed;

  /// No description provided for @joodImportOpened.
  ///
  /// In ar, this message translates to:
  /// **'تم فتح المشروع المستورد.'**
  String get joodImportOpened;

  /// No description provided for @joodImportFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر فتح ملف المشروع.'**
  String get joodImportFailed;

  /// No description provided for @joodRecoveryTitle.
  ///
  /// In ar, this message translates to:
  /// **'مسودة غير محفوظة'**
  String get joodRecoveryTitle;

  /// No description provided for @joodRecoveryMessage.
  ///
  /// In ar, this message translates to:
  /// **'توجد مسودة غير محفوظة من جلسة سابقة. هل ترغب في استعادتها؟'**
  String get joodRecoveryMessage;

  /// No description provided for @joodRecoveryRestore.
  ///
  /// In ar, this message translates to:
  /// **'استعادة'**
  String get joodRecoveryRestore;

  /// No description provided for @joodRecoveryDiscard.
  ///
  /// In ar, this message translates to:
  /// **'إهمال'**
  String get joodRecoveryDiscard;

  /// No description provided for @joodRecoveryRestored.
  ///
  /// In ar, this message translates to:
  /// **'تم استعادة المسودة.'**
  String get joodRecoveryRestored;

  /// No description provided for @joodAutosaveSaved.
  ///
  /// In ar, this message translates to:
  /// **'تم الحفظ تلقائياً'**
  String get joodAutosaveSaved;

  /// No description provided for @joodAutosaveSaving.
  ///
  /// In ar, this message translates to:
  /// **'جاري الحفظ…'**
  String get joodAutosaveSaving;

  /// No description provided for @editorConfirm.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد'**
  String get editorConfirm;

  /// No description provided for @admTitle.
  ///
  /// In ar, this message translates to:
  /// **'إدارة المديرين المحليين'**
  String get admTitle;

  /// No description provided for @admRefresh.
  ///
  /// In ar, this message translates to:
  /// **'تحديث'**
  String get admRefresh;

  /// No description provided for @admTabAdmins.
  ///
  /// In ar, this message translates to:
  /// **'المديرون'**
  String get admTabAdmins;

  /// No description provided for @admTabTransfer.
  ///
  /// In ar, this message translates to:
  /// **'النقل بين الأجهزة'**
  String get admTabTransfer;

  /// No description provided for @admTabAudit.
  ///
  /// In ar, this message translates to:
  /// **'سجل التصدير'**
  String get admTabAudit;

  /// No description provided for @admListTitle.
  ///
  /// In ar, this message translates to:
  /// **'حسابات المديرين على هذا الجهاز'**
  String get admListTitle;

  /// No description provided for @admAdd.
  ///
  /// In ar, this message translates to:
  /// **'إضافة مدير'**
  String get admAdd;

  /// No description provided for @admNoAdmins.
  ///
  /// In ar, this message translates to:
  /// **'لا حسابات مديرين بعد.'**
  String get admNoAdmins;

  /// No description provided for @admLoading.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ تحميل حسابات المديرين على هذا الجهاز…'**
  String get admLoading;

  /// No description provided for @admRoleOwner.
  ///
  /// In ar, this message translates to:
  /// **'المدير الرئيسي'**
  String get admRoleOwner;

  /// No description provided for @admCurrent.
  ///
  /// In ar, this message translates to:
  /// **'أنت'**
  String get admCurrent;

  /// No description provided for @admCurrentCardTitle.
  ///
  /// In ar, this message translates to:
  /// **'الحساب الحالي على الجهاز'**
  String get admCurrentCardTitle;

  /// No description provided for @admRoleAdmin.
  ///
  /// In ar, this message translates to:
  /// **'مدير'**
  String get admRoleAdmin;

  /// No description provided for @admSwitchTitle.
  ///
  /// In ar, this message translates to:
  /// **'تبديل الحساب السريع'**
  String get admSwitchTitle;

  /// No description provided for @admSwitchPrompt.
  ///
  /// In ar, this message translates to:
  /// **'اختر اسم المستخدم المحلي لحساب فرعي على هذا الجهاز وأدخل كلمة مروره المحلية للانتقال إلى جلساته فوراً — تُحفظ مسودّات المشاريع المفتوحة أولاً، ولا يتأثر ترخيص الاشتراك الأساسي.'**
  String get admSwitchPrompt;

  /// No description provided for @admSwitchNoOthers.
  ///
  /// In ar, this message translates to:
  /// **'لا حسابات فرعية أخرى على هذا الجهاز. أضِف مديراً جديداً من شاشة إدارة المديرين أولاً.'**
  String get admSwitchNoOthers;

  /// No description provided for @admSwitchPick.
  ///
  /// In ar, this message translates to:
  /// **'اسم المستخدم المحلي'**
  String get admSwitchPick;

  /// No description provided for @admSwitchPassword.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور المحلية للحساب المختار'**
  String get admSwitchPassword;

  /// No description provided for @admSwitchPickPassword.
  ///
  /// In ar, this message translates to:
  /// **'اختر اسم المستخدم وأدخل كلمة المرور.'**
  String get admSwitchPickPassword;

  /// No description provided for @admSwitchWrongPassword.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور غير صحيحة.'**
  String get admSwitchWrongPassword;

  /// No description provided for @admSwitchFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تبديل الحساب. حاول مرة أخرى.'**
  String get admSwitchFailed;

  /// No description provided for @admSwitchSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم تبديل الحساب بنجاح.'**
  String get admSwitchSuccess;

  /// No description provided for @admSwitchAccount.
  ///
  /// In ar, this message translates to:
  /// **'تبديل الحساب'**
  String get admSwitchAccount;

  /// No description provided for @admSwitchAction.
  ///
  /// In ar, this message translates to:
  /// **'تبديل الآن'**
  String get admSwitchAction;

  /// No description provided for @admColAdmin.
  ///
  /// In ar, this message translates to:
  /// **'المدير'**
  String get admColAdmin;

  /// No description provided for @admColUsername.
  ///
  /// In ar, this message translates to:
  /// **'اسم المستخدم المحلي'**
  String get admColUsername;

  /// No description provided for @admColRole.
  ///
  /// In ar, this message translates to:
  /// **'الصلاحية'**
  String get admColRole;

  /// No description provided for @admColCreated.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ الإضافة'**
  String get admColCreated;

  /// No description provided for @admColActions.
  ///
  /// In ar, this message translates to:
  /// **'إجراءات'**
  String get admColActions;

  /// No description provided for @destJoodWriter.
  ///
  /// In ar, this message translates to:
  /// **'جود كاتب'**
  String get destJoodWriter;

  /// No description provided for @destJoodWriterDesc.
  ///
  /// In ar, this message translates to:
  /// **'مستندات وتقارير نصّية بصفحات متتالية وتدفّق تلقائي للنص.'**
  String get destJoodWriterDesc;

  /// No description provided for @admCreatedAt.
  ///
  /// In ar, this message translates to:
  /// **'أُنشئ'**
  String get admCreatedAt;

  /// No description provided for @admEdit.
  ///
  /// In ar, this message translates to:
  /// **'تعديل البيانات'**
  String get admEdit;

  /// No description provided for @admChangePassword.
  ///
  /// In ar, this message translates to:
  /// **'تغيير كلمة المرور'**
  String get admChangePassword;

  /// No description provided for @admPromote.
  ///
  /// In ar, this message translates to:
  /// **'ترقية إلى «مدير رئيسي»'**
  String get admPromote;

  /// No description provided for @admDemote.
  ///
  /// In ar, this message translates to:
  /// **'تخفيض إلى «مدير»'**
  String get admDemote;

  /// No description provided for @admDelete.
  ///
  /// In ar, this message translates to:
  /// **'حذف الحساب'**
  String get admDelete;

  /// No description provided for @admDeleteConfirm.
  ///
  /// In ar, this message translates to:
  /// **'سيُحذف «{name}» من هذا الجهاز نهائياً. لا يمكن التراجع.'**
  String admDeleteConfirm(Object name);

  /// No description provided for @admPromoted.
  ///
  /// In ar, this message translates to:
  /// **'تمت الترقية إلى «مدير رئيسي».'**
  String get admPromoted;

  /// No description provided for @admDemoted.
  ///
  /// In ar, this message translates to:
  /// **'تم التخفيض إلى «مدير».'**
  String get admDemoted;

  /// No description provided for @admDeleted.
  ///
  /// In ar, this message translates to:
  /// **'حُذف الحساب.'**
  String get admDeleted;

  /// No description provided for @admCreated.
  ///
  /// In ar, this message translates to:
  /// **'أُضيف المدير الجديد.'**
  String get admCreated;

  /// No description provided for @admUpdated.
  ///
  /// In ar, this message translates to:
  /// **'حُدّثت بيانات المدير.'**
  String get admUpdated;

  /// No description provided for @admPasswordChanged.
  ///
  /// In ar, this message translates to:
  /// **'تغيّرت كلمة المرور.'**
  String get admPasswordChanged;

  /// No description provided for @admTransferInfoTitle.
  ///
  /// In ar, this message translates to:
  /// **'كيف يعمل النقل؟'**
  String get admTransferInfoTitle;

  /// No description provided for @admTransferInfo1.
  ///
  /// In ar, this message translates to:
  /// **'يُصدَّر جدول الحسابات (ببصمات كلمات المرور لا كلماتها) داخل ملف مشفّر بعبارة مرور تختارها أنت.'**
  String get admTransferInfo1;

  /// No description provided for @admTransferInfo2.
  ///
  /// In ar, this message translates to:
  /// **'انقل الملف أو الشفرة إلى الجهاز الآخر ثم استوردها هناك بالعبارة نفسها، فتعمل الحسابات بنفس الصلاحيات.'**
  String get admTransferInfo2;

  /// No description provided for @admTransferInfo3.
  ///
  /// In ar, this message translates to:
  /// **'لا يُرسل شيء إلى أي سيرفر: النقل يدوي بالكامل بين أجهزة محلية.'**
  String get admTransferInfo3;

  /// No description provided for @admExport.
  ///
  /// In ar, this message translates to:
  /// **'تصدير الحسابات'**
  String get admExport;

  /// No description provided for @admExportPassphrase.
  ///
  /// In ar, this message translates to:
  /// **'عبارة مرور التصدير'**
  String get admExportPassphrase;

  /// No description provided for @admPassphraseConfirm.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد العبارة'**
  String get admPassphraseConfirm;

  /// No description provided for @admExportRisk.
  ///
  /// In ar, this message translates to:
  /// **'أفهم أن من يملك هذه الشفرة وعبارتها يستطيع الدخول بالحسابات، فسأشاركها بضبط.'**
  String get admExportRisk;

  /// No description provided for @admExportGenerate.
  ///
  /// In ar, this message translates to:
  /// **'توليد الشفرة المشفّرة'**
  String get admExportGenerate;

  /// No description provided for @admExportFile.
  ///
  /// In ar, this message translates to:
  /// **'حفظ في ملف خاص'**
  String get admExportFile;

  /// No description provided for @admExportDone.
  ///
  /// In ar, this message translates to:
  /// **'توليدت الشفرة المشفّرة. انسخها أو احفظها في ملف.'**
  String get admExportDone;

  /// No description provided for @admExportFileSaved.
  ///
  /// In ar, this message translates to:
  /// **'حُفظ ملف الحسابات المشفّر.'**
  String get admExportFileSaved;

  /// No description provided for @admPassphraseTooShort.
  ///
  /// In ar, this message translates to:
  /// **'اجعل عبارة المرور 6 أحرف على الأقل.'**
  String get admPassphraseTooShort;

  /// No description provided for @admPassphraseMismatch.
  ///
  /// In ar, this message translates to:
  /// **'العبارتان غير متطابقتين.'**
  String get admPassphraseMismatch;

  /// No description provided for @admAcceptRiskRequired.
  ///
  /// In ar, this message translates to:
  /// **'أكّد أولاً أنك تفهم مخاطر مشاركة الشفرة.'**
  String get admAcceptRiskRequired;

  /// No description provided for @admFileError.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر التعامل مع الملف: {error}'**
  String admFileError(Object error);

  /// No description provided for @admImport.
  ///
  /// In ar, this message translates to:
  /// **'استيراد الحسابات'**
  String get admImport;

  /// No description provided for @admImportCode.
  ///
  /// In ar, this message translates to:
  /// **'شفرة الحسابات'**
  String get admImportCode;

  /// No description provided for @admImportPassphrase.
  ///
  /// In ar, this message translates to:
  /// **'عبارة مرور الملف'**
  String get admImportPassphrase;

  /// No description provided for @admImportReplace.
  ///
  /// In ar, this message translates to:
  /// **'استبدال كلمات مرور الحسابات الموجودة'**
  String get admImportReplace;

  /// No description provided for @admImportPick.
  ///
  /// In ar, this message translates to:
  /// **'اختيار ملف'**
  String get admImportPick;

  /// No description provided for @admImportRun.
  ///
  /// In ar, this message translates to:
  /// **'استيراد الآن'**
  String get admImportRun;

  /// No description provided for @admImportCodeRequired.
  ///
  /// In ar, this message translates to:
  /// **'ألصق الشفرة أو اختر ملفاً أولاً.'**
  String get admImportCodeRequired;

  /// No description provided for @admImportPassphraseRequired.
  ///
  /// In ar, this message translates to:
  /// **'أدخل عبارة مرور الملف.'**
  String get admImportPassphraseRequired;

  /// No description provided for @admImportDone.
  ///
  /// In ar, this message translates to:
  /// **'تمّ الاستيراد: {added} جديد، {updated} مُحدَّث، {skipped} مُتخطّى.'**
  String admImportDone(int added, int updated, int skipped);

  /// No description provided for @admAuditTitle.
  ///
  /// In ar, this message translates to:
  /// **'سجل الشهادات والمستندات الصادرة'**
  String get admAuditTitle;

  /// No description provided for @admAuditClear.
  ///
  /// In ar, this message translates to:
  /// **'تفريغ السجل'**
  String get admAuditClear;

  /// No description provided for @admAuditEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا سجلات تصدير بعد. كل شهادة أو عقد تصدّره سيُسجَّل هنا بالتاريخ والمدير الذي أصدره.'**
  String get admAuditEmpty;

  /// No description provided for @admAuditBy.
  ///
  /// In ar, this message translates to:
  /// **'بواسطة'**
  String get admAuditBy;

  /// No description provided for @admAuditPages.
  ///
  /// In ar, this message translates to:
  /// **'صفحة'**
  String get admAuditPages;

  /// No description provided for @admAuditClearConfirm.
  ///
  /// In ar, this message translates to:
  /// **'سيُحذف كل سجل التصدير من هذا الجهاز. لا يمكن التراجع.'**
  String get admAuditClearConfirm;

  /// No description provided for @admAuditCleared.
  ///
  /// In ar, this message translates to:
  /// **'تم تفريغ السجل.'**
  String get admAuditCleared;

  /// No description provided for @admUnavailableTitle.
  ///
  /// In ar, this message translates to:
  /// **'الإدارة غير متاحة الآن'**
  String get admUnavailableTitle;

  /// No description provided for @admUnavailableBody.
  ///
  /// In ar, this message translates to:
  /// **'إدارة المديرين تعمل عندما يُشغَّل التطبيق بحساب محلي (LocalAuthRepository)، فتُقرأ الحسابات من هذا الجهاز.'**
  String get admUnavailableBody;

  /// No description provided for @pdfExportTypeTitle.
  ///
  /// In ar, this message translates to:
  /// **'نوع التصدير'**
  String get pdfExportTypeTitle;

  /// No description provided for @pdfExportTypeHint.
  ///
  /// In ar, this message translates to:
  /// **'اختر صيغة الملف قبل التصدير.'**
  String get pdfExportTypeHint;

  /// No description provided for @pdfExportTypeImages.
  ///
  /// In ar, this message translates to:
  /// **'صور'**
  String get pdfExportTypeImages;

  /// No description provided for @pdfExportTypeImagesDesc.
  ///
  /// In ar, this message translates to:
  /// **'مطابقة 100% — حجم أكبر'**
  String get pdfExportTypeImagesDesc;

  /// No description provided for @pdfExportTypeImagesNotCopyable.
  ///
  /// In ar, this message translates to:
  /// **'النص غير قابل للنسخ'**
  String get pdfExportTypeImagesNotCopyable;

  /// No description provided for @pdfExportTypeVector.
  ///
  /// In ar, this message translates to:
  /// **'فيكتور'**
  String get pdfExportTypeVector;

  /// No description provided for @pdfExportTypeVectorDesc.
  ///
  /// In ar, this message translates to:
  /// **'نص قابل للنسخ — حجم أصغر'**
  String get pdfExportTypeVectorDesc;

  /// No description provided for @pdfExportTypeVectorCopyable.
  ///
  /// In ar, this message translates to:
  /// **'نص قابل للنسخ والبحث'**
  String get pdfExportTypeVectorCopyable;

  /// No description provided for @pdfExportTypeVectorBestFor.
  ///
  /// In ar, this message translates to:
  /// **'مثالي للطباعة الاحترافية'**
  String get pdfExportTypeVectorBestFor;

  /// No description provided for @pdfExportTypeComingSoon.
  ///
  /// In ar, this message translates to:
  /// **'قريباً'**
  String get pdfExportTypeComingSoon;

  /// No description provided for @pdfExportTypeComingSoonMessage.
  ///
  /// In ar, this message translates to:
  /// **'تصدير الفيكتور قيد التطوير — سيتوفر قريباً.'**
  String get pdfExportTypeComingSoonMessage;

  /// No description provided for @invCategoryTitle.
  ///
  /// In ar, this message translates to:
  /// **'دعوات ومناسبات'**
  String get invCategoryTitle;

  /// No description provided for @invCategoryRamadan.
  ///
  /// In ar, this message translates to:
  /// **'رمضان'**
  String get invCategoryRamadan;

  /// No description provided for @invCategoryEid.
  ///
  /// In ar, this message translates to:
  /// **'عيد'**
  String get invCategoryEid;

  /// No description provided for @invCategoryWedding.
  ///
  /// In ar, this message translates to:
  /// **'زفاف'**
  String get invCategoryWedding;

  /// No description provided for @invRamadan1Title.
  ///
  /// In ar, this message translates to:
  /// **'رمضان كريم — كلاسيكي'**
  String get invRamadan1Title;

  /// No description provided for @invRamadan2Title.
  ///
  /// In ar, this message translates to:
  /// **'رمضان كريم — Story'**
  String get invRamadan2Title;

  /// No description provided for @invEid1Title.
  ///
  /// In ar, this message translates to:
  /// **'عيد مبارك — كلاسيكي'**
  String get invEid1Title;

  /// No description provided for @invEid2Title.
  ///
  /// In ar, this message translates to:
  /// **'عيد مبارك — Story'**
  String get invEid2Title;

  /// No description provided for @invWedding1Title.
  ///
  /// In ar, this message translates to:
  /// **'زفاف كلاسيكي'**
  String get invWedding1Title;

  /// No description provided for @invWedding2Title.
  ///
  /// In ar, this message translates to:
  /// **'زفاف حديث'**
  String get invWedding2Title;

  /// No description provided for @invWedding3Title.
  ///
  /// In ar, this message translates to:
  /// **'زفاف Story'**
  String get invWedding3Title;

  /// No description provided for @invSizeA6Portrait.
  ///
  /// In ar, this message translates to:
  /// **'A6 رأسي (105×148 mm)'**
  String get invSizeA6Portrait;

  /// No description provided for @invSizeA6Landscape.
  ///
  /// In ar, this message translates to:
  /// **'A6 أفقي (148×105 mm)'**
  String get invSizeA6Landscape;

  /// No description provided for @invSizeSquare148.
  ///
  /// In ar, this message translates to:
  /// **'مربع للطباعة (148×148 mm)'**
  String get invSizeSquare148;

  /// No description provided for @invSizeA5Folded.
  ///
  /// In ar, this message translates to:
  /// **'A5 مطوي (105×148 mm)'**
  String get invSizeA5Folded;

  /// No description provided for @invSizeInstagramSquare.
  ///
  /// In ar, this message translates to:
  /// **'Instagram مربع (1080×1080)'**
  String get invSizeInstagramSquare;

  /// No description provided for @invSizeInstagramPortrait.
  ///
  /// In ar, this message translates to:
  /// **'Instagram طولي (1080×1350)'**
  String get invSizeInstagramPortrait;

  /// No description provided for @invSizeInstagramStory.
  ///
  /// In ar, this message translates to:
  /// **'Instagram Story (1080×1920)'**
  String get invSizeInstagramStory;

  /// No description provided for @invSizeWhatsAppStatus.
  ///
  /// In ar, this message translates to:
  /// **'WhatsApp Status (1080×1920)'**
  String get invSizeWhatsAppStatus;

  /// No description provided for @invSizeFacebookPost.
  ///
  /// In ar, this message translates to:
  /// **'Facebook Post (1200×630)'**
  String get invSizeFacebookPost;

  /// No description provided for @invExportFormatPNG.
  ///
  /// In ar, this message translates to:
  /// **'PNG (للسوشيال ميديا)'**
  String get invExportFormatPNG;

  /// No description provided for @invExportFormatPDF.
  ///
  /// In ar, this message translates to:
  /// **'PDF (للطباعة)'**
  String get invExportFormatPDF;

  /// No description provided for @invExportFormatBoth.
  ///
  /// In ar, this message translates to:
  /// **'PNG + PDF'**
  String get invExportFormatBoth;

  /// No description provided for @invBulkModeTitle.
  ///
  /// In ar, this message translates to:
  /// **'دعوات شخصية جماعية'**
  String get invBulkModeTitle;

  /// No description provided for @invBulkModeHint.
  ///
  /// In ar, this message translates to:
  /// **'كارت واحد لكل اسم — تصدير فردي.'**
  String get invBulkModeHint;

  /// No description provided for @invPreviewTitle.
  ///
  /// In ar, this message translates to:
  /// **'معاينة أول 3 نسخ'**
  String get invPreviewTitle;

  /// No description provided for @invExportFormat.
  ///
  /// In ar, this message translates to:
  /// **'صيغة التصدير'**
  String get invExportFormat;

  /// No description provided for @invNameFieldMissing.
  ///
  /// In ar, this message translates to:
  /// **'هذا القالب لا يحتوي على حقل الاسم'**
  String get invNameFieldMissing;

  /// No description provided for @invDuplicateNames.
  ///
  /// In ar, this message translates to:
  /// **'أسماء مكررة: {count}'**
  String invDuplicateNames(Object count);

  /// No description provided for @invEmptyNames.
  ///
  /// In ar, this message translates to:
  /// **'خلايا فارغة: {count} — ستُتخطى'**
  String invEmptyNames(Object count);

  /// No description provided for @invZIPOption.
  ///
  /// In ar, this message translates to:
  /// **'ضغط في ملف ZIP'**
  String get invZIPOption;

  /// No description provided for @invIndexCSVOption.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء فهرس CSV'**
  String get invIndexCSVOption;

  /// No description provided for @invProgressText.
  ///
  /// In ar, this message translates to:
  /// **'تم توليد {done} من {total}'**
  String invProgressText(Object done, Object total);

  /// No description provided for @navEditors.
  ///
  /// In ar, this message translates to:
  /// **'المحرّكات'**
  String get navEditors;

  /// No description provided for @navLibraries.
  ///
  /// In ar, this message translates to:
  /// **'المكتبات'**
  String get navLibraries;

  /// No description provided for @navAdmin.
  ///
  /// In ar, this message translates to:
  /// **'الإدارة'**
  String get navAdmin;

  /// No description provided for @navUser.
  ///
  /// In ar, this message translates to:
  /// **'الحساب'**
  String get navUser;

  /// No description provided for @bpWorkTypeLabel.
  ///
  /// In ar, this message translates to:
  /// **'نوع القالب'**
  String get bpWorkTypeLabel;

  /// No description provided for @bpExportFormatLabel.
  ///
  /// In ar, this message translates to:
  /// **'نوع التصدير'**
  String get bpExportFormatLabel;

  /// No description provided for @bpKindInvitation.
  ///
  /// In ar, this message translates to:
  /// **'دعوة'**
  String get bpKindInvitation;

  /// No description provided for @invPackOptions.
  ///
  /// In ar, this message translates to:
  /// **'خيارات الإخراج'**
  String get invPackOptions;

  /// No description provided for @tplCertClassicTitle.
  ///
  /// In ar, this message translates to:
  /// **'شهادة كلاسيكية كحلية'**
  String get tplCertClassicTitle;

  /// No description provided for @tplCertClassicDesc.
  ///
  /// In ar, this message translates to:
  /// **'قالب كحلي كلاسيكي بإطار ذهبي مزدوج وزوايا مزخرفة بالنجوم.'**
  String get tplCertClassicDesc;

  /// No description provided for @tplCertMinimalTitle.
  ///
  /// In ar, this message translates to:
  /// **'شهادة مينيمال كحلية'**
  String get tplCertMinimalTitle;

  /// No description provided for @tplCertMinimalDesc.
  ///
  /// In ar, this message translates to:
  /// **'تصميم مينيمال كحلي نظيف بخط ذهبي واحد ومساحات واسعة.'**
  String get tplCertMinimalDesc;

  /// No description provided for @tplCertIslamicTitle.
  ///
  /// In ar, this message translates to:
  /// **'شهادة زخرفية إسلامية'**
  String get tplCertIslamicTitle;

  /// No description provided for @tplCertIslamicDesc.
  ///
  /// In ar, this message translates to:
  /// **'قالب كحلي بحواف ذهبية وزخارف هندسية إسلامية وخط أميري.'**
  String get tplCertIslamicDesc;

  /// No description provided for @tplCertBandTitle.
  ///
  /// In ar, this message translates to:
  /// **'شهادة الشرائط الذهبية'**
  String get tplCertBandTitle;

  /// No description provided for @tplCertBandDesc.
  ///
  /// In ar, this message translates to:
  /// **'قالب كحلي بشرائط ذهبية أفقية أعلى وأسفل وتذييل منسّق.'**
  String get tplCertBandDesc;

  /// No description provided for @tplCertDiagonalTitle.
  ///
  /// In ar, this message translates to:
  /// **'شهادة ديناميكية مائلة'**
  String get tplCertDiagonalTitle;

  /// No description provided for @tplCertDiagonalDesc.
  ///
  /// In ar, this message translates to:
  /// **'قالب كحلي بأشكال هندسية ذهبية مائلة وإحساس بالحركة.'**
  String get tplCertDiagonalDesc;

  /// No description provided for @tplCertSquareTitle.
  ///
  /// In ar, this message translates to:
  /// **'شهادة مربعة أنيقة'**
  String get tplCertSquareTitle;

  /// No description provided for @tplCertSquareDesc.
  ///
  /// In ar, this message translates to:
  /// **'قالب كحلي بإطار ذهبي مربّع متناظر وختم دائري علوي.'**
  String get tplCertSquareDesc;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'de',
    'en',
    'es',
    'fr',
    'id',
    'ru',
    'tr',
    'ur',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'id':
      return AppLocalizationsId();
    case 'ru':
      return AppLocalizationsRu();
    case 'tr':
      return AppLocalizationsTr();
    case 'ur':
      return AppLocalizationsUr();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
