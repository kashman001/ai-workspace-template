#!/usr/bin/env bash
# File: scripts/lib/session-lib.sh
# Purpose: The one way to write a work item's session record
#          (work/<item>/session-state.json, schema 1), plus the two readers
#          that answer "who owns this item, and is it alive" (ADR-0010;
#          `session_record_owner`, `session_owner_live` at the end). Sourced,
#          not executed; bash 3.2. Every writer (launcher, measurer, supervisor) goes through
#          `session_record_update`: read the record, apply a jq filter, write a
#          temp file in the same directory, rename it over the original, all
#          under a `mkdir` lock beside the record (`flock` is absent on macOS;
#          `mkdir` is atomic on both). Each caller passes a precondition: a
#          false precondition is a silent no-op, so a lost race is harmless;
#          an empty or invalid filter result is a refusal.
#          Written for Stage 4 phase 1 of work/template-improvement-review.
#
# The record and who writes each block (evaluation/stage3-design-v2.md, record
# table), verbatim:
#
#   | Block     | Written by                                                          |
#   | `seq`     | launcher (registration may open it once on an item that has no record yet) |
#   | `launch`  | launcher                                                            |
#   | `session` | measurer                                                            |
#   | `staged`  | launcher (supervisor clears it when consumed)                       |
#   | `chain`   | supervisor                                                          |
#
# Every other cross-block write is out of contract: a caller writes its own
# block (`.session = {...}`, `.chain.used += 1`) and leaves the rest alone.
# `release` merges into `ended`, never replaces it.
#
# Usage:   session_record_update <record> <precondition> <filter> [jq-args...]
#          Trailing arguments go to every jq call, so values enter through
#          `--arg name value` / `--argjson name json`, never by quoting them
#          into the filter. An absent record reads as `{"schema": 1}`; the
#          precondition decides whether that is acceptable (`.seq == null`
#          opens seq once; `.seq != null` requires an existing record).
# Returns: 0 written / 1 precondition false or null (no-op, nothing printed,
#          record untouched) / 3 usage / 4 refused, with
#          `session-lib: refused reason=<code> record=<path>` on stderr and the
#          record untouched: record_unreadable (exists but cannot be read, is
#          not JSON, or is not an object), schema_mismatch (`.schema` != 1),
#          precondition_invalid (jq could not evaluate it), filter_empty (no
#          output), filter_invalid (jq error, more than one value, not an
#          object, or schema changed), record_unwritable (directory refuses
#          the temp file or the rename), lock_timeout, jq_missing.
# Lock:    `<record>.lock`, polled every 0.05 s for SESSION_RECORD_LOCK_WAIT_SECS
#          (default 15); a lock older than SESSION_RECORD_LOCK_STALE_SECS
#          (default 10) belongs to a dead writer (a write holds it for
#          milliseconds) and is removed and re-taken. Not CONTEXT_LOCK_STALE_SECS:
#          that knob (3 h) is the session-liveness lock, whose holder is a whole
#          session. No env file is sourced; the library is location-independent.

SESSION_RECORD_SCHEMA=1

_session_record_refuse() { # <reason> <record> [detail]
  echo "session-lib: refused reason=$1 record=$2${3:+ — $3}" >&2; return 4
}

_session_record_lock() { # <record>; returns 0 held / 4 refused (reason printed)
  local record="$1" lock="$1.lock" wait="${SESSION_RECORD_LOCK_WAIT_SECS:-15}"
  local stale="${SESSION_RECORD_LOCK_STALE_SECS:-10}" left mt now dir
  left=$((wait * 20))
  while ! mkdir "$lock" 2>/dev/null; do
    if [ ! -d "$lock" ]; then
      # mkdir failed yet no lock directory exists: the holder released it
      # between the two calls (a lost race — retry, on the same wait budget),
      # unless the record's directory itself refuses or something that is not
      # a directory sits at the lock path. A lock directory here again is a
      # third writer that took it meanwhile — also a lost race (L74).
      dir="$(dirname "$record")"
      { [ -d "$dir" ] && [ -w "$dir" ] && { [ ! -e "$lock" ] || [ -d "$lock" ]; }; } \
        || _session_record_refuse record_unwritable "$record" "cannot create $lock" || return 4
      [ "$left" -gt 0 ] || _session_record_refuse lock_timeout "$record" "$lock held for ${wait}s" || return 4
      left=$((left - 1)); continue
    fi
    mt=$(stat -f%m "$lock" 2>/dev/null || stat -c%Y "$lock" 2>/dev/null) || continue
    now=$(date +%s)
    if [ $((now - mt)) -ge "$stale" ]; then rmdir "$lock" 2>/dev/null; continue; fi
    [ "$left" -gt 0 ] || _session_record_refuse lock_timeout "$record" "$lock held for ${wait}s" || return 4
    left=$((left - 1)); sleep 0.05
  done
}

_session_record_unlock() { rmdir "$1.lock" 2>/dev/null; }

