<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->


# Session Handoff — 2026-08-06 (session 19: issue 05 COMPLETE — workspace-root anchoring; WARN rollover at ~139K)

**What shipped (committed `a850d7b` in worktree
`issue-05-workspace-root-anchoring`, pushed to `origin/main` with the
rollover commit; the successor relaunch itself ff-pulls the main checkout —
first live use of the mechanized sync):**

- **Workspace-root anchoring (issue 05):** all five coordination scripts
  (`context-budget.sh`, `launch-next-session.sh`, `attach-session.sh`,
  `statusline-context-budget.sh`, `hooks/context-budget-hook-lib.sh`) now
  resolve `WORKSPACE_ROOT` via `git rev-parse --git-common-dir` → every
  worktree converges on the main checkout's `.context-budget/`, locks,
  ledger, `.session-seq`. Marker-guarded fallback to script-relative
  resolution outside git. Design + rejected alternatives:
  `plans/workspace-root-anchoring.md` + session-19 `decisions.md` note
  (**promote-candidate: YES** — amends ADR-0004/0005's one-checkout
  assumption; not yet promoted).
- **Mechanized worktree launch-sync:** `launch-next-session.sh` invoked from
  a worktree verifies worktree committed+pushed and main `work/<proj>/`
  clean, `pull --ff-only`s the main checkout, launches from the main root
  (loud exit-3 refusals). Retires the "no auto-relaunch from worktrees" ban
  and register-before-isolate.
- **Tests:** new G1/G2 (registry), W1–W5 (launcher), T8 (statusline); all
  six suites green — registry 60, attach 22, launcher 81, statusline 16,
  vendor 37, children 27 (243 total).
- **Live verification:** `record` from this worktree wrote to the main
  checkout's ledger (fix observed working); T13 back-stamp check at register
  was a correct no-op — session 18 released its lock manually (worktree
  ban, now retired), so no `superseded` record existed to claim.
- **Follow-through, all done:** `docs/context-budget.md` "Worktrees"
  section; operational-knowledge divergence entry marked superseded-by-fix;
  worktree Bash-guard learning promoted (second strike, sessions 18+19);
  backlog changelog row; issue 05 marked RESOLVED; plan COMPLETE.

**Suggested skills (next session):** decision-log (`/decision promote`) if
the user wants the ADR; tdd for the next slice; session-rollover at
WARN/STOP.

**Learnings:** (parked, first strike)
- Registry hygiene: `.context-budget/sessions/` accumulates stale
  `role=primary` records from ended sessions that never released/rolled
  (three from 2026-08-06 alone); lineage stamps only cover launcher-mediated
  successions. Cosmetic for now — the lock, not the records, is
  authoritative.

**Rollover:** WARN at ~126K right after all suites green; follow-through
finished, committed, rolled. First rollover to use the worktree-invoked
auto-relaunch path this slice just shipped.
# Session Handoff — 2026-08-06 (session 18: slice 2 COMPLETE — `children` per-child sweep (R1); WARN rollover at ~120K)

**What shipped (committed `d194cc1`, pushed to `origin/main`; work done in
worktree `slice-2-children-sweep` — main checkout BEHIND until pulled):**

- **`children` subcommand (slice 2, R1):** `context-budget.sh children
  [--parent-session <sid>] [--all]` — enumerates a Claude parent's
  `subagents/agent-*.jsonl` + `.meta.json`, measures each with a
  sidechain-INCLUSIVE Claude-measure variant (child rows are all
  `isSidechain:true`; the self-measure filter would degrade them to size
  estimates), prints escalation-only WARN/STOP check-style lines
  (`agent= tokens= … status= age= type=`), exits with the worst child
  status. Non-claude runtimes die loudly. Design + rejected alternatives:
  `plans/slice-2-children-sweep.md` and the session-18 `decisions.md` note.
- **Tests:** new suite `scripts/tests/test-children-sweep.sh` C1–C9
  (27 asserts); all six suites green (registry 54, attach 22, launcher 65,
  statusline 14, vendor 37, children 27).
- **Live verification:** T13 back-stamp confirmed at register (session-17
  record stamped with this session's id); smoke sweep of a real fleet
  surfaced the research's motivating 141.8K subagent as WARN.
- **Follow-through, all done:** usage header; `docs/context-budget.md`
  "Per-child sweep" section + quickstart line; decisions.md note (not
  promoted — implementation detail within ADR-0005); backlog changelog row;
  plan file marked COMPLETE.

**Suggested skills (next session):** tdd for the next slice;
session-rollover at WARN/STOP.

**Learnings:** (parked, first strike each)
- The worktree-isolated Bash guard refuses compound commands (for-loops,
  `;`-chains with redirects, unquoted globs) even when they only run tests —
  split into one plain command per call.

**Rollover:** WARN at ~120K right at the slice boundary (record after push);
deliberate rollover, no unfinished work. Lock released manually (launch
script not invoked from a worktree, per operational rule).

