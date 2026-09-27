# Catchup prompt — jev-integration (paste into a new agent session)

We're resuming `jev-integration`. Works in any runtime (Claude Code, Codex,
Gemini, OpenCode) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in
> `handoff.md` (the append-only ledger). Convention:
> docs/work-directory-conventions.md.

## Mission

Research is closed (`research/synthesis.md`; live spike `research/spike.md`).
On 2026-09-25 the user set the direction: **integrate Jev, gated on access** —
active only where a person has a key (`jev-api-key` in the OS keychain);
without one, nothing changes. The rest of this item runs as **plan
`01-gated-integration`** (`plans/01-gated-integration/`): wave 1 drafted the
fit note (done, session 7), wave 2 a person approves it, wave 3 writes spec +
tickets and the join replans the implementation waves in. It is also the
`plans` item's dogfood (`work/plans/issues/11-dogfood-first-real-plan.md`):
what breaks, what is slow, and the L48 question go to
`work/plans/decisions.md` as they appear.

## Position

<!-- plan:begin position -->
Position: plan 01-gated-integration, open, wave 2 of 3, done 2/6, doing 0, todo 4, blocked 0, dropped 0, sessions 1.
Frontier: 03-approve-decision. Remaining: 4 of 6 — wave 2: 03-approve-decision todo, 04-reconcile-w2 todo.
<!-- plan:end position -->

## For the person — what node 03 asks (the frontier is a `hitl` node)

Read the **second** note in `decisions.md` (`## 2026-09-27 — Fit decision: …`).
It is a proposal: integrate Jev at the `rlm` leaf-classification seam, gated
on the keychain key; a user without a key sees no change. It carries your Q4
answer (gated) and three proposals from session 6 for you to confirm or amend:

- **Q1** what "serves better" means — proposed (c) determinism + thresholdable
  `confidence`, latency second (not output quality, not cost).
- **Q2** scope — proposed narrow to `rlm`; research-wave verdicts next; the
  other four seams rejected one line each.
- **Q5** how far the key's use widens — proposed orchestrator fact-finding
  now, dispatched agents once the spec says so.
- **Promote?** — left to you (`no` / `maybe` / `yes`).

Also pending your read (recorded as plan notes, `scripts/plan.sh show
02-reconcile-w1` or `plan.md`): TypeSafe's Claude Code plugin is one
SKILL.md with no code (installable for Codex and others via `npx skills
add`), so it is agent knowledge, not the integration; node 05 re-checks the
marketplace for anything newer than 2026-09-23.

A wording fix: edit the note in place. A material change: append a new note
(`skills/decision-log/SKILL.md`). "No-go" is an answer too — write it in the
note. Then:

    scripts/plan.sh done 03-approve-decision --by <your-name> --project jev-integration

## First actions (agent session)

1. `scripts/context-budget.sh register --project jev-integration` (expect `seq=8`).
2. `scripts/plan.sh frontier --project jev-integration`. If it still names
   `03-approve-decision`: stop — a person does it (section above); end with
   `checkpoint`. If it names `04-reconcile-w2`: the person has answered — run
   the reconcile in this session per `skills/plans/SKILL.md` ("Run a reconcile
   node"): verify the note on disk, record the decision the person made (a
   "no-go" closes the plan through the stop door), replan within authority,
   `done`. Then wave 3: `05-spec-and-tickets` per its node file.
3. Overruns: `block <id> <reason>` or split (Replan rule 1); record which as a
   finding — ticket 11 asks whether a rollover split happened (none so far).
4. At WARN/STOP, or when the frontier holds nothing this session can do:
   ledger block in `handoff.md` (insert after the `-->` of the header comment;
   verify block headers unique), `scripts/plan.sh sync`, rewrite the prose
   above the Position block only if the mission changed, commit with a
   `Decision:` trailer. Do not push `main`.
5. Dogfood findings: append one bullet each under the dated "Dogfood findings"
   list at the end of `work/plans/decisions.md`. Do not edit `plan.sh`,
   `session-loop.sh`, or the plans skill from this item.
6. `plan.sh` takes `--project jev-integration` as two words; a shell variable
   holding both is rejected as `unknown option` (finding, s7).

## Do NOT reload

- `research/` beyond what a node's Goal names (claim ids by grep).
- `rulings.md`, `sweep.md`, `seam-inventory.md`, the corrections — settled.
- `work/plans/` beyond `decisions.md` (append) and `issues/11-dogfood.md`
  (read once).
- `handoff.md` — the top block only if something above is unclear.
- The grill round: its questions are in the fit note and the section above.

## Constraints already decided (do not re-litigate)

- Template rules: agent-agnostic, CLI-first or `mcp-fragments/`, credentials
  in the keychain, documented as a first-class addition, a test that proves
  it without a live key.
- "Gated on access" is the user's direction; the seam order (`rlm` first) is
  the proposal in the fit note, approved or amended by a person in node 03 —
  an agent never skips 03.
- Raw `pass/*.md`, `fact-check.md`, `record.md`, every brief, and
  `spike.{md,py}` are provenance — never edited.
- No concrete model name in plan files (tiers only).

## State snapshot

- Branch `main`, not pushed. Plan `01-gated-integration` open: wave 2 of 3,
  nodes 01 and 02 `done` (session 7), frontier `03-approve-decision` (hitl).
- `decisions.md` holds two notes: the R0.4 lift (2026-09-24) and the fit
  proposal (2026-09-27); the "STILL OPEN" line is now a pointer.
- `research/spike.{md,py}` are tracked — never edited; do not re-run the
  spike. The key stays in the keychain: never print it, never write it to a
  file.
- Chain: reopened 2026-09-27 bound to the plan (`session-loop.sh
  jev-integration --reopen --plan 01-gated-integration`), used 7 of 15;
  session 7 closed through the checkpoint door at a `hitl` frontier, so the
  supervisor stages the next session interactive. If it is not running when
  the person has answered node 03, restart it with the command above.
