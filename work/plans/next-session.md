# Catchup prompt — plans (paste into a new agent session)

We're resuming `plans`. Works in any runtime (Claude Code, Codex, Gemini,
OpenCode) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, REPLACED at
> each rollover: what to do next, still-binding constraints, pointers — never
> session history. Past-tense provenance lives in `handoff.md` (the ledger).
> Convention: docs/work-directory-conventions.md.

## Mission

The concept is settled and the verdict is **build**. Implement the tickets
under `issues/` in dependency order, test-first, one ticket per session
unless a ticket is clearly small. First up: ticket 01 (plan directory
format, node parser, `plan.sh new / show / status`).

## Read these, in order

1. `work/plans/issues/01-plan-format-and-read-basics.md` — the ticket.
2. `work/plans/spec.md` — only the S-items the ticket names, plus
   "Implementation Decisions" and "Testing Decisions".
3. `work/plans/concept.md` → "Worked example" — the node-file and `plan.md`
   shapes to implement; the glossary for vocabulary.
4. `skills/implement/SKILL.md` and `skills/tdd/SKILL.md` when starting.
5. Prior art for tests: `scripts/tests/test-session-lib.sh`,
   `scripts/tests/test-context-budget-registry.sh` (fixture dirs, exit-code
   assertions). Read one, not all.

## Do NOT reload

- `decisions.md` in full — every note is settled; open it only to append a
  new note or check one rejected alternative.
- `seams.md` — background only.
- The grill — closed. Do not re-open the verdict, the status set, HITL
  semantics, markers, node kind, or the integration list.
- A runner, a Stop/SessionEnd hook, parallel checkouts, editing wayfinder
  (backlog L48) — all out of scope.

## State snapshot

Branch `main`, clean after this rollover's commit; nothing pushed. `spec.md`
is `Status: draft` — the user has not flipped it to approved. Eleven
tickets, all `ready-for-agent`; frontier = 01. Chain supervised by
`session-loop.sh` (seq 1 → 2 → 3). Budget at rollover: WARN (~122K).

## First actions

1. `scripts/context-budget.sh register --project plans` (expect `seq=3`).
2. If a person is present: ask whether to flip `spec.md` to
   `Status: approved` (one line). If not, proceed on the draft and note it.
3. `implement` ticket 01 with `tdd`: fixture plan under
   `scripts/tests/fixtures/` mirroring `concept.md`'s worked example first,
   then `scripts/tests/test-plan.sh` red, then `scripts/plan.sh` green, one
   verb at a time (`new`, `show`, `status`), text then `--json`. Bash + jq
   only; match the style of `scripts/lib/session-lib.sh`.
4. Start `docs/plans.md` with only the format section the ticket needs.
5. Tick the ticket's acceptance boxes as each lands; `Decision:` trailer on
   the commit; append a note to `decisions.md` only for a real fork.
6. `scripts/context-budget.sh record --label "<unit done>"` at each step.
   At the end or at WARN/STOP: ledger block, rewrite this launcher (next
   ticket on the frontier), update the `work/README.md` row, commit. Do not
   push main; report how far ahead it is.
