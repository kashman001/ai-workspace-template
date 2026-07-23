# Next Session — context-decay

## Mission

The context-budget system is shipped, in live use, and has saved two sessions
from the dumb zone. All spec §12 follow-ups are done or externally blocked.
This project is **dormant** — only reopen it when a blocker clears or the
ledger warrants a fresh analysis pass.

## Read these, in order

1. This file.
2. `handoff.md` — what the 2026-07-23 follow-up session shipped.
3. `ledger-analysis.md` — session baseline ~50K, ~20–40K per work unit,
   2–3 units per session.

## Do NOT reload

- `context-decay-spec.md` — fully implemented incl. §12; re-reading tempts
  re-implementation.
- `design.html` — human reference; duplicated in `docs/context-budget.md`.
- **Gemini auth on this machine** — settled dead ends (personal OAuth tier
  discontinued, Vertex ADC 403): see `docs/operational-knowledge.md`. Do not
  retry those paths.
- The M9 / telemetry / analysis diffs — committed (`2cc2828`, `b278c5f`,
  `58c441e`) and pushed.

## Open items (all externally gated)

1. **Gemini live-response verification** — needs the user to provide a
   `GEMINI_API_KEY` (AI Studio). Then, in this workspace:
   `GEMINI_CLI_TRUST_WORKSPACE=true gemini -p "hi"` and confirm
   `scripts/context-budget.sh check --runtime gemini` says `method=exact`.
2. **Copilot CLI adapter verification** — needs Copilot CLI installed
   (`~/.copilot` currently has only `ide/`).
3. **Next ledger analysis** — after ~20 entries or the first
   `method=estimate` rows (currently 9 entries, all claude/exact).

## State snapshot

Branch `main`, clean, pushed. No running processes. `.gemini/telemetry.log`
exists locally (gitignored) — delete freely.

## First actions

1. `scripts/context-budget.sh register`
2. If a gate above has cleared, run that item; otherwise this project has
   nothing open — proceed with whatever the user brings, following the
   Context Budget section in `CONTEXT.md`.
