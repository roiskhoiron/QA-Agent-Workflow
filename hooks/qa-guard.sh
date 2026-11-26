#!/bin/bash
# PreToolUse guard for the QA agent workflow. stdin = hook JSON. exit 0 = allow, exit 2 + stderr = block.
# Native format = Claude Code (tool_name/tool_input/cwd/session_id). Codex, Gemini CLI and Cursor send the same
# shape with their own tool names (normalized below); OpenCode goes through templates/opencode-guard.js.
#
# Dormant unless the session is in QA mode, so delivery-workflow sessions (Coder) on the same machine are untouched:
#   QA_AGENT_WORKFLOW=1 in the env, or bin/qa-mode.sh marked an ancestor pid (the SPV session) for qa|blind|audit,
#   or this is a teammate whose lead session (--parent-session-id) is marked.
# Rules (skills/_shared/rules.md, "Selalu diblokir"):
#   QA     edits only test automation + QA docs inside a git repo; push only qa/* branches to origin, never force/tags;
#          no PR/MR merge or approve; ticket status only to allowed ids/labels, never close; rm -r only inside the
#          project or /tmp/qa; worktree add/remove only siblings (<repo>-qa-<n>), never --force/move;
#          device install/uninstall only when not locked by someone else.
#   BLIND  plus: no command that shows the diff (git diff/show/log -p, gh pr diff, glab mr diff); names/stat allowed.
#   AUDIT  plus: read-only git/gh/glab, no Atlassian writes, edits only in ${TMPDIR:-/tmp}/qa/audit.
# Shortcut: shell writes (sed -i, > file) are not parsed; QA agents are told not to write product files via shell.
PATH="$PATH:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"
PROTECTED='main|master|develop'

block() { echo "DIBLOKIR oleh qa-guard: $*" >&2; exit 2; }

JQ=$(command -v jq) || { echo "DIBLOKIR oleh qa-guard: jq tidak ditemukan. Install jq." >&2; exit 2; }
PY=$(command -v python3)
STATE=${AGENT_WORKFLOW_STATE:-$HOME/.agent-workflow}

