#!/usr/bin/env bash
# Purpose: build a scratch clone of this workspace for the IDE/app probes, with
#          every context-budget hook wrapped so its raw stdin payload, args and
#          id-ish env vars are logged to <clone>/probe-out/. Never probe in WS.
# Usage:   work/runtime-session-identity/probes/make-ide-probe-clone.sh [dest]
set -euo pipefail
WS="$(cd "$(dirname "$0")/../../.." && pwd)"
DEST="${1:-$HOME/Developer/experiments/ws-identity-probe}"
[ -e "$DEST" ] && { echo "exists: $DEST (remove it first)" >&2; exit 1; }
git clone -q "$WS" "$DEST"
cp "$WS/work/runtime-session-identity/probes/probe-env.sh" "$DEST/probe-env.sh"
for h in codex copilot copilot-vscode gemini stop; do
  f="$DEST/scripts/hooks/context-budget-$h-hook.sh"
  mv "$f" "$f.orig"
  cat > "$f" <<'WRAP'
#!/usr/bin/env bash
in=$(cat); d="$(cd "$(dirname "$0")/../.." && pwd)/probe-out"; mkdir -p "$d"
{ echo "=== $(date '+%F %T') args: $*"; env | grep -iE 'codex|copilot|gemini|vscode|session|thread' | grep -v '^PATH=' | sort
  echo "--- payload"; printf '%s\n' "$in"; } >> "$d/hook-$(basename "$0" .sh).log"
printf '%s' "$in" | "$0.orig" "$@"
WRAP
  chmod +x "$f"
done
echo "probe clone ready: $DEST"
