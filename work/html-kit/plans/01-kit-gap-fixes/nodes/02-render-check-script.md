---
id: 02-render-check-script
title: Render-check script: screenshot every figure at 1280/390, light/dark
status: done
kind: work
wave: 1
blocked_by: []
sessions: [5]
---

## Goal

Write `prototype/render-check.sh <page.html> [out-dir]`: headless Chrome
(`/Applications/Google Chrome.app`), for each `figure` (and each
`svg.diagram` / `pre.mermaid` outside a figure) on the page, a screenshot at
1280 and 390 wide, light and dark, reduced motion. Flags from `handoff.md`
s3: `--blink-settings=preferredColorScheme=1` for light (default renders dark
on this Mac), `--force-prefers-reduced-motion`. No Pillow; use `sips` if
resizing. Approach is free — e.g. a temp copy of the page that hides everything but
one figure, shot with Chrome `--screenshot`, or a full-page shot cropped
with `sips`. For
decks, one screenshot per slide holding a figure. Output file names say page,
figure index, width, theme.

## Acceptance

- [x] script exists, runs on `prototype/setup-guide.html` and `prototype/where-ai-actually-helps.html`
- [x] each run writes 4 shots per figure (1280/390 × light/dark), names list them
- [x] dark and light shots actually differ (checked by eye on one figure)
- [x] usage documented in a header comment

## Log
- s5 · started, tier standard
- s5-b · wrote work/html-kit/prototype/render-check.sh (temp copy per target hides all but it, deck slide via #N hash, dump-dom measure, Chrome screenshot, sips crop); light=preferredColorScheme=1, dark=0
- s5-b · ran on both pages: 8 shots each (2 figures x 1280/390 x light/dark) in work/html-kit/prototype/shots/check/{setup-guide,where-ai-actually-helps}/; viewed setup-guide fig1 light + fig2-390 dark and deck fig2-390 dark: isolated, mermaid rendered, themes differ; no .rc-* temp files left
- s5-b · finding (not fixed, page/kit owned elsewhere): deck backup slide figure (where-ai-actually-helps fig2) overflows at 390 wide, in the original page too; setup-guide fig2 at 390 shows only the visible part of its horizontal-scroll box
- s5-b · on disk: prototype/render-check.sh (uncommitted) + 16 PNGs under prototype/shots/check/; not on disk: no kit/page/AUTHORING edits, nothing committed
- s5 · done
