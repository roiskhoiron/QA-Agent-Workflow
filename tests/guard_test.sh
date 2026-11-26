#!/usr/bin/env bash
# hooks/qa-guard.sh: dorman di luar mode QA; pagar QA, mode buta, dan mode audit.
source "$(dirname "$0")/lib.sh"
REPO="$(cd "$(dirname "$0")/.." && pwd -P)"
G="$REPO/hooks/qa-guard.sh"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
export AGENT_WORKFLOW_STATE="$T/state" AGENT_LOCK_DIR="$T/locks" HOME="$T/home"
mkdir -p "$AGENT_WORKFLOW_STATE" "$HOME"
unset QA_AGENT_WORKFLOW QA_AGENT_BLIND QA_AGENT_AUDIT

# repo with an upstream, a fork (origin) and a sibling worktree
P="$T/proj/app"; mkdir -p "$P"; git init -q "$P"
git -C "$P" -c user.name=t -c user.email=t@t commit -q --allow-empty -m init
git -C "$P" remote add origin https://example.com/fork/app.git
git -C "$P" remote add upstream https://example.com/main/app.git
git -C "$P" checkout -q -b qa/PROJ-1

bash_json() { jq -cn --arg c "$1" --arg d "${2:-$P}" '{tool_name:"Bash",tool_input:{command:$c},cwd:$d,session_id:"s1"}'; }
edit_json() { jq -cn --arg f "$1" --arg d "$P" '{tool_name:"Write",tool_input:{file_path:$f},cwd:$d}'; }
run() { printf '%s' "$1" | "$G" >/dev/null 2>&1; echo $?; }   # exit code of guard
qa() { QA_AGENT_WORKFLOW=1 run "$1"; }
blind() { QA_AGENT_BLIND=1 run "$1"; }
audit() { QA_AGENT_AUDIT=1 run "$1"; }

# ---- dorman di luar mode QA (sesi Coder workflow delivery tidak terganggu) ----
assert_eq 0 "$(run "$(edit_json "$P/src/Main.kt")")" "dorman: edit kode produk lolos"
assert_eq 0 "$(run "$(bash_json 'git push upstream main')")" "dorman: push apa pun tidak diperiksa"

# ---- edit hanya otomasi uji + dokumen QA ----
assert_eq 2 "$(qa "$(edit_json "$P/src/Main.kt")")" "QA: edit kode produk diblokir"
assert_eq 2 "$(qa "$(edit_json "$P/README.md")")" "QA: edit README diblokir"
assert_eq 2 "$(qa "$(edit_json "$P/docs/architecture.md")")" "QA: docs non-QA diblokir"
for f in docs/tickets/PROJ-1/qa.md docs/qa/regresi/login.md docs/rilis/v1.2.0-qa.md .maestro/login.yaml e2e/login.spec.ts \
         app/src/androidTest/LoginTest.kt web/src/cart.test.tsx tests/api/test_cart.py AppUITests/LoginTests.swift playwright.config.ts; do
  assert_eq 0 "$(qa "$(edit_json "$P/$f")")" "QA: boleh edit $f"
done
assert_eq 0 "$(qa "$(edit_json "$T/work/qa.md")")" "QA: berkas di luar repo git bebas"
echo 'src/fixtures/*' > "$AGENT_WORKFLOW_STATE/qa-test-paths.txt"
assert_eq 0 "$(qa "$(edit_json "$P/src/fixtures/user.json")")" "QA: pola tambahan qa-test-paths.txt"
rm "$AGENT_WORKFLOW_STATE/qa-test-paths.txt"
patch=$'*** Begin Patch\n*** Update File: src/Main.kt\n@@\n-a\n+b\n*** End Patch'
assert_eq 2 "$(QA_AGENT_WORKFLOW=1 run "$(jq -cn --arg c "$patch" --arg d "$P" '{tool_name:"apply_patch",tool_input:{command:$c},cwd:$d}')")" "QA: apply_patch ke kode produk diblokir"
assert_eq 2 "$(QA_AGENT_WORKFLOW=1 run "$(jq -cn --arg f "$P/src/a.kt" --arg d "$P" '{tool_name:"write_file",tool_input:{file_path:$f},cwd:$d}')")" "QA: nama tool Gemini dinormalkan"

# ---- push ----
assert_eq 0 "$(qa "$(bash_json 'git push origin qa/PROJ-1')")" "push qa/<KODE> ke origin boleh"
assert_eq 0 "$(qa "$(bash_json 'git push -u origin HEAD')")" "push HEAD di branch qa/ boleh"
assert_eq 2 "$(qa "$(bash_json 'git push upstream qa/PROJ-1')")" "push ke upstream diblokir"
assert_eq 2 "$(qa "$(bash_json 'git push origin feature/PROJ-1')")" "push branch selain qa/ diblokir"
assert_eq 2 "$(qa "$(bash_json 'git push --force origin qa/PROJ-1')")" "force-push diblokir"
assert_eq 2 "$(qa "$(bash_json 'git push origin +qa/PROJ-1')")" "force lewat + diblokir"
assert_eq 2 "$(qa "$(bash_json 'git push origin :qa/PROJ-1')")" "hapus branch diblokir"
assert_eq 2 "$(qa "$(bash_json 'git push origin v1.2.0')")" "push tag diblokir"
assert_eq 2 "$(qa "$(bash_json 'git push --tags origin')")" "push --tags diblokir"
assert_eq 2 "$(qa "$(bash_json 'cd /tmp && git -C '"$P"' push upstream qa/PROJ-1')")" "push lewat -C tetap diperiksa"
assert_eq 2 "$(qa "$(bash_json 'echo ok; sh -c "git push upstream qa/PROJ-1"')")" "push di dalam sh -c diperiksa"

