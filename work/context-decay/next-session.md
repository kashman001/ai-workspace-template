> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in `handoff.md`
> (the append-only ledger). Convention: docs/work-directory-conventions.md.

# Next Session — context-decay

## Mission

The context-budget system is shipped, in live use, and has saved two sessions
from the dumb zone. All spec §12 follow-ups are done or externally blocked.
2026-07-23: the session-pinning review (backlog M10–M12, L11, L12) fixed
discovery binding stale/foreign sessions; everything non-gated landed the
same day, and L13 (developer-quickstart lifecycle note + Claude Code
`SessionStart` registration hook in `.claude/settings.json.example`) landed
later that day. The L11 remainder landed 2026-07-23 (codex pin live-verified;
copilot-cli pin research-sourced). **The project is dormant** — reopen only
when a gate clears or the ledger warrants a fresh analysis pass.

## Read these, in order

1. This file.
2. The TOP block of `handoff.md` (the ledger) — what the last session shipped.

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

Backlog IDs refer to `docs/template-workspace-backlog.html`. All remaining
items are externally gated:

1. **Gemini live-response verification** — needs the user to provide a
   `GEMINI_API_KEY` (AI Studio). Then, in this workspace:
   `GEMINI_CLI_TRUST_WORKSPACE=true gemini -p "hi"` and confirm
   `scripts/context-budget.sh check --runtime gemini` says `method=exact`.
   Also live-verifies the M12 reset-at-register fix (fixture-verified only).
2. **Copilot CLI adapter live verification** — needs Copilot CLI installed
   (`~/.copilot` currently has only `ide/`). The pin + path fix landed from
   changelog research; remaining checks are narrower: confirm
   `$COPILOT_AGENT_SESSION_ID` reaches agent-spawned subshells and equals the
   `session-state/<uuid>/` dir name, and check whether `events.jsonl` token
   metrics are written live mid-session or only at session end.
3. **Next ledger analysis** — after ~20 entries or the first
   `method=estimate` rows (currently 18 entries, all claude/exact — this
   gate is nearly due).

## State snapshot

Branch `main`, clean, pushed. No running processes. `.gemini/telemetry.log`
was deleted during M12 fixture testing (gitignored; Gemini recreates it, and
`register --runtime gemini` now truncates it at every session boundary).
The live gitignored `.claude/settings.json` now carries the `SessionStart`
registration hook — Claude Code sessions in this workspace auto-register
(step 1 below still can't hurt).

## First actions

1. `scripts/context-budget.sh register`
2. If a gate has cleared, run that item; otherwise the project is dormant —
   proceed with whatever the user brings, following the Context Budget
   section in `CONTEXT.md`.
