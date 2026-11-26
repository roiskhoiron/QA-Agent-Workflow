#!/usr/bin/env bash
# install.sh: tiap coding agent dapat skill, agen, hook qa-guard, instruksi; idempotent; berdampingan dengan workflow lain.
source "$(dirname "$0")/lib.sh"
REPO="$(cd "$(dirname "$0")/.." && pwd -P)"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
is_link() { [ -L "$1" ] && echo yes || echo no; }
qa_n() { jq --arg ev "$2" '[.hooks[$ev][]? | select(any(.hooks[]?; .command|test("qa-guard.sh")))] | length' "$1"; }
I=(bash "$REPO/install.sh")

# ---- global, semua agen; workflow delivery (guard.sh) sudah terpasang ----
H="$T/home"; mkdir -p "$H/.claude" "$H/.gemini"
jq -n '{hooks:{PreToolUse:[{matcher:"Bash",hooks:[{type:"command",command:"\"/x/mobiledev/hooks/guard.sh\""}]}]}}' > "$H/.claude/settings.json"
echo '{"theme":"x"}' > "$H/.gemini/settings.json"
assert_exit 0 "global all run 1" -- "${I[@]}" --home "$H" --agent all --scope global
assert_exit 0 "global all run 2 (idempotent)" -- "${I[@]}" --home "$H" --agent all --scope global
S="$H/.claude/settings.json"
assert_eq "$REPO" "$(cd "$H/.agent-workflow/qa-repo" && pwd -P)" "jangkar ~/.agent-workflow/qa-repo"
assert_eq yes "$(is_link "$H/.claude/skills/develop-tiket")" "claude: skill flow"
assert_eq yes "$(is_link "$H/.claude/skills/design-tests")" "claude: skill internal"
assert_eq yes "$(is_link "$H/.claude/skills/_qa-agent-workflow-shared")" "claude: shared"
assert_eq yes "$(is_link "$H/.claude/agents/qa-tester.md")" "claude: agen berawalan qa-"
assert_eq 1 "$(qa_n "$S" PreToolUse)" "claude: qa-guard sekali"
assert_eq 1 "$(jq '[.hooks.PreToolUse[]|select(.hooks[0].command|test("/guard.sh"))]|length' "$S")" "claude: guard.sh workflow lain tetap ada"
assert_eq "\"$REPO/hooks/qa-guard.sh\"" "$(jq -r '.hooks.PreToolUse[]|select(.hooks[0].command|test("qa-guard"))|.hooks[0].command' "$S")" "claude: path guard dikutip"
assert_eq null "$(jq -r '.env.QA_AGENT_WORKFLOW' "$S")" "global: pagar QA tidak selalu aktif"
assert_eq 1 "$(grep -c '^# QA agent workflow' "$H/.claude/CLAUDE.md")" "claude: instruksi sekali"
assert_eq yes "$(is_link "$H/.agents/skills/retest-fix")" "codex skill"
assert_eq no "$(is_link "$H/.agents/skills/_qa-agent-workflow-shared")" "codex: _shared bukan skill"
assert_eq 1 "$(qa_n "$H/.codex/hooks.json" PreToolUse)" "codex hook sekali"
assert_eq 1 "$(qa_n "$H/.gemini/settings.json" BeforeTool)" "gemini hook sekali"
assert_eq x "$(jq -r .theme "$H/.gemini/settings.json")" "gemini setting lain tetap"
assert_eq 1 "$(jq '[.hooks.preToolUse[]|select(.command|test("qa-guard.sh"))]|length' "$H/.cursor/hooks.json")" "cursor hook sekali"
assert_eq yes "$(grep -q "$REPO/hooks/qa-guard.sh" "$H/.config/opencode/plugins/qa-agent-workflow-guard.js" && echo yes || echo no)" "opencode plugin menunjuk qa-guard"
c=$(jq -r '.hooks.PreToolUse[]|select(.hooks[0].command|test("qa-guard"))|.hooks[0].command' "$S")
assert_eq 0 "$(echo '{"tool_name":"Read"}' | sh -c "$c" >/dev/null 2>&1; echo $?)" "hook command jalan lewat shell"

