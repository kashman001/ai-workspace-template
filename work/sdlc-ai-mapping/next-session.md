# sdlc-ai-mapping — session 13 launcher

> **This file is the LAUNCHER** (forward-looking, replaced each rollover).
> Provenance: `handoff.md` top block (session 12).

## Mission

Close the work item — all session-12 work (View 2 mermaid diagrams in
both maps + three-zoom charset/layout fixes) is merged to main via
PR #19. No further work is queued.

## Read these, in order

1. `handoff.md` — top block only (session 12: what shipped, the one
   open user action).
2. Nothing else unless the user asks for changes to the diagrams.

## Do NOT reload

- The diagram trade-off analysis, drafts artifact, review history —
  all settled and executed; `decisions.md` has the record.
- `handoff-archive.md` — sessions 1–10 provenance.
- The deck HTML — unchanged.

## State snapshot

- **PR #19 merged** (`64de5fe` on main; commits `0c40da1` map diagrams,
  `10d7875` three-zoom fixes). PR #18 merged before it. Nothing
  unmerged remains.
- Zoom-3 verdict: no chip overlaps (measured); the fixes were charset +
  a layout-timing guard, both verified.
- Published artifacts (republish only **with the URL as `url`**, after
  WebFetch of that URL in the same session):
  - standalone map: https://claude.ai/code/artifact/f86be94e-2362-4342-bddf-0105f395a204 (favicon 🗺️)
  - three-zoom map: https://claude.ai/code/artifact/181a3593-985f-427e-a889-0fb71776ff7d (favicon 🔍)
  - mermaid drafts: https://claude.ai/code/artifact/abd83fc6-eaa0-4b57-97fd-b43b09bfeabc
  - deck v3: https://claude.ai/code/artifact/6989c82f-fec3-4302-b757-506a1d225d5f
- **Open user action:** the three-zoom artifact's share pin still shows
  the pre-fix version to link viewers — the user must move the pin from
  the artifact page's share menu.

## First actions

1. `scripts/context-budget.sh register --project sdlc-ai-mapping`
2. Read `handoff.md` top block.
3. Remind the user about the share pin, take any follow-up direction,
   and otherwise close the item (CLOSED launcher).
