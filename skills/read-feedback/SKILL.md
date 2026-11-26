---
name: read-feedback
description: Skill internal QA - membaca keadaan tiket setelah rekomendasi QA - komentar developer/QA manusia terbaru, build baru, tiket bug terkait - untuk menentukan uji ulang, regresi, atau cukup lapor. Kata kunci - baca feedback, status setelah perbaikan.
argument-hint: KODE
---
## Langkah
1. Baca tiket + komentar (adapter platform), status, dan rekomendasi QA terakhir (komentar agen terbaru dengan link laporan uji).
2. **Feedback** = komentar manusia setelah rekomendasi QA terakhir (developer, PM, QA manusia), plus status tiket bug yang dibuat dari draft bug.
3. Golongkan:
   | Keadaan | Tindakan di `/rilis-tiket` |
   |---|---|
   | Developer menyatakan sudah diperbaiki, tiket kembali Ready To Review, ada build baru | `retest-fix` |
   | QA manusia minta uji ulang/tambahan di build lain | `retest-fix` dengan build itu |
   | Tiket Done oleh QA manusia | lapor saja (regresi dilakukan per rilis) |
   | Tidak ada feedback baru | lapor saja |
   | Feedback saling bertentangan, atau developer menolak bug | tanya user, jangan menebak |
4. Developer menolak bug ("bukan bug", "sesuai desain") → catat argumennya dan rujukannya; keputusan ke user/QA manusia.

## Hasil
Ringkasan per tiket: feedback terakhir (siapa, kapan, isi), build baru (bila ada), tindakan yang disarankan.
