# Panduan Pelatih dan Asisten pelatih

Bahasa: [Español](coach.es.md) · [English](coach.en.md) · Bahasa Indonesia

Anda masuk dengan alamat e-mail dan kata sandi Anda.

Anda adalah **Pelatih** atau **Asisten pelatih**. Hak Anda berlaku untuk tim tempat administrator mendaftarkan Anda di
**Staf**. Bilah bawah: **Tim**, **Pertandingan**, **Latihan**, **Pemain**. **Profil** ada di bilah atas.

## Perbedaan asisten pelatih
| Tugas | Pelatih | Asisten pelatih |
|---|---|---|
| Membuat pertandingan, daftar pemain, mulai/selesai, jam, mencatat statistik apa pun | ya | ya |
| Kalender latihan, kehadiran, rencana, tugas, ketidakhadiran | ya | ya |
| Cedera, tinggi/berat, hasil tes fisik | ya | ya |
| Menetapkan pemain ke tim, menyelesaikan kasus kelayakan (tim sendiri) | ya | tidak (hanya baca) |
| Mengajukan pemain baru atau pengunduran (perlu persetujuan administrator) | ya | tidak |
| Mengubah nomor punggung pilihan pemain | ya | tidak (hanya baca) |
| Mengekspor daftar tim (CSV) | ya (tim sendiri) | tidak |
| Katalog latihan: membuat, mengubah, mengarsipkan latihan sendiri | ya | ya |

Layar yang tidak diizinkan menampilkan "Hanya baca: Anda tidak berhak mengubah ini."

## 1. Menyiapkan pertandingan
Tab **Pertandingan**: daftar dengan filter tim dan status (Terjadwal, Berlangsung, Selesai, Dibatalkan).
1. **Pertandingan baru**: tim, lawan, tanggal. Format bawaan 4 babak @ 10 menit.
2. Buka pertandingan, pilih **Atur daftar pemain**: centang pemain, tandai **Starter**, isi **Nomor** punggung. Minimal
   satu starter. Pengaturan ini perlu koneksi; setelah tersimpan, daftar disimpan di perangkat.
3. **Mulai pertandingan**.

## 2. Mencatat langsung
Tampilan langsung punya header (skor, babak, jam) dan tiga tab: **Lapangan**, **Catatan**, **Statistik**.
- **Mulai B1** / **Akhiri B1** mengatur babak. **Jalankan jam**, **Hentikan jam**, serta **Kurangi/Tambah 10 detik**
  menjalankan jam lokal (kemudahan saja, tidak disimpan sebagai catatan).
- **Lapangan** menampilkan lima pemain di lapangan dan cadangan. Ketuk pemain untuk membuka aksi: 2 PT / 3 PT / LB masuk
  atau gagal, Asis, Rebound serang, Rebound bertahan, Curi bola, Blok, Turnover, Pelanggaran pribadi / teknis / tidak
  sportif.
- Ketuk pemain cadangan untuk pergantian: "X masuk menggantikan…" lalu pilih siapa yang keluar.
- Tombol header: **Lawan +1 / +2 / +3**, **Time-out**, **Time-out lawan**, **Batalkan** (undo).
- Tab **Catatan** menampilkan tiap catatan beserta status sinkron dan pencatatnya. **Batalkan** (void) membatalkan sebuah
  catatan (peristiwa VOID dicatat; tidak ada yang dihapus). Aksi undo membatalkan catatan terakhir Anda yang masih berlaku.
- Tab **Statistik**: skor per babak, tabel per pemain, total tim, dan **Salin hasil**. Peringatan "N peringatan konsistensi
  (perbaiki dengan Batalkan)" berarti catatan saling bertentangan (mis. pergantian pemain yang tidak ada di lapangan).
- **Selesaikan pertandingan** mengakhirinya. Koreksi tetap bisa dilakukan setelahnya.
Beberapa orang (dua pelatih, orang tua) dapat mencatat bersamaan; catatan mereka digabung menurut waktu pertandingan.
Anda (dan admin) melihat semua catatan. Orang tua dan pemain hanya melihat catatan tim (babak, poin lawan, time-out,
catatan tim) serta catatan anak mereka atau diri sendiri, dengan skor resmi.

