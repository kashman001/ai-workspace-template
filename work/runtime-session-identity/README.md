# Runtime Session Identity — every runtime pins its own session, even without an id env var

Governing skill(s): `plans` (once the probe results are in), `diagnosing-bugs` for the probes.

**Start here:** `next-session.md` (catch-up launcher) → `handoff.md`
(session ledger, top block).

## What this is

`scripts/context-budget.sh` identifies a session by the runtime's own env var
(`CODEX_THREAD_ID`, `COPILOT_AGENT_SESSION_ID`, …) or, failing that, by
newest-mtime discovery — which can bind a sibling session's transcript when two
sessions share a workspace. Claude Code avoids this because its hook payload
carries the exact `session_id` + `transcript_path` and its `SessionStart` hook
registers mechanically. This item measures where Codex, GitHub Copilot and
Antigravity (Google's replacement for Gemini CLI/Code Assist; user decision 2026-10-12) actually stand (CLI and IDE/app surfaces), then plans fixes.

## Success criteria

1. `probes/<surface>.md` exists for every surface in the matrix below, each
   answering Q1–Q4 with captured evidence (or "blocked: <why>").
2. A plan (`plans/`) whose nodes each close a measured gap, with a proving
   check per node.
3. After the plan: for each supported surface, two concurrent sessions in one
   workspace each register their own transcript — shown by a test or a live
   probe log.

## Probe questions (per surface)

- **Q1 env id** — is the runtime's session-id env var set in shells the agent spawns?
- **Q2 hooks** — do the committed repo hooks fire, and does the payload carry
  `session_id` + `transcript_path`? (capture the raw payload)
- **Q3 register** — does `context-budget.sh register` from the agent's shell
  bind the right transcript?
- **Q4 concurrency** — with two sessions live in the same workspace, does each
  bind its own?

## Surface matrix

| Surface | Who runs it | Probe file |
|---|---|---|
| Codex CLI 0.153.4 | agent (scratch clone, `codex exec`) | `probes/codex-cli.md` |
| Codex VS Code extension (`openai.chatgpt`) | user | `probes/codex-vscode.md` |
| Copilot CLI 1.0.78 | agent (scratch clone, `copilot -p`) | `probes/copilot-cli.md` |
| Copilot Chat in VS Code 1.141 | user | `probes/copilot-vscode.md` |
| Gemini CLI 0.46.0 | static only (kept as reference; superseded by Antigravity) | `probes/gemini-cli.md` |
| Antigravity CLI (`agy`, `~/.local/bin/agy`) | agent (scratch clone) | `probes/antigravity-cli.md` |
| Antigravity IDE + app | user | `probes/antigravity-ide.md` |

## Files

- `next-session.md` — forward launcher (what to do next). REPLACED each rollover.
- `handoff.md` — session ledger (what happened). APPEND newest-on-top; archive
  to `handoff-archive.md` when it exceeds the two most recent sessions.
- `probes/` — one evidence file per surface.
