# Pagar keamanan

`hooks/qa-guard.sh` dipasang sebagai hook di semua coding agent yang didukung. Ia **dorman** di luar sesi QA, supaya sesi Coder workflow delivery di komputer yang sama tidak terganggu. Pagar menyala bila:
- skill QA menyalakan mode lewat `qa-mode.sh qa on` (langkah 0 tiap perintah; teammate ikut mode SPV-nya), atau
- env `QA_AGENT_WORKFLOW=1` (otomatis untuk Claude Code yang dipasang dengan `--scope project`).

**Selama mode QA, selalu diblokir** (juga di mode otonom):
- Edit/Write file di repo selain **kode otomasi uji** (`e2e/`, `tests/`, `.maestro/`, `playwright/`, `*.spec.*`, `*.test.*`, `*Test.kt`, `*UITests/`, `androidTest/`, `pact/`, …) dan **dokumen QA** (`docs/tickets/`, `docs/qa/`, `docs/rilis/`). Berkas di luar repo git (folder kerja `/tmp/qa/`) bebas. Pola tambahan per komputer: `~/.agent-workflow/qa-test-paths.txt` (satu pola per baris, mis. `src/fixtures/*`).
- `git push` selain `origin`, selain branch `qa/<KODE>`, force-push, hapus branch, push tag.
- Merge atau approve PR/MR (`gh pr merge`, `glab mr merge`, `gh pr review --approve`, `glab mr approve`).
- Memindah tiket ke status di luar daftar status project (Done tidak pernah ada di sana), menutup issue.
- `rm -r` di luar folder project (isi `/tmp/qa/` bebas).
- `git worktree add` di luar folder sejajar; `git worktree remove` selain `<repo>-qa-<nomor>`, `--force`, `move`.
- Install/uninstall/`pm clear` di device yang dikunci agen lain (kunci dipakai bersama workflow delivery).

**Mode buta** (`/develop-tiket` langkah 1–5, uji ulang): juga `git diff`, `git show <commit>`, `git log -p`, `gh pr diff`, `glab mr diff`. Daftar nama file (`--name-only`/`--stat`) dan `git show <ref>:<path>` (mis. membaca spec contract) tetap boleh.

**Mode audit** (`/audit-issue`): hanya-baca penuh: git/gh/glab baca saja, tanpa komentar/transisi/buat tiket, edit hanya di `/tmp/qa/audit/`.

**Dijaga aturan skill + pemeriksa dokumen (bukan guard):**
- Membuat tiket bug dan mengembalikan tiket ke In Progress: hanya setelah izinmu (per bug, per tiket).
- Rekomendasi harus konsisten dengan hasil test case, tiap AC punya bukti, tiap TC gagal punya draft bug: ditegakkan `qa-check.py` sebelum laporan dikirim.
- Smoke live hanya baca; data uji hanya di dev/staging dan berawalan kode tiket.
- Kelemahan yang diketahui: tulis lewat shell (`sed -i`, `>`) tidak diurai guard.

**Agen selalu berhenti dan bertanya** bila: akan membuat tiket bug, akan mengembalikan tiket, build tidak cocok dengan PR/MR, kredensial/akun uji tidak ada atau lingkungan mengarah ke produksi, AC kabur sampai harapan tidak bisa ditentukan, atau device/akun dipakai tiket lain.

---
[← kembali ke README](../README.md)
