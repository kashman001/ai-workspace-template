# Handoff — context-decay follow-ups (2026-07-23)

Backward-looking record of the follow-up session (session 2 of this project;
the build session's handoff is in git history at `d6827c8`). Forward plan:
`next-session.md`.

## What shipped (all committed & pushed)

- `2cc2828` — **Fix M9**: `register` trusted the stale session registry and
  bound the previous session's transcript (observed live as a false WARN at
  146.8K in a fresh session). `resolve_session()` now forces fresh discovery
  for `register` only. Backlog finding M9 + decision note added.
- `b278c5f` — **Gemini exact counts via workspace telemetry**: tracked
  `.gemini/settings.json` gains a local-file telemetry block; the gemini
  adapter prefers workspace `.gemini/telemetry.log` (gitignored) and parses the
  last response's input tokens, both `input_token_count` and OTel
  `gen_ai.usage.input_tokens` spellings; falls back to chat-log estimate, never
  telemetry-file size. Docs/CONTEXT/graphify-deletion guidance updated.
- `58c441e` — **First ledger analysis** (`ledger-analysis.md`) + next-session
  refresh.
- (uncommitted at rollover, committed with it) Gemini auth gotchas →
  `docs/operational-knowledge.md`; sharpened blocker wording in
  `docs/context-budget.md`.

## Verification status

- M9 fix: verified live (correct re-bind + `check` read-back).
- Gemini telemetry wiring: **proven live** — a real run wrote a 223KB OTLP log
  from the tracked settings. Parser: fixture-verified for both attribute
  spellings (exact WARN/OK exit codes). **Not verified**: a real successful
  response — every auth path on this machine failed (personal OAuth tier
  discontinued → `IneligibleTierError`; Vertex ADC 403; no `GEMINI_API_KEY`).
  Details in `docs/operational-knowledge.md`.
- Copilot CLI adapter: still unverified — CLI not installed on this machine.

## State at handoff

`main` clean and pushed. Ledger at 9 entries (all claude/exact). Session
rolled over on a real hook WARN at 123.9K — the system's second live save.
No running processes. `~/.gemini/settings.json` (my oauth attempt) was removed;
`.gemini/telemetry.log` remains locally (gitignored, harmless).
