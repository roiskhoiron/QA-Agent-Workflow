# qa-agent-workflow

Tim agen AI coding (Claude Code, Codex, Gemini CLI, Cursor, OpenCode) yang **menguji hasil kerja role lain secara independen**: dari tiket **Ready To Review** sampai **rekomendasi Done**. Melayani tiket Mobile, Frontend web, dan Backend.

Workflow ini memakai kerangka yang sama dengan workflow delivery ([mobiledev-agent-workflow](https://github.com/roiskhoiron/mobiledev-agent-workflow)): perintah, mode kerja Diawasi/Otonom, flag `--solo`/`--tim`/`--batch`, platform tiket per project, dan pagar keamanan. Bedanya ada di ruas kanban dan tujuannya:

| | Workflow delivery (mis. Mobile) | Workflow QA ini |
| --- | --- | --- |
| Ruas kanban | Todo → Ready To Review | Ready To Review → rekomendasi Done |
| Yang dihasilkan | Kode dan PR/MR | Laporan uji, rekomendasi, draft bug |
| Menulis kode produk | Ya | **Tidak pernah**, hanya kode otomasi uji |
| Sumber kebenaran | Rencana kerja | Acceptance criteria (AC) dan contract |
| Keputusan akhir | Merge oleh manusia | **Done oleh QA manusia** |

Rancangan lengkap: [Draft: Agent Workflow QA](https://claude.ai/code/artifact/1c154666-5ffc-4627-ad75-f47fbfdfe81b) · ringkasan + keputusan sementara: [docs/rancangan.md](docs/rancangan.md).

Status: **v0.1, kerangka awal**. Siap dicoba di tiket nyata; keputusan yang masih terbuka di rancangan memakai nilai sementara (lihat [rancangan](docs/rancangan.md#keputusan-sementara)).

## Daftar isi
1. [Mulai cepat](#mulai-cepat) dan [istilah](#istilah) (di halaman ini)
2. [Alur kerja](docs/alur-kerja.md): lima perintah, skill set tiap perintah, papan kanban
3. [Tim agen](docs/tim-agen.md): peran, nama, model, aturan independensi
4. [Pagar keamanan](docs/pagar-keamanan.md): yang diblokir `qa-guard.sh`, kapan agen berhenti dan bertanya
5. [Alat](docs/alat.md): skrip `bin/`, alat uji per role, pemeriksa dokumen
6. [Pasang](docs/pasang.md): installer, scope, berdampingan dengan workflow delivery
7. [Masalah umum](docs/masalah-umum.md)
8. [Rancangan dan keputusan sementara](docs/rancangan.md)

## Mulai cepat

```bash
git clone https://github.com/roiskhoiron/QA-Agent-Workflow ~/qa-agent-workflow
bash ~/qa-agent-workflow/install.sh                 # menu: pilih coding agent + scope
bash ~/qa-agent-workflow/tests/run.sh               # harus "ALL PASS"
```

Lalu di coding agent-mu (di Claude Code: `/nama-perintah`):

| Perintah | Gunanya di QA |
| --- | --- |
| `/validate-tiket KODE... [--solo\|--tim]` | Cek tiket siap diuji: AC bisa diuji, build/deploy tersedia dan cocok dengan PR/MR, data uji ada |
| `/develop-tiket KODE... [--solo\|--tim] [--batch\|--separate] [--uat]` | Uji tiket: susun test case dari AC (tanpa membaca diff), jalankan, uji eksploratif, review laporan, rekomendasi + draft bug |
| `/rilis-tiket KODE...` | Uji ulang setelah perbaikan dan rekomendasi baru |
| `/branch-manager --rilis KODE [--smoke]` | Regresi penuh, smoke live, dan rekomendasi rilis beserta risiko yang tersisa |
| `/audit-issue "teks" [--solo\|--tim] [lampiran...]` | Telusuri keluhan dari lapangan: bisa direproduksi atau tidak, **hanya-baca** |

Contoh:
```text
/validate-tiket PROJ-1234
/develop-tiket PROJ-1234 PROJ-1240 --tim
/rilis-tiket PROJ-1234
/branch-manager --rilis PROJ-1400
/audit-issue "keranjang kosong setelah login ulang di Safari" --solo
```

Saat pertama dipakai di sebuah project, agen **bertanya** platform tiket (Jira / GitHub Projects / GitLab Issue Board / tanpa platform), platform dokumentasi (default folder `docs/` di repo), dan siapa **QA manusia** yang memutuskan Done.

## Istilah

| Istilah | Penjelasan sederhana |
| --- | --- |
| **AC / TC** | Acceptance criteria tiket / test case. Hasil TC: **Lulus**, **Gagal**, atau **Tertahan** (tidak bisa diuji, dengan alasan) |
| **Rekomendasi** | Hasil akhir QA per tiket: **Lolos**, **Gagal**, atau **Tertahan**. Bukan keputusan; Done diputuskan QA manusia |
| **Draft bug** | Laporan bug lengkap (langkah, hasil, harapan, bukti, keparahan S1–S4). Jadi tiket hanya setelah kamu izinkan |
| **Skill flow / skill set** | Lima perintah di atas = skill flow. Masing-masing menjalankan beberapa skill internal berurutan (mis. `/design-tests`, `/run-flow`) |
| **Mode QA / mode buta / mode audit** | Penanda sesi untuk guard: pagar QA aktif / perintah yang membuka diff diblokir / hanya-baca |
| **Worktree QA** | Salinan kerja repo per tiket (`<repo>-qa-<nomor>`, branch `qa/<KODE>`) khusus kode otomasi uji dan dokumen QA |
| **Role tiket** | `mobile` (diuji di device), `web` (browser), `api` (server) |
| **SPV** | Agen "mandor": gerbang uji, bagi tugas, putuskan rekomendasi |

## Isi repo

| Folder | Isi |
| --- | --- |
| `skills/<perintah>/SKILL.md` | 5 skill flow + 26 skill internal (skill set) |
| `skills/_shared/` | Aturan bersama: `rules.md`, `tools.md`, `credentials.md`, `report-format.md` |
| `agents/` | 11 peran agen (`qa-*.md`: model, tugas, larangan) |
| `bin/` | `qa-check.py` (pemeriksa dokumen), `qa-mode.sh`, kunci device/akun, `annotate.py` |
| `hooks/qa-guard.sh` | Pagar keamanan QA |
| `templates/` | Template dokumen QA, instruksi agen, `qa.local.properties` |
| `tests/` | Tes: `bash tests/run.sh` |
| `docs/` | Panduan lengkap |

## Merawat dokumen ini
README + `docs/` adalah pintu masuk untuk pemula. Setiap perubahan workflow wajib memperbarui README atau halaman `docs/` yang sesuai di commit yang sama. `tests/readme_test.sh` gagal bila ada perintah, skill, atau skrip `bin/` yang belum disebut. Detail teknis tetap di `skills/` dan `agents/`.
