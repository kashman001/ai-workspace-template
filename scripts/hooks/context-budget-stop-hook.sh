#!/usr/bin/env bash
# File: scripts/hooks/context-budget-stop-hook.sh
# Purpose: turn-end exit hook for the Claude-shaped runtimes, `<runtime>` on argv (claude: .claude/settings.json Stop; codex: .codex/config.toml [[hooks.Stop]]) — shim onto the dispatcher.
exec "$(cd "$(dirname "$0")" && pwd)/context-budget-hook.sh" "${1:-}" Stop
