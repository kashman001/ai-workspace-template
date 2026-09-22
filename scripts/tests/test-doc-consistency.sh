#!/usr/bin/env bash
# File: scripts/tests/test-doc-consistency.sh
# Purpose: pin docs/context-budget.md to the session scripts, both ways: every
#          verb and reason code the doc names exists in the scripts, and every
#          one the scripts emit is named in the doc (ADR-0011: one canonical
#          list). No temp workspace; this is a static read of the tree.
#
# Doc side — one section, two tables. Under "## Verbs and reason codes":
#   "### Verbs"        — every backticked word up to "### Reason codes" is a verb
#   "### Reason codes" — every backticked word up to the next "## " is a code
#   A backticked word is `[a-z][a-z0-9_-]*` (flags start with "-", so `--emit`
#   is never taken; leg names are written without backticks in that section).
#
# Script side — the lifecycle scripts only: scripts/context-budget.sh,
#   launch-next-session.sh, session-loop.sh, import-session-seq.sh, fleet.sh,
#   scripts/hooks/*.sh, scripts/lib/*.sh.
#   verbs — the arms of the final `case "$COMMAND" in … esac` block of
#           context-budget.sh and fleet.sh (`  <name>) …`).
#   codes — every literal a script emits as a code:
#           `refuse <code>` / `broken <code>` / `verdict <code>` calls,
#           `reason=<code>` / `verdict=<code>` / `page=<code>` literals,
#           the `refuse "${var:-<code>}"` fallback, register's `action="<code>"`
#           and the supervisor's `v=quit_<x>` verdicts. The one non-code match,
#           `broken reason` (the function's own line), is dropped; comment
#           lines and trailing ` # …` comments are stripped first.
set -u
export LC_ALL=C   # [a-z] must never match uppercase (macOS locales do)
SRC_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
DOC="$SRC_ROOT/docs/context-budget.md"
PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); echo "  ok: $1"; }
bad() { FAIL=$((FAIL+1)); echo "  FAIL: $1" >&2; }

section() {  # $1 = start marker, $2 = end marker (regex on the line start)
  awk -v s="$1" -v e="$2" '
    index($0, s) == 1 { on = 1; next }
    on && $0 ~ e { exit }
    on { print }' "$DOC"
}
tokens() { grep -oE '`[a-z][a-z0-9_-]*`' | tr -d '`' | sort -u; }

[ -f "$DOC" ] || { bad "docs/context-budget.md missing"; echo "passed=$PASS failed=$FAIL"; exit 1; }
grep -q '^## Verbs and reason codes' "$DOC" && ok "the doc has a 'Verbs and reason codes' section" \
  || bad "the doc has no '## Verbs and reason codes' section"

DOC_VERBS="$(section '### Verbs' '^### Reason codes' | tokens)"
DOC_CODES="$(section '### Reason codes' '^## ' | tokens)"

SCRIPTS="$SRC_ROOT/scripts/context-budget.sh $SRC_ROOT/scripts/launch-next-session.sh \
  $SRC_ROOT/scripts/session-loop.sh $SRC_ROOT/scripts/import-session-seq.sh $SRC_ROOT/scripts/fleet.sh \
  $SRC_ROOT/scripts/hooks/*.sh $SRC_ROOT/scripts/lib/*.sh"
SCRIPT_VERBS="$(for f in "$SRC_ROOT/scripts/context-budget.sh" "$SRC_ROOT/scripts/fleet.sh"; do
  sed -n '/^case "\$COMMAND" in/,/^esac/p' "$f" | grep -oE '^  [a-z][a-z-]*\)' | tr -d ' )'
done | sort -u)"
# shellcheck disable=SC2086
SCRIPT_CODES="$(cat $SCRIPTS | grep -v '^ *#' | sed 's/ #.*$//' \
  | grep -oE '(refuse|broken|verdict) [a-z_]+|(reason|verdict|page)=[a-z_]+|refuse "\$\{[a-z_]+:-[a-z_]+\}"|action="[a-z_]+"|(^|[^a-z_])v=quit_[a-z]+' \
  | sed -E 's/^refuse "\$\{[a-z_]+:-//; s/\}"$//; s/^(refuse|broken|verdict) //; s/^(reason|verdict|page)=//; s/^action="//; s/"$//; s/^.*v=//' \
  | grep -vx 'reason' | sort -u)"

compare() {  # $1 = label, $2 = doc set, $3 = script set
  local doc_only script_only
  doc_only="$(comm -23 <(printf '%s\n' "$2") <(printf '%s\n' "$3") | tr '\n' ' ')"
  script_only="$(comm -13 <(printf '%s\n' "$2") <(printf '%s\n' "$3") | tr '\n' ' ')"
  [ -z "$doc_only" ]    && ok "$1: every one the doc names exists in the scripts" \
                        || bad "$1: named in the doc, not in the scripts: $doc_only"
  [ -z "$script_only" ] && ok "$1: every one the scripts emit is named in the doc" \
                        || bad "$1: emitted by the scripts, not named in the doc: $script_only"
}
[ -n "$SCRIPT_VERBS" ] && ok "verbs extracted from the scripts ($(printf '%s\n' "$SCRIPT_VERBS" | wc -l | tr -d ' '))" || bad "no verbs extracted from the scripts"
[ -n "$SCRIPT_CODES" ] && ok "codes extracted from the scripts ($(printf '%s\n' "$SCRIPT_CODES" | wc -l | tr -d ' '))" || bad "no codes extracted from the scripts"
compare verbs "$DOC_VERBS" "$SCRIPT_VERBS"
compare codes "$DOC_CODES" "$SCRIPT_CODES"

echo "passed=$PASS failed=$FAIL"
[ "$FAIL" -eq 0 ]
