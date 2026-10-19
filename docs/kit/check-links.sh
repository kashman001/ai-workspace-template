#!/usr/bin/env bash
# check-links.sh — verify every relative href/src on kit pages points at something that exists.
#
# Usage: docs/kit/check-links.sh <page.html>...
#
# For each page, every relative href= / src= value (kit.css, kit.js, sibling pages,
# images, ../ links) must resolve, relative to the page's directory, to an existing
# file or directory. Skipped: http:, https:, mailto:, data:, //host, and pure #anchors.
# A #fragment or ?query is stripped and the rest URL-decoded before resolving.
# Prints `<page>: <href> -> <resolved path>` per broken link and exits 1 if any;
# otherwise prints one OK line per page and exits 0.
set -euo pipefail

if [ "$#" -lt 1 ]; then
  echo "usage: $0 <page.html>..." >&2
  exit 2
fi

python3 - "$@" <<'PY'
import os, re, sys
from html.parser import HTMLParser
from urllib.parse import unquote

SKIP = ("http:", "https:", "mailto:", "data:", "//", "#")

class Links(HTMLParser):
    def __init__(self):
        super().__init__()
        self.vals = []
    def handle_starttag(self, tag, attrs):
        self.vals += [v for k, v in attrs if k in ("href", "src") and v]

broken = 0
for page in sys.argv[1:]:
    p = Links()
    with open(page, encoding="utf-8") as f:
        p.feed(f.read())
    base = os.path.dirname(page) or "."
    bad = 0
    for href in p.vals:
        v = href.strip()
        if not v or v.lower().startswith(SKIP):
            continue
        path = unquote(re.split(r"[#?]", v, maxsplit=1)[0])
        if not path:
            continue
        resolved = os.path.normpath(os.path.join(base, path))
        if not os.path.exists(resolved):
            print(f"{page}: {href} -> {resolved}")
            bad += 1
    if not bad:
        print(f"OK {page}: {len(p.vals)} href/src checked")
    broken += bad
sys.exit(1 if broken else 0)
PY
