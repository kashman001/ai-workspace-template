#!/usr/bin/env bash
# File: scripts/hooks/context-budget-codex-hook.sh
# Purpose: Codex hooks (.codex/config.toml: UserPromptSubmit, the default | SessionStart, registration only; trust hash re-prompts on edit) — shim onto the dispatcher.
exec "$(cd "$(dirname "$0")" && pwd)/context-budget-hook.sh" codex "${1:-UserPromptSubmit}"
