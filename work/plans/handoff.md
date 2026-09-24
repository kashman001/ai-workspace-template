<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 12 (2026-09-24): ticket 08 done — node split at rollover, sync step in three skills

**Summary.** Seq 12, supervised chain, hands-off. Started at ~58K, ended
~105K (below WARN). The split was exercised three times on a fixture copy
under the scratchpad (plain, with a `check:`, and a verbatim replay of the
skill text) before it was written down. Slice a (`66c8978`):
`skills/session-rollover/SKILL.md` step 3 gains the conditional sync line and
the six-verb split (`show` → `add` → rename to `<id>-b` + carry `sessions` →
dependants' `blocked_by` → drop `check:`, `done`, Log line → `check`, `sync`);
step 5 keeps the position markers when a plan is open; reconcile/hitl nodes
are never split. Slice b (`89490e5`): the same sync line in
`skills/checkpoint/SKILL.md` step 3. Slice c (`874a623`):
`skills/create-work-item/SKILL.md` scaffolds the `## Position` marker block
only on `--plan` (argument-hint updated in `.claude/commands/create-work-item.md`).
Ticket 08 boxes ticked, status `done` (`e50bedf`). Suites: test-plan 238/238,
test-session-loop 140/140, test-doc-consistency 7/7.

**Decision.** The remainder is renamed to the origin's number after `add`
(the `reconcile-last` lint compares ids as strings and `add` numbers past the
wave's join); note in `decisions.md`, `Promote?: no`.

**Not done.** Ticket 09 (the `plans` skill + `/plan`) — a whole skill with
three procedures and a fixture walk-through; left for a fresh window. Nothing
pushed (main 46 ahead of origin).

# Session Handoff — 11 (2026-09-24): ticket 07 done — the loop's plan hook, code + docs

**Summary.** Seq 11, supervised chain, hands-off. Started at ~56K, ended
~110K (below WARN). Slice b (`232688d`): `scripts/session-loop.sh` gains
`--plan <slug>`; after the `supervisor_live` gate it binds a plan (`--plan` →
`chain.plan` in the record → the single `plans/*/plan.md` with `status: open`;
two open → `refused plan_invalid leg=ambiguous`, a slug `plan.sh status`
cannot read → `leg=unresolved`, both before any write) and stamps
`chain.plan` in the start write. Between children, when bound: `plan.sh
sync` then `check` (failure → `broken plan_invalid leg=sync|check`, lines
relayed, staged command kept); a `closed` plan whose highest-wave reconcile
node is `done` → `verdict=plan_closed`, `chain.closed` written, exit 0; a
hitl-only frontier → `launch.mode=interactive` in the record. Docs box
(`b388f07`): `docs/context-budget.md` usage, a "Plans" paragraph under "The
supervisor", the `plan_closed` verdict row, `plan_invalid` in the broken list
and the reason-code table; one sentence in `docs/plans.md` → "Resolution".
Ticket 07 boxes ticked, status `done`. Suites: test-session-loop 140/140,
test-plan 238/238, test-doc-consistency 7/7.

**One ordering detail the tests settled** (no new decision note — the shape
was pinned by P2c/P4b): the `staged` verdict is emitted *before* the plan
outcome, carrying the plan-derived mode; a `plan_invalid` break or a
`plan_closed` close follows it. So the child's rollover is judged on its own,
then the plan says whether the chain goes on.

**Not done.** Ticket 08 (node split at rollover + the conditional sync step
in `session-rollover`, `checkpoint`, `create-work-item`) — needs a fresh
window; the launcher points at it. Nothing pushed (main 41+ ahead of origin).
