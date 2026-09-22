#!/usr/bin/env bash
# File: scripts/hooks/context-budget-copilot-hook.sh
# Purpose: Copilot CLI hooks (.github/hooks/context-budget.json: sessionStart | agentStop) — shim onto the dispatcher.
exec "$(cd "$(dirname "$0")" && pwd)/context-budget-hook.sh" copilot "${1:-}"
