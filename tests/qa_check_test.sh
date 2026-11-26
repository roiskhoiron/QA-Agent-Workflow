#!/usr/bin/env bash
# bin/qa-check.py: aturan dokumen QA (report-format.md) ditegakkan mesin.
source "$(dirname "$0")/lib.sh"
REPO="$(cd "$(dirname "$0")/.." && pwd -P)"
C=(python3 "$REPO/bin/qa-check.py")
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
out() { "${C[@]}" "$@" 2>&1; }
has() { grep -qF -- "$2" <<< "$1" && echo yes || echo no; }

# ---------- laporan uji ----------
K="$T/PROJ-1"; mkdir -p "$K/img"; touch "$K/img/TC1-01.png" "$K/img/TC2-01.png"
report() { # rec ac1 ac2 tc2-result tc2-proof [extra-bug-row]
cat > "$K/qa.md" <<EOF
# Uji PROJ-1 — ubah alamat

- Tiket: PROJ-1
- Role: mobile
- Build: 1234 (staging)
- Lingkungan: staging
- Penguji: Yanti (QA1)
- Test case disusun tanpa diff: ya

## Rekomendasi
**Rekomendasi: $1**

## Acceptance criteria
| AC | Isi | Hasil |
|---|---|---|
| AC1 | simpan alamat | $2 |
| AC2 | pesan galat | $3 |

## Test case
| TC | AC | Jenis | Langkah | Harapan | Hasil | Bukti |
|---|---|---|---|---|---|---|
| TC1 | AC1 | normal | isi, simpan | tersimpan | Lulus | img/TC1-01.png |
| TC2 | AC2 | normal | nomor salah | pesan galat | $4 | $5 |
| TC3 | AC2 | batas | 50 karakter | diterima | Lulus | img/TC2-01.png |

## Uji eksploratif
Batas waktu: 30 menit

Tidak ada temuan.

## Bug
| Bug | TC | Keparahan | Judul |
|---|---|---|---|
$6

## Review
Reviewer: Mbah Sarmi (Reviewer1) — Lolos review
EOF
}
bugfile() { # n severity
cat > "$K/bug-$1.md" <<EOF
# Bug PROJ-1-$1 — pesan galat tidak muncul

- Tiket: PROJ-1
- TC: TC2
- Keparahan: $2
- Build: 1234
- Lingkungan: staging
- Device/browser: emulator Android 15

## Langkah
1. Buka Alamat
2. Isi nomor salah

## Hasil
Tidak ada pesan.

## Harapan
Pesan galat (AC2).

## Bukti
- img/TC2-01.png
EOF
}

report Lolos Lulus Lulus Lulus img/TC2-01.png ""
assert_exit 0 "report: semua lulus, rekomendasi Lolos" -- "${C[@]}" report "$K/qa.md"
assert_exit 0 "report --final dengan review lolos" -- "${C[@]}" report "$K/qa.md" --final

report Lolos Lulus Gagal Gagal "img/TC2-01.png, bug-1" "| bug-1 | TC2 | S2 | pesan galat |"
bugfile 1 S2
o=$(out report "$K/qa.md")
assert_eq yes "$(has "$o" "seharusnya 'Gagal' menurut hasil AC")" "report: Lolos padahal AC gagal → ditolak"
assert_eq yes "$(has "$o" "rekomendasi tidak boleh Lolos")" "report: bug S2 menolak Lolos"

report Gagal Lulus Gagal Gagal "img/TC2-01.png, bug-1" "| bug-1 | TC2 | S2 | pesan galat |"
assert_exit 0 "report: gagal + bug lengkap → lolos pemeriksa" -- "${C[@]}" report "$K/qa.md"
rm "$K/bug-1.md"
assert_eq yes "$(has "$(out report "$K/qa.md")" "bug-1.md tidak ditemukan")" "report: berkas bug wajib ada"

report Gagal Lulus Gagal Gagal "img/TC2-01.png" ""
assert_eq yes "$(has "$(out report "$K/qa.md")" "wajib menyebut draft bug")" "report: TC gagal tanpa bug ditolak"

report Lolos Lulus Lulus Lulus "" ""
assert_eq yes "$(has "$(out report "$K/qa.md")" "Lulus wajib punya bukti")" "report: lulus tanpa bukti ditolak"

