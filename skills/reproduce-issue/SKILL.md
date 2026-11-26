---
name: reproduce-issue
description: Skill internal QA - mencoba mereproduksi keluhan dari lapangan di build yang sudah ada (device, browser, atau API), hanya-baca terhadap repo dan tiket, dengan bukti dan frekuensi. Kata kunci - reproduksi keluhan, coba ulang bug lapangan.
argument-hint: "<slug> <nomor pertanyaan>"
---
Mode audit menyala (hanya-baca). Alat: `~/.agent-workflow/qa-repo/skills/_shared/tools.md`. Folder kerja `${TMPDIR:-/tmp}/qa/audit/<slug>/`.

## Langkah
1. Build/versi dari pertanyaan; pasang build yang **sudah ada** (store/TestFlight/Firebase/URL live atau staging). Tidak ada → "tidak bisa direproduksi di versi itu".
2. Lingkungan: staging dulu dengan akun uji. Gejala hanya mungkin di live → hanya langkah baca-saja dengan akun uji live (`smoke-live` aturannya); tidak ada akun → catat tidak bisa diperiksa.
3. Jalankan langkah pelapor apa adanya (≥2 kali). Tidak muncul → variasi satu per satu: device/OS/browser lain, akun/data lain, jaringan lambat, urutan langkah berbeda.
4. Catat frekuensi (n dari m percobaan) dan kondisi yang memicu.
5. Bukti: screenshot bertanda, rekaman, potongan log/respons (token/data pribadi disamarkan).
6. Lepas semua kunci device/akun.

## Hasil
`<nama agen>.md` di folder kerja: per pertanyaan **Ya** / **Tidak** / **Kadang** + kondisi + bukti + keyakinan (**pasti** / **kuat** / **dugaan**).
