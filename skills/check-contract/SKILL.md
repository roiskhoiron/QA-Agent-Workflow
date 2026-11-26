---
name: check-contract
description: Skill internal QA - menjalankan Schemathesis dan Pact untuk endpoint di tiket dan membandingkan respons dengan contract API. Dev/staging penuh; beta/live hanya method aman. Kata kunci - cek contract, Schemathesis, Pact, uji API.
argument-hint: KODE
---
Lokasi spec/kontrak: memory project → Kontrak API (belum ada → cari di repo, lalu tanya). Aturan API: `~/.agent-workflow/qa-repo/skills/_shared/tools.md` → API.

## Langkah
1. Daftar endpoint tiket dari tiket/contract (bukan dari diff).
2. **Schemathesis** hanya untuk endpoint itu: `schemathesis run <spec> --base-url <url> --include-path <path> --checks all` di dev/staging. Beta/live (hanya bila diminta): `--include-method GET --include-method HEAD --include-method OPTIONS`, tanpa fuzzing data tulis.
3. **Pact**: verifikasi interaksi yang menyangkut endpoint tiket, bila kontrak ada.
4. Hasil per endpoint: **Sesuai contract** / **Beda contract** (field, tipe, wajib/opsional, kode status) / **Belum ada** / **Tidak dicek** + alasan.
5. Beda contract yang menyentuh AC → TC terkait Gagal + draft bug; beda di luar AC → temuan (keparahan sesuai dampak).

## Hasil
`${TMPDIR:-/tmp}/qa/<KODE>/contract.md`: perintah, tabel endpoint → hasil, potongan output penting (token disamarkan); dirujuk sebagai bukti TC API.
