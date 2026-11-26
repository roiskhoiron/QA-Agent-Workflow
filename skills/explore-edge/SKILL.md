---
name: explore-edge
description: Skill internal QA - uji eksploratif di luar acceptance criteria dengan batas waktu, mencari masalah yang tidak tertulis di tiket. Kata kunci - uji eksploratif, exploratory testing, edge case.
argument-hint: "KODE [menit]"
---
**Batas waktu**: dari argumen, memory project → Batas uji eksploratif, atau default **30 menit**. Berhenti saat waktu habis, walau masih ada ide.

## Arah eksplorasi (pilih yang relevan dengan area tiket)
- Input aneh: kosong, spasi, emoji, sangat panjang, karakter khusus, tempel teks, angka negatif.
- Alur terputus: tombol kembali, tutup app/tab di tengah, rotasi layar, background/foreground, refresh.
- Jaringan: lambat, putus di tengah submit, timeout, kirim dua kali (double tap).
- Akun/data: dua akun bersamaan, sesi kedaluwarsa, data milik orang lain (otorisasi), data sangat banyak.
- Tampilan: layar kecil/besar, dark mode, ukuran font besar, bahasa lain.
- Area sekitar: layar/endpoint tetangga yang memakai komponen yang sama.

## Langkah
1. Catat jam mulai. Tulis tiap percobaan singkat di `${TMPDIR:-/tmp}/qa/<KODE>/eksplorasi.md`.
2. Masalah ditemukan → ulangi sekali, ambil bukti, catat langkah persis. Berarti (bukan sekadar preferensi) → tandai untuk draft bug dengan `TC: eksploratif`.
3. Waktu habis → berhenti, tulis area yang belum sempat dicoba.

## Hasil
Bagian `## Uji eksploratif` untuk `qa.md`: `Batas waktu: <n> menit`, tabel `Temuan | Langkah | Bukti | Bug` (atau "Tidak ada temuan"), dan area yang belum dicoba.
