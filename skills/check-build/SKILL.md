---
name: check-build
description: Skill internal QA - memastikan build atau deploy yang akan diuji tersedia, versinya memuat commit terakhir PR/MR tiket, dan lingkungannya bukan produksi. Kata kunci - cek build, cek deploy, versi uji.
argument-hint: KODE
---
QA tidak membangun sendiri: yang diuji adalah build/deploy yang **diserahkan** workflow delivery. Cara memasang per role: memory project → Lingkungan uji (belum ada → tanya sekali, simpan).

## Langkah
1. Cari build/deploy yang disebut di tiket atau komentar Ready To Review (nomor build, link Firebase/TestFlight, URL deploy preview, tag image).
2. **Cocokkan dengan PR/MR**: commit terakhir PR (`headRefOid` dari `read-ticket`) harus termuat di build:
   | Role | Cara cek |
   |---|---|
   | mobile | catatan rilis Firebase/TestFlight menyebut KODE + commit, atau nomor build ≥ build yang dibuat setelah commit terakhir |
   | web | halaman versi/`/health`/meta build menampilkan commit, atau deploy preview PR yang sama |
   | api | endpoint versi/`/health` menampilkan commit, atau deploy log CI untuk commit itu |
   Commit tidak bisa dipastikan → **berhenti dan tanya** (`rules.md` → Selalu berhenti dan tanya), jangan menebak.
3. **Lingkungan** dev/staging dari memory project. URL mengarah ke produksi → berhenti.
4. Build ada di lebih dari satu lingkungan → pakai yang disebut tiket; tidak disebut → staging.

## Hasil
Baris `Build`, `Lingkungan`, dan tabel "Build dan lingkungan" untuk `qa-validasi.md`, di `${TMPDIR:-/tmp}/qa/<KODE>/validasi/build.md`. Build tidak ada → `Build: -` (keputusan validasi wajib **Belum siap**).
