# Catchup prompt — Automatic Session Rollover

## Mission

No active implementation task. Confirm with the user whether any new mission
exists beyond the already-completed PR #35 merge-conflict resolution.

## Read these, in order

1. `work/automatic-session-rollover/handoff.md` (top block only)
2. `scripts/tests/test-launch-next-session.sh` (T23 and C1–C5 sections)
3. `scripts/tests/test-rollover-clear-seed.sh`

## Do NOT reload

- Archived handoff history in `work/automatic-session-rollover/handoff-archive.md`
- Previously closed map/issues unless user explicitly reopens them

## State snapshot

- Branch: `feat/clear-in-place-rollover`
- Latest conflict-resolution merge commit: `a075cb8`
- No known pending local code edits expected for this work item

## First actions

1. `scripts/context-budget.sh register --project automatic-session-rollover`
2. Ask the user for the next mission (or confirm done).