## 3. Bekerja offline dan banner "N belum tersinkron"
Setiap catatan disimpan dulu di perangkat, lalu dikirim di latar belakang. Anda bisa terus mencatat tanpa jaringan selama
tab aplikasi tetap terbuka.
- Setiap catatan menampilkan **Menunggu**, **Mengirim**, **Tersinkron**, atau **Ditolak: alasan**.
- Banner **"N belum tersinkron"** (dengan **Coba lagi**) menunjukkan catatan yang belum terkonfirmasi. Banner hilang
  sendiri saat koneksi kembali, saat aplikasi dibuka ulang, atau saat Anda masuk lagi. Percobaan ulang berjeda 1 sampai 60
  detik.
- **Masuk lagi untuk sinkronisasi; data tetap tersimpan**: sesi Anda berakhir. Masuk kembali, lalu antrean dikirim.
- Catatan **Ditolak** (mis. "tidak diizinkan", "pertandingan dibatalkan") tidak akan pernah diterima: **Buang** saja.
- Mengirim ulang satu paket aman: duplikat dikenali dan tidak dihitung dua kali.
- Batasan yang diketahui: membuka ulang aplikasi tanpa jaringan sama sekali bergantung pada service worker yang belum
  diuji di peramban sungguhan; jangan membuka pertandingan yang sama di dua tab pada satu perangkat.

## 4. Latihan
Tab **Latihan**: kalender mingguan dengan sebelumnya/berikutnya/hari ini dan filter tim. Menu: **Rencana**, **Jadwal**,
**Ketidakhadiran**, **Tugas**.
- **Jadwal > Jadwal baru**: hari, jam, durasi, lokasi, masa berlaku. Sesi dibuat otomatis jauh hari; sesi tunggal
  ditambahkan lewat **Sesi baru**.
- Buka sesi untuk melihat detail; **Batalkan sesi** meminta alasan. **Kehadiran**: tandai tiap pemain **Hadir**,
  **Terlambat** (menit 1-180), **Absen**, atau **Izin**, lalu **Simpan kehadiran**. Pemain dengan ketidakhadiran terencana
  diberi label dan otomatis terpilih Izin; pemain cedera ditandai **Cedera**.
- **Rencana**: tab **Rencana kami** dan **Templat**. Templat hanya baca; **Gunakan templat** menyalinnya. Di editor
  tambahkan latihan (judul, menit, set, pengulangan, tautan video https) dan urutkan dengan Naikkan/Turunkan.
- **Tugaskan**: ke tim atau pemain, dengan batas waktu. **Tugas** menampilkan jumlah Selesai / Sebagian / Belum; buka satu
  tugas untuk melihat tiap pemain dan menandai sendiri bila perlu.
- **Ketidakhadiran**: catat ketidakhadiran terencana untuk pemain mana pun (dari, sampai, alasan).

## 5. Data kesehatan dan kebugaran
**Pemain** > pilih pemain > ikon kesehatan:
- **Cedera**: **Catat cedera** (bagian tubuh, tingkat Ringan/Sedang/Berat, tanggal, perkiraan kembali). **Tandai pulih**
  saat sudah kembali. Pemain cedera ditampilkan tidak tersedia.
- **Pertumbuhan**: **Tambah pengukuran** (tinggi cm, berat kg; satu per hari); grafik atau tabel.
- **Tes fisik**: **Catat hasil**; aplikasi menjawab dengan **pita yang diharapkan** untuk usia dan gender pemain. "Tidak ada
  norma untuk usia dan jenis kelamin ini" berarti tidak ada norma yang cocok; **Rujukan menyusul** berarti normanya
  sementara.

## 6. Mengajukan pemain (khusus pelatih)
**Pemain** > **Ajukan pemain baru**: nama, tanggal lahir, gender, email opsional, tim awal (tim yang Anda latih), dan catatan
untuk administrator. **Permintaan saya** menampilkannya; batalkan yang tertunda dengan **Batalkan permintaan**. Untuk
mengeluarkan pemain dari tim Anda, gunakan **Keluarkan** di detail pemain: ini dikirim sebagai permintaan. Sampai
disetujui, pemain hanya terlihat oleh Anda dan administrator. Anda tidak dapat menyetujui permintaan sendiri.

