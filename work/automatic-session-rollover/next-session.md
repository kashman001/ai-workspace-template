# Catchup prompt — Automatic Session Rollover (paste into a new agent session)

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, REPLACED at
> each rollover. Past-tense provenance lives in `handoff.md` (append-only
> ledger, newest block on top). Convention: docs/work-directory-conventions.md.

## Mission

Wayfinder work-through-the-map mode (`map.md`). Ticket 09 (copilot adapter
design) resolved in session 25. **The map has exactly one ticket left:**

- **Ticket 08** (`issues/08-per-role-thresholds.md`) — per-role threshold
  config, grilling, **HITL only**: take it only if the user is live; never
  resolve AFK. When 08 closes, the map's destination is reached — every
  §14.4 question is a recorded decision.

If the user is NOT live: there is no AFK map work left. Do not invent work.
Either idle-report, or (only if the user asked) take a backlog item:
swallowed-WARN defect, EnterWorktree registry staleness, or the copilot
adapter BUILD (designed in ticket 09; slice 0 = background/`write_agent`
probe) — all template work scheduled with the user, not map tickets.

One ticket per session. On resolution: answer under `## Answer`,
`Status: resolved`, gist to map's Decisions-so-far, close/graduate the
matching fog patch.

## Read these, in order

1. `handoff.md` top block — session-25 record.
2. `map.md` — destination, decisions so far, remaining fog.
3. Ticket 08 only if the user is live (plus, for context, the threshold
   passages in `docs/context-budget.md` and the per-item override row in
   the backlog — targeted reads).

## Do NOT reload

- Research md/HTML corpus — settled; distilled into ADR-0005/0006,
  `docs/context-budget.md`, plan files.
- Tickets 01–07 and 09: resolved/spun out (answers inline in the ticket
  files — read only if ticket 08 needs them). Issue 04 parked by the
  user — never schedule unprompted.
- `research/06-midflight-hook-injection.md`,
  `research/07-copilot-child-artifacts.md` — evidence logs for settled
  verdicts; 07's VERDICT is distilled into ticket 09's design.
- `rollover-scenarios.md`, `plans/*` — build slices all COMPLETE.
- Sessions ≤24 handoff blocks, `handoff-archive.md` — settled.

## Constraints already decided (do not re-litigate)

- Role schema final: primary / auxiliary / child / superseded. Register-time
  stale-primary sweep ships.
- Dispatch-time contract is the load-bearing parent→child channel.
  Accelerator tier (hook injection into children): CLOSED (ticket 06).
- Copilot measured-tier adapter: DESIGNED (ticket 09) — in-place
  `context-budget.sh` extension, composite child id `<sid>+<toolCallId>`,
  sqlite-first measurement (last row input+cache, WAL snapshot),
  R4 records reused. Build unscheduled.
- Coordination state is repository-keyed (ADR-0006).
- R2/R3/R4 shipped; R6 drain mode stays deferred. Runtime state stays
  gitignored. Standing push-to-main approval applies.

## State snapshot (at session-25 end, 2026-08-06)

- Session-25 work committed in worktree `session-25-ticket-09`, pushed to
  `origin/main` (see handoff top block). Main checkout may need
  `git pull --ff-only`.
- Test suites untouched sessions 24–25 — last green: eight suites,
  326 asserts, at `52b94ea`.
- No live dispatches (`dispatch-list` drains clean); no child agents.
- Copilot durable evidence dirs (don't delete):
  `~/.copilot/session-state/c356dbd8-…` and `96cbc930-…`.
- `issues/04-in-place-clear-relaunch.md` still untracked in the user's
  checkout — parked by user choice.
- Worktrees (all pushed, disposable — prune when convenient):
  `session-25-ticket-09`, `session-24-wayfinder-tickets`,
  `session-23-registry-hygiene`, plus the six in the session-22 snapshot.
- Sandbox gotchas (documented in `docs/operational-knowledge.md`): plain
  single commands in worktree-isolated sessions; enter the worktree BEFORE
  dispatching children.

## First actions

1. `scripts/context-budget.sh register --project automatic-session-rollover`
   — expect `role=primary`; session 25's record back-stamped with YOUR id.
2. Confirm the checkout carries the session-25 commit
   (`git log --oneline -3` mentions "session-25"); pull if not.
3. User live → ticket 08 (grilling, HITL). User AFK → no map work; see
   Mission for the only sanctioned alternatives.

## If you are a VS Code Copilot Chat (agent-mode) session

First live copilot-vscode session on this work item — two extra rules:

- After `register`, paste the emitted `runtime= method= tokens= ...` line
  into the chat for the user: it is the live verification of
  `copilot_vscode_measure` that `issues/01-vscode-agent-mode-hooks.md`
  item 2 needs (record the result there; compare against the session UI).
- If `register` reports `role=auxiliary`, a live claude session owns the
  work item. Do NOT proceed on the mission above — ask the user: either
  they wind down the claude session (then re-register here, expect
  primary), or this session takes ticket 08 only (grilling, HITL — needs
  the user live anyway) as auxiliary, touching nothing else.

## At session end

Lock releases mechanically (launcher script or SessionEnd hook). Manual
fallback: `scripts/context-budget.sh release --project automatic-session-rollover`.
