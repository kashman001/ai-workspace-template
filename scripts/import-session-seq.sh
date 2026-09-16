#!/usr/bin/env bash
# File: scripts/import-session-seq.sh
# Purpose: One-time import of a work item's old session counter
#          (work/<project>/.session-seq) into the new session record
#          (work/<project>/session-state.json, block `seq`). Written for Stage 4
#          phase 0 of work/template-improvement-review; retired after cutover.
#          Idempotent: run again with the same counter and nothing changes; a
#          counter that moved on (old scripts still running) is re-imported;
#          a record already ahead of the counter is refused, never regressed.
# Usage:   scripts/import-session-seq.sh <project>
# Exit:    0 imported or already equal (no-op) / 3 usage /
#          4 refused, with `reason=<code>` on stderr: no_old_counter,
#          counter_unreadable, record_unreadable, seq_conflict, jq_missing.
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT="${1:-}"
[ -n "$PROJECT" ] || { echo "usage: import-session-seq.sh <project>" >&2; exit 3; }
DIR="$ROOT/work/$PROJECT"
[ -d "$DIR" ] || { echo "error: no such work directory: work/$PROJECT" >&2; exit 3; }

refuse() { echo "import-session-seq: refused reason=$1${2:+ — $2}" >&2; exit 4; }
command -v jq >/dev/null 2>&1 || refuse jq_missing "jq is required to write the record"

COUNTER="$DIR/.session-seq"
RECORD="$DIR/session-state.json"
[ -f "$COUNTER" ] || refuse no_old_counter "work/$PROJECT/.session-seq does not exist"
n="$(tr -d '[:space:]' < "$COUNTER")"
case "$n" in ''|*[!0-9]*) refuse counter_unreadable "work/$PROJECT/.session-seq is not a non-negative integer: [$n]" ;; esac

if [ -f "$RECORD" ]; then
  cur="$(jq -r 'if type=="object" then (.seq // "") else error("not an object") end' "$RECORD" 2>/dev/null)" \
    || refuse record_unreadable "work/$PROJECT/session-state.json is not a JSON object"
  case "$cur" in
    '') ;;
    *[!0-9]*) refuse record_unreadable "record seq is not a non-negative integer: [$cur]" ;;
    *)
      if [ "$cur" -gt "$n" ]; then
        refuse seq_conflict "record seq=$cur is already ahead of the counter ($n); nothing written"
      elif [ "$cur" -eq "$n" ]; then
        echo "import-session-seq: noop seq=$n already imported (work/$PROJECT/session-state.json)"
        exit 0
      fi ;;
  esac
  tmp="$RECORD.tmp.$$"
  jq --argjson n "$n" '.schema = (.schema // 1) | .seq = $n' "$RECORD" > "$tmp" \
    || { rm -f "$tmp"; refuse record_unreadable "could not rewrite the record"; }
else
  tmp="$RECORD.tmp.$$"
  jq -n --argjson n "$n" '{schema: 1, seq: $n}' > "$tmp" \
    || { rm -f "$tmp"; refuse record_unreadable "could not write the record"; }
fi
mv -f "$tmp" "$RECORD"
echo "import-session-seq: imported seq=$n (work/$PROJECT/session-state.json)"
