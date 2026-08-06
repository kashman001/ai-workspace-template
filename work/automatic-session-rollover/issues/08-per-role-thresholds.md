# 08 — Do per-role WARN/STOP thresholds earn their keep?

Type: grilling (HITL — needs the user live)
Status: open
Blocked by: none
Map: ../map.md

## Question

Research §2 kept one threshold pair (120K/150K in `context-budget.env`)
for all roles, flagging per-role overrides (e.g. reviewer children vs
implementer children vs primary) as "possible later but YAGNI now". The
empirical data (§1, `subagent-rollover-stats.md`) shows real children
reaching ~141.8K — inside WARN territory under the shared pair.

Decide with the user:

- What evidence would justify per-role thresholds (e.g. systematic
  role-correlated degradation before 120K, or chronic false-positive WARNs
  for short-lived roles)? Does current data meet it?
- If yes: config shape — noting the per-work-item
  `work/<proj>/context-budget.env` override already exists, so the
  question is specifically *role* keying, not per-context tuning.
- If no: record the YAGNI ruling with its revisit trigger, so the question
  stops recurring in handoffs.
