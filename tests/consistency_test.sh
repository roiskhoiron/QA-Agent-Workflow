#!/usr/bin/env bash
# Agen, skill, dan rujukan antar-berkas konsisten; tidak ada identitas pribadi.
source "$(dirname "$0")/lib.sh"
REPO="$(cd "$(dirname "$0")/.." && pwd -P)"
fm() { awk -v k="$2" 'NR==1&&$0!="---"{exit} NR>1&&$0=="---"{exit} NR>1&&index($0,k": ")==1{print substr($0,length(k)+3)}' "$1"; }
yn() { "$@" && echo yes || echo no; }

# ---- agen ----
for pair in qa-spv:opus qa-validator:opus qa-planner:claude-fable-5-2 qa-tester:opus qa-reviewer:opus qa-release:haiku \
            qa-pdm:sonnet qa-contract-runner:sonnet qa-pjm:sonnet qa-auditor:opus qa-analis:opus; do
  n=${pair%%:*} m=${pair#*:} f="$REPO/agents/$n.md"
  assert_eq yes "$(yn [ -f "$f" ])" "agents/$n.md ada"
  [ -f "$f" ] || continue
  assert_eq "$n" "$(fm "$f" name)" "$n: name = nama berkas"
  assert_eq "$m" "$(fm "$f" model)" "$n: model"
  assert_eq yes "$(yn [ -n "$(fm "$f" description)" ])" "$n: description"
  tools=$(fm "$f" tools)
  if [ "$n" = qa-tester ]; then
    assert_eq no "$(yn grep -qE 'mcp__|Atlassian|Docs' <<< "$tools")" "qa-tester: tanpa tool MCP (tidak menyentuh tiket/dokumen)"
    assert_eq yes "$(yn [ -n "$tools" ])" "qa-tester: tools eksplisit"
  else
    assert_eq "" "$tools" "$n: mewarisi semua tool"
  fi
done
assert_eq 11 "$(ls "$REPO"/agents/*.md | wc -l | tr -d ' ')" "tepat 11 agen"

# ---- skill ----
FLOW="validate-tiket develop-tiket rilis-tiket branch-manager audit-issue"
MAP=$(sed -n '/^## Skill flow dan skill set/,/^## /p' "$REPO/skills/_shared/rules.md")
for d in "$REPO"/skills/*/; do
  n=$(basename "$d"); [ "$n" = _shared ] && continue
  f="$d/SKILL.md"
  assert_eq "$n" "$(fm "$f" name)" "skill $n: name = folder"
  assert_eq yes "$(yn [ -n "$(fm "$f" description)" ])" "skill $n: description"
  case " $FLOW " in
    *" $n "*) assert_eq yes "$(yn grep -qF "\`/$n" <<< "$MAP")" "skill flow /$n ada di peta rules.md" ;;
    *) assert_eq yes "$(yn grep -qF "\`$n\`" <<< "$MAP")" "skill internal $n ada di peta rules.md"
  esac
done
for s in $(grep -oE '`[a-z]+(-[a-z]+)+`' <<< "$MAP" | tr -d '`' | sort -u); do
  assert_eq yes "$(yn [ -f "$REPO/skills/$s/SKILL.md" ])" "peta rules.md: skill $s ada"
done
# flow skill memakai semua skill set-nya (urutan di peta = isi flow)
for fl in validate-tiket develop-tiket; do
  row=$(grep -F "\`/$fl\`" <<< "$MAP" | head -1 | cut -d'|' -f3)
  for s in $(grep -oE '`[a-z-]+`' <<< "$row" | tr -d '`'); do
    assert_eq yes "$(yn grep -qF "$s" "$REPO/skills/$fl/SKILL.md")" "/$fl menjalankan $s"
  done
done

# ---- rujukan berkas ----
files=$(ls "$REPO"/agents/*.md "$REPO"/skills/*/*.md)
for r in $(cat $files | grep -oE 'agents/qa-[a-z-]+\.md' | sort -u); do
  assert_eq yes "$(yn [ -f "$REPO/$r" ])" "rujukan $r ada"
done
for r in $(cat $files | grep -oE 'QA_WORKFLOW_DIR/bin/[A-Za-z0-9_.-]+' | sort -u); do
  assert_eq yes "$(yn [ -f "$REPO/bin/${r##*/}" ])" "rujukan $r ada"
done
for r in $(cat $files | grep -oE 'templates/[a-z.-]+\.(md|properties)' | sort -u); do
  assert_eq yes "$(yn [ -f "$REPO/$r" ])" "rujukan $r ada"
done
for r in $(cat $files | grep -oE '_shared/[a-z-]+\.md' | sort -u); do
  assert_eq yes "$(yn [ -f "$REPO/skills/$r" ])" "rujukan $r ada"
done
for r in $(cat $files | grep -oE 'skill `[a-z-]+`' | sed 's/skill `//; s/`//' | sort -u); do
  assert_eq yes "$(yn [ -f "$REPO/skills/$r/SKILL.md" ])" "rujukan skill $r ada"
done
assert_eq "" "$(grep -l 'AGENT_WORKFLOW_DIR/bin\|agent-workflow/repo/skills' $files)" "tidak memakai path workflow Mobile untuk berkas QA"

# ---- repo publik: tanpa identitas pribadi ----
assert_eq "" "$(git -C "$REPO" grep -lE '/Users/[a-z]|@gmail' -- . ':!tests/' 2>/dev/null)" "tanpa path/email pribadi"
if [ -f "$REPO/.private-denylist" ]; then
  assert_eq "" "$(git -C "$REPO" grep -lwFf <(grep -v '^[[:space:]]*$' "$REPO/.private-denylist") -- . ':!.private-denylist' 2>/dev/null)" "tanpa kata dari .private-denylist"
fi
exit $FAILS
