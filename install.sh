#!/usr/bin/env bash
# Pasang QA agent workflow untuk satu atau beberapa coding agent. Idempotent.
#
# Usage: install.sh [--agent LIST] [--scope global|project] [--project DIR] [--home DIR] [--force]
#   --agent    claude,codex,gemini,cursor,opencode (pisah koma) atau all. Default: claude.
#   --scope    global  = untuk semua project di komputer ini (default); pagar QA aktif saat skill QA berjalan
#              project = hanya untuk satu project (--project DIR, default folder saat ini); pagar QA selalu aktif
#   --home     pasang ke HOME lain (tes).
#   --force    timpa skill bernama sama milik workflow lain (mis. /validate-tiket workflow Mobile).
# Tanpa --agent/--scope dan dijalankan di terminal → menu interaktif.
set -euo pipefail
REPO="$(cd "$(dirname "$0")" && pwd -P)"
ALL_AGENTS="claude codex gemini cursor opencode"
DEST="$HOME"; CUSTOM=0; AGENTS=''; SCOPE=''; PROJ=''; FORCE=0

die() { echo "install.sh: $*" >&2; exit 2; }
while [ $# -gt 0 ]; do
  case $1 in
    --home) DEST="${2:?--home butuh folder}"; CUSTOM=1; shift 2;;
    --agent|--agents) AGENTS="${2:?--agent butuh nilai}"; shift 2;;
    --scope) SCOPE="${2:?--scope butuh nilai}"; shift 2;;
    --project) PROJ="${2:?--project butuh folder}"; shift 2;;
    --force) FORCE=1; shift;;
    -h|--help) sed -n '2,11p' "$0" | sed 's/^# \{0,1\}//'; exit 0;;
    *) die "argumen tidak dikenal: $1 (lihat --help)";;
  esac
done

# ---------- pilihan interaktif ----------
if [ -z "$AGENTS$SCOPE" ] && [ -t 0 ] && [ -t 1 ]; then
  echo "Coding agent yang dipasangi QA workflow (pisah spasi/koma, Enter = claude):"
  echo "  1) claude    Claude Code"
  echo "  2) codex     OpenAI Codex CLI"
  echo "  3) gemini    Gemini CLI"
  echo "  4) cursor    Cursor"
  echo "  5) opencode  OpenCode"
  echo "  6) all       semua di atas"
  printf '> '; read -r ans || ans=''
  AGENTS=''
  for a in $(echo "${ans:-1}" | tr ',' ' '); do
    case $a in 1) a=claude;; 2) a=codex;; 3) a=gemini;; 4) a=cursor;; 5) a=opencode;; 6) a=all;; esac
    AGENTS="$AGENTS,$a"
  done
  echo "Scope:"
  echo "  1) global   semua project di komputer ini"
  echo "  2) project  hanya satu project (disarankan bila workflow Mobile/Web/Backend juga terpasang global)"
  printf '> '; read -r ans || ans=''
  case ${ans:-1} in 2|project) SCOPE=project;; *) SCOPE=global;; esac
  if [ "$SCOPE" = project ] && [ -z "$PROJ" ]; then
    printf 'Folder project [%s]: ' "$PWD"; read -r ans || ans=''
    PROJ="${ans:-$PWD}"
  fi
fi
[ -n "$AGENTS" ] || AGENTS=claude
[ -n "$SCOPE" ] || SCOPE=global
case $SCOPE in global|project) ;; *) die "--scope harus global atau project";; esac
AGENTS=$(echo "$AGENTS" | tr ',' ' ' | tr 'A-Z' 'a-z')
case " $AGENTS " in *' all '*) AGENTS=$ALL_AGENTS;; esac
for a in $AGENTS; do case " $ALL_AGENTS " in *" $a "*) ;; *) die "agen tidak dikenal: $a (pilihan: $ALL_AGENTS, all)";; esac; done
if [ "$SCOPE" = project ]; then
  PROJ="$(cd "${PROJ:-$PWD}" 2>/dev/null && pwd -P)" || die "folder project tidak ada"
  [ "$PROJ" != "$REPO" ] || die "--project tidak boleh repo workflow ini sendiri"
fi
command -v jq >/dev/null || die "jq tidak ditemukan (brew install jq / apt install jq)"
command -v python3 >/dev/null || die "python3 tidak ditemukan"

