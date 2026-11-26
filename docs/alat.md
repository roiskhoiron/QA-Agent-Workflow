# Alat

## Skrip di `bin/`
Agen memanggilnya sebagai `$QA_WORKFLOW_DIR/bin/<skrip>` (`QA_WORKFLOW_DIR` = `~/.agent-workflow/qa-repo`).

| Skrip | Gunanya | Contoh |
| --- | --- | --- |
| `qa-check.py` | Pemeriksa dokumen QA: tiap AC punya TC + bukti, hasil dan rekomendasi konsisten, TC gagal punya draft bug, draft bug lengkap, rekomendasi rilis tidak lebih optimis dari regresi. Exit 0 lolos, 1 pelanggaran, 2 salah pakai | `python3 bin/qa-check.py ticket docs/tickets/PROJ-1234 --final` |
| `qa-mode.sh` | Nyalakan/matikan mode `qa`, `blind` (buta), `audit` untuk guard | `AGENT_LOCK_PID=$PPID bin/qa-mode.sh blind on` |
| `device-pick.sh` | Ambil device bebas (virtual dulu, `--physical` bila perlu hardware asli) | `AGENT_LOCK_PID=$PPID bin/device-pick.sh android PROJ-1234-qa1` |
| `device-lock.sh` | Kunci device/akun/checkout: satu benda, satu agen, satu waktu | `bin/device-lock.sh who android:emulator-5554` |
| `annotate.py` | Kotak merah + label di screenshot dari koordinat elemen | `uv run --with pillow python3 bin/annotate.py in.png boxes.json out.png` |

Kunci disimpan di `~/.agent-workflow/locks`, **dipakai bersama** workflow delivery: device yang sedang dipakai Coder/QA Mobile tidak akan direbut agen QA.

## Alat uji per role

| Role | Tempat uji | Alat utama | Cadangan |
| --- | --- | --- | --- |
| `mobile` | simulator/emulator dulu, device fisik bila perlu | Maestro | `adb`; XCUITest runner workflow Mobile bila terpasang |
| `web` | Chromium (Firefox/WebKit bila tiket menyebut) | Playwright | langkah manual tertulis |
| `api` | server dev/staging | Schemathesis, Pact, `curl` | `curl` |

QA **tidak membangun** aplikasi: yang diuji adalah build/deploy yang diserahkan workflow delivery (Firebase, TestFlight, URL deploy). `/check-build` memastikan build memuat commit terakhir PR/MR tiket.

## Template dokumen (`templates/`)
`qa-validasi.md`, `qa.md`, `bug.md`, `signoff.md`, `regresi.md`, `audit.md`. Aturan isinya: `skills/_shared/report-format.md`. Template mentah selalu ditolak `qa-check.py` (placeholder `<...>` belum diisi).

---
[← kembali ke README](../README.md)
