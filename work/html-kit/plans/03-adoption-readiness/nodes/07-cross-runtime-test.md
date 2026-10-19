---
id: 07-cross-runtime-test
title: Codex + Gemini each rebuild docs/setup-guide.html from the rules alone; render-check
status: todo
kind: work
wave: 2
blocked_by: [06-reconcile-1]
check: test -f prototype/xrt/codex/setup-guide.html && test -f prototype/xrt/gemini/setup-guide.html
sessions: []
---

## Goal

Fresh, cross-runtime proof. `codex exec` and `gemini` (both on PATH) each get only AUTHORING.md (+ DIAGRAMS.md) and the source docs/setup-guide.html, and rebuild it into prototype/xrt/<runtime>/setup-guide.html with the kit path adjusted, run the greps, check-links and render-check themselves. Same brief for both; save the brief and each transcript/summary.

## Acceptance

Both pages exist; main session records what each got wrong unaided and whether it self-corrected after the render check.

## Log