join_path() { case $1 in /*) echo "$1";; *) echo "$2/$1";; esac; }
expand_home() {
  case $1 in
    '~') echo "$HOME";;
    '~/'*) echo "$HOME/${1#\~/}";;
    '$HOME'|'${HOME}') echo "$HOME";;
    '$HOME/'*) echo "$HOME/${1#\$HOME/}";;
    '${HOME}/'*) echo "$HOME/${1#\$\{HOME\}/}";;
    *) echo "$1";;
  esac
}

# ---------- mode detection ----------
# sets QA/BLIND/AUDIT (1 or empty)
detect_modes() {
  local m p pp cmd sid lead mk
  QA='' BLIND='' AUDIT=''
  [ "${QA_AGENT_WORKFLOW:-}" = 1 ] && QA=1
  [ "${QA_AGENT_BLIND:-}" = 1 ] && { QA=1; BLIND=1; }
  [ "${QA_AGENT_AUDIT:-}" = 1 ] && { QA=1; AUDIT=1; }
  [ -d "$STATE/qa-mode" ] || return 0
  sid=$(printf '%s' "$input" | "$JQ" -r '.session_id // empty' 2>/dev/null)
  for m in qa blind audit; do
    mk=$STATE/qa-mode/$m
    [ -d "$mk" ] || continue
    p=$$
    for _ in 1 2 3 4 5 6 7 8 9; do
      if [ -f "$mk/$p" ]; then
        set_mode "$m"
        [ -n "$sid" ] && echo "$p" > "$mk/session-$sid"
        break
      fi
      read -r pp cmd < <(ps -o ppid=,command= -p "$p" 2>/dev/null)
      case $cmd in *' --parent-session-id '*)
        lead=${cmd#* --parent-session-id }; lead=${lead%% *}
        lead=$(cat "$mk/session-$lead" 2>/dev/null)
        [ -n "$lead" ] && [ -f "$mk/$lead" ] && { set_mode "$m"; break; } ;;
      esac
      p=$pp
      [ -n "$p" ] && [ "$p" -gt 1 ] || break
    done
  done
}
set_mode() { QA=1; case $1 in blind) BLIND=1;; audit) AUDIT=1;; esac; }

# ---------- git ----------
check_git() {
  local d=$wd n=$# unk=''
  while [ $# -gt 0 ]; do
    case $1 in
      -C) d=$(join_path "$(expand_home "$2")" "$wd"); shift 2;;
      -c|--git-dir|--work-tree|--namespace|--super-prefix|--config-env) shift 2;;
      --*=*|-p|-P|--paginate|--no-pager|--bare|--no-replace-objects|--no-optional-locks|--*-pathspecs) shift;;
      -*) unk=1; shift;;
      *) break;;
    esac
  done
  GSUB_OFF=$((n - $#))
  [ -n "$AUDIT" ] && check_git_audit "$@"
  [ -n "$BLIND" ] && check_git_blind "$@"
  [ "${1:-}" = worktree ] && case ${2:-} in add|remove|move) check_worktree "$d" "${@:2}";; esac
  if [ "${1:-}" != push ] && [ -n "$unk" ]; then
    while [ $# -gt 0 ] && [ "$1" != push ]; do shift; done
  fi
  [ "${1:-}" = push ] || return 0
  shift
  local remote='' repo='' refs=() r dst br
  while [ $# -gt 0 ]; do
    case $1 in
      --repo=*) repo=${1#--repo=};;
      --repo) repo=$2; shift;;
      -o|--push-option|--receive-pack|--exec) shift;;
      --force*|--mirror|--delete) block "git push $1 dilarang: QA tidak pernah force-push atau menghapus branch.";;
      --tags|--follow-tags|--all|--branches) block "git push $1 dilarang: push satu branch qa/<KODE> saja.";;
      --*) ;;
      -*[fd]*) block "git push $1 dilarang: QA tidak pernah force-push atau menghapus branch.";;
      -*) ;;
      *) if [ -z "$remote" ]; then remote=$1; else refs+=("$1"); fi;;
    esac
    shift
  done
  [ -n "$remote" ] || remote=$repo
  br=$(git -C "$d" symbolic-ref --short -q HEAD 2>/dev/null)
  if [ -z "$remote" ]; then
    remote=$(git -C "$d" config "branch.$br.pushRemote" 2>/dev/null ||
             git -C "$d" config remote.pushDefault 2>/dev/null ||
             git -C "$d" config "branch.$br.remote" 2>/dev/null)
    [ -n "$remote" ] || block "remote untuk 'git push' tidak bisa dipastikan. Tulis eksplisit: git push origin qa/<KODE>."
  fi
  if [ "$remote" != origin ]; then
    local ou ru
    ou=$(git -C "$d" remote get-url --push origin 2>/dev/null)
    ru=$(git -C "$d" remote get-url --push "$remote" 2>/dev/null || echo "$remote")
    [ -n "$ou" ] && [ "$ru" = "$ou" ] ||
      block "push ke remote '$remote' dilarang; QA hanya push ke origin. Gunakan: git push origin qa/<KODE>."
  fi
  [ ${#refs[@]} -eq 0 ] && refs=(HEAD)
  for r in "${refs[@]}"; do
    case $r in +*|:*) block "push '$r' dilarang: QA tidak pernah force-push atau menghapus branch.";; esac
    dst=${r##*:}; dst=${dst#refs/heads/}
    [ "$dst" = HEAD ] && dst=$br
    case $dst in
      refs/tags/*|v[0-9]*) block "push tag '$dst' dilarang: tag versi dibuat workflow rilis, bukan QA.";;
      qa/?*) ;;
      *) block "push branch '$dst' dilarang: QA hanya push branch qa/<KODE> (kode otomasi uji + dokumen QA).";;
    esac
  done
}

blind_block() { block "$1 dilarang selama mode buta: test case disusun tanpa membaca diff (aturan independensi). Pakai --name-only/--stat bila hanya butuh daftar file."; }

# blind mode: commands that print patch content
check_git_blind() {
  local s=${1:-} a names=''
  shift
  for a; do case $a in --name-only|--name-status|--stat|--shortstat|--numstat|--quiet|--exit-code|--no-patch|-s) names=1;; esac; done
  case $s in
    diff|difftool|format-patch|range-diff) [ -n "$names" ] && [ "$s" = diff ] && return 0; blind_block "git $s";;
    show)
      [ -n "$names" ] && return 0
      for a; do case $a in -*) ;; *:*) ;; *) blind_block "git show $a";; esac; done
      [ $# -gt 0 ] || blind_block "git show";;
    log|whatchanged)
      for a; do case $a in -p|-u|--patch|--patch-with-stat|--patch-with-raw|-G*|-S*|--word-diff*|--full-diff) blind_block "git $s $a";; esac; done
      [ "$s" = whatchanged ] && [ -z "$names" ] && blind_block "git whatchanged";;
    stash) [ "${1:-}" = show ] && { [ -n "$names" ] || blind_block "git stash show"; };;
    add) for a; do case $a in -p|--patch|-i|--interactive) blind_block "git add $a";; esac; done;;
  esac
  return 0
}

audit_block() { block "$1 dilarang: mode audit hanya-baca (/audit-issue). Catat temuan di laporan, jangan ubah repo/tiket."; }

check_git_audit() {
  local s=${1:-} a list='' skip=''
  shift
  case $s in
    ''|show|log|grep|blame|diff|status|ls-files|ls-tree|rev-parse|rev-list|describe|cat-file|for-each-ref|show-ref|shortlog|name-rev|merge-base|help|version|--version|--help) return 0;;
    fetch) for a; do case $a in *:*) audit_block "git fetch $a (refspec menulis branch lokal)";; esac; done;;
    reflog) case ${1:-} in expire|delete) audit_block "git reflog $1";; esac;;
    branch|tag)
      for a; do
        [ -n "$skip" ] && { skip=''; continue; }
        case $a in
          -l|--list) list=1;;
          --contains|--no-contains|--merged|--no-merged|--points-at|--sort|--format) skip=1;;
          -a) [ "$s" = tag ] && audit_block "git tag -a";;
          -d|-D|-m|-M|-c|-C|-f|-u|-s|-F|-e|--delete|--move|--copy|--force|--annotate|--sign|--edit-description|--unset-upstream|--set-upstream-to*|--track*|--file*|--message*) audit_block "git $s $a";;
          -*) ;;
          *) [ -n "$list" ] || audit_block "git $s $a";;
        esac
      done;;
    remote)
      case ${1:-} in -v|--verbose) shift;; esac
      case ${1:-} in ''|get-url|show) ;; *) audit_block "git remote $1";; esac;;
    config) for a; do case $a in --get|--get-all|--get-regexp|--list|-l) return 0;; esac; done; audit_block "git config";;
    worktree) [ "${1:-}" = list ] || audit_block "git worktree ${1:-}";;
    stash) case ${1:-} in list|show) ;; *) audit_block "git stash ${1:-}";; esac;;
    *) audit_block "git $s";;
  esac
  return 0
}

# worktree add/remove: siblings of the checkout only; remove only QA worktrees <repo>-qa-<n>, never forced
check_worktree() {
  local d=$1 op=$2 p='' top
  shift 2
  [ "$op" = move ] && block "git worktree move dilarang: jangan memindah worktree. Minta user."
  while [ $# -gt 0 ]; do
    case $1 in
      -b|-B|--reason) shift 2;;
      -f|--force) [ "$op" = remove ] && block "git worktree remove --force dilarang: commit + push dulu, atau minta user."; shift;;
      -*) shift;;
      *) [ -n "$p" ] || p=$1; shift;;
    esac
  done
  [ -n "$p" ] || return 0
  [ -n "$PY" ] || block "python3 tidak ditemukan, guard tidak bisa memeriksa path worktree."
  top=$(git -C "$d" rev-parse --show-toplevel 2>/dev/null) || block "git worktree $op: repo tidak dikenali di $d."
  p=$("$PY" -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' "$(join_path "$(expand_home "$p")" "$d")")
  top=$("$PY" -c 'import os,sys; print(os.path.dirname(os.path.realpath(sys.argv[1])))' "$top")
  [ "${p%/*}" = "$top" ] || block "git worktree $op hanya untuk folder sejajar checkout ini ($top/<repo>-qa-<nomor>), tulis path apa adanya tanpa variabel: $p."
  [ "$op" = remove ] && ! [[ ${p##*/} =~ -qa-([0-9]+|rilis-v[0-9][0-9.]*)$ ]] && block "git worktree remove hanya untuk worktree QA <repo>-qa-<nomor> atau <repo>-qa-rilis-vX.Y.Z: ${p##*/} bukan milik workflow QA."
  return 0
}

