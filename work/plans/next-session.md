# Catchup prompt — plans (paste into a new agent session)

We're resuming `plans`. Works in any runtime (Claude Code, Codex, Gemini,
OpenCode) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, REPLACED at
> each rollover: what to do next, still-binding constraints, pointers — never
> session history. Past-tense provenance lives in `handoff.md` (the ledger).
> Convention: docs/work-directory-conventions.md.

## Mission

Implement the tickets under `issues/` in dependency order, test-first, one
ticket per session unless a ticket is clearly small. Tickets 01–06 are done.
Take **07** (`issues/07-session-loop-integration.md`, blocked by 04 and 05,
both done): `session-loop.sh` learns its plan — `--plan <slug>` (or the
single open plan) recorded as `chain.plan` in `session-state.json` (schema
stays 1); sync then check between children, refusing the next session on a
failing check the way it refuses `staged_invalid`; verdict `plan_closed`
when the plan's terminal reconcile node is done and the plan closed;
`--loop-mode interactive` for the next launch when the frontier holds only
hitl nodes. An item without a plan behaves exactly as today. Then **08** in
the same session only if budget allows — `record` before starting it.

## Read these, in order

1. `handoff.md` top block → "Choices made" (ticket 06's settled details) —
   skim only; nothing there blocks 07.
2. `work/plans/issues/07-session-loop-integration.md` — the three boxes.
3. `work/plans/spec.md` → S25–S28 only (grep `S25`); the rest is settled.
4. `scripts/session-loop.sh` → the between-children step (where
   `staged_invalid` is refused) and the verdict emission (`v=quit_*`);
   `scripts/tests/test-session-loop.sh` → the fake-child harness (its
   first ~60 lines) and one existing refusal case to copy the shape of.
5. `scripts/plan.sh` header only — the verbs 07 calls: `sync`, `check`,
   `status --json`, `frontier --json`; `docs/plans.md` → "Resolution" for
   how `chain.plan` is read.
6. `docs/context-budget.md` → "The supervisor" and "Verbs and reason codes"
   (the doc-consistency test pins every verdict/code named there to the
   scripts — add `plan_closed` and the refusal code in both places).
7. Then `work/plans/issues/08-*.md` for the next ticket.

## Do NOT reload

- `decisions.md` in full — settled; open only to append.
- `concept.md`, `seams.md`, the grill — closed. Do not re-open the verdict,
  the status set, HITL semantics, markers, node kind, tiers, or the
  integration list.
- Tickets 01–06 — done and documented (`docs/plans.md`). `plan-tiers.env`
  and the tier stamps are settled; do not touch them for 07.
- A runner, a Stop/SessionEnd hook, parallel checkouts, editing wayfinder
  (backlog L48) — all out of scope.

## Still binding

- Bash 3.2 + jq only; match the scripts' style. Exit codes as documented.
- `session-state.json` schema stays 1; `chain.plan` is the one new field.
- `bash scripts/tests/test-session-loop.sh` (105) and `test-plan.sh` (238)
  must stay green; `test-doc-consistency.sh` after doc edits (it will fail
  until `plan_closed` and the new refusal code are named in
  `docs/context-budget.md` — that is the doc box of the ticket).
- No concrete model name in any plan or node file.
- Nothing pushed to origin; report how far ahead `main` is.

## State snapshot

Branch `main`, clean after this rollover's commit; nothing pushed (36+
ahead). Tickets: 01–06 `done`; 07–11 `ready-for-agent`. Chain supervised by
`session-loop.sh` (seq 1 → … → 9 → 10). Budget at rollover: WARN (~129K).
Untracked `work/jev-integration/research/spike.{md,py}` are another item's.

## First actions

1. `scripts/context-budget.sh register --project plans` (expect `seq=10`).
2. No question to pose. Proceed hands-off.
3. Ticket 07 with `tdd`: the fake-child cases in `test-session-loop.sh`
   first (plan bound → `chain.plan` written; failed `check` refuses the next
   session; `plan_closed` ends the chain; hitl-only frontier → interactive),
   then the code in `scripts/session-loop.sh`; keep the plan-less cases
   untouched; green; `record --label "ticket 07 code"`; commit.
4. Docs: `docs/context-budget.md` verdict + refusal; `test-doc-consistency.sh`
   green; tick the boxes, status `done`; commit with a `Decision:` trailer
   only if a new choice was made.
5. `record` at each step. At the end or at WARN/STOP: ledger block, rewrite
   this launcher (next ticket on the frontier), update the `work/README.md`
   row, commit. Do not push main; report how far ahead it is.
