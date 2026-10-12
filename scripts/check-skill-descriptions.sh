#!/usr/bin/env bash
# File: scripts/check-skill-descriptions.sh
# Purpose: Sum the bytes of the `description:` frontmatter of every
#          model-invoked skills/*/SKILL.md (one without
#          `disable-model-invocation: true`), print them largest first plus
#          the total, and exit 1 when the total exceeds SKILL_DESC_MAX_BYTES.
# See: tested by scripts/tests/test-check-skill-descriptions.sh
set -uo pipefail

ROOT="${CHECK_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
cd "$ROOT" || exit 2

# Every model-invoked description is text the runtime weighs on every turn
# (Claude Code lists them in the system prompt; Codex reads them through
# agents/openai.yaml); this bounds their sum. Over it, repair in this order:
# make a procedure skill user-invoked (disable-model-invocation + openai.yaml
# + a command), then tighten descriptions; raise this number only with the
# reason stated in the commit. 7500 is a ratchet: the total after the trim
# (7,303) rounded up to the next 500, so ~200 bytes of headroom make a new
# model-invoked skill force a trim or a user-invoke swap.
SKILL_DESC_MAX_BYTES="${SKILL_DESC_MAX_BYTES:-7500}"

rows=""; total=0; n=0
for f in skills/*/SKILL.md; do
  [ -f "$f" ] || continue
  name="$(basename "$(dirname "$f")")"
  # awk prints the description's byte count, or "SKIP" for a user-invoked skill.
  b="$(LC_ALL=C awk '
    { sub(/\r$/, "") }
    /^---[ \t]*$/ { fm++; if (fm == 2) exit; next }
    fm != 1 { next }
    folded && /^[ \t]+[^ \t]/ { t = $0; gsub(/^[ \t]+|[ \t]+$/, "", t); d = (d == "" ? t : d " " t); next }
    folded && /^[ \t]*$/ { next }
    { folded = 0 }
    /^disable-model-invocation:[ \t]*true/ { skip = 1 }
    /^description:/ {
      v = $0; sub(/^description:[ \t]*/, "", v); gsub(/[ \t]+$/, "", v)
      if (v ~ /^[>|][-+]?$/) { folded = 1; d = "" } else d = v
    }
    END { if (skip) print "SKIP"; else print length(d) }
  ' "$f")"
  [ "$b" = "SKIP" ] && continue
  rows="$rows$(printf '%6d  %s' "$b" "$name")
"
  total=$((total + b)); n=$((n + 1))
done

printf '%s' "$rows" | sort -k1,1nr -k2,2
echo
echo "total: $total bytes over $n model-invoked skills (budget $SKILL_DESC_MAX_BYTES)"
if [ "$total" -gt "$SKILL_DESC_MAX_BYTES" ]; then
  largest="$(printf '%s' "$rows" | sort -k1,1nr -k2,2 | head -1 | awk '{print $2}')"
  echo "OVER BUDGET: $total bytes > $SKILL_DESC_MAX_BYTES; largest: $largest" >&2
  exit 1
fi
exit 0
