#!/usr/bin/env bash
# render-check.sh — screenshot every figure on a kit page, isolated, at two widths and two themes.
#
# Usage: docs/kit/render-check.sh <page.html> [out-dir]
#   out-dir defaults to ${TMPDIR:-/tmp}/render-check/<page-stem>/ (shots are not committed)
#
# Targets, in document order: each <figure>, plus each <svg class="diagram"> and
# <pre class="mermaid"> that is not inside a figure. For each target it writes
#   <stem>-fig<N>-<1280|390>-<light|dark>.png
# and prints the paths. N is 1-based. Deck figures are shot on their own slide (#N hash).
#
# How: a temp copy of the page (.rc-<stem>-fig<N>.html next to the page, so kit/
# paths resolve; deleted on exit) marks the target and hides everything that neither holds nor sits
# in it. A first headless-Chrome pass (--dump-dom) measures where the target sits; the
# second pass screenshots (window grown if the target runs past it) and crops to the
# target plus 24px (sips on macOS, else ImageMagick magick/convert, else python3 + Pillow).
# Each pass loads the copy in an iframe of the exact width inside a
# wrapper page (.rc-<stem>-frame.html), because headless Chrome won't lay out a window
# narrower than 500px: --window-size=390 alone gives a 500px layout cropped to 390. Light = --blink-settings=preferredColorScheme=1, dark =
# preferredColorScheme=0; both with --force-prefers-reduced-motion. Mermaid comes from a CDN,
# so this needs network; --virtual-time-budget gives it time to render.
#
# Limits: targets are found by regex on the source (no nested <figure>); other mermaid blocks
# on the page are disabled in the copy; deck slides are laid out static (top-aligned, not
# centered) so the shot fits the figure, not the viewport.
#
# Chrome lookup: $CHROME if set (must be executable), else the macOS Google Chrome app, else the
# first of google-chrome, google-chrome-stable, chromium, chromium-browser on PATH. Run as root
# (e.g. in a container), Chrome gets --no-sandbox.
set -euo pipefail

mac_chrome="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
names="google-chrome google-chrome-stable chromium chromium-browser"
if [ -n "${CHROME:-}" ]; then
  [ -x "$CHROME" ] || command -v "$CHROME" >/dev/null || { echo "CHROME=$CHROME is not an executable" >&2; exit 2; }
elif [ -x "$mac_chrome" ]; then CHROME=$mac_chrome
else
  for c in $names; do command -v "$c" >/dev/null && { CHROME=$c; break; }; done
  [ -n "${CHROME:-}" ] || { echo "Chrome not found: tried \$CHROME, $mac_chrome, and $names on PATH." \
    "Install one (e.g. apt install chromium) or set CHROME=/path/to/chrome." >&2; exit 2; }
