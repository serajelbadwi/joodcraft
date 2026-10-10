import '../../l10n/generated/app_localizations.dart';
import '../../l10n/generated/app_localizations_ar.dart';
import '../../l10n/generated/app_localizations_de.dart';
import '../../l10n/generated/app_localizations_en.dart';
import '../../l10n/generated/app_localizations_es.dart';
import '../../l10n/generated/app_localizations_fr.dart';
import '../../l10n/generated/app_localizations_id.dart';
import '../../l10n/generated/app_localizations_ru.dart';
import '../../l10n/generated/app_localizations_tr.dart';
import '../../l10n/generated/app_localizations_ur.dart';
import '../../l10n/generated/app_localizations_zh.dart';

/// عنوان/وصف القوالب الجاهزة من ملفات الترجمة (ARB) بدل النصّ الثابت.
///
/// **لماذا ملف منفصل؟** القوالب الجاهزة تحمل `titleAr`/`descriptionAr` عربيين
/// كمصدر احتياطي دائم (بلا شبكة وبلا اعتماد على الترجمة)، وتبقى تلك هي القيمة
/// المعروضة عند غياب أي مفتاح ترجمة. لكن عناوين القوالب وأوصافها **نصوص واجهة**
/// (بطاقات المكتبة، نوافذ المعاينة، رسائل التصدير) لا محتوى مستند — ومكانها
/// الطبيعي ملفات ARB كبقية نصوص الواجهة.
///
/// **لماذا خريطة ثابتة يدوية؟** الوصول إلى `AppLocalizations` يمرّ إمّا
/// بـ`AppLocalizations.of(context)` (يحتاج سياقاً) أو بـ`load()` غير المتزامن،
/// بينما `PresetTemplate` كائن نقيّ في طبقة `core` يُستدعى من
/// `titleFor(languageCode)` بلا سياق ومتزامناً. الخريطة أدناه تربط رمز اللغة
/// بالكلاس المولَّد المقابل، فيبقى الاستدعاء متزامناً وآمن النوع بلا انعكاس.
///
/// إضافة قالب جديد بلوحة مفاتيح ARB = سطرين في `switch` هنا + مفاتيحه في
/// كل ملف ARB من اللغات العشر.
abstract final class PresetUiText {
  const PresetUiText._();

  /// عنوان القالب المترجم من ARB — أو `null` إن لم يكن للقالب مفتاح.
  ///
  /// تعيد `null` (لا النصّ العربي) ليقرّر `PresetTemplate` بنفسه الرجوع إلى
  /// `titleAr` أو إلى حزمة ترجمة محتوى المستند.
  static String? title(String? languageCode, String presetId) {
    final AppLocalizations? l = localizations(languageCode);
    if (l == null) return null;
    return switch (presetId) {
      'classic_navy_gold_certificate' => l.tplCertClassicTitle,
      'minimal_navy_gold_certificate' => l.tplCertMinimalTitle,
      'islamic_ornament_navy_gold_certificate' => l.tplCertIslamicTitle,
      'gold_band_navy_certificate' => l.tplCertBandTitle,
      'dynamic_diagonal_navy_gold_certificate' => l.tplCertDiagonalTitle,
      'square_elegant_navy_gold_certificate' => l.tplCertSquareTitle,
      _ => null,
    };
  }

  /// وصف القالب المترجم من ARB — أو `null` إن لم يكن للقالب مفتاح.
  static String? description(String? languageCode, String presetId) {
    final AppLocalizations? l = localizations(languageCode);
    if (l == null) return null;
    return switch (presetId) {
      'classic_navy_gold_certificate' => l.tplCertClassicDesc,
      'minimal_navy_gold_certificate' => l.tplCertMinimalDesc,
      'islamic_ornament_navy_gold_certificate' => l.tplCertIslamicDesc,
      'gold_band_navy_certificate' => l.tplCertBandDesc,
      'dynamic_diagonal_navy_gold_certificate' => l.tplCertDiagonalDesc,
      'square_elegant_navy_gold_certificate' => l.tplCertSquareDesc,
      _ => null,
    };
  }

  /// الترجمات المولَّدة للغة المطلوبة (العربية عند غيابها أو عدم دعمها).
  ///
  /// الكلاسات المولَّدة بناة عاديون بلا حالة، فالإنشاء رخيص وآمن للنداء المتكرر.
  static AppLocalizations? localizations(String? languageCode) {
    final String code = (languageCode ?? 'ar').trim().toLowerCase();
    final int dash = code.indexOf(RegExp('[-_]'));
    final String short = dash == -1 ? code : code.substring(0, dash);
    return switch (short) {
      'ar' => AppLocalizationsAr(),
      'de' => AppLocalizationsDe(),
      'en' => AppLocalizationsEn(),
      'es' => AppLocalizationsEs(),
      'fr' => AppLocalizationsFr(),
      'id' => AppLocalizationsId(),
      'ru' => AppLocalizationsRu(),
      'tr' => AppLocalizationsTr(),
      'ur' => AppLocalizationsUr(),
      'zh' => AppLocalizationsZh(),
      _ => AppLocalizationsAr(),
    };
  }
}
