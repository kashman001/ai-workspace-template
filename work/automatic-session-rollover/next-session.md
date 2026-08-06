# Catchup prompt — Automatic Session Rollover (paste into a new agent session)

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, REPLACED at
> each rollover. Past-tense provenance lives in `handoff.md` (append-only
> ledger, newest block on top). Convention: docs/work-directory-conventions.md.

## Mission

Finish implementation **slice 1** (registry/lock schema extension, R4/R5).
Cycles 1–3 shipped in session 16 (`4c6569e`): child records
(`parent_session_id`/`depth`/`agent_id`, role `child`), per-child locks in
`work/<p>/.agent-locks/` with transitive parent-chain validation, and the
I4 release-order guard (stale sweep + bottom-up refusal), tests T7–T12
green. Remaining: T13 `superseded_by` back-stamp at successor register, T14
`--takeover` (explicit recorded steal), then docs + tracker follow-through.
The design doc `subagent-rollover-research.html` remains user-reviewed; no
new design work unprompted.

## Read these, in order

1. `plans/slice-1-registry-schema.md` — the slice plan: design decisions,
   T13/T14 specs, follow-through checklist. THE working document.
2. `handoff.md` top block — session-16 record.
3. On demand only: `scripts/context-budget.sh` (register/acquire_lock/
   cmd_release — the code under change); registry test suite T7–T12 for
   harness idioms; `issues/03-session-roles.md` for the deferred-item
   wording being folded in.

## Do NOT reload

- Research md/HTML — slice-1-relevant parts (§5/§6, R4/R5) are already
  distilled into the plan file.
- `rollover-scenarios.md` — consulted; only the follow-through note-append
  touches it.
- Issues 01/02, sessions ≤15 handoff blocks, `handoff-archive.md` — settled.
- The L21 statusline chaining fix — shipped (`3f97027`), tested, backlogged.
- Role vocabulary debate — decided: `child` extends the role set
  (decisions.md 2026-08-06 session 16).

## Constraints already decided (do not re-litigate)

- Child identity is artifact-derived, never env; children never contend for
  the project lock; liveness lives in the release-time stale sweep only.
- Ladder/roles/verb constraints from sessions ≤15 stand (see previous
  launcher via git history if ever needed — do not reload wholesale).
- Runtime state stays gitignored. Standing push-to-main approval applies.

## State snapshot (at session-16 rollover, 2026-08-06)

- `origin/main` at `4c6569e`; worktree `slice-1-registry-schema` fully
  pushed; **user's main checkout behind until `git pull --ff-only`** (live
  statusline fix inert until then).
- All 5 test suites green (registry 45, launcher 65, attach 22,
  statusline 14, vendor hooks 37).
- No background agents. Session-16 worktree lock released at rollover;
  main-checkout lock free.

## First actions

1. `scripts/context-budget.sh register --project automatic-session-rollover`
   — expect `role=primary`, and (once T13 lands — not before) check the
   predecessor back-stamp behavior live.
2. Confirm checkout at/past `4c6569e` (`git log --oneline -1`); pull if not.
3. TDD T13 then T14 per the plan file, registry-suite style; then the
   follow-through checklist (docs, issues/03, backlog card L22?, scenario
   notes, decisions promote-check).

## At session end

Lock releases mechanically (launcher script or SessionEnd hook). Manual
fallback: `scripts/context-budget.sh release --project automatic-session-rollover`.
