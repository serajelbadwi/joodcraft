// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

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
  String get dashRoadmapSupabase =>
      'Menyiapkan basis data Supabase (tabel + RLS + trigger)';

  @override
  String get dashRoadmapModular =>
      'Struktur Modular Feature-First yang dapat diskalakan';

  @override
  String get dashRoadmapTheme =>
      'Tema visual merek dengan dukungan RTL dalam font Cairo';

  @override
  String get dashRoadmapAuth =>
      'Autentikasi: masuk, pembuatan akun, dan atur ulang kata sandi';

  @override
  String get dashPhaseOneDone => 'Fase pertama selesai';

  @override
  String get dashNextPhase =>
      'Berikutnya: mesin PDF offline dan font Arab, lalu editor templat visual.';

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
}