# ---------- gh / glab ----------
check_forge() { # forge args...
  local forge=$1 a prev='' approve=''
  shift
  case "${1:-} ${2:-}" in
    'pr merge'|'mr merge') block "$forge $1 merge dilarang: merge diputuskan manusia, QA hanya merekomendasikan.";;
    'mr approve') block "glab mr approve dilarang: persetujuan PR/MR diputuskan manusia.";;
    'pr review') for a in "${@:3}"; do case $a in -a|--approve) approve=1;; esac; done
                 [ -n "$approve" ] && block "gh pr review --approve dilarang: persetujuan PR/MR diputuskan manusia. Pakai --comment.";;
    'pr diff'|'mr diff') [ -n "$BLIND" ] && blind_block "$forge $1 diff";;
  esac
  [ -n "$AUDIT" ] && check_forge_audit "$@"
  check_ticket_cli "$forge" "$@"
}

check_forge_audit() {
  local a prev=''
  case ${1:-} in
    ''|search|status|help|version|--version|--help|-h) ;;
    auth) [ "${2:-}" = status ] || audit_block "gh/glab auth ${2:-}";;
    api)
      for a; do
        case $a in -f*|-F*|--field*|--raw-field*|--input*) audit_block "gh/glab api $a";; esac
        case $prev in -X|--method) [ "$a" = GET ] || audit_block "gh/glab api $prev $a";; esac
        case $a in --method=*) [ "${a#*=}" = GET ] || audit_block "gh/glab api $a";; -X?*) [ "${a#-X}" = GET ] || audit_block "gh/glab api $a";; esac
        prev=$a
      done;;
    *) case ${2:-} in view|list|ls|status|diff|checks|show|watch|-h|--help) ;; *) audit_block "gh/glab $1 ${2:-}";; esac;;
  esac
  return 0
}

