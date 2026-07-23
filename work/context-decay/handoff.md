# Handoff — L13 registration lifecycle (2026-07-23, session 4)

Backward-looking record of the L13 session (session 4 of this project;
session 3's session-pinning handoff is in git history at `4ac6f49^`).
Forward plan: `next-session.md` — **the project is now dormant**.

## What shipped (all committed & pushed)

- `4ac6f49` — **Fix L13**: session-lifecycle paragraph in the developer
  quickstart of `docs/context-budget.md` (registration is the agent's job,
  automatic-by-instruction via `CONTEXT.md`, only inside the workspace tree;
  unregistered sessions fall back to newest-mtime discovery) + a
  `SessionStart` hook in `.claude/settings.json.example` running
  `register --runtime claude --transcript <path from hook payload>`.
  Backlog: L13 Resolved, scorecard 1/26/4/0/6 (only L11's machine-gated
  remainder open). `next-session.md` rewritten for dormancy.
- `33767d3` — chore: ledger entry.

## Decisions (in the commit trailer + L13 card)

- Hook reads `transcript_path` from the SessionStart stdin payload
  (documented hook contract) rather than trusting `CLAUDE_CODE_SESSION_ID`
  to be exported to hook processes; fails open (`|| true`, discovery
  fallback on empty payload) so it can never block a session.

## Gotchas worth remembering

- `SessionStart` hook **stdout is injected into the session context** — the
  register status line doubles as the agent's session-start awareness. Keep
  hook stdout terse for that reason.
- Verified the hook by piping a simulated payload into the command extracted
  from the example JSON via `jq` — reusable pattern for testing hook blocks
  without a live session restart.

## Gate status (checked this session — none cleared)

- Copilot CLI: still not installed (`~/.copilot` has only `ide/`).
- `GEMINI_API_KEY`: still unset (user-provided, AI Studio).
- Codex session-pin env check: needs a live Codex session.
- Ledger at 14 entries, all claude/exact (analysis pass at ~20).

## Session telemetry

Registered at 41.6K, 76K at the L13 record, ~80K at checkpoint. No WARN.
