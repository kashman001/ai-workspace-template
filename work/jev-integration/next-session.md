# Catchup prompt — jev-integration (paste into a new agent session)

We're resuming `jev-integration`. Works in any runtime (Claude Code, Codex,
Gemini, OpenCode) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in
> `handoff.md` (the append-only ledger). Convention:
> docs/work-directory-conventions.md.

## Mission

The gated Jev integration is **shipped**: `scripts/jev.sh` (+ `--help`),
`scripts/tests/test-jev.sh` T1–T19 128/128, `classify()` in
`skills/rlm/scripts/rlm_repl.py` (threshold 0.5, model `jev-latest` @ release
2026-09-10), credentials docs, `skills/jev/`, UAT passed, tuned on two real
runs. Plan `01-gated-integration` has every node done (18/18) and is waiting
only for the user's goal-level close. What is left is three decisions that
are the user's, then possibly one small documentation ticket. This item is
also the `plans` item's dogfood: findings go to `work/plans/decisions.md`.

## Position

<!-- plan:begin position -->
Position: plan 01-gated-integration, open, wave 7 of 7, done 18/18, doing 0, todo 0, blocked 0, dropped 0, sessions 8.
Frontier: none. Remaining: 0 of 18.
<!-- plan:end position -->

## First actions

1. `scripts/context-budget.sh register --project jev-integration` (expect `seq=16`).
2. **Interactive session — three decisions for the user, in this order.**
   Pose all three in one message; act on each answer:
   - **Close the plan.** No `plan.sh` verb does it: edit `status: open` →
     `status: closed` in `plans/01-gated-integration/plan.md` (the last write
     — write verbs refuse a closed plan), then `scripts/plan.sh sync
     --project jev-integration` (renders a closed plan). Record the closing
     as a `Decision:` trailer.
   - **Approve the spec.** `spec.md` line 10 `Status: draft` → `approved`
     and `Approved-by: <user>` (vocabulary is draft | in-review | approved;
     there is no `done`). The user approved the fit note (node 03) and ran
     UAT (node 13); the spec itself was never flipped.
   - **Ticket 07, yes or no.** From `research/video-assessment-2026-09-27.md`
     (read it whole — 49 lines): #1 a data-leaves-the-machine sentence in
     `skills/jev/SKILL.md` (No-key contract or step 2) and
     `docs/service-access.md` → Jev Notes; #2 a Score-reliability clause in
     the skill's type table; #4 (optional, spec amendment) a `JEV_DISABLED=1`
     env var honoured by `scripts/jev.sh` as the no-key branch (exit 3) plus
     one test. If yes: `issues/07-<slug>.md`, no plan (one session, one
     agent), check = `bash scripts/tests/test-jev.sh` 128/128 (+1 if #4).
3. Dogfood close-out when the plan closes: `work/plans/issues/11-dogfood-first-real-plan.md`
   box 1 says "chain ends with verdict plan_closed" — this plan was closed by
   a person, not a chain; note that under its Comments rather than ticking.
4. At WARN/STOP (or when the decisions are taken): ledger block (insert after
   the header's `-->`; blocks are `# Session Handoff — N`; keep two, archive
   the rest newest-on-top, no duplicate N; verify the header count after
   writing), commit with a `Decision:` trailer, then `session-rollover`
   (supervised chain → `--emit`) or `checkpoint` if the item is finished.
   Do not push `main`.
5. `plan.sh` flags are separate words and **literal** — `--project
   jev-integration` held in a shell variable is refused as "unknown option"
   (bit session 15 too). `sync` after any state write, not before.

## Do NOT reload

- `research/` beyond the assessment; `video-notes-2026-09-27.md` only if the
  assessment's reasoning is questioned; `spike.md` never.
- `rulings.md`, `sweep.md`, `seam-inventory.md`, the corrections — settled.
- `spec.md` beyond line 10 (Status) unless #4 is taken (then S-item on key
  resolution, ~line 145).
- `work/plans/` beyond `decisions.md` (append) and the dogfood ticket.
- `handoff.md` — the top block only if something above is unclear.
- `scripts/tests/test-jev.sh` in full (390 lines) — grep a `T<n>` label.
- Plan node files — the plan is done; `plan.sh status` is enough.

## Constraints already decided (do not re-litigate)

- **Never run `scripts/jev.sh` without `JEV_ENDPOINT` pointing at the stub
  unless it is `--check` or `--help`.** This machine's keychain holds a real
  key; a bare run is a live paid request. No further live call is planned.
- Template rules: agent-agnostic, CLI-first, credentials in the keychain,
  documented as a first-class addition, a test that proves it without a live
  key. `scripts/jev.sh` is the only code that knows the endpoint or the key.
- CLI contract (fourth note in `decisions.md`): request JSON on stdin; one
  JSON line `{key,value,confidence}` per answer; exit 0/2/3/4; `--check` and
  `--help` are the only flags (an env var is not a flag). Help text ≤ 80
  cols, sections in order, examples byte-identical through `jq -c`.
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

## State snapshot

- Branch `main`, ahead of origin, not pushed; session 15's work in one
  commit. Plan `01-gated-integration` `open`, 18/18 done, frontier none,
  `check` silent.
- `decisions.md`: eight notes (the eighth: threshold 0.5 + pin). Tickets
  01–06 `resolved`. `spec.md` Status `draft`.
- `work/plans/decisions.md` carries dogfood findings s8–s15.
- `/tmp/jev-uat/`, `/tmp/nokey/` are machine-local and no longer needed.
- Chain: supervised; session 15 rolled over at WARN; session 16 is
  **interactive**.
