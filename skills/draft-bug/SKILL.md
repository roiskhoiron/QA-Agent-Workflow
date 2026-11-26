---
name: draft-bug
description: Skill internal QA - menulis draft bug lengkap (langkah, hasil, harapan, bukti, tingkat keparahan S1-S4) untuk test case gagal atau temuan eksploratif. Draft tidak otomatis jadi tiket. Kata kunci - draft bug, laporan bug, bug report.
argument-hint: "KODE TC"
---
Format dan skala: `~/.agent-workflow/qa-repo/skills/_shared/report-format.md` → Draft bug, `rules.md` → Tingkat keparahan bug. Template: `~/.agent-workflow/qa-repo/templates/bug.md`.

## Langkah
1. Nomor bug berikutnya di folder kerja: `bug-1.md`, `bug-2.md`, … (satu masalah = satu bug; dua TC gagal karena satu sebab = satu bug yang menyebut kedua TC).
2. Isi kepala: Tiket, TC (atau `eksploratif`), Keparahan, Build, Lingkungan, Device/browser.
3. **Langkah** bernomor dari kondisi awal yang jelas (akun, data berawalan KODE), cukup untuk diulang developer tanpa bertanya.
4. **Hasil** (yang terjadi) dan **Harapan** (yang seharusnya, dengan rujukan AC/contract/desain). Jangan menebak penyebab di kode; dugaan area boleh di `## Catatan` dengan label dugaan.
5. **Bukti**: screenshot bertanda, potongan log/respons (token disamarkan), frekuensi (selalu / n dari m percobaan).
6. Keparahan menurut dampak ke pengguna, bukan menurut sulitnya perbaikan.
7. `python3 "$QA_WORKFLOW_DIR/bin/qa-check.py" bug <file>` harus lolos.
8. Tambah baris di tabel `## Bug` `qa.md` dan sebut `bug-<n>` di kolom Bukti TC yang gagal.

## Hasil
`${TMPDIR:-/tmp}/qa/<KODE>/bug-<n>.md`. **Tidak** membuat tiket: Release menanyakan izin per bug.
