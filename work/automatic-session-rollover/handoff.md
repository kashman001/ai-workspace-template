<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 2026-08-06 (session 24: wayfinder tickets 06+07 RESOLVED; STOP rollover at ~157K)

**What shipped (worktree `session-24-wayfinder-tickets`, pushed to `origin/main`):**

- **Ticket 06 — mid-flight hook injection: REFUTED, dispatch-only stands.**
  Empirical run on production wiring (evidence:
  `research/06-midflight-hook-injection.md`): PostToolUse hooks DO fire on a
  child's tool calls but keyed to the PARENT session_id (shared 60s throttle
  + shared escalation state), and the harness DROPS hook exit-2 stderr for
  those fires — a natural 120K WARN crossing mid-run reached no transcript
  (parent/child/grandchild all grepped clean). Accelerator-tier fog patch
  closed. Surviving model-mediated alternative noted in the ticket answer
  (parent SendMessage → contract checkpoint clause). Two defects filed as
  backlog rows: swallowed-WARN (busy child consumes the one-shot escalation)
  and EnterWorktree registry-artifact staleness.
- **Ticket 07 — copilot child artifacts: resolved via gen 2
  (DONE_WITH_CONCERNS, ~23 min).** Findable + parseable: per-child events in
  `~/.copilot/session-state/<sid>/events.jsonl` tagged `agentId=<toolCallId>`
  (+ `subagent.completed.totalTokens`), and `session-store.db::
  assistant_usage_events` per-request rows. Adapter buildable → fog patch
  graduated to new ticket `issues/09-copilot-adapter-design.md`. Dispatch
  gen 2 closed; drain clean. Caveats in the ticket answer (model varies,
  background/`write_agent` unverified, `-wal` sidecar).
- Map updated (2 decisions, 2 fog patches closed/graduated); `decisions.md`
  session-24 notes; backlog: 2 finding rows.
- Note: gen 2's report edits landed in the worktree copy of
  `research/07-copilot-child-artifacts.md` (my mid-task worktree entry
  blocked its shared-checkout writes; it adapted via a worktree-isolated
  sub-subagent) — committed from the worktree, so origin/main carries it.

**Suggested skills (next session):** wayfinder (ticket 09 AFK, or 08 if user
is live); session-rollover at WARN/STOP.

**Learnings:** (parked)
- Auto-mode permission classifier blocks spawning nested `claude -p` with
  `--settings`/`--dangerously-skip-permissions`/`--allowedTools` (1st strike;
  worked around by testing against the production hook wiring instead).
- Mid-session EnterWorktree severed a RUNNING subagent's shared-checkout
  writes and all its Bash (1st strike; child adapted with an
  `isolation: worktree` sub-subagent — enter the worktree BEFORE dispatching
  children, or expect this).

**Rollover:** STOP at ~157K immediately after the ticket/map writes;
committed, pushed, rolled. Session-22 block archived (two-block rule).

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

