# 07 — Copilot CLI per-child (task) artifact location — research report

Ticket: `work/automatic-session-rollover/issues/07-copilot-child-artifact-location.md`
(NOTE: ticket exists only in the session-23 worktree
`.claude/worktrees/session-23-registry-hygiene/`, not the main checkout —
this report lives in the same tree.)

Status: IN PROGRESS — rolled over at gen 1 on a pushed context-budget WARN
before any copilot runs were executed. No verdict yet.

## [gen 1] Progress block — 2026-08-06

### Finished

1. Read ticket + `smoke-test-copilot.md` (confirmed facts, do NOT re-derive):
   - copilot 1.0.78 at `/opt/homebrew/bin/copilot`; auth works headless via
     `GH_TOKEN=$(gh auth token) copilot -p '…' --allow-all-tools`.
   - Parent-session artifacts CONFIRMED:
     `~/.copilot/session-state/<sessionId>/events.jsonl` (JSONL; carries
     `"inputTokens"`, event types `session.start`, `assistant.turn_start/end`,
     `session.usage_checkpoint` with `modelId`, `session.shutdown`); siblings
     `session.db`, `workspace.yaml` (`cwd` + `git_root`), `checkpoints/`,
     `files/`. `COPILOT_AGENT_SESSION_ID` exported to shell tools.
   - Useful flags: `-p`, `--allow-all-tools`, `--output-format json` (JSONL
     stdout), `--share[=path]` (session markdown export), `--session-id <uuid>`,
     `--log-dir/--log-level`.
2. Pre-run snapshot of `~/.copilot/` (2026-08-06 ~14:47, BEFORE any probe run):
   - Top level: `config.json`, `ide/`, `installed-plugins/`, `logs/`,
     `session-state/`, `session-store.db` (+ `-shm`/`-wal` — SQLite at the
     ~/.copilot ROOT, distinct from per-session `session.db`),
     `vscode.session.metadata.cache.json`.
   - `session-state/` contains exactly these 6 session dirs (any NEW dir after
     a probe run belongs to that run — diff against this list):
     `8f0a77cf-5e49-4e5c-8500-90838a2fc912`,
     `3536dd0e-230c-4966-8894-05655539e91a`,
     `687723d9-e513-4c6d-ba49-8bc3f87c32a4`,
     `bd3428da-d9c4-4d13-a2a1-7a07037c990f`,
     `b7c7fd8e-1541-4554-919d-feeadf681387`,
     `a78dccb7-56b7-452e-84a1-2a7b0b9fccd3`.
   - `logs/`: `process-<epoch-ms>-<pid>.log` files.

### Not yet done (open items — the actual experiment)

1. Create throwaway scratch dir. GOTCHA: the worktree-isolated session sandbox
   REFUSED the compound `mktemp -d && cd && git init && echo >file` command
   ("too complex to verify it stays inside the worktree"). Use plain separate
   Bash calls, e.g. one call `mktemp -d /tmp/copilot-task-probe.XXXXXX`, then
   subsequent calls with absolute paths (`git -C <dir> init`, Write tool for
   files) — or run copilot with `-C <dir>` without cd.
2. Run 1: `GH_TOKEN=$(gh auth token) copilot -p "<prompt asking it to delegate
   a small investigation to a subagent/task>" --allow-all-tools
   --output-format json -C <scratch>` — capture stdout JSONL; look for
   task/subagent tool calls and per-task usage.
3. Run 2 (if run 1 spawns a task): add `--share <scratch>/share.md`; inspect
   markdown for per-task sections.
4. After EACH run, diff `~/.copilot/` against the gen-1 snapshot above:
   - new `session-state/<uuid>/` dirs — one per run, or extra dirs per task?
   - inside the run's dir: does `events.jsonl` contain task/subagent events
     (grep for `task`, `subagent`, `agent` event types)? Do task events carry
     their own `inputTokens`? Is there a task id key distinct from sessionId?
   - `checkpoints/`, `files/`, per-session `session.db`: any per-task rows?
   - root `session-store.db`: `sqlite3 ~/.copilot/session-store.db .tables`
     (read-only copy first if locked by WAL) — look for a tasks table.
   - `logs/process-*.log`: new processes spawned per task?
5. Only if live evidence is ambiguous: corroborate with gh.io/copilot-cli docs.
6. Write VERDICT section (required): "Findable + parseable" (paths, format,
   keying, adapter sketch: discovery + token measurement) OR "No on-disk
   per-child artifacts" (evidence). Then remove scratch dir.

### Rollover state

- Generation 1 yielded ROLLOVER_NEEDED on a pushed WARN (122.8K tokens) —
  parent session context, not this subagent's own doing; no copilot runs made,
  so zero API cost spent and no scratch dirs left behind.
- Successor: start directly at open item 1; everything needed from the ticket
  and smoke test is condensed above — do not re-read `smoke-test-copilot.md`
  unless a specific claim needs checking.
