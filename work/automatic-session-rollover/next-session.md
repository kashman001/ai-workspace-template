# Catchup prompt — Automatic Session Rollover (paste into a new agent session)

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, REPLACED at
> each rollover. Past-tense provenance lives in `handoff.md` (append-only
> ledger, newest block on top). Convention: docs/work-directory-conventions.md.

## Mission

The subagent-rollover design is under **active user review** of
`subagent-rollover-research.html` — do not start work unless the user prompts.
Session 14 shipped two side units: the M14 lock-release-before-launch fix
(`c45969d`) and the runtime-state gitignore (`bc3fab3`). Next: respond to
review findings as the user raises them; when review settles, start
implementation next-steps item 1 (registry/lock schema extension in
`context-budget.sh` — agent records with `parent_session_id`/`depth`,
per-child locks, release-order guard; R4/R5), using the scenario catalog as
the harness (M-class scenarios first).

## Read these, in order

1. `handoff.md` top block — session-14 record.
2. On demand only: `rollover-scenarios.md` (catalog + dimensions); research md
   by §-pointer (§13 eval model, §3 parent positions); HTML only for the
   section being edited.

## First actions

1. `scripts/context-budget.sh register --project automatic-session-rollover`
   — **verify the lock is ACQUIRED cleanly**: this bootstrap is the first
   real verification of the M14 fix (predecessor's lock released by
   `launch-next-session.sh` pre-launch). If `register` reports the lock held
   by the predecessor, the fix regressed — that's a finding; reclaim needs
   `CONTEXT_DUMB_ZONE_TOKENS=150000 CONTEXT_LOCK_STALE_SECS=<small>` (see
   backlog L18) and the regression goes to the backlog.
2. Report readiness and wait for the user (they are mid-review; standing
   instruction: no new work unprompted). If they green-light implementation
   slice 1: TDD per the harness style in `scripts/tests/` (mktemp fixtures,
   `touch -t` mtimes).

## Do NOT reload

- `handoff-archive.md` and blocks before session 14 — superseded.
- The full HTML file — mirror of md content; open only the section under edit.
- Backlog cards **L17**/**L18** — separate follow-up threads.
- The M14 fix details — shipped, tested, documented; re-derive nothing.
- The gitignore/tracked-vs-untracked discussion — codified in
  `docs/work-directory-conventions.md`; don't re-litigate.

## Constraints already decided (do not re-litigate)

- Vendor-agnostic layering; child rollover verb = successor dispatch, never
  resume; parent never rolls with live children (drain; I4).
- Parent kinds = node *position* (root vs intermediate) — `depth`/
  `parent_session_id` suffice (decisions.md 2026-08-06).
- Lock release lives in `launch-next-session.sh`, pre-launch (decisions.md
  2026-08-06, backlog M14).
- Runtime state (`.active-session`, `.rollover-options`, context ledger) is
  gitignored; commit only what a future session must read.
- Scenarios-before-implementation: done; implementation may begin when the
  user says so. Standing push-to-main approval applies.

## State snapshot (at session-14 rollover, 2026-08-06)

- Branch `main` pushed through `bc3fab3`; working tree clean (this rollover's
  ledger/launcher commit follows). No background agents, servers, worktrees.
- `.active-session` and `context-ledger.jsonl` are now untracked (still on
  disk, hook-maintained).
- `work/automatic-session-rollover/context-budget.env` sets
  `ROLLOVER_RELAUNCH=auto`; no `.rollover-options` (launch flags unknown).

## At session end

The lock is released automatically by `scripts/launch-next-session.sh` at
rollover; if this session ends without invoking it, release manually:
`scripts/context-budget.sh release --project automatic-session-rollover`.
