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
- s12 · Copilot VS Code turn 1 is always method=estimate (~30% low, s12: 29,783 vs 42,654): prompt_tokens first appears in the session.usage_checkpoint written at turn end. Options: document it in docs/context-budget.md, or accept. Not a node until the user picks.


## Out of scope

Other surfaces' rows (already PASS); Antigravity IDE/app and Codex desktop (backlog L86).

## Replans

- 2026-10-18 (06-reconcile-w2): added wave 3 (07 harden Claude session hooks, 08 canonical copilot-cli name, 09 reconcile) and wave 4 (10 live re-probe hitl, 11 review since 816a7d9^, 12 reconcile) — node 05 chose A+hardenings and (b). Structural replan.

<!-- plan:begin board -->
| Wave | Node | Kind | Tier | Status |
|---|---|---|---|---|
| 1 | 01-fix-copilot-vscode-exact-tokens | work | standard | done |
| 1 | 02-investigate-hook-fanout | work | standard | done |
| 1 | 03-investigate-duplicate-records | work | standard | done |
| 1 | 04-reconcile-w1 | reconcile | frontier | done |
| 2 | 05-approve-decisions | hitl | frontier | done |
| 2 | 06-reconcile-w2 | reconcile | frontier | done |
| 3 | 07-harden-claude-session-hooks | work | standard | done |
| 3 | 08-canonical-copilot-registry-name | work | standard | done |
| 3 | 09-reconcile-w3 | reconcile | frontier | done |
| 4 | 10-live-reprobe-vscode | hitl | frontier | done |
| 4 | 11-review-plan-02 | work | standard | done |
| 4 | 12-reconcile-w4 | reconcile | frontier | todo |
Frontier: 12-reconcile-w4. Remaining: 1 of 12. Sessions used: 4.
<!-- plan:end board -->
