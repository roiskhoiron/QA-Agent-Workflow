# Rancangan dan keputusan sementara

Sumber: [Draft: Agent Workflow QA](https://claude.ai/code/artifact/1c154666-5ffc-4627-ad75-f47fbfdfe81b). Ringkasan yang diterapkan di repo ini:

| Bagian rancangan | Diterapkan di |
| --- | --- |
| Ruas Ready To Review → rekomendasi Done | `skills/_shared/rules.md` → Peran workflow ini; guard memblokir Done |
| Empat skill flow + `/audit-issue` | `skills/<flow>/SKILL.md` |
| Skill set per flow (26 skill internal) | `skills/<nama>/SKILL.md`, peta di `rules.md` → Skill flow dan skill set |
| Tiga aturan independensi | `rules.md`; mode buta di `qa-guard.sh`; deklarasi `Test case disusun tanpa diff: ya` dan Reviewer ≠ Penguji di `qa-check.py` |
| `/develop-tiket` versi QA, tujuh langkah | `skills/develop-tiket/SKILL.md` |
| Tidak membuat tiket bug / mengembalikan tiket tanpa izin | `post-verdict`, `rules.md` → Selalu berhenti dan tanya |
| Platform dokumentasi `docs/` + lokasi dokumen | `setup-docs`, `write-report`, `report-format.md` |
| Worktree per tiket hanya untuk kode otomasi uji | `rules.md` → Worktree QA; guard membatasi edit dan push `qa/<KODE>` |

Tambahan dari rancangan (keputusan Claude saat implementasi, boleh dikoreksi):

| Keputusan | Alasan |
| --- | --- |
| Pemeriksa dokumen `qa-check.py` (pola skrip penjaga dari sdd-agent-workflow) | Aturan "setiap AC punya bukti" dan "rekomendasi sesuai hasil" tidak bergantung pada ingatan agen |
| Guard dorman di luar mode QA | Workflow delivery dan QA bisa terpasang di komputer yang sama tanpa saling memblokir |
| Agen berawalan `qa-`, guard `qa-guard.sh`, jangkar `~/.agent-workflow/qa-repo` | Berdampingan dengan workflow delivery |
| State `~/.agent-workflow/` dipakai bersama | Device dan akun uji fisiknya sama; daftar status tiket per project sama |
| Rekomendasi punya nilai ketiga **Tertahan** | AC yang tidak bisa diuji tidak boleh dilaporkan sebagai lolos maupun gagal |

## Keputusan sementara
Pertanyaan yang masih terbuka di rancangan, dengan nilai yang dipakai sampai diputuskan:

| Pertanyaan terbuka | Nilai sementara | Diubah di |
| --- | --- | --- |
| Siapa QA manusia yang memutuskan Done? | Ditanya per project oleh `/setup-board`, disimpan di memory project | memory project |
| Alat pengelola test case, atau cukup `docs/qa/`? | `docs/qa/` (Markdown di repo); platform lain lewat `/setup-docs` | memory project → Platform dokumentasi |
| Device dan akun uji QA terpisah dari developer? | Device dipakai bersama lewat kunci; akun uji QA disarankan terpisah, bila belum ada dipakai bersama dan dicatat di laporan | `credentials.md` |
| Skala keparahan bug? | S1 Kritis / S2 Tinggi / S3 Sedang / S4 Rendah; S1–S2 menolak rekomendasi Lolos | `rules.md` → Tingkat keparahan bug |
| Model agen QA agar beda dari Coder? | QA dan Reviewer Opus (Coder Mobile = Sonnet), Planner Fable, Release Haiku | `agents/qa-*.md` |

---
[← kembali ke README](../README.md)