# ---- bentrok nama skill dengan workflow lain ----
H2="$T/home2"; mkdir -p "$H2/.claude/skills" "$T/mobile/skills/validate-tiket"
ln -s "$T/mobile/skills/validate-tiket" "$H2/.claude/skills/validate-tiket"
assert_exit 2 "skill milik workflow lain tidak ditimpa diam-diam" -- "${I[@]}" --home "$H2" --agent claude
assert_eq "$T/mobile/skills/validate-tiket" "$(readlink "$H2/.claude/skills/validate-tiket")" "skill workflow lain tetap utuh"
assert_exit 0 "--force menimpa" -- "${I[@]}" --home "$H2" --agent claude --force
assert_eq "$REPO/skills/validate-tiket" "$(readlink "$H2/.claude/skills/validate-tiket")" "--force: skill QA terpasang"

# ---- project scope ----
P="$T/proj"; git init -q "$P"; echo "# Tim" > "$P/AGENTS.md"; git -C "$P" add AGENTS.md
H3="$T/home3"; mkdir -p "$H3"
assert_exit 0 "project run 1" -- "${I[@]}" --home "$H3" --agent claude,codex,cursor,opencode,gemini --scope project --project "$P"
assert_exit 0 "project run 2" -- "${I[@]}" --home "$H3" --agent claude,codex,cursor,opencode,gemini --scope project --project "$P"
assert_eq yes "$(is_link "$P/.claude/skills/develop-tiket")" "project claude skill"
assert_eq 1 "$(qa_n "$P/.claude/settings.local.json" PreToolUse)" "project: hook di settings.local.json"
assert_eq 1 "$(jq -r '.env.QA_AGENT_WORKFLOW' "$P/.claude/settings.local.json")" "project: pagar QA selalu aktif"
assert_eq no "$([ -e "$P/.claude/settings.json" ] && echo yes || echo no)" "project: settings.json tim tidak disentuh"
assert_eq 1 "$(grep -c '^# QA agent workflow' "$P/AGENTS.md")" "AGENTS.md: blok sekali walau codex+opencode"
assert_eq no "$([ -e "$H3/.claude" ] && echo yes || echo no)" "project scope tidak menyentuh ~/.claude"
untracked=$(git -C "$P" status --porcelain --untracked-files=all | grep -v ' AGENTS.md$\| GEMINI.md$' || true)
assert_eq "" "$untracked" "project: file buatan installer di-exclude"

# ---- argumen salah ----
assert_exit 2 "agen tidak dikenal" -- "${I[@]}" --home "$T/h4" --agent vim
assert_exit 2 "scope salah" -- "${I[@]}" --home "$T/h4" --scope semua
assert_exit 2 "project = repo workflow" -- "${I[@]}" --home "$T/h4" --scope project --project "$REPO"

# ---- opencode plugin meneruskan ke guard (butuh node) ----
if command -v node >/dev/null; then
  G="$T/g"; git init -q "$G"
  cp "$H/.config/opencode/plugins/qa-agent-workflow-guard.js" "$T/p.mjs"
  r=$(cd "$T" && QA_AGENT_WORKFLOW=1 node --input-type=module -e "
    const { QaAgentWorkflowGuard } = await import('./p.mjs');
    const h = (await QaAgentWorkflowGuard({ directory: '$G' }))['tool.execute.before'];
    const out = [];
    for (const [tool, args] of [['bash',{command:'gh pr merge 1'}],['edit',{filePath:'$G/src/a.kt'}],['edit',{filePath:'$G/e2e/a.spec.ts'}],['read',{filePath:'$G/a'}]]) {
      try { await h({ tool }, { args }); out.push('allow'); } catch { out.push('block'); }
    }
    console.log(out.join(','));" 2>/dev/null)
  assert_eq "block,block,allow,allow" "$r" "opencode plugin: merge & kode produk diblokir"
fi
exit $FAILS
