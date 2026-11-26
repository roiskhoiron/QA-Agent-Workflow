---
name: run-flow
description: Skill internal QA - menjalankan test case di device (Maestro), browser (Playwright), atau API (curl/Schemathesis) sesuai role tiket, mengambil bukti tiap langkah, dan mencatat Lulus/Gagal/Tertahan. Kata kunci - jalankan uji, eksekusi test case.
argument-hint: "KODE [TC...]"
---
Alat dan cadangannya: `~/.agent-workflow/qa-repo/skills/_shared/tools.md`. Folder kerja `W=${TMPDIR:-/tmp}/qa/<KODE>`.

## Langkah
1. Per TC dari `$W/test-cases.md`, jalankan langkahnya **apa adanya**:
   - `mobile`: flow Maestro `$W/flows/<TC>.yaml` dengan `takeScreenshot: <TC>-<nn>` tiap langkah penting, `maestro --device <id> test`.
   - `web`: spec Playwright `$W/flows/<TC>.spec.ts`, screenshot tiap langkah penting, trace bila gagal.
   - `api`: `curl` atau skrip langkah; simpan request (tanpa token) + status + body ringkas di `$W/logs/<TC>.txt`.
2. Bandingkan hasil dengan **Harapan** TC, bukan dengan kode atau rencana kerja. UI: bandingkan juga dengan desain (layout, teks, state).
3. Hasil:
   - **Lulus**: harapan terpenuhi; bukti = screenshot/log yang menunjukkan harapan itu (kotak merah di elemen yang dimaksud).
   - **Gagal**: harapan tidak terpenuhi; ulangi sekali untuk menyingkirkan flaky. Tetap gagal → bukti; TC ditandai untuk draft bug.
   - **Tertahan**: tidak bisa dijalankan (device/akun/data/alat tidak ada); `alasan: ...`.
4. Tertunda karena device diambil alih → bukan kegagalan; antre lagi, ulangi TC dari awal.
5. Bukti disimpan di `$W/img/` (`TC1-01.png`, …) dan `$W/logs/`.

## Hasil
Kolom `Hasil` dan `Bukti` tiap TC terisi di `$W/test-cases.md`.