## 7. Katalog latihan dan menambah latihan
**Latihan > Rencana** punya tab ketiga, **Latihan**: katalog latihan.
- Latihan **Global** (latihan dari templat ditambah tes Cooper, dalam bahasa Anda) hanya bisa dibaca. Latihan milik
  akademi dibuat dengan **Latihan baru**, diubah, diarsipkan (**Arsipkan**) dan dipulihkan (**Pulihkan**) oleh pelatih,
  asisten pelatih, dan administrator. Saring dengan **Semua**, **Global**, dan **Akademi**; **Tampilkan arsip** ikut
  menampilkan yang diarsipkan; **Muat lagi** di bagian akhir. Pencarian rencana juga menemukan latihan katalog.
- **Tambah latihan** di sebuah sesi, di dialog **Sesi baru**, dan **Tambah dari katalog** di editor rencana: cari
  (mis. "cooper"); latihan katalog tampil lebih dulu, item yang cocok dari rencana dan templat Anda di bawahnya. Centang
  beberapa lalu tekan **Tambah (n)**: ditambahkan sesuai urutan Anda mencentang. Di dialog sesi baru latihan ditambahkan
  setelah sesi dibuat; jika gagal, sesi tetap ada dan dialog menjelaskan sebabnya.
- Item yang ditambahkan menyimpan teksnya sendiri, yang boleh Anda ubah, dan bertanda **Dari katalog latihan**.
  Mengarsipkan latihan tidak mengubah item yang memakainya, tetapi latihan yang diarsipkan tidak dapat ditambahkan lagi
  ("Latihan itu diarsipkan: pilih yang lain").

## 8. Nomor punggung
- Halaman pemain menampilkan **Nomor punggung pilihan**. Pelatih mengubahnya (**Ubah nomor pilihan**; satu atau dua
  angka, kosong menghapusnya); asisten pelatih hanya melihatnya. Orang tua dan pemain boleh mengisinya sebagai keinginan.
- Saat Anda menetapkan pemain ke salah satu tim Anda tanpa mengetik nomor, aplikasi memakai nomor pilihan jika kosong
  di tim itu; jika tidak, nomor dari tim terbaru pemain yang punya nomor, jika kosong; jika tidak, tidak ada, dan
  menyebut aturan yang dipakai. Tanpa nomor, pemilih langsung terbuka: menampilkan **Nomor terpakai** beserta pemainnya
  dan **Nomor kosong** (0-99); nomor terpakai ditolak dengan menyebut pemakainya.

## 9. Ekspor
- **Daftar tim** (hanya pelatih tim itu, juga tim yang Anda latih di musim yang sudah selesai): ikon unduh di bilah atas
  tim (**Ekspor daftar pemain (CSV)**) menyimpan pemain dengan datanya, kategori, kelayakan, dan kontak walinya, serta
  staf sebagai blok kedua. Dibuat oleh server: perlu koneksi, memakai bahasa aplikasi, dan tercatat di aktivitas
  akademi. Asisten pelatih tidak punya ekspor ini.
- Dibuat di perangkat Anda dari data yang sudah dimuat layar (ikon unduh **Ekspor**): **Statistik musim** (satu baris per
  pertandingan ditambah total) dan statistik sebuah pertandingan sebagai **File CSV** atau **File Excel**; daftar
  pertandingan dan minggu latihan sebagai kalender tim (pertandingan dan sesi musim yang dipilih) dalam CSV, Excel, atau
  **File kalender (.ics)**, yang bisa diimpor kalender ponsel atau komputer. Excel dimuat saat pertama kali Anda memilihnya
  dan saat itu perlu koneksi; tanpa koneksi aplikasi memberi tahu dan file CSV tetap bisa dipakai.

## 10. Nama Anda
**Profil > Nama Anda** mengubah nama depan dan belakang Anda sendiri seperti yang dilihat akademi ini (**Simpan nama**;
perlu koneksi). Email Anda diubah oleh administrator.

---
Status: disusun dari layar yang sudah diimplementasikan dan berkas terjemahan; belum diperiksa lewat uji manual di peramban.
