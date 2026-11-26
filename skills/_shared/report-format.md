# Format dokumen QA

Semua dokumen QA ditulis sebagai Markdown dengan format tetap, supaya bisa diperiksa mesin oleh `$QA_WORKFLOW_DIR/bin/qa-check.py` sebelum dikirim. Template siap isi ada di `~/.agent-workflow/qa-repo/templates/`. Lokasi default di repo (platform dokumentasi `docs/`):

| Dokumen | Lokasi default | Template | Pemeriksa |
|---|---|---|---|
| Laporan kelayakan uji | `docs/tickets/<KODE>/qa-validasi.md` | `qa-validasi.md` | `qa-check.py validasi <file>` |
| Test case dan laporan uji | `docs/tickets/<KODE>/qa.md` + `docs/tickets/<KODE>/img/` | `qa.md` | `qa-check.py report <file>` |
| Draft bug | `docs/tickets/<KODE>/bug-<nomor>.md` | `bug.md` | `qa-check.py bug <file>` |
| Kumpulan test case regresi | `docs/qa/regresi/<area>.md` | `regresi.md` | — |
| Rekomendasi rilis | `docs/rilis/vX.Y.Z-qa.md` | `signoff.md` | `qa-check.py signoff <file>` |
| Laporan audit | `docs/qa/audit/<slug>.md` | `audit.md` | — |

Platform dokumentasi lain (Claude Docs, Confluence, Notion; lihat `setup-docs`): berkas Markdown tetap ditulis dulu di folder kerja `${TMPDIR:-/tmp}/qa/<KODE>/` dan diperiksa `qa-check.py`, lalu isinya dipublikasikan ke platform itu. Link hasil publikasi = link laporan.

`qa-check.py ticket docs/tickets/<KODE>` memeriksa semua dokumen tiket sekaligus. Exit 0 = lolos, 1 = ada pelanggaran (dicetak per baris), 2 = salah pakai. Peringatan (`peringatan:`) tidak menggagalkan.

Gaya: Bahasa Indonesia, singkat padat, ramah pemula. Tabel lebih dulu daripada paragraf. Tanpa kredensial (sebut nama kunci saja, mis. `qa.user1`).

## Kepala dokumen
Setiap dokumen dibuka dengan judul `#` lalu daftar `- Kunci: nilai`. Kunci yang diperiksa disebut per dokumen di bawah. Nilai kosong atau `-` dianggap tidak ada.

## Laporan kelayakan uji (`qa-validasi.md`)
Kepala: `Tiket`, `Role` (`mobile`/`web`/`api`), `Build`, `PR/MR`, `Validator`.

| Bagian | Isi | Aturan mesin |
|---|---|---|
| `## Keputusan` | `**Keputusan: Siap diuji**` / `Siap dengan catatan` / `Belum siap` + alasan | wajib, salah satu dari tiga |
| `## Acceptance criteria` | tabel `AC \| Isi \| Terukur \| Hasil yang diharapkan` | ≥1 baris; `Terukur` = `ya`/`tidak`; ada `tidak` → bukan **Siap diuji** |
| `## Build dan lingkungan` | build/deploy, versinya, kecocokan dengan PR/MR, lingkungan | `Build` kosong → wajib **Belum siap** |
| `## Data uji` | akun (nama kunci) dan data yang dibutuhkan; tersedia atau tidak | |
| `## Tiket terkait` | tiket/PR/bug terbuka yang menyentuh area sama | |
| `## Catatan` | pertanyaan untuk reporter, hal yang belum jelas | |

## Laporan uji (`qa.md`)
Kepala: `Tiket`, `Role`, `Build`, `Lingkungan`, `Penguji`, dan `Test case disusun tanpa diff: ya` (wajib `ya`).