# ---- merge / approve / tutup issue ----
assert_eq 2 "$(qa "$(bash_json 'gh pr merge 12 --squash')")" "gh pr merge diblokir"
assert_eq 2 "$(qa "$(bash_json 'glab mr merge 12')")" "glab mr merge diblokir"
assert_eq 2 "$(qa "$(bash_json 'gh pr review 12 --approve')")" "gh pr review --approve diblokir"
assert_eq 0 "$(qa "$(bash_json 'gh pr review 12 --comment --body x')")" "gh pr review --comment boleh"
assert_eq 2 "$(qa "$(bash_json 'glab mr approve 12')")" "glab mr approve diblokir"
assert_eq 2 "$(qa "$(bash_json 'gh issue close 7')")" "gh issue close diblokir"
assert_eq 0 "$(qa "$(bash_json 'gh issue comment 7 --body hasil')")" "komentar issue boleh"

# ---- status tiket ----
echo '{"PROJ":{"allow":["21","41"]}}' > "$AGENT_WORKFLOW_STATE/jira-transitions.json"
jira() { jq -cn --arg k "$1" --arg i "$2" '{tool_name:"mcp__claude_ai_Atlassian__transitionJiraIssue",tool_input:{issueIdOrKey:$k,transition:{id:$i}}}'; }
assert_eq 0 "$(qa "$(jira PROJ-1 41)")" "Jira: In Testing (diizinkan) boleh"
assert_eq 2 "$(qa "$(jira PROJ-1 51)")" "Jira: Done (tidak diizinkan) diblokir"
assert_eq 2 "$(qa "$(jira OTHER-1 21)")" "Jira: project tanpa daftar diblokir"
echo '{"github":{"PVT_1":{"allow":["opt_prog"]}},"gitlab":{"g/r":{"allow":["status::in-progress"]}}}' > "$AGENT_WORKFLOW_STATE/ticket-status.json"
assert_eq 0 "$(qa "$(bash_json 'gh project item-edit --project-id PVT_1 --id I --field-id F --single-select-option-id opt_prog')")" "GitHub: status diizinkan boleh"
assert_eq 2 "$(qa "$(bash_json 'gh project item-edit --project-id PVT_1 --id I --field-id F --single-select-option-id opt_done')")" "GitHub: status Done diblokir"
assert_eq 2 "$(qa "$(bash_json 'glab issue update 3 --label status::done')")" "GitLab: label Done diblokir"
assert_eq 0 "$(qa "$(bash_json 'glab issue update 3 --label status::in-progress')")" "GitLab: label diizinkan boleh"

# ---- rm -r dan worktree ----
assert_eq 0 "$(qa "$(bash_json "rm -rf $P/build")")" "rm -r di dalam project boleh"
assert_eq 0 "$(qa "$(bash_json 'rm -rf /tmp/qa/PROJ-1')")" "rm -r isi /tmp/qa boleh"
assert_eq 2 "$(qa "$(bash_json 'rm -rf /etc/x')")" "rm -r di luar project diblokir"
assert_eq 0 "$(qa "$(bash_json 'git worktree add ../app-qa-1 -b qa/PROJ-2 upstream/develop')")" "worktree QA sejajar boleh"
assert_eq 2 "$(qa "$(bash_json 'git worktree add /tmp/elsewhere -b qa/PROJ-2')")" "worktree di luar folder sejajar diblokir"
assert_eq 2 "$(qa "$(bash_json 'git worktree remove ../app-1234')")" "hapus worktree bukan milik QA diblokir"
assert_eq 2 "$(qa "$(bash_json 'git worktree remove --force ../app-qa-1')")" "worktree remove --force diblokir"
assert_eq 0 "$(qa "$(bash_json 'git worktree remove ../app-qa-1')")" "hapus worktree QA boleh"
assert_eq 0 "$(qa "$(bash_json 'git worktree remove ../app-qa-rilis-v1.2.0')")" "hapus worktree rekomendasi rilis boleh"

# ---- device lock bersama ----
mkdir -p "$AGENT_LOCK_DIR/android%3Aemulator-5554"; sleep 300 & holder=$!
echo $holder > "$AGENT_LOCK_DIR/android%3Aemulator-5554/pid"; echo PROJ-9-qa1 > "$AGENT_LOCK_DIR/android%3Aemulator-5554/owner"
assert_eq 2 "$(qa "$(bash_json 'adb -s emulator-5554 uninstall com.app')")" "uninstall di device milik agen lain diblokir"
assert_eq 0 "$(qa "$(bash_json 'adb -s emulator-5554 logcat -d')")" "baca log device lain boleh"
kill $holder 2>/dev/null
assert_eq 0 "$(qa "$(bash_json 'adb -s emulator-5554 uninstall com.app')")" "kunci basi (pid mati) dianggap bebas"

