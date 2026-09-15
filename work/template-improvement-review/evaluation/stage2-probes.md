# Stage 2 probes — `claude --bg` env survival and `/clear` session rotation

Empirical, 2026-09-15 (local 2026-09-14 ~22:25–22:31), `claude` 2.1.272 at `/Users/kashif/.local/bin/claude`, macOS.
Probe dir (left in place for inspection, contains `hook.log`, `session*.log`, `drive.exp`, `marks.txt`, stdout captures):
`/private/tmp/claude-501/-Users-kashif-Developer-experiments-ai-workspace-template/e7e59475-fbf6-4073-8afb-212ddc186b97/scratchpad/probes/` (below: `$P`).
Transcript dir for that cwd: `~/.claude/projects/-private-tmp-claude-501--Users-kashif-…-scratchpad-probes/` (below: `$T`).

Shared setup: `$P/.claude/settings.json` with `SessionStart` (matcher `*`) and `SessionEnd` hooks, both calling `$P/hook.sh <event>`,
which appends the hook's stdin JSON plus `TF_PROBE`, `hook_ppid`, `hook_pid`, `ts` as one JSON line to `$P/hook.log`.
Nothing under the workspace or `~/.claude/settings.json` was modified.

## Probe B — does an env var survive `claude --bg`?

**Method.** From `$P`:
1. `claude --help` — `--bg` exists in 2.1.272. Help text, verbatim: `--bg, --background  Start the session in the background and
   return immediately. Prints the id that `claude attach`, `logs`, `stop` and `rm` take; `claude agents` lists them. With --resume
   <session-id>, continues that session in the background under the same ID, or starts a copy and says so when the session is already running`
2. `TF_PROBE=bgprobe-$(date +%s) claude --bg "Reply with exactly: ok"` (no daemon was running beforehand; shell pid 94318).
3. Second launch, new value, ~40 s later while the first daemon was still alive: `TF_PROBE=bgprobe2-$(date +%s) claude --bg "Reply with exactly: ok"`.
4. Contrast: `TF_PROBE=attached-$(date +%s) claude -p "Reply with exactly: ok"`.

**Raw evidence** (`hook.log`, SessionStart lines, trimmed to the relevant keys):
```
{"session_id":"cb95909d-…","source":"startup","TF_PROBE":"bgprobe-1789442702","hook_ppid":"94352","ts":"2026-09-15T03:25:03Z"}   # launch 1, exported bgprobe-1789442702
{"session_id":"718d3b48-…","source":"startup","TF_PROBE":"bgprobe-1789442702","hook_ppid":"94368","ts":"2026-09-15T03:25:44Z"}   # launch 2, exported bgprobe2-1789442743 -> STALE value
{"session_id":"96f49c8d-…","source":"startup","TF_PROBE":"attached-1789442767","hook_ppid":"96855","ts":"2026-09-15T03:26:07Z"}  # -p, correct value
```
Process tree after launch 1 (`ps -o pid,ppid,command`): shell 94318 → gone by the time the hook ran; session 94352 `claude bg-spare …` ← 94347
`claude bg-pty-host …` ← 94330 `claude daemon run --origin transient --spawned-by {"label":"claude --bg",…}` ← PPID 1 (launchd). So the
session is fully re-parented. `ps -E -p 94330` (daemon) and `ps -E -p 94368` (a pre-spawned *spare* session) both showed
`TF_PROBE=bgprobe-1789442702`: the daemon inherits the environment of whichever `claude --bg` invocation spawned it, and pre-forks spare
sessions from that environment. Launch 2 claimed spare 94368 (hook_ppid 94368), hence the stale value. Both bg sessions replied `ok`
(`claude logs cb95909d`). `claude agents --json` listed them alongside 5 pre-existing `blocked` background agents from other work (untouched).

**Verdict: SURVIVES-ONLY-IF-THE-LAUNCH-SPAWNS-THE-DAEMON** (no clean yes/no). The launcher's line-1184 claim ("does not survive") is false
for a cold start and effectively true for a warm one: with a daemon already up, the new session's environment is the daemon's, not the caller's.

**Cleanup.** `claude stop cb95909d`, `claude stop 718d3b48` (SessionEnd lines logged, `reason:"other"`); the transient daemon exited on its
own. One orphaned `bg-pty-host` (pid 96000, ppid 1, cwd `/private/tmp/cc-daemon-501/…/spare`) remained; its env carried no `TF_PROBE`, so
it could not be proven mine and was left alone. Final sweep (`pgrep -f claude` minus 6 baseline pids, cwd via `lsof -d cwd`): nothing left.

