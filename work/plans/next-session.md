# Catchup prompt — plans (paste into a new agent session)

We're resuming `plans`. Works in any runtime (Claude Code, Codex, Gemini,
OpenCode) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, REPLACED at
> each rollover: what to do next, still-binding constraints, pointers — never
> session history. Past-tense provenance lives in `handoff.md` (the ledger).
> Convention: docs/work-directory-conventions.md.

## Mission

Implement the tickets under `issues/` in dependency order, test-first, one
ticket per session unless a ticket is clearly small. Ticket 01 is done; the
frontier is ticket 02 (`plan.sh frontier`, `remaining`, `graph`).

## Read these, in order

1. `work/plans/issues/02-frontier-remaining-graph.md` — the ticket.
2. `docs/plans.md` — the format and the verbs that exist; extend it, don't
   restate it.
3. `scripts/plan.sh` — read it whole (~170 lines): `load_nodes` gives every
   verb a JSON array of nodes; add verbs as `cmd_<verb>` + a `case` arm.
4. `scripts/tests/test-plan.sh` — append `T8…` cases in the same style; the
   fixture `scripts/tests/fixtures/plan-01-concept/` mirrors the concept's
   worked example (frontier there = `07-spec` is `doing`, so `frontier`
   prints nothing until you adjust a copy of the fixture in the test).
5. `work/plans/spec.md` — only the S-items ticket 02 names (S13, S14, S16,
   S17) plus "Implementation Decisions" → Frontier.

## Do NOT reload

- `decisions.md` in full — every note is settled; open it only to append a
  new note or check one rejected alternative.
- `concept.md`, `seams.md` — the format is now in `docs/plans.md`.
- The grill — closed. Do not re-open the verdict, the status set, HITL
  semantics, markers, node kind, or the integration list.
- A runner, a Stop/SessionEnd hook, parallel checkouts, editing wayfinder
  (backlog L48) — all out of scope.

## Still binding

- Bash 3.2 + jq only; match `scripts/plan.sh`'s style. Exit codes 0/1/2 as
  documented. Text by default, `--json` on every read verb.
- Frontier: `todo` nodes whose blockers are all `done` or `dropped`,
  restricted to the lowest wave that still has unfinished nodes; print
  id, kind, tier (concept's sample: `06-reconcile-write   reconcile  frontier`).
- Wave names ("1 ground") live in no frontmatter — derive or omit; note the
  choice in the ledger for ticket 05 (board renderer).

## State snapshot

Branch `main`, clean after this rollover's commit; nothing pushed. Tickets:
01 `done`; 02–11 `ready-for-agent`; frontier = 02. Chain supervised by
`session-loop.sh` (seq 1 → 2 → 3 → 4). Budget at rollover: WARN (~118K).

## First actions

1. `scripts/context-budget.sh register --project plans` (expect `seq=4`).
2. No question to pose. Proceed hands-off.
3. `implement` ticket 02 with `tdd`: red cases in `test-plan.sh` first
   (`frontier` text + `--json`, mixed done/dropped blockers, `remaining`,
   `graph` text), then `plan.sh` green one verb at a time.
4. Extend `docs/plans.md` → "`plan.sh`" table with the new verbs.
5. Tick the ticket's boxes as each lands; `Decision:` trailer on the commit.
6. `scripts/context-budget.sh record --label "<unit done>"` at each step.
   At the end or at WARN/STOP: ledger block, rewrite this launcher (next
   ticket on the frontier), update the `work/README.md` row, commit. Do not
   push main; report how far ahead it is.
