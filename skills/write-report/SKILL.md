---
name: write-report
description: Skill internal QA - memeriksa dokumen QA dengan qa-check.py lalu mengirimnya ke platform dokumentasi project (default docs/ di repo lewat branch qa/<KODE>), dan mengembalikan link laporan. Kata kunci - tulis laporan, publikasi laporan QA.
argument-hint: "<path dokumen> [KODE]"
---
Satu pintu untuk semua dokumen QA: kelayakan, laporan uji, draft bug, rekomendasi rilis, laporan audit. Format: `~/.agent-workflow/qa-repo/skills/_shared/report-format.md`.

## Langkah
1. **Periksa dulu**: `python3 "$QA_WORKFLOW_DIR/bin/qa-check.py" <validasi|report --final|bug|signoff|ticket> <path>`. Exit ≠ 0 → jangan kirim; kembalikan ke penulisnya. (Laporan audit dan regresi tidak punya pemeriksa.)
2. **Kirim** sesuai memory project → Platform dokumentasi (`setup-docs`):
   - **`docs/` di repo:** di worktree QA (`rules.md` → Worktree QA) salin ke lokasi default (`docs/tickets/<KODE>/`, `docs/rilis/`, `docs/qa/…`) beserta `img/` terpilih (hanya bukti yang dirujuk). Commit `docs: <KODE> <jenis dokumen>`, lalu Release push `git push origin qa/<KODE>`. Link laporan = link berkas di branch (`<url repo>/blob/qa/<KODE>/docs/tickets/<KODE>/qa.md`) dan link Draft PR/MR.
   - **Claude Docs / Confluence / Notion:** satu dokumen per laporan, judul sama dengan judul Markdown, unggah gambar bukti. Link laporan = link dokumen.
3. **Mode audit** (`/audit-issue`, hanya-baca): tidak ada commit/push. Platform `docs/` → laporan tetap di `${TMPDIR:-/tmp}/qa/audit/<slug>/` dan isinya ditampilkan di chat; platform lain → publikasikan ke sana bila konektornya bukan platform tiket.
4. Tunggu link benar-benar ada sebelum lanjut. Tanpa link → jangan komentar tiket.

## Hasil
Link laporan (dan link Draft PR/MR bila `docs/`). Tanpa kredensial di dokumen.
