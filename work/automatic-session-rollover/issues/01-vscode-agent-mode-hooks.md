# 01 — Verify VS Code agent-mode hooks + `copilot_vscode_measure` on a Copilot-licensed machine

Type: task
Status: open

## Why spun out

Everything else in the detection scope was verified live on this machine
(smoke tests in `../smoke-test-opencode.md` and `../smoke-test-copilot.md`);
this piece can't be: it needs a VS Code install with a licensed Copilot
extension, which the origin machine doesn't have. VS Code agent-mode hooks
also shipped only in v1.109 as **Preview**, so the contract may shift before
verification. Decision provenance: `../decisions.md` → "Detection + runtime
scope after smoke tests (session 3)"; ADR-0004.

## What to verify

1. **Agent-mode hooks fire.** Wire a minimal hook per the v1.109 agent-mode
   hooks contract (see `../vendor-hooks-research.md` → VS Code section) and
   confirm a WARN/STOP push can reach an agent-mode session in-band —
   the equivalent of the copilot CLI `sessionStart` `additionalContext` /
   `agentStop` block-`reason` channels confirmed in `../smoke-test-copilot.md`.
2. **`copilot_vscode_measure` is exact.** The adapter branch in
   `scripts/context-budget.sh` (chatSessions `promptTokens` grep — see
   `docs/context-budget.md` per-runtime table, "Copilot VS Code" row) is
   plausible but unverified on current builds; compare its output against the
   live session UI the way copilot-cli was verified (73.0k exact match).

## Done when

- Both checks pass on a Copilot-licensed machine (note VS Code + extension
  versions in this file), or findings recorded here and the adapter/docs
  amended to match reality.
