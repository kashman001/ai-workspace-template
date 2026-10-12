#!/usr/bin/env bash
# File: scripts/hooks/context-budget-antigravity-hook.sh
# Purpose: Antigravity PreInvocation hook (.agents/hooks.json; JSON-only stdout; registers the session) — shim onto the dispatcher.
exec "$(cd "$(dirname "$0")" && pwd)/context-budget-hook.sh" antigravity PreInvocation
