---
name: prepare-data
description: Skill internal QA - menyiapkan data uji berawalan kode tiket dan memastikan build atau deploy yang benar terpasang di device/browser/lingkungan uji. Kata kunci - siapkan data uji, pasang build.
argument-hint: KODE
---
Aturan data: `~/.agent-workflow/qa-repo/skills/_shared/credentials.md` → Data uji. Alat: `tools.md`.

## Langkah
1. **Akun**: kunci akun dari jatah SPV (`device-lock.sh acquire account:qa.userN <KODE>-qa<n>`). Kredensial dibaca saat dipakai.
2. **Lingkungan**: base URL dari memory project/`qa.local.properties`. Mengarah ke produksi → berhenti.
3. **Pasang build** (role `mobile`): device dari `device-pick.sh` (virtual dulu; `--physical` untuk TC `(fisik)`), uninstall versi lama di device yang kamu kunci, install build dari `check-build`. Cocokkan versi di layar About/`adb shell dumpsys package`/`simctl` dengan build di laporan kelayakan.
   Role `web`: buka URL deploy, cocokkan versi/commit di halaman versi atau `/health`.
   Role `api`: cek `/health` atau endpoint versi.
4. **Data uji**: buat lewat app/API di lingkungan uji, semua nama diawali KODE (`PROJ-1234 Alamat Uji`, `proj1234+a@example.com`). Data yang tidak bisa dibuat → TC terkait `Tertahan` dengan alasan.
5. Catat data yang dibuat (tanpa password) di `${TMPDIR:-/tmp}/qa/<KODE>/data.md`.

## Hasil
Lingkungan siap dan versi build terverifikasi, `data.md` terisi. Versi tidak cocok → berhenti, lapor SPV.
