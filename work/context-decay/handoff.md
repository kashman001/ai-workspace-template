<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on TOP.
Each "# Session Handoff" block records what happened in one session. Read the
TOP block only; older blocks are in handoff-archive.md. Forward "what to do
next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 2026-07-23 (session 4: L13 + L11 remainder)

Backlog is 0 open / 27 resolved; the project is dormant.

## What got done (all committed & pushed, through `a138c6e`)

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

## State at rollover / next step

Branch `main` clean, pushed. Registered 41.6K → WARN at 120.7K → rollover at
~125K. Ledger 18 entries (analysis gate ~20 is close). Next: dormant; check
gates in `next-session.md`.

# Session Handoff — 2026-07-23 (session 3: session-pinning fixes)

Session 2's handoff is in git history at `f18b830^..f18b830`.

## What got done (all committed & pushed)

- `03c19d3` — **Fix M10+M11**: session discovery pinned to runtime-exported
  ids over newest-mtime. M10 (reported live from a downstream copilot-vscode
  session: false STOP from a stale sibling log) — `copilot_vscode_discover`
  prefers `$VSCODE_TARGET_SESSION_LOG`. M11 — `claude_discover` pins
  `$CLAUDE_CODE_SESSION_ID.jsonl`; differential-verified (stale transcript
  touched newest in the same shell call: unpinned register binds it, pinned
  binds the live session).
- `f1eb1b1` — **Fix M12+L12, L11 part**: `register --runtime gemini`
  truncates the shared workspace telemetry log after binding it (fixture
  lifecycle-verified: stale 140K WARN → 0 after register → appended response
  reads exact); `gemini_measure` reports `0 estimate` when no logs exist;
  codex any-project fallback removed (fails rather than bind another
  project's rollout); single-session-per-runtime limitation documented.
- Backlog: M10, M11, M12, L12 resolved; L11 open (machine-gated remainder);
  **L13 opened at rollover** — registration lifecycle is agent-documented
  only; fix queued as the next session's first task.

## Decisions (captured in commit trailers + backlog cards)

- Authoritative session-id pin where the runtime exports one; mtime only as
  fallback (rejected: mtime-only — lazy flushes / concurrent sessions lie).
- Gemini: truncate-at-register over OTLP session-id filtering (CLI exports
  no session id to match against).

## Gotchas worth remembering

- Claude transcripts re-flush every turn: mtime differential tests must
  touch-and-measure in a single shell call or the live session instantly
  regains newest mtime.
- `check` reads the registry pin (M9 fix); only `register` re-discovers —
  test discovery changes via `register`, not `check`.

## State at rollover / next step

Registered at 41.6K, WARN hook fired at ~126K mid-turn (live demo of layer
1), rollover started at 133K. Ledger 13 entries, all claude/exact. Next:
land L13.