report Lolos Lulus Lulus Lulus img/TC9-01.png ""
assert_eq yes "$(has "$(out report "$K/qa.md")" "berkas bukti tidak ditemukan: img/TC9-01.png")" "report: path bukti harus ada"

report Tertahan Lulus Tertahan Tertahan "device fisik tidak ada" ""
sed -i 's/| TC3 | AC2 | batas | 50 karakter | diterima | Lulus | img\/TC2-01.png |/| TC3 | AC2 | batas | 50 karakter | diterima | Tertahan | alasan: sama |/' "$K/qa.md"
assert_eq yes "$(has "$(out report "$K/qa.md")" "Tertahan wajib menulis 'alasan: ...'")" "report: tertahan tanpa alasan ditolak"
report Tertahan Lulus Tertahan Tertahan "alasan: device fisik tidak ada" ""
sed -i 's/| TC3 | AC2 | batas | 50 karakter | diterima | Lulus | img\/TC2-01.png |/| TC3 | AC2 | batas | 50 karakter | diterima | Tertahan | alasan: sama |/' "$K/qa.md"
assert_exit 0 "report: AC tak teruji → rekomendasi Tertahan diterima" -- "${C[@]}" report "$K/qa.md"

report Lolos Lulus Lulus Lulus img/TC2-01.png ""
sed -i 's/| TC1 | AC1 | normal |/| TC1 | AC1 | batas |/' "$K/qa.md"
assert_eq yes "$(has "$(out report "$K/qa.md")" "AC1: tidak punya test case berjenis normal")" "report: tiap AC wajib TC normal"

report Lolos Lulus Lulus Lulus img/TC2-01.png ""
sed -i 's/Test case disusun tanpa diff: ya/Test case disusun tanpa diff: tidak/' "$K/qa.md"
assert_eq yes "$(has "$(out report "$K/qa.md")" "aturan independensi")" "report: deklarasi independensi wajib"

report Lolos Lulus Lulus Lulus img/TC2-01.png ""
sed -i 's/Batas waktu: 30 menit/Sebentar saja/' "$K/qa.md"
assert_eq yes "$(has "$(out report "$K/qa.md")" "Batas waktu")" "report: uji eksploratif wajib batas waktu"

report Lolos Lulus Lulus Lulus img/TC2-01.png ""
sed -i 's/— Lolos review/— Perlu revisi/' "$K/qa.md"
assert_exit 0 "report tanpa --final tidak menuntut review" -- "${C[@]}" report "$K/qa.md"
assert_eq yes "$(has "$(out report "$K/qa.md" --final)" "Lolos review")" "report --final menuntut Lolos review"
sed -i 's/Reviewer: Mbah Sarmi (Reviewer1) — Perlu revisi/Reviewer: Yanti (QA1) — Lolos review/' "$K/qa.md"
assert_eq yes "$(has "$(out report "$K/qa.md" --final)" "tidak boleh sama dengan Penguji")" "report --final: reviewer ≠ penguji"

report Lolos Lulus Lulus Lulus img/TC2-01.png ""
sed -i 's/- Build: 1234 (staging)/- Build: <nomor build>/' "$K/qa.md"
assert_eq yes "$(has "$(out report "$K/qa.md")" "placeholder")" "report: placeholder template ditolak"

# ---------- draft bug ----------
bugfile 2 S3
assert_exit 0 "bug lengkap lolos" -- "${C[@]}" bug "$K/bug-2.md"
bugfile 3 S9
assert_eq yes "$(has "$(out bug "$K/bug-3.md")" "Keparahan harus S1-S4")" "bug: keparahan S1-S4"
bugfile 4 S2; sed -i '/^## Harapan/,/^## Bukti/{/^## Bukti/!d}' "$K/bug-4.md"
assert_eq yes "$(has "$(out bug "$K/bug-4.md")" "'## Harapan' tidak ada")" "bug: harapan wajib"
bugfile 5 S2; sed -i 's/^1\. Buka Alamat/Buka Alamat/; /^2\. /d' "$K/bug-5.md"
assert_eq yes "$(has "$(out bug "$K/bug-5.md")" "daftar bernomor")" "bug: langkah bernomor"

