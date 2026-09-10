#!/usr/bin/env bash
# File: scripts/tests/test-session-loop-notify.sh
# Purpose: session-loop-notify.sh contract — the message always reaches stdout
#          (that is what lands in the supervisor's log), desktop notifiers are
#          best-effort, and quoting in the message can't break the osascript
#          expression.
set -u
SRC_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
SLN="$SRC_ROOT/scripts/session-loop-notify.sh"

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); echo "  ok: $1"; }
bad() { FAIL=$((FAIL+1)); echo "  FAIL: $1" >&2; }
assert_eq()       { [ "$2" = "$3" ] && ok "$1" || bad "$1 (want [$3] got [$2])"; }
assert_contains() { case "$2" in *"$3"*) ok "$1" ;; *) bad "$1 (no [$3] in [$2])" ;; esac; }

# Bare PATH with only core utils — no osascript, no notify-send.
mkdir -p "$TMP/bin"
for t in sh sed printf command; do
  p="$(command -v "$t" 2>/dev/null)" && [ -x "$p" ] && ln -s "$p" "$TMP/bin/$t"
done

echo "N1: no notifier on PATH — message still echoes, exit 0"
out="$(PATH="$TMP/bin" "$SLN" "chain halted: testproj")"; rc=$?
assert_eq "N1 exit" "$rc" "0"
assert_eq "N1 stdout" "$out" "chain halted: testproj"

echo "N2: no argument — default message, exit 0"
out="$(PATH="$TMP/bin" "$SLN")"; rc=$?
assert_eq "N2 exit" "$rc" "0"
assert_eq "N2 stdout" "$out" "session-loop notification"

echo "N3: stub osascript — invoked once, quotes/backslashes escaped, echo intact"
cat > "$TMP/bin/osascript" <<EOF
#!/bin/sh
printf '%s\n' "\$*" >> "$TMP/osascript.calls"
EOF
chmod +x "$TMP/bin/osascript"
msg='say "hi" C:\path'
out="$(PATH="$TMP/bin" "$SLN" "$msg")"; rc=$?
assert_eq "N3 exit" "$rc" "0"
assert_eq "N3 stdout verbatim" "$out" "$msg"
calls="$(cat "$TMP/osascript.calls" 2>/dev/null)"
assert_eq "N3 osascript called once" "$(wc -l < "$TMP/osascript.calls" | tr -d ' ')" "1"
assert_contains "N3 quotes escaped" "$calls" 'say \"hi\" C:\\path'

echo
echo "pass=$PASS fail=$FAIL"
[ "$FAIL" -eq 0 ]