| Bagian | Isi | Aturan mesin |
|---|---|---|
| `## Rekomendasi` | `**Rekomendasi: Lolos**` / `Gagal` / `Tertahan` + alasan singkat | harus sama dengan hasil turunan dari AC (di bawah) |
| `## Acceptance criteria` | tabel `AC \| Isi \| Hasil` | hasil tiap AC harus sama dengan hasil turunan dari TC-nya |
| `## Test case` | tabel `TC \| AC \| Jenis \| Langkah \| Harapan \| Hasil \| Bukti` | lihat aturan TC |
| `## Uji eksploratif` | baris `Batas waktu: <n> menit`, lalu tabel `Temuan \| Langkah \| Bukti \| Bug` (boleh "Tidak ada temuan") | `Batas waktu` wajib |
| `## Regresi area terdampak` | tabel `Flow \| Hasil \| Bukti`, atau "Tidak ada flow regresi untuk area ini" | |
| `## Bug` | tabel `Bug \| TC \| Keparahan \| Judul`, atau "Tidak ada" | Keparahan `S1`–`S4` |
| `## Review` | `Reviewer: <Nama> (<Label>) — Lolos review` atau `— Perlu revisi` + catatan | wajib `Lolos review` untuk `report --final` |

**Aturan TC:**
- `Jenis` = `normal` (alur yang diharapkan), `batas` (nilai batas), `gagal` (alur gagal/galat), atau `regresi`. Tiap AC punya minimal satu TC `normal`. Tanpa TC `batas` atau `gagal` sama sekali → peringatan.
- `Hasil` = `Lulus`, `Gagal`, atau `Tertahan`.
- `Lulus`/`Gagal` wajib punya `Bukti` (path screenshot/log relatif terhadap dokumen, mis. `img/TC1-01.png`; path yang disebut harus ada).
- `Gagal` wajib menyebut draft bug (`bug-1`) di kolom `Bukti`, bug itu ada di tabel `## Bug`, dan berkasnya `bug-1.md` ada di folder yang sama.
- `Tertahan` wajib menulis `alasan: ...` di kolom `Bukti`.

**Hasil turunan:**
- AC = **Gagal** bila ada TC-nya Gagal; **Lulus** bila tidak ada yang Gagal dan minimal satu Lulus; selain itu **Tertahan**.
- Rekomendasi = **Gagal** bila ada AC Gagal; **Lolos** bila semua AC Lulus; selain itu **Tertahan** (ada AC yang tidak bisa diuji, alasannya tertulis).
- Ada bug **S1** atau **S2** (termasuk dari uji eksploratif) → Rekomendasi tidak boleh **Lolos**.

## Draft bug (`bug-<nomor>.md`)
Kepala: `Tiket`, `TC` (ID TC, atau `eksploratif`), `Keparahan` (`S1`–`S4`, lihat `rules.md`), `Build`, `Lingkungan`, `Device/browser`.

Bagian wajib dan tidak kosong: `## Langkah` (daftar bernomor), `## Hasil` (yang terjadi), `## Harapan` (yang seharusnya, dari AC/contract/desain), `## Bukti` (screenshot/log/video). Opsional: `## Catatan` (frekuensi, dugaan area). Judul: `# Bug <KODE>-<nomor> — <ringkasan>`.

Draft bug **tidak** otomatis jadi tiket. Release menanyakan izin per bug (`rules.md` → Selalu berhenti dan tanya).

## Rekomendasi rilis (`vX.Y.Z-qa.md`)
Kepala: `Versi`, `Build`, `Tiket rilis`.

| Bagian | Isi | Aturan mesin |
|---|---|---|
| `## Rekomendasi` | `**Rekomendasi rilis: Layak rilis**` / `Layak dengan risiko` / `Tidak layak rilis` | wajib |
| `## Tiket dalam rilis` | tabel `KODE \| Rekomendasi QA \| Bug terbuka` | ada `Gagal` → bukan **Layak rilis** |
| `## Regresi penuh` | tabel `Flow \| Hasil \| Bukti` | kosong, `Gagal`, atau `Tertahan` → bukan **Layak rilis** |
| `## Smoke live` | tabel `Flow \| Hasil \| Bukti`, atau "Belum dijalankan" | kosong atau `Gagal` → bukan **Layak rilis** |
| `## Risiko tersisa` | daftar risiko (atau "Tidak ada") | wajib tidak kosong |

