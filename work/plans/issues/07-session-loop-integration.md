# 07 — Session loop knows its plan: `chain.plan`, sync + check between children, `plan_closed`, interactive when only HITL

**What to build:** `session-loop.sh --plan <slug>` (or the single open plan) records `chain.plan` in `session-state.json` (schema stays 1); between children the supervisor runs sync then check and refuses the next session on failure the way it refuses staged_invalid; when the terminal reconcile node is done and the plan closed, the chain ends with verdict `plan_closed`; when the frontier holds only hitl nodes the next launch uses `--loop-mode interactive`. An item without a plan behaves exactly as today.

**Blocked by:** 04, 05

**Status:** ready-for-agent

**Spec:** S25, S26, S27, S28

- [ ] New cases in `test-session-loop.sh` with a fake child: plan bound, failed check refuses, plan_closed ends, hitl-only frontier → interactive
- [ ] Existing loop tests pass unchanged (plan-less regression)
- [ ] `docs/context-budget.md` documents the verdict and the refusal
