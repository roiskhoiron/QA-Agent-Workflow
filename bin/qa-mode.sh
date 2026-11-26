#!/usr/bin/env bash
# Usage: qa-mode.sh <qa|blind|audit> on|off|status
# Marks the calling agent session for hooks/qa-guard.sh:
#   qa    = QA rules on (only test-automation/QA docs editable, push only qa/<KODE> to origin, no merge/approve)
#   blind = also block commands that reveal the diff (test cases are designed without reading the change)
#   audit = read-only (/audit-issue)
# Marker = ${AGENT_WORKFLOW_STATE:-$HOME/.agent-workflow}/qa-mode/<mode>/<pid>, pid = AGENT_LOCK_PID
# (default $PPID): call as `AGENT_LOCK_PID=$PPID qa-mode.sh qa on`. Markers of dead pids are pruned.
mode=${1:-} op=${2:-}
case $mode in qa|blind|audit) ;; *) echo "usage: $0 <qa|blind|audit> on|off|status" >&2; exit 2;; esac
base=${AGENT_WORKFLOW_STATE:-$HOME/.agent-workflow}/qa-mode/$mode
pid=${AGENT_LOCK_PID:-$PPID}
case $op in
  on)
    mkdir -p "$base"
    for f in "$base"/*; do
      [ -e "$f" ] || continue
      p=${f##*/}; case $p in session-*) p=$(cat "$f");; esac   # session-<id> holds the SPV pid (qa-guard.sh)
      kill -0 "$p" 2>/dev/null || rm -f "$f"
    done
    : > "$base/$pid" ;;
  off) rm -f "$base/$pid" ;;
  status) if [ -f "$base/$pid" ]; then echo on; else echo off; exit 1; fi ;;
  *) echo "usage: $0 <qa|blind|audit> on|off|status" >&2; exit 2 ;;
esac
