# Catchup prompt — jev-integration (paste into a new agent session)

Plan `02-follow-on` is open (created s17, 2026-09-28); this session runs
**wave 1**. Works in any runtime (Claude Code, Codex, Gemini, OpenCode) — all
read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, REPLACED at
> each rollover: what to do next, binding constraints, pointers — never
> history. Past tense lives in `handoff.md` (ledger, top block only).
> Convention: docs/work-directory-conventions.md.

## Mission — run plan 02-follow-on, hands-off

Five approved follow-on slices, spec `S22–S30` (approved 2026-09-28), tickets
`issues/08…12`, plan `plans/02-follow-on/`. Spend is **pre-authorized by the
user (2026-09-28)**: the agent runs every paid Jev batch itself on this keyed
machine and writes the cost into the node Log (S30). No hitl nodes exist; no
question needs a person until the plan's goal-level close.

## Position

<!-- plan:begin position -->
Position: plan 02-follow-on, open, wave 1 of 2, done 0/7, doing 0, todo 7, blocked 0, dropped 0, sessions 0.
Frontier: 01-confirm-threshold, 02-score-check-helpers, 03-relevance-experiment. Remaining: 7 of 7 — wave 1: 01-confirm-threshold todo, 02-score-check-helpers todo, 03-relevance-experiment todo, 04-reconcile-w1 todo.
<!-- plan:end position -->

## First actions

0. `scripts/context-budget.sh register --project jev-integration` (expect
   `seq=18`). Hands-off: nobody is watching; do not stop with a question.
1. `scripts/plan.sh status` and `scripts/plan.sh frontier` from
   `work/jev-integration/` (flags literal, `--plan 02-follow-on` on every write
   verb while plan 01 exists closed — `add`/`start`/`done` without it target
   plan 01 and are refused).
2. Work the frontier per `skills/plans/SKILL.md`: `start <id>`, do the node's
   Goal (its body carries the ticket text, `Read first:` list, and Acceptance),
   tick boxes in the node file, `done <id>` (its `check` must pass). Nodes
   01–03 are independent — dispatch 02 (code, `tdd`) to a subagent with the
   skill's prompt template if budget allows; 01 and 03 are one-off paid
   batches best run in-session. Then `04-reconcile-w1` (procedure: "Run a
   reconcile node"; flip tickets 08–10 `resolved`; if 01 moved the threshold,
   update the "≥ 0.5" wording in nodes 05/06 as a local replan).
3. Budget at every node boundary (`record --label`). WARN → finish the node,
   roll over hands-off (`--loop-mode handsoff`); STOP → roll now. Ledger block
   18 at the end (insert after the header's `-->`, keep two blocks, archive the
   rest newest-on-top, verify the `# Session Handoff` count = 2); commit with a
   `Decision:` trailer. **Never push `main`.**

## Do NOT reload

- `research/` (settled; `research/*fact-check*.md` is *read* by node 05's live
  run, never edited), `spike.md`, `rulings.md`, `sweep.md`, `seam-inventory.md`.
- `spec.md` beyond S22–S30 (lines ~140–210) and the non-goals; the grill is
  over — its nine answers are in ledger block 17 and the tenth decision note.
- Plan 01's node files; `scripts/tests/test-jev.sh` in full (grep a `T<n>`).
- `handoff.md` below the top block.

## Constraints already decided (do not re-litigate)

- **A bare `scripts/jev.sh` run is a live paid request** (real key in this
  keychain). Run it only inside the batch a node intends to pay for, or with
  `JEV_ENDPOINT` at the stub / `JEV_DISABLED=1`; `--check`/`--help` are free.
- Pre-registered rule for node 01 (S22): keep 0.5 iff leaf agreement in
  `[0.5,1]` ≥ 2× that in `[0.25,0.5)`, else move to the lowest bucket boundary
  where it holds. Recipe: s13 note in `decisions.md` (pass-through keychain stub
  that fails only `jev-api-key`; a stub failing every `security` call logs the
  `claude` CLI out).
- Helpers (S23/S24): `score()` and `check()` are siblings of `classify()`;
  Noul fallback when `|p − 0.5| < 0.25` (`DEFAULT_JEV_NOUL_MARGIN`,
  `RLM_JEV_NOUL_MARGIN`); Score keeps the 0.5 confidence rule and carries the
  reliability caveat. `llm_query` byte-for-byte untouched (T14 golden — never
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

- Branch `main`, clean at 05b8273 (+ this rollover commit); origin is behind —
  the user pushes. Plan 02 open 0/7; spec approved; tickets 08–12 `open`;
  `decisions.md` ten notes; test-jev.sh 140/140 (T1–T20).
- Chain: supervised, hands-off from session 18. Session 17 rolled at WARN
  (128 K) with the plan freshly created.