session_record_update() { # <record> <precondition> <filter> [jq-args...]
  [ $# -ge 3 ] || { echo "usage: session_record_update <record> <precondition> <filter> [jq-args...]" >&2; return 3; }
  local record="$1" pre="$2" filter="$3" cur tmp rc
  shift 3
  command -v jq >/dev/null 2>&1 || { _session_record_refuse jq_missing "$record" "jq is required to write the record"; return 4; }
  _session_record_lock "$record" || return 4

  # Read once, under the lock. Absent reads as an empty schema-1 record.
  if [ -e "$record" ]; then
    cur=$(cat "$record" 2>/dev/null) \
      || { _session_record_unlock "$record"; _session_record_refuse record_unreadable "$record" "cannot read"; return 4; }
    printf '%s' "$cur" | jq -e 'type=="object"' >/dev/null 2>&1 \
      || { _session_record_unlock "$record"; _session_record_refuse record_unreadable "$record" "not a JSON object"; return 4; }
    printf '%s' "$cur" | jq -e --argjson s "$SESSION_RECORD_SCHEMA" '.schema == $s' >/dev/null 2>&1 \
      || { _session_record_unlock "$record"; _session_record_refuse schema_mismatch "$record" "schema is not $SESSION_RECORD_SCHEMA"; return 4; }
  else
    cur="{\"schema\":$SESSION_RECORD_SCHEMA}"
  fi

  rc=0; printf '%s' "$cur" | jq -e "$@" "$pre" >/dev/null || rc=$?
  case "$rc" in
    0) ;;
    1) _session_record_unlock "$record"; return 1 ;;
    *) _session_record_unlock "$record"; _session_record_refuse precondition_invalid "$record" "jq exit $rc"; return 4 ;;
  esac

  tmp="$record.tmp.$$"
  if ! : > "$tmp" 2>/dev/null; then
    _session_record_unlock "$record"; _session_record_refuse record_unwritable "$record" "cannot create $tmp"; return 4
  fi
  rc=0; printf '%s' "$cur" | jq "$@" "$filter" > "$tmp" || rc=$?
  if [ "$rc" -ne 0 ]; then
    rm -f "$tmp"; _session_record_unlock "$record"; _session_record_refuse filter_invalid "$record" "jq exit $rc"; return 4
  fi
  if [ ! -s "$tmp" ]; then
    rm -f "$tmp"; _session_record_unlock "$record"; _session_record_refuse filter_empty "$record" "filter produced no output"; return 4
  fi
  if ! jq -s -e --argjson s "$SESSION_RECORD_SCHEMA" 'length == 1 and (.[0] | type) == "object" and .[0].schema == $s' "$tmp" >/dev/null 2>&1; then
    rm -f "$tmp"; _session_record_unlock "$record"; _session_record_refuse filter_invalid "$record" "result is not exactly one schema-$SESSION_RECORD_SCHEMA object"; return 4
  fi
  if ! mv -f "$tmp" "$record" 2>/dev/null; then
    rm -f "$tmp"; _session_record_unlock "$record"; _session_record_refuse record_unwritable "$record" "cannot rename over the record"; return 4
  fi
  _session_record_unlock "$record"
}

# ---- Readers (ticket 01, work/session-management-followups). The owner is
# the record's `session` block while `ended` is null; it is alive while its
# process id is running and was started when `pid_start` says (pids are
# recycled, so the start time is part of the identity). A block with no pid
# (a runtime without a process of its own) falls back to its transcript's age
# against the stale window, as the retired lock did. Mirrors owner_live() in
# scripts/context-budget.sh, which cannot be sourced (it dispatches on execution).

session_record_owner() { # <record>; prints the open `session` block / 1 no owner (silent)
  [ $# -eq 1 ] || { echo "usage: session_record_owner <record>" >&2; return 3; }
  local out
  [ -f "$1" ] || return 1
  out=$(jq -c 'if type == "object" and (.session | type) == "object" and .session.ended == null
               then .session else empty end' "$1" 2>/dev/null) || return 1
  [ -n "$out" ] || return 1
  printf '%s\n' "$out"
}

session_owner_live() { # <session-block-json> [stale-secs, default 10800]; 0 live / 1 dead or unknowable
  [ $# -ge 1 ] || { echo "usage: session_owner_live <session-json> [stale-secs]" >&2; return 3; }
  local pid pstart cur af mt stale="${2:-10800}"
  printf '%s' "$1" | jq -e '.ended == null' >/dev/null 2>&1 || return 1
  pid=$(printf '%s' "$1" | jq -r '.pid // empty' 2>/dev/null)
  pstart=$(printf '%s' "$1" | jq -r '.pid_start // empty' 2>/dev/null)
  if [ -n "$pid" ]; then
    kill -0 "$pid" 2>/dev/null || return 1
    cur=$(ps -o lstart= -p "$pid" 2>/dev/null | sed 's/^ *//;s/ *$//')
    [ -n "$cur" ] && [ "$cur" = "$pstart" ]
    return
  fi
  af=$(printf '%s' "$1" | jq -r '.artifact // empty' 2>/dev/null)
  [ -n "$af" ] && [ -f "$af" ] || return 1
  mt=$(stat -f%m "$af" 2>/dev/null || stat -c%Y "$af" 2>/dev/null) || return 1
  [ $(( $(date +%s) - mt )) -lt "$stale" ]
}
