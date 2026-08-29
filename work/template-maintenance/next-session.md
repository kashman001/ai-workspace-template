<!-- LAUNCHER: forward-looking only; REPLACED at each rollover. History: handoff.md -->

# Next Session — template-maintenance (session #12)

## Mission

No queued mission — the M31→M34 / L41–L43 arc is fully drained and repo-wide
`scripts/check-ledger.py` exits 0. Pick the next work from the backlog's
**6 open cards** (`docs/template-workspace-backlog.html` — grep card IDs,
never load whole) by severity/leverage, or take direction from the user.

## Read these, in order

1. Open cards: `grep -n 'status open' -B 2 docs/template-workspace-backlog.html`
   then targeted reads of the chosen card(s).
2. Top ledger block (`work/template-maintenance/handoff.md`) only if you need
   session-11 context.

## Do NOT reload

- L43 / the ledger-archive fixes — delivered (see session-11 ledger block);
  the lineage-restart marker is documented in
  `docs/work-directory-conventions.md` → "Lineage restart (rare)".
- M31–M34 history — settled; setup docs and hook wiring are current.

## State snapshot

- main = session-11 close commit (L43 fix is its parent). Backlog: 6 open /
  75 resolved. Repo-wide ledger check green; mutation suite 12/12.
- User's checkout: on main, pulled current at session-11 close.
- `.claude/settings.json` (tracked) carries the Claude hook wiring; local
  file is personal-only.

## First actions

1. `scripts/context-budget.sh register --project template-maintenance`
2. Pick/confirm the mission (see above); work it top-down.
3. `scripts/context-budget.sh record --label "<unit>"`; close per conventions
   (ledger block + launcher replacement + push).
