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
}
