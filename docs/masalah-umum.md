# Masalah umum

| Gejala | Artinya / yang dilakukan |
| --- | --- |
| "DIBLOKIR oleh qa-guard: edit '...' dilarang: QA tidak menulis kode produk" | Benar sesuai aturan. Bila berkas itu memang kode otomasi uji di lokasi tak biasa, tambahkan polanya ke `~/.agent-workflow/qa-test-paths.txt` |
| "... dilarang selama mode buta" | Agen mencoba membaca diff saat menyusun/menjalankan uji. Pakai `--name-only` bila hanya butuh daftar file |
| `install.sh: ... sudah ada dan milik workflow lain` | Workflow delivery memakai nama perintah yang sama. Pasang dengan `--scope project` (disarankan) atau `--force` |
| `qa-check.py` exit 1 | Dokumen belum memenuhi aturan; tiap baris menyebut masalahnya (mis. AC tanpa TC normal, TC gagal tanpa draft bug). Perbaiki lalu jalankan lagi |
| Rekomendasi **Tertahan** | Ada AC yang tidak bisa diuji (device/akun/data tidak ada, AC kabur); alasannya tertulis per TC |
| Validasi **Belum siap** karena build | Build belum ada atau tidak memuat commit terakhir PR/MR. Minta workflow delivery membuat build, lalu ulangi |
| `device-pick.sh` exit 1 | Semua device sedang dipakai (juga oleh workflow delivery); agen menunggu lalu mencoba lagi |
| Teammate tidak muncul / agen bertanya buka ulang sesi | Mode tim butuh `claude --teammate-mode auto` atau `/config` → Teammate mode → `auto` |

---
[← kembali ke README](../README.md)
