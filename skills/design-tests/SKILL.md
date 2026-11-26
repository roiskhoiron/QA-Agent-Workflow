---
name: design-tests
description: Skill internal QA - menyusun test case dari acceptance criteria, contract, dan desain - alur normal, nilai batas, dan alur gagal - tanpa membaca rencana kerja dan diff. Kata kunci - susun test case, desain uji, test case dari AC.
argument-hint: KODE
---
Jalankan dalam **mode buta** (`qa-mode.sh blind on` sudah dinyalakan SPV). Sumber hanya `${TMPDIR:-/tmp}/qa/<KODE>/gerbang.md`, tiket, contract, dan desain. Kode sumber produk tidak dibuka untuk menebak perilaku.

## Teknik
| Jenis | Kapan | Contoh |
|---|---|---|
| `normal` | **wajib** minimal satu per AC: alur yang diharapkan pengguna | isi form valid → tersimpan, muncul pesan sukses |
| `batas` | AC/contract punya angka, panjang, rentang, jumlah, waktu | 0, 1, maks, maks+1 karakter; tanggal awal/akhir bulan |
| `gagal` | ada validasi, galat jaringan/server, izin, data kosong | nomor salah → pesan galat; 401 → kembali ke login |
| `regresi` | alur lama yang wajib tetap jalan di area yang sama | daftar alamat lama tetap tampil |

Pertimbangkan juga (bila relevan): state kosong/loading/error, layar kecil, dark mode (mobile/web), aksesibilitas dasar, dua akun bersamaan, kembali/batal di tengah alur, koneksi lambat.

## Langkah
1. Untuk tiap AC: TC `normal` → TC `batas` → TC `gagal`. Satu TC = satu hal yang diperiksa.
2. Tiap TC: ID (`TC1`, `TC2`, …), AC (boleh `AC1, AC2`), Jenis, **Langkah** singkat yang bisa diulang orang lain, **Harapan** yang bisa diamati (dari AC/contract/desain, bukan dari kode), alat (Maestro / Playwright / Schemathesis / Pact / curl), kebutuhan `(fisik)`, akun (nama kunci), data uji berawalan KODE.
3. AC kabur → TC itu `Tertahan` dengan `alasan: AC kabur, menunggu jawaban <pertanyaan>`.
4. Urutkan TC supaya data yang dibuat satu TC bisa dipakai TC berikutnya, dan TC `(fisik)` dikelompokkan.

## Hasil
`${TMPDIR:-/tmp}/qa/<KODE>/test-cases.md`: tabel kolom `TC | AC | Jenis | Langkah | Harapan | Hasil | Bukti` (Hasil dan Bukti kosong) + kolom tambahan di bawahnya untuk alat, device, akun, data.
