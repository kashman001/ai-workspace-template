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
Position: plan 01-gated-integration, open, wave 6 of 7, done 12/17, doing 0, todo 5, blocked 0, dropped 0, sessions 5.
Frontier: 13-uat-gated. Remaining: 5 of 17 — wave 6: 13-uat-gated todo, 14-reconcile-w6 todo, 17-13b-uat-fixes todo.
<!-- plan:end position -->

Remaining nodes (`plan.sh remaining`):

```
13-uat-gated         todo     wave 6
14-reconcile-w6      todo     wave 6
15-tune-and-pin      todo     wave 7
16-reconcile-w7      todo     wave 7
```

## First actions

1. `scripts/context-budget.sh register --project jev-integration` (expect `seq=13`).
2. **Interactive session.** Node 13 (hitl) is half done — see ledger block
   12. First fix the plan lint: `scripts/plan.sh check --project
   jev-integration` fails because fix node `17-13b-uat-fixes` (wave 6,
   added for the UAT findings) sorts after reconcile `14-reconcile-w6`.
   Resolve per `skills/plans/SKILL.md` (replan rules), not by hand-editing
   ids; record how as a `plan.sh note`.
3. Re-pose the two remaining UAT legs to the user, with `python3` (not
   `python`) and a **real file path** in place of `<file>` (zsh parses the
   literal placeholder as a redirection). Keyed leg: `python3
   skills/rlm/scripts/rlm_repl.py init <path>` then the `classify(...)`
   exec block from `skills/rlm/SKILL.md` section 3 printing `by_source`;
   expect mostly `jev`, samples with `confidence`; note the leaf share. It is
   the one sanctioned live paid call (cents). Keyless leg: same, prefixed
   `PATH=/tmp/nokey:$PATH` (the user's fake `security`, exit 44; recreate if
   `/tmp` was cleared); expect only `leaf`, nothing mentioning Jev.
4. On pass: `scripts/plan.sh done 13-uat-gated --by human --project
   jev-integration`; write the leaf share to `decisions.md` for node 15.
   Then run node 17 (goal + acceptance in the node; reviewer's help text at
   `uat-help-proposal.txt`), then `14-reconcile-w6`, then wave 7.
5. After the plan closes: the user's deferred request — a critical
   assessment of the three videos' implementation ideas against context
   budget and usefulness; candidates and on-disk evidence are listed under
   "Deferred" in `research/video-notes-2026-09-27.md`. Do not start it
   before node 16 is done.
6. At WARN/STOP: ledger block (insert after the header's `-->`; blocks are
   `# Session Handoff — N`; keep two, archive the rest newest-on-top, no
   duplicate N; verify the header count after writing), `plan.sh sync`,
   commit with a `Decision:` trailer, then `session-rollover` (supervised
   chain → `--emit`). Do not push `main`.
7. `plan.sh` flags are separate words (`--project jev-integration`); a
   variable holding both is rejected. `frontier` exits 1 while a reconcile
   node is `doing` — do not chain it with `&&`. A node `check:` runs from the
   work item directory: every path in it needs `"$WORKSPACE_ROOT/"`.
   `plan.sh done` streams the check's full output — pipe through `tail`.
   `plan.sh add <slug>` prefixes its own number: the file is
   `nodes/NN-<slug>.md`; append the body there, never to `nodes/<slug>.md`.
8. Test-authoring gotcha: a background stub started inside `$( … )` must
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
  nodes 01–12 `done`, 13 `todo` (hitl, half-run), 17 `todo` (fix node, lint
  ordering unresolved), 14/15/16 `todo`.
- `decisions.md`: five notes (R0.4 lift; fit decision, approved; typed
  helper; CLI stdin/JSON-lines shape; `classify` dict categories + `question=`).
- `spec.md` Status: draft (the user may flip it to approved; the tickets are
  `ready-for-agent`, 05 `ready-for-human`).
- Chain: supervised; session 12 staged session 13 **interactive** at STOP.
