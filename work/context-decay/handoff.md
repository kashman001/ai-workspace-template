# Handoff — session-pinning fixes (2026-07-23, session 3)

Backward-looking record of the session-pinning session (session 3 of this
project; session 2's handoff is in git history at `f18b830^..f18b830`).
Forward plan: `next-session.md`.

## What shipped (all committed & pushed)

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

## Session telemetry

Registered at 41.6K, WARN hook fired at ~126K mid-turn (live demo of layer
1), rollover started at 133K. Ledger now 13 entries, all claude/exact.
