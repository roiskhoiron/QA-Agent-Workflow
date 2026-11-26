---
name: post-decision
description: Skill internal QA - menulis komentar keputusan kelayakan uji di tiket (Siap diuji / Siap dengan catatan / Belum siap) dan menggeser tiket ke In Testing bila board punya kolom itu. Tidak pernah mengembalikan tiket tanpa izin. Kata kunci - komentar keputusan, kelayakan uji.
argument-hint: KODE
---
Gaya komentar: `~/.agent-workflow/qa-repo/skills/_shared/report-format.md` → Komentar tiket.

## Langkah
1. Komentar tiket (adapter platform): baris pertama link laporan kelayakan, lalu keputusan dalam bahasa awam + apa yang dibutuhkan dari reporter/developer (bila ada).
2. **Siap diuji / Siap dengan catatan** → pindah ke **In Testing** bila id/label-nya ada di daftar status project (`setup-board`); tidak ada → tiket tetap di Ready To Review.
3. **Belum siap** → tiket tetap di kolomnya. Mengembalikan ke In Progress **hanya** bila user menjawab "ya" untuk tiket itu (`rules.md` → Selalu berhenti dan tanya).
4. Tanpa platform → tulis komentar dan saran status di chat.

## Hasil
Link komentar dan status akhir tiket.