fi
if command -v sips >/dev/null; then crop() { sips -c "$2" "$3" --cropOffset "$4" 0 "$1" >/dev/null; }
elif command -v magick >/dev/null; then crop() { magick "$1" -crop "${3}x${2}+0+$4" +repage "$1"; }
elif command -v convert >/dev/null; then crop() { convert "$1" -crop "${3}x${2}+0+$4" +repage "$1"; }
elif python3 -c 'import PIL' 2>/dev/null; then crop() { # <png> <height> <width> <y>
  python3 -c 'import sys; from PIL import Image; f,h,w,y=sys.argv[1],*map(int,sys.argv[2:])
Image.open(f).crop((0,y,w,y+h)).save(f)' "$@"; }
else echo "no image cropper: need sips, ImageMagick (magick/convert), or python3 Pillow (e.g. apt install imagemagick)" >&2; exit 2
fi
page=${1:?usage: render-check.sh <page.html> [out-dir]}
page=$(cd "$(dirname "$page")" && pwd)/$(basename "$page")
stem=$(basename "$page" .html)
out=${2:-${TMPDIR:-/tmp}/render-check/$stem}
mkdir -p "$out"; out=$(cd "$out" && pwd)
dir=$(dirname "$page")
list=$(mktemp)
trap 'rm -f "$list" "$dir"/.rc-"$stem"-fig*.html "$dir"/.rc-"$stem"-frame.html' EXIT

# Write one isolated copy per target; print "<index>\t<file>\t<hash>".
python3 - "$page" "$dir" "$stem" > "$list" <<'PY'
import re, sys, os
src = open(sys.argv[1], encoding='utf-8').read()
tmp, stem = sys.argv[2], sys.argv[3]
tok = re.compile(r'<figure\b|</figure>|<svg\b[^>]*class="[^"]*\bdiagram\b|<pre\b[^>]*class="[^"]*\bmermaid\b')
targets, depth = [], 0
for m in tok.finditer(src):
    t = m.group(0)
    if t == '</figure>': depth -= 1; continue
    if t.startswith('<figure'):
        if depth == 0: targets.append(m.start())
        depth += 1
    elif depth == 0:
        targets.append(m.start())
css = ('<style id="rc">'
  'body *:not(:has([data-rc])):not([data-rc]):not([data-rc] *):not(svg[width="0"]):not(svg[width="0"] *){display:none!important}'
  'body.deck{height:auto!important;overflow:visible!important;display:block!important}'
  'body.deck>main{position:static!important}'
  'body.deck .slide.current{position:static!important;justify-content:flex-start!important}'
  '</style>')
js = ('<script>addEventListener("load",()=>setTimeout(()=>{const r=document.querySelector("[data-rc]")'
      '.getBoundingClientRect();document.body.dataset.rch=[Math.floor(r.top+scrollY),Math.ceil(r.bottom+scrollY),'
      'innerHeight].join(" ");parent!==window&&parent.postMessage(document.body.dataset.rch,"*")},4000))</script>')
for n, pos in enumerate(targets, 1):
    end = src.index('>', pos)
    tag = src[pos:end]
    close = {'<f': '</figure>', '<p': '</pre>', '<s': '</svg>'}[tag[:2]]
    stop = src.index(close, pos)
    # keep only the target's mermaid block live, so a hidden one cannot break the run
    off = lambda t: re.sub(r'(<pre\b[^>]*class="[^"]*)\bmermaid\b', r'\1mermaid-off', t)
    s = off(src[:pos]) + tag + ' data-rc' + src[end:stop] + off(src[stop:])
    s = s.replace('</head>', css + '</head>', 1).replace('</body>', js + '</body>', 1)
    slide = len(re.findall(r'<section\b[^>]*class="[^"]*\bslide\b', src[:pos]))
    f = os.path.join(tmp, f'.rc-{stem}-fig{n}.html')
    open(f, 'w', encoding='utf-8').write(s)
    print(f'{n}\t{f}\t{"#%d" % slide if slide else ""}')
PY
[ -s "$list" ] || { echo "no figures found in $page" >&2; exit 1; }

frame="$dir/.rc-$stem-frame.html"
shot() { # <file-url> <width> <height> <scheme> [screenshot-path]
  printf '<!doctype html><body style="margin:0"><iframe src="%s" width="%s" height="%s" style="border:0;display:block"></iframe><script>addEventListener("message",e=>document.body.dataset.rch=e.data)</script>' \
    "$1" "$2" "$3" > "$frame"
  local win=$(( $2 > 500 ? $2 : 500 ))
  local flags=(--headless=new --disable-gpu --hide-scrollbars --force-prefers-reduced-motion
    --allow-file-access-from-files
    --blink-settings=preferredColorScheme="$4" --window-size="$win,$3" --virtual-time-budget=15000)
  [ "$(id -u)" = 0 ] && flags+=(--no-sandbox)
  if [ -n "${5:-}" ]; then "$CHROME" "${flags[@]}" --screenshot="$5" "file://$frame" >/dev/null 2>&1
  else "$CHROME" "${flags[@]}" --dump-dom "file://$frame" 2>/dev/null; fi
}

while IFS=$'\t' read -r n file hash; do
  url="file://$file$hash"
  for w in 1280 390; do
    h0=800; [ "$w" = 390 ] && h0=844
    # measure: target top, bottom, viewport height (window height minus browser chrome)
    read -r top bot vh < <(shot "$url" "$w" "$h0" 1 | sed -n 's/.*data-rch="\([0-9 ]*\)".*/\1/p')
    [ -n "${vh:-}" ] || { echo "measure failed: $url at $w" >&2; continue; }
    pad=24; y=$(( top > pad ? top - pad : 0 )); ch=$(( bot + pad - y ))
    h=$(( bot + pad > vh ? h0 + bot + pad - vh : h0 ))
    for theme in light dark; do
      scheme=1; [ "$theme" = dark ] && scheme=0
      f="$out/$stem-fig$n-$w-$theme.png"
      shot "$url" "$w" "$h" "$scheme" "$f"
      crop "$f" "$ch" "$w" "$y"
      echo "$f"
    done
  done
done < "$list"
