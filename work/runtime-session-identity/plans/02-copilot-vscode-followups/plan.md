---
plan: 02-copilot-vscode-followups
status: open
replan: structural
default_tier: standard
---

# Plan 02 — Copilot VS Code follow-ups

## Goal

Close the three findings from the s10 Copilot VS Code re-probe: (1) token count is a size
estimate (~30% low) because `prompt_tokens` is not read; (2) four hook sets fire per Copilot
event, two of them Claude Code's; (3) two registry records per chat. Fix 1 now; decide 2 and
3 with the user, then deliver and re-probe live.

## Not yet specified

The delivery for findings 2 and 3, until node 05 is answered.

## Out of scope

Other surfaces' rows (already PASS); Antigravity IDE/app and Codex desktop (backlog L86).

## Replans

<!-- plan:begin board -->
| Wave | Node | Kind | Tier | Status |
|---|---|---|---|---|
| 1 | 01-fix-copilot-vscode-exact-tokens | work | standard | done |
| 1 | 02-investigate-hook-fanout | work | standard | done |
| 1 | 03-investigate-duplicate-records | work | standard | done |
| 1 | 04-reconcile-w1 | reconcile | frontier | done |
| 2 | 05-approve-decisions | hitl | frontier | todo |
| 2 | 06-reconcile-w2 | reconcile | frontier | todo |
Frontier: 05-approve-decisions. Remaining: 2 of 6. Sessions used: 1.
<!-- plan:end board -->
