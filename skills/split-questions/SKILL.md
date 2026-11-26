---
name: split-questions
description: Skill internal QA - memecah keluhan dari lapangan (belum jadi tiket) menjadi pertanyaan yang bisa diuji - gejala, platform, versi, langkah, dan apa yang harus dibuktikan. Kata kunci - pecah keluhan, analisis keluhan.
argument-hint: "\"<teks keluhan>\""
---
## Langkah
1. Dari teks keluhan dan lampiran: **gejala** (apa yang dilihat pengguna), **di mana** (layar/halaman/endpoint), **role** (mobile/web/api), **platform & versi** (OS, browser, versi app; tidak disebut → versi live terbaru), **akun/data** yang terlibat (tanpa data pribadi), **kapan** (sejak kapan, selalu/kadang).
2. Susun pertanyaan yang bisa dijawab dengan mencoba, mis.:
   - "Apakah <gejala> muncul di <versi> dengan langkah pelapor?"
   - "Apakah muncul juga di <platform/browser lain>?"
   - "Apakah tergantung data (akun baru vs lama)?"
3. Informasi kurang sampai tidak bisa dicoba → tanya user dengan satu saran asumsi.
4. Pilih mode: satu role, satu pertanyaan sempit = solo; selain itu tim (Auditor per platform, Analis bila ada lampiran).

## Hasil
`${TMPDIR:-/tmp}/qa/audit/<slug>/pertanyaan.md`: ringkasan keluhan + daftar pertanyaan bernomor + pembagian ke Auditor/Analis.
