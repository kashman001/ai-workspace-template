# Next Session — context-decay

## Mission

The context-budget system is shipped, in live use, and has saved two sessions
from the dumb zone. All spec §12 follow-ups are done or externally blocked.
2026-07-23 update: the session-pinning review (M10–M12, L11, L12) reopened
three small non-gated fixes — see Open items. After those land the project
returns to **dormant** (reopen when a gate clears or the ledger warrants a
fresh analysis pass).

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

## Open items

Backlog IDs refer to `docs/template-workspace-backlog.html`. 2026-07-23: a
live false-STOP on a downstream machine (M10, copilot-vscode) triggered a
session-pinning review of every adapter; M10 + M11 (claude) are fixed, the
rest are planned below.

Not gated (actionable any time):

1. **M12 — gemini stale first-read**: rotate `.gemini/telemetry.log` at
   `register --runtime gemini` so a fresh session can't read the previous
   session's counts. Verification (not the fix) is gated on Gemini auth.
2. **L11 (part) — codex any-project fallback**: drop/demote the last-resort
   "newest rollout anywhere" in `codex_discover()`.
3. **L12 — document the single-session-per-runtime-per-workspace assumption**
   in `docs/context-budget.md` (registry is keyed per-runtime).

Externally gated:

4. **Gemini live-response verification** — needs the user to provide a
   `GEMINI_API_KEY` (AI Studio). Then, in this workspace:
   `GEMINI_CLI_TRUST_WORKSPACE=true gemini -p "hi"` and confirm
   `scripts/context-budget.sh check --runtime gemini` says `method=exact`.
   Also verifies the M12 fix once landed.
5. **Copilot CLI adapter verification** — needs Copilot CLI installed
   (`~/.copilot` currently has only `ide/`). While there: `env | grep -i copilot`
   for a session-pin var (L11).
6. **L11 (part) — codex session-pin check**: in a live Codex session,
   `env | grep CODEX` for a session/rollout id; pin like M10/M11 if found.
7. **Next ledger analysis** — after ~20 entries or the first
   `method=estimate` rows (currently 9 entries, all claude/exact).

## State snapshot

Branch `main`, clean, pushed. No running processes. `.gemini/telemetry.log`
exists locally (gitignored) — delete freely.

## First actions

1. `scripts/context-budget.sh register`
2. If a gate above has cleared, run that item; otherwise this project has
   nothing open — proceed with whatever the user brings, following the
   Context Budget section in `CONTEXT.md`.
