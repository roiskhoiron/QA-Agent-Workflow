---
name: gate-validation
description: Skill internal QA - gerbang langkah 1 /develop-tiket - membaca laporan kelayakan uji, AC, dan contract, lalu memutuskan uji boleh mulai dan menyusun daftar yang diuji. Kata kunci - gerbang uji, cek kelayakan uji.
argument-hint: KODE
---
## Langkah
1. Cari komentar kelayakan uji terbaru di tiket (baris pertama = link `qa-validasi.md`) dan **baca laporannya**.
   | Kondisi | Tindakan |
   |---|---|
   | Belum pernah divalidasi | Tanya user: jalankan `/validate-tiket` dulu (saran), atau lanjut dengan cek singkat (gerbang = **cek singkat**; flow menjalankan cek AC dan build sekarang, dicatat di laporan uji) |
   | **Belum siap** | Berhenti dan tanya |
   | **Siap dengan catatan** | Tiap catatan jadi TC atau TC `Tertahan` beralasan |
   | **Siap diuji** | Lanjut |
2. **Build berubah sejak validasi?** Bandingkan commit terakhir PR/MR (`tiket.md`) dan build terbaru di tiket dengan yang tercatat di laporan kelayakan. Berubah → gerbang = **cek build ulang** (flow memeriksa build lagi sebelum uji).
3. **Tiket berubah sejak validasi?** AC/desain/contract berbeda dari laporan → sebut bedanya dan tanya sebelum lanjut.
4. Susun **daftar yang diuji**: AC bernomor + hasil yang diharapkan, role, build + lingkungan, contract, desain, akun/data yang dibutuhkan.

## Hasil
`${TMPDIR:-/tmp}/qa/<KODE>/gerbang.md` berisi keputusan gerbang (**lolos** / **cek singkat** / **cek build ulang** / **berhenti**) dan daftar yang diuji. Ini satu-satunya brief untuk Planner, tanpa diff atau rencana kerja.
