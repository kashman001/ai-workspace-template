#!/usr/bin/env bash
# File: scripts/build-guide-html.sh
# Purpose: Render docs/workspace-structure.md (the authoritative workspace guide)
#          into a styled, self-contained docs/workspace-structure.html for easy
#          human reading and GitHub Pages publishing. Regenerate whenever the
#          Markdown changes — never hand-edit the HTML. Requires pandoc.
# Usage:   scripts/build-guide-html.sh
# See: README "Using this template"; docs/template-usage.md → "Reference"
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

SRC="docs/workspace-structure.md"
OUT="docs/workspace-structure.html"

if ! command -v pandoc >/dev/null 2>&1; then
  echo "  ✗ pandoc not found — install it (e.g. 'brew install pandoc') to build the guide HTML" >&2
  echo "Status: guide-html=skipped"
  exit 0
fi
if [ ! -f "$SRC" ]; then
  echo "  ✗ $SRC missing" >&2
  echo "Status: guide-html=error"
  exit 1
fi

TEMPLATE="$(mktemp "${TMPDIR:-/tmp}/wsguide-template.XXXXXX")"
trap 'rm -f "$TEMPLATE"' EXIT

# Hash of the Markdown source, embedded in the HTML <head> below so
# check-workspace-structure.sh can flag when the guide needs regenerating.
SRC_SHA="$( { shasum "$SRC" 2>/dev/null || sha1sum "$SRC"; } | awk '{print $1}')"

# The page sits on the shared HTML kit (docs/kit/AUTHORING.md, TADR-0015):
# kit skeleton, body.doc, one <section> per heading, no page-level CSS.
cat > "$TEMPLATE" <<HTML
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Dev-AI Workspace Structure — ai-workspace-template guide</title>
<link rel="stylesheet" href="kit/kit.css">
<script src="kit/kit.js" defer></script>
<!-- source-md-sha1: $SRC_SHA -->
</head>
<body class="doc">
<main>
<p class="note">Rendered workspace guide · generated from <code>docs/workspace-structure.md</code> by
<code>scripts/build-guide-html.sh</code> — do not hand-edit; edit the Markdown and regenerate.
· <a href="https://github.com/kashman001/ai-workspace-template/blob/main/docs/workspace-structure.md">Markdown source</a>
· <a href="setup-guide.html">Setup guide</a></p>
\$body\$
</main>
</body>
</html>
HTML

# --section-divs gives the kit its <section>s; highlighting off keeps pandoc's
# token CSS out. Pandoc writes style= on aligned table cells and column widths;
# the kit styles tables itself, so those attributes are stripped.
# --syntax-highlighting arrived in pandoc 3.8; older pandoc spells it --no-highlight.
HL="--syntax-highlighting=none"
pandoc --help 2>/dev/null | grep -q -- '--syntax-highlighting' || HL="--no-highlight"
pandoc "$SRC" \
  --from gfm \
  --template "$TEMPLATE" \
  --section-divs \
  "$HL" \
  | sed -E 's/ style="[^"]*"//g' > "$OUT"
rc=${PIPESTATUS[0]}

if [ "$rc" -ne 0 ]; then
  echo "  ✗ pandoc failed (rc=$rc)" >&2
  echo "Status: guide-html=error"
  exit 1
fi

echo "  ✓ wrote $OUT from $SRC ($(wc -l < "$OUT" | tr -d ' ') lines)"
echo "Status: guide-html=ok"
exit 0
