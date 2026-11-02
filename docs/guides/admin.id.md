# Panduan Administrator

Bahasa: [Español](admin.es.md) · [English](admin.en.md) · Bahasa Indonesia

Anda masuk dengan alamat e-mail dan kata sandi Anda.

Anda adalah **Administrator** sebuah akademi. Anda menyiapkan akademi, mengundang orang, membuat musim dan tim, serta
memutuskan permintaan pemain. Nama menu di bawah sesuai tampilan aplikasi berbahasa Indonesia.

## Menjelajah aplikasi
- Masuk dengan akun dari email undangan (pertama kali, tautan di email memungkinkan Anda memilih kata sandi).
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
2. Orang tersebut menerima email untuk membuat kata sandi. Sebelum itu statusnya **Undangan tertunda**.
3. **Ubah peran** mengganti peran. **Nonaktifkan** mencabut akses (orangnya tetap tersimpan, ditandai **Tidak aktif**).
Pada pengembangan lokal, email undangan terlihat di MailHog (http://localhost:8025).

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
  langsung dibuat. Jika ada email, pemain juga menerima undangan akun.
- Pemain tanpa tim valid ditampilkan sebagai **Tanpa tim valid** sampai ditetapkan ke tim.
- Detail pemain: data dasar, kategori alami, tim, wali, **Tetapkan ke tim** (hanya tim yang memenuhi syarat), kesehatan,
  **Statistik musim**, dan **Keluarkan**.
- **Admin > Permintaan tertunda**: pelatih meminta penambahan atau pengunduran pemain. **Setujui** (catatan opsional) atau
  **Tolak** (catatan wajib). Persetujuan penambahan bisa gagal jika pemain tidak memenuhi syarat untuk tim yang dipilih;
  permintaan tetap tertunda.

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

---
Status: disusun dari layar yang sudah diimplementasikan dan berkas terjemahan; belum diperiksa lewat uji manual di peramban.
