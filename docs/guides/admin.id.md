# Panduan Administrator

Bahasa: [Español](admin.es.md) · [English](admin.en.md) · Bahasa Indonesia

Anda masuk dengan alamat e-mail dan kata sandi Anda.

Anda adalah **Administrator** sebuah akademi. Anda menyiapkan akademi, mengundang orang, membuat musim dan tim, serta
memutuskan permintaan pemain. Nama menu di bawah sesuai tampilan aplikasi berbahasa Indonesia.

## Menjelajah aplikasi
- Masuk dengan email Anda dan kata sandi sementara yang diberikan administrator platform; pertama kali, Keycloak meminta
  Anda memilih kata sandi sendiri (minimal 12 karakter). Tidak ada email undangan yang dikirim (ADR-0024).
- Bilah bawah di ponsel (rail samping di layar lebar): **Admin**, **Tim**, **Pertandingan**, **Latihan**, **Pemain**.
- Ketuk logo/nama akademi di bilah atas untuk **Ganti akademi** jika Anda tergabung di beberapa akademi.
- **Profil** (bilah atas): **Bahasa** (Español, English, Bahasa Indonesia) dan **Keluar**.

## 1. Profil akademi dan logo
**Admin > Profil akademi.**
- Nama, **Zona waktu** (mis. Asia/Jakarta), dan **Bahasa bawaan**.
- **Aturan usia** dan **Maksimum tingkat naik kategori**: lihat bagian 7.
- **Logo**: **Pilih gambar**, lalu **Unggah logo**. PNG, JPEG, atau WebP, maksimal 512 KB. **Hapus logo** menghapusnya.
  Logo tampil di bilah atas semua anggota.

## 2. Anggota dan undangan
**Admin > Anggota.** Cari berdasarkan nama atau email.
1. **Undang**: nama depan, nama belakang, email, dan minimal satu **Peran** (Administrator, Pelatih, Asisten pelatih,
   Orang tua, Pemain). Satu orang boleh memiliki beberapa peran.
2. Tidak ada email yang dikirim. Jika orang itu belum punya akun login, dialog **Kata sandi sementara** menampilkan **kata sandinya satu kali
   saja** kepada Anda (dengan tombol **Salin kata sandi**; hanya bisa ditutup dengan **Selesai**): sampaikan secara pribadi (langsung, lewat telepon, atau aplikasi pesan tepercaya; jangan dalam
   pesan yang sama dengan alamat email). Ia masuk dengan email dan kata sandi itu, lalu harus memilih kata sandi sendiri.
   Jika email itu sudah punya akun login (misalnya anggota akademi lain), tidak ada dialog, sebuah catatan menyebut ia memakai kata
   sandi yang sudah dimilikinya. Sampai ia masuk pertama kali, statusnya **Undangan tertunda**. Selama masih tertunda dan
   ia belum memilih kata sandi, buka halaman anggotanya dan pakai **Buat kata sandi sementara baru** (menggantikan yang lama; ditolak jika
   akun login itu juga dipakai di akademi lain: minta administrator platform).
   Kata sandi sementara yang tidak dipakai **kedaluwarsa setelah 3 hari** (ADR-0028): halaman masuk orang tersebut lalu
   menampilkan "Kata sandi sementara Anda sudah kedaluwarsa. Mintalah yang baru kepada administrator akademi Anda.", dan
   anggota itu menampilkan **Kata sandi sementara kedaluwarsa** di daftar dan di halamannya. Gunakan **Buat kata sandi
   sementara baru** di sana: kata sandi baru langsung berfungsi (akun login aktif kembali) dan juga kedaluwarsa setelah 3
   hari bila tidak dipakai.
3. **Ubah peran** mengganti peran. **Nonaktifkan** mencabut akses (orangnya tetap tersimpan, ditandai **Tidak aktif**).
4. **Mengubah email** anggota yang punya akun login juga mengubah alamat masuknya: sejak itu ia masuk dengan email baru,
   tanpa email apa pun yang dikirim dan kata sandinya tidak berubah. Jika orang itu juga anggota akademi lain, perubahan
   ditolak ("dipakai di akademi lain"): minta administrator platform. Email anggota yang punya akun login tidak dapat
   dihapus.

## 3. Wali (orang tua)
Buka anggota yang berperan **Orang tua**. Di **Pemain terkait**, pilih **Kaitkan pemain** lalu pilih anaknya; kaitan
dihapus dengan aksi hapus. Orang tua hanya melihat dan mengubah data pemain yang terkait. Kaitan hanya dapat diubah untuk
anggota berperan Orang tua, jadi undang orang tuanya terlebih dahulu.

## 4. Musim dan kategori usia
- **Admin > Musim > Musim baru**: nama, mulai, selesai, dan **Tahun acuan** (dipakai aturan tahun lahir). Musim dalam satu
  akademi tidak boleh tumpang tindih.
- **Admin > Kategori usia**: kode, nama, **Usia maksimum** (kosong = tanpa batas), dan **Urutan**. U8 sampai U18 dan SENIOR
  dibuat otomatis dan dapat diubah. Mengubah kategori akan memeriksa ulang semua penempatan tim.

## 5. Tim dan staf
Tab **Tim**, pilih musim, lalu **Tim baru**: nama, alias (opsional), **Kategori**, dan **Kebijakan gender** (Putra,
Putri, Campuran). Di dalam tim:
- **Staf > Tambah staf**: pilih anggota dan fungsinya (Pelatih atau Asisten pelatih). Wewenang pelatih atas sebuah tim
  berasal dari terdaftarnya di sini.
