---
id: 06-deck-rerender
title: Re-render the deck through the render check; fix what it shows
status: done
kind: work
wave: 2
blocked_by: [04-reconcile-w1]
sessions: [5]
---

## Goal

Run the render check on `prototype/where-ai-actually-helps.html` with the
wave-1 kit; fix any diagram that fails (clipped, unreadable at 390, poor dark
contrast) in the deck source only (not the kit; kit bugs go in the Log).

## Acceptance

- [x] shots written to `prototype/shots/s5/deck/`
- [x] failures fixed or logged as kit bugs
- [x] size in bytes reported

## Log
- s5 · started, tier standard
- s5-e · first render-check run → 8 shots in prototype/shots/s5/deck/; failures: fig1 (ring) 'new work' label sat on its dashed arrow at 1280, and at 390 the ring drew at ~0.48 scale (viewBox 700 wide, ring only spans x 174–526) so labels were ~8px; fig2 (eight-stage backup) 'triaged work re-enters planning' was crossed by the telemetry curve at 1280, and at 390 all text ~5px
- s5-e · fixed in prototype/where-ai-actually-helps.html only: fig1 viewBox cropped to content (160 20 380 360) + 'new work' moved to 392,252; fig2 viewBox cropped (20 40 880 300), telemetry curve deepened (control y 305→340), triaged label to 490,259, telemetry label to 430,320; layout/meaning unchanged; author greps print 0 and 0
- s5-e · re-run → all 8 shots opened: fig1 passes at 1280 and 390, light and dark (labels ~14px at 390, no overlap); fig2 passes at 1280 both themes; fig2 at 390 still ~5px labels — logged as a format limit, not fixed: eight stages in one row (the slide's meaning) cannot be legible at 336px content width, a taller viewBox can't be swapped per width, and the deck is a 1280×800 presentation format whose fig2 is a backup slide; phone width is not its target medium. Note for AUTHORING: 'viewBox 700–960 wide' should say crop the viewBox to the drawing (fig1's empty side margins halved its phone size)
- s5-e · size: 17074 → 17079 bytes (wc -c). On disk: edited deck + 8 shots in prototype/shots/s5/deck/. Not on disk/not done: no kit, render-check.sh or setup-guide.html edits; no commit; fig2 phone legibility remains a logged format limit
- s5 · done
