# Catchup prompt — plans (paste into a new agent session)

We're resuming `plans`. Works in any runtime (Claude Code, Codex, Gemini,
OpenCode) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, REPLACED at
> each rollover: what to do next, still-binding constraints, pointers — never
> session history. Past-tense provenance lives in `handoff.md` (the ledger).
> Convention: docs/work-directory-conventions.md.

## Mission

Implement the tickets under `issues/` in dependency order, test-first, one
ticket per session unless a ticket is clearly small. Tickets 01–03 are done;
the frontier is 04, 05, 06 (all blocked only by done tickets). Take **04**
(write verbs and the state machine) — 07 and 09 need it, and it is the
largest; if it will not fit one session, land `start`/`done`/`verify` first
and leave `add`/`block`/`drop`/`note` for the successor.

## Read these, in order

1. `work/plans/issues/04-write-verbs-state-machine.md` — the ticket.
2. `handoff.md` top block → "For ticket 04" — the fixture's 09 node has a
   `check` that exits 2 in the test workspace; decide how `done` tests run a
   check (own command per test, or a fixture edit).
3. `docs/plans.md` — format, every verb, "Check rules", exit codes; extend,
   don't restate. The state machine is in `work/plans/spec.md` →
   "Implementation Decisions" (`todo → doing → done`, `doing → blocked →
   doing`, any → `dropped`; `done` requires the check to pass; hitl nodes
   need `--by human`).
4. `scripts/plan.sh` — read it whole (~300 lines): `load_nodes` (strict),
   `node_parse` (lenient, used by `check`), `DERIVE_JQ`, `cmd_<verb>` +
   `case` arm per verb. Write verbs edit node files in place: keep the
   frontmatter line order and comments, append `## Log` lines.
5. `scripts/tests/test-plan.sh` — T8 shows fixture variants (`reset`,
   `setf`, `addf`, `squeeze`); T11 shows exit-code + `--json` shape
   assertions. Append `T12…`.
6. `work/plans/spec.md` — only S4, S8, S18, S19, S20.

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
- Write verbs never call a model and never decide: `done` is refused when the
  check fails; the Nth failed check (`loop: N`) writes `blocked`.
- `plan.sh check` must still pass on the fixture after any fixture edit.
- Wave names ("1 ground") live in no frontmatter — derive or omit; note the
  choice in the ledger for ticket 05 (board renderer).

## State snapshot

Branch `main`, clean after this rollover's commit; nothing pushed. Tickets:
01–03 `done`; 04–11 `ready-for-agent`; frontier = 04, 05, 06. Chain
supervised by `session-loop.sh` (seq 1 → 2 → 3 → 4 → 5 → 6). Budget at
rollover: OK (~110K; ticket 03 finished under WARN).

## First actions

1. `scripts/context-budget.sh register --project plans` (expect `seq=6`).
2. No question to pose. Proceed hands-off.
3. `implement` ticket 04 with `tdd`: one red case per transition in
   `test-plan.sh` first (legal transition, each illegal one refused with
   exit 1, `done` on a passing and a failing check, `loop` exhaustion,
   `--by human`), then `plan.sh <verb>` green one verb at a time.
4. Extend `docs/plans.md` → "`plan.sh`" table with the write verbs and a
   "State machine" paragraph.
5. Tick the ticket's boxes as each lands; `Decision:` trailer on the commit.
6. `scripts/context-budget.sh record --label "<unit done>"` at each step.
   At the end or at WARN/STOP: ledger block, rewrite this launcher (next
   ticket on the frontier), update the `work/README.md` row, commit. Do not
   push main; report how far ahead it is.