**Bearing on the design.** The handshake-file approach is the right call, but for a different reason than the script states: env vars are
not dropped by daemonization, they are *captured* by the first daemon and replayed into later sessions, so an env-var contract would
silently hand session N the value meant for session 1. Any per-launch parameter (project, rollover token, mode) must travel via a file or
CLI argument, never via the environment of the `claude --bg` caller; the comment at line 1184 should be reworded to say so.

## Probe A — does `/clear` rotate the session id and the transcript JSONL?

**Method.** `expect` driver `$P/drive.exp` (log: `$P/session.log`, wall-clock marks: `$P/marks.txt`): `spawn claude` (140x40), wait 12 s,
detect the "Quick safety check … Yes, I trust this folder" dialog, send Down+Enter (its default cursor is on **No, exit** — plain Enter
quits; that cost one attempt), send `hello, reply with one word`⏎, wait 25 s, `/clear`⏎, wait 12 s, `hi again, one word`⏎, wait 25 s,
`/exit`⏎. Three attempts total: (1) Tcl quoting bug in the script, (2) Enter chose "No, exit" and, once fixed, ran fine but the TUI
showed `⚠ Transcript saving is off — inherited CLAUDE_CODE_CHILD_SESSION marker` (this probe runs inside a Claude Code subagent), so no
JSONL was written; (3) final run under `env -u CLAUDE_CODE_CHILD_SESSION`, which is the run below. Model replied `Hello.` both times.
The TUI's own `/clear` help line, from `session.log`: `Start a new session with empty context; previous session stays on disk (resumable with /resume)`.

**Raw evidence.** `hook.log` (run 3):
```
{"event":"start","session_id":"f5649d8f-0a09-4203-bbc5-1be9b31592eb","source":"startup","ts":"2026-09-15T03:29:37Z"}
{"event":"end",  "session_id":"f5649d8f-0a09-4203-bbc5-1be9b31592eb","reason":"clear","ts":"2026-09-15T03:30:16Z"}
{"event":"start","session_id":"82dd9ae0-efb9-4b26-a879-2aad63b3e060","source":"clear","ts":"2026-09-15T03:30:16Z"}
{"event":"end",  "session_id":"82dd9ae0-efb9-4b26-a879-2aad63b3e060","reason":"prompt_input_exit","ts":"2026-09-15T03:30:56Z"}
```
`transcript_path` in the two start lines: `$T/f5649d8f-….jsonl` and `$T/82dd9ae0-….jsonl` (different files). `marks.txt`: `clear-sent 03:30:16`.
`ls -la $T` afterwards (local time; 22:30:16 local = 03:30:16Z):
```
-rw-------  257353 Sep 14 22:30  f5649d8f-0a09-4203-bbc5-1be9b31592eb.jsonl   (stat mtime 22:30:16 = the /clear instant; 36 lines; never grew again)
-rw-------  260118 Sep 14 22:30  82dd9ae0-efb9-4b26-a879-2aad63b3e060.jsonl   (stat mtime 22:30:56 = /exit; 38 lines)
```
Cross-references: `jq .sessionId | sort -u` is a single value per file (own sid). No `parentUuid` in the new file matches any `uuid` in the
old file (0 hits); the new file's first record is `{"type":"mode","sessionId":"82dd9ae0-…"}` with `parentUuid:null` on the first user record.
The `/clear` command itself is recorded in the **new** file as a `user` record (`<command-name>/clear</command-name>` under a
`local-command-caveat`), not in the old one. The old sid does appear 8 times in the new file, but only as a stale snake_case top-level
`session_id` key on `attachment`/`assistant`/`system` (stop_hook_summary) records, whose camelCase `sessionId` is the new sid.
Assistant `usage` per file: old `cache_read 34813 / cache_creation 13704 / input 2 / output 6`; new `cache_read 34813 / cache_creation 13861 / input 2 / output 6`,
i.e. the post-clear turn was billed as a fresh context of the same size, not as a continuation.

**Verdict: ROTATES** — new `session_id`, new transcript file; hooks fire `SessionEnd(reason=clear)` then `SessionStart(source=clear)`.

**Bearing on the design.** ADR-0009's assumption holds: `/clear` is a full session boundary observable both via hooks (`source:"clear"`)
and on disk (old JSONL frozen at the clear instant, new JSONL with a fresh uuid chain), so per-session token accounting can key on
transcript file = session. Two measurement caveats: filter records by `sessionId` (camelCase), because the snake_case `session_id` on some
records is stale, and remember the `/clear` command record lands in the *new* file; also note transcripts are not written at all when
`CLAUDE_CODE_CHILD_SESSION` is inherited (nested launches), which any automated measurement harness must unset or override with
`CLAUDE_CODE_FORCE_SESSION_PERSISTENCE=1`.
