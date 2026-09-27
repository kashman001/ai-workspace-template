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
`scripts/tests/test-jev.sh` (stub server, fake `security`/`claude`, fixtures
under `scripts/tests/fixtures/jev/`); node 10 shipped the credentials docs and
the preflight; node 09 shipped `classify()` in `skills/rlm/scripts/rlm_repl.py`
(T8–T14, `llm_query` golden-diffed) and the `rlm` skill guidance. This item is also the `plans` item's dogfood: findings go to
`work/plans/decisions.md`.

## Position

<!-- plan:begin position -->
Position: plan 01-gated-integration, open, wave 5 of 7, done 10/16, doing 0, todo 6, blocked 0, dropped 0, sessions 4.
Frontier: 11-cli-skill-rule. Remaining: 6 of 16 — wave 5: 11-cli-skill-rule todo, 12-reconcile-w5 todo.
<!-- plan:end position -->

## First actions

1. `scripts/context-budget.sh register --project jev-integration` (expect `seq=11`).
2. `scripts/plan.sh frontier --project jev-integration` → `11-cli-skill-rule`
   (wave 5; ticket `issues/04-cli-three-types-skill-and-rule.md`). `start` it,
   read the node and the ticket, then grep `spec.md` for the `S<n>` each box
   cites (S5–S8 are the CLI/skill/rule stories). Build test-first (`tdd`) in
   `scripts/tests/test-jev.sh` — same style as T1–T14, reuse `$FAKE`,
   `$ENDPOINT`, `start_stub <fixture> <name>`, `requests()`; new fixtures under
   `scripts/tests/fixtures/jev/` (a Score and a Noul answer). Then `jev.sh`:
   widen answer extraction to Score (`{score, legend, probabilities,
   confidence}`) and Noul (`{noul}`, no confidence) keeping the one-line
   `{key,value,confidence}` shape; the S7 limit refusals (exit 2 before any
   request: >255 options in one Choice; estimated state + longest question
   over 32k tokens) and the exit-4 test (stub returning 401/429); `--help`
   with one worked example per type. The `jev` skill dir (`skills/jev/`):
   TypeSafe's SKILL.md vendored from `typesafe-ai/skills` at `65a39f3`
   (v0.5.7) with a provenance comment + license, per
   `skills/vendored-skills.md`. The always-on rule: one bullet under
   `CONTEXT.md` → "Service Access" (<100 tokens; edit `CONTEXT.md`, never a
   symlink). `classify()` in `rlm_repl.py` is done — do not touch it; the
   test's T8–T14 must stay green. Tick verified boxes, `done`.
3. `12-reconcile-w5`: verify 09, 10, and 11 on disk (`verify <id>`, diffs,
   test output), record, `check`, `sync`, `done`. Then the frontier is
   `13-uat-gated` (`hitl`): roll over with `--loop-mode interactive` so the
   successor poses the UAT to the user (what to run on a keyed and a keyless
   machine — `scripts/jev.sh --check`, then an `rlm` run whose `by_source`
   shows `jev` — how to answer: `done 13-uat-gated --by human` / amend /
   `drop`).
4. Overruns: `block`/split (Replan rule 1); record which as a finding.
5. At WARN/STOP: ledger block (insert after the header's `-->`; blocks are
   `# Session Handoff — N`; keep two, archive the rest newest-on-top, no
   duplicate N), `plan.sh sync`, commit with a `Decision:` trailer, then
   `session-rollover` (supervised chain → `--emit`). Do not push `main`.
6. `plan.sh` flags are separate words (`--project jev-integration`); a
   variable holding both is rejected. `frontier` exits 1 while a reconcile
   node is `doing` — do not chain it with `&&`.
7. Test-authoring gotcha: a background stub started inside `$( … )` must
   redirect its stdout/stderr or the substitution hangs (`start_stub` does).

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
- The `rlm` swap is the `classify()` helper beside `llm_query`; `llm_query`
  is byte-for-byte untouched (third note in `decisions.md`; T14 diffs it
  against `scripts/tests/fixtures/jev/llm_query.golden.py` — never regenerate
  the golden to make a diff pass).
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
  nodes 01–10 `done`, frontier `11-cli-skill-rule`.
- `decisions.md`: five notes (R0.4 lift; fit decision, approved; typed
  helper; CLI stdin/JSON-lines shape; `classify` dict categories + `question=`).
- `spec.md` Status: draft (the user may flip it to approved; the tickets are
  `ready-for-agent`, 05 `ready-for-human`).
- Chain: supervised; session 10 staged session 11 hands-off at WARN.
