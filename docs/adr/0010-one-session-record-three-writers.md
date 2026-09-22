# ADR-0010: One session-state record per work item, with three writers and process liveness as the only ownership test

- Status: accepted
- Date: 2026-09-21
- Deciders: Kashif + Claude Code sessions 8–16 of `template-improvement-review` (Stage 2 design, Stage 3 review, Stage 4 phases 1–8)

## Context

By September 2026 the session machinery kept twelve machine-local files per
work item (`.session-seq`, `.session-seq.bump.json`, `.next-command`,
`.session-loop`, `.chain-closed`, `.rollover-complete`, `.active-session`,
`.agent-locks/`, `.rollover-options`, `.pending-clear-seed`, …), each written
by one script and read by others, with agent-written sentinels and inference
paths (mtime scans, a lineage gate that reclaimed numbers on evidence) between
them. Three "I think I rolled over" incidents, a duplicate session started
from a stale command file, and a chain halted by a drifted sentinel all came
from readers and writers disagreeing about state that lived in several places.
Session roles (`primary`/`auxiliary`/`child`/`superseded`) and their stamps
were another layer of inference over the same facts.

## Decision

Every fact about a work item's current launch lives in one machine-local file,
`work/<item>/session-state.json`: `seq` (the session number), `launch` (who
launched, how, the predecessor, a pending in-place restart), `session` (the
owner), `staged` (the successor's command under a supervisor), `chain` (the
supervisor's budget). Three scripts write it, each its own block, all through
one helper (`scripts/lib/session-lib.sh`: read, precondition, filter, temp
file, rename, under a lock): the launcher writes `seq`, `launch` and `staged`;
`context-budget.sh` writes `session`; `session-loop.sh` writes `chain` and
consumes `staged`. Hooks and gates only read it.

The owner is the record's `session`; it is alive while its process id is
running and was started when `pid_start` says. Where a runtime has no process
of its own, the transcript's age is the fallback. There are no roles, no
locks and no stamps: another session is measured but cannot roll the item
over, and a human takes it over with one flag, logged with the loser.

Session numbers are never reused. The successor finds its number without
guessing: the launcher passes it in the environment, an in-place restart
matches by process id, and whoever explicitly registers against an open launch
becomes that session. An orphaned launch is closed as `abandoned` at the next
bump.

## Alternatives considered

- **The launcher as the record's sole author** — rejected: the successor's id
  is born at its own `register`, so the measurer must write the owner block.
- **A dual-write migration (record beside the old files for a release)** —
  rejected: keeps every inference path alive; the cut was made in one change
  per script with the suites rewritten alongside, and the only compatibility
  code is a one-time import of the old counter.
- **A tracked record** — rejected: it names processes on one machine, dirties
  every session, defeats the supervisor's stall guard and collides across
  people.
- **Reclaiming a number on evidence (the lineage gate)** — rejected: the
  cluster of defects this ADR exists to remove; a gap in the lineage is cheap,
  a reclaimed number is a duplicate session.
- **Environment-only identity for a background daemon launch** — rejected: the
  Stage 2 probe showed the environment is captured by the first daemon and
  replayed into later sessions, so the launch could never be bound exactly; the
  background path was deleted instead.

## Consequences

- One file to read when anything is in doubt; one lib to test for atomicity.
- Superseded mechanisms: ADR-0007's `.session-seq` counter and ADR-0008's
  `seq-sync` (their rulings — the bootstrap prompt's number is canonical, and
  a session asserts rather than writes — stand, carried by `seq` and the
  launcher's `ledger_seq_mismatch` gate). ADR-0005's roles, lineage stamps and
  child locks are gone; its child registry moved unchanged to `scripts/fleet.sh`.
  ADR-0004's lock is the record's owner slot; ADR-0009's seed file is
  `launch.pending`.
- A hand edit of the record is the new way to break a chain (`staged_invalid`);
  the skill forbids it.
- Copilot CLI and Gemini identify a session by its newest transcript, so
  ownership there is a heuristic while those runtimes stay unverified (design
  decision 3a).

## Provenance

- Promoted from: `work/template-improvement-review/decisions.md` (Stage 2/3
  decisions, sessions 8–10) and `work/template-improvement-review/plans/phase-1.md`
  … `phase-8.md` (per-phase decisions).
- Commits: Stage 4 phases 1–8 on `stage4` (phase 8: `12ba7d8`, the last
  mirrors removed).
- Supersedes: ADR-0007, ADR-0008 (mechanism); amends ADR-0004, ADR-0005,
  ADR-0006, ADR-0009.
- Refs: `work/template-improvement-review/evaluation/stage3-design-v2.md`
  ("The record and its three writers", "Who is alive", "How the successor
  finds its number"); `session-management-review-findings.md` §(k).
