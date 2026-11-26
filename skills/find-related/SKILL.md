---
name: find-related
description: Skill internal QA - mencari tiket terkait atau bertabrakan, tiket bug terbuka di area yang sama, dan PR/MR lain yang bisa memengaruhi hasil uji. Hanya-baca. Kata kunci - tiket terkait, bug terbuka, ketergantungan uji.
argument-hint: KODE
---
Hanya-baca: tidak membuat link antar tiket, tidak mengomentari tiket lain.

## Langkah
1. Tiket yang di-link ke tiket ini (blocks/is blocked by/relates) beserta statusnya.
2. Tiket yang tidak di-link tapi menyentuh komponen/label/layar/endpoint yang sama, status selain Done (Jira: JQL `text ~ "<kata kunci>"`; GitHub/GitLab: `issue list --search`).
3. **Tiket bug terbuka** di area yang sama: bisa membuat TC gagal bukan karena tiket ini. Catat supaya QA tidak salah menyalahkan.
4. PR/MR terbuka lain yang menyentuh area sama (`gh pr list --search`, judul/label saja, tanpa diff).
5. Tiket lain di build yang sama yang juga menunggu uji (kesempatan uji bersama di `--batch`).

## Hasil
Tabel `Tiket/PR | Status | Dampak ke uji` dan saran urutan uji, di `${TMPDIR:-/tmp}/qa/<KODE>/validasi/related.md`. Tidak ada → "Tidak ada".
