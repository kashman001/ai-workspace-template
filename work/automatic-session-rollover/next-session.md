# Catchup prompt — Automatic Session Rollover (paste into a new agent session)

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, REPLACED at
> each rollover. Past-tense provenance lives in `handoff.md` (append-only
> ledger, newest block on top). Convention: docs/work-directory-conventions.md.

## Mission

Implementation **slices 1 and 2 are COMPLETE** (slice 1: roles/registry/locks
→ ADR-0005; slice 2: `children` per-child sweep, R1). The mission now:
**implement issue 05 — workspace-root anchoring** (`issues/
05-workspace-root-anchoring.md`), **already adopted by the user as the next
implementation work** — no slice-pick confirmation needed. It carries its own
codification plan (anchor `WORKSPACE_ROOT` to `git rev-parse
--git-common-dir`; mechanize the launch-sync step; TDD; decision capture).
Deferred behind it: research §14 slice 3 (SDD dispatch-contract hardening,
R2/R3) and slice 4 (wayfinder tickets) — those DO need a user pick.

## Read these, in order

1. `handoff.md` top block — session-18 record (what slice 2 shipped).
2. `issues/05-workspace-root-anchoring.md` — the adopted plan; plan it as
   `plans/workspace-root-anchoring.md` in the slice-2 pattern.
3. On demand: `docs/adr/0005-session-roles-and-child-registry.md`;
   `plans/slice-2-children-sweep.md` (freshest slice-plan pattern);
   `docs/context-budget.md` → "Per-child sweep" (the shipped R1 contract).

## Do NOT reload

- Research md/HTML beyond §14 — reviewed, settled; slice-relevant parts are
  distilled into ADR-0005, the plan files, and `docs/context-budget.md`.
- `rollover-scenarios.md` — load only if the chosen slice needs specific rows.
- Issues 01/02/03 — 01 spun out (needs Copilot-licensed machine), 02/03
  resolved. Issue 04 (in-place `/clear` relaunch) is parked by the user — do
  not schedule it unprompted.
- Sessions ≤17 handoff blocks, `handoff-archive.md` — settled.
- Slice-1/2 design debates (child identity, role vocabulary, takeover,
  children-vs-check-flag, sidechain-inclusive measure) — decided; see
  ADR-0005 + the two plan files if ever needed.

## Constraints already decided (do not re-litigate)

- Role schema is final: primary / auxiliary / child / superseded (+
  `superseded_by`, `--takeover`).
- `children` sweep is escalation-only, claude-adapter-only, exit = worst
  child status; throttling/ledger writes belong to a future hook-wiring slice.
- Children never contend for the project lock; release is bottom-up (I4).
- Runtime state stays gitignored. Standing push-to-main approval applies.
- Auto-relaunch is never invoked from inside a worktree (operational rule).

## State snapshot (at session-18 rollover, 2026-08-06)

- `origin/main` carries the slice-2 commit (`d194cc1`), issue 05
  (`1f5cfbf`, pushed by another session mid-rollover), and the session-18
  rollover commit; **user's main checkout behind until `git pull --ff-only`**.
- All six test suites green (registry 54, attach 22, launcher 65,
  statusline 14, vendor 37, children 27).
- Worktrees: `slice-2-children-sweep` (this session's, pushed, disposable);
  `slice-1-t13-t14`, `slice-1-registry-schema`, `issue-02-permission-mode-auto`
  (older, disposable — prune when convenient).
- `issues/04-in-place-clear-relaunch.md` untracked in the user's checkout —
  parked by user choice.
- No background agents. Session-18 lock released at rollover.

## First actions

1. `scripts/context-budget.sh register --project automatic-session-rollover`
   — expect `role=primary`; the session-18 record should show `superseded_by`
   stamped with YOUR session id (T13 live check).
2. Confirm checkout carries `d194cc1` (`git log --oneline -1` mentions
   slice 2); `git pull --ff-only` if not.
3. Read issue 05, plan it as `plans/workspace-root-anchoring.md` in the
   slice-2 pattern, and TDD it (no pick confirmation needed — user-adopted).

## At session end

Lock releases mechanically (launcher script or SessionEnd hook). Manual
fallback: `scripts/context-budget.sh release --project automatic-session-rollover`.
