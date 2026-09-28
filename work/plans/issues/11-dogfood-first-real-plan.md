# 11 — Dogfood: run the next multi-session item as the first real plan

**What to build:** Open a plan in the next real multi-session work item, drive it with `session-loop.sh --plan` through at least two waves including one hitl node and one reconcile node, and record in that item's ledger and in `work/plans/decisions.md` what broke, what was slow, and whether L48 (wayfinder as a plan template) should be taken up.

**Blocked by:** 10

**Status:** ready-for-agent (in progress since 2026-09-25, session 15 — plan `work/jev-integration/plans/01-gated-integration` opened; findings accrue in `decisions.md`)

**Spec:** S1–S36 (verification)

- [ ] Chain ends with verdict plan_closed at least once
- [ ] A rollover split of an overrunning node happened, or was shown unnecessary
- [ ] Findings appended to `work/plans/decisions.md`; README status line of this item updated

## Comments

- 2026-09-27 (jev-integration s15, wave 7 join): plan `01-gated-integration`
  reached its last join — 17/18 done, seven sessions, two hitl nodes (03, 13,
  plus the replanned gate 15a), one local and two structural replans, no
  rollover split needed (every node fit one session). Findings in
  `work/plans/decisions.md`, newest: s14 hitl-at-creation (a ticket that says
  "needs the user / a key / spend" should get a `hitl` gate when the plan is
  created from tickets, not at the join) and s15 sync-after-done (`sync`
  before `done` leaves the Position block one state stale). Closing the plan
  is the user's; the first box ticks once the chain reports `plan_closed`.
- 2026-09-27 (jev-integration s16): plan `01-gated-integration` closed
  18/18 — by a person (the user answered "close it" in an interactive
  session and the agent edited `status: open` → `closed`, then `sync`),
  not by a chain reporting `plan_closed`. Box 1 stays unticked: the chain
  ended at a hitl gate and a WARN rollover, and no `plan.sh` verb closes a
  plan (s15 finding "no close verb"). The plan-closed verdict remains
  unexercised by this dogfood.
