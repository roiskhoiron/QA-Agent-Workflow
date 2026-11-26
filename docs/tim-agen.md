# Tim agen

| Agen (berkas) | Nama | Model | Tugas | Tidak boleh |
| --- | --- | --- | --- | --- |
| SPV (`qa-spv`) | Bu Endang | opus | gerbang uji, bagi tugas, jatah device/akun, putuskan rekomendasi | kode produk, Done |
| Validator (`qa-validator`) | Kang Dadan | opus | `/validate-tiket`; mode tim = SPV validasi | kode produk, Done |
| Planner (`qa-planner`) | Pak Broto | `claude-fable-5-2` | test case dari AC + contract + desain | membaca diff/rencana kerja, device, tiket |
| QA (`qa-tester`) | Yanti, Wawan, Iis | opus | data uji, jalankan alur/otomasi/contract, eksploratif, draft bug | kode produk, tiket, push |
| Reviewer (`qa-reviewer`) | Mbah Sarmi | opus | review laporan uji: tiap AC punya bukti | review laporan sendiri, mengubah hasil uji |
| Release (`qa-release`) | Mbak Tutik | haiku | dokumen ke platform, push `qa/<KODE>`, Draft PR otomasi, komentar rekomendasi, rekomendasi rilis | Done, tiket bug/pengembalian tanpa izin, merge |
| PdM (`qa-pdm`) | Bu Sri | sonnet | `/validate-tiket --tim`: AC terukur vs dokumen bisnis | menulis repo/tiket/dokumen |
| Contract Runner (`qa-contract-runner`) | Kang Dede | sonnet | build/deploy cocok, contract siap; Schemathesis + Pact | menulis data ke beta/live |
| PjM (`qa-pjm`) | Pak Slamet | sonnet | tiket terkait, PR/MR, bug terbuka | menulis tiket/PR/dokumen |
| Auditor (`qa-auditor`) | Engkos, Kardi | opus | `/audit-issue`: reproduksi keluhan | menulis repo/tiket |
| Analis (`qa-analis`) | Bu Warsih | opus | `/audit-issue`: lampiran vs hasil nyata | menulis repo/tiket |

Nama berkas agen berawalan `qa-` supaya tidak bentrok dengan agen workflow delivery (`spv`, `qa`, `release`, …) bila keduanya terpasang di komputer yang sama.

## Tiga aturan independensi
Nilai workflow QA ada pada independensinya dari Coder.

1. **Test case disusun tanpa membaca rencana kerja dan diff.** Agen QA hanya membaca tiket, AC, dan contract, sehingga ia tidak mewarisi asumsi Coder. Guard menegakkannya lewat **mode buta**.
2. **Dijalankan di worker terpisah, sebaiknya dengan model berbeda** dari yang menulis kode. Default QA = Opus, Coder workflow Mobile = Sonnet.
3. **Hasil uji workflow delivery tidak dipakai sebagai bukti.** Setiap AC diuji ulang.

Reviewer juga bukan QA yang menguji tiket itu (`qa-check.py report --final` menolak bila nama Reviewer sama dengan Penguji).

## Mode tim
Di Claude Code, tiap agen adalah **teammate** (panel split, label `@<Nama>-<Label><n>`). Syarat: `claude --teammate-mode auto` atau `/config` → Teammate mode → `auto`. Coding agent lain menjalankan `--tim` sebagai solo: peran dijalankan berurutan, dengan test case disusun **sebelum** membuka apa pun dari PR/MR. Model tiap peran diubah di `agents/qa-<peran>.md`.

---
[← kembali ke README](../README.md)