# ticket status: never close; status changes only to option ids (GitHub) / labels (GitLab) in ticket-status.json
check_ticket_cli() {
  local forge=$1; shift
  local cfg=$STATE/ticket-status.json a prev='' pid='' opt='' labels=() l x xs
  case "${1:-} ${2:-}" in
    'issue close'|'issue delete') block "$forge issue ${2} dilarang: Done/tutup issue hanya oleh manusia.";;
    'project item-edit'|'project item-archive'|'project item-delete')
      [ "$forge" = gh ] || return 0
      [ "${2}" = item-edit ] || block "gh project ${2} dilarang: kolom board hanya dipindah lewat item-edit ke status yang diizinkan."
      for a in "${@:3}"; do
        case $prev in --project-id) pid=$a;; --single-select-option-id) opt=$a;; esac
        case $a in --project-id=*) pid=${a#*=};; --single-select-option-id=*) opt=${a#*=};; --clear) block "gh project item-edit --clear dilarang.";; esac
        prev=$a
      done
      [ -n "$opt" ] || return 0
      "$JQ" -e type "$cfg" >/dev/null 2>&1 || block "daftar status tiket tidak ada/rusak ($cfg). Jalankan /setup-board."
      "$JQ" -e --arg p "$pid" '.github // {} | has($p)' "$cfg" >/dev/null 2>&1 || block "project '$pid' belum punya daftar status. Jalankan /setup-board."
      "$JQ" -e --arg p "$pid" --arg o "$opt" '.github[$p].allow // [] | map(tostring) | index($o) != null' "$cfg" >/dev/null 2>&1 ||
        block "status '$opt' tidak diizinkan untuk project $pid. Done hanya dipindah QA manusia.";;
    'issue update')
      [ "$forge" = glab ] || return 0
      for a in "${@:3}"; do
        case $prev in -l|--label) labels+=("$a");; esac
        case $a in --label=*) labels+=("${a#*=}");; esac
        prev=$a
      done
      [ ${#labels[@]} -gt 0 ] || return 0
      "$JQ" -e type "$cfg" >/dev/null 2>&1 || block "daftar status tiket tidak ada/rusak ($cfg). Jalankan /setup-board."
      for l in "${labels[@]}"; do
        IFS=, read -ra xs <<< "$l"
        for x in "${xs[@]}"; do
          "$JQ" -e --arg l "$x" '[.gitlab // {} | .[] | .allow // [] | .[]] | index($l) != null' "$cfg" >/dev/null 2>&1 ||
            block "label '$x' tidak ada di daftar status GitLab. Done hanya dipindah QA manusia."
        done
      done;;
  esac
  return 0
}

# transitionJiraIssue: only transition ids allowed for the project in jira-transitions.json
check_jira() {
  local cfg=$STATE/jira-transitions.json key id proj
  key=$(printf '%s' "$input" | "$JQ" -r '.tool_input.issueIdOrKey // empty' 2>/dev/null)
  id=$(printf '%s' "$input" | "$JQ" -r '.tool_input.transition.id // empty' 2>/dev/null)
  proj=$(printf '%s' "$key" | sed -E 's/-[0-9]+$//')
  "$JQ" -e type "$cfg" >/dev/null 2>&1 || block "config transisi Jira tidak ada/rusak ($cfg). Jalankan /setup-board."
  "$JQ" -e --arg p "$proj" 'has($p)' "$cfg" >/dev/null 2>&1 || block "project '$proj' belum punya daftar transisi. Jalankan /setup-board."
  "$JQ" -e --arg p "$proj" --arg i "$id" '.[$p].allow // [] | map(tostring) | index($i) != null' "$cfg" >/dev/null 2>&1 ||
    block "transisi id '$id' untuk $proj tidak diizinkan. Done hanya dipindah QA manusia."
}

# ---------- rm -r ----------
check_rm() {
  local rec='' endopt='' paths=() a bad
  for a; do
    if [ -z "$endopt" ]; then
      case $a in
        --) endopt=1; continue;;
        --recursive) rec=1; continue;;
        --*) continue;;
        -*[rR]*) rec=1; continue;;
        -*) continue;;
      esac
    fi
    paths+=("$(expand_home "$a")")
  done
  [ -n "$rec" ] || return 0
  [ -n "$AUDIT" ] && audit_block "rm -r"
  for a in ${paths[@]+"${paths[@]}"}; do
    case $a in *'$'*|*'`'*|'~'*|*'{}'*) block "rm -r dengan variabel/path tak pasti ('$a') dilarang. Tulis path literal.";; esac
  done
  [ ${#paths[@]} -gt 0 ] || block "rm -r tanpa path literal (mis. lewat xargs) dilarang."
  bad=$("$PY" -c '
import os, sys
c, root = sys.argv[1], os.path.realpath(sys.argv[2])
tmp = [os.path.realpath(p) + os.sep for p in ("/tmp/qa", os.path.join(os.environ.get("TMPDIR") or "/tmp", "qa"))]
for p in sys.argv[3:]:
    n = os.path.normpath(os.path.join(c, p))
    r = os.path.realpath(n) if p.endswith("/") else os.path.join(os.path.realpath(os.path.dirname(n)), os.path.basename(n))
    if not (r.startswith(root + os.sep) or any(r.startswith(t) for t in tmp)):
        print(p); break
' "$wd" "$root" "${paths[@]}" 2>/dev/null) || block "path rm -r tidak bisa diverifikasi (python3 gagal)."
  [ -z "$bad" ] || block "rm -r di luar proyek ($root) dilarang: '$bad'. Hanya path di dalam proyek atau isi /tmp/qa."
}

# ---------- devices (locks shared with the delivery workflow: ~/.agent-workflow/locks) ----------
lock_dir() { printf '%s/%s' "${AGENT_LOCK_DIR:-$HOME/.agent-workflow/locks}" "$(printf '%s' "$1" | sed 's/%/%25/g; s#/#%2F#g; s/:/%3A/g')"; }
ancestors() {
  [ -n "${ANC:-}" ] && return 0
  local p=$$
  for _ in 0 1 2 3 4 5 6 7 8; do
    ANC="$ANC $p"
    p=$(ps -o ppid= -p "$p" 2>/dev/null | tr -d ' ')
    [ -n "$p" ] && [ "$p" -gt 1 ] || break
  done
  ANC="$ANC "
}
check_lock() {
  local d p
  d=$(lock_dir "$1"); p=$(cat "$d/pid" 2>/dev/null)
  [ -n "$p" ] && kill -0 "$p" 2>/dev/null || return 0
  ancestors; [[ $ANC == *" $p "* ]] && return 0
  block "device $1 dikunci $(cat "$d/owner" 2>/dev/null). Tunggu atau tanya user (tools.md → Device)."
}
check_device() { # tool ANDROID_SERIAL args...
  local tool=$1 s=$2 mut='' n
  shift 2
  case $tool in
    adb)
      while [ $# -gt 0 ]; do
        case $1 in -s) s=${2:-}; shift;; -t|-H|-P|-L) shift;; -*) ;; *) break;; esac
        [ $# -gt 0 ] && shift
      done
      case ${1:-} in
        uninstall|install|install-multiple) mut=1;;
        shell) [[ " ${*:2} " == *" pm clear "* ]] && mut=1;;
      esac
      [ -n "$mut" ] || return 0
      if [ -z "$s" ]; then
        s=$("${ADB:-adb}" devices 2>/dev/null | awk '$2 == "device" {print $1}')
        n=$(printf '%s' "$s" | grep -c .)
        [ "$n" -eq 1 ] || block "adb $1 tanpa device pasti ($n device terhubung): tulis -s <serial>."
      fi
      check_lock "android:$s";;
    xcrun)
      [ "${1:-}" = simctl ] || return 0
      case ${2:-} in install|uninstall) s=${3:-};; *) return 0;; esac
      case $s in ''|booted|-*) block "xcrun simctl $2 tanpa udid pasti: tulis udid (bukan booted).";; esac
      check_lock "ios:$s";;
  esac
  return 0
}

