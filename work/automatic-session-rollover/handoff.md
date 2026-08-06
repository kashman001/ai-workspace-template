<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 2026-08-06 (session 25: wayfinder ticket 09 RESOLVED — copilot adapter designed; clean wrap at ~113K)

**What shipped (worktree `session-25-ticket-09`, pushed to `origin/main`):**

- **Ticket 09 — copilot measured-tier adapter: DESIGNED.** Full design +
  rejected alternatives under `## Answer` in
  `issues/09-copilot-adapter-design.md`; gist: in-place extension of
  `context-budget.sh` (no new script) — composite child identity
  `<parentSessionId>+<toolCallId>` via the existing `--agent-id` flag
  (task children have no session); `children` grows a copilot-cli branch
  (events.jsonl `subagent.started` scan cross-checked against
  `session-store.db::assistant_usage_events initiator='sub-agent'` — the
  hedge for unverified background/`write_agent` streams); measurement
  keeps claude context-size semantics — last usage row's
  `input+cache_read+cache_write` per agent_id, `method=exact`, WAL-sidecar
  snapshot before reading; `subagent.completed.totalTokens` demoted to
  estimate-only fallback (lifetime sum, not context size); per-child locks
  and R4 dispatch records reused verbatim; escalation is post-hoc/external
  only (sync `task` blocks the parent; push tier closed by ticket 06).
  Build = execution work, out of map scope: backlog row added (incl.
  slice-0 probe + `copilot_cli_measure` sqlite-first upgrade), unscheduled.
- Map updated: ticket-09 decision line, fog patch cleared (Not-yet-specified
  now holds only the ticket-08-dependent threshold-config item), Out-of-scope
  line for the adapter build. Launcher REPLACED (frontier = ticket 08 only,
  HITL; AFK sessions have no map work left).
- No code/tests touched (design-only session). No dispatches opened.

**Suggested skills (next session):** wayfinder (ticket 08, ONLY if user is
live — grilling, HITL); session-rollover at WARN/STOP.

**Learnings:** none new (the two session-24 parked learnings did not
re-strike; register-time artifact path did go worktree-stale again after
EnterWorktree — already an open backlog finding, second strike noted there
if it bites a check).

**Wrap:** clean end at ~113K (OK, below WARN) — ticket resolved, map has
no AFK frontier left, so the session wrapped rather than idling toward
WARN. Committed, pushed. Session-23 block archived (two-block rule).

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

