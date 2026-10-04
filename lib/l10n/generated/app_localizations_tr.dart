// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTagline =>
      'Resmî sertifika ve sözleşmeleri çevrimdışı oluşturun';

  @override
  String get navDashboard => 'Kontrol Paneli';

  @override
  String get navCertificates => 'Sertifika Oluşturucu';

  @override
  String get navContracts => 'Sözleşme Oluşturucu';

  @override
  String get navBatch => 'Toplu Üretim';

  @override
  String get navTemplates => 'Şablon Kitaplığı';

  @override
  String get navAssets => 'Varlıklar ve İmzalar';

  @override
  String get actionSignOut => 'Çıkış yap';

  @override
  String get actionBackToDashboard => 'Kontrol paneline dön';

  @override
  String get offlineProcessingLabel => 'Yerel işleme';

  @override
  String get themeTooltip => 'Temayı değiştir';

  @override
  String get themeSystem => 'Sistem';

  @override
  String get themeLight => 'Açık';

  @override
  String get themeDark => 'Koyu';

  @override
  String get languageTooltip => 'Dili değiştir';

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
  String get configMissingKeysTitle => 'Bağlantı anahtarları bulunamadı';

  @override
  String get configMissingKeysBody =>
      'Uygulama başlangıçta anahtarları üç kaynakta arar: --dart-define bayrağı, ardından diskteki env.json dosyası (kök veya assets/env/) ve son olarak uygulamaya gömülü kopya — hiçbiri bulunamadı. Dosyayı oluşturun, bir kez doldurun ve bayraksız çalıştırın:';

  @override
  String get configEnvNote =>
      'Paket assets/env/ klasörünü varlık olarak tanımlar, bu nedenle dosyanın yokluğu temiz bir derlemeyi bozmaz. env.example.json\'dan oluşturun veya şunu çalıştırın: dart run tool/ensure_env.dart — yalnızca anon/public anahtarı gerekir; service_role uygulamada hiç kullanılmaz.';

  @override
  String get routeNotFoundTitle => 'Sayfa bulunamadı';

  @override
  String get routeNotFoundBody => 'İstenen yol uygulamada tanımlı değil:';

  @override
  String get editorPrecisionTitle => 'Hassas ayarlar';

  @override
  String get editorNudgeStep => 'Kaydırma adımı';

  @override
  String get editorNudgeStepHint => 'Tuvaldeki oklar da Shift = 10px kaydırır.';

  @override
  String get editorNudgeUp => 'Yukarı kaydır';

  @override
  String get editorNudgeLeft => 'Sola kaydır';

  @override
  String get editorNudgeDown => 'Aşağı kaydır';

  @override
  String get editorNudgeRight => 'Sağa kaydır';

  @override
  String get editorScale => 'Ölçek';

  @override
  String get editorScaleHint =>
      'Öğe merkezine göre göreli ölçekleme (daha ince adım için düğmelerde tekerlek).';

  @override
  String get editorScaleUp => 'Büyüt';

  @override
  String get editorScaleDown => 'Küçült';

  @override
  String get editorDecorTitle => 'Vektör süsleme';

  @override
  String get editorDecorKind => 'Süsleme türü';

  @override
  String get editorDecorPalette => 'Renk paleti';

  @override
  String get editorDecorLayers => 'Katman sayısı';

  @override
  String get editorDecorSeed => 'Tohum';

  @override
  String get editorDecorThickness => 'Kalınlık';

  @override
  String get editorDecorPrimary => 'Ana renk';

  @override
  String get editorDecorSecondary => 'İkincil renk';

  @override
  String get editorDecorAccent => 'Vurgu rengi';

  @override
  String get editorDecorGradient => 'Katman geçişi';

  @override
  String get editorDecorGallery => 'Hazır ayarlar';

  @override
  String get editorDecorGalleryTitle => 'Hazır süsleme galerisi';

  @override
  String get editorClose => 'Kapat';

  @override
  String get editorDecorPaletteCustom => 'Özel';

  @override
  String get decorKindModernWave => 'Modern dalgalar';

  @override
  String get decorKindPaperCut => 'Katmanlı kâğıt kesimi';

  @override
  String get decorKindClassicCorner => 'Klasik süslü çerçeve';

  @override
  String get decorKindGuilloche => 'Guilloche deseni';

  @override
  String get decorKindRibbonBanner => 'Şerit / flama';

  @override
  String get decorPaletteRoyalGold => 'Kraliyet altını';

  @override
  String get decorPaletteRoyalBlue => 'Kraliyet mavisi';

  @override
  String get decorPaletteEmerald => 'Zümrüt';

  @override
  String get decorPaletteBurgundy => 'Bordo';

  @override
  String get decorPaletteMidnight => 'Gece lacivert';

  @override
  String get decorPaletteMono => 'Tek renk gri';

  @override
  String get editorSignatureTitle => 'İmza bloğu';

  @override
  String get editorSignatureCount => 'İmza sayısı';

  @override
  String get signatureCountOne => 'Tek imza';

  @override
  String get signatureCountTwo => 'İki imza';

  @override
  String get signatureCountThree => 'Üç imza';

  @override
  String get editorSignatureOrder => 'Alan sırası';

  @override
  String get editorSignatureOrderHint =>
      'Arapça belgelerde ilk alan en sağda yer alır.';

  @override
  String get editorSignatureFirstRight => 'İlki sağda';

  @override
  String get editorSignatureFirstLeft => 'İlki solda';

  @override
  String get editorDirectionAuto => 'Otomatik';

  @override
  String get editorSignatureImageAlign => 'Görsel hizası';

  @override
  String get editorAlignStart => 'Başlangıç';

  @override
  String get editorAlignCenter => 'Orta';

  @override
  String get editorAlignEnd => 'Son';

  @override
  String get editorSignatureDivider => 'İmza çizgisi';

  @override
  String get editorVisible => 'Görünür';

  @override
  String get editorHidden => 'Gizli';

  @override
  String get editorSignatureNameSize => 'İsim boyutu';

  @override
  String get editorSignatureRoleSize => 'Görev boyutu';

  @override
  String get editorSignatureSpacing => 'Aralık';

  @override
  String get editorSignatureImageSize => 'Görsel boyutu';

  @override
  String get editorSignatureNameColor => 'İsim rengi';

  @override
  String get editorSignatureRoleColor => 'Görev rengi';

  @override
  String get editorFont => 'Yazı tipi';

  @override
  String get editorImageSource => 'Görsel kaynağı';

  @override
  String get imageSourceAppAssets => 'Uygulama varlıkları';

  @override
  String get imageSourceMyLibrary => 'Varlık kitaplığım';

  @override
  String get imageSourceLocalFile => 'Yerel dosya';

  @override
  String get imageSourceEmbedded => 'Gömülü veri';

  @override
  String get editorSignatureChangeImage => 'İmza görselini değiştir';

  @override
  String get editorSignatureAddImage => 'İmza görseli ekle';

  @override
  String get editorSignatureRemoveImage => 'İmza görselini kaldır';

  @override
  String get editorSignaturePickImageTitle =>
      'Varlık kitaplığımdan imza görseli seç';

  @override
  String get editorSignatureSlot => 'Alan';

  @override
  String get editorSignatureRoleField => 'Görev (örn. Genel Müdür)';

  @override
  String get editorSignatureNameField =>
      'İmzalayan adı (dinamik alan kabul eder)';

  @override
  String get editorFromMyLibrary => 'Varlık kitaplığımdan';

  @override
  String get paletteSignatureBlock => 'İmzalar';

  @override
  String get editorInsertFromLibraryTooltip =>
      'Yüklenen çerçeveyi veya logoyu doğrudan ekle';

  @override
  String get unsupportedElementVersionNote =>
      'Bu öğe düzenleyicinin daha yeni bir sürümünden — olduğu gibi korunur ve burada düzenlenemez.';

  @override
  String editorSelectedCount(Object count) {
    return '$count seçili';
  }

  @override
  String get editorClearSelection => 'Seçimi temizle';

  @override
  String get editorGroup => 'Grup';

  @override
  String get editorOpacity => 'Opaklık';

  @override
  String get editorBringToFront => 'Öne getir';

  @override
  String get editorSendToBack => 'Arkaya gönder';

  @override
  String get editorDuplicate => 'Çoğalt';

  @override
  String get editorDeleteSelected => 'Seçileni sil';

  @override
  String get editorGroupDragHint =>
      'Grubu fareyle sürükleyin, ince kaydırma için okları kullanın (Shift = 10px) ve seçimi ayarlamak için Ctrl + tıklayın.';

  @override
  String get editorBringForward => 'Öne al';

  @override
  String get editorDuplicateElement => 'Öğeyi çoğalt';

  @override
  String get editorDeleteElement => 'Öğeyi sil';

  @override
  String get editorPageSettings => 'Sayfa ayarları';

  @override
  String get editorPageSize => 'Boyut';

  @override
  String get editorUnit => 'Birim';

  @override
  String get editorWidth => 'Genişlik';

  @override
  String get editorHeight => 'Yükseklik';

  @override
  String get editorLabelText => 'Metin';

  @override
  String get editorLabelShape => 'Şekil';

  @override
  String get editorLabelSeal => 'Mühür';

  @override
  String get editorLabelDecoration => 'Vektör süsleme';

  @override
  String get editorLabelSignature => 'İmza bloğu';

  @override
  String get editorLabelImage => 'Görsel / logo';

  @override
  String get editorLabelQr => 'QR kodu';

  @override
  String get editorLabelUnknown => 'Desteklenmeyen öğe';

  @override
  String get editorLabelDynamicField => 'Dinamik alan';

  @override
  String get editorPositionAndSize => 'Konum ve boyut';

  @override
  String get editorPosX => 'X';

  @override
  String get editorPosY => 'Y';

  @override
  String get editorRotation => 'Döndürme';

  @override
  String get editorTextFormat => 'Metin biçimlendirme';

  @override
  String get editorConvertToField => 'Dinamik alana dönüştür';

  @override
  String get editorFontWeight => 'Kalınlık';

  @override
  String get editorWeightRegular => 'Normal';

  @override
  String get editorWeightSemiBold => 'Orta';

  @override
  String get editorWeightBold => 'Kalın';

  @override
  String get editorFontSize => 'Yazı tipi boyutu';

  @override
  String get editorLetterSpacing => 'Harf aralığı';

  @override
  String get editorLineHeight => 'Satır yüksekliği';

  @override
  String get editorTextColor => 'Metin rengi';

  @override
  String get editorTextBackground => 'Metin arka planı';

  @override
  String get editorTextAlign => 'Hizalama';

  @override
  String get editorAlignJustify => 'İki yana yasla';

  @override
  String get editorJustifyMode => 'Yaslama yöntemi';

  @override
  String get editorJustifyHint =>
      'Keşide PDF dosyasında uygulanır (önizleme boşluk yaslamayı gösterir)';

  @override
  String get editorJustifySpaces => 'Boşluklar';

  @override
  String get editorJustifyKashida => 'Keşide';

  @override
  String get editorVerticalAlign => 'Dikey hizalama';

  @override
  String get editorVerticalTop => 'Üst';

  @override
  String get editorVerticalBottom => 'Alt';

  @override
  String get editorDirection => 'Yön';

  @override
  String get editorDirectionHint => 'Geçiş kısayolu: Ctrl+Shift+D';

  @override
  String get editorDirectionRtl => 'Arapça (RTL)';

  @override
  String get editorDirectionLtr => 'Latin (LTR)';

  @override
  String get editorImage => 'Görsel';

  @override
  String get editorSource => 'Kaynak';

  @override
  String get editorImageFit => 'Görsel sığdırma';

  @override
  String get editorFitContain => 'Sığdır';

  @override
  String get editorFitCover => 'Kapla';

  @override
  String get editorFitFill => 'Uzat';

  @override
  String get assetPickerEmptyHint =>
      'Henüz varlık yüklemediniz. Burada ve baskıda kullanmak için bir logo, imza veya mühür yükleyin.';

  @override
  String get assetPickerNoneOption => 'Yok (başka kaynak)';

  @override
  String get assetPickerTitle => 'Varlık kitaplığımdan görsel seç';

  @override
  String assetUploadType(Object type) {
    return '$type yükle';
  }

  @override
  String get editorSeal => 'Mühür';

  @override
  String get editorSealColor => 'Mühür rengi';

  @override
  String get editorSealRingColor => 'Halka rengi';

  @override
  String get editorSealStarColor => 'Yıldız rengi';

  @override
  String get editorSealStarSize => 'Yıldız boyutu';

  @override
  String get editorShape => 'Şekil';

  @override
  String get editorFillColor => 'Dolgu rengi';

  @override
  String get editorBorderColor => 'Kenarlık rengi';

  @override
  String get editorBorderWidth => 'Kenarlık kalınlığı';

  @override
  String get editorCornerRadius => 'Köşe yarıçapı';

  @override
  String get editorQrVerify => 'Doğrulama kodu';

  @override
  String get editorQrData => 'Kod verisi';

  @override
  String get editorQrColor => 'Kod rengi';

  @override
  String get editorQrBackground => 'Kod arka planı';

  @override
  String editorConvertDialogMessage(Object text) {
    return 'Dönüştürme, “$text” metnini toplu üretimde bağlanabilen dinamik bir işarete çevirir.';
  }

  @override
  String get editorFieldKeyHint => 'Alan anahtarı (örn. ad, tarih, referans)';

  @override
  String get editorCustomKeyHint =>
      'Özel bir anahtar girin (süslü parantez olmadan — otomatik eklenir)';

  @override
  String get editorCancel => 'İptal';

  @override
  String get editorConvert => 'Dönüştür';

  @override
  String get editorPath => 'Yol';

  @override
  String get editorTextContent => 'Metin içeriği';

  @override
  String editorInsertFieldToken(Object token) {
    return '$token ekle';
  }

  @override
  String editorAddLabel(Object label) {
    return '$label ekle';
  }

  @override
  String assetInsertedSnack(Object name) {
    return '“$name” şablona eklendi.';
  }

  @override
  String get paletteHeading => 'Başlık';

  @override
  String get paletteFrame => 'Dikdörtgen / çerçeve';

  @override
  String get paletteDivider => 'Ayırıcı';

  @override
  String get paletteLogo => 'Logo / imza';
}