# ---- mode buta ----
assert_eq 2 "$(blind "$(bash_json 'git diff upstream/develop...origin/feature/PROJ-1')")" "buta: git diff diblokir"
assert_eq 0 "$(blind "$(bash_json 'git diff --name-only upstream/develop...HEAD')")" "buta: git diff --name-only boleh"
assert_eq 2 "$(blind "$(bash_json 'git show abc123')")" "buta: git show commit diblokir"
assert_eq 0 "$(blind "$(bash_json 'git show --stat abc123')")" "buta: git show --stat boleh"
assert_eq 0 "$(blind "$(bash_json 'git show upstream/develop:openapi.yaml')")" "buta: git show ref:path (contract) boleh"
assert_eq 2 "$(blind "$(bash_json 'git log -p -3')")" "buta: git log -p diblokir"
assert_eq 0 "$(blind "$(bash_json 'git log --oneline -5')")" "buta: git log ringkas boleh"
assert_eq 2 "$(blind "$(bash_json 'gh pr diff 12')")" "buta: gh pr diff diblokir"
assert_eq 2 "$(blind "$(bash_json 'glab mr diff 12')")" "buta: glab mr diff diblokir"
assert_eq 0 "$(blind "$(bash_json 'gh pr view 12 --json headRefOid')")" "buta: metadata PR boleh"
assert_eq 0 "$(qa "$(bash_json 'gh pr diff 12')")" "tanpa mode buta: gh pr diff boleh"

# ---- mode audit ----
assert_eq 2 "$(audit "$(bash_json 'git commit -m x')")" "audit: commit diblokir"
assert_eq 2 "$(audit "$(bash_json 'git checkout -b x')")" "audit: checkout diblokir"
assert_eq 0 "$(audit "$(bash_json 'git log --oneline')")" "audit: git log boleh"
assert_eq 2 "$(audit "$(bash_json 'gh issue comment 7 --body x')")" "audit: komentar issue diblokir"
assert_eq 2 "$(audit "$(bash_json 'gh issue create --title x')")" "audit: buat issue diblokir"
assert_eq 0 "$(audit "$(bash_json 'gh issue view 7')")" "audit: baca issue boleh"
assert_eq 2 "$(audit "$(jq -cn '{tool_name:"mcp__claude_ai_Atlassian__addCommentToJiraIssue",tool_input:{}}')")" "audit: komentar Jira diblokir"
assert_eq 0 "$(audit "$(jq -cn '{tool_name:"mcp__claude_ai_Atlassian__getJiraIssue",tool_input:{}}')")" "audit: baca Jira boleh"
assert_eq 2 "$(audit "$(edit_json "$P/e2e/a.spec.ts")")" "audit: edit di repo (walau otomasi uji) diblokir"
assert_eq 0 "$(TMPDIR=$T audit "$(edit_json "$T/qa/audit/s/laporan.md")")" "audit: folder kerja audit boleh"

# ---- penanda qa-mode.sh: pid leluhur & teammate ----
M="$AGENT_WORKFLOW_STATE/qa-mode"
AGENT_LOCK_PID=$$ "$REPO/bin/qa-mode.sh" qa on
assert_eq 2 "$(run "$(edit_json "$P/src/Main.kt")")" "penanda qa pada pid leluhur mengaktifkan guard"
run "$(bash_json 'true')" >/dev/null
assert_eq "$$" "$(cat "$M/qa/session-s1" 2>/dev/null)" "guard mencatat session lead → pid"
AGENT_LOCK_PID=$$ "$REPO/bin/qa-mode.sh" blind on
assert_eq 2 "$(run "$(bash_json 'git diff HEAD~1')")" "penanda blind aktif"
AGENT_LOCK_PID=$$ "$REPO/bin/qa-mode.sh" blind off
AGENT_LOCK_PID=$$ "$REPO/bin/qa-mode.sh" qa off
assert_eq 0 "$(run "$(edit_json "$P/src/Main.kt")")" "qa off → dorman lagi"
# teammate: bukan turunan SPV, tapi Claude-nya jalan dengan --parent-session-id <session SPV>
sleep 300 & lead=$!
mkdir -p "$M/qa"; : > "$M/qa/$lead"; echo "$lead" > "$M/qa/session-lead1"
as_teammate() { printf '%s' "$1" | python3 -c 'import subprocess,sys; sys.exit(subprocess.run([sys.argv[1]]).returncode)' "$G" --parent-session-id lead1 --x >/dev/null 2>&1; echo $?; }
assert_eq 2 "$(as_teammate "$(edit_json "$P/src/Main.kt")")" "teammate mewarisi mode QA dari SPV"
rm -f "$M/qa/$lead"
assert_eq 0 "$(as_teammate "$(edit_json "$P/src/Main.kt")")" "SPV mode off → teammate dorman"
kill $lead 2>/dev/null
exit $FAILS
