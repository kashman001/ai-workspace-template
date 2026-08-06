# Catchup prompt — Automatic Session Rollover (paste into a new agent session)

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, REPLACED at
> each rollover. Past-tense provenance lives in `handoff.md` (append-only
> ledger, newest block on top). Convention: docs/work-directory-conventions.md.

## Mission

The subagent-rollover design is under **active user review** of
`subagent-rollover-research.html`. Session 13 resolved the first review
finding (root vs intermediate parent positions → HTML §2.2, S53/S54) and
shipped the full scenario catalog (S11–S54, `rollover-scenarios.md`,
mirrored HTML §7). Next: respond to further review findings as the user
raises them; when review settles, start implementation next-steps item 1
(registry/lock schema extension in `context-budget.sh` — agent records with
`parent_session_id`/`depth`, per-child locks, release-order guard; R4/R5),
using the catalog as the harness (M-class scenarios first).

## Read these, in order

1. `handoff.md` top block — session-13 record (what shipped, parked
   learnings).
2. On demand only: `rollover-scenarios.md` (catalog + dimension set);
   research md by §-pointer (§13 eval model, §3 parent positions); HTML only
   for the section being edited.

## First actions

1. `scripts/context-budget.sh register --project automatic-session-rollover`
   (also `git pull --ff-only` if the checkout lags origin/main).
2. Ask the user whether to continue doc review or begin implementation
   slice 1 (above). If starting implementation: TDD per the harness style in
   `scripts/tests/` (mktemp fixtures, `touch -t` mtimes).

## Do NOT reload

- `handoff-archive.md` and blocks before session 13 — superseded.
- The full HTML file — mirror of md content; open only the section under
  edit.
- The research-agent transcripts/scratchpad — captured in the three
  committed research files.
- Backlog card **L17** — separate follow-up thread.
- The learnings/retro discussion — codified in `skills/session-rollover/
  SKILL.md` (Reflect step) + `skills/checkpoint/SKILL.md`; don't re-derive.

## Constraints already decided (do not re-litigate)

- Vendor-agnostic layering; child rollover verb = successor dispatch, never
  resume; parent never rolls with live children (drain; I4).
- Parent kinds = node *position* (root vs intermediate), not a type enum —
  `depth`/`parent_session_id` suffice (decisions.md 2026-08-06).
- Scenarios-before-implementation: done — the catalog exists; implementation
  may begin when the user says so.
- Standing push-to-main approval applies.

## State snapshot (at session-13 rollover, 2026-08-06)

- Branch `main` pushed through `536fd9c`; this rollover's commit follows
  (ledger restructure + decisions notes + launcher). `.active-session` lock
  released at session end; `work/context-decay/context-ledger.jsonl`
  hook-maintained.
- No running background agents, servers, or worktrees.
- `work/automatic-session-rollover/context-budget.env` sets
  `ROLLOVER_RELAUNCH=auto` — the successor is launched by
  `scripts/launch-next-session.sh`. No `.rollover-options` file (launch
  flags unknown; runtime defaults).

## At session end

Release the lock: `scripts/context-budget.sh release --project automatic-session-rollover`.
