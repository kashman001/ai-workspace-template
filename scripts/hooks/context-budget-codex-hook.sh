#!/usr/bin/env bash
# File: scripts/hooks/context-budget-codex-hook.sh
# Purpose: Codex CLI UserPromptSubmit hook (.codex/config.toml; trust hash re-prompts on edit) — shim onto the dispatcher.
exec "$(cd "$(dirname "$0")" && pwd)/context-budget-hook.sh" codex UserPromptSubmit
