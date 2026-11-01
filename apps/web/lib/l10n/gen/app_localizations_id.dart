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

  @override
  String get save => 'Simpan';

  @override
  String get cancel => 'Batal';

  @override
  String get delete => 'Hapus';

  @override
  String get edit => 'Ubah';

  @override
  String get add => 'Tambah';

  @override
  String get create => 'Buat';

  @override
  String get confirm => 'Konfirmasi';

  @override
  String get close => 'Tutup';

  @override
  String get remove => 'Hapus dari daftar';

  @override
  String get search => 'Cari';

  @override
  String get all => 'Semua';

  @override
  String get none => 'Tidak ada';

  @override
  String get saved => 'Perubahan disimpan';

  @override
  String get fieldRequired => 'Wajib diisi';

  @override
  String get fieldInvalidNumber => 'Masukkan angka yang valid';

  @override
  String get fieldInvalidEmail => 'Masukkan email yang valid';

  @override
  String get noResults => 'Tidak ada hasil';

  @override
  String get noteOptional => 'Catatan (opsional)';

  @override
  String get noteRequired => 'Catatan (wajib)';

  @override
  String get readOnlyHint => 'Hanya baca: Anda tidak berhak mengubah ini.';

  @override
  String get moreActions => 'Tindakan lainnya';

  @override
  String get adminTitle => 'Administrasi';

  @override
  String get adminAcademyProfile => 'Profil akademi';

  @override
  String get adminMembers => 'Anggota';

  @override
  String get adminSeasons => 'Musim';

  @override
  String get adminAgeCategories => 'Kategori usia';

  @override
  String get adminApprovals => 'Permintaan tertunda';

  @override
  String get adminCases => 'Kasus kelayakan';

  @override
  String get academyName => 'Nama akademi';

  @override
  String get academyTimezone => 'Zona waktu (mis. Asia/Jakarta)';

  @override
  String get academyAgeRule => 'Aturan usia';

  @override
  String get ageRuleBirthYear => 'Berdasarkan tahun lahir';

  @override
  String get ageRuleBirthday => 'Berdasarkan tanggal lahir';

  @override
  String get academyMaxPlayUp => 'Maksimum tingkat naik kategori';

  @override
  String get academyDefaultLocale => 'Bahasa bawaan';

  @override
  String get logoTitle => 'Logo';

  @override
  String get logoHint => 'PNG, JPEG, atau WebP, maksimal 512 KB';

  @override
  String get logoChoose => 'Pilih gambar';

  @override
  String get logoUpload => 'Unggah logo';

  @override
  String get logoRemove => 'Hapus logo';

  @override
  String get logoRemoveConfirm => 'Hapus logo akademi?';

  @override
  String get logoPreview => 'Pratinjau';

  @override
  String get logoNone => 'Tidak ada logo';

  @override
  String get logoUploaded => 'Logo diperbarui';

  @override
  String get logoRemoved => 'Logo dihapus';

  @override
  String get logoErrorTooLarge => 'Gambar lebih besar dari 512 KB.';

  @override
  String get logoErrorWrongType =>
      'Format tidak valid: gunakan PNG, JPEG, atau WebP.';

  @override
  String get logoErrorEmpty => 'Berkas kosong.';

  @override
  String get membersSearchHint => 'Cari berdasarkan nama atau email';

  @override
  String get membersEmpty => 'Belum ada anggota';

  @override
  String get memberInvite => 'Undang';

  @override
  String get memberInviteTitle => 'Undang anggota';

  @override
  String get memberGivenName => 'Nama depan';

  @override
  String get memberFamilyName => 'Nama belakang';

  @override
  String get memberEmail => 'Email';

  @override
  String get memberRoles => 'Peran';

  @override
  String get memberRolesRequired => 'Pilih setidaknya satu peran';

  @override
  String get memberInvited => 'Undangan terkirim';

  @override
  String get memberEditRoles => 'Ubah peran';

  @override
  String get memberDeactivate => 'Nonaktifkan';

  @override
  String memberDeactivateConfirm(String name) {
    return 'Nonaktifkan $name? Akses ke akademi akan dicabut.';
  }

  @override
  String get memberDeactivated => 'Anggota dinonaktifkan';

  @override
  String get memberInactive => 'Tidak aktif';

  @override
  String get memberInvitationPending => 'Undangan tertunda';

  @override
  String get memberGuardianLinks => 'Pemain terkait';

  @override
  String get memberGuardianNone => 'Belum ada pemain terkait';

  @override
  String get memberGuardianAdd => 'Kaitkan pemain';

  @override
  String memberGuardianRemoveConfirm(String name) {
    return 'Hapus kaitan dengan $name?';
  }

  @override
  String get memberGuardianOnlyParents =>
      'Kaitan hanya dapat diubah untuk anggota dengan peran Orang tua.';

  @override
  String get seasonsEmpty => 'Belum ada musim';

  @override
  String get seasonNew => 'Musim baru';

  @override
  String get seasonEdit => 'Ubah musim';

  @override
  String get seasonName => 'Nama';

  @override
  String get seasonStarts => 'Mulai';

  @override
  String get seasonEnds => 'Selesai';

  @override
  String get seasonReferenceYear => 'Tahun acuan (aturan tahun lahir)';

  @override
  String get seasonCurrent => 'Saat ini';

  @override
  String get seasonDatesInvalid =>
      'Tanggal selesai harus setelah tanggal mulai';

  @override
  String get seasonRollover => 'Lanjutkan ke musim baru';

  @override
  String get rolloverTitle => 'Pergantian musim';

  @override
  String rolloverIntro(String name) {
    return 'Musim berikutnya dibuat dari $name: tim disalin dan pemain diperiksa ulang.';
  }

  @override
  String get rolloverCloneStaff => 'Salin staf tim';

  @override
  String get rolloverClonePlayers => 'Salin daftar pemain';

  @override
  String get rolloverConfirm => 'Jalankan pergantian musim';

  @override
  String get rolloverDone => 'Pergantian musim selesai';

  @override
  String rolloverClonedTeams(String count) {
    return 'Tim disalin: $count';
  }

  @override
  String get rolloverOrphansTitle => 'Pemain tanpa tim yang valid';

  @override
  String get rolloverNoOrphans => 'Semua pemain tetap memenuhi syarat.';

  @override
  String rolloverOrphanLine(String player, String team) {
    return '$player (sebelumnya: $team)';
  }

  @override
  String get rolloverGoToCases => 'Buka kasus kelayakan';

  @override
  String rolloverCasesOpened(String count) {
    return 'Kasus dibuka: $count';
  }

  @override
  String get categoryNew => 'Kategori baru';

  @override
  String get categoryEdit => 'Ubah kategori';

  @override
  String get categoriesEmpty => 'Belum ada kategori';

  @override
  String get categoryCode => 'Kode';

  @override
  String get categoryName => 'Nama';

  @override
  String get categoryMaxAge => 'Usia maksimum (kosong = tanpa batas)';

  @override
  String get categoryRank => 'Urutan';

  @override
  String get categoryNoLimit => 'Tanpa batas usia';

  @override
  String categoryUpTo(String age) {
    return 'Hingga $age tahun';
  }

  @override
  String categoryDeleteConfirm(String name) {
    return 'Hapus kategori $name?';
  }

  @override
  String get teamsEmpty => 'Tidak ada tim di musim ini';

  @override
  String get teamsNoSeason => 'Buat musim terlebih dahulu';

  @override
  String get teamsSeason => 'Musim';

  @override
  String get teamNew => 'Tim baru';

  @override
  String get teamEdit => 'Ubah tim';

  @override
  String get teamName => 'Nama';

  @override
  String get teamAlias => 'Alias (opsional)';

  @override
  String get teamCategory => 'Kategori';

  @override
  String get teamGenderPolicy => 'Kebijakan gender';

  @override
  String get genderPolicyMale => 'Putra';

  @override
  String get genderPolicyFemale => 'Putri';

  @override
  String get genderPolicyMixed => 'Campuran';

  @override
  String teamPlayerCount(String count) {
    return '$count pemain';
  }

  @override
  String get teamStaff => 'Staf';

  @override
  String get teamStaffAdd => 'Tambah staf';

  @override
  String get teamStaffNone => 'Belum ada staf';

  @override
  String teamStaffRemoveConfirm(String name) {
    return 'Keluarkan $name dari tim?';
  }

  @override
  String get teamStaffPick => 'Orang';

  @override
  String get teamStaffRole => 'Fungsi';

  @override
  String get teamRoster => 'Daftar pemain';

  @override
  String get teamRosterEmpty => 'Daftar pemain kosong';

  @override
  String get rosterAssign => 'Tetapkan pemain';

  @override
  String get rosterSearchPlayer => 'Cari pemain';

  @override
  String get rosterUnassign => 'Keluarkan dari daftar pemain';

  @override
  String rosterUnassignConfirm(String name) {
    return 'Keluarkan $name dari daftar pemain?';
  }

  @override
  String get rosterJersey => 'Nomor punggung';

  @override
  String get rosterJerseyEdit => 'Ubah nomor punggung';

  @override
  String get rosterAssigned => 'Pemain ditetapkan';

  @override
  String get rosterInvalid => 'Tidak lagi memenuhi syarat';

  @override
  String get rosterEligibilityPending => 'Memeriksa kelayakan…';

  @override
  String get eligibilityEligible => 'Memenuhi syarat';

  @override
  String eligibilityPlayUp(String levels) {
    return 'Naik kategori (+$levels)';
  }

  @override
  String get eligibilityIneligible => 'Tidak memenuhi syarat';

  @override
  String playUpBadge(String levels) {
    return '+$levels';
  }

  @override
  String get reasonCategoryTooLow => 'Terlalu tua untuk kategori ini';

  @override
  String get reasonPlayUpLimit => 'Melebihi maksimum tingkat naik kategori';

  @override
  String get reasonGenderPolicy => 'Tidak sesuai kebijakan gender tim';

  @override
  String get reasonMissingBirthDate => 'Tanggal lahir belum diisi';

  @override
  String get reasonMissingGender => 'Gender belum diisi';

  @override
  String get reasonPlayerNotActive => 'Pemain tidak aktif';

  @override
  String get playersSearchHint => 'Cari pemain';

  @override
  String get playersEmpty => 'Tidak ada pemain yang cocok dengan filter';

  @override
  String get filterStatus => 'Status';

  @override
  String get filterTeam => 'Tim';

  @override
  String get filterCategory => 'Kategori';

  @override
  String get filterClear => 'Hapus filter';

  @override
  String get statusActive => 'Aktif';

  @override
  String get statusOrphan => 'Tanpa tim valid';

  @override
  String get statusPendingApproval => 'Menunggu persetujuan';

  @override
  String get statusWithdrawn => 'Mengundurkan diri';

  @override
  String get playerNew => 'Pemain baru';

  @override
  String get playerNewRequest => 'Ajukan pemain baru';

  @override
  String get playerGivenName => 'Nama depan';

  @override
  String get playerFamilyName => 'Nama belakang';

  @override
  String get playerBirthDate => 'Tanggal lahir';

  @override
  String get playerBirthDateInvalid => 'Tanggal lahir tidak valid';

  @override
  String get playerGender => 'Gender';

  @override
  String get genderMale => 'Laki-laki';

  @override
  String get genderFemale => 'Perempuan';

  @override
  String get playerEmail => 'Email (opsional)';

  @override
  String get playerInitialTeam => 'Tim awal (opsional)';

  @override
  String get playerNote => 'Catatan untuk administrator (opsional)';

  @override
  String get playerCreated => 'Pemain dibuat';

  @override
  String get playerRequestSent => 'Permintaan dikirim ke administrator';

  @override
  String get playerBasics => 'Data dasar';

  @override
  String get playerNaturalCategory => 'Kategori alami';

  @override
  String get playerGuardians => 'Wali';

  @override
  String get playerNoGuardians => 'Belum ada wali terkait';

  @override
  String get playerTeams => 'Tim';

  @override
  String get playerNoTeams => 'Belum ada tim';

  @override
  String get playerAssignToTeam => 'Tetapkan ke tim';

  @override
  String get playerNoEligibleTeams =>
      'Tidak ada tim yang memenuhi syarat musim ini';

  @override
  String get playerWithdraw => 'Keluarkan';

  @override
  String playerWithdrawConfirm(String name) {
    return 'Keluarkan $name?';
  }

  @override
  String get playerWithdrawReason => 'Alasan (opsional)';

  @override
  String get playerWithdrawn => 'Pemain dikeluarkan';

  @override
  String get playerWithdrawRequested => 'Permintaan pengunduran dikirim';

  @override
  String get approvalsTitle => 'Permintaan';

  @override
  String get approvalsMine => 'Permintaan saya';

  @override
  String get approvalsEmpty => 'Tidak ada permintaan';

  @override
  String get approvalActionAdd => 'Tambah pemain';

  @override
  String get approvalActionWithdraw => 'Pengunduran pemain';

  @override
  String get approvalStatusPending => 'Menunggu';

  @override
  String get approvalStatusApproved => 'Disetujui';

  @override
  String get approvalStatusRejected => 'Ditolak';

  @override
  String get approvalStatusCancelled => 'Dibatalkan';

  @override
  String approvalRequestedBy(String name) {
    return 'Diminta oleh $name';
  }

  @override
  String get approvalApprove => 'Setujui';

  @override
  String get approvalReject => 'Tolak';

  @override
  String get approvalCancel => 'Batalkan permintaan';

  @override
  String get approvalCancelConfirm => 'Batalkan permintaan ini?';

  @override
  String approvalDecisionNote(String note) {
    return 'Catatan keputusan: $note';
  }

  @override
  String get approvalApproved => 'Permintaan disetujui';

  @override
  String get approvalRejected => 'Permintaan ditolak';

  @override
  String get approvalCancelled => 'Permintaan dibatalkan';

  @override
  String get casesEmpty => 'Tidak ada kasus terbuka';

  @override
  String caseTeam(String team) {
    return 'Tim yang tidak valid: $team';
  }

  @override
  String get caseReassign => 'Tetapkan ulang';

  @override
  String caseReassignTitle(String player) {
    return 'Tetapkan ulang $player';
  }

  @override
  String get caseRemoveFromTeam => 'Keluarkan dari tim';

  @override
  String get caseDismiss => 'Abaikan kasus';

  @override
  String get caseResolved => 'Kasus diselesaikan';

  @override
  String get casePickTeam => 'Pilih tim baru';

  @override
  String get back => 'Kembali';
}
