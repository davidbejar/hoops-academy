# Panduan Super administrator

Bahasa: [Español](super-admin.es.md) · [English](super-admin.en.md) · Bahasa Indonesia

Anda masuk dengan alamat e-mail dan kata sandi Anda.

**Super administrator** menjalankan platform: membuat dan menarik akademi serta melihat penggunaannya. Ini adalah peran
realm Keycloak (`super_admin`), bukan peran akademi. Super administrator **tidak dapat membaca isi akademi** (pemain,
pertandingan, data kesehatan): platform tidak punya akses ke sana.

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
administrator menerima email berisi tautan untuk memilih kata sandi. Jika penyedia identitas tidak tersedia, pembuatan
gagal seluruhnya dan tidak ada yang tersisa ("502").

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

## Dasbor penggunaan
Detail akademi menampilkan **Penggunaan** per layanan (Inti, Pertandingan, Atlet): anggota, pemain, pemain aktif, tim, musim,
pertandingan, pertandingan langsung, peristiwa pertandingan, sesi latihan, catatan kehadiran, rencana, hasil tes, cedera,
dan pengukuran tubuh. Jika sebuah layanan tidak menjawab, pemberitahuan "Tidak ada data dari: ..." menyebutkannya dan
sisanya tetap tampil. Satu rekam jepret disimpan per akademi per hari (02:30 UTC); grafik tren belum ada di aplikasi.

---
Status: disusun dari layar yang sudah diimplementasikan, kontrak, dan berkas terjemahan; belum diperiksa lewat uji manual di peramban.
