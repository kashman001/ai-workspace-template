# Catchup prompt — Automatic Session Rollover (paste into a new agent session)

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, REPLACED at
> each rollover. Past-tense provenance lives in `handoff.md` (append-only
> ledger, newest block on top). Convention: docs/work-directory-conventions.md.

## Mission

**FIRST TASK (user-approved, session 26): implement the copilot-vscode
sandbox discovery fix.** Spec: `work/context-decay/
copilot-vscode-sandbox-discovery-fix.md` (derive the workspaceStorage hash
from `VSCODE_TARGET_SESSION_LOG` by parameter expansion — the sandboxed
VS Code terminal blocks readdir on `workspaceStorage/`; keep the existing
glob scan as fallback). Verify per the spec's Verify section + run the
existing `scripts/tests/` suite (last green: 326 asserts). Context:
issue-01 update block (item 2: measure verified exact, tokens=38680 live).

Then: wayfinder work-through-the-map mode (`map.md`). Ticket 09 (copilot
adapter design) resolved in session 25, verified session 26. **The map has
exactly one ticket left:**

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

1. `handoff.md` top block — session-26 record (incl. post-wrap addendum).
1a. `work/context-decay/copilot-vscode-sandbox-discovery-fix.md` — the
    first task's spec (short, self-contained).
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

## State snapshot (at session-26 end, 2026-08-06)

- Session-26 work (ticket-09 verification addendum + launcher-staleness
  Finding; session 25's design confirmed, sqlite-first now VERIFIED
  necessary) committed in worktree `session-26-ticket-09`, pushed to
  `origin/main` (see handoff top block). Main checkout may need
  `git pull --ff-only` (First action 1).
- Test suites untouched sessions 24–26 — last green: eight suites,
  326 asserts, at `52b94ea`.
- No live dispatches (`dispatch-list` drains clean); no child agents.
- Copilot durable evidence dirs (don't delete):
  `~/.copilot/session-state/c356dbd8-…` and `96cbc930-…`.
- `issues/04-in-place-clear-relaunch.md` still untracked in the user's
  checkout — parked by user choice.
- Worktrees (all pushed, disposable — prune when convenient):
  `session-26-ticket-09` (also carries local branch
  `session-26-pre-reconcile` — the discarded duplicate, safe to delete),
  `session-25-ticket-09`, `session-24-wayfinder-tickets`,
  `session-23-registry-hygiene`, plus the six in the session-22 snapshot.
- Sandbox gotchas (documented in `docs/operational-knowledge.md`): plain
  single commands in worktree-isolated sessions; enter the worktree BEFORE
  dispatching children.

## First actions

1. **Freshness guard — do this BEFORE trusting anything in this file:**
   `git fetch origin` then `git log --oneline HEAD..origin/main` — MUST be
   empty. If not, `git pull --ff-only` and RE-READ this launcher: the copy
   you just read may be stale (this exact race made session 26 re-resolve
   an already-resolved ticket; backlog Finding row has the details).
2. `scripts/context-budget.sh register --project automatic-session-rollover`
   — expect `role=primary`; session 26's record back-stamped with YOUR id.
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
