# Catchup prompt — Automatic Session Rollover (paste into a new agent session)

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, REPLACED at
> each rollover. Past-tense provenance lives in `handoff.md` (append-only
> ledger, newest block on top). Convention: docs/work-directory-conventions.md.

## Mission

Implementation **slice 1 is COMPLETE** (registry/lock schema, R4/R5:
child registry T7–T12, `superseded_by` back-stamp T13, `--takeover` T14 —
all follow-through done, promoted to ADR-0005). The mission now: **agree the
next implementation slice with the user and start it.** Candidates: the next
slice in the research doc's implementation-slice list (§14 — demand-load
only that section), or a user re-prioritization. Do not start coding a slice
without confirming the pick.

## Read these, in order

1. `handoff.md` top block — session-17 record (what slice 1 shipped).
2. `subagent-rollover-research.md` §14 ONLY — the slice list; pick the next.
3. On demand: `docs/adr/0005-session-roles-and-child-registry.md` (the now-
   final role/registry schema any next slice builds on);
   `plans/slice-1-registry-schema.md` (pattern for a slice plan file).

## Do NOT reload

- Research md/HTML beyond §14 — reviewed, settled; slice-1-relevant parts
  are distilled into ADR-0005 and the plan file.
- `rollover-scenarios.md` — consulted; has an "Implementation notes" section
  now; load only if the chosen slice needs specific scenario rows.
- Issues 01/02/03 — 01 spun out (needs Copilot-licensed machine), 02/03
  resolved. Issue 04 (in-place `/clear` relaunch) is deliberately parked by
  the user — do not schedule it unprompted.
- Sessions ≤16 handoff blocks, `handoff-archive.md` — settled.
- Slice-1 design debates (child identity, role vocabulary, liveness
  placement, takeover semantics) — decided; see ADR-0005 if ever needed.

## Constraints already decided (do not re-litigate)

- Role schema is final: primary / auxiliary / child / superseded (+
  `superseded_by`, `--takeover`). Future session kinds extend, not overload.
- Children never contend for the project lock; liveness lives in the
  release-time stale sweep only; release is bottom-up (I4).
- Runtime state stays gitignored. Standing push-to-main approval applies.
- Auto-relaunch is never invoked from inside a worktree (operational rule).

## State snapshot (at session-17 rollover, 2026-08-06)

- `origin/main` carries the session-17 commit (slice-1 completion);
  **user's main checkout behind until `git pull --ff-only`**.
- All 5 test suites green (registry 54, launcher 65, attach 22,
  statusline 14, vendor hooks 37).
- Worktrees: `slice-1-t13-t14` (this session's, pushed, disposable);
  `slice-1-registry-schema` (session 16's, lock-held by a `claude bg-spare`
  daemon — prune when it exits); `issue-02-permission-mode-auto` (old).
- `issues/04-in-place-clear-relaunch.md` untracked in the user's checkout —
  parked by user choice; commit or leave as they prefer.
- No background agents. Session-17 lock released at rollover.

## First actions

1. `scripts/context-budget.sh register --project automatic-session-rollover`
   — expect `role=primary`; the session-17 record should now show
   `superseded_by` stamped with YOUR session id (T13 live check).
2. Confirm checkout carries the session-17 commit (`git log --oneline -1`
   mentions slice-1 T13/T14); `git pull --ff-only` if not.
3. Read research §14, propose the next slice to the user, then plan it as
   `plans/<slice-name>.md` in the slice-1 pattern and TDD it.

## At session end

Lock releases mechanically (launcher script or SessionEnd hook). Manual
fallback: `scripts/context-budget.sh release --project automatic-session-rollover`.
