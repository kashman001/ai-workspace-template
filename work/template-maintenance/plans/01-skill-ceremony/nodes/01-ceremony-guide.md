---
id: 01-ceremony-guide
title: Stakes-to-ceremony guide (docs) + ask-matt call
status: doing
kind: work
wave: 1
blocked_by: []
sessions: [24]
---

## Goal

Brief: `../../skill-ceremony-brief.md` item 1. Write a short, runtime-neutral
stakes-to-ceremony guide at `docs/stakes-to-ceremony.md`: a table mapping
change size and risk to the skills to use (tweak → do it and check it; small
feature → `grill-me` + `tdd`; big or fuzzy → `to-spec` + `plans`, verify each
phase; production / security / irreversible → `doubt-driven-development` +
`security-and-hardening` + `code-review`), plus a short adoption note for
downloaders (roll out gradually, verification first, prune what you don't
use). Decide whether `ask-matt` (pristine, vendored) gets a one-line
`workspace.patch` pointing at the guide or is left alone; record the call as
a Tier-2 note (text returned to the orchestrator). Return the one-line
`CONTEXT.md` pointer for Workspace Skills.

## Acceptance

- [ ] `docs/stakes-to-ceremony.md` exists, under ~4 KB, names only skills that exist in `skills/`
- [ ] Adoption note included (gradual rollout, verification first, prune)
- [ ] `ask-matt` decision made; if patched, `workspace.patch` applies cleanly (`patch --dry-run`) and starts with an `Upstream:` line
- [ ] Decision-note text and the `CONTEXT.md` one-liner returned to the orchestrator

## Log
- s24 · started, tier standard
