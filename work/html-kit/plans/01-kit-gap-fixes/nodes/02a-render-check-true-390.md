---
id: 02a-render-check-true-390
title: render-check: real 390 layout (Chrome min window 500)
status: done
kind: work
wave: 1
blocked_by: []
sessions: [5]
---

## Goal

Found at the wave-1 join: headless Chrome will not lay out a window narrower than 500px, so `--window-size=390` gave a 500px layout cropped to 390 (false overflow findings). Load each copy in an iframe of the exact width inside a wrapper page.

## Acceptance

- [x] probe page reports innerWidth 500 at --window-size=390 (bug confirmed)
- [x] script re-run on setup-guide.html; 390 shots show a true 390 layout (caption wraps; table fits)

## Log
- s5 · render-check.sh now shoots through `.rc-<stem>-frame.html` iframe wrapper (--allow-file-access-from-files, postMessage for measurement); shots/check/setup-guide/ regenerated
- s5 · started, tier standard
- s5 · done
