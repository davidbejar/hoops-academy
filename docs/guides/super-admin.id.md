# Panduan Super administrator

Bahasa: [Español](super-admin.es.md) · [English](super-admin.en.md) · Bahasa Indonesia

Anda masuk dengan alamat e-mail dan kata sandi Anda.

**Super administrator** menjalankan platform: membuat dan menarik akademi serta melihat penggunaannya. Ini adalah peran
realm Keycloak (`super_admin`), bukan peran akademi. Super administrator **tidak dapat membaca isi akademi** (pemain,
pertandingan, data kesehatan): platform tidak punya akses ke sana. Pengecualiannya adalah daftar **administrator**
akademi (nama, email, dan status undangan), yang dikelola oleh super administrator (lihat di bawah, ADR-0023), dan
pencarian **Pengguna**, yang menampilkan setiap login dengan nama dan perannya di setiap akademi (amandemen ADR-0029).

## Admin aplikasi dan konteks
Login Anda dapat bekerja dalam beberapa **konteks**: **Admin aplikasi** (karena Anda super administrator) dan setiap
akademi tempat Anda menjadi anggota. Setiap konteks punya menunya sendiri.
- Jika satu-satunya konteks Anda adalah Admin aplikasi (tanpa keanggotaan akademi), Anda langsung masuk ke
  **Ringkasan**.
- Dengan beberapa konteks Anda masuk ke konteks terakhir yang dipakai di peramban ini, atau ke daftar untuk memilih.
  Ganti kapan saja lewat chip konteks di header: di ponsel terbuka lembar di bawah, di layar lebar sebuah panel di
  samping menu samping (tombol **Ganti konteks**). Setiap baris menampilkan nama dan peran Anda, mis. "Admin aplikasi /
  Super admin" atau "Hangtuah / Administrator". Pilihan diingat di peramban ini dan dilupakan saat Anda keluar.
- Tautan lama ke halaman `/platform/...` membuka halaman yang sama di dalam Admin aplikasi.
- Tombol bulat dengan inisial Anda (kanan atas, di setiap konteks) membuka menu: **Profil**, **Bahasa**, dan **Tema**
  (**Sistem**, **Terang**, **Gelap**; diingat di peramban ini, **Sistem** mengikuti perangkat Anda).

Menu Admin aplikasi berisi **Ringkasan** (hub), **Akademi**, **Pengguna**, **Permintaan** (lencana menghitung
permintaan akademi yang menunggu) dan **Audit**. Hub menampilkan area yang sama sebagai kartu (**Persetujuan tertunda**,
**Jejak audit**) ditambah **Penagihan**, yang bertuliskan "Segera hadir": belum ada yang perlu diatur.

## Akademi
**Akademi** menampilkan akademi dengan kolom pencarian (nama atau slug) dan filter status: **Aktif**, **Ditangguhkan**,
**Ditarik**. Buka satu akademi untuk melihat detail dan penggunaannya.

## Membuat akademi
**Akademi > Akademi baru** (lihat juga `docs/runbooks/onboard-tenant.md`):
- **Nama akademi**, **Pengenal (slug)** (huruf kecil, angka, dan tanda hubung, 3-50), **Zona waktu**, **Bahasa**.
- **Email admin pertama**, nama depan, dan nama belakang.
Saat **Buat**, akademi dan administrator pertamanya langsung ada, kategori usia bawaan (U8 sampai U18, SENIOR) terisi, dan
**kata sandi sementara** administrator ditampilkan kepada Anda **satu kali saja** (lihat "Masuk pertama kali" di bawah).
Tidak ada email yang dikirim. Jika email itu sudah punya akun login di platform (misalnya administrator akademi lain),
tidak ada kata sandi sementara: orang itu masuk dengan kata sandi yang sudah dimilikinya. Jika penyedia identitas tidak
tersedia, pembuatan gagal seluruhnya dan tidak ada yang tersisa ("502").

## Masuk pertama kali dengan kata sandi sementara (ADR-0024)
- Akun login baru mendapat kata sandi sementara buatan server (16 huruf dan angka) yang ditampilkan **satu kali saja**
  kepada pembuatnya. Ditampilkan di dialog **Kata sandi sementara**: kata sandi di kolom monospace besar, tombol **Salin kata sandi**, dan
  tombol **Selesai** yang eksplisit; dialog tidak bisa ditutup dengan cara lain dan kata sandinya tidak disimpan di mana
  pun. Platform tidak pernah menyimpannya; jika hilang, buat yang baru (**Buat kata sandi sementara baru**, di bawah).
