# Catchup prompt — Automatic Session Rollover (paste into a new agent session)

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, REPLACED at
> each rollover. Past-tense provenance lives in `handoff.md` (append-only
> ledger, newest block on top). Convention: docs/work-directory-conventions.md.

## Mission

The user ordered the remaining slices (b) → (c) → (a); (b) R4
dispatch-records is COMPLETE (session 22). **No user pick needed — do (c),
then (a):**

- **(c) registry-hygiene mini-slice (next):** `register`-time sweep of
  stale `role=primary` records in `.context-budget/sessions/` (parked
  learning, sessions 19/21; small). Plan in the established pattern
  (`plans/` file + TDD), likely inside `cmd_register`/near
  `backstamp_superseded` in `scripts/context-budget.sh`.
- **(a) research §14 slice 4 (after):** wayfinder decision tickets for the
  open questions — mid-flight hook injection into running claude children;
  copilot child artifact location; per-role thresholds. Use the `wayfinder`
  skill; maps live under `work/<effort>/` per `docs/agents/issue-tracker.md`
  → "Wayfinding operations".

## Read these, in order

1. `handoff.md` top block — session-22 record (R4 shipped).
2. For (c): `scripts/context-budget.sh` — `cmd_register`,
   `backstamp_superseded`, `lock_holder_age` regions only; the parked
   Learnings line in the handoff top block is the whole problem statement.
3. For (a) only when (c) is done: research §14.4 + §3/§8 open questions;
   `skills/wayfinder/SKILL.md`.
4. On demand: `plans/dispatch-records-r4.md` (freshest slice-plan pattern);
   ADR-0005/0006.

## Do NOT reload

- Research md/HTML beyond the sections named above — reviewed, settled;
  distilled into ADR-0005/0006, plan files, `docs/context-budget.md`.
- `rollover-scenarios.md` — load only if a slice needs specific rows.
- Issues 01–03/05 — 01 spun out (needs Copilot-licensed machine), 02/03/05
  resolved. Issue 04 (in-place `/clear` relaunch) is parked by the user — do
  not schedule it unprompted.
- Sessions ≤21 handoff blocks, `handoff-archive.md` — settled.
- Slice-1/2/3/R4/issue-05 design debates (child identity, roles, takeover,
  children-vs-check-flag, sidechain measure, repo-vs-checkout keying,
  emitter-vs-prose contract, record-storage placement, fencing enforcement
  point) — decided; see ADR-0005/0006 + plan files + decisions.md.

## Constraints already decided (do not re-litigate)

- Role schema final: primary / auxiliary / child / superseded (+
  `superseded_by`, `--takeover`).
- `children` sweep is escalation-only, claude-adapter-only; throttling/
  ledger writes belong to a future hook-wiring slice.
- Coordination state is repository-keyed (ADR-0006); worktree relaunch is
  mechanized.
- R2 contract emitted by `dispatch-contract`; R3 = roll-don't-resume,
  parent-side; R4 records/fencing shipped via `dispatch-open`/`close`/
  `list` (records in gitignored `work/<proj>/.agent-dispatch/`; fencing at
  open; `KILLED` = parent ruling). Drain mode (R6) stays deferred.
- Runtime state stays gitignored. Standing push-to-main approval applies.

## State snapshot (at session-22 rollover, 2026-08-06)

- `origin/main` carries `1713daa` (R4) + the session-22 rollover commit. If
  auto-relaunch ran, the main checkout was ff-pulled by the launcher;
  otherwise `git pull --ff-only` it.
- All eight suites green: registry 60, attach 22, launcher 81, statusline
  16, vendor 37, children 27, dispatch-contract 24, dispatch-records 51
  (318 asserts).
- Worktrees (all pushed, disposable — prune when convenient):
  `session-22-r4-dispatch-records` (this session's),
  `session-21-adr-0006-slice-3`, `issue-05-workspace-root-anchoring`,
  `slice-2-children-sweep`, `slice-1-t13-t14`, `slice-1-registry-schema`,
  `issue-02-permission-mode-auto`.
- `issues/04-in-place-clear-relaunch.md` untracked in the user's checkout —
  parked by user choice.
- No background agents. Session-22 lock released by the launcher (or
  manually if the auto path was skipped).
- Parked learning (carried; slice (c) retires it): stale `role=primary`
  records accumulate in `.context-budget/sessions/`; cosmetic — lock is
  authoritative.

## First actions

1. `scripts/context-budget.sh register --project automatic-session-rollover`
   — expect `role=primary`; session 22's record should show `superseded_by`
   stamped with YOUR session id.
2. Confirm checkout carries `1713daa` (`git log --oneline -3`); pull if not.
3. Plan slice (c) (`plans/` file + TDD), ship it, then move to slice (a).

## At session end

Lock releases mechanically (launcher script or SessionEnd hook). Manual
fallback: `scripts/context-budget.sh release --project automatic-session-rollover`.
