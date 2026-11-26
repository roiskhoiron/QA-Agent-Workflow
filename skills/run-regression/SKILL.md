---
name: run-regression
description: Skill internal QA - menjalankan suite regresi penuh di build kandidat rilis (beta/staging) dan mengaitkan flow yang gagal ke tiket yang menyentuh areanya. Kata kunci - regresi penuh, regression test, suite regresi.
argument-hint: vX.Y.Z
---
Suite: memory project → Suite regresi (folder flow Maestro / spec Playwright / tes kontrak, plus kumpulan test case manual `docs/qa/regresi/`). Belum ada → tanya sekali, simpan; suite kosong → tulis "belum ada suite regresi" sebagai **risiko**, jangan dianggap lulus.

## Langkah
1. Build kandidat rilis dari tiket rilis / workflow rilis (QA tidak membangun), sudah diverifikasi memuat commit rilis (masukan dari flow).
2. Jatah device/akun per QA run (`device-pick.sh`, owner `rilis-vX.Y.Z-qa<n>`); data uji berawalan `vX.Y.Z`.
3. Jalankan seluruh suite otomasi; test case manual di `docs/qa/regresi/` dijalankan untuk area yang tidak punya otomasi.
4. Flow gagal → ulang sekali (flaky); tetap gagal = **Gagal**. Kaitkan dengan tiket rilis yang menyentuh area itu (judul/komponen tiket, atau `git diff --name-only` antar-tag/branch rilis; nama file saja) → draft bug `TC: regresi`.
5. Tidak bisa dijalankan (device/akun/lingkungan) → **Tertahan** + alasan.

## Hasil
Tabel `Flow | Hasil | Bukti` (+ tiket terkait untuk yang gagal) untuk `## Regresi penuh` di rekomendasi rilis, di `${TMPDIR:-/tmp}/qa/rilis-vX.Y.Z/regresi.md`.