- Sampaikan **secara pribadi**: langsung, lewat telepon, atau aplikasi pesan tepercaya, jangan pernah bersama alamat
  email dalam pesan yang sama.
- Orang itu membuka aplikasi, masuk dengan email dan kata sandi sementara, lalu Keycloak langsung meminta mereka
  **memilih kata sandi baru** (minimal 12 karakter, bukan email mereka). Sejak itu hanya kata sandi mereka sendiri yang
  berlaku.
- Salah kata sandi berulang kali mengunci akun login untuk sementara (perlindungan brute force).

- **Kata sandi sementara kedaluwarsa setelah 3 hari** jika belum dipakai (ADR-0028). Akun login lalu dinonaktifkan:
  orang tersebut melihat "Kata sandi sementara Anda sudah kedaluwarsa. Mintalah yang baru kepada administrator akademi
  Anda." di halaman masuk. Baris administrator menampilkan **Kata sandi sementara kedaluwarsa** di samping **Undangan
  tertunda**; gunakan **Buat kata sandi sementara baru** (tombol kunci) untuk memberi yang baru, yang sekaligus
  mengaktifkan kembali akun login. Pemeriksaan berjalan di latar belakang setiap kali kata sandi sementara dibuat atau
  seseorang masuk untuk pertama kali, jadi kata sandi yang kedaluwarsa bisa masih berfungsi sebentar sampai peristiwa
  berikutnya. Orang yang sudah memilih kata sandinya sendiri tidak pernah terpengaruh.

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
Di halaman detail akademi (**Akademi >** akademi itu) bagian **Administrator** menampilkan setiap administrator dengan
nama, email, status undangan (**Undangan tertunda** / **Undangan diterima**), dan peran lain mereka di akademi. Setiap
baris punya **Ubah administrator**, **Hapus administrator** dan, selama undangan masih tertunda, tombol kunci **Buat kata sandi sementara baru**;
**Tambah administrator** ada di bagian atas. Bagian ini berlaku untuk akademi aktif dan ditangguhkan; untuk akademi yang
**ditarik** hanya tampil catatan (administratornya tidak dapat lagi dilihat atau diubah). Operasi yang sama ada di API
platform `/platform/tenants/{id}/admins`.
- **Daftar**: administrator aktif dengan nama, email, status undangan, dan peran lain mereka di akademi.
- **Tambah** (email, nama depan dan belakang, bahasa opsional): anggota akademi dengan email itu menjadi administrator
  (datanya tetap; anggota tanpa akun login dibuatkan satu, dengan kata sandi sementara yang ditampilkan satu kali). Jika
  tidak ada, administrator baru dibuat seperti administrator pertama dan dialog menampilkan kata sandi sementaranya. Jika
  email itu sudah punya akun login, sebuah catatan menyebut bahwa orang itu masuk dengan kata sandinya saat ini. Email milik anggota yang dinonaktifkan ditolak.
- **Ubah** nama depan, nama belakang, atau email. Email baru juga menjadi alamat masuk orang itu (username dan email di
  Keycloak); tidak ada email yang dikirim dan kata sandi tidak berubah (kata sandi sementara yang belum dipakai tetap
  berlaku). Berbeda dengan administrator akademi, Anda boleh melakukannya juga untuk akun login yang dipakai di beberapa
  akademi: email baru lalu menggantikan email lama di setiap akademi tempat orang itu menjadi anggota aktif (satu orang,
  satu email), dan log audit setiap akademi itu mencatat perubahannya. Jika anggota lain di salah satu akademi itu sudah
  memakai alamat baru tersebut, perubahan ditolak ("email sudah dipakai") dan tidak ada yang berubah di akademi mana
  pun.
- **Hapus** (meminta konfirmasi): orang itu kehilangan peran administrator; peran lainnya tetap, dan jika itu
  satu-satunya perannya, ia dinonaktifkan di akademi ini. Akun loginnya tidak pernah dihapus (mungkin dipakai di tempat
  lain).
- **Administrator terakhir tidak dapat dihapus.** Sebuah akademi selalu memerlukan setidaknya satu administrator aktif.
  Jika hanya ada satu administrator dalam daftar, tombol **Hapus**-nya dinonaktifkan dan barisnya menjelaskan: "Sebuah
  akademi memerlukan setidaknya satu administrator. Tambahkan administrator lain terlebih dahulu." Jika orang lain baru
  saja mengubah daftar dan server tetap menolak, Anda melihat pesan yang sama. Tambahkan administrator baru terlebih
  dahulu, lalu hapus yang lama.
