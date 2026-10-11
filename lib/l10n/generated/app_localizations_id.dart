// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get editorDone => 'Selesai';

  @override
  String get appTagline => 'Buat sertifikat dan kontrak resmi secara offline';

  @override
  String get navDashboard => 'Dasbor';

  @override
  String get navCertificates => 'Pembuat Sertifikat';

  @override
  String get navContracts => 'Pembuat Kontrak';

  @override
  String get navBatch => 'Pembuatan Massal';

  @override
  String get navTemplates => 'Pustaka Templat';

  @override
  String get navAssets => 'Aset & Tanda Tangan';

  @override
  String get actionSignOut => 'Keluar';

  @override
  String get actionOpenMenu => 'Menu';

  @override
  String get editorFitToScreen => 'Sesuaikan ke layar';

  @override
  String get editorNewTemplate => 'Templat baru';

  @override
  String get editorNewConfirm =>
      'Templat baru akan dimulai dari desain default; perubahan yang belum disimpan tetap ada di riwayat. Lanjutkan?';

  @override
  String get actionBackToDashboard => 'Kembali ke dasbor';

  @override
  String get offlineProcessingLabel => 'Pemrosesan lokal';

  @override
  String get themeTooltip => 'Ubah tema';

  @override
  String get themeSystem => 'Sistem';

  @override
  String get themeLight => 'Terang';

  @override
  String get themeDark => 'Gelap';

  @override
  String get languageTooltip => 'Ubah bahasa';

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
  String get configMissingKeysTitle => 'Kunci koneksi tidak ditemukan';

  @override
  String get configMissingKeysBody =>
      'Saat mulai, aplikasi mencari kunci di tiga sumber: flag --dart-define, lalu file env.json di disk (root atau assets/env/), lalu salinan yang dibundel — tidak ada yang ditemukan. Buat file, isi sekali, lalu jalankan tanpa flag:';

  @override
  String get configEnvNote =>
      'Bundel menyatakan assets/env/ sebagai aset, jadi tidak adanya file tidak merusak build bersih. Buat dari env.example.json atau jalankan: dart run tool/ensure_env.dart — hanya kunci anon/public yang diperlukan; service_role tidak pernah dipakai di aplikasi.';

  @override
  String get routeNotFoundTitle => 'Halaman tidak ditemukan';

  @override
  String get routeNotFoundBody =>
      'Rute yang diminta tidak terdefinisi di aplikasi:';

  @override
  String get editorPrecisionTitle => 'Kontrol presisi';

  @override
  String get editorNudgeStep => 'Langkah geser';

  @override
  String get editorNudgeStepHint =>
      'Panah di kanvas juga menggeser Shift = 10px.';

  @override
  String get editorNudgeUp => 'Geser ke atas';

  @override
  String get editorNudgeLeft => 'Geser ke kiri';

  @override
  String get editorNudgeDown => 'Geser ke bawah';

  @override
  String get editorNudgeRight => 'Geser ke kanan';

  @override
  String get editorScale => 'Skala';

  @override
  String get editorScaleHint =>
      'Penskalaan relatif di sekitar pusat elemen (roda pada tombol untuk langkah lebih halus).';

  @override
  String get editorScaleUp => 'Perbesar';

  @override
  String get editorScaleDown => 'Perkecil';

  @override
  String get editorDecorTitle => 'Dekorasi vektor';

  @override
  String get editorDecorKind => 'Jenis dekorasi';

  @override
  String get editorDecorPalette => 'Palet warna';

  @override
  String get editorDecorLayers => 'Jumlah lapisan';

  @override
  String get editorDecorSeed => 'Benih';

  @override
  String get editorDecorThickness => 'Ketebalan';

  @override
  String get editorDecorPrimary => 'Warna utama';

  @override
  String get editorDecorSecondary => 'Warna kedua';

  @override
  String get editorDecorAccent => 'Warna aksen';

  @override
  String get editorDecorGradient => 'Gradasi lapisan';

  @override
  String get editorDecorGallery => 'Galeri preset';

  @override
  String get editorDecorGalleryTitle => 'Galeri dekorasi siap pakai';

  @override
  String get editorClose => 'Tutup';

  @override
  String get editorDecorPaletteCustom => 'Kustom';

  @override
  String get decorKindModernWave => 'Gelombang modern';

  @override
  String get decorKindPaperCut => 'Potongan kertas berlapis';

  @override
  String get decorKindClassicCorner => 'Bingkai klasik berhias';

  @override
  String get decorKindGuilloche => 'Pola guilloche';

  @override
  String get decorKindRibbonBanner => 'Pita / spanduk';

  @override
  String get decorPaletteRoyalGold => 'Emas kerajaan';

  @override
  String get decorPaletteRoyalBlue => 'Biru kerajaan';

  @override
  String get decorPaletteEmerald => 'Zamrud';

  @override
  String get decorPaletteBurgundy => 'Burgundi';

  @override
  String get decorPaletteMidnight => 'Navy tengah malam';

  @override
  String get decorPaletteMono => 'Abu-abu monokrom';

  @override
  String get editorSignatureTitle => 'Blok tanda tangan';

  @override
  String get editorSignatureCount => 'Jumlah tanda tangan';

  @override
  String get signatureCountOne => 'Satu tanda tangan';

  @override
  String get signatureCountTwo => 'Dua tanda tangan';

  @override
  String get signatureCountThree => 'Tiga tanda tangan';

  @override
  String get editorSignatureOrder => 'Urutan kolom';

  @override
  String get editorSignatureOrderHint =>
      'Pada dokumen berbahasa Arab, kolom pertama berada di paling kanan.';

  @override
  String get editorSignatureFirstRight => 'Pertama di kanan';

  @override
  String get editorSignatureFirstLeft => 'Pertama di kiri';

  @override
  String get editorDirectionAuto => 'Otomatis';

  @override
  String get editorSignatureImageAlign => 'Perataan gambar';

  @override
  String get editorAlignStart => 'Awal';

  @override
  String get editorAlignCenter => 'Tengah';

  @override
  String get editorAlignEnd => 'Akhir';

  @override
  String get editorSignatureDivider => 'Garis tanda tangan';

  @override
  String get editorVisible => 'Terlihat';

  @override
  String get editorHidden => 'Tersembunyi';

  @override
  String get editorSignatureNameSize => 'Ukuran nama';

  @override
  String get editorSignatureRoleSize => 'Ukuran jabatan';

  @override
  String get editorSignatureSpacing => 'Jarak';

  @override
  String get editorSignatureImageSize => 'Ukuran gambar';

  @override
  String get editorSignatureNameColor => 'Warna nama';

  @override
  String get editorSignatureRoleColor => 'Warna jabatan';

  @override
  String get editorFont => 'Font';

  @override
  String get editorImageSource => 'Sumber gambar';

  @override
  String get imageSourceAppAssets => 'Aset aplikasi';

  @override
  String get imageSourceMyLibrary => 'Pustaka aset saya';

  @override
  String get imageSourceLocalFile => 'Berkas lokal';

  @override
  String get imageSourceEmbedded => 'Data tertanam';

  @override
  String get editorSignatureChangeImage => 'Ubah gambar tanda tangan';

  @override
  String get editorSignatureAddImage => 'Tambah gambar tanda tangan';

  @override
  String get editorSignatureRemoveImage => 'Hapus gambar tanda tangan';

  @override
  String get editorSignaturePickImageTitle =>
      'Pilih gambar tanda tangan dari pustaka aset saya';

  @override
  String get editorSignatureSlot => 'Kolom';

  @override
  String get editorSignatureRoleField => 'Jabatan (mis. Direktur Utama)';

  @override
  String get editorSignatureNameField =>
      'Nama penanda tangan (menerima bidang dinamis)';

  @override
  String get editorFromMyLibrary => 'Dari pustaka aset saya';

  @override
  String get paletteSignatureBlock => 'Tanda tangan';

  @override
  String get editorInsertFromLibraryTooltip =>
      'Sisipkan bingkai atau logo yang diunggah secara langsung';

  @override
  String get unsupportedElementVersionNote =>
      'Elemen ini berasal dari versi editor yang lebih baru — dipertahankan apa adanya dan tidak dapat diedit di sini.';

  @override
  String editorSelectedCount(Object count) {
    return '$count dipilih';
  }

  @override
  String get editorClearSelection => 'Bersihkan pilihan';

  @override
  String get editorGroup => 'Grup';

  @override
  String get editorOpacity => 'Opasitas';

  @override
  String get editorBringToFront => 'Bawa ke depan';

  @override
  String get editorSendToBack => 'Kirim ke belakang';

  @override
  String get editorDuplicate => 'Duplikat';

  @override
  String get editorDeleteSelected => 'Hapus pilihan';

  @override
  String get editorGroupDragHint =>
      'Seret grup dengan mouse, gunakan panah untuk menggeser halus (Shift = 10px), dan Ctrl + klik untuk menyesuaikan pilihan.';

  @override
  String get destBrand => 'Identitas & profil';

  @override
  String get destBrandDesc =>
      'Logo, stempel, tanda tangan, dan warna merek Anda.';

  @override
  String get brandTitle => 'Pengaturan identitas dan profil';

  @override
  String get brandTabVisuals => 'Identitas visual';

  @override
  String get brandTabText => 'Data teks';

  @override
  String get brandTabColors => 'Warna & font';

  @override
  String get brandTabPreview => 'Pratinjau identitas';

  @override
  String get brandPrimaryLogo => 'Logo utama';

  @override
  String get brandWatermarkLogo => 'Logo tanda air';

  @override
  String get brandSeals => 'Stempel resmi';

  @override
  String get brandAddSeal => 'Tambah stempel';

  @override
  String get brandSealName => 'Nama stempel';

  @override
  String get brandSignatures => 'Tanda tangan resmi';

  @override
  String get brandAddSignature => 'Tambah tanda tangan';

  @override
  String get brandSignatureName => 'Nama penanda tangan';

  @override
  String get brandSignatureTitle => 'Jabatan';

  @override
  String get brandRemove => 'Hapus';

  @override
  String get brandNoSeals => 'Belum ada stempel.';

  @override
  String get brandNoSignatures => 'Belum ada tanda tangan.';

  @override
  String get brandOrgNameAr => 'Nama organisasi (Arab)';

  @override
  String get brandOrgNameEn => 'Nama organisasi (Inggris)';

  @override
  String get brandHeaderText => 'Teks kepala';

  @override
  String get brandFooterText => 'Teks kaki';

  @override
  String get brandRegNumber => 'Nomor pajak / registrasi';

  @override
  String get brandPrimaryColor => 'Warna utama';

  @override
  String get brandSecondaryColor => 'Warna sekunder';

  @override
  String get brandAccentColor => 'Warna aksen';

  @override
  String get brandHeaderFont => 'Font judul';

  @override
  String get brandBodyFont => 'Font isi';

  @override
  String get brandClear => 'Hapus identitas';

  @override
  String get brandClearConfirm =>
      'Semua konten identitas yang tersimpan akan dihapus. Lanjutkan?';

  @override
  String get brandSaved => 'Identitas disimpan.';

  @override
  String get brandPresets => 'Elemen identitas';

  @override
  String get brandInsertHeader => 'Sisipkan kepala standar';

  @override
  String get brandInsertFooter => 'Sisipkan kaki standar';

  @override
  String get brandApplyColors => 'Terapkan warna';

  @override
  String get brandQuickSeals => 'Stempel';

  @override
  String get brandQuickSignatures => 'Tanda tangan';

  @override
  String get brandNoBrand => 'Identitas Anda belum diatur.';

  @override
  String get brandOpenSettings => 'Buka pengaturan identitas';

  @override
  String get brandHeaderInserted => 'Kepala standar disisipkan.';

  @override
  String get brandFooterInserted => 'Kaki standar disisipkan.';

  @override
  String get brandColorsApplied => 'Warna diterapkan.';

  @override
  String get brandSealInserted => 'Stempel disisipkan.';

  @override
  String get brandSignatureInserted => 'Tanda tangan disisipkan.';

  @override
  String get brandFontDefault => 'Bawaan';

  @override
  String get paletteShapes => 'Bentuk';

  @override
  String get paletteRoundedRect => 'Persegi membulat';

  @override
  String get paletteEllipse => 'Lingkaran / elips';

  @override
  String get editorFillOpacity => 'Opasitas isian';

  @override
  String get editorCollapsePanel => 'Ringkas panel samping';

  @override
  String get editorExpandPanel => 'Tampilkan panel samping';

  @override
  String get editorCustomSize => 'Ukuran khusus';

  @override
  String get editorStandardSize => 'Ukuran standar';

  @override
  String get editorBackgroundTitle => 'Latar halaman';

  @override
  String get editorGradientFrom => 'Dari';

  @override
  String get editorGradientTo => 'Ke';

  @override
  String get editorGradientDirection => 'Arah';

  @override
  String get editorGradientNone => 'Tanpa gradien';

  @override
  String get editorGradientVertical => 'Vertikal';

  @override
  String get editorGradientHorizontal => 'Horizontal';

  @override
  String get editorGradientDiagonal => 'Diagonal';

  @override
  String get editorLayersTitle => 'Lapisan';

  @override
  String get editorLayerShow => 'Tampilkan elemen';

  @override
  String get editorLayerHide => 'Sembunyikan elemen';

  @override
  String get editorLayerLock => 'Kunci elemen';

  @override
  String get editorLayerUnlock => 'Buka kunci elemen';

  @override
  String get editorLayersEmpty => 'Belum ada elemen di halaman ini.';

  @override
  String get editorGroupSelected => 'Kelompokkan pilihan';

  @override
  String get editorUngroupSelected => 'Pisahkan grup';

  @override
  String get editorAlignLeft => 'Rata kiri';

  @override
  String get editorAlignCenterH => 'Rata tengah horizontal';

  @override
  String get editorAlignRight => 'Rata kanan';

  @override
  String get editorAlignTop => 'Rata atas';

  @override
  String get editorAlignCenterV => 'Rata tengah vertikal';

  @override
  String get editorAlignBottom => 'Rata bawah';

  @override
  String get editorBringForward => 'Maju selangkah';

  @override
  String get editorDuplicateElement => 'Duplikat elemen';

  @override
  String get editorDeleteElement => 'Hapus elemen';

  @override
  String get editorPageSettings => 'Pengaturan halaman';

  @override
  String get editorPageSize => 'Ukuran';

  @override
  String get editorUnit => 'Satuan';

  @override
  String get editorWidth => 'Lebar';

  @override
  String get editorHeight => 'Tinggi';

  @override
  String get editorLabelText => 'Teks';

  @override
  String get editorLabelShape => 'Bentuk';

  @override
  String get editorLabelSeal => 'Segel';

  @override
  String get editorLabelDecoration => 'Dekorasi vektor';

  @override
  String get editorLabelSignature => 'Blok tanda tangan';

  @override
  String get editorLabelImage => 'Gambar / logo';

  @override
  String get editorLabelQr => 'Kode QR';

  @override
  String get editorLabelUnknown => 'Elemen tidak didukung';

  @override
  String get editorLabelDynamicField => 'Bidang dinamis';

  @override
  String get editorPositionAndSize => 'Posisi dan ukuran';

  @override
  String get editorPosX => 'X';

  @override
  String get editorPosY => 'Y';

  @override
  String get editorRotation => 'Rotasi';

  @override
  String get editorTextFormat => 'Pemformatan teks';

  @override
  String get editorConvertToField => 'Konversi ke bidang dinamis';

  @override
  String get editorFontWeight => 'Ketebalan';

  @override
  String get editorWeightRegular => 'Normal';

  @override
  String get editorWeightSemiBold => 'Sedang';

  @override
  String get editorWeightBold => 'Tebal';

  @override
  String get editorFontSize => 'Ukuran font';

  @override
  String get editorLetterSpacing => 'Spasi huruf';

  @override
  String get editorLineHeight => 'Tinggi baris';

  @override
  String get editorTextColor => 'Warna teks';

  @override
  String get editorTextBackground => 'Latar teks';

  @override
  String get editorTextAlign => 'Perataan';

  @override
  String get editorAlignJustify => 'Rata kanan-kiri';

  @override
  String get editorJustifyMode => 'Metode perataan';

  @override
  String get editorJustifyHint =>
      'Kashida diterapkan pada berkas PDF (pratinjau menampilkan perataan spasi)';

  @override
  String get editorJustifySpaces => 'Spasi';

  @override
  String get editorJustifyKashida => 'Kashida';

  @override
  String get editorVerticalAlign => 'Perataan vertikal';

  @override
  String get editorVerticalTop => 'Atas';

  @override
  String get editorVerticalBottom => 'Bawah';

  @override
  String get editorDirection => 'Arah';

  @override
  String get editorDirectionHint => 'Pintasan alih: Ctrl+Shift+D';

  @override
  String get editorDirectionRtl => 'Arab (RTL)';

  @override
  String get editorDirectionLtr => 'Latin (LTR)';

  @override
  String get editorImage => 'Gambar';

  @override
  String get editorSource => 'Sumber';

  @override
  String get editorImageTint => 'Warna gambar';

  @override
  String get editorImageFit => 'Kesesuaian gambar';

  @override
  String get editorFitContain => 'Muat penuh';

  @override
  String get editorFitCover => 'Tutupi';

  @override
  String get editorFitFill => 'Regangkan';

  @override
  String get assetPickerEmptyHint =>
      'Anda belum mengunggah aset apa pun. Unggah logo, tanda tangan, atau segel untuk digunakan di sini dan saat mencetak.';

  @override
  String get assetPickerNoneOption => 'Tidak ada (sumber lain)';

  @override
  String get assetPickerTitle => 'Pilih gambar dari pustaka aset saya';

  @override
  String assetUploadType(Object type) {
    return 'Unggah $type';
  }

  @override
  String get editorSeal => 'Segel';

  @override
  String get editorSealColor => 'Warna segel';

  @override
  String get editorSealRingColor => 'Warna cincin';

  @override
  String get editorSealStarColor => 'Warna bintang';

  @override
  String get editorSealStarSize => 'Ukuran bintang';

  @override
  String get editorShape => 'Bentuk';

  @override
  String get editorFillColor => 'Warna isian';

  @override
  String get editorBorderColor => 'Warna batas';

  @override
  String get editorBorderWidth => 'Ketebalan batas';

  @override
  String get editorCornerRadius => 'Radius sudut';

  @override
  String get editorQrVerify => 'Kode verifikasi';

  @override
  String get editorQrData => 'Data kode';

  @override
  String get editorQrColor => 'Warna kode';

  @override
  String get editorQrBackground => 'Latar kode';

  @override
  String editorConvertDialogMessage(Object text) {
    return 'Konversi mengubah teks “$text” menjadi penanda dinamis yang dapat ditautkan dalam pembuatan massal.';
  }

  @override
  String get editorFieldKeyHint =>
      'Kunci bidang (mis. nama, tanggal, referensi)';

  @override
  String get editorCustomKeyHint =>
      'Masukkan kunci khusus (tanpa kurung — akan ditambahkan otomatis)';

  @override
  String get editorCancel => 'Batal';

  @override
  String get editorConvert => 'Konversi';

  @override
  String get editorPath => 'Jalur';

  @override
  String get editorTextContent => 'Isi teks';

  @override
  String editorInsertFieldToken(Object token) {
    return 'Sisipkan $token';
  }

  @override
  String editorAddLabel(Object label) {
    return 'Tambah $label';
  }

  @override
  String assetInsertedSnack(Object name) {
    return '“$name” disisipkan ke templat.';
  }

  @override
  String get paletteHeading => 'Judul';

  @override
  String get paletteFrame => 'Persegi panjang / bingkai';

  @override
  String get paletteDivider => 'Pembatas';

  @override
  String get paletteLogo => 'Logo / tanda tangan';

  @override
  String get evSignatureEmptyLabel => 'Tanda tangan kosong';

  @override
  String get evSignatureEmptyDetail =>
      'Tambahkan jabatan, nama, dan gambar tanda tangan';

  @override
  String get evSignatureMissingLabel => 'Tanda tangan hilang';

  @override
  String get evUploadToLibraryDetail => 'Unggah gambar ke pustaka aset';

  @override
  String get evImageNotFoundLabel => 'Gambar tidak ditemukan';

  @override
  String get evNoFileLabel => 'Tidak ada berkas dipilih';

  @override
  String get evChooseFromAssetsDetail => 'Pilih gambar dari pustaka aset';

  @override
  String get evAssetMissingLabel => 'Aset hilang';

  @override
  String get evReselectAssetDetail => 'Pilih ulang bingkai/aset dari pustaka';

  @override
  String get evInvalidImageLabel => 'Gambar tidak valid';

  @override
  String get evRenderDataFailedDetail => 'Tidak dapat menampilkan data';

  @override
  String get evInvalidDataLabel => 'Data tidak valid';

  @override
  String get evDecodeFailedDetail => 'Tidak dapat mendekode gambar';

  @override
  String get evEmptyQrLabel => 'Kode kosong';

  @override
  String get evEmptyQrDetail => 'Masukkan nilai kode di bilah properti';

  @override
  String evUnknownElementLabel(Object type) {
    return 'Elemen tidak didukung: $type';
  }

  @override
  String get alpFilterAll => 'Semua';

  @override
  String get alpEmptyHint =>
      'Tidak ada aset yang diunggah dari jenis yang diminta. Unggah bingkai atau logo dari bagian “Aset & tanda tangan”, lalu coba lagi.';

  @override
  String alpNoFilteredAssets(Object type) {
    return 'Tidak ada aset bertipe “$type”.';
  }

  @override
  String get authWelcomeBack => 'Selamat datang di JoodCraft.';

  @override
  String get authResetLinkSent =>
      'Tautan atur ulang telah dikirim. Periksa email Anda.';

  @override
  String get authLogin => 'Masuk';

  @override
  String get authLoginSubtitle =>
      'Email dan kata sandi Anda untuk melanjutkan ke dasbor.';

  @override
  String get authNoAccount => 'Belum punya akun?';

  @override
  String get authCreateAccountLink => 'Buat akun baru';

  @override
  String get authConfirmEmailThenLogin =>
      'Akun Anda telah dibuat. Konfirmasikan email Anda terlebih dahulu, lalu masuk.';

  @override
  String get authEmail => 'Email';

  @override
  String get authPassword => 'Kata sandi';

  @override
  String get authForgotPassword => 'Lupa kata sandi?';

  @override
  String get authEnterDashboard => 'Masuk ke dasbor';

  @override
  String get authResetPassword => 'Atur ulang kata sandi';

  @override
  String get authResetPasswordHint =>
      'Masukkan email Anda dan kami akan mengirim tautan atur ulang kata sandi.';

  @override
  String get authSendLink => 'Kirim tautan';

  @override
  String get authConfirmEmailMessage =>
      'Akun Anda telah dibuat. Periksa email untuk mengonfirmasi, lalu masuk.';

  @override
  String get authAccountCreatedWelcome =>
      'Akun Anda telah dibuat. Selamat datang di JoodCraft.';

  @override
  String get authCreateAccount => 'Buat akun';

  @override
  String get authRegisterSubtitle =>
      'Akun Anda menyimpan templat dan aset (logo, tanda tangan, segel) untuk digunakan di semua proyek.';

  @override
  String get authHaveAccount => 'Sudah punya akun?';

  @override
  String get authFullName => 'Nama lengkap';

  @override
  String get authFullNameHint => 'mis. Abdullah Al-Ahmad';

  @override
  String get authName => 'Nama';

  @override
  String get authOrgName => 'Nama organisasi (opsional)';

  @override
  String get authOrgNameHint => 'mis. Yayasan Amal Jood';

  @override
  String get authOrgHelper => 'Tercetak otomatis pada sertifikat dan kontrak.';

  @override
  String get authOrgNameShort => 'Nama organisasi';

  @override
  String get authPasswordHint => 'Minimal 8 karakter';

  @override
  String authPasswordRule(Object min) {
    return 'Gunakan minimal $min karakter dengan angka dan simbol.';
  }

  @override
  String get authConfirmPassword => 'Konfirmasi kata sandi';

  @override
  String get authCreateAccountButton => 'Buat akun';

  @override
  String get authFeatureLocalExcel =>
      'Pemrosesan lokal penuh berkas Excel — data Anda tidak meninggalkan perangkat';

  @override
  String get authFeaturePdf =>
      'Pembuatan PDF dengan font Arab berkualitas tinggi dan dukungan RTL penuh';

  @override
  String get authFeatureTemplates =>
      'Templat Anda tersimpan di akun Anda dan siap digunakan kembali';

  @override
  String get authTagline =>
      'Sertifikat dan kontrak resmi Anda… dicetak dengan percaya diri.';

  @override
  String authVersion(Object name, Object version) {
    return '$name • Versi $version';
  }

  @override
  String get dashModules => 'Modul platform';

  @override
  String dashWelcome(Object name) {
    return 'Selamat datang, $name';
  }

  @override
  String dashSubscription(Object tier) {
    return 'Langganan: $tier';
  }

  @override
  String dashOrg(Object name) {
    return 'Organisasi: $name';
  }

  @override
  String get dashOrgMissing =>
      'Anda belum menetapkan nama organisasi — akan dicetak otomatis pada sertifikat dan kontrak.';

  @override
  String get dashOpenModule => 'Buka modul';

  @override
  String get destDashboard => 'Dasbor';

  @override
  String get destDashboardDesc => 'Ringkasan proyek dan templat Anda.';

  @override
  String get destCertificates => 'Mesin sertifikat';

  @override
  String get destCertificatesDesc =>
      'Desain sertifikat lanskap dari templat yang dapat diedit.';

  @override
  String get destContracts => 'Mesin kontrak';

  @override
  String get destContractsDesc => 'Susun kontrak potret dengan bidang dinamis.';

  @override
  String get destBatch => 'Pembuatan massal';

  @override
  String get destBatchDesc =>
      'Baca berkas Excel secara lokal dan buat ratusan sertifikat sekaligus.';

  @override
  String get destTemplates => 'Pustaka templat';

  @override
  String get destTemplatesDesc =>
      'Kelola, atur, dan gunakan kembali templat yang tersimpan.';

  @override
  String get destAssets => 'Aset & tanda tangan';

  @override
  String get destAssetsDesc => 'Logo, segel, tanda tangan, dan bingkai Anda.';

  @override
  String get dashUser => 'Pengguna';

  @override
  String get dashLogoutSuccess => 'Anda berhasil keluar.';

  @override
  String get dashLogoutError => 'Tidak dapat keluar. Coba lagi.';

  @override
  String get commonSave => 'Simpan';

  @override
  String get commonPreview => 'Pratinjau';

  @override
  String get commonOptions => 'Opsi';

  @override
  String get tplDelete => 'Hapus';

  @override
  String get tplSortRecentlyUpdated => 'Terbaru diperbarui';

  @override
  String get tplSortTitleAsc => 'Nama (A–Z)';

  @override
  String get tplSortLabel => 'Urutkan';

  @override
  String get tplSubtitle =>
      'Templat siap pakai profesional + templat tersimpan Anda — cari, filter, buka, dan impor, sepenuhnya offline.';

  @override
  String get tplRefreshTooltip => 'Segarkan daftar';

  @override
  String get tplSearchHint => 'Cari templat…';

  @override
  String get tplNoResultsTitle => 'Tidak ada hasil yang cocok';

  @override
  String get tplNoResultsMessage =>
      'Coba kata kunci lain atau atur ulang filter.';

  @override
  String tplAddedToLocal(Object title) {
    return '“$title” ditambahkan ke templat lokal Anda.';
  }

  @override
  String get tplCloudRequiresConnection =>
      'Menyimpan templat ke cloud memerlukan koneksi ke proyek Supabase. Simpan secara lokal.';

  @override
  String tplSavedToCloud(Object title) {
    return '“$title” disimpan ke cloud.';
  }

  @override
  String get tplRenamed => 'Templat telah diganti nama.';

  @override
  String tplCopySuffix(Object title) {
    return '$title (salinan)';
  }

  @override
  String tplCopyCreated(Object title) {
    return 'Salinan “$title” dibuat.';
  }

  @override
  String get tplNowPrivate => 'Templat sekarang privat.';

  @override
  String get tplNowPublic =>
      'Templat sekarang publik (hanya baca untuk orang lain).';

  @override
  String tplConfirmCloudDelete(Object title) {
    return '“$title” akan dihapus permanen dari cloud. Tidak dapat dibatalkan.';
  }

  @override
  String tplCloudDeleted(Object title) {
    return 'Templat “$title” dihapus.';
  }

  @override
  String tplConfirmLocalDelete(Object title) {
    return '“$title” akan dihapus dari perangkat ini. Templat siap pakai yang asli tetap tersedia di pustaka.';
  }

  @override
  String tplLocalDeleted(Object title) {
    return 'Templat lokal “$title” dihapus.';
  }

  @override
  String get tplDeleteTitle => 'Hapus templat';

  @override
  String get tplRenameTitle => 'Judul templat';

  @override
  String get tplFieldTitle => 'Judul';

  @override
  String tplPreviewLabel(Object title) {
    return 'Pratinjau: $title';
  }

  @override
  String tplCount(Object count) {
    return '$count templat';
  }

  @override
  String tplCloudLoadError(Object message) {
    return 'Tidak dapat memuat templat cloud: $message';
  }

  @override
  String get tplPublicBadge => 'Templat publik';

  @override
  String get tplOrientationLandscape => 'Lanskap';

  @override
  String get tplOrientationPortrait => 'Potret';

  @override
  String get tplPresetOffline => 'Templat siap pakai • tersedia offline';

  @override
  String tplSchemaVersion(Object version) {
    return 'Skema v$version';
  }

  @override
  String get tplOpenAsTemplate => 'Buka sebagai templat';

  @override
  String get tplOpen => 'Buka';

  @override
  String get tplUseInBatch => 'Gunakan dalam pembuatan massal';

  @override
  String get tplImportLocal => 'Impor secara lokal';

  @override
  String get tplSaveToCloud => 'Simpan ke cloud';

  @override
  String get tplDeleteLocal => 'Hapus secara lokal';

  @override
  String get tplRename => 'Ganti nama';

  @override
  String get tplMakePrivate => 'Jadikan privat';

  @override
  String get tplMakePublic => 'Jadikan publik';

  @override
  String get tplNoDate => 'Tanpa tanggal';

  @override
  String get amSubtitle =>
      'Unggah logo, segel, dan tanda tangan Anda sekali, lalu sisipkan ke templat mana pun — tersimpan di perangkat Anda dan digunakan offline.';

  @override
  String get amSearchHint => 'Cari aset…';

  @override
  String get amTypeLabel => 'Jenis';

  @override
  String get amUploadTooltip => 'Unggah aset baru';

  @override
  String get amUpload => 'Unggah aset';

  @override
  String get amEmptyTitle => 'Belum ada aset';

  @override
  String get amEmptyMessage =>
      'Unggah logo, tanda tangan, atau segel organisasi Anda, lalu sisipkan ke templat mana pun dari bilah properti gambar.';

  @override
  String get amNoResultsMessage => 'Coba nama lain atau atur ulang filter.';

  @override
  String get amRenamed => 'Aset telah diganti nama.';

  @override
  String amMovedToType(Object type) {
    return 'Aset dipindahkan ke “$type”.';
  }

  @override
  String get amDeleteTitle => 'Hapus aset';

  @override
  String amConfirmDelete(Object name) {
    return '“$name” akan dihapus dari perangkat ini. Templat yang memakainya akan kehilangan gambar (tanpa kegagalan cetak).';
  }

  @override
  String amDeleted(Object name) {
    return 'Aset “$name” dihapus.';
  }

  @override
  String get amRenameTitle => 'Ganti nama aset';

  @override
  String amCount(Object count) {
    return '$count aset';
  }

  @override
  String amMakeType(Object type) {
    return 'Jadikan jenis: $type';
  }

  @override
  String get amCacheLabel => 'Cache gambar di disk';

  @override
  String amCacheUsage(Object count, Object size) {
    return '$count berkas · $size';
  }

  @override
  String amCacheUsageOf(Object count, Object used, Object limit) {
    return '$count berkas · $used dari $limit';
  }

  @override
  String get amCacheEmpty => 'Belum ada cache disk';

  @override
  String get amCacheClear => 'Bersihkan cache';

  @override
  String get amCacheCleared => 'Cache gambar di disk telah dibersihkan.';

  @override
  String get commonRetry => 'Coba lagi';

  @override
  String get commonPrint => 'Cetak';

  @override
  String get commonExportPdf => 'Ekspor PDF';

  @override
  String get commonExportFailed => 'Tidak dapat mengekspor berkas PDF.';

  @override
  String get commonPrintFailed => 'Tidak dapat mengirim berkas ke printer.';

  @override
  String commonExportReady(Object name) {
    return 'Berkas siap disimpan sebagai $name.';
  }

  @override
  String get commonGenerating => 'Menghasilkan…';

  @override
  String get commonDataPanelTitle => 'Data contoh';

  @override
  String evElementCount(Object count) {
    return '$count elemen';
  }

  @override
  String get evStatusDynamicFields => ' • bidang dinamis';

  @override
  String get evStatusUnsaved => ' • perubahan belum disimpan';

  @override
  String get tevNewTemplateTitle => 'Templat baru';

  @override
  String get tevUnsavedTitle => 'Perubahan belum disimpan';

  @override
  String tevUnsavedMessage(Object title) {
    return 'Anda memiliki perubahan belum disimpan pada “$title”. Simpan sebelum keluar?';
  }

  @override
  String get tevLeaveWithoutSaving => 'Keluar tanpa menyimpan';

  @override
  String get tevSaveAndLeave => 'Simpan dan keluar';

  @override
  String get tevViewMode => 'Mode tampilan';

  @override
  String get tevModeEditor => 'Editor';

  @override
  String get tevModePreview => 'Pratinjau PDF';

  @override
  String get tevPaperDirection => 'Orientasi kertas';

  @override
  String get tevWidthCm => 'Lebar (cm)';

  @override
  String get tevHeightCm => 'Tinggi (cm)';

  @override
  String get tevUndo => 'Urungkan (Ctrl+Z)';

  @override
  String get tevRedo => 'Ulangi (Ctrl+Y)';

  @override
  String get tevSnapGrid => 'Kisi penjajaran';

  @override
  String get tevGuidesOn => 'Panduan pintar: aktif (matikan)';

  @override
  String get tevGuidesOff => 'Panduan pintar: nonaktif (nyalakan)';

  @override
  String get tevZoom => 'Zoom';

  @override
  String get tevDocumentBackground => 'Latar dokumen';

  @override
  String get tevFrameFromLibrary => 'Bingkai dari pustaka aset saya';

  @override
  String get tevChangeTitle => 'Ubah judul templat';

  @override
  String get tevMyTemplates => 'Templat saya';

  @override
  String get tevSaveAs => 'Simpan sebagai';

  @override
  String get tevSaveTemplate => 'Simpan templat';

  @override
  String get tevSaveUnavailable => 'Penyimpanan tidak tersedia';

  @override
  String get tevSaveNeedsSupabase =>
      'Menyimpan memerlukan koneksi ke proyek Supabase. Jalankan aplikasi dengan kunci proyek Anda (env.json) untuk menyimpan templat.';

  @override
  String tevMissingAssets(Object list) {
    return 'Aset hilang: $list — pilih ulang bingkai/aset dari “Pustaka aset saya” agar tidak kosong.';
  }

  @override
  String get tevTemplateLibraryNeedsSupabase =>
      'Pustaka templat memerlukan koneksi ke proyek Supabase.';

  @override
  String tevOpenedTemplate(Object title) {
    return '“$title” dibuka.';
  }

  @override
  String get tevTitleHint =>
      'mis. sertifikat penyelesaian kursus Manajemen Proyek';

  @override
  String get tevContinue => 'Lanjutkan';

  @override
  String get tevSavedTemplates => 'Templat tersimpan saya';

  @override
  String get tevNoSavedTemplates =>
      'Belum ada templat tersimpan. Simpan dari tombol “Simpan templat”.';

  @override
  String get ecIncrease => 'Tambah';

  @override
  String get ecDecrease => 'Kurangi';

  @override
  String get ecQuickPalette => 'Palet cepat';

  @override
  String get ecFullPicker => 'Pemilih warna lengkap';

  @override
  String get ecRemoveColor => 'Hapus warna';

  @override
  String get ecNone => 'Tidak ada';

  @override
  String get ecPickColorTitle => 'Pilih warna';

  @override
  String get ecApply => 'Terapkan';

  @override
  String tevBackgroundAdded(Object name) {
    return '“$name” ditambahkan sebagai latar dokumen.';
  }

  @override
  String get cfpUploadTooltip => 'Unggah font khusus (.ttf / .otf)';

  @override
  String get cfpManageTooltip => 'Kelola font yang diunggah';

  @override
  String get cfpNotice =>
      'Font yang diunggah hanya disimpan di perangkat Anda dan langsung digunakan di sini dan saat mencetak — tanpa internet.';

  @override
  String get cfpMyFonts => 'Font khusus saya';

  @override
  String get cfpNoFonts => 'Belum ada font diunggah';

  @override
  String get cfpBuiltinOption => 'Tidak ada (font bawaan)';

  @override
  String get cfpGroupBuiltin => 'Font bawaan';

  @override
  String get cfpGroupUploaded => 'Font yang saya unggah';

  @override
  String get cfpGroupSystem => 'Font sistem';

  @override
  String get cfpSearchHint => 'Cari font…';

  @override
  String get cfpNoMatch => 'Tidak ada font yang cocok.';

  @override
  String get cfpPickTitle => 'Pilih berkas font (TTF atau OTF)';

  @override
  String cfpPickerError(Object error) {
    return 'Tidak dapat membuka pemilih berkas: $error';
  }

  @override
  String cfpReadError(Object name, Object error) {
    return 'Tidak dapat membaca \"$name\": $error';
  }

  @override
  String get cfpFontAdded => 'Font ditambahkan dan langsung diterapkan.';

  @override
  String cfpFontsAdded(Object count) {
    return '$count font ditambahkan.';
  }

  @override
  String get cfpLibraryTitle => 'Pustaka font khusus saya';

  @override
  String get cfpLibraryNotice =>
      'Semua font hanya disimpan di perangkat Anda. Peringatan: menghapus font yang dipakai templat mengembalikan templat itu ke font bawaan alih-alih gagal.';

  @override
  String get cfpEmpty => 'Belum ada font yang diunggah.';

  @override
  String get cfpCoverageFull => 'Cakupan Arab penuh';

  @override
  String get cfpCoveragePartial => 'Cakupan Arab sebagian';

  @override
  String get cfpUploadNew => 'Unggah font baru';

  @override
  String get ptpPrepError =>
      'Tidak dapat menyiapkan pratinjau. Periksa berkas templat.';

  @override
  String ptpElapsedSize(Object ms, Object kb) {
    return '$ms ms — $kb KB';
  }

  @override
  String get ptpGeneratingNote => '— pratinjau diperbarui otomatis';

  @override
  String get ptpGenerateFailedTitle => 'Tidak dapat membuat pratinjau';

  @override
  String get ptpPreparingTitle => 'Menyiapkan mesin…';

  @override
  String get ptpPreparingMessage =>
      'Font bawaan dimuat dan versi pertama berkas dibuat.';

  @override
  String get ptpShowFailedTitle => 'Tidak dapat menampilkan pratinjau';

  @override
  String cfgOverride(Object override) {
    return 'Build alternatif dengan nilai eksplisit mengalahkan berkas: $override';
  }

  @override
  String get tevBackgroundTitle => 'Latar dokumen dari pustaka aset saya';

  @override
  String get tevAddElement => 'Tambah elemen';

  @override
  String get commonUndo => 'Urungkan';

  @override
  String get bpTitle => 'Pembuatan massal dari Excel';

  @override
  String get bpSubtitle =>
      'Impor berkas .xlsx atau .csv, petakan kolomnya ke bidang templat, lalu buat PDF dengan satu halaman per catatan — semua di perangkat Anda, offline.';

  @override
  String get bpStepTemplate => '1) Templat';

  @override
  String get bpLoadingSampleTemplate => 'Memuat templat contoh…';

  @override
  String bpTemplateInfo(Object name) {
    return 'Templat: $name • bidang wajib:';
  }

  @override
  String get bpLoadingTemplates => 'Memuat templat Anda…';

  @override
  String get bpNoTemplates =>
      'Belum ada templat tersimpan — buat di editor atau impor dari pustaka templat.';

  @override
  String get bpTemplateFromMine => 'Templat dari templat saya';

  @override
  String get bpSampleTemplatesHeader => '— templat contoh —';

  @override
  String bpTemplateEntry(Object title, Object source) {
    return '$title  •  $source';
  }

  @override
  String get bpSourceCloud => 'Cloud';

  @override
  String get bpSourceLocal => 'Lokal';

  @override
  String get bpStepDataFile => '2) Berkas data';

  @override
  String get bpReadingFile => 'Membaca berkas…';

  @override
  String get bpNoFileChosen =>
      'Belum ada berkas dipilih — format yang didukung:';

  @override
  String bpFileSummary(Object name, Object rows, Object cols) {
    return '$name — $rows baris, $cols kolom';
  }

  @override
  String bpSheetSuffix(Object name) {
    return ' (lembar: $name)';
  }

  @override
  String get bpChooseFile => 'Pilih berkas';

  @override
  String get bpRemove => 'Hapus';

  @override
  String get bpHeaderRow => 'Baris tajuk';

  @override
  String bpAutoRow(Object n) {
    return 'Otomatis (baris $n)';
  }

  @override
  String bpRow(Object n) {
    return 'Baris $n';
  }

  @override
  String bpAutoRowLong(Object n) {
    return 'Otomatis — baris $n';
  }

  @override
  String bpRowPreview(Object n, Object preview) {
    return 'Baris $n: $preview';
  }

  @override
  String get bpEmptyRow => '(baris kosong)';

  @override
  String get bpWorksheet => 'Lembar kerja';

  @override
  String get bpPickDataFile => 'Pilih berkas data (Excel atau CSV)';

  @override
  String bpReadFileError(Object error) {
    return 'Tidak dapat membaca berkas: $error';
  }

  @override
  String bpFileReadRows(Object rows, Object cols) {
    return 'Berkas dibaca secara lokal: $rows baris dan $cols kolom.';
  }

  @override
  String bpSaveError(Object error) {
    return 'Tidak dapat menyimpan perubahan ke templat: $error';
  }

  @override
  String get bpMapFieldTitle => 'Tetapkan bidang dinamis ke elemen ini';

  @override
  String get bpMapFieldBody =>
      'Hanya teks elemen ini yang diganti dengan bidang; elemen lain tidak terpengaruh.';

  @override
  String get bpUndoConvert => 'Konversi dibatalkan.';

  @override
  String get bpUndoConvertSaved =>
      'Konversi dibatalkan dan teks dipulihkan di templat.';

  @override
  String bpRestoreError(Object error) {
    return 'Tidak dapat memulihkan teks di templat: $error';
  }

  @override
  String bpGeneratedReport(Object count) {
    return '$count catatan dibuat';
  }

  @override
  String bpSkippedSuffix(Object count) {
    return ' dan $count dilewati';
  }

  @override
  String get bpReadyToSave => 'Berkas siap disimpan.';

  @override
  String get bpStepMapping => '3) Petakan kolom ke bidang';

  @override
  String get bpChooseFileFirst =>
      'Pilih berkas dulu untuk menampilkan tabel pemetaan.';

  @override
  String get bpNoDynamicFields =>
      'Tidak ada bidang dinamis di templat saat ini.';

  @override
  String bpMappedCount(Object mapped, Object total) {
    return '$mapped dari $total kolom dipetakan';
  }

  @override
  String get bpAutoMapHint =>
      'Setelah memilih berkas, pemetaan otomatis pintar disarankan; Anda dapat mengedit tiap kolom.';

  @override
  String get bpNoFieldsHelp =>
      'Templat terpilih tidak punya bidang dinamis, jadi tidak ada yang dipetakan ke kolom berkas. Buka templat di editor, sisipkan “bidang dinamis” di slot nama, simpan, lalu coba lagi.';

  @override
  String get bpAutoMap => 'Pemetaan otomatis';

  @override
  String get bpClearMapping => 'Hapus pemetaan';

  @override
  String get bpNameFieldWarning =>
      'Templat ini tidak punya bidang nama dinamis — jangan petakan kolom nama ke bidang tanggal atau referensi, atau nama bisa tercetak di tempat yang salah. Pilih kunci nama dari daftar kolom, atau ubah teks nama tetap di editor menjadi bidang dinamis.';

  @override
  String bpStaticNameHints(Object preview) {
    return 'Teks tetap yang mirip nama: “$preview” — tidak ada bidang dinamis yang menggantinya.';
  }

  @override
  String get bpConvertToNameField => 'Ubah menjadi bidang nama peserta';

  @override
  String bpDuplicateField(Object field) {
    return 'Bidang “$field” dipetakan ke lebih dari satu kolom. Petakan tiap bidang ke satu kolom.';
  }

  @override
  String bpUnmappedColumns(Object count) {
    return '$count kolom tak dipetakan — datanya tidak dipakai di sertifikat.';
  }

  @override
  String bpColumn(Object n) {
    return 'Kolom $n';
  }

  @override
  String get bpEmptyCell => '(kosong)';

  @override
  String get bpUnmapped => '— tidak dipetakan —';

  @override
  String get bpStepMissing => '4) Sel kosong dan data hilang';

  @override
  String get bpNoNotes => 'Tidak ada catatan sebelum memilih berkas.';

  @override
  String get bpStepGenerate => '5) Hasilkan';

  @override
  String bpGenerating(Object progress) {
    return 'Menghasilkan… $progress';
  }

  @override
  String get bpGenerateHint =>
      'Satu berkas PDF, satu halaman per catatan yang dibuat.';

  @override
  String get bpGeneratePickFile =>
      'Pilih berkas data dulu untuk mengaktifkan pembuatan.';

  @override
  String get bpMappingInvalid =>
      'Pemetaan tidak valid — bidang yang sama dipetakan ke dua kolom.';

  @override
  String get bpMapAtLeastOne =>
      'Petakan minimal satu kolom ke bidang templat untuk mengaktifkan pembuatan.';

  @override
  String get bpGenerateCertificates => 'Buat sertifikat';

  @override
  String get bpRegenerate => 'Buat ulang';

  @override
  String get bpStatGenerated => 'Dibuat';

  @override
  String get bpStatSkipped => 'Dilewati';

  @override
  String get bpStatPages => 'Halaman';

  @override
  String get bpStatSize => 'Ukuran';

  @override
  String bpKilobytes(Object value) {
    return '$value KB';
  }

  @override
  String get bpStatTime => 'Waktu';

  @override
  String bpMilliseconds(Object value) {
    return '$value ms';
  }

  @override
  String bpCompletion(Object pct, Object total) {
    return '$pct% selesai dari $total baris.';
  }

  @override
  String get bpSkippedRows => 'Baris yang tidak dibuat:';

  @override
  String bpRowSkipReason(Object n, Object reason) {
    return 'Baris $n: $reason';
  }

  @override
  String get bpPreviewHere => 'Pratinjau muncul di sini';

  @override
  String get bpPreviewHint =>
      'Pilih berkas data, sesuaikan pemetaan, lalu tekan “Buat sertifikat” — halaman pertama berkas yang dibuat muncul di sini.';

  @override
  String get bpAssignByTapTitle => 'Tetapkan bidang dengan mengetuk';

  @override
  String get bpAssignByTapBody =>
      'Ketuk teks mana pun di templat untuk menetapkannya ke bidang dinamis sendiri. Elemen lain tidak terpengaruh — bukan tanggal, nama manajer, atau teks tetap apa pun.';

  @override
  String get bpNoTexts => 'Tidak ada teks di templat ini.';

  @override
  String get bpEmptyText => '(teks kosong)';

  @override
  String get bpDynamicFieldTap => 'Bidang dinamis — ketuk untuk mengubah';

  @override
  String get bpStaticTextTap => 'Teks tetap — ketuk untuk menetapkan';

  @override
  String get bpAssignField => 'Tetapkan bidang';

  @override
  String get bpKindCertificate => 'Sertifikat';

  @override
  String get bpKindContract => 'Kontrak';

  @override
  String bpLoadSampleError(Object error) {
    return 'Tidak dapat memuat templat contoh: $error';
  }

  @override
  String bpReadSheetError(Object error) {
    return 'Tidak dapat membaca lembar: $error';
  }

  @override
  String bpUpdateHeaderRowError(Object error) {
    return 'Tidak dapat memperbarui baris tajuk: $error';
  }

  @override
  String get bpChooseTemplateFirst =>
      'Pilih templat (sertifikat atau kontrak) sebelum membuat.';

  @override
  String bpBatchTitle(Object kind) {
    return '$kind massal — JoodCraft';
  }

  @override
  String bpGenerateError(Object error) {
    return 'Tidak dapat menjalankan pembuatan massal: $error';
  }

  @override
  String get bpWarnNoDynamicFields =>
      'Templat ini tidak punya bidang dinamis — data tidak berubah antar catatan. Tambahkan bidang “nama peserta” dari bilah editor, lalu simpan templat.';

  @override
  String get bpWarnNoNameField =>
      'Templat ini tidak punya bidang nama dinamis — kolom nama bisa dipetakan ke bidang tanggal atau referensi dan nama tercetak di tempat yang salah. Ubah teks nama tetap menjadi bidang atau rancang ulang templat.';

  @override
  String bpAssignedTemp(Object token) {
    return 'Elemen ini ditetapkan ke $token untuk pembuatan saat ini — elemen lain tidak terpengaruh. Simpan templat agar perubahan permanen.';
  }

  @override
  String bpAssignedSaved(Object token) {
    return 'Elemen ini ditetapkan ke $token dan perubahan disimpan ke templat. Elemen lain tidak terpengaruh.';
  }

  @override
  String get commonShow => 'Tampilkan';

  @override
  String get commonHide => 'Sembunyikan';

  @override
  String get themeSwitchToLight => 'Beralih ke tema terang';

  @override
  String get themeSwitchToDark => 'Beralih ke tema gelap';

  @override
  String commonComingSoonPhase(Object phase) {
    return 'Sedang berjalan — tahap $phase';
  }

  @override
  String get cbNewCertificateTitle => 'Sertifikat baru';

  @override
  String get cbNewContractTitle => 'Kontrak baru';

  @override
  String get cbBeneficiaryDataTitle => 'Data penerima (contoh)';

  @override
  String get cbContractDataTitle => 'Data kontrak (contoh)';

  @override
  String get editorSendBackward => 'Kirim ke belakang';

  @override
  String get editorRotateLeft => 'Putar 90° kiri';

  @override
  String get editorRotateRight => 'Putar 90° kanan';

  @override
  String get editorFlipH => 'Balik horizontal';

  @override
  String get editorFlipV => 'Balik vertikal';

  @override
  String get editorTransform => 'Transformasi';

  @override
  String get editorToolSelect => 'Pilih';

  @override
  String get editorToolShapes => 'Bentuk';

  @override
  String get editorFillType => 'Jenis isian';

  @override
  String get editorFillSolid => 'Padat';

  @override
  String get editorGradientLinear => 'Gradien linear';

  @override
  String get editorGradientRadial => 'Gradien radial';

  @override
  String get editorGradientAngle => 'Sudut gradien';

  @override
  String get editorShadowEnable => 'Tambah bayangan';

  @override
  String get editorShadowColor => 'Warna bayangan';

  @override
  String get editorShadowBlur => 'Buram bayangan';

  @override
  String get editorShadowOffsetX => 'Geser X';

  @override
  String get editorShadowOffsetY => 'Geser Y';

  @override
  String get editorShadowSpread => 'Sebar';

  @override
  String get editorShadowRemove => 'Hapus bayangan';

  @override
  String get editorPoints => 'Titik';

  @override
  String get editorInnerRadius => 'Jari-jari dalam';

  @override
  String get editorCornerTopLeft => 'Kiri atas';

  @override
  String get editorCornerTopRight => 'Kanan atas';

  @override
  String get editorCornerBottomRight => 'Kanan bawah';

  @override
  String get editorCornerBottomLeft => 'Kiri bawah';

  @override
  String get editorDashPattern => 'Pola garis putus';

  @override
  String get editorBooleanOps => 'Operasi boolean';

  @override
  String get editorBooleanUnion => 'Gabung';

  @override
  String get editorBooleanSubtract => 'Kurangi';

  @override
  String get editorBooleanIntersect => 'Irisan';

  @override
  String get editorBooleanUngroup => 'Pisahkan';

  @override
  String get paletteStar => 'Bintang';

  @override
  String get palettePolygon => 'Poligon';

  @override
  String get editorBooleanExclude => 'Kecualikan';

  @override
  String get editorBooleanHint =>
      'Jalur gabungan adalah satu hasil boolean (tanpa tepi dalam) dan dapat dipisahkan kapan saja.';

  @override
  String get editorDockTools => 'Panel alat';

  @override
  String get editorDockAnchor => 'Posisi dok';

  @override
  String get editorDockTopBar => 'Bilah atas';

  @override
  String get editorDockInspector => 'Panel samping';

  @override
  String get editorDockLeftRail => 'Rel samping';

  @override
  String get editorDockFloating => 'Mengambang';

  @override
  String get editorDockCollapse => 'Ciutkan alat';

  @override
  String get editorDockExpand => 'Perluas alat';

  @override
  String get editorDockResize => 'Seret untuk mengubah ukuran';

  @override
  String get editorDockDropHint => 'Lepaskan untuk menempel ke';

  @override
  String get editorMoreTools => 'Alat lainnya';

  @override
  String get editorDocumentProperties => 'Properti dokumen';

  @override
  String get editorDockReset => 'Pulihkan dok bawaan';

  @override
  String get editorTextShadow => 'Bayangan teks';

  @override
  String get editorTextShadowAdd => 'Tambahkan bayangan teks';

  @override
  String get editorShadowOpacity => 'Opasitas bayangan';

  @override
  String get genderMale => 'Laki-laki';

  @override
  String get genderFemale => 'Perempuan';

  @override
  String get genderPreviewAutoHint =>
      'Klik untuk membatalkan pemaksaan (otomatis)';

  @override
  String get genderPresetCompleted => '\"completed\" (l./p.)';

  @override
  String get genderPresetPassed => '\"passed\" (l./p.)';

  @override
  String get genderPresetForStudent => '\"untuk siswa\" (l./p.)';

  @override
  String get genderPresetStudent => '\"siswa\" (l./p.)';

  @override
  String get genderPresetToHim => '\"untuk dia (l./p.)\"';

  @override
  String get genderPresetHonoring => '\"peserta terbaik\" (l./p.)';

  @override
  String get editorGenderSnippet => 'Sisipkan frasa bersyarat';

  @override
  String get editorGenderSnippetHint =>
      'Menyisipkan frasa yang berubah otomatis sesuai jenis kelamin penerima.';

  @override
  String get bpGenderReviewTitle => 'Tinjauan jenis kelamin (pria/wanita)';

  @override
  String get bpGenderReviewSubtitle =>
      'Jenis kelamin dideteksi dari nama atau kolom \"Gender\" — perbaiki kasus khusus sebelum mencetak.';

  @override
  String get bpGenderRow => 'Baris';

  @override
  String get bpGenderDetected => 'Terdeteksi';

  @override
  String get bpGenderEffective => 'Diterapkan';

  @override
  String get bpGenderNameColumn => 'Nama';

  @override
  String get bpGenderEditName => 'Ubah nama';

  @override
  String get bpGenderNameHint => 'Tulis nama yang benar';

  @override
  String get bpGenderClearOverrides => 'Hapus koreksi';

  @override
  String get bpGenderOverridden => 'Dikoreksi manual';

  @override
  String get bpGenderUnknownName => '—';

  @override
  String get bpOutputTitle => 'Tujuan penyimpanan sertifikat';

  @override
  String get bpOutputHint =>
      'Pilih folder untuk menyimpan PDF yang dihasilkan, atau mulai dengan lokasi bawaan.';

  @override
  String get bpOutputPickFolder => 'Pilih folder…';

  @override
  String get bpOutputStart => 'Mulai pembuatan';

  @override
  String get bpOutputPathLabel => 'Folder terpilih';

  @override
  String get bpOutputNoFolder =>
      'Tidak ada folder dipilih — hanya cetak dan ekspor.';

  @override
  String get bpOpenFolder => 'Buka folder';

  @override
  String get bpOutputSavedTitle => 'File PDF disimpan';

  @override
  String get bpOpenFolderFailed => 'Tidak dapat membuka folder.';

  @override
  String get bpOutputNameLabel => 'Nama file ekspor';

  @override
  String get bpOutputNameHint => 'Tulis nama tanpa ekstensi';

  @override
  String get bpOutputNamePreviewLabel => 'Akan disimpan sebagai';

  @override
  String get bpOutputModeLabel => 'Mode penyimpanan';

  @override
  String get bpOutputModeCombined => 'Satu file gabungan';

  @override
  String get bpOutputModeIndividual => 'File terpisah per orang';

  @override
  String get hubTitle => 'Proyek baru';

  @override
  String get hubSubtitle =>
      'Pilih ukuran siap pakai atau tentukan sendiri — kanvas terbuka dengan ukuran dan rasio yang tepat.';

  @override
  String get hubKindSingle => 'Cetakan dan dokumen satu lembar';

  @override
  String get hubKindMulti => 'Buku dan publikasi banyak halaman';

  @override
  String get hubKindSingleHint =>
      'Satu lembar: sertifikat, kontrak, kartu, nomor kursi, kartu ucapan.';

  @override
  String get hubKindMultiHint =>
      'Banyak halaman: buku, majalah, buklet, laporan, katalog.';

  @override
  String get hubGroupCertificates => 'Sertifikat dan kontrak';

  @override
  String get hubGroupCards => 'Kartu dan tanda pengenal';

  @override
  String get hubGroupSeat => 'Nomor kursi dan label';

  @override
  String get hubGroupGreeting => 'Kartu ucapan';

  @override
  String get hubGroupPublications => 'Buku dan publikasi';

  @override
  String get hubGroupCustom => 'Ukuran khusus';

  @override
  String get hubDigitalBadge => 'Digital';

  @override
  String get hubCreate => 'Buat';

  @override
  String get hubCustomCardBody =>
      'Masukkan dimensi Anda dalam satuan apa pun dan mulai dengan kanvas sesuai ukuran Anda.';

  @override
  String get hubCustomName => 'Nama proyek';

  @override
  String get hubCustomNameHint => 'mis. Kartu undangan';

  @override
  String get hubCustomPreview => 'Ukuran akhir';

  @override
  String get hubCustomCreate => 'Buat kanvas';

  @override
  String get hubCustomType => 'Jenis proyek';

  @override
  String get hubSearchHint => 'Cari ukuran…';

  @override
  String get hubNoResults =>
      'Tidak ada ukuran yang cocok — coba kata kunci lain.';

  @override
  String get hubAspectRatio => 'Rasio';

  @override
  String get destNewProject => 'Proyek baru';

  @override
  String get destNewProjectDesc =>
      'Pilih ukuran siap pakai atau khusus dan mulai mendesain segera.';

  @override
  String get ptpImpositionToggle => 'Penataan cetak';

  @override
  String get ptpImpositionNoFit =>
      'Lembar terlalu kecil untuk item ini — kurangi margin atau pilih lembar yang lebih besar.';

  @override
  String get editorEffectsTitle => 'Efek & penyesuaian warna';

  @override
  String get editorShadowGroup => 'Bayangan';

  @override
  String get editorOuterGlow => 'Cahaya luar';

  @override
  String get editorInnerGlow => 'Cahaya dalam';

  @override
  String get editorGlowAdd => 'Tambah cahaya';

  @override
  String get editorGlowRemove => 'Hapus cahaya';

  @override
  String get editorGlowColor => 'Warna cahaya';

  @override
  String get editorGlowRadius => 'Radius cahaya';

  @override
  String get editorGlowSpread => 'Sebaran cahaya';

  @override
  String get editorGlowOpacity => 'Opasitas cahaya';

  @override
  String get editorAdjustGroup => 'Penyesuaian warna';

  @override
  String get editorAdjustBrightness => 'Kecerahan';

  @override
  String get editorAdjustContrast => 'Kontras';

  @override
  String get editorAdjustSaturation => 'Saturasi';

  @override
  String get editorAdjustHue => 'Hue';

  @override
  String get editorAdjustReset => 'Atur ulang';

  @override
  String get bpOutputSavedFolderTitle => 'File disimpan di folder khusus';

  @override
  String get hubDetailsTitle => 'Detail ukuran';

  @override
  String get hubDetailsHint =>
      'Spesifikasi bawaan yang terisi — pilih ukuran di kisi atau ubah dimensinya.';

  @override
  String get hubFilterAll => 'Semua';

  @override
  String get hubFilterRecent => 'Ukuran terbaru';

  @override
  String get hubFilterSeat => 'Nomor kursi';

  @override
  String get hubFilterGreeting => 'Ucapan dan layar';

  @override
  String get hubRecentEmpty =>
      'Belum ada ukuran terbaru — proyek yang Anda buat akan muncul di sini.';

  @override
  String get hubDocTitle => 'Nama proyek';

  @override
  String get hubDocTitleHint => 'Proyek baru - 1';

  @override
  String get hubWidth => 'Lebar';

  @override
  String get hubHeight => 'Tinggi';

  @override
  String get hubUnitLabel => 'Satuan';

  @override
  String get hubOrientationLabel => 'Orientasi';

  @override
  String get hubPortrait => 'Potret';

  @override
  String get hubLandscape => 'Lanskap';

  @override
  String get hubVariantLabel => 'Jenis';

  @override
  String get hubResolutionLabel => 'Resolusi';

  @override
  String get hubResolutionUnitLabel => 'Satuan resolusi';

  @override
  String get hubColorModeLabel => 'Mode warna';

  @override
  String get hubBackgroundLabel => 'Warna latar';

  @override
  String get hubBackgroundWhite => 'Putih';

  @override
  String get hubBackgroundTransparent => 'Transparan';

  @override
  String get hubBackgroundBlack => 'Hitam';

  @override
  String get hubBackgroundCustom => 'Warna khusus';

  @override
  String get hubCreateProject => 'Buat proyek';

  @override
  String get hubCustomFamilyTitle => 'Ukuran khusus';

  @override
  String get newDocTitle => 'Dokumen baru';

  @override
  String get newDocScopeSocial => 'Layar dan ucapan';

  @override
  String get newDocFilterCertificates => 'Sertifikat';

  @override
  String get newDocFilterCards => 'Kartu';

  @override
  String get newDocFilterGreeting => 'Ucapan';

  @override
  String get newDocFilterPublications => 'Publikasi';

  @override
  String get menuFile => 'Berkas';

  @override
  String get menuEdit => 'Sunting';

  @override
  String get menuView => 'Tampilan';

  @override
  String get menuTools => 'Alat';

  @override
  String get menuHelp => 'Bantuan';

  @override
  String get menuNewDocument => 'Dokumen baru…';

  @override
  String get menuPurgeRecent => 'Bersihkan ukuran terbaru';

  @override
  String get menuPurgeImageCache => 'Bersihkan cache gambar';

  @override
  String get menuPreviewCertificate => 'Pratinjau contoh sertifikat';

  @override
  String get menuPreviewContract => 'Pratinjau contoh kontrak';

  @override
  String get menuAbout => 'Tentang JoodCraft';

  @override
  String get actionNewShort => '+ Baru';

  @override
  String get dashLocalMode => 'Lokal';

  @override
  String get dashLocalStorage =>
      'Disimpan secara lokal di perangkat ini — tidak ada proyek yang diunggah ke server.';

  @override
  String get dashRecentProjects => 'Proyek terbaru';

  @override
  String get dashRecentEmpty =>
      'Belum ada proyek tersimpan di perangkat ini — buat dokumen baru dan langsung muncul di sini.';

  @override
  String get dashRecentOpen => 'Buka proyek';

  @override
  String get editorTransformPosition => 'Transformasi & Posisi';

  @override
  String get editorTransformPositionHint => 'Posisi, ukuran dan sudut rotasi';

  @override
  String get editorAppearanceEffects => 'Tampilan & Efek';

  @override
  String get editorAppearanceEffectsHint =>
      'Isian, garis tepi, cahaya dan bayangan';

  @override
  String get editorTypographyHint => 'Font, ukuran, perataan dan spasi';

  @override
  String get editorPageSettingsHint => 'Ukuran dan satuan ukur';

  @override
  String get editorBackgroundHint => 'Warna atau gradien halaman';

  @override
  String get editorPrecisionHint => 'Geser halus dan skala';

  @override
  String get joodExportProject => 'Ekspor proyek (.jood)';

  @override
  String get joodImportProject => 'Buka proyek (.jood)';

  @override
  String get joodExportReady => 'File proyek siap disimpan.';

  @override
  String get joodExportFailed => 'Tidak dapat mengekspor file proyek.';

  @override
  String get joodImportOpened => 'Proyek yang diimpor dibuka.';

  @override
  String get joodImportFailed => 'Tidak dapat membuka file proyek.';

  @override
  String get joodRecoveryTitle => 'Draf belum disimpan';

  @override
  String get joodRecoveryMessage =>
      'Ada draf yang belum disimpan dari sesi sebelumnya. Apakah Anda ingin memulihkannya?';

  @override
  String get joodRecoveryRestore => 'Pulihkan';

  @override
  String get joodRecoveryDiscard => 'Abaikan';

  @override
  String get joodRecoveryRestored => 'Draf dipulihkan.';

  @override
  String get joodAutosaveSaved => 'Disimpan otomatis';

  @override
  String get joodAutosaveSaving => 'Menyimpan…';

  @override
  String get editorConfirm => 'Konfirmasi';

  @override
  String get admTitle => 'Manajemen admin lokal';

  @override
  String get admRefresh => 'Segarkan';

  @override
  String get admTabAdmins => 'Admin';

  @override
  String get admTabTransfer => 'Transfer antar perangkat';

  @override
  String get admTabAudit => 'Log ekspor';

  @override
  String get admListTitle => 'Akun admin di perangkat ini';

  @override
  String get admAdd => 'Tambah admin';

  @override
  String get admNoAdmins => 'Belum ada akun admin.';

  @override
  String get admLoading => 'Memuat akun admin di perangkat ini…';

  @override
  String get admRoleOwner => 'Admin utama';

  @override
  String get admCurrent => 'Anda';

  @override
  String get admCurrentCardTitle => 'Akun saat ini di perangkat ini';

  @override
  String get admRoleAdmin => 'Administrator';

  @override
  String get admSwitchTitle => 'Berganti akun cepat';

  @override
  String get admSwitchPrompt =>
      'Pilih nama pengguna lokal admin bawahan di perangkat ini dan masukkan kata sandi lokalnya untuk langsung masuk ke sesinya — draf proyek yang terbuka disimpan lebih dulu, dan lisensi utama tidak terpengaruh.';

  @override
  String get admSwitchNoOthers =>
      'Tidak ada admin bawahan lain di perangkat ini. Tambahkan admin baru dari layar admin terlebih dahulu.';

  @override
  String get admSwitchPick => 'Nama pengguna lokal';

  @override
  String get admSwitchPassword => 'Kata sandi lokal akun terpilih';

  @override
  String get admSwitchPickPassword =>
      'Pilih nama pengguna dan masukkan kata sandi.';

  @override
  String get admSwitchWrongPassword => 'Kata sandi salah.';

  @override
  String get admSwitchFailed => 'Gagal berganti akun. Coba lagi.';

  @override
  String get admSwitchSuccess => 'Akun berhasil diganti.';

  @override
  String get admSwitchAccount => 'Ganti akun';

  @override
  String get admSwitchAction => 'Beralih sekarang';

  @override
  String get admColAdmin => 'Admin';

  @override
  String get admColUsername => 'Nama pengguna lokal';

  @override
  String get admColRole => 'Peran';

  @override
  String get admColCreated => 'Ditambahkan pada';

  @override
  String get admColActions => 'Tindakan';

  @override
  String get destJoodWriter => 'Jood Writer';

  @override
  String get destJoodWriterDesc =>
      'Dokumen dan laporan teks dengan halaman mengalir otomatis.';

  @override
  String get admCreatedAt => 'Dibuat';

  @override
  String get admEdit => 'Ubah detail';

  @override
  String get admChangePassword => 'Ubah kata sandi';

  @override
  String get admPromote => 'Jadikan admin utama';

  @override
  String get admDemote => 'Turunkan menjadi admin';

  @override
  String get admDelete => 'Hapus akun';

  @override
  String admDeleteConfirm(Object name) {
    return '“$name” akan dihapus secara permanen dari perangkat ini. Tindakan ini tidak dapat dibatalkan.';
  }

  @override
  String get admPromoted => 'Dijadikan admin utama.';

  @override
  String get admDemoted => 'Diturunkan menjadi admin.';

  @override
  String get admDeleted => 'Akun dihapus.';

  @override
  String get admCreated => 'Admin baru ditambahkan.';

  @override
  String get admUpdated => 'Detail admin diperbarui.';

  @override
  String get admPasswordChanged => 'Kata sandi diubah.';

  @override
  String get admTransferInfoTitle => 'Bagaimana transfer bekerja?';

  @override
  String get admTransferInfo1 =>
      'Tabel akun (dengan hash kata sandi, bukan kata sandinya) diekspor di dalam file yang dienkripsi dengan frasa sandi pilihan Anda.';

  @override
  String get admTransferInfo2 =>
      'Pindahkan file atau kode ke perangkat lain dan impor di sana dengan frasa sandi yang sama, maka akun berfungsi dengan izin yang sama.';

  @override
  String get admTransferInfo3 =>
      'Tidak ada yang dikirim ke server mana pun: transfer sepenuhnya manual antar perangkat lokal.';

  @override
  String get admExport => 'Ekspor akun';

  @override
  String get admExportPassphrase => 'Frasa sandi ekspor';

  @override
  String get admPassphraseConfirm => 'Konfirmasi frasa sandi';

  @override
  String get admExportRisk =>
      'Saya memahami bahwa siapa pun yang memegang kode ini dan frasa sandinya dapat masuk dengan akun ini, jadi saya akan membagikannya dengan hati-hati.';

  @override
  String get admExportGenerate => 'Buat kode terenkripsi';

  @override
  String get admExportFile => 'Simpan ke file khusus';

  @override
  String get admExportDone =>
      'Kode terenkripsi dibuat. Salin atau simpan ke file.';

  @override
  String get admExportFileSaved => 'File akun terenkripsi disimpan.';

  @override
  String get admPassphraseTooShort =>
      'Gunakan minimal 6 karakter untuk frasa sandi.';

  @override
  String get admPassphraseMismatch => 'Frasa sandi tidak cocok.';

  @override
  String get admAcceptRiskRequired =>
      'Konfirmasi dulu bahwa Anda memahami risiko berbagi kode.';

  @override
  String admFileError(Object error) {
    return 'Tidak dapat menangani file: $error';
  }

  @override
  String get admImport => 'Impor akun';

  @override
  String get admImportCode => 'Kode akun';

  @override
  String get admImportPassphrase => 'Frasa sandi file';

  @override
  String get admImportReplace => 'Ganti kata sandi akun yang sudah ada';

  @override
  String get admImportPick => 'Pilih file';

  @override
  String get admImportRun => 'Impor sekarang';

  @override
  String get admImportCodeRequired =>
      'Tempel kode atau pilih file terlebih dahulu.';

  @override
  String get admImportPassphraseRequired => 'Masukkan frasa sandi file.';

  @override
  String admImportDone(int added, int updated, int skipped) {
    return 'Diimpor: $added baru, $updated diperbarui, $skipped dilewati.';
  }

  @override
  String get admAuditTitle => 'Log sertifikat dan dokumen yang diterbitkan';

  @override
  String get admAuditClear => 'Bersihkan log';

  @override
  String get admAuditEmpty =>
      'Belum ada ekspor. Setiap sertifikat atau kontrak yang Anda ekspor akan dicatat di sini beserta tanggal dan admin yang menerbitkannya.';

  @override
  String get admAuditBy => 'Oleh';

  @override
  String get admAuditPages => 'halaman';

  @override
  String get admAuditClearConfirm =>
      'Seluruh log ekspor akan dihapus dari perangkat ini. Tindakan ini tidak dapat dibatalkan.';

  @override
  String get admAuditCleared => 'Log dibersihkan.';

  @override
  String get admUnavailableTitle => 'Manajemen tidak tersedia saat ini';

  @override
  String get admUnavailableBody =>
      'Manajemen admin berfungsi saat aplikasi berjalan dengan akun lokal (LocalAuthRepository), sehingga akun dibaca dari perangkat ini.';

  @override
  String get pdfExportTypeTitle => 'Jenis ekspor';

  @override
  String get pdfExportTypeHint => 'Pilih format berkas sebelum mengekspor.';

  @override
  String get pdfExportTypeImages => 'Gambar';

  @override
  String get pdfExportTypeImagesDesc => 'Cocok 100% — ukuran lebih besar';

  @override
  String get pdfExportTypeImagesNotCopyable => 'Teks tidak dapat disalin';

  @override
  String get pdfExportTypeVector => 'Vektor';

  @override
  String get pdfExportTypeVectorDesc =>
      'Teks dapat disalin — ukuran lebih kecil';

  @override
  String get pdfExportTypeVectorCopyable => 'Teks dapat disalin dan dicari';

  @override
  String get pdfExportTypeVectorBestFor => 'Ideal untuk pencetakan profesional';

  @override
  String get pdfExportTypeComingSoon => 'Segera hadir';

  @override
  String get pdfExportTypeComingSoonMessage =>
      'Ekspor vektor masih dikembangkan — segera hadir.';

  @override
  String get invCategoryTitle => 'Undangan dan acara';

  @override
  String get invCategoryRamadan => 'Ramadan';

  @override
  String get invCategoryEid => 'Idulfitri';

  @override
  String get invCategoryWedding => 'Pernikahan';

  @override
  String get invRamadan1Title => 'Ramadan Kareem — Klasik';

  @override
  String get invRamadan2Title => 'Ramadan Kareem — Story';

  @override
  String get invEid1Title => 'Idulfitri Mubarak — Klasik';

  @override
  String get invEid2Title => 'Idulfitri Mubarak — Story';

  @override
  String get invWedding1Title => 'Pernikahan — Klasik';

  @override
  String get invWedding2Title => 'Pernikahan — Modern';

  @override
  String get invWedding3Title => 'Pernikahan — Story';

  @override
  String get invSizeA6Portrait => 'A6 potret (105×148 mm)';

  @override
  String get invSizeA6Landscape => 'A6 lanskap (148×105 mm)';

  @override
  String get invSizeSquare148 => 'Persegi cetak (148×148 mm)';

  @override
  String get invSizeA5Folded => 'A5 terlipat (105×148 mm)';

  @override
  String get invSizeInstagramSquare => 'Instagram persegi (1080×1080)';

  @override
  String get invSizeInstagramPortrait => 'Instagram potret (1080×1350)';

  @override
  String get invSizeInstagramStory => 'Instagram Story (1080×1920)';

  @override
  String get invSizeWhatsAppStatus => 'WhatsApp Status (1080×1920)';

  @override
  String get invSizeFacebookPost => 'Facebook Post (1200×630)';

  @override
  String get invExportFormatPNG => 'PNG (untuk media sosial)';

  @override
  String get invExportFormatPDF => 'PDF (untuk dicetak)';

  @override
  String get invExportFormatBoth => 'PNG + PDF';

  @override
  String get invBulkModeTitle => 'Undangan pribadi massal';

  @override
  String get invBulkModeHint => 'Satu kartu per nama — ekspor individual.';

  @override
  String get invPreviewTitle => 'Pratinjau 3 salinan pertama';

  @override
  String get invExportFormat => 'Format ekspor';

  @override
  String get invNameFieldMissing => 'Template ini tidak memiliki kolom nama';

  @override
  String invDuplicateNames(Object count) {
    return 'Nama ganda: $count';
  }

  @override
  String invEmptyNames(Object count) {
    return 'Sel kosong: $count — akan dilewati';
  }

  @override
  String get invZIPOption => 'Kompres ke berkas ZIP';

  @override
  String get invIndexCSVOption => 'Buat indeks CSV';

  @override
  String invProgressText(Object done, Object total) {
    return '$done dari $total dibuat';
  }

  @override
  String get navEditors => 'Editor';

  @override
  String get navLibraries => 'Pustaka';

  @override
  String get navAdmin => 'Administrasi';

  @override
  String get navUser => 'Akun';

  @override
  String get bpWorkTypeLabel => 'Jenis template';

  @override
  String get bpExportFormatLabel => 'Jenis ekspor';

  @override
  String get bpKindInvitation => 'Undangan';

  @override
  String get invPackOptions => 'Opsi keluaran';

  @override
  String get tplCertClassicTitle => 'Sertifikat Klasik Biru Laut';

  @override
  String get tplCertClassicDesc =>
      'Sertifikat biru laut klasik dengan bingkai emas ganda dan bintang sudut hias.';

  @override
  String get tplCertMinimalTitle => 'Sertifikat Minimal Biru Laut';

  @override
  String get tplCertMinimalDesc =>
      'Desain minimal biru laut yang bersih dengan satu garis emas dan ruang lega.';

  @override
  String get tplCertIslamicTitle => 'Sertifikat Ornamen Islami';

  @override
  String get tplCertIslamicDesc =>
      'Sertifikat biru laut dengan tepi emas, ornamen geometris Islami dan huruf Amiri.';

  @override
  String get tplCertBandTitle => 'Sertifikat Pita Emas';

  @override
  String get tplCertBandDesc =>
      'Sertifikat biru laut dengan pita emas horizontal di atas dan bawah.';

  @override
  String get tplCertDiagonalTitle => 'Sertifikat Diagonal Dinamis';

  @override
  String get tplCertDiagonalDesc =>
      'Sertifikat biru laut dengan bentuk geometris emas miring yang memberi kesan gerak.';

  @override
  String get tplCertSquareTitle => 'Sertifikat Persegi Elegan';

  @override
  String get tplCertSquareDesc =>
      'Sertifikat biru laut dengan bingkai emas persegi simetris dan segel lingkaran di atas.';

  @override
  String get navInvitationsEngine => 'Mesin undangan';

  @override
  String get aboutTitle => 'Tentang JoodCraft';

  @override
  String get aboutTagline => 'Buat sertifikat dan kontrak resmi berbahasa Arab';

  @override
  String aboutVersion(Object version) {
    return 'Versi $version';
  }

  @override
  String get aboutSummaryTitle => 'Gambaran umum';

  @override
  String get aboutSummaryBody =>
      'JoodCraft adalah aplikasi desktop dan web yang berjalan sepenuhnya di perangkat Anda: membaca berkas Excel dan membuat sertifikat serta kontrak PDF dengan font Arab yang dibundel. Semua proyek, template, dan aset tersimpan di basis data lokal — tidak ada yang diunggah ke server.';

  @override
  String get aboutFeaturesTitle => 'Fitur utama';

  @override
  String get aboutFeatureOffline =>
      'Sepenuhnya offline: tanpa internet, tanpa mengunggah data';

  @override
  String get aboutFeatureArabicFonts =>
      'Font Arab bawaan dengan pembentukan huruf dan arah RTL yang tepat';

  @override
  String get aboutFeatureExcel =>
      'Membaca Excel dan CSV, memetakan kolom ke field template secara otomatis';

  @override
  String get aboutFeatureBatch =>
      'Buat ratusan sertifikat sekaligus — satu berkas gabungan atau satu per orang';

  @override
  String get aboutFeatureVisualEditor =>
      'Editor visual seret-dan-lepas dengan pilih banyak, batal, dan ulangi';

  @override
  String get aboutFeatureInvitations =>
      'Undangan siap pakai untuk Ramadan, Idulfitri, dan pernikahan dalam ukuran cetak dan media sosial';

  @override
  String get aboutFeatureExports =>
      'Ekspor PDF, PNG, dan proyek Jood yang dapat dibagikan';

  @override
  String get aboutDeveloperTitle => 'Pengembang';

  @override
  String get aboutDeveloperName => 'Seraj Abdullah Al-Badawi';

  @override
  String get aboutDeveloperEmail => 'serajelroh@gmail.com';

  @override
  String get aboutDeveloperStatus => 'Proyek pribadi — dalam pengembangan';

  @override
  String get aboutLicenses => 'Lihat lisensi';

  @override
  String get aboutFeedback => 'Kirim masukan';

  @override
  String get aboutFeedbackCopied =>
      'Email disalin — masukan Anda selalu diterima';

  @override
  String get aboutCreditsTitle => 'Ucapan terima kasih';

  @override
  String get aboutCreditsBody =>
      'Dibangun dengan Flutter dan pustaka sumber terbuka — terima kasih kepada komunitas Flutter dan semua kontributor pustaka tersebut.';

  @override
  String get jwPagesSettings => 'Pengaturan halaman';

  @override
  String get jwPagesMultiple => 'Beberapa halaman';

  @override
  String get jwPagesMultipleHint =>
      'Bagi lembar menjadi dua untuk mencetak dua halaman pada satu lembar';

  @override
  String get jwPagesSingle => 'Normal (satu halaman)';

  @override
  String get jwPagesA4ToA5Portrait => 'A4 → 2 × A5 potret (buklet)';

  @override
  String get jwPagesA4ToA5Landscape => 'A4 → 2 × A5 lanskap';

  @override
  String get jwPagesPreview => 'Pratinjau';

  @override
  String get aboutLinksTitle => 'Tautan';

  @override
  String get aboutDescription =>
      'JoodCraft adalah platform Arab yang lengkap untuk membuat sertifikat, kontrak, dan undangan berkualitas profesional. Rancang satu template secara visual, lalu tautkan ke berkas Excel untuk menghasilkan ratusan dokumen dengan tipografi Arab yang presisi dan arah tulisan yang benar — tanpa internet dan tanpa server.';

  @override
  String get aboutFeatures => 'Fitur';

  @override
  String get aboutFeature10Languages => '10 bahasa yang didukung';

  @override
  String get aboutFeatureArabicText => 'Penghubungan huruf Arab yang presisi';

  @override
  String get aboutFeatureBulkGeneration => 'Pembuatan massal dari Excel';

  @override
  String get aboutFeaturePdfExport => 'Ekspor PDF berkualitas tinggi';

  @override
  String get aboutDeveloper => 'Pengembang';

  @override
  String get aboutDeveloperNote => 'Proyek pribadi — dalam pengembangan';

  @override
  String get aboutLinks => 'Tautan';

  @override
  String get aboutViewLicenses => 'Lihat lisensi';

  @override
  String get aboutSendFeedback => 'Kirim masukan';

  @override
  String get aboutCredits => 'Ucapan terima kasih';

  @override
  String get aboutCreditsText =>
      'JoodCraft dibangun dengan Flutter dan Dart serta pustaka sumber terbuka. Terima kasih kepada semua yang berkontribusi.';

  @override
  String get navInvitationTemplates => 'Template undangan';

  @override
  String get ocrTitle => 'Ekstrak teks dari gambar';

  @override
  String get ocrSubtitle => 'Impor gambar atau PDF dan ekstrak teksnya';

  @override
  String get ocrImportImage => 'Impor gambar';

  @override
  String get ocrImportPdf => 'Impor PDF';

  @override
  String get ocrExtractText => 'Ekstrak teks';

  @override
  String get ocrProcessing => 'Memproses...';

  @override
  String get ocrPreview => 'Pratinjau teks';

  @override
  String get ocrInsertInEditor => 'Sisipkan ke editor';

  @override
  String get ocrCopyToClipboard => 'Salin';

  @override
  String get ocrRetry => 'Coba lagi';

  @override
  String get ocrAccept => 'Terima';

  @override
  String get ocrCancel => 'Batal';

  @override
  String get ocrLanguageLabel => 'Bahasa';

  @override
  String get ocrLanguageArabic => 'Arab';

  @override
  String get ocrLanguageEnglish => 'Inggris';

  @override
  String get ocrLanguageBoth => 'Arab dan Inggris';

  @override
  String get ocrAccuracyNote =>
      'Akurasi ekstraksi mungkin tidak 100% — periksa teks sebelum menyimpan.';

  @override
  String get ocrNoTextFound => 'Tidak ditemukan teks pada gambar.';

  @override
  String get ocrInvalidImage => 'Gambar tidak valid.';

  @override
  String get ocrError => 'Gagal mengekstrak teks. Coba lagi.';

  @override
  String get ocrEngineMissing =>
      'Tesseract tidak ditemukan — pasang lalu coba lagi.';

  @override
  String get ocrLanguageDataMissing =>
      'Data bahasa tidak terpasang bersama Tesseract.';

  @override
  String get ocrNoImage => 'Impor gambar atau PDF terlebih dahulu.';

  @override
  String get ocrCopyDone => 'Teks disalin ke papan klip.';

  @override
  String get ocrConfidence => 'Keyakinan';

  @override
  String get ocrPsmLabel => 'Segmentasi';

  @override
  String get ocrPsmAuto => 'Otomatis';

  @override
  String get ocrPsmBlock => 'Satu blok teks';

  @override
  String get ocrPsmLine => 'Satu baris';

  @override
  String get ocrPsmSparse => 'Teks tersebar';

  @override
  String get ocrScaleLabel => 'Zoom';

  @override
  String get ocrPdfPages => 'Halaman';

  @override
  String get ocrInsertInWriter => 'Sisipkan ke Jood Writer';

  @override
  String get ocrTessHint => 'Memerlukan Tesseract terpasang di perangkat ini.';
}
