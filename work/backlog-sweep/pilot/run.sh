#!/usr/bin/env bash
# Usage: run.sh <skill> <task> <arm>   (arm: none | dummy | skill)
# Runs ONE fresh headless claude session in a throwaway temp dir (so no workspace
# CLAUDE.md leaks in) and saves the answer under pilot/runs/<skill>-<task>-<arm>.*
# Skill/dummy text is appended to the system prompt; tools are disabled so the run
# is exactly one model turn (this CLI has no --max-turns).
set -euo pipefail
[ $# -eq 3 ] || { echo "usage: $0 <skill> <task> <arm: none|dummy|skill>" >&2; exit 64; }
skill=$1 task=$2 arm=$3
here=$(cd "$(dirname "$0")" && pwd)
root=$(cd "$here/../../.." && pwd)
model=${PILOT_MODEL:-claude-sonnet-5-5}
scratch=${PILOT_SCRATCH:-${TMPDIR:-/tmp}}
taskfile=$here/tasks/$skill/$task.md
skillfile=$root/skills/$skill/SKILL.md
[ -f "$taskfile" ] || { echo "no task file $taskfile" >&2; exit 66; }
[ -f "$skillfile" ] || { echo "no skill file $skillfile" >&2; exit 66; }
mkdir -p "$here/runs"
# skill body = SKILL.md minus the YAML frontmatter
body=$(awk 'BEGIN{n=0} /^---$/ && n<2 {n++; next} n>=2 {print}' "$skillfile")
case $arm in
  none) extra="" ;;
  skill) extra=$body ;;
  dummy) # same word count as the skill body, from unrelated filler
    words=$(printf '%s' "$body" | wc -w | tr -d ' ')
    extra=$(for i in $(seq 1 $(( words / 150 + 2 ))); do cat "$here/dummy.txt"; done | tr -s ' \n' '\n\n' | head -n "$words" | tr '\n' ' ') ;;
  *) echo "bad arm: $arm" >&2; exit 64 ;;
esac
work=$(mktemp -d "$scratch/pilot-XXXXXX")
out=$here/runs/$skill-$task-$arm
args=(-p --model "$model" --output-format json --tools "" --no-session-persistence
      --disable-slash-commands --setting-sources "" --max-budget-usd "${PILOT_BUDGET:-0.50}")
[ -n "$extra" ] && args+=(--append-system-prompt "$extra")
start=$(date +%s)
( cd "$work" && claude "${args[@]}" < "$taskfile" > "$out.json" 2> "$out.err" ) || echo "claude exited non-zero; see $out.err" >&2
end=$(date +%s)
jq -r '.result // empty' "$out.json" > "$out.txt" 2>/dev/null || true
echo "$skill $task $arm wall=$((end-start))s cost=$(jq -r '.total_cost_usd // "n/a"' "$out.json" 2>/dev/null) words_in_extra=$(printf '%s' "$extra" | wc -w | tr -d ' ') out=$out.txt"
rm -rf "$work"
