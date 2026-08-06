<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 2026-08-06 (session 21: ADR-0006 promoted + slice 3 COMPLETE — dispatch-contract (R2/R3); WARN rollover at ~129K)

**What shipped (committed `d2ee5dd` + `6fc7cec` in worktree
`session-21-adr-0006-slice-3`, both pushed to `origin/main`):**

- **ADR-0006 promoted (`d2ee5dd`):** the session-19 note ("coordination
  state keyed to repository identity, never a checkout") is now
  `docs/adr/0006-repository-keyed-coordination-state.md`, amending
  ADR-0004/0005's implicit one-checkout assumption; README index + backlog
  row updated, note flipped to `done → ADR-0006`.
- **Slice 3 — dispatch-contract hardening, R2/R3 (`6fc7cec`):** new
  stateless, runtime-agnostic `context-budget.sh dispatch-contract
  --report <path> [--brief <path>] [--gen <n>]` emits the R2 rollover
  contract for a long-running child's dispatch prompt (checkpoint to report
  at work-unit boundaries = heartbeat; 15-line return cap; five-status
  vocabulary incl. `ROLLOVER_NEEDED` only-on-request, never
  self-assessment; gen≥2 read-report-first clause; ASCII-only for the
  `%q`/BSD-sed launch paths). R3 documented parent-side: successor dispatch
  is the only rollover verb; sweep (`children`) before any resume, roll at
  child WARN/STOP, no human ask (R7). Design + rejected alternatives:
  `plans/slice-3-dispatch-contract.md` + session-21 `decisions.md` note
  (not promoted — implementation within ADR-0005's model).
- **Tests:** new suite `scripts/tests/test-dispatch-contract.sh` K1–K7
  (24 asserts); all seven suites green — registry 60, attach 22, launcher
  81, statusline 16, vendor 37, children 27, dispatch-contract 24 (267).
- **Docs:** `docs/context-budget.md` new "Dispatching long-running
  children" section + agent-quickstart line + children cross-ref;
  CONTEXT.md Context Budget bullet (dispatch-time pointer); backlog rows
  for both units.
- **Live verification:** first live T13-via-launcher back-stamp — session
  19's record was stamped `superseded_by` this session's id at register
  (the launcher-mediated succession chain now closes end-to-end).

**Suggested skills (next session):** tdd for the next slice; wayfinder if
slice 4 (decision tickets) is picked; session-rollover at WARN/STOP.

**Learnings:** (parked, carried from session 19 — did not bite this
session)
- Registry hygiene: stale `role=primary` records accumulate in
  `.context-budget/sessions/` from sessions that never released; cosmetic —
  lock is authoritative.

**Rollover:** WARN at ~121.6K right after slice-3 suites green;
follow-through finished, committed, rolled. Second worktree-invoked
auto-relaunch.

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
