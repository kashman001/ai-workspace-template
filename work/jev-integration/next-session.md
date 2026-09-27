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
`rlm` behaves exactly as today. Requirements: `spec.md` (S1–S21) and the six
tickets under `issues/`. Plan `01-gated-integration`: waves 4–7 (nodes
07–16), one node per ticket, a reconcile last in each wave. Waves 4 and 5 are
done: `scripts/jev.sh` (Choice/Score/Noul, `--check`, `--help`, S7 refusals,
exit 0/2/3/4), `scripts/tests/test-jev.sh` (T1–T19, 128/128, stub + fake
keychain), `classify()` in `skills/rlm/scripts/rlm_repl.py`, credentials docs
+ preflight, `skills/jev/SKILL.md` + vendored `skills/jev/typesafe-ai/`, the
Service Access bullet in `CONTEXT.md`. This item is also the `plans` item's
dogfood: findings go to `work/plans/decisions.md`.

## Position

<!-- plan:begin position -->
Position: plan 01-gated-integration, open, wave 5 of 7, done 11/16, doing 1, todo 4, blocked 0, dropped 0, sessions 5.
Frontier: none (12-reconcile-w5 doing). Remaining: 5 of 16 — wave 5: 12-reconcile-w5 doing.
<!-- plan:end position -->

Remaining nodes (`plan.sh remaining`):

```
13-uat-gated         todo     wave 6
14-reconcile-w6      todo     wave 6
15-tune-and-pin      todo     wave 7
16-reconcile-w7      todo     wave 7
```

## First actions

1. `scripts/context-budget.sh register --project jev-integration` (expect `seq=12`).
2. `scripts/plan.sh frontier --project jev-integration` → `13-uat-gated`
   (`hitl`, wave 6; ticket `issues/05-*` is `ready-for-human`). **This session
   is interactive: pose the UAT to the user and wait.** Read the node
   (`nodes/13-uat-gated.md`) for its boxes, then ask the user to run, on a
   **keyed** machine: `scripts/jev.sh --check` (expect `jev: key present
   (keychain)`), `scripts/jev.sh --help` (three examples read correctly), and
   an `rlm` classification run following `skills/rlm/SKILL.md` section 3
   (`classify(...)`) whose `by_source` counter shows `jev`; and on a
   **keyless** machine (or with a fake `security` first on `PATH`):
   `--check` exits 3 with one stderr line, the same `rlm` run works and
   `by_source` shows only `leaf`, nothing mentions Jev. Note: an `rlm` run on
   the keyed machine is a real paid request (small: cents). Record the answer:
   pass → `scripts/plan.sh done 13-uat-gated --by human --project
   jev-integration`; findings → fix in a new wave-6 `work` node
   (`plan.sh add`), or `drop 13-uat-gated <reason>` if the user says so.
3. Then `14-reconcile-w6` (verify 13 by its human mark, record, `check`,
   `sync`, `done`), and wave 7 (see the nodes for 15/16).
4. Overruns: `block`/split (Replan rule 1); record which as a finding.
5. At WARN/STOP: ledger block (insert after the header's `-->`; blocks are
   `# Session Handoff — N`; keep two, archive the rest newest-on-top, no
   duplicate N; verify the header count after writing), `plan.sh sync`,
   commit with a `Decision:` trailer, then `session-rollover` (supervised
   chain → `--emit`). Do not push `main`.
6. `plan.sh` flags are separate words (`--project jev-integration`); a
   variable holding both is rejected. `frontier` exits 1 while a reconcile
   node is `doing` — do not chain it with `&&`. A node `check:` runs from the
   work item directory: every path in it needs `"$WORKSPACE_ROOT/"`.
   `plan.sh done` streams the check's full output — pipe through `tail`.
7. Test-authoring gotcha: a background stub started inside `$( … )` must
   redirect its stdout/stderr or the substitution hangs (`start_stub` does).

## Do NOT reload

- `research/` beyond claim ids by grep; `spike.md` only if a number is needed.
- `rulings.md`, `sweep.md`, `seam-inventory.md`, the corrections — settled.
- `spec.md` "User Stories" in full — the tickets and the node bodies carry
  what each node needs; grep an `S<n>` when a box cites one.
- `work/plans/` beyond `decisions.md` (append) and `issues/11-dogfood.md`.
- `handoff.md` — the top block only if something above is unclear.
- `scripts/tests/test-jev.sh` in full (330+ lines) — grep a `T<n>` label.

## Constraints already decided (do not re-litigate)

- **Never run `scripts/jev.sh` without `JEV_ENDPOINT` pointing at the stub
  unless it is `--check` or `--help`.** This machine's keychain holds a real
  key; a bare run is a live paid request. The test isolates this with a fake
  `security` on `PATH`. The UAT's `rlm` run is the one sanctioned live call.
- Template rules: agent-agnostic, CLI-first, credentials in the keychain,
  documented as a first-class addition, a test that proves it without a live
  key. `scripts/jev.sh` is the only code that knows the endpoint or the key.
- CLI contract (fourth note in `decisions.md`): request JSON on stdin, passed
  through; one JSON line `{key,value,confidence}` per answer (Noul:
  confidence `null`); key reaches Python via the child env only; exit 0/2/3/4;
  `--check` and `--help` are the only flags.
- The `rlm` swap is the `classify()` helper beside `llm_query`; `llm_query`
  is byte-for-byte untouched (T14 diffs it against
  `scripts/tests/fixtures/jev/llm_query.golden.py` — never regenerate the
  golden to make a diff pass). `classify()` is done — do not touch it.
- Vendored `skills/jev/typesafe-ai/` is pristine upstream (`65a39f3`,
  v0.5.7) below its provenance comment — never edit the body.
- Gated on access; `rlm` first; Q1 (c), Q2 narrow, Q5 (a) widened to (b) by
  the spec; `Promote?: maybe` on the fit note.
- Raw `pass/*.md`, `fact-check.md`, `record.md`, every brief, and
  `spike.{md,py}` are provenance — never edited. Do not re-run the spike.
  The key stays in the keychain: never print it, never write it to a file.
- No concrete model name in plan files (tiers only). Do not edit `plan.sh`,
  `session-loop.sh`, or the plans skill from this item.

## State snapshot

- Branch `main`, not pushed. Plan `01-gated-integration` open: wave 6 of 7,
  nodes 01–12 `done`, frontier `13-uat-gated` (hitl).
- `decisions.md`: five notes (R0.4 lift; fit decision, approved; typed
  helper; CLI stdin/JSON-lines shape; `classify` dict categories + `question=`).
- `spec.md` Status: draft (the user may flip it to approved; the tickets are
  `ready-for-agent`, 05 `ready-for-human`).
- Chain: supervised; session 11 staged session 12 **interactive** at WARN.
