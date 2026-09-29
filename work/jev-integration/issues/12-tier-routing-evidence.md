# 12 — Tier routing by Jev: evidence batch, then a ticket for the `plans` item

**What to build:** No code in this item; `plan.sh` and `plan-tiers.env` are not touched. One paid batch (S28): `state` = every node file of `plans/01-gated-integration/nodes/` (18) plus the `plans` item's own plan nodes (Goal + Acceptance + Check text; reconcile and hitl nodes excluded, they are always frontier); one Choice per node over `frontier / standard / cheap` with criteria = the tier definitions in `docs/plans.md` → "Tiers". Compare with the tier each node actually ran at (`tier <t>` stamp in its Log) and with whether the node closed first time (Log: done without a blocked line). Table: agreement rate overall and by actual tier, Jev's confidence per row, cost. Write `work/plans/issues/12-jev-tier-routing.md` in that item's ticket format with the table as the brief, the two designs (Jev resolver for `auto`; cheap-first + escalate, which does not exist yet) as options, and this item's constraint stated; add one bullet to `work/plans/decisions.md` pointing at it. Node Log carries the cost (S30).

**Read first:** `docs/plans.md` (Tiers, Log stamps), `plan-tiers.env` (comment header), `work/plans/issues/11-dogfood-first-real-plan.md` (ticket format), `work/plans/decisions.md`, `docs/work-directory-conventions.md`.

**Blocked by:** 08 (Jev picks count only at or above the confirmed threshold).

**Status:** open

**Spec:** S28, S30

- [ ] Node corpus assembled from both items' node files (work nodes only); actual tier read from each Log
- [ ] One Choice per node through `scripts/jev.sh`; agreement table (overall, by actual tier, confidence) built; cost recorded in the node Log
- [ ] `work/plans/issues/12-jev-tier-routing.md` written in that item's format with the table, both designs, and the "no edit from jev-integration" constraint
- [ ] One bullet in `work/plans/decisions.md` linking the ticket; nothing else in the `plans` item touched

**Check:** `test -f "$WORKSPACE_ROOT/work/plans/issues/12-jev-tier-routing.md"`
