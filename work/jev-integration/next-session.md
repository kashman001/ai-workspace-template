# Catchup prompt — jev-integration (paste into a new agent session)

`jev-integration`'s first plan is shipped and closed (s16); the user has
**approved the follow-on** (2026-09-28) — session 17 plans it.
Works in any runtime (Claude Code, Codex, Gemini, OpenCode) — all read
`CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in
> `handoff.md` (the append-only ledger). Convention:
> docs/work-directory-conventions.md.

## Mission — first plan complete; follow-on approved

The gated Jev integration is shipped and closed: `scripts/jev.sh` (+
`--help`, `JEV_DISABLED=1` off switch), `scripts/tests/test-jev.sh` T1–T20
140/140, `classify()` in `skills/rlm/scripts/rlm_repl.py` (threshold 0.5,
model `jev-latest` @ release 2026-09-10), `skills/jev/`, credentials docs,
UAT passed, tuned on two real runs. Plan `01-gated-integration` is
**closed** 18/18; `spec.md` is **approved**; tickets 01–07 `resolved`.
Next: plan the approved follow-on (below). Ledger top block
(`handoff.md` — 16) has the close-out and the approval.

## Position

<!-- plan:begin position -->
Position: plan 02-follow-on, open, wave 1 of 2, done 0/7, doing 0, todo 7, blocked 0, dropped 0, sessions 0.
Frontier: 01-confirm-threshold, 02-score-check-helpers, 03-relevance-experiment. Remaining: 7 of 7 — wave 1: 01-confirm-threshold todo, 02-score-check-helpers todo, 03-relevance-experiment todo, 04-reconcile-w1 todo.
<!-- plan:end position -->

## First actions — plan the approved follow-on

0. `scripts/context-budget.sh register --project jev-integration` (expect
   `seq=17`). Interactive session: the grill below needs the user.

The user approved **all** Jev follow-on items listed at the s16 checkpoint
and authorized any spending they need ("You have my approval if any
spending is needed"). This session was at WARN, so the planning is the
successor's first job. Scope, in the order proposed (reorder if the grill
says so):

1. **Confirm 0.5 on the crisp commit corpus** — one paid Jev batch (100
   commit subjects, `threshold=0.0`, confidence distribution + leaf
   agreement); recipe in the s13 note of `decisions.md`; regenerate the
   corpus with `git log --format=%s -n 100`. Spend approved; still say what
   it cost. Verdict goes to a tenth decision note (keep 0.5 or move it).
2. **Score and Noul in the `rlm` helper** — `classify()` is Choice-only;
   the CLI already does all three. Spec non-goal to lift; T-tests widen.
3. **Jev at a second seam: research-wave verdicts** — the spec's named
   next candidate; same gate-on-key rule, same CLI, no new vendor surface.
4. **Tier routing at subagent dispatch** — resolve `tier: auto` with a Jev
   decision. Touches `plan.sh` / `plan-tiers.env`, owned by the `plans`
   item: coordinate there (a ticket in `work/plans/issues/`), baseline to
   beat is cheap-first + escalate on a failed check.
5. **Relevance filter** before loading files/tickets into context — the
   vaguest; grill it to a testable slice or drop it with a note.
(Re-pin on a newer `jev-latest` release date stays a watch item, not work.)

How to plan: `grill-with-docs` on the five (amend `spec.md` — new S-items,
lift the non-goals it takes; Status back to `in-review` until the user
re-approves), `to-tickets` → `issues/08-…` onward, then `/plan create` as
`plans/02-<slug>/` in this item (default; a new work item only if the grill
finds the scope no longer fits "Jev at seams"). Paid calls get a `hitl`
gate only where the user must *run* them on their machine — the spend
itself is pre-authorized. Same constraints as below; never a bare
`scripts/jev.sh` run outside the batch you intend to pay for.

## Other reasons to be here (not now — the follow-on above comes first)

1. Each of these is a separate decision for the user, not a continuation:
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

- Branch `main`, pushed to origin at c43a271 on 2026-09-28; two later
  commits (index row, approval) plus this rollover are ahead — the user
  pushes. Plan `closed`, spec `approved`, tickets 01–07
  `resolved`, `decisions.md` nine notes, test-jev.sh 140/140.
- `work/plans/decisions.md` carries dogfood findings s8–s16; ticket 11 of
  the `plans` item keeps box 1 open (no chain-side `plan_closed`).
- `/tmp/jev-uat/`, `/tmp/nokey/` are machine-local and no longer needed.
- Chain: supervised. Session 16 checkpointed, then rolled over interactive
  at WARN once the follow-on was approved; session 17 plans.
