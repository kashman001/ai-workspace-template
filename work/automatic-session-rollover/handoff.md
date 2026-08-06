<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 2026-08-06 (session 22: R4 COMPLETE — dispatch records + generation fencing; WARN rollover at ~127K)

**What shipped (committed `1713daa` in worktree
`session-22-r4-dispatch-records`, pushed to `origin/main`):**

- **R4 — parent-persisted dispatch records + generation fencing:** three new
  `context-budget.sh` subcommands. `dispatch-open --project <p> --task
  <slug> --report <path> [--brief/--agent-type/--model/--effort/--agent-id]`
  appends generation N+1 (status `open`) to the gitignored record
  `work/<p>/.agent-dispatch/<slug>.json` and emits the R2 contract for that
  generation in one step; refuses while the previous generation is still
  open (fencing — at most one live writer per report file); `--gen` is
  rejected (computed from the record). `dispatch-close --status <five yield
  statuses|KILLED>` closes the open generation (`--agent-id` merges
  post-hoc). `dispatch-list` prints `task= gen= status= report=` lines,
  exit 1 while any generation is open (the rolling parent's drain check).
  Contract emitter now labels progress blocks `[gen N]`. Design + rejected
  alternatives: `plans/dispatch-records-r4.md` + session-22 `decisions.md`
  note (not promoted — within ADR-0005/0006's model; revisit at R6).
- **Tests:** new suite `scripts/tests/test-dispatch-records.sh` L1–L9
  (51 asserts); all eight suites green — registry 60, attach 22, launcher
  81, statusline 16, vendor 37, children 27, dispatch-contract 24,
  dispatch-records 51 (318 total).
- **Docs:** `docs/context-budget.md` children section retitled R2–R4 with
  the record/fencing flow + successor-parent re-dispatch paragraph +
  quickstart bullet now dispatch-open-first; CONTEXT.md dispatch bullet
  likewise; `.gitignore` gains `work/*/.agent-dispatch/`; backlog changelog
  row.

**Slice order (user pick, session 22):** (b) R4 → (c) registry hygiene →
(a) §14 wayfinder tickets. (b) is done; (c) is next, then (a) — no further
user pick needed.

**Suggested skills (next session):** tdd for slice (c); wayfinder for
slice (a); session-rollover at WARN/STOP.

**Learnings:** (parked, carried from sessions 19/21 — slice (c) is the
retirement)
- Registry hygiene: stale `role=primary` records accumulate in
  `.context-budget/sessions/`; cosmetic — lock is authoritative.

**Rollover:** WARN at ~125K right as R4 follow-through finished; committed,
pushed, rolled. Session-19 block archived (two-block ledger rule).

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
