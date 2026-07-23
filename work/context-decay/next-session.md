# Next Session — context-decay

## Mission

The context-budget system is shipped, in live use, and has saved two sessions
from the dumb zone. All spec §12 follow-ups are done or externally blocked.
2026-07-23: the session-pinning review (backlog M10–M12, L11, L12) fixed
discovery binding stale/foreign sessions; everything non-gated landed the
same day. **One queued task remains (L13, below); after it lands the project
is dormant** — reopen only when a gate clears or the ledger warrants a fresh
analysis pass.

## Read these, in order

1. This file.
2. `handoff.md` — what the 2026-07-23 session-pinning session shipped.
3. Only if doing L13: the L13 card in `docs/template-workspace-backlog.html`
   and the two Quickstart sections of `docs/context-budget.md`.

## Do NOT reload

- `context-decay-spec.md` — fully implemented incl. §12; re-reading tempts
  re-implementation.
- `design.html` — human reference; duplicated in `docs/context-budget.md`.
- **Gemini auth on this machine** — settled dead ends (personal OAuth tier
  discontinued, Vertex ADC 403): see `docs/operational-knowledge.md`. Do not
  retry those paths.
- The M9 / telemetry / analysis / session-pinning diffs — committed
  (`2cc2828`, `b278c5f`, `58c441e`, `03c19d3`, `f1eb1b1`) and pushed.
- `ledger-analysis.md` — unchanged conclusions (baseline ~50K, 20–40K per
  unit); re-read only at the next analysis pass.
- The mtime-vs-pin debate — settled: pin runtime-exported session ids,
  mtime only as fallback (backlog M10/M11 cards carry the reasoning).

## Open items

Backlog IDs refer to `docs/template-workspace-backlog.html`.

Queued (not gated — do first):

0. **L13 — developer-facing registration lifecycle**: add a short
   session-lifecycle note to the *developer* quickstart in
   `docs/context-budget.md` (register is agent-documented only; clarify
   what's automatic-by-instruction vs manual, inside vs outside the
   workspace tree). Optionally wire a Claude Code `SessionStart` hook in
   `.claude/settings.json.example` to make registration mechanical for that
   runtime (verify the hook event exists in current Claude Code first).
   See the L13 card for evidence/impact.

Externally gated:

1. **Gemini live-response verification** — needs the user to provide a
   `GEMINI_API_KEY` (AI Studio). Then, in this workspace:
   `GEMINI_CLI_TRUST_WORKSPACE=true gemini -p "hi"` and confirm
   `scripts/context-budget.sh check --runtime gemini` says `method=exact`.
   Also live-verifies the M12 reset-at-register fix (fixture-verified only).
2. **Copilot CLI adapter verification** — needs Copilot CLI installed
   (`~/.copilot` currently has only `ide/`). While there: `env | grep -i copilot`
   for a session-pin var (L11).
3. **L11 remainder — codex session-pin check**: in a live Codex session,
   `env | grep CODEX` for a session/rollout id; pin like M10/M11 if found.
4. **Next ledger analysis** — after ~20 entries or the first
   `method=estimate` rows (currently 13 entries, all claude/exact).

## State snapshot

Branch `main`, clean, pushed. No running processes. `.gemini/telemetry.log`
was deleted during M12 fixture testing (gitignored; Gemini recreates it, and
`register --runtime gemini` now truncates it at every session boundary).

## First actions

1. `scripts/context-budget.sh register`
2. Land **L13** (queued item 0 above): developer-quickstart lifecycle note
   + optional `SessionStart` hook; flip the L13 card to Resolved, commit,
   push.
3. Then: if a gate has cleared, run that item; otherwise the project is
   dormant — proceed with whatever the user brings, following the Context
   Budget section in `CONTEXT.md`.
