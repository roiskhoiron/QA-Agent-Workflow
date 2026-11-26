#!/usr/bin/env bash
# bin/qa-mode.sh: penanda mode qa/blind/audit per pid, penanda pid mati dibersihkan.
source "$(dirname "$0")/lib.sh"
REPO="$(cd "$(dirname "$0")/.." && pwd -P)"
A="$REPO/bin/qa-mode.sh"
export AGENT_WORKFLOW_STATE=$(mktemp -d); trap 'rm -rf "$AGENT_WORKFLOW_STATE"' EXIT
M="$AGENT_WORKFLOW_STATE/qa-mode"
for m in qa blind audit; do
  AGENT_LOCK_PID=$$ "$A" $m on
  assert_eq yes "$([ -f "$M/$m/$$" ] && echo yes || echo no)" "$m on membuat penanda"
  assert_eq on "$(AGENT_LOCK_PID=$$ "$A" $m status)" "$m status on"
  AGENT_LOCK_PID=$$ "$A" $m off
  assert_exit 1 "$m status exit 1 saat off" -- env AGENT_LOCK_PID=$$ "$A" $m status
done
mkdir -p "$M/qa"; touch "$M/qa/999999"; echo 999999 > "$M/qa/session-dead"; echo $$ > "$M/qa/session-live"
AGENT_LOCK_PID=$$ "$A" qa on
assert_eq no "$([ -f "$M/qa/999999" ] && echo yes || echo no)" "penanda pid mati dibersihkan"
assert_eq no "$([ -f "$M/qa/session-dead" ] && echo yes || echo no)" "session pid mati dibersihkan"
assert_eq yes "$([ -f "$M/qa/session-live" ] && echo yes || echo no)" "session pid hidup tetap"
assert_exit 2 "mode tidak dikenal → exit 2" -- "$A" nope on
assert_exit 2 "operasi tidak dikenal → exit 2" -- "$A" qa nope
exit $FAILS
