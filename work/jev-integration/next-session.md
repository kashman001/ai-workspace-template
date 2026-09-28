# Catchup prompt — jev-integration (paste into a new agent session)

`jev-integration` is **finished** (checkpoint, session 16, 2026-09-27).
Works in any runtime (Claude Code, Codex, Gemini, OpenCode) — all read
`CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in
> `handoff.md` (the append-only ledger). Convention:
> docs/work-directory-conventions.md.

## Mission — complete

The gated Jev integration is shipped and closed: `scripts/jev.sh` (+
`--help`, `JEV_DISABLED=1` off switch), `scripts/tests/test-jev.sh` T1–T20
140/140, `classify()` in `skills/rlm/scripts/rlm_repl.py` (threshold 0.5,
model `jev-latest` @ release 2026-09-10), `skills/jev/`, credentials docs,
UAT passed, tuned on two real runs. Plan `01-gated-integration` is
**closed** 18/18; `spec.md` is **approved**; tickets 01–07 `resolved`.
Nothing is scheduled. Ledger top block (`handoff.md` — 16) has the close-out.

## Position

<!-- plan:begin position -->
Position: plan 01-gated-integration, closed, wave 7 of 7, done 18/18, doing 0, todo 0, blocked 0, dropped 0, sessions 8.
Frontier: none. Remaining: 0 of 18.
<!-- plan:end position -->

## If a session opens this item again

1. `scripts/context-budget.sh register --project jev-integration`
   (next `seq=17`).
2. There is no open work. Possible reasons to be here, each a new decision
   for the user, not a continuation:
   - **A later slice** from `spec.md` ("later slices": tier routing at
     dispatch, another seam) or the assessment's #3 (a paid batch to confirm
     0.5 on the crisp commit corpus; well under a cent) → open a new ticket
     (`issues/08-…`) or a new plan (`/plan create`), never a wave 8 of the
     closed plan (write verbs refuse it).
   - **A re-pin** when `GET /v1/models` shows a newer `release_date` for
     `jev-latest` → re-tune the threshold (ninth note's recipe is in
     `decisions.md`; corpus recipe in the s13 note) — a paid call, the
     user's to trigger.
   - **A regression** → `bash scripts/tests/test-jev.sh` (140/140 expected)
     is the check; `diagnosing-bugs`.
3. At the end: ledger block 17 (insert after the header's `-->`; keep two
   blocks, archive the rest newest-on-top; verify the header count), commit
   with a `Decision:` trailer, `checkpoint`. Do not push `main`.

## Do NOT reload

- `research/` (all settled; the assessment is applied), `spike.md` never.
- `rulings.md`, `sweep.md`, `seam-inventory.md`, the corrections.
- `spec.md` beyond its Status lines unless a later slice is taken.
- Plan node files — the plan is closed; `plan.sh status` is enough.
- `scripts/tests/test-jev.sh` in full (413 lines) — grep a `T<n>` label.

## Constraints already decided (do not re-litigate)

- **Never run `scripts/jev.sh` without `JEV_ENDPOINT` pointing at the stub
  unless it is `--check` or `--help`.** This machine's keychain holds a real
  key; a bare run is a live paid request. `JEV_DISABLED=1` is the safe
  default for any experiment on this machine.
- Template rules: agent-agnostic, CLI-first, credentials in the keychain,
  documented as a first-class addition, a test that proves it without a live
  key. `scripts/jev.sh` is the only code that knows the endpoint or the key.
- CLI contract (fourth note in `decisions.md`): request JSON on stdin; one
  JSON line `{key,value,confidence}` per answer; exit 0/2/3/4; `--check` and
  `--help` are the only flags (`JEV_DISABLED` is an env var, not a flag —
  ninth note). Help text ≤ 80 cols, sections in order, examples
  byte-identical through `jq -c`.
- `llm_query` is byte-for-byte untouched (T14 golden — never regenerate).
  Threshold 0.5, model `jev-latest` @ release 2026-09-10 (no versioned id
  exists — do not invent one); the fixtures' `jev-1.13.0` is a stub-only
  override value (eighth note). Vendored `skills/jev/typesafe-ai/` is pristine
  upstream (`65a39f3`, v0.5.7) below its provenance comment.
- Raw `pass/*.md`, `fact-check.md`, `record.md`, briefs, `spike.{md,py}` are
  provenance — never edited. The key stays in the keychain: never print it.
- No model name in plan files. Do not edit `plan.sh`, `session-loop.sh`, or
  the plans skill from this item — a dogfood finding is a note in
  `work/plans/decisions.md`.
- `plan.sh` flags are separate words and literal (`--project jev-integration`
  in a shell variable is refused).

## State snapshot

- Branch `main`, ahead of origin, not pushed (the user pushes). Session 16's
  work in one commit. Plan `closed`, spec `approved`, tickets 01–07
  `resolved`, `decisions.md` nine notes, test-jev.sh 140/140.
- `work/plans/decisions.md` carries dogfood findings s8–s16; ticket 11 of
  the `plans` item keeps box 1 open (no chain-side `plan_closed`).
- `/tmp/jev-uat/`, `/tmp/nokey/` are machine-local and no longer needed.
- Chain: ended. Session 16 checkpointed; no successor scheduled.