- **Buat kata sandi sementara baru** (tombol kunci; menggantikan "Kirim ulang undangan" yang lama) menampilkan
  **kata sandi sementara baru** di dialog yang sama (satu kali; yang lama tidak berlaku lagi),
  hanya selama undangan masih tertunda dan orang itu belum memilih kata sandi. Ini juga memperbaiki administrator yang
  dibuat sebelum perubahan ini dan tidak pernah mendapat kata sandi (mereka sama sekali tidak bisa masuk).
Setiap perubahan dicatat di jejak audit akademi dengan Anda sebagai pelakunya.

## Dasbor penggunaan
Detail akademi menampilkan **Penggunaan** per layanan (Inti, Pertandingan, Atlet): anggota, pemain, pemain aktif, tim, musim,
pertandingan, pertandingan langsung, peristiwa pertandingan, sesi latihan, catatan kehadiran, rencana, hasil tes, cedera,
dan pengukuran tubuh. Jika sebuah layanan tidak menjawab, pemberitahuan "Tidak ada data dari: ..." menyebutkannya dan
sisanya tetap tampil. Satu rekam jepret disimpan per akademi per hari (02:30 UTC); grafik tren belum ada di aplikasi.

## Pengguna
**Pengguna** mencari login mana pun di platform: ketik minimal 2 karakter dari nama atau email (huruf besar atau kecil
tidak berpengaruh); 25 hasil per halaman. Setiap login menampilkan emailnya dan, untuk setiap akademi tempat ia
bergabung, nama orang itu, perannya, dan statusnya (termasuk anggota tidak aktif dan akademi yang ditangguhkan atau
ditarik), atau "Bukan anggota akademi mana pun". Ketuk sebuah akademi untuk membuka halamannya. Daftar ini hanya untuk
dibaca: email administrator atau kata sandi sementara diubah di halaman akademi (**Administrator**, di atas).

## Permintaan (permintaan akademi)
Pengunjung meminta akademi lewat formulir di halaman depan. **Permintaan** menampilkan permintaan itu menurut status
(**Menunggu**, **Diterima**, **Ditolak**); lencana di menu menghitung yang menunggu. Permintaan dari dalam akademi
(persetujuan pemain) tidak ada di sini.
- **Terima** membuka **Buat akademi**, terisi dari permintaan: periksa pengenal (slug), zona waktu, dan nama
  administrator. Peminta menjadi administrator pertama akademi, apa pun peran yang ia sebutkan. Login baru mendapat
  kata sandi sementara yang ditampilkan satu kali (lihat "Masuk pertama kali" di atas); login yang sudah ada tidak
  mendapatkannya. Peminta menerima email penerimaan dalam bahasa permintaan berisi alamat masuk, tidak pernah kata
  sandinya.
- **Tolak** meminta **Alasan**, yang dikirim ke peminta lewat email.
- Jika email gagal dikirim, permintaan menampilkan **Email tidak terkirim**; keputusan tetap berlaku.
- Permintaan yang sudah diputuskan orang lain menjawab "Permintaan ini sudah diputuskan".

## Audit
**Audit** menampilkan jejak audit semua akademi, dari yang terbaru, setiap entri dengan akademinya; ikon jam di halaman
sebuah akademi hanya menampilkan akademi itu. Saring menurut rentang tanggal dan satu atau beberapa tindakan; pindah
halaman dengan panah di bawah. Nama hanya ditampilkan untuk akademi dan administratornya saat ini; anggota lain dan
pemain tampil menurut jenisnya, karena platform tidak membaca isi akademi selain identitas administratornya (ADR-0023,
ADR-0029). Entri hanya bisa ditambah dan disimpan (belum ada retensi).

Ikon unduh (**Ekspor aktivitas (CSV)**) menyimpan semua yang dipilih filter saat ini, bukan hanya halaman di layar,
sebagai file CSV dalam bahasa aplikasi. Perlu koneksi (file dibuat di server) dan berhenti di 10.000 baris: jika
diminta, persempit tanggal atau tindakan. Ekspor itu sendiri tercatat sebagai **Jejak audit diekspor** di setiap
akademi yang punya baris di file tersebut.

---
Status: disusun dari layar yang sudah diimplementasikan, kontrak, dan berkas terjemahan; belum diperiksa lewat uji manual di peramban.
