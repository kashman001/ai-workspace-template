---
plan: 01-open-cards
status: open
replan: local
default_tier: standard
---

# Plan 01 — Close the open backlog cards

## Goal

Close L85, L95, L96 and L98 with verified, test-first changes, run in parallel subagents at the tier each node names (frontier = opus, standard = sonnet, cheap = haiku via `plan-tiers.env`); then carry L86 through the user's probe run. Success criteria: `work/backlog-sweep/README.md`.

## Not yet specified

## Out of scope

- L97 — its card defers it until `work/concurrent-sessions/` settles R1.
- R11/R12 (study-feature skill) — only on the user's explicit yes.
- Pushing to origin — the user's call.

## Replans

<!-- plan:begin board -->
| Wave | Node | Kind | Tier | Status |
|---|---|---|---|---|
| 1 | 01-l85-skip-template-only-suites | work | cheap | doing |
| 1 | 02-l95-dispatch-contract | work | standard | doing |
| 1 | 03-l96-usage-limit-watchdog | work | standard | doing |
| 1 | 04-l98-pilot-design | work | standard | doing |
| 1 | 05-reconcile-w1 | reconcile | frontier | todo |
| 2 | 06-l98-pilot-run | work | standard | todo |
| 2 | 07-reconcile-w2 | reconcile | frontier | todo |
| 3 | 08-review | work | frontier | todo |
| 3 | 09-reconcile-w3 | reconcile | frontier | todo |
| 4 | 10-l86-user-probes | hitl | frontier | todo |
| 4 | 11-reconcile-w4 | reconcile | frontier | todo |
| 5 | 12-l86-probe-writeup | work | standard | todo |
| 5 | 13-reconcile-w5 | reconcile | frontier | todo |
Frontier: none (01-l85-skip-template-only-suites doing, 02-l95-dispatch-contract doing, 03-l96-usage-limit-watchdog doing, 04-l98-pilot-design doing). Remaining: 13 of 13. Sessions used: 1.
<!-- plan:end board -->
