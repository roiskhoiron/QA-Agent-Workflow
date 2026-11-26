#!/usr/bin/env bash
# README + docs/*.md = pintu masuk pemula: setiap perintah, skill internal, dan skrip bin/ disebut.
source "$(dirname "$0")/lib.sh"
REPO="$(cd "$(dirname "$0")/.." && pwd -P)"
R="$REPO/README.md"
mentioned() { cat "$R" "$REPO"/docs/*.md | grep -qF -- "$1" && echo yes || echo no; }
for l in $(grep -oE '\(docs/[a-z-]+\.md\)' "$R" | tr -d '()' | sort -u); do
  assert_eq yes "$([ -f "$REPO/$l" ] && echo yes || echo no)" "link $l ada"
done
for d in "$REPO"/skills/*/; do
  n=$(basename "$d"); [ "$n" = _shared ] && continue
  assert_eq yes "$(mentioned "/$n")" "/$n disebut di README/docs"
done
for f in "$REPO"/bin/*; do
  assert_eq yes "$(mentioned "$(basename "$f")")" "skrip $(basename "$f") disebut di README/docs"
done
exit $FAILS
