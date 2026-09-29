---
id: 06-tier-routing-evidence
title: Ticket 12 — Tier routing evidence batch + ticket for the plans item
status: todo
kind: work
wave: 2
blocked_by: [01-confirm-threshold]
tier: cheap
check: test -f "$WORKSPACE_ROOT/work/plans/issues/12-jev-tier-routing.md"
sessions: []
---

## Goal

Ticket: issues/12-tier-routing-evidence.md
Spec: S28, S30

No code in this item; `plan.sh` and `plan-tiers.env` are not touched. One paid batch (S28): `state` = every node file of `plans/01-gated-integration/nodes/` (18) plus the `plans` item's own plan nodes (Goal + Acceptance + Check text; reconcile and hitl nodes excluded, they are always frontier); one Choice per node over `frontier / standard / cheap` with criteria = the tier definitions in `docs/plans.md` → "Tiers". Compare with the tier each node actually ran at (`tier <t>` stamp in its Log) and with whether the node closed first time (Log: done without a blocked line). Table: agreement rate overall and by actual tier, Jev's confidence per row, cost. Write `work/plans/issues/12-jev-tier-routing.md` in that item's ticket format with the table as the brief, the two designs (Jev resolver for `auto`; cheap-first + escalate, which does not exist yet) as options, and this item's constraint stated; add one bullet to `work/plans/decisions.md` pointing at it. Node Log carries the cost (S30).

Read first: `docs/plans.md` (Tiers, Log stamps), `plan-tiers.env` (comment header), `work/plans/issues/11-dogfood-first-real-plan.md` (ticket format), `work/plans/decisions.md`, `docs/work-directory-conventions.md`.

Paid batch: run by the agent on the keyed machine (spend pre-authorized 2026-09-28); cost goes in this Log (S30). Never a bare `scripts/jev.sh` run outside the batch intended; `JEV_DISABLED=1` for any dry run. Scratch under the session scratchpad, never checked in.

## Acceptance

- [ ] Node corpus assembled from both items' node files (work nodes only); actual tier read from each Log
- [ ] One Choice per node through `scripts/jev.sh`; agreement table (overall, by actual tier, confidence) built; cost recorded in the node Log
- [ ] `work/plans/issues/12-jev-tier-routing.md` written in that item's format with the table, both designs, and the "no edit from jev-integration" constraint
- [ ] One bullet in `work/plans/decisions.md` linking the ticket; nothing else in the `plans` item touched

## Log
