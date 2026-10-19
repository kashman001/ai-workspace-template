---
id: 07-cross-runtime-test
title: Codex + Gemini each rebuild docs/setup-guide.html from the rules alone; render-check
status: done
kind: work
wave: 2
blocked_by: [06-reconcile-1]
check: test -f prototype/xrt/codex/setup-guide.html && test -f prototype/xrt/gemini/setup-guide.html
sessions: [8]
---

## Goal

Fresh, cross-runtime proof. `codex exec` and `gemini` (both on PATH) each get only AUTHORING.md (+ DIAGRAMS.md) and the source docs/setup-guide.html, and rebuild it into prototype/xrt/<runtime>/setup-guide.html with the kit path adjusted, run the greps, check-links and render-check themselves. Same brief for both; save the brief and each transcript/summary.

## Acceptance

Both pages exist; main session records what each got wrong unaided and whether it self-corrected after the render check.

## Log
- s8 · started, tier standard
- s8 · blocked: codex half done (2 rounds, shots viewed); gemini half blocked: Gemini CLI 0.46 free tier refused (IneligibleTierError, migrate to Antigravity); launching agy was denied by the auto-mode safety classifier - needs the user's permission
- s8 · started, tier standard
- s8 · check passed → done
