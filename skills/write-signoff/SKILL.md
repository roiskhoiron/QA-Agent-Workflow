---
name: write-signoff
description: Skill internal QA - menulis rekomendasi rilis per versi beserta daftar risiko yang tersisa, dari rekomendasi QA tiap tiket, regresi penuh, dan smoke live. Rekomendasi, bukan keputusan rilis. Kata kunci - rekomendasi rilis, QA sign-off.
argument-hint: "vX.Y.Z KODE-tiket-rilis"
---
Format: `~/.agent-workflow/qa-repo/skills/_shared/report-format.md` → Rekomendasi rilis. Template: `templates/signoff.md`.

## Langkah
1. **Tiket dalam rilis**: dari tiket rilis (daftar/link tiket) atau laporan rilis workflow delivery. Per tiket: rekomendasi QA terakhir (link laporan) dan bug terbuka. Tiket tanpa laporan QA → `belum diuji` (risiko).
2. Isi `## Regresi penuh` dari hasil regresi (`regresi.md`) dan `## Smoke live` dari hasil smoke (atau "Belum dijalankan").
3. **Rekomendasi**:
   | Kondisi | Rekomendasi |
   |---|---|
   | Semua tiket Lolos, regresi dan smoke Lulus | **Layak rilis** |
   | Ada Tertahan/belum diuji/smoke belum jalan, atau bug S3–S4 terbuka, tanpa Gagal | **Layak dengan risiko** (sebut risikonya) |
   | Ada tiket Gagal, regresi/smoke Gagal, atau bug S1–S2 terbuka | **Tidak layak rilis** (saran: keluarkan tiket X / tunda) |
4. `## Risiko tersisa`: tiap risiko satu baris, dengan dampak ke pengguna.
5. `python3 "$QA_WORKFLOW_DIR/bin/qa-check.py" signoff <file>` harus lolos.

## Hasil
`${TMPDIR:-/tmp}/qa/rilis-vX.Y.Z/vX.Y.Z-qa.md` siap dikirim flow, dan teks komentar di tiket rilis: baris pertama link dokumen, lalu rekomendasi + jumlah risiko. Tidak ada merge, tag, atau Done.
