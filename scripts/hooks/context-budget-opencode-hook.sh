#!/usr/bin/env bash
# File: scripts/hooks/context-budget-opencode-hook.sh
# Purpose: called by .opencode/plugins/context-budget.js: `<sid>` on chat.message, `--exit-check <sid>` on session.idle — shim onto the dispatcher.
[ "${1:-}" = --exit-check ] && exec "$(cd "$(dirname "$0")" && pwd)/context-budget-hook.sh" opencode session.idle "${2:-}"; exec "$(cd "$(dirname "$0")" && pwd)/context-budget-hook.sh" opencode chat.message "${1:-}"