# ---------- kelayakan uji ----------
validasi() { # decision build terukur
cat > "$K/qa-validasi.md" <<EOF
# Validasi uji PROJ-1 — ubah alamat

- Tiket: PROJ-1
- Role: mobile
- Build: $2
- PR/MR: https://example.com/pr/1
- Validator: Kang Dadan (Validator)

## Keputusan
**Keputusan: $1**

## Acceptance criteria
| AC | Isi | Terukur | Hasil yang diharapkan |
|---|---|---|---|
| AC1 | simpan alamat | ya | alamat baru tampil |
| AC2 | rapi | $3 | - |

## Build dan lingkungan
staging

## Data uji
qa.user1 ada
EOF
}
validasi "Siap dengan catatan" 1234 tidak
assert_exit 0 "validasi: AC kabur + catatan diterima" -- "${C[@]}" validasi "$K/qa-validasi.md"
validasi "Siap diuji" 1234 tidak
assert_eq yes "$(has "$(out validasi "$K/qa-validasi.md")" "tidak boleh 'Siap diuji'")" "validasi: AC tak terukur menolak Siap diuji"
validasi "Siap dengan catatan" - tidak
assert_eq yes "$(has "$(out validasi "$K/qa-validasi.md")" "harus 'Belum siap'")" "validasi: tanpa build wajib Belum siap"
validasi "Mungkin" 1234 ya
assert_exit 1 "validasi: keputusan di luar daftar ditolak" -- "${C[@]}" validasi "$K/qa-validasi.md"

# ---------- folder tiket ----------
validasi "Siap dengan catatan" 1234 tidak
report Gagal Lulus Gagal Gagal "img/TC2-01.png, bug-1" "| bug-1 | TC2 | S2 | pesan galat |"
bugfile 1 S2; rm -f "$K"/bug-[345].md
assert_exit 0 "ticket: semua dokumen lolos" -- "${C[@]}" ticket "$K" --final
bugfile 3 S9
assert_exit 1 "ticket: satu bug rusak menggagalkan folder" -- "${C[@]}" ticket "$K"

# ---------- rekomendasi rilis ----------
S="$T/v1.2.0-qa.md"
signoff() { # rec ticket-rec reg-result smoke-section risk
cat > "$S" <<EOF
# Rekomendasi rilis v1.2.0

- Versi: v1.2.0
- Build: 1300
- Tiket rilis: PROJ-9

## Rekomendasi
**Rekomendasi rilis: $1**

## Tiket dalam rilis
| KODE | Rekomendasi QA | Bug terbuka |
|---|---|---|
| PROJ-1 | $2 | - |

## Regresi penuh
| Flow | Hasil | Bukti |
|---|---|---|
| login | $3 | img/login.png |

## Smoke live
$4

## Risiko tersisa
$5
EOF
}
SMOKE_OK=$'| Flow | Hasil | Bukti |\n|---|---|---|\n| beranda | Lulus | img/home.png |'
signoff "Layak rilis" Lolos Lulus "$SMOKE_OK" "Tidak ada"
assert_exit 0 "signoff: semua lulus → Layak rilis" -- "${C[@]}" signoff "$S"
signoff "Layak rilis" Lolos Gagal "$SMOKE_OK" "Tidak ada"
assert_eq yes "$(has "$(out signoff "$S")" "regresi login Gagal")" "signoff: regresi gagal menolak Layak rilis"
signoff "Layak rilis" Gagal Lulus "$SMOKE_OK" "Tidak ada"
assert_exit 1 "signoff: tiket gagal menolak Layak rilis" -- "${C[@]}" signoff "$S"
signoff "Layak rilis" Lolos Lulus "Belum dijalankan." "Tidak ada"
assert_eq yes "$(has "$(out signoff "$S")" "smoke live belum dijalankan")" "signoff: smoke belum jalan menolak Layak rilis"
signoff "Layak dengan risiko" Lolos Lulus "Belum dijalankan." "- Smoke live belum dijalankan"
assert_exit 0 "signoff: risiko tertulis → Layak dengan risiko" -- "${C[@]}" signoff "$S"
signoff "Layak dengan risiko" Lolos Lulus "Belum dijalankan." "Tidak ada"
assert_exit 1 "signoff: Layak dengan risiko wajib menyebut risiko" -- "${C[@]}" signoff "$S"

# ---------- template kosong tidak pernah lolos ----------
for t in qa-validasi:validasi qa:report bug:bug signoff:signoff; do
  assert_exit 1 "template $t.md mentah ditolak" -- "${C[@]}" "${t#*:}" "$REPO/templates/${t%%:*}.md"
done
assert_exit 2 "salah pakai → exit 2" -- "${C[@]}" nope x
exit $FAILS