# ---------- Bash ----------
TOKENIZER='
import json, re, shlex, sys
SEP = set("();<>|&\n")
def toks(c):
    c = re.sub(r"(?<!\\)((?:\\\\)*)\\\n", r"\1", c)
    try:
        l = shlex.shlex(c, posix=True, punctuation_chars="();<>|&\n")
        l.whitespace = " \t\r"
        l.whitespace_split = True; l.commenters = ""
        return list(l)
    except ValueError:
        return [t.strip("\"\x27") for t in re.findall(r"[();<>|&\n]+|[^\s();<>|&]+", c)]
def segs(c, depth=0):
    out, cur, prev = [], [], ""
    for t in toks(c):
        if t and all(ch in SEP for ch in t):
            out.append(cur); cur = []; prev = t; continue
        if not t.strip(): continue
        if depth < 3 and ("$(" in t or "`" in t or (re.search(r"\s", t) and (re.fullmatch(r"-\w*c", prev) or prev == "eval"))):
            out += segs(t.replace("`", " "), depth + 1)
        t = t.replace("`", "").replace("\n", " ").replace("\x1f", " ")
        cur.append(t)
        if t != "--": prev = t
    return out + [cur]
cmd = (json.load(sys.stdin).get("tool_input") or {}).get("command") or ""
for s in segs(cmd):
    if s: print("\x1f".join(s))
