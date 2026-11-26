---
name: compare-attachments
description: Skill internal QA - membandingkan lampiran keluhan (screenshot, video, PDF, mockup, link) dengan hasil nyata dari reproduksi, hanya-baca. Kata kunci - bandingkan lampiran, cek screenshot pelapor.
argument-hint: "<slug>"
---
## Langkah
1. Baca semua lampiran. Gagal dibuka / alatnya tidak ada → sebut nama + alasannya, jangan dilewati diam-diam.
2. Dari tiap lampiran catat: layar/halaman, versi yang terlihat (nomor build, URL, tanggal), teks/pesan galat, langkah yang terlihat, perangkat.
3. Bandingkan dengan hasil reproduksi Auditor (`${TMPDIR:-/tmp}/qa/audit/<slug>/`): tabel `Lampiran | Hasil nyata | Beda?`. Beda versi antara lampiran dan build uji → sebut, karena bisa menjelaskan "tidak bisa direproduksi".
4. Mockup/PDF requirement terlampir → bandingkan juga dengan perilaku nyata: keluhan ternyata permintaan fitur (bukan bug) → catat.
5. Data pribadi atau kredensial di lampiran tidak disalin ke temuan.

## Hasil
`<nama agen>.md` di folder kerja: tabel perbandingan + tiap perbedaan dengan keyakinan **pasti** / **kuat** / **dugaan**.
