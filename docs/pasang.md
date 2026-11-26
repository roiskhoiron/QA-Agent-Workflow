# Pasang

1. Prasyarat: `git`, `jq`, `python3`; untuk menguji: Maestro + Android SDK/Xcode (mobile), Node + Playwright (web), Schemathesis + Pact (api); `gh`/`glab` sesuai host git; minimal satu coding agent.
2. Konektor: **Atlassian** hanya bila project memakai Jira; Claude Docs/Confluence/Notion hanya bila dipilih sebagai platform dokumentasi.
3. Pasang dan cek:
   ```bash
   git clone https://github.com/roiskhoiron/QA-Agent-Workflow ~/qa-agent-workflow
   bash ~/qa-agent-workflow/install.sh && bash ~/qa-agent-workflow/tests/run.sh   # harus "ALL PASS"
   ```

## Pilih coding agent dan scope
```bash
bash install.sh                                           # menu interaktif
bash install.sh --agent claude                            # Claude Code, global
bash install.sh --agent all --scope project --project ~/work/app
bash install.sh --help
```

| Agen | Skill | Hook guard | Instruksi |
| --- | --- | --- | --- |
| Claude Code | `.claude/skills` + `.claude/agents/qa-*.md` | `settings.json` (global) / `settings.local.json` (project) → PreToolUse | `CLAUDE.md` / `CLAUDE.local.md` |
| Codex CLI | `.agents/skills` | `.codex/hooks.json` (jalankan `/hooks` sekali untuk trust) | `AGENTS.md` |
| Gemini CLI | `.gemini/skills` | `.gemini/settings.json` → BeforeTool | `GEMINI.md` |
| Cursor | `.cursor/skills` | `.cursor/hooks.json` | global: tempel ke Settings → Rules; project: `.cursor/rules/qa-agent-workflow.mdc` |
| OpenCode | `.config/opencode/skills` / `.opencode/skills` | plugin `qa-agent-workflow-guard.js` | `AGENTS.md` |

Installer membuat jangkar `~/.agent-workflow/qa-repo` (symlink ke repo ini) dan memakai state `~/.agent-workflow/` **bersama** workflow delivery (kunci device/akun, daftar status tiket, memory project agen non-Claude). Berkas JSON yang diubah di-backup sekali ke `*.bak-qa-agent-workflow`. Karena symlink, perubahan repo langsung berlaku; pasang ulang hanya bila ada skill/agen baru.

## Berdampingan dengan workflow delivery
Perintah QA sengaja **bernama sama** dengan workflow delivery (`/validate-tiket`, `/develop-tiket`, …). Satu folder skill hanya bisa berisi satu perintah bernama sama, jadi:
- Di komputer yang juga memasang workflow Mobile/Web/Backend secara global → pasang QA dengan **`--scope project`** di project yang diuji (atau di folder kerja QA). Installer **menolak** menimpa skill milik workflow lain dan menyebut caranya; `--force` untuk tetap menimpa.
- Agen QA berawalan `qa-` dan guard bernama `qa-guard.sh`, jadi keduanya tidak bentrok dengan agen dan `guard.sh` workflow delivery; kedua hook berjalan berdampingan.
- `--scope project` di Claude Code juga menulis `env.QA_AGENT_WORKFLOW=1` di `settings.local.json`: pagar QA selalu aktif di project itu. Semua berkas buatan installer dicatat di `.git/info/exclude`.

Tidak ikut repo (per komputer): memory project, `~/.agent-workflow/*.json` (daftar status), `~/.agent-workflow/qa-test-paths.txt` (opsional), `qa.local.properties` per project.

---
[← kembali ke README](../README.md)
