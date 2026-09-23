# 11 — Dogfood: run the next multi-session item as the first real plan

**What to build:** Open a plan in the next real multi-session work item, drive it with `session-loop.sh --plan` through at least two waves including one hitl node and one reconcile node, and record in that item's ledger and in `work/plans/decisions.md` what broke, what was slow, and whether L48 (wayfinder as a plan template) should be taken up.

**Blocked by:** 10

**Status:** ready-for-agent

**Spec:** S1–S36 (verification)

- [ ] Chain ends with verdict plan_closed at least once
- [ ] A rollover split of an overrunning node happened, or was shown unnecessary
- [ ] Findings appended to `work/plans/decisions.md`; README status line of this item updated
