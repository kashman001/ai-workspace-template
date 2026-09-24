# Catchup prompt — plans (paste into a new agent session)

We're resuming `plans`. Works in any runtime (Claude Code, Codex, Gemini,
OpenCode) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, REPLACED at
> each rollover: what to do next, still-binding constraints, pointers — never
> session history. Past-tense provenance lives in `handoff.md` (the ledger).
> Convention: docs/work-directory-conventions.md.

## Mission

Finish ticket **07** (`issues/07-session-loop-integration.md`). Slice a is
committed (`c2ea565`): the fake-child cases P1–P4 in
`scripts/tests/test-session-loop.sh` are RED (24 of 140) and are the spec.
Slice b is the code in `scripts/session-loop.sh`; then the docs box. Then
**08** in the same session only if budget allows — `record` before it.

## Read these, in order (keep it lean — session 10 hit WARN on reading)

1. `scripts/tests/test-session-loop.sh` → grep `^echo "P` and read P1–P4 and
   the `mkplan` helper above them (~70 lines). Do not read the whole file.
2. `scripts/session-loop.sh` — read whole (374 lines): the option loop, the
   start gates, the `.chain = {…}` start write, and the between-children
   block from `[ "$seq_after" = "$((seq + 1))" ]` to the interactive pause.
3. `scripts/plan.sh` header only (`sed -n 1,45p`): the verbs used are
   `status --json` (`.status`), `graph --json` (`.nodes[]` with `kind`,
   `wave`, `status`), `frontier --json` (array; exit 1 = nothing ready),
   `check` (exit 1 on violations, lines on stdout), `sync` (exit 1 when a
   marker pair is missing). Always pass `--project "$PROJECT" --plan "$slug"`.
4. `docs/context-budget.md` lines 379–528 only when doing the docs box.

## Design (settled in the 2026-09-24 decision note — do not re-derive)

- `--plan <slug>` option. After the `supervisor_live` gate, before the
  `.chain = {…}` start write: slug = `--plan` → `.chain.plan` in the record →
  the single `work/<p>/plans/*/plan.md` with `status: open` (0 → none; ≥2 →
  `refuse plan_invalid "leg=ambiguous …"`). A slug that `plan.sh status
  --json` cannot read → `refuse plan_invalid "leg=unresolved …"`. Add
  `plan: $plan` (string or null) to the start write so it survives restarts.
- Between children, after the lifetime check and before the `verdict staged`
  line, only when a plan is bound: `sync` (rc≠0 → `broken plan_invalid
  "leg=sync …"`), `check` (rc≠0 → `broken plan_invalid "leg=check …"`, its
  lines relayed on stderr). Then closed = `status --json` `.status=="closed"`
  AND the reconcile node of the highest wave in `graph --json` is `done`.
  Else if `frontier --json` exits 0, is non-empty and every node is
  `kind=="hitl"` → `mode=interactive`, `rec_write true '.launch.mode =
  "interactive"'`, `say` why. Emit `verdict staged "… mode=$mode"`; if closed:
  `rec_write` `.chain.closed = {at, by_seq: $seq, reason: "plan_closed"}`,
  `notify "verdict=plan_closed seq=$seq plan=$slug — …"`, `exit 0`.
- Plan-less items: not one line of behaviour changes (105 assertions pin it).
- Docs box: `docs/context-budget.md` → usage block gets `[--plan <slug>]`; a
  "Plans" paragraph under "The supervisor"; verdict table row `plan_closed`;
  the broken list gains `plan_invalid`; under "Verbs and reason codes":
  supervisor start `plan_invalid` (legs unresolved, ambiguous), verdicts
  `plan_closed`, broken `plan_invalid` (legs sync, check). One sentence in
  `docs/plans.md` → "Resolution" that the supervisor writes `chain.plan`.
  `scripts/tests/test-doc-consistency.sh` pins all of it.

## Do NOT reload

- `decisions.md`, `concept.md`, `seams.md`, `spec.md`, the grill — settled.
- Tickets 01–06 — done. `plan-tiers.env` and tier stamps — do not touch.
- `handoff.md` — the top block only if something above is unclear.

## Still binding

- Bash 3.2 + jq only; match the scripts' style. Exit codes as documented
  (supervisor: 0 ended, 1 broken, 3 usage, 4 refused).
- `session-state.json` schema stays 1; `chain.plan` is the one new field
  (plus the supervisor may set `launch.mode`).
- `test-session-loop.sh` all 140 green, `test-plan.sh` (238) untouched and
  green, `test-doc-consistency.sh` green after the docs box.
- No concrete model name anywhere. Nothing pushed to origin.

## State snapshot

Branch `main`, clean after this rollover's commit; nothing pushed (39+
ahead). Tickets: 01–06 `done`; 07 in flight (tests red, committed); 08–11
`ready-for-agent`. Chain supervised by `session-loop.sh` (seq 1 → … → 10 →
11). Budget at rollover: WARN (~135K). Untracked
`work/jev-integration/research/spike.{md,py}` are another item's.

## First actions

1. `scripts/context-budget.sh register --project plans` (expect `seq=11`).
2. No question to pose. Proceed hands-off.
3. Code slice b in `scripts/session-loop.sh` per "Design" until
   `bash scripts/tests/test-session-loop.sh` prints `passed=140 failed=0`;
   update the script's header comment (usage line, codes list);
   `record --label "ticket 07 code"`; commit.
4. Docs box; `test-doc-consistency.sh` green; tick the three boxes in
   `issues/07-*.md`, status `done`; commit (no new `Decision:` trailer unless
   a new choice was made — the shape is settled).
5. `record` at each step. At the end or at WARN/STOP: ledger block, rewrite
   this launcher (ticket 08 next), update the `work/README.md` row, commit.
   Do not push main; report how far ahead it is.
