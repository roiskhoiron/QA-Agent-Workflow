---
name: retest-fix
description: Skill internal QA - menguji ulang test case yang gagal setelah perbaikan di build baru, ditambah cek singkat bahwa test case yang dulu lulus tidak rusak. Kata kunci - uji ulang, retest, verifikasi perbaikan.
argument-hint: KODE
---
Bahan: laporan uji sebelumnya (`docs/tickets/<KODE>/qa.md` di branch `qa/<KODE>` atau platform dokumentasi) dan draft/tiket bug-nya. Mode buta tetap menyala: perbaikan diverifikasi dari perilaku, bukan dari diff.

## Masukan (dari flow)
Build baru yang sudah diverifikasi memuat commit terakhir PR/MR, dan `qa.md` putaran sebelumnya.

## Langkah
1. Salin `qa.md` lama ke folder kerja sebagai putaran baru (`Build` diganti; tambah kepala `- Putaran: <n>`).
2. **TC Gagal**: jalankan ulang persis dengan alat yang sama (`tools.md`). Lulus → bug terkait ditandai "sudah diperbaiki di <build>" di tabel Bug (draft bug tetap disimpan). Tetap gagal → bug tetap terbuka; perilaku berubah tapi masih salah → perbarui draft bug.
3. **TC Lulus sebelumnya**: jalankan ulang TC `normal` semua AC (cek singkat tidak rusak). Ada yang jadi Gagal → tandai untuk draft bug baru.
4. **TC Tertahan sebelumnya**: coba lagi bila penyebabnya sudah hilang.
5. `python3 "$QA_WORKFLOW_DIR/bin/qa-check.py" report <qa.md>` lolos (tanpa `--final`).

## Hasil
`qa.md` putaran baru, siap untuk uji eksploratif singkat dan review di flow.
