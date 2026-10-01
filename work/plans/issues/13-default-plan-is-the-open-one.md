# 13 — Default plan is the open one (plan.sh and session-loop.sh)

**What to build:** With one closed and one open plan in an item, `plan.sh` verbs without `--plan` resolve to the closed plan (`chain.plan` in the record) and writes are refused; `session-loop.sh` binds the stale closed plan at start, re-renders the launcher Position block from it, and ends the chain with a false `plan_closed`. Fix: when `chain.plan` names a closed plan and exactly one other plan is open, resolve to the open one (and rebind `chain.plan`); with several open plans, refuse naming `--plan`. `plan.sh new` prints the `--plan` flag the next writes need. Source: findings s17, s18 (jev-integration).

**Blocked by:** 11

**Status:** done (2026-09-30, s18)

**Spec:** S-chain.plan rules (`docs/plans.md` → session loop)

- [x] Test reproducing s18 (closed 01, open 02, `chain.plan=01`) fails first, then passes: no false `plan_closed`, Position block shows plan 02
- [x] `plan.sh` default-plan resolution test for the same layout
- [x] `test-plan.sh` and `test-session-loop.sh` green
