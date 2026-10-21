#!/usr/bin/env bash
# File: scripts/tests/test-build-guide-html.sh
# Purpose: build-guide-html.sh emits a page on the HTML kit (docs/kit/AUTHORING.md):
#          kit link + script, body.doc, <main>, one <section> per heading, no
#          <style> and no style= (pandoc adds these for aligned tables and
#          highlighted code, so the fixture has both), the source-md-sha1 head
#          comment that check-workspace-structure.sh reads, and links that
#          docs/kit/check-links.sh resolves. Skips when pandoc is absent.
set -u
SRC_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); echo "  ok: $1"; }
bad() { FAIL=$((FAIL+1)); echo "  FAIL: $1" >&2; }
assert_eq()       { [ "$2" = "$3" ] && ok "$1" || bad "$1 (want [$3] got [$2])"; }
assert_contains() { case "$2" in *"$3"*) ok "$1" ;; *) bad "$1 (no [$3] in output)" ;; esac; }

if ! command -v pandoc >/dev/null 2>&1; then
  echo "SKIP: pandoc not installed"; echo "PASS=0 FAIL=0"; exit 0
fi

W="$TMP/w"
mkdir -p "$W/scripts" "$W/docs"
cp "$SRC_ROOT/scripts/build-guide-html.sh" "$W/scripts/"
cp -R "$SRC_ROOT/docs/kit" "$W/docs/kit"
: > "$W/docs/setup-guide.html"
cat > "$W/docs/workspace-structure.md" <<'MD'
# Guide

Intro paragraph.

## Contents

- [Layout](#layout)

## Layout

| Path | Count |
|:-----|------:|
| `docs/` | 3 |

### Sub-topic

```bash
echo "hi" && ls
```
MD

echo "G1: build succeeds"
out="$(bash "$W/scripts/build-guide-html.sh" 2>&1)"; rc=$?
assert_eq "G1 exit 0" "$rc" "0"
assert_contains "G1 status ok" "$out" "Status: guide-html=ok"
html="$(cat "$W/docs/workspace-structure.html" 2>/dev/null)"

echo "G2: kit skeleton"
assert_contains "G2 kit.css" "$html" '<link rel="stylesheet" href="kit/kit.css">'
assert_contains "G2 kit.js"  "$html" '<script src="kit/kit.js" defer></script>'
assert_contains "G2 body.doc" "$html" '<body class="doc">'
assert_contains "G2 main"    "$html" '<main>'
assert_contains "G2 section per h2" "$html" '<section id="layout"'

echo "G3: no page-level design (AUTHORING.md greps)"
assert_eq "G3 no style/fill/stroke/font attrs" \
  "$(grep -cE '<style|style=|fill=|stroke=|font-[a-z]+=|<defs' "$W/docs/workspace-structure.html")" "0"
assert_eq "G3 only the kit script" "$(grep -c '<script' "$W/docs/workspace-structure.html")" "1"
assert_eq "G3 only kit classes (no pandoc level/language classes)" \
  "$(grep -o 'class="[^"]*"' "$W/docs/workspace-structure.html" | grep -vcE '^class="(doc|note)"$')" "0"

echo "G4: freshness hash kept"
sha="$( { shasum "$W/docs/workspace-structure.md" 2>/dev/null || sha1sum "$W/docs/workspace-structure.md"; } | awk '{print $1}')"
assert_contains "G4 source-md-sha1" "$html" "<!-- source-md-sha1: $sha -->"

echo "G5: links resolve"
bash "$W/docs/kit/check-links.sh" "$W/docs/workspace-structure.html" >/dev/null 2>&1; rc=$?
assert_eq "G5 check-links exit 0" "$rc" "0"

echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ]
