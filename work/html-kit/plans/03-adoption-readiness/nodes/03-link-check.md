---
id: 03-link-check
title: check-links.sh: kit path + relative hrefs resolve
status: done
kind: work
wave: 1
blocked_by: []
check: bash prototype/check-links.sh prototype/setup-guide.html prototype/where-ai-actually-helps.html
sessions: [7]
---

## Goal

prototype/check-links.sh <page>…: for each page, the kit.css and kit.js paths and every relative href/src resolve to an existing file (ignore http(s):, mailto:, #anchors; strip #fragment). Exit 1 listing each broken link.

## Acceptance

Passes on both prototype pages; seen to FAIL on a copy moved one folder down (a new check counts only once seen to fail).

## Log
- s7 · started, tier standard
- s7 · check passed → done
