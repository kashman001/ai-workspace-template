#!/usr/bin/env bash
# File: work/template-improvement-review/evaluation/probes/v10-fleet.sh
# Purpose: Probe V10 — a fleet and its parent's rollover (scenarios S8, I6),
#          self-checking. The parent (a registered session whose transcript
#          has child transcripts beside it) opens two dispatch records, rolls
#          over through the launcher while both generations are still open —
#          the child-lock gate the stage-3 review deleted (decision 11) must
#          NOT refuse — and the successor closes and re-dispatches one task as
#          generation 2, then sweeps the parent's children.
#          Criteria: `dispatch-list` rc 1 before the rollover; launcher rc 0
#          with launch.predecessor.disposition = rolled_over; a gen-2 record
#          after; `children --parent-session` measures both; no retired file.
# Usage:   v10-fleet.sh --root <workspace> --project <item> --parent-session <sid>
#          The parent must be registered against the workspace's registry
#          (.context-budget/sessions/claude-<sid>.json) with a transcript whose
#          `<transcript-dir>/<sid>/subagents/agent-*.jsonl` children exist. No
#          login is needed: the launcher and the fleet verbs read identity from
#          the environment.
set -u
PROBE_NAME="v10-fleet"
. "$(cd "$(dirname "$0")" && pwd -P)/lib.sh"
probe_parse "$@"
[ -n "$PARENT_SESSION" ] || probe_usage
preg="$ROOT/.context-budget/sessions/claude-$PARENT_SESSION.json"
[ -f "$preg" ] || { echo "$PROBE_NAME: parent $PARENT_SESSION is not registered ($preg)" >&2; exit 3; }
ptx="$(jq -r '.artifact // empty' "$preg")"
[ -n "$ptx" ] && [ -f "$ptx" ] || { echo "$PROBE_NAME: parent $PARENT_SESSION has no transcript on record" >&2; exit 3; }
probe_seed_item
as_parent() { CLAUDE_CODE_SESSION_ID="$PARENT_SESSION" "$@"; }
succ="$PARENT_SESSION-succ"
as_succ() { CLAUDE_CODE_SESSION_ID="$succ" "$@"; }
drec() { jq -r "$2" "$W/.agent-dispatch/$1.json" 2>/dev/null; }

echo "V10: two children dispatched; the parent rolls over with both generations open"
(cd "$ROOT" && as_parent "$CB" register --project "$PROJECT" --runtime claude --transcript "$ptx" >/dev/null 2>&1)
probe_assert_eq "V10a: the parent owns the item"                  "$(rec '.session.session_id')" "$PARENT_SESSION"
(cd "$ROOT" && as_parent "$FLEET" dispatch-open --project "$PROJECT" --task task-a --report "work/$PROJECT/task-a.md" >/dev/null 2>&1); rc_a=$?
(cd "$ROOT" && as_parent "$FLEET" dispatch-open --project "$PROJECT" --task task-b --report "work/$PROJECT/task-b.md" >/dev/null 2>&1); rc_b=$?
probe_assert_eq "V10b: both dispatch records opened"              "$rc_a/$rc_b" "0/0"
(cd "$ROOT" && "$FLEET" dispatch-list --project "$PROJECT" >/dev/null 2>&1); rc=$?
probe_assert_eq "V10c: dispatch-list rc 1 before the rollover (generations open)" "$rc" "1"
(cd "$ROOT" && as_parent bash "work/$PROJECT/session-turn.sh"); rc=$?
probe_assert_eq "V10d: the launcher did not refuse (no child-lock gate)" "$rc" "0"
probe_assert_eq "V10e: no refusal code in its output"             "$(grep -o 'refused reason=[a-z_]*' "$W/launcher-1.log" 2>/dev/null | head -1)" ""
probe_assert_eq "V10f: seq advanced 1 -> 2"                       "$(rec .seq)" "2"
probe_assert_eq "V10g: launch.predecessor.disposition"            "$(rec '.launch.predecessor.disposition')" "rolled_over"
probe_assert_eq "V10h: launch.predecessor.session_id"             "$(rec '.launch.predecessor.session_id')" "$PARENT_SESSION"
probe_assert_eq "V10i: the dispatch records survived the rollover" "$(drec task-a '.generations[-1].status')/$(drec task-b '.generations[-1].status')" "open/open"

echo "V10: the successor re-dispatches generation 2 and sweeps the parent's children"
(cd "$ROOT" && TF_SESSION_PROJECT="$PROJECT" TF_SESSION_SEQ=2 as_succ "$CB" register --runtime claude >/dev/null 2>&1)
probe_assert_eq "V10j: the successor bound by the env pair"        "$(rec '.session.seq')/$(rec '.session.session_id')" "2/$succ"
(cd "$ROOT" && as_succ "$FLEET" dispatch-close --project "$PROJECT" --task task-a --status ROLLOVER_NEEDED >/dev/null 2>&1); rc=$?
probe_assert_eq "V10k: dispatch-close rc 0"                        "$rc" "0"
out="$(cd "$ROOT" && as_succ "$FLEET" dispatch-open --project "$PROJECT" --task task-a --report "work/$PROJECT/task-a.md" 2>/dev/null)"; rc=$?
probe_assert_eq "V10l: dispatch-open again rc 0"                   "$rc" "0"
probe_assert_eq "V10m: task-a is on generation 2"                  "$(drec task-a '.generations | length')" "2"
probe_assert_eq "V10n: generation 2 is open"                       "$(drec task-a '.generations[-1].status')" "open"
case "$out" in *"generation 2"*) probe_ok "V10o: the contract names generation 2" ;; *) probe_bad "V10o: the contract does not name generation 2" ;; esac
(cd "$ROOT" && "$FLEET" dispatch-list --project "$PROJECT" >/dev/null 2>&1); rc=$?
probe_assert_eq "V10p: dispatch-list rc 1 (gen 2 open)"            "$rc" "1"
cout="$(cd "$ROOT" && as_succ "$FLEET" children --parent-session "$PARENT_SESSION" --all 2>&1)"; rc=$?
probe_assert_eq "V10q: children rc 0 (both under WARN)"            "$rc" "0"
probe_assert_eq "V10r: children measured both"                     "$(printf '%s\n' "$cout" | grep -o 'children: [0-9]* measured' | head -1)" "children: 2 measured"
probe_assert_eq "V10s: no retired file under work/$PROJECT/"       "$(retired_present)" ""
probe_finish
