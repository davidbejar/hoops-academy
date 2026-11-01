// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appName => 'Hoops Academy';

  @override
  String get loading => 'Memuat…';

  @override
  String get retry => 'Coba lagi';

  @override
  String get signIn => 'Masuk';

  @override
  String get signInSubtitle => 'Masuk dengan akun akademi Anda';

  @override
  String get signOut => 'Keluar';

  @override
  String signedInAs(String name) {
    return 'Masuk sebagai $name';
  }

  @override
  String get offlineBanner => 'Anda sedang offline. Data mungkin sudah usang.';

  @override
  String get mockModeBanner => 'Mode demo: data contoh, tanpa server';

  @override
  String get navAdmin => 'Admin';

  @override
  String get navTeams => 'Tim';

  @override
  String get navMatches => 'Pertandingan';

  @override
  String get navTraining => 'Latihan';

  @override
  String get navPlayers => 'Pemain';

  @override
  String get navMyPlayers => 'Pemain saya';

  @override
  String get navMe => 'Saya';

  @override
  String get navPlatform => 'Platform';

  @override
  String placeholderModule(String module) {
    return '$module: segera hadir';
  }

  @override
  String get profileTitle => 'Profil';

  @override
  String get language => 'Bahasa';

  @override
  String get languageName_es => 'Español';

  @override
  String get languageName_en => 'English';

  @override
  String get languageName_id => 'Bahasa Indonesia';

  @override
  String get academy => 'Akademi';

  @override
  String get switchAcademy => 'Ganti akademi';

  @override
  String get chooseAcademyTitle => 'Pilih akademi Anda';

  @override
  String get chooseAcademySubtitle =>
      'Anda tergabung di beberapa akademi. Akademi mana yang ingin Anda gunakan?';

  @override
  String rolesInAcademy(String roles) {
    return 'Peran: $roles';
  }

  @override
  String get roleAdmin => 'Administrator';

  @override
  String get roleCoach => 'Pelatih';

  @override
  String get roleAssistantCoach => 'Asisten pelatih';

  @override
  String get roleParent => 'Orang tua';

  @override
  String get rolePlayer => 'Pemain';

  @override
  String get noAccessTitle => 'Tidak ada akses ke akademi mana pun';

  @override
  String get noAccessBody =>
      'Akun Anda belum tergabung di akademi mana pun. Minta administrator untuk mengundang Anda.';

  @override
  String get profileLoadFailed => 'Kami tidak dapat memuat profil Anda';

  @override
  String get errorNetwork =>
      'Tidak dapat terhubung ke server. Periksa koneksi Anda lalu coba lagi.';

  @override
  String get errorTimeout => 'Server terlalu lama merespons. Coba lagi.';

  @override
  String get errorUnauthorized =>
      'Sesi Anda telah berakhir. Silakan masuk kembali.';

  @override
  String get errorForbidden => 'Anda tidak diizinkan melakukan ini.';

  @override
  String get errorNotFound => 'Kami tidak menemukan yang Anda cari.';

  @override
  String get errorConflict => 'Data telah berubah. Muat ulang lalu coba lagi.';

  @override
  String get errorValidation => 'Periksa kembali data yang Anda masukkan.';

  @override
  String get errorServer =>
      'Server mengalami masalah. Silakan coba lagi nanti.';

  @override
  String get errorUnknown => 'Terjadi kesalahan yang tidak terduga.';

  @override
  String errorReference(String traceId) {
    return 'Referensi: $traceId';
  }

  @override
  String get emptyTitle => 'Belum ada apa pun di sini';
}
