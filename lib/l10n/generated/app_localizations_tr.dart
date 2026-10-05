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
  String get dashRoadmapSupabase =>
      'Supabase veritabanının kurulması (tablolar + RLS + trigger’lar)';

  @override
  String get dashRoadmapModular =>
      'Ölçeklenebilir Modüler Feature-First yapısı';

  @override
  String get dashRoadmapTheme =>
      'Cairo yazı tipiyle RTL destekli marka görsel teması';

  @override
  String get dashRoadmapAuth =>
      'Kimlik doğrulama: giriş, hesap oluşturma ve parola sıfırlama';

  @override
  String get dashPhaseOneDone => 'Birinci aşama tamamlandı';

  @override
  String get dashNextPhase =>
      'Sonraki: çevrimdışı PDF motoru ve Arapça yazı tipleri, ardından görsel şablon düzenleyici.';

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
}
