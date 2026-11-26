---
name: setup-board
description: Skill internal QA - memastikan platform tiket, status yang boleh dipakai agen QA (In Testing opsional, In Progress untuk pengembalian), dan QA manusia tercatat untuk project ini. Dipanggil di awal /validate-tiket, /develop-tiket, /rilis-tiket, /branch-manager. Kata kunci - setup board, platform tiket, status tiket QA.
argument-hint: "[KODE contoh tiket]"
---
Pastikan project siap dipakai workflow QA. Aturan platform: `~/.agent-workflow/qa-repo/skills/_shared/rules.md` → Platform tiket.

## Langkah
1. Baca memory project → **Platform tiket**. Belum ada (= `none`) → **berhenti dan tanya** user. Jangan menebak dari konektor yang kebetulan terpasang. Bingung → sarankan board bawaan host git (`git remote -v`: GitHub → GitHub Projects, GitLab → GitLab Issue Board), opsi lain Jira atau tanpa platform. Simpan jawaban (platform, identitas board, format KODE) sebagai memory project tipe `reference`.
2. Cek koneksi adapter (tabel di `rules.md`). Gagal → berhenti dan lapor.
3. Memory project → **QA manusia** (nama + sapaan orang yang memutuskan Done). Belum ada → tanya sekali, simpan.
4. **Daftar status QA** (kecuali tanpa platform). File state dipakai bersama workflow delivery: `${AGENT_WORKFLOW_STATE:-$HOME/.agent-workflow}/jira-transitions.json` (Jira) atau `ticket-status.json` (GitHub/GitLab). Cek project ini sudah punya id untuk **In Progress** dan (bila board punya) **In Testing**. Belum → tunjukkan daftar status/transisi ke user, user memilih, lalu **gabungkan** (jangan timpa id yang sudah ada dari workflow lain), lewat Bash:
```bash
S=${AGENT_WORKFLOW_STATE:-$HOME/.agent-workflow}; F="$S/jira-transitions.json"
mkdir -p "$S" && { [ -s "$F" ] || echo '{}' > "$F"; } &&
jq --arg p PROJ --argjson add '{"21":"In Progress","41":"In Testing"}' \
  '.[$p].allow = ((.[$p].allow // []) + ($add|keys) | unique) | .[$p].names = ((.[$p].names // {}) + $add)' "$F" > "$F.tmp" && mv "$F.tmp" "$F"
```
   GitHub: `.github[<PVT_id>]` dengan id opsi field Status; GitLab: `.gitlab["group/repo"].allow` dengan label. Cara membaca daftarnya: Jira `getTransitionsForJiraIssue`; GitHub `gh project field-list <n> --owner <o> --format json`; GitLab `glab label list`.
5. **Done tidak pernah** ditambahkan ke daftar. User memintanya → tolak dengan sopan: Done diputuskan QA manusia.

## Hasil
Platform, koneksi, QA manusia, dan daftar status siap. Sebut di chat bila ada yang baru disimpan.
