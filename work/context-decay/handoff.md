# Handoff — L13 + L11 remainder (2026-07-23, session 4)

Backward-looking record of session 4 (session 3's session-pinning handoff is
in git history at `4ac6f49^`). Forward plan: `next-session.md` — **the
project is dormant**; backlog is 0 open / 27 resolved.

## What shipped (all committed & pushed, through `a138c6e`)

- `4ac6f49` — **Fix L13**: developer-quickstart session-lifecycle note in
  `docs/context-budget.md` + `SessionStart` registration hook in
  `.claude/settings.json.example` (reads `transcript_path` from the hook
  stdin payload; fails open). Also copied into the user's live gitignored
  `.claude/settings.json` — future Claude sessions here register
  mechanically.
- `7c29476` (pulled from origin, authored downstream) — copilot-vscode
  discovery maps `$VSCODE_TARGET_SESSION_LOG` (a `debug-logs/<id>` dir on
  current builds) to `chatSessions/<id>.jsonl`. `df12f76` reconciled the
  backlog (M10 follow-up row) since the delivering session skipped it.
- `83dcb0a` — **Fix L11 remainder** (subagent-driven: 2 sonnet research
  agents + 1 opus implementer): `codex_discover()` pins
  `rollout-*-$CODEX_THREAD_ID.jsonl` — var live-probed via a real
  `codex exec` session on this machine and confirmed in openai/codex source;
  `copilot_cli_discover()` pins
  `${COPILOT_HOME:-~/.copilot}/session-state/$COPILOT_AGENT_SESSION_ID/events.jsonl`
  (CLI ≥1.0.29 changelog) and drops the nonexistent `sessions/` path.
  Research with citations: `work/context-decay/research/*.md`.

## Decisions (commit trailers + backlog cards)

- Pin runtime-exported ids, mtime only as fallback — settled M10/M11
  reasoning extended to the last two adapters.
- Copilot CLI adapter stays **unverified**: its pin is changelog-sourced,
  not live-probed (CLI not installed here).

## Gotchas worth remembering

- `SessionStart` hook stdout is injected into session context — keep it terse.
- `codex exec` probing works for "what env does runtime X export to its
  shells" questions — it cleared a gate previously assumed machine-blocked.
- Copilot CLI's real state dir is `session-state/` (since 0.0.342), not
  `history-session-state/` (legacy) or `sessions/` (never existed).

## Session telemetry

Registered 41.6K → WARN fired at 120.7K on the L11-remainder record →
rollover at ~125K. Ledger now 18 entries (analysis gate at ~20 is close).
