# Akun uji dan kredensial

Isi kredensial **tidak pernah** ditulis ke dokumen QA, tiket, PR/MR, commit, log laporan, atau file instruksi agen. Di dokumen cukup sebut nama kunci (mis. `qa.user1`).

QA idealnya punya akun uji sendiri, terpisah dari akun developer, supaya data uji tidak tercampur. Belum ada → pakai akun uji project dan catat di laporan bahwa akunnya dipakai bersama.

## Urutan cari
1. `qa.local.properties` di root project
2. `local.properties` → kunci `qa.*`
3. `.env*.local` / `.env` yang di-gitignore

Cek gitignore sebelum memakai file: `git check-ignore -q <file>`. File berisi kredensial yang **tidak** di-ignore → jangan dipakai, berhenti dan tanya (jangan commit, jangan tampilkan isinya).

## Belum ada kredensial
Berhenti dan tanya (`rules.md`) dengan saran:
1. Tambahkan `qa.local.properties` ke `.gitignore` **lebih dulu**.
2. Salin template `$QA_WORKFLOW_DIR/templates/qa.local.properties` ke root project.
3. User mengisi nilainya sendiri.

| Kunci | Isi |
|---|---|
| `qa.env` | `dev` atau `staging` |
| `qa.api.baseUrl` | URL API dev/staging |
| `qa.web.baseUrl` | URL web dev/staging (role `web`) |
| `qa.user1.phone`, `qa.user1.password` | akun uji 1 (`email` boleh menggantikan `phone`) |
| `qa.user2.phone`, `qa.user2.password` | akun uji 2 (tambah `user3...` bila perlu) |

## Pemakaian
- Satu akun, satu agen, satu waktu: kunci `account:qa.userN` (`tools.md` → Akun uji), lepas setelah selesai.
- Kredensial dibaca saat dipakai (mis. env Maestro `-e USER_PHONE=...`, env Playwright), tidak disalin ke file lain yang ter-track.

## Data uji
- Hanya di **dev/staging**; jika `qa.env` atau base URL mengarah ke produksi → berhenti.
- Semua data yang dibuat diawali kode tiket, mis. `PROJ-1234 Alamat Uji`, `proj1234+a@example.com`; data regresi rilis diawali versi (`v1.4.0-…`).
- Catat data yang dibuat di laporan (tanpa password). Hapus data uji bila lingkungan menyediakan caranya, dan catat bila tidak bisa.
