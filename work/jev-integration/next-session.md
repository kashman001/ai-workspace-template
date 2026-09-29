# Catchup prompt — jev-integration (paste into a new agent session)

Plan `02-follow-on` is open; this session finishes **wave 1** (node 03, then
reconcile 04) and starts **wave 2**. Works in any runtime (Claude Code, Codex,
Gemini, OpenCode) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, REPLACED at
> each rollover: what to do next, binding constraints, pointers — never
> history. Past tense lives in `handoff.md` (ledger, top block only).
> Convention: docs/work-directory-conventions.md.

## Mission — run plan 02-follow-on, hands-off

Spec `S22–S30` (approved 2026-09-28), tickets `issues/08…12`, plan
`plans/02-follow-on/`. Spend is **pre-authorized by the user (2026-09-28)**:
the agent runs every paid Jev batch itself on this keyed machine and writes
the cost into the node Log (S30). No hitl nodes; no question needs a person
until the plan's goal-level close.

## Position

<!-- plan:begin position -->
Position: plan 02-follow-on, open, wave 1 of 2, done 2/7, doing 0, todo 5, blocked 0, dropped 0, sessions 1.
Frontier: 03-relevance-experiment. Remaining: 5 of 7 — wave 1: 03-relevance-experiment todo, 04-reconcile-w1 todo.
<!-- plan:end position -->

## First actions

0. `scripts/context-budget.sh register --project jev-integration` (expect
   `seq=19`). Hands-off: nobody is watching; do not stop with a question.
1. From `work/jev-integration/`: `scripts/plan.sh status --plan 02-follow-on`,
   `frontier --plan 02-follow-on`. **Pass `--plan 02-follow-on` on every
   verb, reads included** — without it the closed plan 01 is resolved via the
   record's stale `chain.plan` and `sync` rewrites this Position block wrongly.
2. Node `03-relevance-experiment` in-session (`start`, Goal, tick, `done`).
   `check()` has landed (node 02): `check(rows, condition, margin=0.0)` in
   `skills/rlm/scripts/rlm_repl.py` returns every raw Noul probability with no
   leaf fallback — one call per task sentence over the `docs/README.md` rows.
   Truth = `docs/…` paths in tickets 08–12's **Read first** lines. Note is the
   S29 decision note (name it by S-number, not ordinal). Scratch in the
   session scratchpad only.
3. `04-reconcile-w1` per `skills/plans/SKILL.md` → "Run a reconcile node":
   re-verify 01 (S22 note, scratch is gone — verify the note and Log) and 02
   (run `bash scripts/tests/test-jev.sh`, expect 182/182; `git show HEAD --
   skills/rlm/scripts/rlm_repl.py | grep '^@@'` — no hunk inside `llm_query`/
   `llm_query_map`, T14 golden untouched); flip tickets 08–10 `resolved`; sum
   the wave's costs in its Log. 01 kept 0.5 → no "≥ 0.5" wording change.
4. Wave 2: `05-research-wave-second-reader` (code + one live run; a subagent
   with `tdd` if budget allows), `06-tier-routing-evidence` (paid batch,
   writes `work/plans/issues/12-jev-tier-routing.md` + one bullet), then
   `07-reconcile-w2`. Closing the plan is goal-level — leave it open and say so.
5. Budget at every node boundary (`record --label`). WARN → finish the node,
   roll over hands-off; STOP → roll now. Ledger block 19 (insert after the
   header's `-->`, keep two blocks, archive the rest newest-on-top, verify the
   `# Session Handoff` count = 2, `scripts/check-ledger.py`); commit with a
   `Decision:` trailer. **Never push `main`.**

## Do NOT reload

- `research/` (settled; node 05's live run *reads* `research/*fact-check*.md`,
  never edits), `spike.md`, `rulings.md`, `sweep.md`, `seam-inventory.md`.
- `spec.md` beyond S22–S30 (lines ~140–210); the grill is over.
- Plan 01's node files; `scripts/tests/test-jev.sh` in full (grep a `T<n>`);
  `handoff.md` below the top block; `decisions.md` beyond its last two notes.

## Constraints already decided (do not re-litigate)

- **A bare `scripts/jev.sh` run is a live paid request.** Only inside the batch
  a node intends to pay for, or with `JEV_ENDPOINT` at the stub /
  `JEV_DISABLED=1`; `--check`/`--help` are free.
- Threshold stays **0.5** (S22 verdict: keep, rule inconclusive; lowering to
  0.25 is a question for the user at the goal-level close, not for a session).
- `llm_query`/`llm_query_map` byte-for-byte untouched (T14 golden — never
  regenerate). CLI contract unchanged: stdin JSON, JSON lines out, exit
  0/2/3/4, `--check`/`--help` only, `JEV_DISABLED` an env var not a flag.
- Template rules: agent-agnostic, CLI-first, key in the keychain (never
  printed), first-class docs, an offline test for anything with code. Only
  `scripts/jev.sh` knows the endpoint or the key — `scripts/jev-verdicts.sh`
  (node 05) calls it, never the network.
- Do not edit `plan.sh`, `plan-tiers.env`, `session-loop.sh`, or the plans
  skill; dogfood findings → a bullet in `work/plans/decisions.md`. Node 06
  *writes a ticket* in `work/plans/issues/` and one bullet there, nothing else.
- No model name in plan files. Corpora and raw Jev output stay in the
  scratchpad, never committed.

## State snapshot

- Branch `main`, clean after the session-18 rollover commit; origin is behind —
  the user pushes. Plan 02: done 01, 02; todo 03, 04, 05, 06, 07. Tickets
  08–12 `open`. test-jev.sh 182/182 (T1–T25).
- **Chain caveat:** the supervisor that ran session 18 was bound to closed plan
  01 and will have ended the chain with `plan_closed`. If you were started by
  hand, that is why; the chain restarts with
  `scripts/session-loop.sh jev-integration --plan 02-follow-on --reopen`.