GUARD="$REPO/hooks/qa-guard.sh"
GUARD_CMD="\"$GUARD\""
NOTES=''
note() { NOTES="$NOTES
- $*"; }

# ---------- helper ----------
# jangkar: semua skill/agen merujuk ~/.agent-workflow/qa-repo (rules.md → Lokasi); state ~/.agent-workflow dipakai bersama
mkdir -p "$DEST/.agent-workflow"
ln -sfn "$REPO" "$DEST/.agent-workflow/qa-repo"

exclude() { # relpath (project scope: file buatan installer jangan sampai ter-commit)
  [ "$SCOPE" = project ] || return 0
  local ex
  ex=$(git -C "$PROJ" rev-parse --git-path info/exclude 2>/dev/null) || return 0
  case $ex in /*) ;; *) ex="$PROJ/$ex";; esac
  mkdir -p "$(dirname "$ex")"
  grep -qxF "/$1" "$ex" 2>/dev/null || echo "/$1" >> "$ex"
}

# link $1 -> $2, refusing to replace something that belongs to another workflow (unless --force)
safe_link() { # target link
  local t=$1 l=$2 cur
  if [ -L "$l" ]; then
    cur=$(readlink "$l")
    case $cur in "$REPO"/*) ;; *)
      [ "$FORCE" = 1 ] || die "$l sudah ada dan milik workflow lain ($cur). Pakai --scope project untuk project QA, atau --force untuk menimpa.";;
    esac
  elif [ -e "$l" ]; then
    [ "$FORCE" = 1 ] || die "$l sudah ada (bukan symlink). Pindahkan dulu, atau pakai --force."
    rm -rf "$l"
  fi
  ln -sfn "$t" "$l"
}

link_skills() { # dir relpath-for-exclude [shared]
  local dir=$1 rel=$2 d n
  mkdir -p "$dir"
  for d in "$REPO"/skills/*/; do
    n=$(basename "$d")
    if [ "$n" = _shared ]; then [ "${3:-}" = shared ] || continue; n=_qa-agent-workflow-shared; fi
    safe_link "${d%/}" "$dir/$n"
    exclude "$rel/$n"
  done
}

json_init() { # file → ada + backup isi asli pertama
  mkdir -p "$(dirname "$1")"
  [ -f "$1" ] || { echo '{}' > "$1"; exclude "${1#"$PROJ"/}"; }
  [ -e "$1.bak-qa-agent-workflow" ] || cp "$1" "$1.bak-qa-agent-workflow"
  exclude "${1#"$PROJ"/}.bak-qa-agent-workflow"
  if [ "$SCOPE" = project ] && git -C "$PROJ" ls-files --error-unmatch "$1" >/dev/null 2>&1; then
    note "$1 ter-commit di repo project: hook qa-guard ditambahkan, periksa sebelum commit."
  fi
}

json_apply() { # file jq-filter [jq args...]
  local f=$1 flt=$2 tmp; shift 2
  tmp=$(mktemp)
  jq "$@" "$flt" "$f" > "$tmp" || { rm -f "$tmp"; die "gagal memperbarui $f (JSON rusak?)"; }
  mv "$tmp" "$f"
}

# hook gaya Claude (Claude Code, Codex, Gemini CLI): .hooks[EVENT] = [{matcher, hooks:[{type,command}]}]
# hanya entri qa-guard yang disentuh; guard workflow lain (guard.sh) tetap ada.
merge_hook() { # file event matcher
  json_init "$1"
  json_apply "$1" '
    def isg: (.command | tostring | test("/qa-guard\\.sh\"?$"));
    def isguard: any((.hooks // [])[]?; isg);
    .hooks[$ev] = ((.hooks[$ev] // [])
      | if any(.[]; isguard) then map(if isguard then .matcher = $m | .hooks |= map(if isg then .command = $cmd else . end) else . end)
        else . + [{matcher:$m, hooks:[{type:"command",command:$cmd}]}] end)' \
    --arg ev "$2" --arg m "$3" --arg cmd "$GUARD_CMD"
}

append_instructions() { # file [frontmatter untuk file baru]
  local f=$1 T="$REPO/templates/agent-instructions.md"
  mkdir -p "$(dirname "$f")"
  grep -qsE '^# QA agent workflow' "$f" && return 0
  if [ -n "${2:-}" ] && [ ! -s "$f" ]; then printf '%s\n' "$2" > "$f"; fi
  { [ -s "$f" ] && echo; cat "$T"; } >> "$f"
  if [ "$SCOPE" = project ] && git -C "$PROJ" ls-files --error-unmatch "$f" >/dev/null 2>&1; then
    note "$f ter-commit di repo project: blok QA workflow ditambahkan di bawahnya, periksa sebelum commit."
  fi
}

# ---------- per agen ----------
install_claude() {
  local C S f
  if [ "$SCOPE" = global ]; then C="$DEST/.claude"; S="$C/settings.json"; else C="$PROJ/.claude"; S="$C/settings.local.json"; fi
  link_skills "$C/skills" .claude/skills shared
  mkdir -p "$C/agents"
  for f in "$REPO"/agents/*.md; do
    safe_link "$f" "$C/agents/$(basename "$f")"; exclude ".claude/agents/$(basename "$f")"
  done
  merge_hook "$S" PreToolUse 'Bash|Edit|Write|MultiEdit|NotebookEdit|mcp__.*Atlassian.*'
  # project scope = project QA: pagar QA selalu aktif, tanpa perlu qa-mode.sh
  [ "$SCOPE" = project ] && json_apply "$S" '.env.QA_AGENT_WORKFLOW = "1"'
  if [ "$SCOPE" = global ]; then append_instructions "$C/CLAUDE.md"
  else append_instructions "$PROJ/CLAUDE.local.md"; exclude CLAUDE.local.md; exclude .claude/settings.local.json; fi
}

install_codex() {
  local C K
  if [ "$SCOPE" = global ]; then
    if [ "$CUSTOM" = 1 ]; then C="$DEST/.codex"; else C="${CODEX_HOME:-$DEST/.codex}"; fi
    K="$DEST/.agents/skills"
  else C="$PROJ/.codex"; K="$PROJ/.agents/skills"; fi
  link_skills "$K" .agents/skills
  merge_hook "$C/hooks.json" PreToolUse 'Bash|apply_patch'
  exclude .codex/hooks.json
  if [ "$SCOPE" = global ]; then append_instructions "$C/AGENTS.md"; else append_instructions "$PROJ/AGENTS.md"; fi
  note "Codex: buka Codex lalu jalankan /hooks untuk me-review dan trust hook qa-guard."
}

install_gemini() {
  local G
  if [ "$SCOPE" = global ]; then G="$DEST/.gemini"; else G="$PROJ/.gemini"; fi
  link_skills "$G/skills" .gemini/skills
  merge_hook "$G/settings.json" BeforeTool 'run_shell_command|write_file|replace'
  if [ "$SCOPE" = global ]; then append_instructions "$G/GEMINI.md"; else append_instructions "$PROJ/GEMINI.md"; fi
}

install_cursor() {
  local U H
  if [ "$SCOPE" = global ]; then U="$DEST/.cursor"; else U="$PROJ/.cursor"; fi
  link_skills "$U/skills" .cursor/skills
  H="$U/hooks.json"
  json_init "$H"
  json_apply "$H" '
    def isguard: (.command | tostring | test("/qa-guard\\.sh\"?$"));
    .version = (.version // 1)
    | .hooks.preToolUse = ((.hooks.preToolUse // [])
      | if any(.[]; isguard) then map(if isguard then .matcher = $m | .command = $cmd else . end)
        else . + [{command:$cmd, matcher:$m}] end)' \
    --arg m 'Shell|Write|Delete' --arg cmd "$GUARD_CMD"
  if [ "$SCOPE" = global ]; then
    note "Cursor: aturan global bukan file. Tempel isi templates/agent-instructions.md ke Cursor Settings → Rules → User Rules."
  else
    append_instructions "$PROJ/.cursor/rules/qa-agent-workflow.mdc" $'---\ndescription: QA agent workflow (qa-agent-workflow)\nalwaysApply: true\n---'
    exclude .cursor/rules/qa-agent-workflow.mdc; exclude .cursor/hooks.json
  fi
}

install_opencode() {
  local O g
  if [ "$SCOPE" = global ]; then
    if [ "$CUSTOM" = 1 ]; then O="$DEST/.config/opencode"; else O="${XDG_CONFIG_HOME:-$DEST/.config}/opencode"; fi
  else O="$PROJ/.opencode"; fi
  link_skills "$O/skills" .opencode/skills
  mkdir -p "$O/plugins"
  g=$(jq -cn --arg g "$GUARD" '$g')
  GUARD_JSON="$g" python3 -c 'import os,sys; print(open(sys.argv[1]).read().replace("__GUARD__", os.environ["GUARD_JSON"]), end="")' \
    "$REPO/templates/opencode-guard.js" > "$O/plugins/qa-agent-workflow-guard.js"
  exclude .opencode/plugins/qa-agent-workflow-guard.js
  if [ "$SCOPE" = global ]; then append_instructions "$O/AGENTS.md"; else append_instructions "$PROJ/AGENTS.md"; fi
}

for a in $AGENTS; do "install_$a"; echo "ok: $a ($SCOPE)"; done
[ "$SCOPE" = project ] && [ "${AGENTS// /}" != claude ] &&
  note "Agen selain Claude Code di scope project: set env QA_AGENT_WORKFLOW=1 di sesi agen itu supaya pagar QA selalu aktif (skill QA juga menyalakannya lewat qa-mode.sh)."

if [ "$SCOPE" = project ]; then echo "installed into $PROJ (project) + jangkar $DEST/.agent-workflow/qa-repo"
else echo "installed into $DEST"; fi
[ -z "$NOTES" ] || echo "Catatan:$NOTES"
