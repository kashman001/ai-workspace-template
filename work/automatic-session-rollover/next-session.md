# Catchup prompt — Automatic Session Rollover (paste into a new agent session)

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, REPLACED at
> each rollover. Past-tense provenance lives in `handoff.md` (append-only
> ledger, newest block on top). Convention: docs/work-directory-conventions.md.

## Mission

**None — the work item is DORMANT.** The wayfinder map is complete and fully
drained: issues 01–10 are CLOSED/settled; issue 04 (in-place clear relaunch)
is PARKED and strictly user-scheduled — never pick it up unprompted. Only
resume this item on an explicit user mission.

## If you were launched anyway

1. **Freshness guard:** `git fetch origin` then
   `git log --oneline HEAD..origin/main` — MUST be empty; else
   `git pull --ff-only` and RE-READ this launcher.
2. `scripts/context-budget.sh register --project automatic-session-rollover`
   — expect `role=primary`.
3. Read the top `handoff.md` block, then ask the user what the mission is.

## Numbering rule (ADR-0007, binding)

Your session number = the number in your own bootstrap prompt, verbatim —
use it in your ledger block title and any worktree name; never re-derive it
from ledger prose. At rollover, sync `.session-seq` to your own number before
launching (session-rollover skill, step 7).

## Do NOT reload

- Issue tickets, `map.md`, research corpus, sessions ≤29 handoff blocks,
  `handoff-archive.md` — settled provenance; reference only.

## At session end

Lock releases mechanically (launcher script or SessionEnd hook). Manual
fallback: `scripts/context-budget.sh release --project automatic-session-rollover`.