## Laporan audit (`/audit-issue`)
1. **Ringkasan untuk awam** (3–5 kalimat).
2. **Keluhan asli** + daftar lampiran (terbaca / gagal + alasan).
3. **Temuan per pertanyaan**, tiap klaim dengan bukti (screenshot bertanda, log, langkah).
4. **Lampiran vs hasil nyata**: tabel `Lampiran | Hasil nyata | Beda?`.
5. **Bisa direproduksi?** **Ya** / **Tidak** / **Kadang** + tingkat keyakinan (**pasti** / **kuat** / **dugaan**).
6. **Saran tiket** (tidak dibuat): judul, langkah, harapan, keparahan.
7. **Cara audit**: build, device/browser, akun (nama kunci), hal yang tidak bisa diperiksa.

## Screenshot bertanda
- Kotak merah + label dari koordinat elemen (`maestro hierarchy`, Playwright `boundingBox()`), bukan tebakan; digambar dengan `annotate.py` (`tools.md`).
- Label = kode AC/TC + penjelasan singkat, mis. `AC2 pesan galat tampil`.
- Nama file urut: `TC1-01.png`, `TC1-02.png`, di `img/` sebelah dokumen.

## Komentar tiket
Ditulis seperti rekan satu tim yang sopan, dipahami pembaca awam (PM, bisnis), bukan hanya developer.
- Orang pertama **aku**, hangat dan to the point; paling banyak satu emoji.
- Bahasa awam: dampak bagi pengguna, bukan detail teknis. Istilah teknis (AC, TC, endpoint) diberi arti singkat bila terpaksa.
- Sapaan: pakai sapaan yang sudah dipakai tim untuk orang itu; belum ada contoh → **Kak <nama depan>**. Jangan menebak mas/mba dari nama.
- Baris pertama **selalu** memuat link laporan.
- Kabar kurang enak disampaikan jujur tapi lembut, dengan alasan dan jalan keluar.
- Rekomendasi **bukan** keputusan: tutup dengan menyebut QA manusia yang memutuskan Done.

**Contoh — kelayakan uji, belum siap**
```
Halo Kak Rina, aku sudah cek apakah tiket ini siap diuji ya. Catatannya di sini: <link>
Untuk sementara aku belum bisa mulai, karena versi aplikasi yang memuat perubahan ini belum tersedia di Firebase. Begitu versinya ada, kabari aku dan aku lanjut uji. Terima kasih 🙏
```

**Contoh — rekomendasi lolos**
```
Halo Kak Sari, pengujian tiket ini sudah selesai. Laporan lengkapnya di sini: <link>
Semua yang diminta di tiket sudah aku coba di versi <build> dan hasilnya sesuai. Aku juga mencoba beberapa cara pakai di luar daftar, tidak ada masalah yang menghalangi.
Rekomendasiku: lolos. Keputusan Done tetap di Kak <QA manusia> ya.
```

**Contoh — rekomendasi gagal**
```
Halo Mas Dimas, hasil pengujianku ada di sini: <link>
Ada satu hal yang belum sesuai: setelah ubah alamat lalu tekan Simpan, alamat lama masih tampil. Langkah dan buktinya sudah aku tulis sebagai draft laporan bug.
Rekomendasiku: belum lolos. Aku tunggu keputusan Kak <QA manusia> apakah tiket dikembalikan ke tim pengembang.
```

Kirim lewat adapter platform (`rules.md` → Platform tiket). Tanpa platform → tulis komentarnya di chat untuk user.
