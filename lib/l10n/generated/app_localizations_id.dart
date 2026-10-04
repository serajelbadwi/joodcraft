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
}
