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

  @override
  String get matchListEmpty => 'Belum ada pertandingan';

  @override
  String get matchAllTeams => 'Semua tim';

  @override
  String get matchTeam => 'Tim';

  @override
  String get matchStatusScheduled => 'Terjadwal';

  @override
  String get matchStatusLive => 'Berlangsung';

  @override
  String get matchStatusFinished => 'Selesai';

  @override
  String get matchStatusCancelled => 'Dibatalkan';

  @override
  String matchVs(String opponent) {
    return 'vs $opponent';
  }

  @override
  String get matchHome => 'Kandang';

  @override
  String get matchAway => 'Tandang';

  @override
  String get matchUs => 'Kami';

  @override
  String get matchCachedData => 'Luring: data yang tersimpan di perangkat ini';

  @override
  String get matchNew => 'Pertandingan baru';

  @override
  String get matchOpponent => 'Lawan';

  @override
  String get matchDate => 'Tanggal';

  @override
  String get matchCreated => 'Pertandingan dibuat';

  @override
  String get matchSetup => 'Daftar pemain';

  @override
  String get matchSetupHint => 'Pilih pemain, starter, dan nomor punggung';

  @override
  String get matchStarter => 'Starter';

  @override
  String get matchJersey => 'Nomor';

  @override
  String get matchSetupSaved => 'Daftar pemain disimpan';

  @override
  String get matchSetupNoPlayers => 'Tim belum memiliki pemain';

  @override
  String get matchSetupNeedStarter => 'Tandai minimal satu starter';

  @override
  String matchSetupSummary(int selected, int starters) {
    return '$selected dipilih · $starters starter';
  }

  @override
  String get matchSetupAction => 'Atur daftar pemain';

  @override
  String get matchNoRoster => 'Pertandingan ini belum punya daftar pemain';

  @override
  String get matchTabCourt => 'Lapangan';

  @override
  String get matchTabLog => 'Catatan';

  @override
  String get matchTabBox => 'Statistik';

  @override
  String matchPeriodShort(int period) {
    return 'B$period';
  }

  @override
  String matchOvertimeShort(int number) {
    return 'OT$number';
  }

  @override
  String get matchBeforeStart => 'Belum mulai';

  @override
  String matchStartPeriod(String period) {
    return 'Mulai $period';
  }

  @override
  String matchEndPeriod(String period) {
    return 'Akhiri $period';
  }

  @override
  String get matchClockStart => 'Jalankan jam';

  @override
  String get matchClockPause => 'Hentikan jam';

  @override
  String get matchClockMinus => 'Kurangi 10 detik';

  @override
  String get matchClockPlus => 'Tambah 10 detik';

  @override
  String get matchOnCourt => 'Di lapangan';

  @override
  String get matchBench => 'Cadangan';

  @override
  String matchOpponentPoints(int points) {
    return 'Lawan +$points';
  }

  @override
  String get matchTimeoutOwn => 'Time-out';

  @override
  String get matchTimeoutOpponent => 'Time-out lawan';

  @override
  String get matchUndo => 'Batalkan';

  @override
  String get matchUndone => 'Catatan terakhir dibatalkan';

  @override
  String get matchNothingToUndo => 'Tidak ada yang bisa dibatalkan';

  @override
  String matchSubFor(String name) {
    return '$name masuk menggantikan…';
  }

  @override
  String matchStatsFor(String name) {
    return 'Statistik $name';
  }

  @override
  String matchRecorded(String action, String name) {
    return '$action · $name';
  }

  @override
  String get matchAction2ptMade => '2 PT ✓';

  @override
  String get matchAction2ptMissed => '2 PT ✗';

  @override
  String get matchAction3ptMade => '3 PT ✓';

  @override
  String get matchAction3ptMissed => '3 PT ✗';

  @override
  String get matchActionFtMade => 'LB ✓';

  @override
  String get matchActionFtMissed => 'LB ✗';

  @override
  String get matchActionAssist => 'Asis';

  @override
  String get matchActionOreb => 'Rebound serang';

  @override
  String get matchActionDreb => 'Rebound bertahan';

  @override
  String get matchActionSteal => 'Curi bola';

  @override
  String get matchActionBlock => 'Blok';

  @override
  String get matchActionTurnover => 'Turnover';

  @override
  String get matchActionFoulPersonal => 'Pelanggaran pribadi';

  @override
  String get matchActionFoulTechnical => 'Pelanggaran teknis';

  @override
  String get matchActionFoulUnsportsmanlike => 'Tidak sportif';

  @override
  String matchEvPeriodStart(String period) {
    return '$period dimulai';
  }

  @override
  String matchEvPeriodEnd(String period) {
    return '$period berakhir';
  }

  @override
  String matchEvSubIn(String name) {
    return '$name masuk';
  }

  @override
  String matchEvSubOut(String name) {
    return '$name keluar';
  }

  @override
  String matchEvVoid(String target) {
    return 'Membatalkan: $target';
  }

  @override
  String get matchEvVoidUnknown => 'Membatalkan catatan';

  @override
  String matchEvNote(String text) {
    return 'Catatan: $text';
  }

  @override
  String get matchSyncPending => 'Menunggu';

  @override
  String get matchSyncSent => 'Mengirim';

  @override
  String get matchSyncDone => 'Tersinkron';

  @override
  String matchSyncRejected(String reason) {
    return 'Ditolak: $reason';
  }

  @override
  String get matchVoided => 'Dibatalkan';

  @override
  String matchRecordedBy(String name) {
    return 'oleh $name';
  }

  @override
  String get matchReasonSchema => 'data tidak valid';

  @override
  String get matchReasonNotAuthorized => 'tidak diizinkan';

  @override
  String get matchReasonCancelled => 'pertandingan dibatalkan';

  @override
  String get matchReasonSeqConflict => 'konflik urutan';

  @override
  String get matchReasonOther => 'ditolak server';

  @override
  String get matchVoidEvent => 'Batalkan';

  @override
  String get matchVoidConfirm =>
      'Batalkan catatan ini? Peristiwa VOID akan dicatat.';

  @override
  String get matchDiscard => 'Buang';

  @override
  String get matchDiscardConfirm =>
      'Buang catatan yang ditolak ini? Tidak akan dikirim lagi.';

  @override
  String matchUnsynced(int count) {
    return '$count belum tersinkron';
  }

  @override
  String matchRejectedCount(int count) {
    return '$count ditolak';
  }

  @override
  String get matchSyncPausedAuth =>
      'Masuk lagi untuk sinkronisasi; data tetap tersimpan';

  @override
  String get matchSyncing => 'Menyinkronkan…';

  @override
  String get matchParentMode => 'Mode keluarga: hanya pemain Anda';

  @override
  String get matchReadOnly => 'Hanya baca';

  @override
  String get matchStart => 'Mulai pertandingan';

  @override
  String get matchFinish => 'Selesaikan pertandingan';

  @override
  String get matchFinishConfirm =>
      'Selesaikan pertandingan? Koreksi tetap bisa dilakukan.';

  @override
  String get matchColMin => 'MNT';

  @override
  String get matchColPts => 'PTS';

  @override
  String get matchColReb => 'REB';

  @override
  String get matchColAst => 'AST';

  @override
  String get matchColStl => 'CUR';

  @override
  String get matchColBlk => 'BLK';

  @override
  String get matchColTov => 'TO';

  @override
  String get matchColPf => 'PF';

  @override
  String get matchColFg => 'FG';

  @override
  String get matchCol3p => '3P';

  @override
  String get matchColFt => 'LB';

  @override
  String get matchTotals => 'Total tim';

  @override
  String get matchPeriodScores => 'Per babak';

  @override
  String matchWarnings(int count) {
    return '$count peringatan konsistensi (perbaiki dengan Batalkan)';
  }

  @override
  String get matchCopy => 'Salin hasil';

  @override
  String get matchCopied => 'Hasil disalin';

  @override
  String matchShareLine(String name, int points, int rebounds, int assists) {
    return '$name: $points poin, $rebounds reb, $assists asis';
  }

  @override
  String get seasonStatsTitle => 'Statistik musim';

  @override
  String seasonStatsGames(int played, int started) {
    return '$played pertandingan · $started sebagai starter';
  }

  @override
  String get seasonStatsAverages => 'Rata-rata per pertandingan';

  @override
  String get seasonStatsTotals => 'Total';

  @override
  String get seasonStatsMatches => 'Pertandingan';

  @override
  String get seasonStatsEmpty => 'Belum ada pertandingan musim ini';

  @override
  String get seasonStatsPoints => 'Poin';

  @override
  String get seasonStatsRebounds => 'Rebound';

  @override
  String get seasonStatsAssists => 'Asis';

  @override
  String get seasonStatsMinutes => 'Menit';

  @override
  String get seasonStatsSeason => 'Musim';
}
