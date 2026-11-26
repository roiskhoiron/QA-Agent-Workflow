---
name: check-testable
description: Skill internal QA - memeriksa apakah tiap acceptance criteria terukur dan punya hasil yang diharapkan yang bisa diamati. Kata kunci - AC terukur, testable, cek AC.
argument-hint: KODE
---
Nilai tiap AC dari `${TMPDIR:-/tmp}/qa/<KODE>/tiket.md` (hasil `read-ticket`).

## AC terukur bila
- Ada pemicu yang jelas (aksi pengguna, request API, kondisi data).
- Ada hasil yang bisa diamati dan dibandingkan: teks/elemen yang tampil, status/kode respons, data tersimpan, navigasi.
- Angka/batas/format disebut bila relevan ("maksimal 50 karakter", "dalam 3 detik", "format +62").
- Tidak memakai kata kabur tanpa ukuran: "cepat", "mudah", "rapi", "sesuai desain" tanpa link desain.

## Langkah
1. Untuk tiap AC: `Terukur` = `ya`/`tidak` dan **Hasil yang diharapkan** dalam satu kalimat yang bisa diamati. Sumber harapan boleh dari desain/contract bila AC merujuknya.
2. AC tidak terukur → tulis apa yang kurang dan satu usulan rumusan yang terukur (untuk ditanyakan ke reporter).
3. Tiket tanpa AC tertulis → turunkan AC dari deskripsi hanya bila jelas, tandai "diturunkan agen" dan masukkan ke pertanyaan; selain itu semua `tidak`.
4. Cocokkan dengan dokumen bisnis/desain bila ada: AC yang bertentangan dengan desain → catat sebagai pertanyaan, bukan memilih sendiri.

## Hasil
Tabel `AC | Isi | Terukur | Hasil yang diharapkan` (format `qa-validasi.md`) + daftar pertanyaan, di `${TMPDIR:-/tmp}/qa/<KODE>/validasi/ac.md`.
