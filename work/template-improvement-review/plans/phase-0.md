# Phase 0 plan — end the chain, flip the default, script the import

Ticket: `issues/01-phase-0-end-chain-and-import.md`. Plan of record: Part 4 of
`session-management-review-findings.md` (line 765). Written and executed in
session 10 (2026-09-16).

## Why this phase exists

Bash reads a script as it runs, so editing `session-loop.sh` while the live
supervisor (pid 72900, started 2026-09-14) runs it would corrupt that process.
Nothing under `scripts/` that the supervisor runs may change until the chain
has ended. The other three tasks are small preconditions that need no chain.

## Tasks

| # | Task | Check | Status |
|---|---|---|---|
| 1 | End the live chain: session 10 is the supervisor's interactive pause; it quits with nothing staged, which the old supervisor logs as a deliberate quit and exits 0. Nothing is edited in `session-loop.sh`. | `.session-loop` state file gone; `ps -p 72900` empty; log ends with the quit verdict | done at session end (see "Ending the chain") |
| 2 | Root `ROLLOVER_RELAUNCH` → `manual`; committed `work/template-improvement-review/context-budget.env` keeps this item on `auto` | `test-launch-next-session.sh` T15 (per-item override) still green; both files in one commit | done |
| 3 | Pin `jq` as a hard requirement | `test-check-dependencies.sh` D5a/D5b: absent → exit 1 with `jq … MISSING (required)`; present → no MISSING line | done |
| 4 | `SESSION_LOOP_NOTIFY` no longer depends on `ROOT` | `test-session-loop-notify.sh` N4: sourcing the root env with `ROOT` unset, from another cwd, under `set -u`, yields the workspace hook path | done |
| 5 | Import script `scripts/import-session-seq.sh <project>` + `scripts/tests/test-import-session-seq.sh` on a throwaway item | I1–I9: seq equals counter; second run no-op and byte-identical; moved-on counter re-imported; record ahead → `seq_conflict`; bad inputs → `counter_unreadable` / `record_unreadable`; no jq → `jq_missing`; other blocks survive | done, 26 asserts |

## Decisions made here (Tier 2 in `decisions.md`)

- The record file is `work/<item>/session-state.json` and the import writes
  `{"schema": 1, "seq": N}`. Phase 1 inherits schema version 1 as this shape
  and adds blocks to it; if phase 1 changes the version, the import script
  is updated in the same commit.
- Import semantics: record absent or behind the counter → write; equal →
  no-op; ahead → refuse. The counter is not deleted (old scripts still use
  it until cutover), so idempotence is by comparison, not by consuming it.
- The notify path resolves from the env file's own location
  (`${BASH_SOURCE[0]}`), not from a caller variable. Every sourcer is bash.

## Ending the chain — amended 2026-09-17: chain kept

**Amendment (user, 2026-09-17):** each wave runs in its own session and the
successor is kicked off automatically, so the live chain is kept. It is safe
because the waves build on an integration branch (`stage4`) and `main`, which
the supervisor and the parent's hooks run from, stays frozen until cutover.
Cutover stops the chain first (plain quit), then merges. The original text:

The old supervisor's verdict for "child exited 0, nothing staged, counter
unmoved" is a deliberate quit (`session-loop.sh`, the `delta -eq 0` branch):
it logs the quit and exits 0. So the chain ends correctly when this session
is closed by hand with nothing staged. The session therefore stages no
successor, and session 11 is started by hand with the launcher's bootstrap
prompt. The `.session-loop*` files are ignored runtime state and are left for
the supervisor to clean.

## Not done here

- `.gitignore` entry for `work/*/session-state.json`: phase 8 (the record is
  not written on any real item until cutover; the test uses a temp tree).
- Docs on the relaunch default beyond the one paragraph corrected in
  `docs/context-budget.md`: phase 8 rewrites those sections.
