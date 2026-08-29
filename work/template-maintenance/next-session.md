<!-- LAUNCHER: forward-looking only; REPLACED at each rollover. History: handoff.md -->

# Next Session — template-maintenance (session #9)

## Mission

No task in flight. **M31 is closed and delivered** (merged to `main`, session
#8). Pick the next item from `docs/template-workspace-backlog.html` (6 open:
grep `status open`) with the user, or wait for direction.

## State snapshot

- `vendor-mattpocock-skills` merged to `main` and pushed; the long-lived
  branch can be retired or kept for the next vendoring wave — ask the user.
- Backlog scorecards: 6 Open / 69 Resolved / 4 Decided.
- Claude Code hook wiring is now committed (`.claude/settings.json`); the
  example seeds only the personal `settings.local.json`.

## First actions

1. `scripts/context-budget.sh register` (skip if the SessionStart hook ran).
2. Read the top block of `handoff.md` (session #8) for what just landed.
3. Ask the user which backlog item is next, or triage the 6 open cards.
