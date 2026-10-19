---
id: 05-setup-guide-rebuild
title: Fresh agent rebuilds docs/setup-guide.html from AUTHORING.md alone
status: done
kind: work
wave: 2
blocked_by: [04-reconcile-w1]
sessions: [5]
---

## Goal

A fresh subagent, given only `prototype/AUTHORING.md` and the original
`docs/setup-guide.html` (content source), rebuilds it to
`prototype/setup-guide.html` (kit unseen), then runs the render check and
fixes its own diagrams until they pass by its eye.

## Acceptance

- [x] page rebuilt, grep checks print 0
- [x] render-check shots written to `prototype/shots/s5/setup/`
- [x] size in bytes reported; deviations from the rule listed

## Log
- s5 · started, tier standard
- s5-d · rebuilt work/html-kit/prototype/setup-guide.html (19667 bytes) from AUTHORING.md + docs/setup-guide.html only; both greps print 0, one script (kit line), all classes on the sheet, all ../../../docs/ links resolve
- s5-d · first render pass failed: Mermaid pipeline clipped at 390, 720/900-wide SVGs unreadable at 390; redrew fig2/fig3 as narrow SVG (520/560 viewBox), fig1/fig4/fig5 as table/card grids; second pass 20 shots in work/html-kit/prototype/shots/s5/setup/ all opened and pass (fig2/fig3 labels large at 1280, ~25px)
- s5-d · on disk: work/html-kit/prototype/setup-guide.html + 20 shots in work/html-kit/prototype/shots/s5/setup/; not on disk: no commit, no kit or other page changes
- s5 · done
