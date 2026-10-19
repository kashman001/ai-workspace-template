# Catchup prompt — Backlog sweep (closed)

> **This file is the LAUNCHER.** Forward-only, REPLACED at each rollover.
> Provenance lives in `handoff.md`. Convention: docs/work-directory-conventions.md.

## Mission

None. The item is closed: plan `01-open-cards` done (13/13), then L99, L100, L101 fixed.
Remaining Open cards (L97, L103) were not assigned to this item. If the user names a card,
read just that card (`grep -n '<ID>' docs/template-workspace-backlog.html`) and work it
test-first, as L101 was.

## Constraints already decided (do not re-litigate)

- Other sessions share this checkout: stage only your own paths; re-read the backlog files
  right before writing them, and re-check the scorecard after committing.
- Pushing is the user's call; ask, don't push.

## State snapshot

main at the s7 checkpoint commit, ahead of origin (unpushed); tree clean otherwise.

## First actions

1. `scripts/context-budget.sh register --project backlog-sweep`
2. Ask the user which card (if any) to take next.