'

check_Bash() {
  local segs w i c t prev gsub es
  [ -n "$PY" ] || block "python3 tidak ditemukan, guard tidak bisa memeriksa perintah Bash."
  segs=$(printf '%s' "$input" | "$PY" -c "$TOKENIZER" 2>/dev/null) || block "perintah Bash tidak bisa diurai oleh guard."
  root=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null || echo "$cwd")
  wd=$cwd
  while IFS=$'\x1f' read -ra w; do
    gsub=-1; prev=''; es=''
    for ((i = 0; i < ${#w[@]}; i++)); do
      c=${w[$i]##*/}
      case $c in
        cd|pushd)
          case $prev in ''|'!'|'{'|then|do|else|if|while|until|command|builtin)
            t=$(expand_home "${w[$((i+1))]:-~}")
            case $t in *'$'*|-*) wd=/;; *) wd=$(join_path "$t" "$wd");; esac;;
          esac;;
        git) GSUB_OFF=-1; check_git "${w[@]:$((i+1))}"; gsub=$((i + 1 + GSUB_OFF));;
        gh|glab) check_forge "$c" "${w[@]:$((i+1))}";;
        rm) [ $i -eq $gsub ] || check_rm "${w[@]:$((i+1))}";;
        ANDROID_SERIAL=*) es=${w[$i]#*=};;
        adb|xcrun) check_device "$c" "$es" "${w[@]:$((i+1))}";;
      esac
      prev=${w[$i]}
    done
  done <<< "$segs"
}

# ---------- Edit/Write ----------
# Test automation + QA docs only, relative to the repo root. fnmatch: `*` also matches `/`.
DEFAULT_TEST_PATHS='docs/tickets/* docs/qa/* docs/rilis/* .maestro/* */.maestro/* maestro/* e2e/* */e2e/* tests/* */tests/* test/* */test/* */__tests__/* __tests__/* *.spec.* *.test.* *_test.* *Test.kt *Test.java *Tests.swift *UITests/* */androidTest/* playwright/* */playwright/* playwright.config.* */playwright.config.* cypress/* */cypress/* qa/* pact/* pacts/* */pacts/* contract-tests/* schemathesis/*'

