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
without one, nothing changes. That answers session 6's grill question Q4 as
(a); Q1 (axis of "serves better"), Q2 (candidate scope) and Q5 (scope of the
R0.4 lift) are drafted as proposals by node 01 and confirmed by a person in
node 03. The rest of this item runs as **plan `01-gated-integration`**
(`plans/01-gated-integration/`): wave 1 drafts the fit note, wave 2 a person
approves it, wave 3 writes spec + tickets and the join replans the
implementation waves in. It is also the `plans` item's dogfood
(`work/plans/issues/11-dogfood-first-real-plan.md`): what breaks, what is
slow, and the L48 question go to `work/plans/decisions.md` as they appear.

## Position

<!-- plan:begin position -->
Position: plan 01-gated-integration, open, wave 1 of 3, done 0/6, doing 0, todo 6, blocked 0, dropped 0, sessions 0.
Frontier: 01-decision-note. Remaining: 6 of 6 — wave 1: 01-decision-note todo, 02-reconcile-w1 todo.
<!-- plan:end position -->

## First actions

1. `scripts/context-budget.sh register --project jev-integration` (expect `seq=7`
   on the first session after 2026-09-25).
2. `scripts/plan.sh frontier` (add `--project jev-integration` if this session
   is bound elsewhere). Work the node it names, per `skills/plans/SKILL.md`:
   `start <id>`, read the node file (`## Goal` is the work, `## Acceptance` the
   definition of done), do it, tick only boxes you verified, `done <id>`.
   A `reconcile` node: the procedure "Run a reconcile node" — it runs in this
   session, never a subagent. A `hitl` node on the frontier: stop — a person
   does it (the node file says how); end with `checkpoint` (stop door); the
   supervisor stages the next session interactive.
3. Overruns: a node that will not finish in this window → `block <id>
   <reason>` or split it (Replan rule 1), and record which as a finding —
   ticket 11 asks whether a rollover split happened or was shown unnecessary.
4. At WARN/STOP, or when the frontier holds nothing this session can do:
   ledger block in `handoff.md`, `scripts/plan.sh sync`, rewrite the prose
   above the Position block only if the mission changed, commit with a
   `Decision:` trailer. Do not push `main`.
5. Dogfood findings: append to `work/plans/decisions.md` under the dated
   "Dogfood" heading (one bullet each). Do not edit `plan.sh`,
   `session-loop.sh`, or the plans skill from this item.

## Do NOT reload

- `research/` beyond what a node's Goal names (synthesis §5–§6, `spike.md`;
  claim ids by grep).
- `rulings.md`, `sweep.md`, `seam-inventory.md`, the corrections — settled.
- `work/plans/` beyond `decisions.md` (append) and `issues/11-dogfood.md`
  (read once).
- `handoff.md` — the top block only if something above is unclear.
- The grill round itself: its four questions live in the node files now.

## Constraints already decided (do not re-litigate)

- Template rules: agent-agnostic, CLI-first or `mcp-fragments/`, credentials
  in the keychain, documented as a first-class addition, a test that proves
  it without a live key.
- "Gated on access" is the user's direction; the seam order (`rlm` first) is
  proposed by node 01 and approved or amended by a person in node 03 — an
  agent never skips 03.
- Raw `pass/*.md`, `fact-check.md`, `record.md`, every brief, and
  `spike.{md,py}` are provenance — never edited.
- No concrete model name in plan files (tiers only).

## State snapshot

- Branch `main`, not pushed. Plan `01-gated-integration` open: 6 nodes, 3
  waves, all `todo`; frontier `01-decision-note`.
- `decisions.md` holds one note (the R0.4 lift, 2026-09-24) and the line
  "Fit decision: STILL OPEN" — node 01 appends the fit note and replaces that
  line with a pointer to it.
- `research/spike.{md,py}` are tracked (session 6, commit 524bb2a) — never
  edited; do not re-run the spike. The key stays in the keychain: read it only
  for a new fact a node needs, never print it, never write it to a file.
- Chain: session 6 quit through the checkpoint door, so the supervisor closed
  the chain (used 6 of 15). Start it again bound to the plan:
  `scripts/session-loop.sh jev-integration --reopen --plan 01-gated-integration`.
