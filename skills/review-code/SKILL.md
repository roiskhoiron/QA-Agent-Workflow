---
name: review-code
description: Skill internal QA - di workflow QA, review-code me-review laporan uji, bukan kode - setiap acceptance criteria harus punya test case dan bukti yang meyakinkan, dijalankan oleh agen yang bukan penguji. Kata kunci - review laporan uji, cek bukti.
argument-hint: KODE
---
Dijalankan **Reviewer** (bukan QA yang menguji). Mode solo: SPV sendiri, dan laporan mencatat review bukan independen.

## Langkah
1. Mesin dulu: `python3 "$QA_WORKFLOW_DIR/bin/qa-check.py" ticket ${TMPDIR:-/tmp}/qa/<KODE>`. Tiap pelanggaran = temuan **wajib**.
2. Lalu manusiawi, per AC:
   | Cek | Pertanyaan |
   |---|---|
   | Cakupan | TC benar-benar menguji isi AC, bukan versi yang dipermudah? Batas dan galat yang disebut AC/contract ada TC-nya? |
   | Bukti | Screenshot/log menunjukkan harapan TC (layar dan build yang benar, kotak merah di elemen yang tepat)? |
   | Harapan | Harapan TC berasal dari AC/contract/desain, bukan disesuaikan dengan perilaku app? |
   | Ulang | Langkah cukup jelas untuk diulang orang lain? |
   | Bug | Keparahan wajar? Langkah, hasil, harapan lengkap? |
   | Eksploratif | Batas waktu ditulis? Area berisiko di sekitar tiket tersentuh? |
   | Independensi | Ada tanda TC disusun dari diff/rencana kerja, atau bukti diambil dari laporan workflow delivery? |
3. Temuan → `${TMPDIR:-/tmp}/qa/<KODE>/review.md`, tabel `Lokasi | Masalah | Saran | Tingkat (wajib/saran)`.
4. Isi `## Review` di `qa.md`: `Reviewer: <Nama> (<Label>) — Lolos review` bila tidak ada temuan wajib, selain itu `— Perlu revisi` + ringkasan. Lolos → `qa-check.py report --final` harus lolos.

## Hasil
`review.md` + bagian Review di `qa.md`. Perlu revisi → kembali ke QA lewat SPV; lebih dari 2 putaran → SPV meminta Planner merevisi test case.
