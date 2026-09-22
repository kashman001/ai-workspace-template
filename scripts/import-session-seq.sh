#!/usr/bin/env bash
# File: scripts/import-session-seq.sh
# Purpose: Migration of a work item from the old session scripts (the
#          work/<project>/.session-seq counter) to the session record
#          (work/<project>/session-state.json, block `seq`). Kept after the
#          Stage 4 cutover: every workspace that pulls the new scripts has
#          work items on the old counter to bring over.
#          Idempotent: run again with the same counter and nothing changes; a
#          counter that moved on (old scripts still running) is re-imported;
#          a record already ahead of the counter is refused, never regressed.
#          `--status` classifies items without writing: which generation of
#          the scripts each item ran, and whether it needs the import.
# Usage:   scripts/import-session-seq.sh <project>
#          scripts/import-session-seq.sh --status [<project>]
# Status:  one line per item — `<project> state=<s> loop=<yes|no> counter=<n|->
#          seq=<n|-> next=<import|nothing|delete-leftovers|check> leftovers=<files|->`
#            fresh      never ran any session script (old or new); `register
#                       --project` opens the record from the ledger — nothing to do
#            old        ran the old scripts, no record yet — run the import;
#                       loop=yes means the old session-loop.sh ran it
#            imported   record and counter agree — delete the leftover old files
#            new        record only — the current scripts; loop=yes means the
#                       current session-loop.sh has run it
#            conflict   record ahead of the counter — look before touching
#            unreadable counter or record not parseable — look before touching
#          A counter ahead of an existing record reads as `old` again (re-import).
# Exit:    import: 0 imported or already equal (no-op) / 3 usage /
#          4 refused, with `reason=<code>` on stderr: no_old_counter,
#          counter_unreadable, record_unreadable, seq_conflict, jq_missing.
#          --status: 0 nothing needs the import / 1 at least one item does
#          (or needs a look) / 3 usage.
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STATUS=0
[ "${1:-}" = "--status" ] && { STATUS=1; shift; }
PROJECT="${1:-}"
[ $# -le 1 ] || { echo "usage: import-session-seq.sh <project> | --status [<project>]" >&2; exit 3; }
[ -n "$PROJECT" ] || [ "$STATUS" -eq 1 ] || { echo "usage: import-session-seq.sh <project> | --status [<project>]" >&2; exit 3; }
DIR="$ROOT/work/$PROJECT"
[ -z "$PROJECT" ] || [ -d "$DIR" ] || { echo "error: no such work directory: work/$PROJECT" >&2; exit 3; }

refuse() { echo "import-session-seq: refused reason=$1${2:+ — $2}" >&2; exit 4; }
command -v jq >/dev/null 2>&1 || refuse jq_missing "jq is required to write the record"

# The old scripts' state files; every one is dead weight once the record exists.
OLD_FILES=".session-seq .session-seq.provenance.json .session-seq.bump.json .rollover-options .active-session .rollover-complete"

status_one() {  # $1 = project; prints one line; returns 1 when the item needs work
  local d="$ROOT/work/$1" counter="-" seq="-" chain="" loop=no state next lo="" f
  [ -f "$d/.session-seq" ] && { counter="$(tr -d '[:space:]' < "$d/.session-seq")"; [ -n "$counter" ] || counter="?"; }
  case "$counter" in -|'') ;; *[!0-9]*) counter="?" ;; esac
  if [ -f "$d/session-state.json" ]; then
    seq="$(jq -r 'if type=="object" and .schema==1 then ((.seq // "-")|tostring) else "?" end' "$d/session-state.json" 2>/dev/null)" || seq="?"
    case "$seq" in -|'') seq="-" ;; *[!0-9]*) seq="?" ;; esac
    chain="$(jq -r '.chain // empty | type' "$d/session-state.json" 2>/dev/null)"
  fi
  if [ -n "$chain" ]; then loop=yes
  else for f in .session-seq.provenance.json .active-session .session-loop.log; do [ -e "$d/$f" ] && loop=yes; done; fi
  for f in $OLD_FILES; do [ -e "$d/$f" ] && lo="$lo${lo:+,}$f"; done
  if   [ "$counter" = "?" ] || [ "$seq" = "?" ]; then state=unreadable; next=check
  elif [ "$seq" = "-" ] && [ "$counter" = "-" ]; then state=fresh; next=nothing
  elif [ "$seq" = "-" ]; then state=old; next=import
  elif [ "$counter" = "-" ]; then state=new; next=nothing
  elif [ "$counter" -gt "$seq" ]; then state=old; next=import
  elif [ "$counter" -eq "$seq" ]; then state=imported; next=delete-leftovers
  else state=conflict; next=check; fi
  printf '%s state=%s loop=%s counter=%s seq=%s next=%s leftovers=%s\n' "$1" "$state" "$loop" "$counter" "$seq" "$next" "${lo:--}"
  case "$next" in import|check) return 1 ;; esac
  return 0
}

if [ "$STATUS" -eq 1 ]; then
  rc=0
  if [ -n "$PROJECT" ]; then status_one "$PROJECT" || rc=1
  else
    for d in "$ROOT"/work/*/; do
      [ -d "$d" ] || continue
      d="${d%/}"; status_one "${d##*/}" || rc=1
    done
  fi
  exit "$rc"
fi

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
