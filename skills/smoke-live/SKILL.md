---
name: smoke-live
description: Skill internal QA - uji baca-saja di lingkungan live setelah rilis atau sebelum izin upload produksi - hanya flow bertag smoke-live, tanpa menulis data. Kata kunci - smoke live, smoke test produksi.
argument-hint: vX.Y.Z
---
Satu-satunya skill QA yang boleh menyentuh produksi, dan **hanya membaca**.

## Langkah
1. Jalankan hanya flow bertag `smoke-live` (Maestro/Playwright) dan endpoint `GET`/`HEAD` yang terdaftar di suite. Tidak ada flow → tulis "Belum ada flow smoke-live" sebagai risiko.
2. Akun: hanya akun uji live yang terdaftar di `credentials.md`; tanpa itu → hanya halaman/endpoint publik. Tidak pernah login akun nyata.
3. Tidak ada submit, pembelian, pengiriman pesan, atau perubahan data apa pun. Flow yang ternyata menulis data → hentikan, tandai Tertahan, laporkan sebagai risiko.
4. Gagal → ulang sekali; tetap gagal → **Gagal** + bukti, langsung lapor ke user (dampak produksi).

## Hasil
Tabel `Flow | Hasil | Bukti` untuk `## Smoke live` di rekomendasi rilis.
