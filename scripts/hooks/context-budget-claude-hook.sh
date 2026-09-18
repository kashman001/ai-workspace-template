#!/usr/bin/env bash
# File: scripts/hooks/context-budget-claude-hook.sh
# Purpose: Claude Code PostToolUse hook (.claude/settings.json) — shim onto the dispatcher; see context-budget-adapters.conf.
exec "$(cd "$(dirname "$0")" && pwd)/context-budget-hook.sh" claude PostToolUse