check_edit() { # [path]
  local f=${1:-} rel
  [ -n "$f" ] || f=$(printf '%s' "$input" | "$JQ" -r '.tool_input.file_path // .tool_input.notebook_path // .tool_input.path // .tool_input.filePath // empty' 2>/dev/null)
  [ -n "$f" ] || return 0
  [ -n "$PY" ] || block "python3 tidak ditemukan, guard tidak bisa memeriksa path."
  f=$(join_path "$(expand_home "$f")" "$cwd")
  rel=$(QA_PATHS="$DEFAULT_TEST_PATHS" EXTRA="$STATE/qa-test-paths.txt" AUDIT="$AUDIT" "$PY" -c '
import fnmatch, os, subprocess, sys
f = os.path.realpath(sys.argv[1])
tmp = [os.path.realpath(p) for p in ("/tmp/qa", os.path.join(os.environ.get("TMPDIR") or "/tmp", "qa"))]
if os.environ.get("AUDIT"):
    ok = any(f.startswith(os.path.join(t, "audit") + os.sep) for t in tmp)
    print("" if ok else "AUDIT:" + f); sys.exit(0)
d = os.path.dirname(f)
while d != "/" and not os.path.isdir(d):
    d = os.path.dirname(d)
r = subprocess.run(["git", "-C", d, "rev-parse", "--show-toplevel"], capture_output=True, text=True)
if r.returncode != 0:
    sys.exit(0)  # outside any git repo: work files are free
root = os.path.realpath(r.stdout.strip())
rel = os.path.relpath(f, root)
pats = os.environ["QA_PATHS"].split()
try:
    pats += [l.strip() for l in open(os.environ["EXTRA"]) if l.strip() and not l.startswith("#")]
except OSError:
    pass
if not any(fnmatch.fnmatchcase(rel, p) for p in pats):
    print(rel)
' "$f" 2>/dev/null) || block "path tidak bisa diverifikasi (python3 gagal)."
  case $rel in
    '') return 0;;
    AUDIT:*) audit_block "edit file di luar folder kerja audit ${TMPDIR:-/tmp}/qa/audit/ (${rel#AUDIT:})";;
    *) block "edit '$rel' dilarang: QA tidak menulis kode produk. Yang boleh: kode otomasi uji (e2e/, tests/, .maestro/, *.spec.*, ...) dan dokumen QA (docs/tickets/, docs/qa/, docs/rilis/). Tambahan pola per komputer: $STATE/qa-test-paths.txt.";;
  esac
}

check_patch() {
  local f
  while IFS= read -r f; do
    [ -n "$f" ] && check_edit "$f"
  done < <(printf '%s' "$input" | "$JQ" -r '.tool_input.command // .tool_input.patch // empty' 2>/dev/null |
    sed -nE 's/^\*\*\* (Add|Update|Delete) File: (.+)$/\2/p; s/^\*\*\* Move to: (.+)$/\1/p')
  return 0
}

# ---------- main ----------
input=$(cat)
tool=$(printf '%s' "$input" | "$JQ" -r '.tool_name // empty' 2>/dev/null) || exit 0
cwd=$(printf '%s' "$input" | "$JQ" -r '.cwd // empty' 2>/dev/null)
[ -n "$cwd" ] || cwd=$PWD

detect_modes
[ -n "$QA" ] || exit 0

case $tool in
  run_shell_command|Shell|shell|bash) tool=Bash;;
  write_file|replace|Delete|edit|write) tool=Edit;;
esac

case $tool in
  Bash) check_Bash;;
  Edit|Write|MultiEdit|NotebookEdit) check_edit;;
  apply_patch) check_patch;;
  mcp__claude_ai_Atlassian__*|mcp__*Atlassian*__*)
    if [ -n "$AUDIT" ]; then
      case $tool in *__create*|*__edit*|*__add*|*__update*|*__transition*|*__executeWrite|*__executeDestructive) audit_block "$tool";; esac
    fi
    case $tool in *__transitionJiraIssue) check_jira;; esac;;
esac
exit 0
