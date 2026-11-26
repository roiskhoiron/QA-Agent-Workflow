# Pengembangan qa-agent-workflow

Repo ini adalah **sumber** workflow QA, bukan tempat workflow dijalankan. Pengguna memasangnya lewat `install.sh`. Panduan pemakai ada di `README.md` dan `docs/`.

## Susunan

| Lokasi | Isi |
| --- | --- |
| `skills/<flow>/` | 5 skill flow: `validate-tiket`, `develop-tiket`, `rilis-tiket`, `branch-manager`, `audit-issue` |
| `skills/<internal>/` | 26 skill internal (skill set); peta flow → skill set di `skills/_shared/rules.md` |
| `skills/_shared/` | Aturan bersama: `rules.md`, `tools.md`, `credentials.md`, `report-format.md` |
| `agents/qa-*.md` | 11 peran agen, berawalan `qa-` supaya tidak bentrok dengan workflow delivery |
| `hooks/qa-guard.sh` | Pagar QA, dorman di luar mode QA |
| `bin/qa-check.py` | Pemeriksa dokumen QA (pustaka standar Python saja) |
| `bin/qa-mode.sh` | Penanda mode qa/blind/audit untuk guard |
| `bin/device-*.sh`, `bin/annotate.py` | Disalin dari mobiledev-agent-workflow; kunci dipakai bersama |
| `templates/` | Template dokumen QA (format = `report-format.md`) |

## Aturan saat mengubah repo ini

- Skill internal **tidak saling memanggil**; urutan ada di skill flow. Skill internal baru → tambahkan ke peta di `rules.md` dan ke `docs/alur-kerja.md`.
- Format dokumen di `report-format.md`, template di `templates/`, dan aturan di `bin/qa-check.py` harus berubah bersama. Template mentah harus selalu ditolak `qa-check.py`.
- Jangan melemahkan tiga aturan independensi (mode buta di guard, `Test case disusun tanpa diff: ya`, Reviewer ≠ Penguji) dan larangan Done/merge/push selain `qa/<KODE>`.
- Guard harus tetap dorman tanpa mode QA: sesi Coder workflow delivery di komputer yang sama tidak boleh terblokir.
- Path workflow di skill/agen ditulis `~/.agent-workflow/qa-repo/...` dan `$QA_WORKFLOW_DIR/bin/...`, bukan path workflow Mobile.
- Setiap perintah, skill, atau skrip `bin/` baru wajib disebut di `README.md` atau `docs/`.
- Setelah mengubah apa pun: `bash tests/run.sh` harus `ALL PASS`.
