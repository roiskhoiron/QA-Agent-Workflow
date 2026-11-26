---
name: read-ticket
description: Skill internal QA - mengambil tiket, komentar, lampiran, link desain/contract, PR/MR, dan role tiket (mobile/web/api) dari platform tiket. Kata kunci - baca tiket, ambil AC.
argument-hint: KODE
---
Kumpulkan bahan uji satu tiket. Adapter platform: `~/.agent-workflow/qa-repo/skills/_shared/rules.md` → Platform tiket.

## Langkah
1. Baca tiket + semua komentar + lampiran. Catat: judul, deskripsi, **AC** (beri nomor AC1, AC2, … sesuai urutan di tiket; tiket tanpa AC tertulis → catat "AC tidak tertulis"), versi/build yang disebut, reporter, assignee.
2. **Status**: QA bekerja pada tiket **Ready To Review** (atau In Testing). Status lain → lapor dan lewati tiket itu, kecuali user memintanya.
3. **Role tiket** dari label/komponen (pemetaan di memory project → Role tiket; belum ada → tanya sekali, simpan): `mobile`, `web`, `api`, atau gabungan.
4. **PR/MR tiket**: `gh pr list --state all --search <KODE> --json number,url,headRefName,headRefOid,state` / `glab mr list --all --search <KODE>`. Catat nomor, URL, commit terakhir (`headRefOid`). **Jangan** buka diff atau deskripsi rencana kerja di PR; cukup metadata.
5. **Desain** (link Figma/mockup di tiket, atau lokasi dari memory project → Desain) dan **contract** (spec OpenAPI/Pact, memory project → Kontrak API).
6. Komentar laporan uji dari workflow delivery: catat link-nya sebagai petunjuk area, **bukan bukti** (`rules.md` → Tiga aturan independensi).
7. Jejak QA sebelumnya: komentar rekomendasi QA lama atau folder `docs/tickets/<KODE>/` di `upstream/<protected>` → catat sebagai putaran ke-n (dipakai `retest-fix`).

## Hasil
Ringkasan tiket di `${TMPDIR:-/tmp}/qa/<KODE>/tiket.md`: AC bernomor, role, PR/MR + commit, desain, contract, putaran QA.
