# Panduan Super administrator

Bahasa: [Español](super-admin.es.md) · [English](super-admin.en.md) · Bahasa Indonesia

Anda masuk dengan alamat e-mail dan kata sandi Anda.

**Super administrator** menjalankan platform: membuat dan menarik akademi serta melihat penggunaannya. Ini adalah peran
realm Keycloak (`super_admin`), bukan peran akademi. Super administrator **tidak dapat membaca isi akademi** (pemain,
pertandingan, data kesehatan): platform tidak punya akses ke sana. Satu-satunya pengecualian adalah daftar
**administrator** akademi (nama, email, dan status undangan), yang dikelola oleh super administrator (lihat di bawah,
ADR-0023).

## Menemukan konsol
- Super administrator tanpa keanggotaan akademi langsung masuk ke **Platform**.
- Yang juga tergabung di sebuah akademi melihat navigasi akademi itu; buka **Profil > Konsol platform** untuk ke platform.

## Daftar akademi
**Platform** menampilkan akademi dengan kolom pencarian (nama atau slug) dan filter status: **Aktif**, **Ditangguhkan**,
**Ditarik**. Buka satu akademi untuk melihat detail dan penggunaannya.

## Membuat akademi
**Platform > Akademi baru** (lihat juga `docs/runbooks/onboard-tenant.md`):
- **Nama akademi**, **Pengenal (slug)** (huruf kecil, angka, dan tanda hubung, 3-50), **Zona waktu**, **Bahasa**.
- **Email admin pertama**, nama depan, dan nama belakang.
Saat **Buat**, akademi dan administrator pertamanya langsung ada, kategori usia bawaan (U8 sampai U18, SENIOR) terisi, dan
**kata sandi sementara** administrator ditampilkan kepada Anda **satu kali saja** (lihat "Masuk pertama kali" di bawah).
Tidak ada email yang dikirim. Jika email itu sudah punya akun login di platform (misalnya administrator akademi lain),
tidak ada kata sandi sementara: orang itu masuk dengan kata sandi yang sudah dimilikinya. Jika penyedia identitas tidak
tersedia, pembuatan gagal seluruhnya dan tidak ada yang tersisa ("502").

## Masuk pertama kali dengan kata sandi sementara (ADR-0024)
- Akun login baru mendapat kata sandi sementara buatan server (16 huruf dan angka) yang ditampilkan **satu kali saja**
  kepada pembuatnya. Platform tidak pernah menyimpannya; jika hilang, buat yang baru (**Kirim ulang undangan**, di bawah).
- Sampaikan **secara pribadi**: langsung, lewat telepon, atau aplikasi pesan tepercaya, jangan pernah bersama alamat
  email dalam pesan yang sama.
- Orang itu membuka aplikasi, masuk dengan email dan kata sandi sementara, lalu Keycloak langsung meminta mereka
  **memilih kata sandi baru** (minimal 12 karakter, bukan email mereka). Sejak itu hanya kata sandi mereka sendiri yang
  berlaku.
- Salah kata sandi berulang kali mengunci akun login untuk sementara (perlindungan brute force).

## Siklus hidup dan artinya
| Status | Arti |
|---|---|
| **Aktif** | beroperasi normal |
| **Ditangguhkan** | penghentian yang dapat dibatalkan. Semua anggota mendapat "tidak ditemukan" (404) pada semua API akademi, dan akademi hilang dari daftar mereka. Data tidak disentuh. Layanan lain menyimpan keanggotaan di cache hingga 30 detik, sehingga efeknya bisa tertunda selama itu. |
| **Ditarik** | final. Login diblokir seketika; data disimpan sampai tanggal **disimpan hingga** (bawaan 365 hari setelah penarikan). Belum ada proses pembersihan (lihat `docs/roadmap.md`), jadi data tidak terhapus otomatis. |

Aksi di halaman detail akademi:
- **Tangguhkan**: alasan wajib diisi.
- **Aktifkan kembali**: hanya dari Ditangguhkan; akses pulih seperti semula.
- **Tarik**: alasan wajib diisi dan peringatan menjelaskan bahwa masa retensi dimulai. Tidak dapat dibatalkan.
Setiap perubahan siklus hidup tercatat di jejak audit akademi (hanya bisa ditambah).

