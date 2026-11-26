---
name: run-automation
description: Skill internal QA - menjalankan otomasi uji yang sudah ada untuk area tiket, dan menambah otomasi untuk test case baru yang stabil di worktree QA (branch qa/<KODE>). Kata kunci - otomasi uji, suite otomasi, tambah test otomatis.
argument-hint: KODE
---
Kode otomasi uji adalah satu-satunya kode yang ditulis QA (guard mengizinkan `e2e/`, `tests/`, `.maestro/`, `*.spec.*`, dan sejenisnya). Lokasi suite: memory project → Suite regresi.

## Langkah
1. **Jalankan yang ada**: suite bertag/berfolder area tiket (`area-<modul>` untuk Maestro; project/tag Playwright; tes kontrak). Area dipilih dari judul/komponen tiket, atau dari daftar file berubah `git diff --name-only <base>...<commit PR>` (nama saja; mode buta mengizinkan `--name-only`). Hasil masuk `## Regresi area terdampak` di `qa.md`.
2. Suite gagal → periksa apakah karena perubahan yang memang diminta tiket (harapan lama tidak berlaku lagi) atau regresi. Ragu → catat sebagai Gagal + draft bug, SPV yang memutuskan.
3. **Tambah otomasi**: TC yang Lulus, stabil (lulus 2× berturut-turut), dan mewakili alur penting → salin flow/spec dari `$W/flows/` ke suite di worktree QA (`rules.md` → Worktree QA), beri tag `area-<modul>`; flow baca-saja yang aman di live boleh diberi tag `smoke-live`. Tanpa kredensial di berkas; pakai variabel env.
4. Jalankan otomasi baru sekali di worktree QA, lalu commit `test: <KODE> <ringkasan>` di branch `qa/<KODE>` (push oleh Release).
5. Tambahkan ringkasannya ke `docs/qa/regresi/<area>.md` (template `regresi.md`).

## Hasil
Hasil suite area terdampak + daftar otomasi baru (path) untuk `qa.md`.
