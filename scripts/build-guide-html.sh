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

HEADER="$(mktemp "${TMPDIR:-/tmp}/wsguide-header.XXXXXX")"
BANNER="$(mktemp "${TMPDIR:-/tmp}/wsguide-banner.XXXXXX")"
trap 'rm -f "$HEADER" "$BANNER"' EXIT

# Hash of the Markdown source, embedded in the HTML <head> below so
# check-workspace-structure.sh can flag when the guide needs regenerating.
SRC_SHA="$( { shasum "$SRC" 2>/dev/null || sha1sum "$SRC"; } | awk '{print $1}')"

# Visual identity reused from docs/setup-guide.html (same palette + typography),
# adapted for a long-form document: prose, tables, code blocks, and the doc's
# own "Contents" list (no separate pandoc TOC — the Markdown already has one).
cat > "$HEADER" <<'CSS'
<style>
  :root{
    --bg:#0f1222; --panel:#171a2e; --panel-2:#1d2138; --ink:#e7e9f3; --muted:#a3a8c3;
    --line:#2b3052; --accent:#7c83ff; --accent-2:#22d3ee; --green:#34d399; --amber:#fbbf24;
    --code:#0b0e1a; --radius:14px; --maxw:980px;
    --mono:ui-monospace,SFMono-Regular,Menlo,Consolas,"Liberation Mono",monospace;
    --sans:ui-sans-serif,system-ui,-apple-system,"Segoe UI",Roboto,Helvetica,Arial,sans-serif;
  }
  *{box-sizing:border-box}
  html{scroll-behavior:smooth}
  body{margin:0 auto;max-width:var(--maxw);padding:0 22px 90px;
    background:linear-gradient(180deg,#0c0f1d,#0f1222 260px);color:var(--ink);
    font-family:var(--sans);line-height:1.65;font-size:16px}
  a{color:var(--accent);text-decoration:none}
  a:hover{text-decoration:underline}
  h1{font-size:38px;line-height:1.12;letter-spacing:-.02em;margin:48px 0 14px}
  h1:first-of-type{margin-top:40px}
  h2{font-size:25px;margin:46px 0 12px;letter-spacing:-.01em;scroll-margin-top:18px;
    padding-bottom:7px;border-bottom:1px solid var(--line)}
  h3{font-size:18px;margin:28px 0 8px}
  h4{font-size:15px;margin:20px 0 6px;color:var(--muted);text-transform:uppercase;letter-spacing:.04em}
  p{max-width:76ch}
  ul,ol{padding-left:24px;max-width:76ch}
  li{margin:5px 0}
  strong{color:#fff}
  pre{background:var(--code);border:1px solid var(--line);border-radius:12px;padding:16px 18px;
    overflow-x:auto;font-family:var(--mono);font-size:13.5px;line-height:1.55;color:#d7dcff}
  code{font-family:var(--mono);font-size:.92em;background:#20243f;padding:1px 6px;border-radius:6px;color:#cfd4ff}
  pre code{background:none;padding:0;color:inherit;font-size:13.5px}
  table{border-collapse:collapse;width:100%;margin:16px 0;font-size:14.5px}
  th,td{border:1px solid var(--line);padding:9px 12px;text-align:left;vertical-align:top}
  th{background:var(--panel-2);font-weight:600}
  td code,th code{white-space:nowrap}
  blockquote{border-left:4px solid var(--accent);background:var(--panel);
    border-radius:0 12px 12px 0;padding:10px 18px;margin:18px 0;color:var(--ink)}
  blockquote p{margin:6px 0}
  hr{border:none;border-top:1px solid var(--line);margin:42px 0}
  /* The Markdown's own "## Contents" list — render as a navigable card. */
  #contents + ul{background:var(--panel);border:1px solid var(--line);border-radius:var(--radius);
    list-style:none;padding:16px 22px;margin:14px 0 10px;column-gap:32px}
  #contents + ul li{margin:5px 0}
  #contents + ul a{color:var(--muted)}
  #contents + ul a:hover{color:var(--accent)}
  .src-banner{font-family:var(--mono);font-size:12.5px;color:var(--muted);
    background:var(--panel);border:1px solid var(--line);border-radius:10px;
    padding:11px 15px;margin:26px 0 6px;line-height:1.5}
  .src-banner a{color:var(--accent-2)}
</style>
CSS
printf '<!-- source-md-sha1: %s -->\n' "$SRC_SHA" >> "$HEADER"

cat > "$BANNER" <<'HTML'
<div class="src-banner">
  Rendered workspace guide · generated from <code>docs/workspace-structure.md</code> by
  <code>scripts/build-guide-html.sh</code> — do not hand-edit; edit the Markdown and regenerate.
  · <a href="https://github.com/kashman001/ai-workspace-template/blob/main/docs/workspace-structure.md">Markdown source</a>
  · <a href="setup-guide.html">Setup guide</a>
</div>
HTML

pandoc "$SRC" \
  --standalone \
  --from gfm \
  --metadata pagetitle="Dev-AI Workspace Structure — ai-workspace-template guide" \
  --include-in-header "$HEADER" \
  --include-before-body "$BANNER" \
  -o "$OUT"
rc=$?

if [ "$rc" -ne 0 ]; then
  echo "  ✗ pandoc failed (rc=$rc)" >&2
  echo "Status: guide-html=error"
  exit 1
fi

echo "  ✓ wrote $OUT from $SRC ($(wc -l < "$OUT" | tr -d ' ') lines)"
echo "Status: guide-html=ok"
exit 0
