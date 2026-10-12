---
id: 01-ceremony-guide
title: Stakes-to-ceremony guide (docs) + ask-matt call
status: done
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

- [x] `docs/stakes-to-ceremony.md` exists, under ~4 KB, names only skills that exist in `skills/`
- [x] Adoption note included (gradual rollout, verification first, prune)
- [x] `ask-matt` decision made; if patched, `workspace.patch` applies cleanly (`patch --dry-run`) and starts with an `Upstream:` line
- [x] Decision-note text and the `CONTEXT.md` one-liner returned to the orchestrator

## Log
- s24 · started, tier standard
- s24-a · wrote docs/stakes-to-ceremony.md (2793 B: band test, four-band table, floors, adoption note); all 17 backticked skill names checked against `ls skills/`, none missing
- s24-a · ask-matt left pristine — no skills/ask-matt/workspace.patch written; the guide's intro points at ask-matt for the detailed route instead (Tier-2 text in the handback)
- s24-a · on disk: docs/stakes-to-ceremony.md and this node file only. Not on disk, returned for the orchestrator: CONTEXT.md Workspace Skills pointer, decisions.md note; last Acceptance box left for the orchestrator to tick on receipt
- s24 · orchestrator: decision note appended to decisions.md; CONTEXT.md bullet queued for node 09
- s24 · done
