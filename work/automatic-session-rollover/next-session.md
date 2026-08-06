# Catchup prompt — Automatic Session Rollover (paste into a new agent session)

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, REPLACED at
> each rollover. Past-tense provenance lives in `handoff.md` (append-only
> ledger, newest block on top). Convention: docs/work-directory-conventions.md.

## Mission

Slices 1, 2 and issue 05 are COMPLETE (roles/registry/locks → ADR-0005;
`children` sweep R1; workspace-root anchoring — state keyed to repository,
worktree launch-sync mechanized). **The next slice needs a user pick**:

- (a) research §14 slice 3 — SDD dispatch-contract hardening (R2/R3);
- (b) slice 4 — wayfinder tickets;
- (c) promote the session-19 decision note to an ADR (small, could precede
  either) — "coordination state keyed to repository identity" amending
  ADR-0004/0005.

Ask the user which, then plan it in the slice-2/issue-05 pattern
(`plans/` file + TDD).

## Read these, in order

1. `handoff.md` top block — session-19 record (what issue 05 shipped).
2. On the chosen slice only: research §14 (slices 3/4) or the session-19
   `decisions.md` note (ADR promotion, tail of file).
3. On demand: `plans/workspace-root-anchoring.md` (freshest slice-plan
   pattern); `docs/context-budget.md` → "Worktrees" (the shipped contract);
   ADR-0005.

## Do NOT reload

- Research md/HTML beyond §14 — reviewed, settled; distilled into ADR-0005,
  plan files, `docs/context-budget.md`.
- `rollover-scenarios.md` — load only if the chosen slice needs specific rows.
- Issues 01–03/05 — 01 spun out (needs Copilot-licensed machine), 02/03/05
  resolved. Issue 04 (in-place `/clear` relaunch) is parked by the user — do
  not schedule it unprompted.
- Sessions ≤18 handoff blocks, `handoff-archive.md` — settled.
- Slice-1/2/issue-05 design debates (child identity, roles, takeover,
  children-vs-check-flag, sidechain measure, repo-vs-checkout keying,
  shared-lib-vs-duplicated resolver) — decided; see ADR-0005 + plan files +
  decisions.md.

## Constraints already decided (do not re-litigate)

- Role schema final: primary / auxiliary / child / superseded (+
  `superseded_by`, `--takeover`).
- `children` sweep is escalation-only, claude-adapter-only; throttling/
  ledger writes belong to a future hook-wiring slice.
- Coordination state is repository-keyed (`git rev-parse --git-common-dir`);
  worktree relaunch is now allowed and mechanized. Register-before-isolate
  is obsolete.
- Runtime state stays gitignored. Standing push-to-main approval applies.

## State snapshot (at session-19 rollover, 2026-08-06)

- `origin/main` carries the issue-05 commit (`a850d7b`) + session-19
  rollover commit. If auto-relaunch ran, the main checkout was ff-pulled by
  the launcher; otherwise `git pull --ff-only` it.
- All six suites green: registry 60, attach 22, launcher 81, statusline 16,
  vendor 37, children 27 (243 asserts).
- Worktrees (all pushed, disposable — prune when convenient):
  `issue-05-workspace-root-anchoring` (session 19's), `slice-2-children-sweep`,
  `slice-1-t13-t14`, `slice-1-registry-schema`, `issue-02-permission-mode-auto`.
- `issues/04-in-place-clear-relaunch.md` untracked in the user's checkout —
  parked by user choice.
- No background agents. Session-19 lock released by the launcher (or
  manually if the auto path was skipped).
- Parked learning (first strike): stale `role=primary` records accumulate in
  `.context-budget/sessions/` from sessions that never released; cosmetic —
  lock is authoritative.

## First actions

1. `scripts/context-budget.sh register --project automatic-session-rollover`
   — expect `role=primary`; if session 19 was auto-relaunched, its record
   should show `superseded_by` stamped with YOUR session id (first live
   T13-via-launcher check).
2. Confirm checkout carries `a850d7b` (`git log --oneline -3`); pull if not.
3. Ask the user to pick slice (a)/(b)/(c) above, then plan + TDD it.

## At session end

Lock releases mechanically (launcher script or SessionEnd hook). Manual
fallback: `scripts/context-budget.sh release --project automatic-session-rollover`.
