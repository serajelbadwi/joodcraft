// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get editorDone => 'Tamam';

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
  String get actionOpenMenu => 'Menü';

  @override
  String get editorFitToScreen => 'Ekrana sığdır';

  @override
  String get editorNewTemplate => 'Yeni şablon';

  @override
  String get editorNewConfirm =>
      'Yeni şablon varsayılan tasarımla başlar; kaydedilmemiş değişiklikler geri alma geçmişinde kalır. Devam?';

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
  String get destBrand => 'Kimlik ve profil';

  @override
  String get destBrandDesc =>
      'Logonuz, kaşeleriniz, imzalarınız ve marka renkleriniz.';

  @override
  String get brandTitle => 'Kimlik ve profil ayarları';

  @override
  String get brandTabVisuals => 'Görsel kimlik';

  @override
  String get brandTabText => 'Metin verileri';

  @override
  String get brandTabColors => 'Renkler ve yazı tipleri';

  @override
  String get brandTabPreview => 'Kimlik önizlemesi';

  @override
  String get brandPrimaryLogo => 'Ana logo';

  @override
  String get brandWatermarkLogo => 'Filigran logo';

  @override
  String get brandSeals => 'Resmî kaşeler';

  @override
  String get brandAddSeal => 'Kaşe ekle';

  @override
  String get brandSealName => 'Kaşe adı';

  @override
  String get brandSignatures => 'Yetkili imzalar';

  @override
  String get brandAddSignature => 'İmza ekle';

  @override
  String get brandSignatureName => 'İmzalayan adı';

  @override
  String get brandSignatureTitle => 'Görev';

  @override
  String get brandRemove => 'Kaldır';

  @override
  String get brandNoSeals => 'Henüz kaşe eklenmedi.';

  @override
  String get brandNoSignatures => 'Henüz imza eklenmedi.';

  @override
  String get brandOrgNameAr => 'Kurum adı (Arapça)';

  @override
  String get brandOrgNameEn => 'Kurum adı (İngilizce)';

  @override
  String get brandHeaderText => 'Başlık metni';

  @override
  String get brandFooterText => 'Altbilgi metni';

  @override
  String get brandRegNumber => 'Vergi / sicil numarası';

  @override
  String get brandPrimaryColor => 'Ana renk';

  @override
  String get brandSecondaryColor => 'İkincil renk';

  @override
  String get brandAccentColor => 'Vurgu rengi';

  @override
  String get brandHeaderFont => 'Başlık yazı tipi';

  @override
  String get brandBodyFont => 'Gövde yazı tipi';

  @override
  String get brandClear => 'Kimliği temizle';

  @override
  String get brandClearConfirm =>
      'Kayıtlı tüm kimlik içeriği silinecek. Devam edilsin mi?';

  @override
  String get brandSaved => 'Kimlik kaydedildi.';

  @override
  String get brandPresets => 'Kimlik öğeleri';

  @override
  String get brandInsertHeader => 'Standart başlığı ekle';

  @override
  String get brandInsertFooter => 'Standart altbilgiyi ekle';

  @override
  String get brandApplyColors => 'Renkleri uygula';

  @override
  String get brandQuickSeals => 'Kaşeler';

  @override
  String get brandQuickSignatures => 'İmzalar';

  @override
  String get brandNoBrand => 'Kimliğiniz henüz ayarlanmadı.';

  @override
  String get brandOpenSettings => 'Kimlik ayarlarını aç';

  @override
  String get brandHeaderInserted => 'Standart başlık eklendi.';

  @override
  String get brandFooterInserted => 'Standart altbilgi eklendi.';

  @override
  String get brandColorsApplied => 'Renkler uygulandı.';

  @override
  String get brandSealInserted => 'Kaşe eklendi.';

  @override
  String get brandSignatureInserted => 'İmza eklendi.';

  @override
  String get brandFontDefault => 'Varsayılan';

  @override
  String get paletteShapes => 'Şekiller';

  @override
  String get paletteRoundedRect => 'Yuvarlatılmış dikdörtgen';

  @override
  String get paletteEllipse => 'Daire / elips';

  @override
  String get editorFillOpacity => 'Dolgu saydamlığı';

  @override
  String get editorCollapsePanel => 'Yan paneli daralt';

  @override
  String get editorExpandPanel => 'Yan paneli göster';

  @override
  String get editorCustomSize => 'Özel boyut';

  @override
  String get editorStandardSize => 'Standart boyut';

  @override
  String get editorBackgroundTitle => 'Sayfa arka planı';

  @override
  String get editorGradientFrom => 'Başlangıç';

  @override
  String get editorGradientTo => 'Bitiş';

  @override
  String get editorGradientDirection => 'Yön';

  @override
  String get editorGradientNone => 'Degrade yok';

  @override
  String get editorGradientVertical => 'Dikey';

  @override
  String get editorGradientHorizontal => 'Yatay';

  @override
  String get editorGradientDiagonal => 'Çapraz';

  @override
  String get editorLayersTitle => 'Katmanlar';

  @override
  String get editorLayerShow => 'Öğeyi göster';

  @override
  String get editorLayerHide => 'Öğeyi gizle';

  @override
  String get editorLayerLock => 'Öğeyi kilitle';

  @override
  String get editorLayerUnlock => 'Öğenin kilidini aç';

  @override
  String get editorLayersEmpty => 'Bu sayfada henüz öğe yok.';

  @override
  String get editorGroupSelected => 'Seçimi grupla';

  @override
  String get editorUngroupSelected => 'Grubu çöz';

  @override
  String get editorAlignLeft => 'Sola hizala';

  @override
  String get editorAlignCenterH => 'Yatay ortala';

  @override
  String get editorAlignRight => 'Sağa hizala';

  @override
  String get editorAlignTop => 'Üste hizala';

  @override
  String get editorAlignCenterV => 'Dikey ortala';

  @override
  String get editorAlignBottom => 'Alta hizala';

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
  String get editorImageTint => 'Görsel rengi';

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

  @override
  String get evSignatureEmptyLabel => 'Boş imza';

  @override
  String get evSignatureEmptyDetail => 'Görev, ad ve imza görseli ekleyin';

  @override
  String get evSignatureMissingLabel => 'Eksik imza';

  @override
  String get evUploadToLibraryDetail => 'Görseli varlık kitaplığına yükleyin';

  @override
  String get evImageNotFoundLabel => 'Görsel bulunamadı';

  @override
  String get evNoFileLabel => 'Dosya seçilmedi';

  @override
  String get evChooseFromAssetsDetail => 'Varlık kitaplığından görsel seçin';

  @override
  String get evAssetMissingLabel => 'Eksik varlık';

  @override
  String get evReselectAssetDetail =>
      'Çerçeveyi/varlığı kitaplıktan yeniden seçin';

  @override
  String get evInvalidImageLabel => 'Geçersiz görsel';

  @override
  String get evRenderDataFailedDetail => 'Veriler gösterilemedi';

  @override
  String get evInvalidDataLabel => 'Geçersiz veri';

  @override
  String get evDecodeFailedDetail => 'Görsel çözülemedi';

  @override
  String get evEmptyQrLabel => 'Boş kod';

  @override
  String get evEmptyQrDetail => 'Kod değerini özellikler çubuğuna girin';

  @override
  String evUnknownElementLabel(Object type) {
    return 'Desteklenmeyen öğe: $type';
  }

  @override
  String get alpFilterAll => 'Tümü';

  @override
  String get alpEmptyHint =>
      'İstenen türlerde yüklenmiş varlık yok. “Varlıklar ve imzalar” bölümünden bir çerçeve veya logo yükleyin, sonra tekrar deneyin.';

  @override
  String alpNoFilteredAssets(Object type) {
    return '“$type” türünde varlık yok.';
  }

  @override
  String get authWelcomeBack => 'JoodCraft’a hoş geldiniz.';

  @override
  String get authResetLinkSent =>
      'Sıfırlama bağlantısı gönderildi. E-postanızı kontrol edin.';

  @override
  String get authLogin => 'Giriş yap';

  @override
  String get authLoginSubtitle =>
      'Kontrol paneline devam etmek için e-posta ve parolanız.';

  @override
  String get authNoAccount => 'Hesabınız yok mu?';

  @override
  String get authCreateAccountLink => 'Yeni hesap oluştur';

  @override
  String get authConfirmEmailThenLogin =>
      'Hesabınız oluşturuldu. Lütfen önce e-postanızı doğrulayın, sonra giriş yapın.';

  @override
  String get authEmail => 'E-posta';

  @override
  String get authPassword => 'Parola';

  @override
  String get authForgotPassword => 'Parolanızı mı unuttunuz?';

  @override
  String get authEnterDashboard => 'Panoya gir';

  @override
  String get authResetPassword => 'Parolayı sıfırla';

  @override
  String get authResetPasswordHint =>
      'E-postanızı girin, size bir parola sıfırlama bağlantısı göndereceğiz.';

  @override
  String get authSendLink => 'Bağlantıyı gönder';

  @override
  String get authConfirmEmailMessage =>
      'Hesabınız oluşturuldu. Doğrulamak için e-postanızı kontrol edin, sonra giriş yapın.';

  @override
  String get authAccountCreatedWelcome =>
      'Hesabınız oluşturuldu. JoodCraft’a hoş geldiniz.';

  @override
  String get authCreateAccount => 'Hesap oluştur';

  @override
  String get authRegisterSubtitle =>
      'Hesabınız şablonlarınızı ve varlıklarınızı (logo, imza, mühür) tüm projelerinizde yeniden kullanmak üzere saklar.';

  @override
  String get authHaveAccount => 'Hesabınız var mı?';

  @override
  String get authFullName => 'Ad soyad';

  @override
  String get authFullNameHint => 'örn. Abdullah Al-Ahmad';

  @override
  String get authName => 'Ad';

  @override
  String get authOrgName => 'Kurum adı (isteğe bağlı)';

  @override
  String get authOrgNameHint => 'örn. Jood Hayır Derneği';

  @override
  String get authOrgHelper =>
      'Sertifikalara ve sözleşmelere otomatik olarak yazdırılır.';

  @override
  String get authOrgNameShort => 'Kurum adı';

  @override
  String get authPasswordHint => 'En az 8 karakter';

  @override
  String authPasswordRule(Object min) {
    return 'En az $min karakter, sayı ve sembol kullanın.';
  }

  @override
  String get authConfirmPassword => 'Parolayı doğrula';

  @override
  String get authCreateAccountButton => 'Hesabı oluştur';

  @override
  String get authFeatureLocalExcel =>
      'Excel dosyalarının tamamen yerel işlenmesi — verileriniz cihazınızdan çıkmaz';

  @override
  String get authFeaturePdf =>
      'Yüksek kaliteli Arapça yazı tipleriyle PDF üretimi ve tam RTL desteği';

  @override
  String get authFeatureTemplates =>
      'Şablonlarınız hesabınızda saklanır ve yeniden kullanıma hazırdır';

  @override
  String get authTagline =>
      'Resmî sertifika ve sözleşmeleriniz… güvenle bastırılır.';

  @override
  String authVersion(Object name, Object version) {
    return '$name • Sürüm $version';
  }

  @override
  String get dashModules => 'Platform modülleri';

  @override
  String dashWelcome(Object name) {
    return 'Hoş geldiniz, $name';
  }

  @override
  String dashSubscription(Object tier) {
    return 'Abonelik: $tier';
  }

  @override
  String dashOrg(Object name) {
    return 'Kurum: $name';
  }

  @override
  String get dashOrgMissing =>
      'Kurum adınızı henüz ayarlamadınız — sertifika ve sözleşmelere otomatik yazdırılacaktır.';

  @override
  String get dashOpenModule => 'Modülü aç';

  @override
  String get destDashboard => 'Kontrol paneli';

  @override
  String get destDashboardDesc =>
      'Projelerinize ve şablonlarınıza genel bakış.';

  @override
  String get destCertificates => 'Sertifika motoru';

  @override
  String get destCertificatesDesc =>
      'Düzenlenebilir bir şablondan yatay (Landscape) sertifikalar tasarlayın.';

  @override
  String get destContracts => 'Sözleşme motoru';

  @override
  String get destContractsDesc =>
      'Dinamik alanlarla dikey (Portrait) sözleşmeler hazırlayın.';

  @override
  String get destBatch => 'Toplu üretim';

  @override
  String get destBatchDesc =>
      'Bir Excel dosyasını yerel olarak okuyun ve yüzlerce sertifikayı tek seferde üretin.';

  @override
  String get destTemplates => 'Şablon kitaplığı';

  @override
  String get destTemplatesDesc =>
      'Kaydedilen şablonlarınızı yönetin, sınıflandırın ve yeniden kullanın.';

  @override
  String get destAssets => 'Varlıklar ve imzalar';

  @override
  String get destAssetsDesc => 'Logonuz, mührünüz, imzanız ve çerçeveleriniz.';

  @override
  String get dashUser => 'Kullanıcı';

  @override
  String get dashLogoutSuccess => 'Başarıyla çıkış yaptınız.';

  @override
  String get dashLogoutError => 'Çıkış yapılamadı. Lütfen tekrar deneyin.';

  @override
  String get commonSave => 'Kaydet';

  @override
  String get commonPreview => 'Önizleme';

  @override
  String get commonOptions => 'Seçenekler';

  @override
  String get tplDelete => 'Sil';

  @override
  String get tplSortRecentlyUpdated => 'Son değiştirilenler';

  @override
  String get tplSortTitleAsc => 'Ad (A–Z)';

  @override
  String get tplSortLabel => 'Sırala';

  @override
  String get tplSubtitle =>
      'Profesyonel hazır şablonlar + kaydedilenler — arama, filtreleme, açma ve içe aktarma, tamamen çevrimdışı.';

  @override
  String get tplRefreshTooltip => 'Listeyi yenile';

  @override
  String get tplSearchHint => 'Şablonlarda ara…';

  @override
  String get tplNoResultsTitle => 'Eşleşen sonuç yok';

  @override
  String get tplNoResultsMessage =>
      'Başka bir arama terimi deneyin veya filtreyi sıfırlayın.';

  @override
  String tplAddedToLocal(Object title) {
    return '“$title” yerel şablonlarınıza eklendi.';
  }

  @override
  String get tplCloudRequiresConnection =>
      'Şablonları buluta kaydetmek bir Supabase projesine bağlantı gerektirir. Bunun yerine yerel kaydedin.';

  @override
  String tplSavedToCloud(Object title) {
    return '“$title” buluta kaydedildi.';
  }

  @override
  String get tplRenamed => 'Şablon yeniden adlandırıldı.';

  @override
  String tplCopySuffix(Object title) {
    return '$title (kopya)';
  }

  @override
  String tplCopyCreated(Object title) {
    return '“$title” kopyası oluşturuldu.';
  }

  @override
  String get tplNowPrivate => 'Şablon artık özel.';

  @override
  String get tplNowPublic => 'Şablon artık genel (başkaları için salt okunur).';

  @override
  String tplConfirmCloudDelete(Object title) {
    return '“$title” buluttan kalıcı olarak silinecek. Geri alınamaz.';
  }

  @override
  String tplCloudDeleted(Object title) {
    return '“$title” şablonu silindi.';
  }

  @override
  String tplConfirmLocalDelete(Object title) {
    return '“$title” bu cihazdan silinecek. Özgün hazır şablon kitaplıkta kullanılabilir kalır.';
  }

  @override
  String tplLocalDeleted(Object title) {
    return 'Yerel şablon “$title” silindi.';
  }

  @override
  String get tplDeleteTitle => 'Şablonu sil';

  @override
  String get tplRenameTitle => 'Şablon başlığı';

  @override
  String get tplFieldTitle => 'Başlık';

  @override
  String tplPreviewLabel(Object title) {
    return 'Önizleme: $title';
  }

  @override
  String tplCount(Object count) {
    return '$count şablon';
  }

  @override
  String tplCloudLoadError(Object message) {
    return 'Bulut şablonları yüklenemedi: $message';
  }

  @override
  String get tplPublicBadge => 'Genel şablon';

  @override
  String get tplOrientationLandscape => 'Yatay';

  @override
  String get tplOrientationPortrait => 'Dikey';

  @override
  String get tplPresetOffline => 'Hazır şablon • çevrimdışı kullanılabilir';

  @override
  String tplSchemaVersion(Object version) {
    return 'Şema v$version';
  }

  @override
  String get tplOpenAsTemplate => 'Şablon olarak aç';

  @override
  String get tplOpen => 'Aç';

  @override
  String get tplUseInBatch => 'Toplu üretimde kullan';

  @override
  String get tplImportLocal => 'Yerel içe aktar';

  @override
  String get tplSaveToCloud => 'Buluta kaydet';

  @override
  String get tplDeleteLocal => 'Yerel sil';

  @override
  String get tplRename => 'Yeniden adlandır';

  @override
  String get tplMakePrivate => 'Özel yap';

  @override
  String get tplMakePublic => 'Genel yap';

  @override
  String get tplNoDate => 'Tarih yok';

  @override
  String get amSubtitle =>
      'Logonuzu, mührünüzü ve imzanızı bir kez yükleyin, sonra herhangi bir şablona ekleyin — cihazınızda saklanır ve çevrimdışı kullanılır.';

  @override
  String get amSearchHint => 'Varlıklarda ara…';

  @override
  String get amTypeLabel => 'Tür';

  @override
  String get amUploadTooltip => 'Yeni varlık yükle';

  @override
  String get amUpload => 'Varlık yükle';

  @override
  String get amEmptyTitle => 'Henüz varlık yok';

  @override
  String get amEmptyMessage =>
      'Kurumunuzun logosunu, imzasını veya mührünü yükleyin, sonra görsel özellikleri çubuğundan herhangi bir şablona ekleyin.';

  @override
  String get amNoResultsMessage =>
      'Başka bir ad deneyin veya filtreyi sıfırlayın.';

  @override
  String get amRenamed => 'Varlık yeniden adlandırıldı.';

  @override
  String amMovedToType(Object type) {
    return 'Varlık “$type” konumuna taşındı.';
  }

  @override
  String get amDeleteTitle => 'Varlığı sil';

  @override
  String amConfirmDelete(Object name) {
    return '“$name” bu cihazdan silinecek. Kullanan şablonlar görseli kaybeder (baskı hatası olmadan).';
  }

  @override
  String amDeleted(Object name) {
    return '“$name” varlığı silindi.';
  }

  @override
  String get amRenameTitle => 'Varlığı yeniden adlandır';

  @override
  String amCount(Object count) {
    return '$count varlık';
  }

  @override
  String amMakeType(Object type) {
    return 'Türü yap: $type';
  }

  @override
  String get amCacheLabel => 'Diskteki görsel önbelleği';

  @override
  String amCacheUsage(Object count, Object size) {
    return '$count dosya · $size';
  }

  @override
  String amCacheUsageOf(Object count, Object used, Object limit) {
    return '$count dosya · $used / $limit';
  }

  @override
  String get amCacheEmpty => 'Henüz disk önbelleği yok';

  @override
  String get amCacheClear => 'Önbelleği temizle';

  @override
  String get amCacheCleared => 'Diskteki görsel önbelleği temizlendi.';

  @override
  String get commonRetry => 'Yeniden dene';

  @override
  String get commonPrint => 'Yazdır';

  @override
  String get commonExportPdf => 'PDF dışa aktar';

  @override
  String get commonExportFailed => 'PDF dosyası dışa aktarılamadı.';

  @override
  String get commonPrintFailed => 'Dosya yazıcıya gönderilemedi.';

  @override
  String commonExportReady(Object name) {
    return 'Dosya $name olarak kaydedilmeye hazır.';
  }

  @override
  String get commonGenerating => 'Üretiliyor…';

  @override
  String get commonDataPanelTitle => 'Örnek veriler';

  @override
  String evElementCount(Object count) {
    return '$count öğe';
  }

  @override
  String get evStatusDynamicFields => ' • dinamik alanlar';

  @override
  String get evStatusUnsaved => ' • kaydedilmemiş değişiklikler';

  @override
  String get tevNewTemplateTitle => 'Yeni şablon';

  @override
  String get tevUnsavedTitle => 'Kaydedilmemiş değişiklikler';

  @override
  String tevUnsavedMessage(Object title) {
    return '“$title” üzerinde kaydedilmemiş değişiklikleriniz var. Ayrılmadan önce kaydetmek ister misiniz?';
  }

  @override
  String get tevLeaveWithoutSaving => 'Kaydetmeden çık';

  @override
  String get tevSaveAndLeave => 'Kaydet ve çık';

  @override
  String get tevViewMode => 'Görünüm modu';

  @override
  String get tevModeEditor => 'Düzenleyici';

  @override
  String get tevModePreview => 'PDF önizleme';

  @override
  String get tevPaperDirection => 'Kâğıt yönü';

  @override
  String get tevWidthCm => 'Genişlik (cm)';

  @override
  String get tevHeightCm => 'Yükseklik (cm)';

  @override
  String get tevUndo => 'Geri al (Ctrl+Z)';

  @override
  String get tevRedo => 'Yinele (Ctrl+Y)';

  @override
  String get tevSnapGrid => 'Hizalama ızgarası';

  @override
  String get tevGuidesOn => 'Akıllı kılavuzlar: açık (kapat)';

  @override
  String get tevGuidesOff => 'Akıllı kılavuzlar: kapalı (aç)';

  @override
  String get tevZoom => 'Yakınlaştırma';

  @override
  String get tevDocumentBackground => 'Belge arka planı';

  @override
  String get tevFrameFromLibrary => 'Varlık kitaplığımdan çerçeve';

  @override
  String get tevChangeTitle => 'Şablon başlığını değiştir';

  @override
  String get tevMyTemplates => 'Şablonlarım';

  @override
  String get tevSaveAs => 'Farklı kaydet';

  @override
  String get tevSaveTemplate => 'Şablonu kaydet';

  @override
  String get tevSaveUnavailable => 'Kaydetme kullanılamıyor';

  @override
  String get tevSaveNeedsSupabase =>
      'Kaydetmek bir Supabase projesine bağlantı gerektirir. Şablonları kaydetmek için uygulamayı anahtarlarınızla (env.json) çalıştırın.';

  @override
  String tevMissingAssets(Object list) {
    return 'Eksik varlıklar: $list — boş görünmemesi için çerçeveyi/varlığı “Varlık kitaplığım”dan yeniden seçin.';
  }

  @override
  String get tevTemplateLibraryNeedsSupabase =>
      'Şablon kitaplığı bir Supabase projesine bağlantı gerektirir.';

  @override
  String tevOpenedTemplate(Object title) {
    return '“$title” açıldı.';
  }

  @override
  String get tevTitleHint => 'örn. Proje Yönetimi kursu tamamlama sertifikası';

  @override
  String get tevContinue => 'Devam';

  @override
  String get tevSavedTemplates => 'Kaydedilen şablonlarım';

  @override
  String get tevNoSavedTemplates =>
      'Henüz kaydedilmiş şablon yok. “Şablonu kaydet” düğmesinden bir tane kaydedin.';

  @override
  String get ecIncrease => 'Artır';

  @override
  String get ecDecrease => 'Azalt';

  @override
  String get ecQuickPalette => 'Hızlı palet';

  @override
  String get ecFullPicker => 'Tam renk seçici';

  @override
  String get ecRemoveColor => 'Rengi kaldır';

  @override
  String get ecNone => 'Yok';

  @override
  String get ecPickColorTitle => 'Renk seç';

  @override
  String get ecApply => 'Uygula';

  @override
  String tevBackgroundAdded(Object name) {
    return '“$name” belge arka planı olarak eklendi.';
  }

  @override
  String get cfpUploadTooltip => 'Özel yazı tipi yükle (.ttf / .otf)';

  @override
  String get cfpManageTooltip => 'Yüklenen yazı tiplerini yönet';

  @override
  String get cfpNotice =>
      'Yüklenen yazı tipleri yalnızca cihazınızda saklanır ve burada ve baskıda anında kullanılır — internetsiz.';

  @override
  String get cfpMyFonts => 'Özel yazı tiplerim';

  @override
  String get cfpNoFonts => 'Henüz yazı tipi yüklenmedi';

  @override
  String get cfpBuiltinOption => 'Yok (dahili yazı tipi)';

  @override
  String get cfpGroupBuiltin => 'Yerleşik yazı tipleri';

  @override
  String get cfpGroupUploaded => 'Yüklediğim yazı tipleri';

  @override
  String get cfpGroupSystem => 'Sistem yazı tipleri';

  @override
  String get cfpSearchHint => 'Yazı tipi ara…';

  @override
  String get cfpNoMatch => 'Eşleşen yazı tipi yok.';

  @override
  String get cfpPickTitle => 'Bir yazı tipi dosyası seç (TTF veya OTF)';

  @override
  String cfpPickerError(Object error) {
    return 'Dosya seçici açılamadı: $error';
  }

  @override
  String cfpReadError(Object name, Object error) {
    return '\"$name\" okunamadı: $error';
  }

  @override
  String get cfpFontAdded => 'Yazı tipi eklendi ve anında uygulandı.';

  @override
  String cfpFontsAdded(Object count) {
    return '$count yazı tipi eklendi.';
  }

  @override
  String get cfpLibraryTitle => 'Özel yazı tipi kitaplığım';

  @override
  String get cfpLibraryNotice =>
      'Tüm yazı tipleri yalnızca cihazınızda saklanır. Uyarı: bir şablonun kullandığı yazı tipini silmek, hata vermek yerine o şablonu dahili yazı tipine döndürür.';

  @override
  String get cfpEmpty => 'Henüz yüklenmiş yazı tipi yok.';

  @override
  String get cfpCoverageFull => 'Tam Arapça kapsam';

  @override
  String get cfpCoveragePartial => 'Kısmi Arapça kapsam';

  @override
  String get cfpUploadNew => 'Yeni yazı tipi yükle';

  @override
  String get ptpPrepError =>
      'Önizleme hazırlanamadı. Şablon dosyasını kontrol edin.';

  @override
  String ptpElapsedSize(Object ms, Object kb) {
    return '$ms ms — $kb KB';
  }

  @override
  String get ptpGeneratingNote => '— önizleme otomatik güncellenir';

  @override
  String get ptpGenerateFailedTitle => 'Önizleme oluşturulamadı';

  @override
  String get ptpPreparingTitle => 'Motor hazırlanıyor…';

  @override
  String get ptpPreparingMessage =>
      'Paketlenmiş yazı tipleri yükleniyor ve dosyanın ilk sürümü oluşturuluyor.';

  @override
  String get ptpShowFailedTitle => 'Önizleme gösterilemedi';

  @override
  String cfgOverride(Object override) {
    return 'Açık değerlerle alternatif derleme dosyayı geçersiz kılar: $override';
  }

  @override
  String get tevBackgroundTitle => 'Varlık kitaplığımdan belge arka planı';

  @override
  String get tevAddElement => 'Öğe ekle';

  @override
  String get commonUndo => 'Geri al';

  @override
  String get bpTitle => 'Excel’den toplu üretim';

  @override
  String get bpSubtitle =>
      'Bir .xlsx veya .csv dosyası içe aktarın, sütunlarını şablon alanlarıyla eşleştirin, sonra kayıt başına bir sayfa içeren bir PDF üretin — hepsi cihazınızda, çevrimdışı.';

  @override
  String get bpStepTemplate => '1) Şablon';

  @override
  String get bpLoadingSampleTemplate => 'Örnek şablon yükleniyor…';

  @override
  String bpTemplateInfo(Object name) {
    return 'Şablon: $name • gerekli alanlar:';
  }

  @override
  String get bpLoadingTemplates => 'Şablonlarınız yükleniyor…';

  @override
  String get bpNoTemplates =>
      'Henüz kaydedilmiş şablon yok — düzenleyicide oluşturun veya şablon kitaplığından içe aktarın.';

  @override
  String get bpTemplateFromMine => 'Şablonlarımdan şablon';

  @override
  String get bpSampleTemplatesHeader => '— örnek şablonlar —';

  @override
  String bpTemplateEntry(Object title, Object source) {
    return '$title  •  $source';
  }

  @override
  String get bpSourceCloud => 'Bulut';

  @override
  String get bpSourceLocal => 'Yerel';

  @override
  String get bpStepDataFile => '2) Veri dosyası';

  @override
  String get bpReadingFile => 'Dosya okunuyor…';

  @override
  String get bpNoFileChosen => 'Henüz dosya seçilmedi — desteklenen biçimler:';

  @override
  String bpFileSummary(Object name, Object rows, Object cols) {
    return '$name — $rows satır, $cols sütun';
  }

  @override
  String bpSheetSuffix(Object name) {
    return ' (sayfa: $name)';
  }

  @override
  String get bpChooseFile => 'Dosya seç';

  @override
  String get bpRemove => 'Kaldır';

  @override
  String get bpHeaderRow => 'Başlık satırı';

  @override
  String bpAutoRow(Object n) {
    return 'Otomatik (satır $n)';
  }

  @override
  String bpRow(Object n) {
    return 'Satır $n';
  }

  @override
  String bpAutoRowLong(Object n) {
    return 'Otomatik — satır $n';
  }

  @override
  String bpRowPreview(Object n, Object preview) {
    return 'Satır $n: $preview';
  }

  @override
  String get bpEmptyRow => '(boş satır)';

  @override
  String get bpWorksheet => 'Çalışma sayfası';

  @override
  String get bpPickDataFile => 'Veri dosyasını seç (Excel veya CSV)';

  @override
  String bpReadFileError(Object error) {
    return 'Dosya okunamadı: $error';
  }

  @override
  String bpFileReadRows(Object rows, Object cols) {
    return 'Dosya yerel olarak okundu: $rows satır ve $cols sütun.';
  }

  @override
  String bpSaveError(Object error) {
    return 'Değişiklik şablona kaydedilemedi: $error';
  }

  @override
  String get bpMapFieldTitle => 'Bu öğeye dinamik alan ata';

  @override
  String get bpMapFieldBody =>
      'Yalnızca bu öğenin metni bir alanla değiştirilir; başka hiçbir öğe etkilenmez.';

  @override
  String get bpUndoConvert => 'Dönüştürme geri alındı.';

  @override
  String get bpUndoConvertSaved =>
      'Dönüştürme geri alındı ve metin şablonda geri yüklendi.';

  @override
  String bpRestoreError(Object error) {
    return 'Metin şablonda geri yüklenemedi: $error';
  }

  @override
  String bpGeneratedReport(Object count) {
    return '$count kayıt üretildi';
  }

  @override
  String bpSkippedSuffix(Object count) {
    return ' ve $count atlandı';
  }

  @override
  String get bpReadyToSave => 'Dosya kaydedilmeye hazır.';

  @override
  String get bpStepMapping => '3) Sütunları alanlara eşle';

  @override
  String get bpChooseFileFirst => 'Eşleme tablosu için önce bir dosya seçin.';

  @override
  String get bpNoDynamicFields => 'Geçerli şablonda dinamik alan yok.';

  @override
  String bpMappedCount(Object mapped, Object total) {
    return '$total sütundan $mapped eşlendi';
  }

  @override
  String get bpAutoMapHint =>
      'Dosya seçildikten sonra akıllı otomatik eşleme önerilir; her sütunu düzenleyebilirsiniz.';

  @override
  String get bpNoFieldsHelp =>
      'Seçilen şablonda dinamik alan yok, bu yüzden dosya sütunlarına eşlenecek bir şey yok. Şablonu düzenleyicide açın, ad alanına “dinamik alan” ekleyin, kaydedin ve tekrar deneyin.';

  @override
  String get bpAutoMap => 'Otomatik eşle';

  @override
  String get bpClearMapping => 'Eşlemeyi temizle';

  @override
  String get bpNameFieldWarning =>
      'Bu şablonda dinamik ad alanı yok — ad sütununu tarih veya referans alanına eşlemeyin, yoksa ad yanlış yere basılabilir. Sütun listesinden ad anahtarını seçin veya düzenleyicideki sabit ad metnini dinamik alana dönüştürün.';

  @override
  String bpStaticNameHints(Object preview) {
    return 'İsme benzeyen sabit metin: “$preview” — hiçbir dinamik alan onu değiştirmez.';
  }

  @override
  String get bpConvertToNameField => 'Eğitmen adı alanına dönüştür';

  @override
  String bpDuplicateField(Object field) {
    return '“$field” alanı birden fazla sütuna eşlendi. Her alanı tek sütuna eşleyin.';
  }

  @override
  String bpUnmappedColumns(Object count) {
    return '$count eşlenmemiş sütun — verileri sertifikalarda kullanılmayacak.';
  }

  @override
  String bpColumn(Object n) {
    return 'Sütun $n';
  }

  @override
  String get bpEmptyCell => '(boş)';

  @override
  String get bpUnmapped => '— eşlenmemiş —';

  @override
  String get bpStepMissing => '4) Boş hücreler ve eksik veriler';

  @override
  String get bpNoNotes => 'Dosya seçilmeden önce not yok.';

  @override
  String get bpStepGenerate => '5) Üret';

  @override
  String bpGenerating(Object progress) {
    return 'Üretiliyor… $progress';
  }

  @override
  String get bpGenerateHint =>
      'Tek PDF dosyası, üretilen her kayıt için bir sayfa.';

  @override
  String get bpGeneratePickFile =>
      'Üretimi etkinleştirmek için önce bir veri dosyası seçin.';

  @override
  String get bpMappingInvalid =>
      'Eşleme geçersiz — aynı alan iki sütuna eşlendi.';

  @override
  String get bpMapAtLeastOne =>
      'Üretimi etkinleştirmek için en az bir sütunu bir şablon alanına eşleyin.';

  @override
  String get bpGenerateCertificates => 'Sertifikaları üret';

  @override
  String get bpRegenerate => 'Yeniden üret';

  @override
  String get bpStatGenerated => 'Üretilen';

  @override
  String get bpStatSkipped => 'Atlanan';

  @override
  String get bpStatPages => 'Sayfalar';

  @override
  String get bpStatSize => 'Boyut';

  @override
  String bpKilobytes(Object value) {
    return '$value KB';
  }

  @override
  String get bpStatTime => 'Süre';

  @override
  String bpMilliseconds(Object value) {
    return '$value ms';
  }

  @override
  String bpCompletion(Object pct, Object total) {
    return '$total satırın %$pct’i tamamlandı.';
  }

  @override
  String get bpSkippedRows => 'Üretilmeyen satırlar:';

  @override
  String bpRowSkipReason(Object n, Object reason) {
    return 'Satır $n: $reason';
  }

  @override
  String get bpPreviewHere => 'Önizleme burada görünür';

  @override
  String get bpPreviewHint =>
      'Veri dosyasını seçin, eşlemeyi ayarlayın, sonra “Sertifikaları üret”e basın — üretilen dosyanın ilk sayfasını burada göreceksiniz.';

  @override
  String get bpAssignByTapTitle => 'Alanları dokunarak ata';

  @override
  String get bpAssignByTapBody =>
      'Şablondaki herhangi bir metne dokunarak onu kendiniz bir dinamik alana atayın. Başka hiçbir öğe etkilenmez — ne tarih, ne müdür adı, ne de sabit metin.';

  @override
  String get bpNoTexts => 'Bu şablonda metin yok.';

  @override
  String get bpEmptyText => '(boş metin)';

  @override
  String get bpDynamicFieldTap => 'Dinamik alan — değiştirmek için dokun';

  @override
  String get bpStaticTextTap => 'Sabit metin — atamak için dokun';

  @override
  String get bpAssignField => 'Alan ata';

  @override
  String get bpKindCertificate => 'Sertifika';

  @override
  String get bpKindContract => 'Sözleşme';

  @override
  String bpLoadSampleError(Object error) {
    return 'Örnek şablon yüklenemedi: $error';
  }

  @override
  String bpReadSheetError(Object error) {
    return 'Sayfa okunamadı: $error';
  }

  @override
  String bpUpdateHeaderRowError(Object error) {
    return 'Başlık satırı güncellenemedi: $error';
  }

  @override
  String get bpChooseTemplateFirst =>
      'Üretmeden önce bir şablon (sertifika veya sözleşme) seçin.';

  @override
  String bpBatchTitle(Object kind) {
    return '$kind toplu — JoodCraft';
  }

  @override
  String bpGenerateError(Object error) {
    return 'Toplu üretim çalıştırılamadı: $error';
  }

  @override
  String get bpWarnNoDynamicFields =>
      'Bu şablonda dinamik alan yok — veriler kayıtlar arasında değişmez. Düzenleyici çubuğundan “eğitmen adı” alanı ekleyin, sonra şablonu kaydedin.';

  @override
  String get bpWarnNoNameField =>
      'Bu şablonda dinamik ad alanı yok — ad sütunu bir tarih veya referans alanına eşlenip ad yanlış yere basılabilir. Sabit ad metnini bir alana dönüştürün veya şablonu yeniden tasarlayın.';

  @override
  String bpAssignedTemp(Object token) {
    return 'Bu öğe geçerli üretim için $token ile eşlendi — diğer öğeler etkilenmedi. Değişikliği kalıcı kılmak için şablonu kaydedin.';
  }

  @override
  String bpAssignedSaved(Object token) {
    return 'Bu öğe $token ile eşlendi ve değişiklik şablona kaydedildi. Diğer öğeler etkilenmedi.';
  }

  @override
  String get commonShow => 'Göster';

  @override
  String get commonHide => 'Gizle';

  @override
  String get themeSwitchToLight => 'Açık temaya geç';

  @override
  String get themeSwitchToDark => 'Koyu temaya geç';

  @override
  String commonComingSoonPhase(Object phase) {
    return 'Devam ediyor — aşama $phase';
  }

  @override
  String get cbNewCertificateTitle => 'Yeni sertifika';

  @override
  String get cbNewContractTitle => 'Yeni sözleşme';

  @override
  String get cbBeneficiaryDataTitle => 'Yararlanıcı verileri (örnek)';

  @override
  String get cbContractDataTitle => 'Sözleşme verileri (örnek)';

  @override
  String get editorSendBackward => 'Geri gönder';

  @override
  String get editorRotateLeft => '90° sola döndür';

  @override
  String get editorRotateRight => '90° sağa döndür';

  @override
  String get editorFlipH => 'Yatay çevir';

  @override
  String get editorFlipV => 'Dikey çevir';

  @override
  String get editorTransform => 'Dönüşümler';

  @override
  String get editorToolSelect => 'Seçim';

  @override
  String get editorToolShapes => 'Şekiller';

  @override
  String get editorFillType => 'Dolgu türü';

  @override
  String get editorFillSolid => 'Düz';

  @override
  String get editorGradientLinear => 'Doğrusal gradyan';

  @override
  String get editorGradientRadial => 'Radyal gradyan';

  @override
  String get editorGradientAngle => 'Gradyan açısı';

  @override
  String get editorShadowEnable => 'Gölge ekle';

  @override
  String get editorShadowColor => 'Gölge rengi';

  @override
  String get editorShadowBlur => 'Gölge bulanıklığı';

  @override
  String get editorShadowOffsetX => 'X kaydırma';

  @override
  String get editorShadowOffsetY => 'Y kaydırma';

  @override
  String get editorShadowSpread => 'Yayılma';

  @override
  String get editorShadowRemove => 'Gölgeyi kaldır';

  @override
  String get editorPoints => 'Köşe sayısı';

  @override
  String get editorInnerRadius => 'İç yarıçap';

  @override
  String get editorCornerTopLeft => 'Sol üst';

  @override
  String get editorCornerTopRight => 'Sağ üst';

  @override
  String get editorCornerBottomRight => 'Sağ alt';

  @override
  String get editorCornerBottomLeft => 'Sol alt';

  @override
  String get editorDashPattern => 'Çizgi deseni';

  @override
  String get editorBooleanOps => 'Boole işlemleri';

  @override
  String get editorBooleanUnion => 'Birleştir';

  @override
  String get editorBooleanSubtract => 'Çıkar';

  @override
  String get editorBooleanIntersect => 'Kesişim';

  @override
  String get editorBooleanUngroup => 'Ayır';

  @override
  String get paletteStar => 'Yıldız';

  @override
  String get palettePolygon => 'Çokgen';

  @override
  String get editorBooleanExclude => 'Hariç tut';

  @override
  String get editorBooleanHint =>
      'Birleşik yol tek bir mantıksal sonuçtur (iç kenar yoktur) ve istenildiğinde ayrılabilir.';

  @override
  String get editorDockTools => 'Araç paneli';

  @override
  String get editorDockAnchor => 'Yerleştirme konumu';

  @override
  String get editorDockTopBar => 'Üst çubuk';

  @override
  String get editorDockInspector => 'Yan panel';

  @override
  String get editorDockLeftRail => 'Yan şerit';

  @override
  String get editorDockFloating => 'Yüzen';

  @override
  String get editorDockCollapse => 'Araçları daralt';

  @override
  String get editorDockExpand => 'Araçları genişlet';

  @override
  String get editorDockResize => 'Boyutlandırmak için sürükleyin';

  @override
  String get editorDockDropHint => 'Yerleştirmek için bırakın';

  @override
  String get editorMoreTools => 'Diğer araçlar';

  @override
  String get editorDocumentProperties => 'Belge özellikleri';

  @override
  String get editorDockReset => 'Varsayılan yerleşimi geri yükle';

  @override
  String get editorTextShadow => 'Metin gölgesi';

  @override
  String get editorTextShadowAdd => 'Metne gölge ekle';

  @override
  String get editorShadowOpacity => 'Gölge saydamlığı';

  @override
  String get genderMale => 'Erkek';

  @override
  String get genderFemale => 'Kadın';

  @override
  String get genderPreviewAutoHint =>
      'Zorlamayı kaldırmak için tıklayın (otomatik)';

  @override
  String get genderPresetCompleted => '\"completed\" (e./k.)';

  @override
  String get genderPresetPassed => '\"passed\" (e./k.)';

  @override
  String get genderPresetForStudent => '\"öğrenci için\" (e./k.)';

  @override
  String get genderPresetStudent => '\"öğrenci\" (e./k.)';

  @override
  String get genderPresetToHim => '\"ona (e.) / ona (k.)\"';

  @override
  String get genderPresetHonoring => '\"seçkin kursiyer\" (e./k.)';

  @override
  String get editorGenderSnippet => 'Koşullu parça ekle';

  @override
  String get editorGenderSnippetHint =>
      'Alıcının cinsiyetine göre otomatik değişen bir ifade ekler.';

  @override
  String get bpGenderReviewTitle => 'Cinsiyet incelemesi (eril/dişil)';

  @override
  String get bpGenderReviewSubtitle =>
      'Cinsiyet addan veya \"Cinsiyet\" sütunundan algılanır — yazdırmadan önce sınır durumları düzeltin.';

  @override
  String get bpGenderRow => 'Satır';

  @override
  String get bpGenderDetected => 'Algılanan';

  @override
  String get bpGenderEffective => 'Uygulanan';

  @override
  String get bpGenderNameColumn => 'Ad';

  @override
  String get bpGenderEditName => 'Adı düzenle';

  @override
  String get bpGenderNameHint => 'Doğru adı yazın';

  @override
  String get bpGenderClearOverrides => 'Düzeltmeleri temizle';

  @override
  String get bpGenderOverridden => 'Elle düzeltildi';

  @override
  String get bpGenderUnknownName => '—';

  @override
  String get bpOutputTitle => 'Sertifika kayıt konumu';

  @override
  String get bpOutputHint =>
      'Oluşturulan PDF\'in kaydedileceği klasörü seçin veya varsayılan konumla başlayın.';

  @override
  String get bpOutputPickFolder => 'Klasör seç…';

  @override
  String get bpOutputStart => 'Oluşturmayı başlat';

  @override
  String get bpOutputPathLabel => 'Seçilen klasör';

  @override
  String get bpOutputNoFolder =>
      'Klasör seçilmedi — yalnızca yazdırma ve dışa aktarma.';

  @override
  String get bpOpenFolder => 'Klasörü aç';

  @override
  String get bpOutputSavedTitle => 'PDF dosyası kaydedildi';

  @override
  String get bpOpenFolderFailed => 'Klasör açılamadı.';

  @override
  String get bpOutputNameLabel => 'Dışa aktarma dosya adı';

  @override
  String get bpOutputNameHint => 'Uzantı olmadan bir ad yazın';

  @override
  String get bpOutputNamePreviewLabel => 'Şu adla kaydedilecek';

  @override
  String get bpOutputModeLabel => 'Kaydetme modu';

  @override
  String get bpOutputModeCombined => 'Tek bir birleşik dosya';

  @override
  String get bpOutputModeIndividual => 'Her kişi için ayrı dosya';

  @override
  String get hubTitle => 'Yeni proje';

  @override
  String get hubSubtitle =>
      'Hazır bir boyut seçin veya kendinizinkini belirleyin — tuval tam boyut ve oranla açılır.';

  @override
  String get hubKindSingle => 'Tek sayfa baskılar ve belgeler';

  @override
  String get hubKindMulti => 'Çok sayfalı kitaplar ve yayınlar';

  @override
  String get hubKindSingleHint =>
      'Tek sayfa: sertifikalar, sözleşmeler, kartlar, koltuk numaraları, tebrik kartları.';

  @override
  String get hubKindMultiHint =>
      'Çok sayfalı: kitap, dergi, broşür, rapor, katalog.';

  @override
  String get hubGroupCertificates => 'Sertifikalar ve sözleşmeler';

  @override
  String get hubGroupCards => 'Kartlar ve kimlik kartları';

  @override
  String get hubGroupSeat => 'Koltuk numaraları ve etiketler';

  @override
  String get hubGroupGreeting => 'Tebrik kartları';

  @override
  String get hubGroupPublications => 'Kitaplar ve yayınlar';

  @override
  String get hubGroupCustom => 'Özel boyut';

  @override
  String get hubDigitalBadge => 'Dijital';

  @override
  String get hubCreate => 'Oluştur';

  @override
  String get hubCustomCardBody =>
      'Ölçülerinizi istediğiniz birimde girin ve kendi boyutunuzda bir tuvalle başlayın.';

  @override
  String get hubCustomName => 'Proje adı';

  @override
  String get hubCustomNameHint => 'örn. Davetiye kartı';

  @override
  String get hubCustomPreview => 'Son boyut';

  @override
  String get hubCustomCreate => 'Tuval oluştur';

  @override
  String get hubCustomType => 'Proje türü';

  @override
  String get hubSearchHint => 'Boyut ara…';

  @override
  String get hubNoResults => 'Eşleşen boyut yok — başka bir kelime deneyin.';

  @override
  String get hubAspectRatio => 'Oran';

  @override
  String get destNewProject => 'Yeni proje';

  @override
  String get destNewProjectDesc =>
      'Hazır veya özel bir boyut seçin ve hemen tasarlamaya başlayın.';

  @override
  String get ptpImpositionToggle => 'Baskı yerleşimi';

  @override
  String get ptpImpositionNoFit =>
      'Sayfa bu öğeye sığmıyor — kenar boşluklarını küçültün veya daha büyük bir sayfa seçin.';

  @override
  String get editorEffectsTitle => 'Efektler ve renk ayarları';

  @override
  String get editorShadowGroup => 'Gölge';

  @override
  String get editorOuterGlow => 'Dış ışıma';

  @override
  String get editorInnerGlow => 'İç ışıma';

  @override
  String get editorGlowAdd => 'Işıma ekle';

  @override
  String get editorGlowRemove => 'Işımayı kaldır';

  @override
  String get editorGlowColor => 'Işıma rengi';

  @override
  String get editorGlowRadius => 'Işıma yarıçapı';

  @override
  String get editorGlowSpread => 'Işıma yayılımı';

  @override
  String get editorGlowOpacity => 'Işıma saydamlığı';

  @override
  String get editorAdjustGroup => 'Renk ayarları';

  @override
  String get editorAdjustBrightness => 'Parlaklık';

  @override
  String get editorAdjustContrast => 'Kontrast';

  @override
  String get editorAdjustSaturation => 'Doygunluk';

  @override
  String get editorAdjustHue => 'Ton';

  @override
  String get editorAdjustReset => 'Sıfırla';

  @override
  String get bpOutputSavedFolderTitle => 'Dosyalar ayrı bir klasöre kaydedildi';

  @override
  String get hubDetailsTitle => 'Ölçü ayrıntıları';

  @override
  String get hubDetailsHint =>
      'Önceden doldurulmuş varsayılan değerler — ızgaradan bir ölçü seçin ya da ölçüleri düzenleyin.';

  @override
  String get hubFilterAll => 'Tümü';

  @override
  String get hubFilterRecent => 'Son ölçüler';

  @override
  String get hubFilterSeat => 'Koltuk numaraları';

  @override
  String get hubFilterGreeting => 'Kutlama kartları ve ekranlar';

  @override
  String get hubRecentEmpty =>
      'Henüz son ölçü yok — oluşturduğunuz her proje burada görünür.';

  @override
  String get hubDocTitle => 'Proje adı';

  @override
  String get hubDocTitleHint => 'Yeni proje - 1';

  @override
  String get hubWidth => 'Genişlik';

  @override
  String get hubHeight => 'Yükseklik';

  @override
  String get hubUnitLabel => 'Birim';

  @override
  String get hubOrientationLabel => 'Yön';

  @override
  String get hubPortrait => 'Dikey';

  @override
  String get hubLandscape => 'Yatay';

  @override
  String get hubVariantLabel => 'Tür';

  @override
  String get hubResolutionLabel => 'Çözünürlük';

  @override
  String get hubResolutionUnitLabel => 'Çözünürlük birimi';

  @override
  String get hubColorModeLabel => 'Renk modu';

  @override
  String get hubBackgroundLabel => 'Arka plan rengi';

  @override
  String get hubBackgroundWhite => 'Beyaz';

  @override
  String get hubBackgroundTransparent => 'Saydam';

  @override
  String get hubBackgroundBlack => 'Siyah';

  @override
  String get hubBackgroundCustom => 'Özel renk';

  @override
  String get hubCreateProject => 'Projeyi oluştur';

  @override
  String get hubCustomFamilyTitle => 'Özel ölçü';

  @override
  String get newDocTitle => 'Yeni belge';

  @override
  String get newDocScopeSocial => 'Ekranlar ve kutlamalar';

  @override
  String get newDocFilterCertificates => 'Sertifikalar';

  @override
  String get newDocFilterCards => 'Kartlar';

  @override
  String get newDocFilterGreeting => 'Kutlamalar';

  @override
  String get newDocFilterPublications => 'Yayınlar';

  @override
  String get menuFile => 'Dosya';

  @override
  String get menuEdit => 'Düzen';

  @override
  String get menuView => 'Görünüm';

  @override
  String get menuTools => 'Araçlar';

  @override
  String get menuHelp => 'Yardım';

  @override
  String get menuNewDocument => 'Yeni belge…';

  @override
  String get menuPurgeRecent => 'Son boyutları temizle';

  @override
  String get menuPurgeImageCache => 'Görsel önbelleğini temizle';

  @override
  String get menuPreviewCertificate => 'Örnek sertifikayı önizle';

  @override
  String get menuPreviewContract => 'Örnek sözleşmeyi önizle';

  @override
  String get menuAbout => 'JoodCraft hakkında';

  @override
  String get actionNewShort => '+ Yeni';

  @override
  String get dashLocalMode => 'Yerel';

  @override
  String get dashLocalStorage =>
      'Bu cihazda yerel olarak kaydedilir — hiçbir proje sunucuya yüklenmez.';

  @override
  String get dashRecentProjects => 'Son projeler';

  @override
  String get dashRecentEmpty =>
      'Bu cihazda henüz kayıtlı proje yok — yeni bir belge oluşturun, anında burada görünür.';

  @override
  String get dashRecentOpen => 'Projeyi aç';

  @override
  String get editorTransformPosition => 'Dönüşüm ve Konum';

  @override
  String get editorTransformPositionHint => 'Konum, boyut ve döndürme açısı';

  @override
  String get editorAppearanceEffects => 'Görünüm ve Efektler';

  @override
  String get editorAppearanceEffectsHint =>
      'Dolgu, kontur, parlama ve gölgeler';

  @override
  String get editorTypographyHint => 'Yazı tipi, boyut, hizalama ve aralık';

  @override
  String get editorPageSettingsHint => 'Boyut ve ölçü birimi';

  @override
  String get editorBackgroundHint => 'Sayfa rengi veya degrade';

  @override
  String get editorPrecisionHint => 'İnce taşıma ve ölçekleme';

  @override
  String get joodExportProject => 'Projeyi dışa aktar (.jood)';

  @override
  String get joodImportProject => 'Projeyi aç (.jood)';

  @override
  String get joodExportReady => 'Proje dosyası kaydedilmeye hazır.';

  @override
  String get joodExportFailed => 'Proje dosyası dışa aktarılamadı.';

  @override
  String get joodImportOpened => 'İçe aktarılan proje açıldı.';

  @override
  String get joodImportFailed => 'Proje dosyası açılamadı.';

  @override
  String get joodRecoveryTitle => 'Kaydedilmemiş taslak';

  @override
  String get joodRecoveryMessage =>
      'Önceki bir oturumdan kaydedilmemiş bir taslak var. Geri yüklemek ister misiniz?';

  @override
  String get joodRecoveryRestore => 'Geri yükle';

  @override
  String get joodRecoveryDiscard => 'Yoksay';

  @override
  String get joodRecoveryRestored => 'Taslak geri yüklendi.';

  @override
  String get joodAutosaveSaved => 'Otomatik kaydedildi';

  @override
  String get joodAutosaveSaving => 'Kaydediliyor…';

  @override
  String get editorConfirm => 'Onayla';

  @override
  String get admTitle => 'Yerel yönetici yönetimi';

  @override
  String get admRefresh => 'Yenile';

  @override
  String get admTabAdmins => 'Yöneticiler';

  @override
  String get admTabTransfer => 'Cihazlar arası aktarım';

  @override
  String get admTabAudit => 'Dışa aktarma günlüğü';

  @override
  String get admListTitle => 'Bu cihazdaki yönetici hesapları';

  @override
  String get admAdd => 'Yönetici ekle';

  @override
  String get admNoAdmins => 'Henüz yönetici hesabı yok.';

  @override
  String get admLoading => 'Bu cihazdaki yönetici hesapları yükleniyor…';

  @override
  String get admRoleOwner => 'Birincil yönetici';

  @override
  String get admCurrent => 'Sen';

  @override
  String get admCurrentCardTitle => 'Bu cihazdaki mevcut hesap';

  @override
  String get admRoleAdmin => 'Yönetici';

  @override
  String get admSwitchTitle => 'Hızlı hesap değiştirme';

  @override
  String get admSwitchPrompt =>
      'Bu cihazdaki bir alt yöneticinin yerel kullanıcı adını seçin ve yerel parolasını girin; açık proje taslakları önce kaydedilir ve ana lisans etkilenmez.';

  @override
  String get admSwitchNoOthers =>
      'Bu cihazda başka alt yönetici yok. Önce yöneticiler ekranından yeni bir yönetici ekleyin.';

  @override
  String get admSwitchPick => 'Yerel kullanıcı adı';

  @override
  String get admSwitchPassword => 'Seçilen hesabın yerel parolası';

  @override
  String get admSwitchPickPassword =>
      'Bir kullanıcı adı seçin ve parolayı girin.';

  @override
  String get admSwitchWrongPassword => 'Parola hatalı.';

  @override
  String get admSwitchFailed => 'Hesap değiştirilemedi. Tekrar deneyin.';

  @override
  String get admSwitchSuccess => 'Hesap başarıyla değiştirildi.';

  @override
  String get admSwitchAccount => 'Hesap değiştir';

  @override
  String get admSwitchAction => 'Şimdi değiştir';

  @override
  String get admColAdmin => 'Yönetici';

  @override
  String get admColUsername => 'Yerel kullanıcı adı';

  @override
  String get admColRole => 'Rol';

  @override
  String get admColCreated => 'Eklenme';

  @override
  String get admColActions => 'İşlemler';

  @override
  String get destJoodWriter => 'Jood Writer';

  @override
  String get destJoodWriterDesc =>
      'Otomatik sayfa akışlı metin belgeleri ve raporlar.';

  @override
  String get admCreatedAt => 'Oluşturulma';

  @override
  String get admEdit => 'Bilgileri düzenle';

  @override
  String get admChangePassword => 'Parolayı değiştir';

  @override
  String get admPromote => 'Birincil yöneticiye yükselt';

  @override
  String get admDemote => 'Yöneticiye düşür';

  @override
  String get admDelete => 'Hesabı sil';

  @override
  String admDeleteConfirm(Object name) {
    return '“$name” bu cihazdan kalıcı olarak silinecek. Bu işlem geri alınamaz.';
  }

  @override
  String get admPromoted => 'Birincil yöneticiye yükseltildi.';

  @override
  String get admDemoted => 'Yöneticiye düşürüldü.';

  @override
  String get admDeleted => 'Hesap silindi.';

  @override
  String get admCreated => 'Yeni yönetici eklendi.';

  @override
  String get admUpdated => 'Yönetici bilgileri güncellendi.';

  @override
  String get admPasswordChanged => 'Parola değiştirildi.';

  @override
  String get admTransferInfoTitle => 'Aktarım nasıl çalışır?';

  @override
  String get admTransferInfo1 =>
      'Hesap tablosu (parola özetleriyle, asla parolalarla değil) seçtiğiniz bir parola ifadesiyle şifrelenmiş bir dosyanın içinde dışa aktarılır.';

  @override
  String get admTransferInfo2 =>
      'Dosyayı veya kodu diğer cihaza taşıyın ve aynı parola ifadesiyle orada içe aktarın; hesaplar aynı izinlerle çalışır.';

  @override
  String get admTransferInfo3 =>
      'Hiçbir sunucuya bir şey gönderilmez: aktarım tamamen yerel cihazlar arasında elle yapılır.';

  @override
  String get admExport => 'Hesapları dışa aktar';

  @override
  String get admExportPassphrase => 'Dışa aktarma parola ifadesi';

  @override
  String get admPassphraseConfirm => 'Parola ifadesini doğrula';

  @override
  String get admExportRisk =>
      'Bu kodu ve parola ifadesini elinde bulunduran herkesin bu hesaplarla oturum açabileceğini anlıyorum, bu yüzden dikkatli paylaşacağım.';

  @override
  String get admExportGenerate => 'Şifreli kod oluştur';

  @override
  String get admExportFile => 'Özel bir dosyaya kaydet';

  @override
  String get admExportDone =>
      'Şifreli kod oluşturuldu. Kopyalayın veya bir dosyaya kaydedin.';

  @override
  String get admExportFileSaved => 'Şifreli hesaplar dosyası kaydedildi.';

  @override
  String get admPassphraseTooShort =>
      'Parola ifadesi için en az 6 karakter kullanın.';

  @override
  String get admPassphraseMismatch => 'Parola ifadeleri eşleşmiyor.';

  @override
  String get admAcceptRiskRequired =>
      'Önce kodu paylaşmanın riskini anladığınızı doğrulayın.';

  @override
  String admFileError(Object error) {
    return 'Dosya işlenemedi: $error';
  }

  @override
  String get admImport => 'Hesapları içe aktar';

  @override
  String get admImportCode => 'Hesap kodu';

  @override
  String get admImportPassphrase => 'Dosya parola ifadesi';

  @override
  String get admImportReplace => 'Mevcut hesapların parolalarını değiştir';

  @override
  String get admImportPick => 'Bir dosya seç';

  @override
  String get admImportRun => 'Şimdi içe aktar';

  @override
  String get admImportCodeRequired =>
      'Önce kodu yapıştırın veya bir dosya seçin.';

  @override
  String get admImportPassphraseRequired => 'Dosya parola ifadesini girin.';

  @override
  String admImportDone(int added, int updated, int skipped) {
    return 'İçe aktarıldı: $added yeni, $updated güncellendi, $skipped atlandı.';
  }

  @override
  String get admAuditTitle => 'Verilen sertifika ve belge günlüğü';

  @override
  String get admAuditClear => 'Günlüğü temizle';

  @override
  String get admAuditEmpty =>
      'Henüz dışa aktarma yok. Dışa aktardığınız her sertifika veya sözleşme, tarihi ve onu veren yöneticiyle birlikte burada günlüğe kaydedilir.';

  @override
  String get admAuditBy => 'Tarafından';

  @override
  String get admAuditPages => 'sayfa';

  @override
  String get admAuditClearConfirm =>
      'Dışa aktarma günlüğünün tamamı bu cihazdan silinecek. Bu işlem geri alınamaz.';

  @override
  String get admAuditCleared => 'Günlük temizlendi.';

  @override
  String get admUnavailableTitle => 'Yönetim şu anda kullanılamıyor';

  @override
  String get admUnavailableBody =>
      'Yönetici yönetimi, uygulama yerel bir hesapla (LocalAuthRepository) çalıştığında çalışır; böylece hesaplar bu cihazdan okunur.';

  @override
  String get pdfExportTypeTitle => 'Dışa aktarma türü';

  @override
  String get pdfExportTypeHint => 'Dışa aktarmadan önce dosya biçimini seçin.';

  @override
  String get pdfExportTypeImages => 'Görseller';

  @override
  String get pdfExportTypeImagesDesc => '%100 eşleşme — daha büyük dosya';

  @override
  String get pdfExportTypeImagesNotCopyable => 'Metin kopyalanamaz';

  @override
  String get pdfExportTypeVector => 'Vektör';

  @override
  String get pdfExportTypeVectorDesc =>
      'Kopyalanabilir metin — daha küçük dosya';

  @override
  String get pdfExportTypeVectorCopyable => 'Metin kopyalanıp aranabilir';

  @override
  String get pdfExportTypeVectorBestFor => 'Profesyonel baskı için ideal';

  @override
  String get pdfExportTypeComingSoon => 'Yakında';

  @override
  String get pdfExportTypeComingSoonMessage =>
      'Vektör dışa aktarma geliştirilme aşamasında — yakında.';

  @override
  String get invCategoryTitle => 'Davetler ve özel günler';

  @override
  String get invCategoryRamadan => 'Ramazan';

  @override
  String get invCategoryEid => 'Bayram';

  @override
  String get invCategoryWedding => 'Düğün';

  @override
  String get invRamadan1Title => 'Ramazan — Klasik';

  @override
  String get invRamadan2Title => 'Ramazan — Story';

  @override
  String get invEid1Title => 'Bayramınız Mübarek — Klasik';

  @override
  String get invEid2Title => 'Bayramınız Mübarek — Story';

  @override
  String get invWedding1Title => 'Düğün — Klasik';

  @override
  String get invWedding2Title => 'Düğün — Modern';

  @override
  String get invWedding3Title => 'Düğün — Story';

  @override
  String get invSizeA6Portrait => 'A6 dikey (105×148 mm)';

  @override
  String get invSizeA6Landscape => 'A6 yatay (148×105 mm)';

  @override
  String get invSizeSquare148 => 'Baskı karesi (148×148 mm)';

  @override
  String get invSizeA5Folded => 'A5 katlı (105×148 mm)';

  @override
  String get invSizeInstagramSquare => 'Instagram kare (1080×1080)';

  @override
  String get invSizeInstagramPortrait => 'Instagram dikey (1080×1350)';

  @override
  String get invSizeInstagramStory => 'Instagram Story (1080×1920)';

  @override
  String get invSizeWhatsAppStatus => 'WhatsApp Status (1080×1920)';

  @override
  String get invSizeFacebookPost => 'Facebook Post (1200×630)';

  @override
  String get invExportFormatPNG => 'PNG (sosyal medya için)';

  @override
  String get invExportFormatPDF => 'PDF (baskı için)';

  @override
  String get invExportFormatBoth => 'PNG + PDF';

  @override
  String get invBulkModeTitle => 'Toplu kişisel davetler';

  @override
  String get invBulkModeHint =>
      'Her isim için bir kart — ayrı ayrı dışa aktarma.';

  @override
  String get invPreviewTitle => 'İlk 3 kopyanın önizlemesi';

  @override
  String get invExportFormat => 'Dışa aktarma biçimi';

  @override
  String get invNameFieldMissing => 'Bu şablonda isim alanı yok';

  @override
  String invDuplicateNames(Object count) {
    return 'Yinelenen isimler: $count';
  }

  @override
  String invEmptyNames(Object count) {
    return 'Boş hücreler: $count — atlanacak';
  }

  @override
  String get invZIPOption => 'ZIP dosyasında sıkıştır';

  @override
  String get invIndexCSVOption => 'CSV dizini oluştur';

  @override
  String invProgressText(Object done, Object total) {
    return '$done/$total oluşturuldu';
  }

  @override
  String get navEditors => 'Düzenleyiciler';

  @override
  String get navLibraries => 'Kütüphaneler';

  @override
  String get navAdmin => 'Yönetim';

  @override
  String get navUser => 'Hesap';

  @override
  String get bpWorkTypeLabel => 'Şablon türü';

  @override
  String get bpExportFormatLabel => 'Dışa aktarma türü';

  @override
  String get bpKindInvitation => 'Davetiye';

  @override
  String get invPackOptions => 'Çıktı seçenekleri';
}
