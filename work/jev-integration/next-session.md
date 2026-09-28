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
tickets under `issues/`. Plan `01-gated-integration`: waves 4–7, one node per
ticket, a reconcile last in each wave. Waves 4–6 are done (`scripts/jev.sh` +
`--help`, `scripts/tests/test-jev.sh` T1–T19 128/128, `classify()` in
`skills/rlm/scripts/rlm_repl.py`, credentials docs, `skills/jev/`, UAT passed
by the user). Wave 7's work is done too (threshold 0.5,
pin `jev-latest` @ release 2026-09-10). Left: the wave 7 join, which closes
the plan, then the user's deferred video assessment. This item is also the `plans` item's dogfood:
findings go to `work/plans/decisions.md`.

## Position

<!-- plan:begin position -->
Position: plan 01-gated-integration, open, wave 7 of 7, done 17/18, doing 0, todo 1, blocked 0, dropped 0, sessions 7.
Frontier: 16-reconcile-w7. Remaining: 1 of 18 — wave 7: 16-reconcile-w7 todo.
<!-- plan:end position -->

## First actions

1. `scripts/context-budget.sh register --project jev-integration` (expect `seq=15`).
2. **Interactive session.** Run `16-reconcile-w7` per `skills/plans/SKILL.md`
   → "Run a reconcile node": `start`; verify node 15 on disk — `bash
   scripts/tests/test-jev.sh | tail -1` → 128/128; `grep -n
   'DEFAULT_JEV_THRESHOLD = ' skills/rlm/scripts/rlm_repl.py` → `"0.5"`;
   `grep -c '0\.9' skills/rlm/SKILL.md skills/jev/SKILL.md` → the only
   remaining `0.9`s are the spike's "0.89–1.0" range; `grep -n release
   skills/jev/SKILL.md skills/rlm/SKILL.md` → both name 2026-09-10; node 15a's
   Log holds the raw numbers, the eighth note in `decisions.md` the decision.
   Verify `git diff HEAD~1 --stat` touches only the files the note's Blast
   radius lists. Record (`plan.sh note` for anything not yet a node); replan:
   nothing remains — closing the plan is **goal-level**, so propose it in the
   Log and stop; the user closes (`plan.sh` close verb, or says so). `check`
   silent, `sync`, `done`. No human needed for the join itself.
3. The user's deferred request: a critical assessment of the three videos'
   implementation ideas against context budget and usefulness; candidates
   under "Deferred" in `research/video-notes-2026-09-27.md`. Plain-language,
   one page, self-contained (the user rejects jargon-heavy design docs).
4. Housekeeping the join may propose: `spec.md` Status draft → done; ticket
   06 `ready-for-agent` → done; `work/plans/issues/11-dogfood.md` gets the
   two s14 findings (hitl-at-creation; sync-after-done). Dogfood decisions
   are already in `work/plans/decisions.md`.
5. At WARN/STOP: ledger block (insert after the header's `-->`; blocks are
   `# Session Handoff — N`; keep two, archive the rest newest-on-top, no
   duplicate N; verify the header count after writing), `plan.sh sync`,
   commit with a `Decision:` trailer, then `session-rollover` (supervised
   chain → `--emit`). Do not push `main`.
6. `plan.sh` flags are separate words (`--project jev-integration`).
   `frontier` exits 1 while a reconcile node is `doing` — do not chain it
   with `&&`. `done` on a `todo` node needs `start` first (or `--force`);
   hitl nodes need `--by`. A node `check:` runs from the work item directory:
   every path needs `"$WORKSPACE_ROOT/"`. `plan.sh done` streams the check's
   output — pipe through `tail`. Run `sync` *after* `done`, not before — the
   Position block is a snapshot.
7. Keyless testing: `/tmp/nokey/security` must stay a **pass-through** stub
   that fails only the `jev-api-key` lookup. Leaf batches of 50 via `claude
   -p haiku` take ~30 s; that is slow, not hung. The REPL state
   (`.claude/rlm_state/state.pkl`) now holds the 100 ledger bullets, not the
   commits; both corpora are in `/tmp/jev-uat/` (`commits.txt`, `ledger.txt`).

## Do NOT reload

- `research/` beyond claim ids by grep; `spike.md` only if a number is needed.
- `rulings.md`, `sweep.md`, `seam-inventory.md`, the corrections — settled.
- `spec.md` "User Stories" in full — grep an `S<n>` when a box cites one.
- `work/plans/` beyond `decisions.md` (append) and `issues/11-dogfood.md`.
- `handoff.md` — the top block only if something above is unclear.
- `scripts/tests/test-jev.sh` in full (390 lines) — grep a `T<n>` label.
- `uat-help-proposal.txt` — applied; `scripts/jev.sh --help` is the text now.

## Constraints already decided (do not re-litigate)

- **Never run `scripts/jev.sh` without `JEV_ENDPOINT` pointing at the stub
  unless it is `--check` or `--help`.** This machine's keychain holds a real
  key; a bare run is a live paid request. Node 15a's two calls were run with
  the user's in-session authorization; no further live call is planned.
- Template rules: agent-agnostic, CLI-first, credentials in the keychain,
  documented as a first-class addition, a test that proves it without a live
  key. `scripts/jev.sh` is the only code that knows the endpoint or the key;
  the model-listing `curl` is a one-off in the node file, not a script.
- CLI contract (fourth note in `decisions.md`): request JSON on stdin, passed
  through; one JSON line `{key,value,confidence}` per answer (Noul:
  confidence `null`); key reaches Python via the child env only; exit 0/2/3/4;
  `--check` and `--help` are the only flags. Help text: every line ≤ 80 cols,
  sections USAGE…SEE ALSO in order, examples byte-identical through `jq -c`.
- `llm_query` is byte-for-byte untouched (T14 golden diff — never regenerate
  the golden). `classify()` and node 15 are done: threshold 0.5, model
  `jev-latest` @ release 2026-09-10 (the listing has no versioned ids — do not
  invent one), fixture r3 at 0.41. No code changes remain in this item.
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

- Branch `main`, 72 ahead of origin, not pushed; session 14's work in two
  commits. Plan `01-gated-integration` open: wave 7 of 7, 17/18 done, only
  `16-reconcile-w7` `todo`; `check` silent.
- `decisions.md`: eight notes (…; UAT observation; hitl gate for node 15's
  calls; threshold 0.5 + pin @ release 2026-09-10 with the rejected values).
- `spec.md` Status: draft (tickets `ready-for-agent`, 05 done by the user;
  06 done in fact, not yet marked).
- `/tmp/jev-uat/` (both corpora + three recipes), `/tmp/nokey/` are
  machine-local.
- Chain: supervised; session 14 rolled over at WARN; session 15 is
  **interactive**.
