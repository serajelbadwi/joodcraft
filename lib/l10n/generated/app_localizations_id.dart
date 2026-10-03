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
}
