# Phase 1 plan — the record helper (`scripts/lib/session-lib.sh`)

Ticket: `issues/02-phase-1-record-helper.md`. Plan of record: Part 4 of
`session-management-review-findings.md` (line 793); record table in
`evaluation/stage3-design-v2.md` lines 50–58. Built on branch `s4-phase-1`
(2026-09-17), test-first, no callers wired.

## Tasks

| # | Task | Check |
|---|---|---|
| 1 | Suite `scripts/tests/test-session-lib.sh` on a temp directory: race, byte-identical no-op, schema/unreadable reasons, empty filter refused | red before the library exists, green after |
| 2 | Library `scripts/lib/session-lib.sh`: one public function, `mkdir` lock, temp-and-rename write, precondition, block table comment | suite green |
| 3 | Every `scripts/tests/*.sh` rc = 0 | rc lines in Evidence |

## Interface

`session_record_update <record> <precondition> <filter> [jq-args...]`
(sourced library; bash 3.2). Trailing arguments go to every jq call, so callers
inject values with `--arg` / `--argjson` instead of quoting them into the filter.

- Reads `<record>` once under the lock `<record>.lock` (a `mkdir` lock). An
  absent record reads as `{"schema": 1}` so registration can open `seq` on an
  item that has no record yet; the caller's precondition decides whether an
  absent record is acceptable.
- Evaluates `<precondition>` with `jq -e` on the current record. False or null
  → **return 1**, nothing written, nothing printed ("no-op"; the lost side of a
  compare-and-set race).
- Applies `<filter>`; the result must be exactly one JSON object whose `schema`
  is still 1. Written to `<record>.tmp.<pid>` in the same directory, then
  `mv -f` over the record. **Return 0.**
- Refusals **return 4** with `session-lib: refused reason=<code> record=<path>`
  on stderr and the record untouched: `record_unreadable` (exists but cannot be
  read, is not JSON, or is not an object), `schema_mismatch` (`.schema` is not
  1), `precondition_invalid` (jq could not evaluate it), `filter_empty` (no
  output), `filter_invalid` (jq error, more than one value, not an object, or
  schema changed), `lock_timeout` (lock not obtained within the wait),
  `jq_missing`. **Return 3** on usage (fewer than three arguments).
- Lock wait `SESSION_RECORD_LOCK_WAIT_SECS` (default 15) polling every 0.05 s;
  a lock directory older than `SESSION_RECORD_LOCK_STALE_SECS` (default 10) is
  removed and re-taken. Both overridable from the environment (the suite uses
  that to test reclaim without waiting).

Exit codes follow the existing scripts: 0 ok, 3 usage, 4 refused with a
`reason=` line (`import-session-seq.sh`); 1 is the "ran fine, answer was no"
convention of `grep`/`cmp`.

## Decisions (Tier 2 candidates)

- **Precondition false returns 1, silent.** Rejected: return 0 and print a
  marker (callers would parse output to tell a write from a no-op).
- **Absent record reads as `{"schema": 1}`.** Rejected: refuse on absence and
  give registration a separate "create" entry point (a second public function
  for one caller; the precondition already expresses "only if no record").
- **Own small stale constant (10 s), not `CONTEXT_LOCK_STALE_SECS` (3 h).**
  That knob is the session-liveness lock: a holder is a whole session. A
  record write holds the lock for milliseconds, so a 3 h reclaim would block
  every writer for hours after one crash. The library therefore sources no
  env file and is location-independent.
- **Lock released by explicit code paths, no `trap`.** A sourced function
  setting `trap ... EXIT` would clobber the caller's trap. A signal between
  acquire and release leaves a lock that the stale rule reclaims.
- **Schema stays 1.** The library adds blocks to the phase-0 shape; the import
  script is unchanged.
- **Lock wait polls at 0.05 s.** Rejected: 0.2 s (the race test then spends
  most of its time sleeping; the poll costs nothing while the lock is free).

## Evidence

Suite for this phase: `test-session-lib: 55 passed, 0 failed` (S1–S11).
Race (S8): 3 concurrent writers x 20 `.seq += 1` each on one record → exactly
one valid JSON record, `seq == 60`, the untouched `chain` block kept, no
`.tmp.*` or `.lock` left. Compare-and-set race (S9): two writers on
`.seq == 0` → return codes `0 1`, `seq == 1`, the block names the winner.
Byte-identical after a false precondition (S3) and after every refusal
(S5–S7, S10f, S11): `cmp`. `schema_mismatch` → 4 (S5, including a record
with no `schema` field); `record_unreadable` for not-JSON, not-object,
empty and mode-000 records (S6); `filter_empty` / `filter_invalid` /
`precondition_invalid` (S7); lock waited for, stale lock reclaimed,
`lock_timeout` (S10); `jq_missing` (S11).

Every suite, run with `bash` from the worktree (2026-09-17):

```
scripts/tests/test-agent-entrypoints.sh rc=0
scripts/tests/test-attach-session.sh rc=0
scripts/tests/test-check-dependencies.sh rc=0
scripts/tests/test-children-sweep.sh rc=0
scripts/tests/test-context-budget-registry.sh rc=0
scripts/tests/test-dispatch-contract.sh rc=0
scripts/tests/test-dispatch-records.sh rc=0
scripts/tests/test-emit-mode.sh rc=0
scripts/tests/test-import-session-seq.sh rc=0
scripts/tests/test-launch-next-session.sh rc=0
scripts/tests/test-link-local-work.sh rc=0
scripts/tests/test-parameterization.sh rc=0
scripts/tests/test-rollover-clear-seed.sh rc=0
scripts/tests/test-rollover-prep.sh rc=0
scripts/tests/test-rollover-sentinel.sh rc=0
scripts/tests/test-seq-sync.sh rc=0
scripts/tests/test-session-lib.sh rc=0
scripts/tests/test-session-loop-notify.sh rc=0
scripts/tests/test-session-loop.sh rc=0
scripts/tests/test-session-numbering.sh rc=0
scripts/tests/test-statusline-context-budget.sh rc=0
scripts/tests/test-template-instantiation.sh rc=0
scripts/tests/test-turn-end-exit.sh rc=0
scripts/tests/test-vendor-budget-hooks.sh rc=0
```

Callers under `set -e` use `session_record_update … || rc=$?` (a bare call
returning 1 for a no-op would end the shell, as with any non-zero command);
checked from a `bash -eu` shell: no-op 1, refusal 4, write 0.
