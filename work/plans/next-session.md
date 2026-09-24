# Catchup prompt — plans (paste into a new agent session)

We're resuming `plans`. Works in any runtime (Claude Code, Codex, Gemini,
OpenCode) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, REPLACED at
> each rollover: what to do next, still-binding constraints, pointers — never
> session history. Past-tense provenance lives in `handoff.md` (the ledger).
> Convention: docs/work-directory-conventions.md.

## Mission

Implement the tickets under `issues/` in dependency order, test-first, one
ticket per session unless a ticket is clearly small. Tickets 01–05 are done;
06 is half in (slice a: tier resolution, T19a–l, commit `6dc70f6`). Finish
06 (slices b and c: model mapping + `start` stamp, `add --leaf` + refusals,
`plan-tiers.env`, docs), then take **07** (next on the frontier; check its
"Blocked by" line) in the same session only if budget allows — 06's
remainder is a full implement+test+commit unit, so `record` before starting 07.

## Read these, in order

1. `handoff.md` top block → "Left for the successor" — the exact remaining
   pieces of ticket 06 and the Log-line wording; "Choices made" for what
   is settled without a note.
2. `work/plans/issues/06-tiers.md` — the three boxes to tick.
3. `decisions.md` → the last note only (2026-09-24, tiers) — the settled
   shape; do not re-open it.
4. `scripts/plan.sh` → the "tiers" section (`tier_env_json`,
   `plan_tiers_json`, `RESOLVE_JQ`, ~30 lines) and `cmd_start`,
   `registry_project`, `cmd_add` — only what slice b/c touches.
5. `scripts/tests/test-plan.sh` → T19 (the tail) for the helpers
   (`tiers`, `$TENV`) and T12d's pinned `started` line.
6. `docs/plans.md` → Format node table and the `plan.sh` table, to extend.
7. Then `work/plans/issues/07-*.md` for the next ticket.

## Do NOT reload

- `decisions.md` in full — settled; open only its last note, or to append.
- `concept.md`, `seams.md`, `spec.md` — S6/S7 are quoted in the decision note.
- The grill — closed. Do not re-open the verdict, the status set, HITL
  semantics, markers, node kind, tiers' shape, or the integration list.
- Ticket 05 — done, documented. The `create-work-item` launcher template —
  left alone on purpose (S22); S34's "sync first" step is a later ticket.
- A runner, a Stop/SessionEnd hook, parallel checkouts, editing wayfinder
  (backlog L48) — all out of scope.

## Still binding

- Bash 3.2 + jq only; match `scripts/plan.sh`'s style. Exit codes 0/1/2 as
  documented. Text by default, `--json` on every read verb.
- No concrete model name in any plan or node file (ticket 06 box 3): the
  Log stamps the tier, never the model.
- `plan.sh check` on the fixture and `bash scripts/tests/test-plan.sh` (221)
  must stay green; `test-doc-consistency.sh` too after doc edits.
- Nothing pushed to origin; report how far ahead `main` is.

## State snapshot

Branch `main`, clean after this rollover's commit; nothing pushed (33+
ahead). Tickets: 01–05 `done`; 06 `ready-for-agent`, slice a committed;
07–11 `ready-for-agent`. Chain supervised by `session-loop.sh`
(seq 1 → … → 8 → 9). Budget at rollover: WARN (~129K).

## First actions

1. `scripts/context-budget.sh register --project plans` (expect `seq=9`).
2. No question to pose. Proceed hands-off.
3. Ticket 06 slice b with `tdd`: red cases in T19 (after T19l) and the
   T12d update first, then `model` + runtime + the `start` stamp in
   `scripts/plan.sh`; green; commit.
4. `scripts/context-budget.sh record --label "ticket 06 slice b"`.
5. Slice c: `add --leaf`, the two refusals, `plan-tiers.env`, docs, boxes,
   status `done`; run `test-doc-consistency.sh`; commit with a `Decision:`
   trailer only if a new choice was made.
6. `record` at each step. At the end or at WARN/STOP: ledger block, rewrite
   this launcher (next ticket on the frontier), update the `work/README.md`
   row, commit. Do not push main; report how far ahead it is.
