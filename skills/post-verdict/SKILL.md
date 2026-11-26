---
name: post-verdict
description: Skill internal QA - menulis rekomendasi lolos atau gagal di komentar tiket beserta link laporan dan draft bug, tanpa menggeser tiket ke Done; membuat tiket bug atau mengembalikan tiket hanya setelah izin user. Kata kunci - rekomendasi QA, komentar hasil uji.
argument-hint: KODE
---
Hanya untuk `qa.md` yang lolos `qa-check.py report --final` dan sudah punya link laporan (`write-report`). Gaya: `report-format.md` → Komentar tiket.

## Langkah
1. **Komentar tiket** (adapter platform): baris pertama link laporan uji; lalu rekomendasi dalam bahasa awam (**lolos** / **belum lolos** / **tertahan** + alasannya), build yang diuji, ringkasan bug (judul + dampak, tanpa istilah teknis), link Draft PR/MR otomasi uji bila ada, dan kalimat penutup bahwa keputusan Done ada di QA manusia (sapa namanya dari memory project).
2. **Rekomendasi Gagal** — tanya user di chat (ringkasan + satu saran):
   - **Per bug**: "Buat tiket bug untuk bug-<n> (<keparahan>, <judul>)?" "Ya" → buat lewat adapter platform (isi = draft bug, link ke tiket asal); simpan link tiket bug di laporan.
   - **Per tiket**: "Kembalikan <KODE> ke In Progress?" "Ya" → pindah status (id dari daftar status project) + komentar singkat berisi daftar bug. Bukan "ya" → tiket tetap.
3. **Rekomendasi Lolos/Tertahan**: tidak ada pemindahan status. In Testing → tetap; QA manusia yang memindah ke Done.
4. Tanpa platform → tulis komentar dan saran tindakan di chat.

## Hasil
Link komentar; daftar tiket bug yang dibuat (bila ada) dan status akhir tiket. **Tidak pernah** Done atau tutup issue.
