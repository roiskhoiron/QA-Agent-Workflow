---
name: setup-docs
description: Skill internal QA - memastikan platform dokumentasi untuk laporan QA tercatat di memory project (default folder docs/ di repo sebagai Markdown; atau Claude Docs, Confluence, Notion). Kata kunci - platform dokumentasi, lokasi laporan QA.
---
Pastikan agen tahu ke mana dokumen QA dikirim. Lokasi default per dokumen: `~/.agent-workflow/qa-repo/skills/_shared/report-format.md`.

## Langkah
1. Baca memory project → **Platform dokumentasi**.
2. Belum ada → pakai default **`docs/` di repo** (Markdown, lewat worktree QA dan Draft PR otomasi uji), dan tanya user sekali apakah tim memakai platform lain. Pilihan:
   | Platform | Cara kirim | Link laporan |
   |---|---|---|
   | `docs/` di repo (default) | commit di branch `qa/<KODE>` + Draft PR/MR | link berkas di PR/MR |
   | Claude Docs | konektor Claude Docs, satu dokumen per laporan | link dokumen |
   | Confluence | konektor Atlassian, halaman di space dari memory | link halaman |
   | Notion | konektor Notion, halaman di database dari memory | link halaman |
3. Simpan pilihan + lokasi (space/database/repo dokumen) sebagai memory project tipe `reference`.
4. Platform selain `docs/`: cek konektornya terjangkau. Tidak → tanya user: pakai `docs/` dulu, atau berhenti.
5. Apa pun platformnya, Markdown tetap ditulis dan diperiksa `qa-check.py` di folder kerja lebih dulu.

## Hasil
Platform dokumentasi dan lokasinya diketahui untuk `write-report`.
