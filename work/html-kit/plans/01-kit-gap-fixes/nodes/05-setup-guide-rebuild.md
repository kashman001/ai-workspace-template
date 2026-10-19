---
id: 05-setup-guide-rebuild
title: Fresh agent rebuilds docs/setup-guide.html from AUTHORING.md alone
status: todo
kind: work
wave: 2
blocked_by: [04-reconcile-w1]
sessions: []
---

## Goal

A fresh subagent, given only `prototype/AUTHORING.md` and the original
`docs/setup-guide.html` (content source), rebuilds it to
`prototype/setup-guide.html` (kit unseen), then runs the render check and
fixes its own diagrams until they pass by its eye.

## Acceptance

- [ ] page rebuilt, grep checks print 0
- [ ] render-check shots written to `prototype/shots/s5/setup/`
- [ ] size in bytes reported; deviations from the rule listed

## Log
