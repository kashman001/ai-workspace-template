# Catchup prompt — jev-integration (paste into a new agent session)

We're resuming `jev-integration`. Works in any runtime (Claude Code, Codex,
Gemini, OpenCode) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in
> `handoff.md` (the append-only ledger). Convention:
> docs/work-directory-conventions.md.

## Mission

Research is closed; the fit decision is approved (`decisions.md`, second
note): **integrate Jev at the `rlm` leaf-classification seam, gated on
access** — active only where `jev-api-key` is in the OS keychain; without one,
`rlm` behaves exactly as today. The requirements are `spec.md` (S1–S21, with
`## Testability`) and the six tickets under `issues/`. Plan
`01-gated-integration` carries the implementation: waves 4–7 (nodes 07–16),
one node per ticket, a reconcile node last in each wave, node 13 a `hitl`
UAT. Wave 4 shipped `scripts/jev.sh` (Choice, `--check`) and
`scripts/tests/test-jev.sh` (stub server, fake `security`, fixtures under
`scripts/tests/fixtures/jev/`); node 10 shipped the credentials docs and the
preflight. This item is also the `plans` item's dogfood: findings go to
`work/plans/decisions.md`.

## Position

<!-- plan:begin position -->
Position: plan 01-gated-integration, open, wave 5 of 7, done 9/16, doing 0, todo 7, blocked 0, dropped 0, sessions 3.
Frontier: 09-rlm-classify, 11-cli-skill-rule. Remaining: 7 of 16 — wave 5: 09-rlm-classify todo, 11-cli-skill-rule todo, 12-reconcile-w5 todo.
<!-- plan:end position -->

## First actions

1. `scripts/context-budget.sh register --project jev-integration` (expect `seq=10`).
2. `scripts/plan.sh frontier --project jev-integration` → `09-rlm-classify`
   and `11-cli-skill-rule` (both wave 5). Do **09 first** (ticket
   `issues/02-rlm-classify-helper.md`, the seam): `start` it, read the node
   and the ticket, then `spec.md` → "Implementation Decisions" (the
   `classify()`, batching, threshold/fallback, model-id bullets) and "Testing
   Decisions". Read only the helper region of `skills/rlm/scripts/rlm_repl.py`
   (`llm_query`, `llm_query_map`, the `RLM_*` knobs) — `llm_query` stays
   byte-for-byte unchanged, asserted by diff in the test. Build it test-first
   (`tdd`): extend `scripts/tests/test-jev.sh` (T8+, same style; fake `claude`
   on `PATH` echoing canned `N: label` lines for the leaf; the stub server for
   the key path — reuse the `$FAKE`, `$ENDPOINT`, `requests()` helpers), then
   the helper: it calls `scripts/jev.sh` with the request on stdin and reads
   the JSON lines back (`{key,value,confidence}`); exit 3 → current path
   silently; exit 4 or bad JSON → leaf for that batch plus one warning line.
   Update `skills/rlm/SKILL.md` (root guidance: use `classify`, keep `other`,
   choose a threshold, read `source`). Tick verified boxes, `done`.
3. `11-cli-skill-rule` (ticket `issues/04-cli-three-types-skill-and-rule.md`):
   widen `jev.sh` answer extraction to Score/Noul, the S7 limit refusals
   (exit 2 before any request; 255 options; 32k tokens) and the exit-4 test;
   `--help` with one worked example per type; the `jev` skill dir with
   TypeSafe's SKILL.md vendored from `typesafe-ai/skills` at `65a39f3`
   (v0.5.7) with a provenance comment + license; the always-on rule as one
   bullet under `CONTEXT.md` → "Service Access" (<100 tokens; edit
   `CONTEXT.md`, never a symlink). Standard tier; a subagent candidate via the
   plans skill's prompt template if the budget is tight — the orchestrator
   `start`s/`done`s.
4. `12-reconcile-w5`: verify 09, 10, and 11 on disk (`verify <id>`, diffs,
   test output), record, `check`, `sync`, `done`. Then the frontier is
   `13-uat-gated` (`hitl`): roll over with `--loop-mode interactive` so the
   successor poses the UAT to the user (what to run on a keyed and a keyless
   machine, how to answer: `done 13-uat-gated --by human` / amend / `drop`).
5. Overruns: `block`/split (Replan rule 1); record which as a finding.
6. At WARN/STOP: ledger block (insert after the header's `-->`; blocks are
   `# Session Handoff — N`; keep two, archive the rest newest-on-top, no
   duplicate N), `plan.sh sync`, commit with a `Decision:` trailer, then
   `session-rollover` (supervised chain → `--emit`). Do not push `main`.
7. `plan.sh` flags are separate words (`--project jev-integration`); a
   variable holding both is rejected. `frontier` exits 1 while a reconcile
   node is `doing` — do not chain it with `&&`.

## Do NOT reload

- `research/` beyond claim ids by grep; `spike.md` only if a number is needed.
- `rulings.md`, `sweep.md`, `seam-inventory.md`, the corrections — settled.
- `spec.md` "User Stories" in full — the tickets and the node bodies carry
  what each node needs; grep an `S<n>` when a box cites one.
- `work/plans/` beyond `decisions.md` (append) and `issues/11-dogfood.md`.
- `handoff.md` — the top block only if something above is unclear.

## Constraints already decided (do not re-litigate)

- **Never run `scripts/jev.sh` without `JEV_ENDPOINT` pointing at the stub
  unless it is `--check`.** This machine's keychain holds a real key; a bare
  run is a live paid request (session 9 made one by accident — `plan.sh`
  note). The test isolates this with a fake `security` on `PATH`.
- Template rules: agent-agnostic, CLI-first, credentials in the keychain,
  documented as a first-class addition, a test that proves it without a live
  key. `scripts/jev.sh` is the only code that knows the endpoint or the key.
- CLI contract (fourth note in `decisions.md`): request JSON on stdin, passed
  through; one JSON line `{key,value,confidence}` per answer; key reaches
  Python via the child env only; exit 0/2/3/4; `--check` and `--help` are the
  only flags.
- The `rlm` swap is a new `classify()` helper beside `llm_query`; `llm_query`
  is byte-for-byte untouched (third note in `decisions.md`).
- Gated on access; `rlm` first; Q1 (c), Q2 narrow, Q5 (a) widened to (b) by
  the spec; `Promote?: maybe` on the fit note.
- Raw `pass/*.md`, `fact-check.md`, `record.md`, every brief, and
  `spike.{md,py}` are provenance — never edited. Do not re-run the spike.
  The key stays in the keychain: never print it, never write it to a file.
- No concrete model name in plan files (tiers only). Do not edit `plan.sh`,
  `session-loop.sh`, or the plans skill from this item.
- Vendor TypeSafe's SKILL.md from `typesafe-ai/skills` at `65a39f3` (v0.5.7);
  re-checked 2026-09-27, nothing newer.

## State snapshot

- Branch `main`, not pushed. Plan `01-gated-integration` open: wave 5 of 7,
  nodes 01–08 and 10 `done`, frontier `09-rlm-classify` + `11-cli-skill-rule`.
- `decisions.md`: four notes (R0.4 lift; fit decision, approved; typed
  helper; CLI stdin/JSON-lines shape).
- `spec.md` Status: draft (the user may flip it to approved; the tickets are
  `ready-for-agent`, 05 `ready-for-human`).
- Chain: supervised; session 9 staged session 10 hands-off just under WARN.
