#!/usr/bin/env bash
# File: scripts/hooks/context-budget-copilot-vscode-hook.sh
# Purpose: VS Code Copilot agent-mode hooks (.github/hooks/context-budget-vscode.json: SessionStart | Stop) — shim onto the dispatcher.
exec "$(cd "$(dirname "$0")" && pwd)/context-budget-hook.sh" copilot-vscode "${1:-}"
