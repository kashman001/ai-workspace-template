#!/usr/bin/env bash
# File: scripts/hooks/context-budget-gemini-hook.sh
# Purpose: Gemini CLI BeforeAgent hook (.gemini/settings.json; JSON-only stdout) — shim onto the dispatcher.
exec "$(cd "$(dirname "$0")" && pwd)/context-budget-hook.sh" gemini BeforeAgent
