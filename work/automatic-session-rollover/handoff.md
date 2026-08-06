<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 2026-08-06 (session 23: slice (c) registry hygiene COMPLETE + wayfinder map charted; WARN rollover at ~132K)

**What shipped (commits `0b71c46`, `f10941a`, `52b94ea` in worktree
`session-23-registry-hygiene`, all pushed to `origin/main`):**

- **Slice (c) — register-time sweep of stale primary records
  (`0b71c46`):** `sweep_stale_primaries` in `context-budget.sh` runs at
  primary acquisition (after `backstamp_superseded`): any other
  same-project `role=primary` record whose artifact liveness is stale
  (`LOCK_STALE` rule) is stamped with the takeover triple
  (`superseded`/`superseded_at`/`superseded_by=<new primary>`); live
  records, other projects, non-primary roles untouched; auxiliary/child
  registrations never sweep. Registry suite T15 (8 asserts, 68 total);
  all eight suites green (326 asserts). Plan:
  `plans/registry-hygiene-sweep.md`; stamp-don't-delete rationale in
  `decisions.md` session-23 note (not promoted). Docs paragraph in
  `context-budget.md` roles section; backlog row. **Retires the parked
  sessions-19/21 learning.**
- **Slice (a) — wayfinder map charted (`f10941a`):** `map.md` +
  tickets `issues/06-midflight-hook-injection.md` (task, AFK),
  `07-copilot-child-artifact-location.md` (research, AFK),
  `08-per-role-thresholds.md` (grilling, HITL). Accelerator-tier and
  copilot-adapter design parked in the map's fog until 06/07 resolve.
- **Ticket-07 gen 1 dispatched and rolled (`52b94ea`):** research
  subagent launched via `dispatch-open` (first live use of the R4
  machinery — open → contract emit → close worked end-to-end); child hit
  its own WARN at ~123K before any copilot probe runs and yielded
  `ROLLOVER_NEEDED` per contract; gen 1 closed with that status; report
  checkpointed at `research/07-copilot-child-artifacts.md`
  (self-contained: pre-run `~/.copilot` snapshot + method; gen 2 starts
  at its open item 1). Ticket 07 back to `Status: open`.

**Suggested skills (next session):** wayfinder (work-through-the-map
mode); session-rollover at WARN/STOP.

**Learnings:** (parked)
- Worktree-isolated sessions: the sandbox refuses compound shell
  commands (for-loops, multi-statement `&&`/`;` chains with redirects)
  as "too complex to verify"; use separate plain commands. Bit both the
  parent and the ticket-07 child this session (also documented in the
  gen-1 report).

**Rollover:** WARN at ~122K as charting finished; child's
ROLLOVER_NEEDED yield folded in, committed, pushed, rolled.

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