## Administrator
Di halaman detail akademi (**Platform >** akademi itu) bagian **Administrator** menampilkan setiap administrator dengan
nama, email, status undangan (**Undangan tertunda** / **Undangan diterima**), dan peran lain mereka di akademi. Setiap
baris punya **Ubah administrator**, **Hapus administrator** dan, selama undangan masih tertunda, **Kirim ulang undangan**;
**Tambah administrator** ada di bagian atas. Bagian ini berlaku untuk akademi aktif dan ditangguhkan; untuk akademi yang
**ditarik** hanya tampil catatan (administratornya tidak dapat lagi dilihat atau diubah). Operasi yang sama ada di API
platform `/platform/tenants/{id}/admins`.
- **Daftar**: administrator aktif dengan nama, email, status undangan, dan peran lain mereka di akademi.
- **Tambah** (email, nama depan dan belakang, bahasa opsional): anggota akademi dengan email itu menjadi administrator
  (datanya tetap; anggota tanpa akun login dibuatkan satu, dengan kata sandi sementara yang ditampilkan satu kali). Jika
  tidak ada, administrator baru diundang seperti administrator pertama. Email milik anggota yang dinonaktifkan ditolak.
- **Ubah** nama depan, nama belakang, atau email. Email baru juga menjadi alamat masuk orang itu (username dan email di
  Keycloak); tidak ada email yang dikirim dan kata sandi tidak berubah (kata sandi sementara yang belum dipakai tetap
  berlaku). Berbeda dengan administrator akademi, Anda boleh melakukannya juga untuk akun login yang dipakai di beberapa
  akademi.
- **Hapus** (meminta konfirmasi): orang itu kehilangan peran administrator; peran lainnya tetap, dan jika itu
  satu-satunya perannya, ia dinonaktifkan di akademi ini. Akun loginnya tidak pernah dihapus (mungkin dipakai di tempat
  lain).
- **Administrator terakhir tidak dapat dihapus.** Sebuah akademi selalu memerlukan setidaknya satu administrator aktif.
  Jika hanya ada satu administrator dalam daftar, tombol **Hapus**-nya dinonaktifkan dan barisnya menjelaskan: "Sebuah
  akademi memerlukan setidaknya satu administrator. Tambahkan administrator lain terlebih dahulu." Jika orang lain baru
  saja mengubah daftar dan server tetap menolak, Anda melihat pesan yang sama. Tambahkan administrator baru terlebih
  dahulu, lalu hapus yang lama.
- **Kirim ulang undangan** membuat **kata sandi sementara baru** (ditampilkan satu kali; yang lama tidak berlaku lagi),
  hanya selama undangan masih tertunda dan orang itu belum memilih kata sandi. Ini juga memperbaiki administrator yang
  dibuat sebelum perubahan ini dan tidak pernah mendapat kata sandi (mereka sama sekali tidak bisa masuk).
Setiap perubahan dicatat di jejak audit akademi dengan Anda sebagai pelakunya.

## Dasbor penggunaan
Detail akademi menampilkan **Penggunaan** per layanan (Inti, Pertandingan, Atlet): anggota, pemain, pemain aktif, tim, musim,
pertandingan, pertandingan langsung, peristiwa pertandingan, sesi latihan, catatan kehadiran, rencana, hasil tes, cedera,
dan pengukuran tubuh. Jika sebuah layanan tidak menjawab, pemberitahuan "Tidak ada data dari: ..." menyebutkannya dan
sisanya tetap tampil. Satu rekam jepret disimpan per akademi per hari (02:30 UTC); grafik tren belum ada di aplikasi.

---
Status: disusun dari layar yang sudah diimplementasikan, kontrak, dan berkas terjemahan; belum diperiksa lewat uji manual di peramban.
Teks tentang kata sandi sementara menjelaskan perilaku server WP24; layar yang menampilkannya hadir di WP25.
