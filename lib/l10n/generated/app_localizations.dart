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

  /// No description provided for @dashRoadmapSupabase.
  ///
  /// In ar, this message translates to:
  /// **'تأسيس قاعدة بيانات Supabase (جداول + RLS + Triggers)'**
  String get dashRoadmapSupabase;

  /// No description provided for @dashRoadmapModular.
  ///
  /// In ar, this message translates to:
  /// **'هيكل Modular Feature-First قابل للتوسّع'**
  String get dashRoadmapModular;

  /// No description provided for @dashRoadmapTheme.
  ///
  /// In ar, this message translates to:
  /// **'الثيم البصري للهوية ودعم RTL بخط Cairo'**
  String get dashRoadmapTheme;

  /// No description provided for @dashRoadmapAuth.
  ///
  /// In ar, this message translates to:
  /// **'المصادقة: تسجيل الدخول وإنشاء الحساب واستعادة كلمة المرور'**
  String get dashRoadmapAuth;

  /// No description provided for @dashPhaseOneDone.
  ///
  /// In ar, this message translates to:
  /// **'المرحلة الأولى مكتملة'**
  String get dashPhaseOneDone;

  /// No description provided for @dashNextPhase.
  ///
  /// In ar, this message translates to:
  /// **'التالية: محرك PDF والخطوط العربية أوفلاين، ثم محرر القوالب البصري.'**
  String get dashNextPhase;

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
