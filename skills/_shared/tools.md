# Alat uji per role

Tempat uji dan alatnya mengikuti **role tiket** (`mobile` / `web` / `api`, dari label/komponen tiket; pemetaannya di memory project → Role tiket). Satu tiket boleh lebih dari satu role (mis. layar mobile + endpoint baru): uji tiap role dengan alatnya.

| Role | Tempat uji | Alat utama | Cadangan | Bukti |
|---|---|---|---|---|
| `mobile` | device (simulator/emulator dulu, fisik bila perlu) | Maestro | Android: `adb`; iOS: XCUITest runner dari workflow Mobile bila terpasang (`~/.agent-workflow/repo/bin/ios-ui.sh`) | screenshot bertanda, rekaman layar |
| `web` | browser (Chromium dulu; Firefox/WebKit bila tiket menyebut) | Playwright | Playwright codegen + langkah manual tertulis | screenshot bertanda, trace Playwright |
| `api` | server dev/staging | Schemathesis (spec OpenAPI), Pact (kontrak), `curl` untuk langkah eksplisit | `curl` | potongan request/response (tanpa token), ringkasan Schemathesis |

Semua alat gagal → TC **Tertahan**, tulis alat yang dicoba + error-nya.

## Folder kerja
Berkas sementara (flow, skrip, hierarchy, screenshot mentah) **tidak** ditulis ke repo:
- Validator: `${TMPDIR:-/tmp}/qa/<KODE>/validasi/`
- QA: `${TMPDIR:-/tmp}/qa/<KODE>/` (`flows/`, `img/`, `logs/`)
- Audit: `${TMPDIR:-/tmp}/qa/audit/<slug>/`

Yang masuk repo (worktree QA, branch `qa/<KODE>`): dokumen QA di `docs/`, screenshot terpilih di `docs/tickets/<KODE>/img/`, dan kode otomasi uji yang layak dipelihara (flow Maestro di suite, spec Playwright, tes kontrak).

## Device (role `mobile`)
Aturan sama dengan workflow Mobile dan **kunci dipakai bersama** (`~/.agent-workflow/locks`): satu device, satu agen, satu waktu, dari workflow mana pun. **Virtual dulu**; device fisik hanya bila TC butuh hardware asli (push notification, kamera/QR, NFC, Bluetooth, GPS bergerak, SMS/telepon asli, biometrik, pembayaran, metrik performa, bug di model device tertentu) — TC seperti ini ditandai `(fisik)`.

**Wajib:** setiap perintah `device-lock.sh`/`device-pick.sh` diawali `AGENT_LOCK_PID=$PPID` di panggilan Bash yang sama.
```bash
# ambil (satu panggilan Bash)
if dev=$(AGENT_LOCK_PID=$PPID "$QA_WORKFLOW_DIR/bin/device-pick.sh" android PROJ-1234-qa1); then
  echo "pakai $dev"     # ios:<udid> atau android:<serial>
else
  echo "antre: semua device sibuk"
fi
# lepas setelah selesai (panggilan lain, id ditulis literal)
AGENT_LOCK_PID=$PPID "$QA_WORKFLOW_DIR/bin/device-lock.sh" release android:<serial> PROJ-1234-qa1
```
- `device-pick.sh <ios|android> <owner> [--physical]` → resource terkunci, exit 1 = tidak ada yang bebas (tunggu lalu coba lagi; jangan pakai device lain).
- `device-lock.sh who <resource>` → pemilik. Pemilik tiket lain atau `human-*` → **tanya user**: tunggu atau ambil alih (ambil alih hanya setelah user setuju; pakai `device-preempt.sh` dari workflow Mobile bila terpasang, selain itu minta pemilik melepas).
- Owner = `<KODE>-<peran><n>`, mis. `PROJ-1234-qa1`.
- Install/uninstall/`pm clear` hanya di device yang kamu kunci; selalu tulis `-s <serial>` / `--device <id>` / udid.
- Build **tidak** dibangun QA: pasang build yang sudah didistribusikan (Firebase App Distribution, TestFlight, artefak CI) sesuai memory project → Lingkungan uji.

## Browser (role `web`)
- Playwright headless, satu folder kerja per TC run. Simpan spec di `$W/flows/<TC>.spec.ts`, jalankan dengan trace bila TC gagal: `npx playwright test <spec> --trace on`.
- Ukuran layar default desktop 1280×800; tiket yang menyebut mobile web → `devices['iPhone 13']` atau ukuran yang disebut tiket.
- Screenshot tiap langkah penting (`page.screenshot({ path: 'img/TC1-01.png' })`), kotak merah dari `locator.boundingBox()`.
- URL lingkungan dari memory project; produksi dilarang kecuali `/smoke-live` (baca saja).

## API (role `api`)
- Schemathesis hanya untuk endpoint tiket. Dev/staging: penuh. Beta/live: hanya method aman (GET/HEAD/OPTIONS), tanpa fuzzing, tanpa menulis data.
- Pact: verifikasi interaksi yang menyangkut endpoint tiket, bila kontrak ada.
- Bukti: perintah, status, potongan body; token/kunci diganti `***`.

## Kotak merah dari koordinat, bukan tebakan
1. Ambil koordinat elemen: `maestro --device <id> hierarchy > "$W/h.json"` (Android: bounds piksel; iOS: point × skala layar), atau Playwright `await locator.boundingBox()` (piksel CSS × `deviceScaleFactor`).
2. Tulis `boxes.json` lalu jalankan:
```bash
W=${TMPDIR:-/tmp}/qa/PROJ-1234
echo '[{"x":60,"y":720,"w":1050,"h":140,"label":"AC2 tombol Simpan aktif"}]' > "$W/boxes.json"
uv run --with pillow python3 "$QA_WORKFLOW_DIR/bin/annotate.py" "$W/img/TC1-02.png" "$W/boxes.json" "$W/img/TC1-02-ac2.png"
```
- Elemen tidak ada di hierarchy → tulis itu di laporan; jangan menggambar kotak kira-kira.

## Akun uji
Satu akun uji, satu agen, satu waktu: `AGENT_LOCK_PID=$PPID "$QA_WORKFLOW_DIR/bin/device-lock.sh" acquire account:qa.user1 PROJ-1234-qa1` (exit 1 = dipakai, stdout = pemiliknya). Detail: `credentials.md`.

## Pemeriksa dokumen
`python3 "$QA_WORKFLOW_DIR/bin/qa-check.py" <validasi|report|bug|signoff|ticket> <path>` (aturan di `report-format.md`). Dijalankan sebelum dokumen dikirim ke platform dokumentasi atau dikomentarkan ke tiket.
