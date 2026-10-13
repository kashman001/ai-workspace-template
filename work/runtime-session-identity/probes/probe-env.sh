#!/usr/bin/env bash
# Purpose: run BY THE AGENT inside an IDE/app session (in the probe clone) to
#          record what session identity it can see. Appends to probe-out/env.log.
# Usage:   ./probe-env.sh <runtime: claude|antigravity|codex|copilot-cli|copilot-vscode> <label>
rt="${1:?runtime}"; label="${2:-unlabelled}"
cd "$(dirname "$0")"; mkdir -p probe-out
{
  echo "=== $(date '+%F %T') runtime=$rt label=$label pwd=$PWD"
  echo "--- id-ish env"; env | grep -iE 'claude|antigravity|codex|copilot|gemini|vscode|session|thread|conversation' | grep -v '^PATH=' | sort
  echo "--- process ancestry"; p=$$
  while [ "${p:-0}" -gt 1 ]; do ps -o pid=,ppid=,comm= -p "$p"; p=$(ps -o ppid= -p "$p" | tr -d ' '); done
  echo "--- register"; scripts/context-budget.sh register --runtime "$rt" 2>&1
  echo "--- check"; scripts/context-budget.sh check 2>&1
  echo "--- registry records"; for f in .context-budget/sessions/*.json; do echo "$f"; jq -c '{runtime,session_id,artifact,pid}' "$f"; done
} >> probe-out/env.log 2>&1
tail -40 probe-out/env.log