- **Daftar pemain > Tetapkan pemain**: cari pemain. Aplikasi menampilkan **Memenuhi syarat**, **Naik kategori (+n)**, atau
  **Tidak memenuhi syarat** beserta alasannya (terlalu tua, melebihi maksimum tingkat naik kategori, kebijakan gender,
  tanggal lahir atau gender belum diisi, pemain tidak aktif). Pemain yang tidak memenuhi syarat tidak dapat ditetapkan.
  Isi **Nomor punggung** saat menetapkan; **Ubah nomor punggung** dan **Keluarkan dari daftar pemain** ada di tiap baris.

## 6. Pemain dan persetujuan
Tab **Pemain**: filter **Status** (Aktif, Tanpa tim valid, Menunggu persetujuan, Mengundurkan diri), **Tim**, **Kategori**,
dan kolom pencarian.
- **Pemain baru**: nama, tanggal lahir, gender (wajib), email dan tim awal (opsional). Sebagai administrator, pemain
  langsung dibuat. Jika ada email, pemain juga mendapat akun login: kata sandi sementaranya ditampilkan satu kali, seperti
  pada undangan.
- Pemain tanpa tim valid ditampilkan sebagai **Tanpa tim valid** sampai ditetapkan ke tim.
- Detail pemain: data dasar, kategori alami, tim, wali, **Tetapkan ke tim** (hanya tim yang memenuhi syarat), kesehatan,
  **Statistik musim**, dan **Keluarkan**.
- **Admin > Permintaan tertunda**: pelatih meminta penambahan atau pengunduran pemain. **Setujui** (catatan opsional) atau
  **Tolak** (catatan wajib). Persetujuan penambahan bisa gagal jika pemain tidak memenuhi syarat untuk tim yang dipilih;
  permintaan tetap tertunda. Menyetujui pemain yang punya email membuatkan akun login; kata sandi sementaranya
  ditampilkan satu kali.

## 7. Pengaturan: aturan usia, naik kategori, bahasa
**Admin > Profil akademi**
- **Aturan usia**: **Berdasarkan tahun lahir** (bawaan: tahun acuan musim dikurangi tahun lahir) atau **Berdasarkan tanggal
  lahir** (usia penuh hari ini).
- **Maksimum tingkat naik kategori**: berapa tingkat di atas kategori alaminya seorang pemain boleh dimainkan. Kosong
  berarti tanpa batas.
- **Bahasa bawaan**: dipakai untuk orang yang belum memilih bahasanya sendiri.
Menyimpan perubahan aturan usia atau batas naik kategori akan mengevaluasi ulang semua penempatan. Tidak ada yang
dihapus: penempatan yang tidak lagi memenuhi syarat ditandai **Tidak lagi memenuhi syarat** dan sebuah kasus kelayakan
dibuka.

## 8. Kasus kelayakan dan pergantian musim
**Admin > Kasus kelayakan** menampilkan kasus terbuka (pemain, tim yang tidak valid, alasan). Untuk tiap kasus pilih
**Tetapkan ulang** (pilih tim yang memenuhi syarat), **Keluarkan dari tim**, atau **Abaikan kasus**.

**Pergantian musim**: **Admin > Musim > Lanjutkan ke musim baru** pada musim yang berakhir.
1. Pilih apakah **Salin staf tim** dan **Salin daftar pemain**.
2. **Jalankan pergantian musim**. Hasilnya menampilkan tim yang disalin, **Pemain tanpa tim yang valid** (mis. pemain yang
   melewati batas usia), dan jumlah kasus yang dibuka.
3. **Buka kasus kelayakan** dan selesaikan. Pada aturan tahun lahir, pergantian musim adalah saat sebagian besar pemain
   tanpa tim muncul; pada aturan tanggal lahir, pemeriksaan malam juga menemukannya.

## 9. Tes fisik dan norma
Ikon di daftar pemain membuka **Jenis tes** dan **Norma**. Norma global hanya baca; tambahkan baris **Penggantian
akademi** untuk menggantinya. Nilai berlabel **Rujukan menyusul** hanyalah nilai sementara, bukan norma terbitan:
gantilah sebelum memakai pita untuk keputusan (lihat `docs/domain/norms.md`).

## 10. Aktivitas (jejak audit)
**Administrasi → Aktivitas** menampilkan apa yang dilakukan di akademi, dari yang terbaru: anggota diundang, diubah,
diganti perannya atau dinonaktifkan, kata sandi sementara dibuat atau kedaluwarsa, masuk pertama kali, tautan wali,
pengajuan dan keputusan pemain, perubahan profil, pengaturan dan logo, serta tindakan administrasi platform
(administrator ditambahkan, akademi ditangguhkan…). Setiap entri menyebut tindakan, objeknya, dan siapa pelakunya
("Sistem" untuk proses otomatis, "Administrator platform" untuk super administrator, yang identitasnya tidak ditampilkan; alasan penangguhan atau penarikan tetap ditampilkan). Nama ditampilkan seperti saat ini;
entri tentang sesuatu yang sudah tidak ada hanya menampilkan jenisnya. Saring menurut rentang tanggal dan satu atau
beberapa tindakan; pindah halaman dengan panah di bawah. Hanya administrator yang dapat melihatnya. Entri tidak pernah
diubah atau dihapus, dan disimpan (belum ada pembersihan otomatis).

---
Status: disusun dari layar yang sudah diimplementasikan dan berkas terjemahan; belum diperiksa lewat uji manual di peramban.
