# Catchup prompt — Automatic Session Rollover (paste into a new agent session)

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, REPLACED at
> each rollover. Past-tense provenance lives in `handoff.md` (append-only
> ledger, newest block on top). Convention: docs/work-directory-conventions.md.

## Mission

Slices 1–3, issue 05 and ADR-0006 are COMPLETE (roles/registry/locks →
ADR-0005; `children` sweep R1; repository-keyed state → ADR-0006;
dispatch-contract R2/R3). **The next slice needs a user pick**:

- (a) research §14 slice 4 — wayfinder decision tickets for the open
  questions (mid-flight hook injection into running claude children; copilot
  child artifact location; per-role thresholds);
- (b) R4 — parent-persisted dispatch records + generation fencing (the next
  mechanization; makes parent rollover fleet-safe and enables faithful
  re-dispatch);
- (c) registry-hygiene mini-slice — `register`-time sweep of stale
  `role=primary` records (parked learning, sessions 19/21; small).

Ask the user which, then plan it in the established pattern
(`plans/` file + TDD).

## Read these, in order

1. `handoff.md` top block — session-21 record (ADR-0006 + slice 3).
2. On the chosen slice only: research §14.4 + §3/§8 open questions (a);
   research §5 "dispatch record" + §8 "Generation fencing" (b); the
   session-19/21 handoff Learnings lines (c).
3. On demand: `plans/slice-3-dispatch-contract.md` (freshest slice-plan
   pattern); `docs/context-budget.md` → "Dispatching long-running children"
   (the shipped R2/R3 contract); ADR-0005/0006.

## Do NOT reload

- Research md/HTML beyond the sections named above — reviewed, settled;
  distilled into ADR-0005/0006, plan files, `docs/context-budget.md`.
- `rollover-scenarios.md` — load only if the chosen slice needs specific rows.
- Issues 01–03/05 — 01 spun out (needs Copilot-licensed machine), 02/03/05
  resolved. Issue 04 (in-place `/clear` relaunch) is parked by the user — do
  not schedule it unprompted.
- Sessions ≤19 handoff blocks, `handoff-archive.md` — settled.
- Slice-1/2/3/issue-05 design debates (child identity, roles, takeover,
  children-vs-check-flag, sidechain measure, repo-vs-checkout keying,
  emitter-vs-prose contract) — decided; see ADR-0005/0006 + plan files +
  decisions.md.

## Constraints already decided (do not re-litigate)

- Role schema final: primary / auxiliary / child / superseded (+
  `superseded_by`, `--takeover`).
- `children` sweep is escalation-only, claude-adapter-only; throttling/
  ledger writes belong to a future hook-wiring slice.
- Coordination state is repository-keyed (ADR-0006); worktree relaunch is
  mechanized. Register-before-isolate is obsolete.
- R2 contract is emitted by `dispatch-contract` (single source of truth,
  ASCII-only); R3 (roll, don't resume, at child WARN/STOP) is parent-side
  policy — a child never self-assesses (D1).
- Runtime state stays gitignored. Standing push-to-main approval applies.

## State snapshot (at session-21 rollover, 2026-08-06)

- `origin/main` carries `d2ee5dd` (ADR-0006) + `6fc7cec` (slice 3) + the
  session-21 rollover commit. If auto-relaunch ran, the main checkout was
  ff-pulled by the launcher; otherwise `git pull --ff-only` it.
- All seven suites green: registry 60, attach 22, launcher 81, statusline
  16, vendor 37, children 27, dispatch-contract 24 (267 asserts).
- Worktrees (all pushed, disposable — prune when convenient):
  `session-21-adr-0006-slice-3` (this session's),
  `issue-05-workspace-root-anchoring`, `slice-2-children-sweep`,
  `slice-1-t13-t14`, `slice-1-registry-schema`,
  `issue-02-permission-mode-auto`.
- `issues/04-in-place-clear-relaunch.md` untracked in the user's checkout —
  parked by user choice.
- No background agents. Session-21 lock released by the launcher (or
  manually if the auto path was skipped).
- Parked learning (first strike, carried): stale `role=primary` records
  accumulate in `.context-budget/sessions/`; cosmetic — lock is
  authoritative. Option (c) above would retire it.

## First actions

1. `scripts/context-budget.sh register --project automatic-session-rollover`
   — expect `role=primary`; session 21's record should show `superseded_by`
   stamped with YOUR session id.
2. Confirm checkout carries `6fc7cec` (`git log --oneline -3`); pull if not.
3. Ask the user to pick slice (a)/(b)/(c) above, then plan + TDD it.

## At session end

Lock releases mechanically (launcher script or SessionEnd hook). Manual
fallback: `scripts/context-budget.sh release --project automatic-session-rollover`.
