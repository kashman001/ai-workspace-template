# Catchup prompt — Automatic Session Rollover (paste into a new agent session)

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, REPLACED at
> each rollover. Past-tense provenance lives in `handoff.md` (append-only
> ledger, newest block on top). Convention: docs/work-directory-conventions.md.

## Mission

Wayfinder work-through-the-map mode (`map.md`). Tickets 06 and 07 resolved
in session 24 (both decisions recorded in the map). The frontier is now:

- **Ticket 09** (`issues/09-copilot-adapter-design.md`) — copilot
  measured-tier adapter design (task, AFK-able). Facts it builds on are in
  `research/07-copilot-child-artifacts.md` (gen-2 VERDICT + [gen 2] blocks).
- **Ticket 08** (`issues/08-per-role-thresholds.md`) — grilling, **HITL
  only**: take it only if the user is live; never resolve AFK.

One ticket per session. On resolution: answer under `## Answer`,
`Status: resolved`, gist to map's Decisions-so-far, close/graduate the
matching fog patch.

## Read these, in order

1. `handoff.md` top block — session-24 record.
2. `map.md` — destination, decisions so far, remaining fog.
3. The chosen ticket file (09 or 08); for 09 also the research file named
   above (targeted sections only).

## Do NOT reload

- Research md/HTML corpus — settled; distilled into ADR-0005/0006,
  `docs/context-budget.md`, plan files.
- Tickets 01–07: 01 spun out, 02/03/05 resolved earlier, 06/07 resolved
  session 24 (answers are inline in the ticket files — read only if the
  new ticket needs them). Issue 04 parked by the user — never schedule
  unprompted.
- `research/06-midflight-hook-injection.md` — evidence log for a settled
  verdict; load only if working the swallowed-WARN backlog fix.
- `rollover-scenarios.md`, `plans/*` — build slices all COMPLETE.
- Sessions ≤23 handoff blocks, `handoff-archive.md` — settled.

## Constraints already decided (do not re-litigate)

- Role schema final: primary / auxiliary / child / superseded. Register-time
  stale-primary sweep ships.
- Dispatch-time contract is the load-bearing parent→child channel.
  **Accelerator tier (hook injection into children): CLOSED — empirically
  refuted, ticket 06.** Only a model-mediated SendMessage push survives as
  a possible parent behavior; not scheduled.
- Coordination state is repository-keyed (ADR-0006).
- R2/R3/R4 shipped; R6 drain mode stays deferred. Runtime state stays
  gitignored. Standing push-to-main approval applies.
- Swallowed-WARN defect + EnterWorktree registry staleness are BACKLOG
  items (template work, not map tickets) — schedule only with the user.

## State snapshot (at session-24 rollover, 2026-08-06)

- All session-24 work committed in worktree `session-24-wayfinder-tickets`
  and pushed to `origin/main` (see handoff top block for the commit).
  Main checkout ff-pulled only if auto-relaunch ran; else `git pull --ff-only`.
- Test suites untouched this session — last green: eight suites,
  326 asserts, at `52b94ea`.
- Dispatch record `07-copilot-artifacts.json`: gen 2 closed
  DONE_WITH_CONCERNS; `dispatch-list` drains clean. No live agents.
- Copilot durable evidence: `~/.copilot/session-state/c356dbd8-…` and
  `96cbc930-…` (probe sessions; don't delete).
- `issues/04-in-place-clear-relaunch.md` still untracked in the user's
  checkout — parked by user choice.
- Worktrees (all pushed, disposable — prune when convenient):
  `session-24-wayfinder-tickets`, `session-23-registry-hygiene`, plus the
  six in the session-22 snapshot.
- Sandbox gotchas (documented in `docs/operational-knowledge.md`): plain
  single commands in worktree-isolated sessions; enter the worktree BEFORE
  dispatching children (mid-session entry severs a running child's
  shared-checkout writes — bit gen 2, session 24).

## First actions

1. `scripts/context-budget.sh register --project automatic-session-rollover`
   — expect `role=primary`; session 24's record back-stamped with YOUR id.
2. Confirm the checkout carries the session-24 commit
   (`git log --oneline -3` mentions "session-24"); pull if not.
3. Pick the frontier ticket: user live → 08 (grilling, HITL); AFK → 09
   (design). Work it; fold the resolution into map + ticket.

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
