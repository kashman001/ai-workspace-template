# Deterministic session pin for `codex_discover()` (context-budget.sh)

Date: 2026-07-23
Codex CLI installed locally: `codex-cli 0.142.4` (`/opt/homebrew/bin/codex`), authed
(`~/.codex/auth.json` present, mode not printed — contents not read).
Source checked out: `openai/codex` GitHub, default branch `main`, shallow clone at
commit `205d37a20f742b0bf8e191622bd07c43f567ea49` (fetched 2026-07-23).

## 1. Local inspection

`~/.codex/sessions/` layout: `YYYY/MM/DD/rollout-<timestamp>-<uuid>.jsonl`, e.g.
`~/.codex/sessions/2026/07/23/rollout-2026-07-23T12-29-43-019f9006-aa79-74a2-9b21-25d760dfd452.jsonl`.

First line of a rollout file is a `session_meta` record:

```json
{"timestamp":"...","type":"session_meta","payload":{
  "id":"019f9006-aa79-74a2-9b21-25d760dfd452",
  "timestamp":"...",
  "cwd":"/path/to/workdir",
  "originator":"codex_cli_rs",
  "cli_version":"0.0.0",
  "source":"unknown",
  "model_provider":"openai",
  "base_instructions":{...}
}}
```

Top-level keys: `timestamp`, `type`, `payload`. `payload` keys: `base_instructions`,
`cli_version`, `cwd`, `id`, `model_provider`, `originator`, `source`, `timestamp`.
`payload.id` is the same UUID that appears as the trailing component of the rollout
filename, and `payload.cwd` is the working directory the session started in — both
useful independent of the env-var pin below.

## 2. Live probe

Ran, from the scratchpad dir, one non-interactive session:

```
codex exec --skip-git-repo-check "Run the shell command: env | grep -iE 'codex|session|rollout' ; echo done. ..."
```

Codex's own banner printed `session id: 019f9006-aa79-74a2-9b21-25d760dfd452`. The
executed shell command's `env` output (captured verbatim) included:

```
CODEX_CI=1
CODEX_SANDBOX=seatbelt
CODEX_SANDBOX_NETWORK_DISABLED=1
CODEX_THREAD_ID=019f9006-aa79-74a2-9b21-25d760dfd452
```

`CODEX_THREAD_ID` is **exactly** the session id from the banner. After the run, the
resulting rollout file was:

```
~/.codex/sessions/2026/07/23/rollout-2026-07-23T12-29-43-019f9006-aa79-74a2-9b21-25d760dfd452.jsonl
```

— i.e. `CODEX_THREAD_ID` == the UUID suffix of the rollout filename == `payload.id`
in the file's `session_meta` record. All three identifiers are the same value.

`CODEX_SANDBOX` / `CODEX_SANDBOX_NETWORK_DISABLED` are sandbox-mode indicators, not
session identifiers (no session-scoped value); irrelevant to pinning. `CODEX_CI` is
also an unrelated flag exported in this environment (project/CI env, not Codex-set —
see below).

## 3. Source research (openai/codex, `codex-rs`)

**(a) Env var injection — `CODEX_THREAD_ID`.**

- Constant defined once: `codex-rs/protocol/src/shell_environment.rs:6`
  `pub const CODEX_THREAD_ID_ENV_VAR: &str = "CODEX_THREAD_ID";`
- Injected unconditionally whenever a thread id is available, in
  `codex-rs/protocol/src/shell_environment.rs:104-107` (`populate_env`, "Step 6 -
  Populate the thread ID environment variable when provided"):
  ```rust
  if let Some(thread_id) = thread_id {
      env_map.insert(CODEX_THREAD_ID_ENV_VAR.to_string(), thread_id.to_string());
  }
  ```
  This happens **after** the `include_only` allow-list filter (Step 5), so
  `CODEX_THREAD_ID` survives even a restrictive shell-environment policy — the doc
  comment on `codex-rs/core/src/exec_env.rs:23` states this explicitly: *"`CODEX_THREAD_ID`
  is injected when a thread id is provided, even when `include_only` is set."*
- Thin wrapper: `codex-rs/core/src/exec_env.rs:25-31` (`create_env`), which converts a
  `codex_protocol::ThreadId` to its string form and calls the above.
- `create_env` is called from every shell-execution path that runs agent-issued
  commands, confirming `CODEX_THREAD_ID` is not an `exec`-mode-only special case:
  - `codex-rs/core/src/tools/handlers/shell/shell_command.rs:103` — the `shell` tool
    handler (what runs when the agent executes a shell command; this is the path
    our own script relies on).
  - `codex-rs/core/src/tasks/user_shell.rs:159` — user-invoked shell task.
  - `codex-rs/core/src/unified_exec/process_manager.rs:1126` — unified-exec (PTY-backed
    interactive/long-running commands).
- There's also a companion `CODEX_PERMISSION_PROFILE` env var
  (`codex-rs/core/src/exec_env.rs:14`, `CODEX_PERMISSION_PROFILE_ENV_VAR`), same
  treatment, but it carries a profile name, not a session id.
- Nested-agent handling: `codex-rs/core/src/tools/runtimes/mod.rs:225-270` explicitly
  strips/repopulates `CODEX_THREAD_ID` (and the permission-profile var) for spawned
  runtime environments "without pretending they came from" the parent, so nested
  Codex-in-Codex invocations get their own correct thread id rather than inheriting
  the parent's — reinforcing that this var is meant as *the* live-session identifier
  for whichever Codex process actually spawned the shell.

**(b) Rollout filename — is the UUID the session/conversation id?**

- `codex-rs/rollout/src/recorder.rs:1553`:
  `let filename = format!("rollout-{date_str}-{conversation_id}.jsonl");`
  where `conversation_id: ThreadId` (struct field documented at
  `codex-rs/rollout/src/recorder.rs:1526`: *"Session ID (also embedded in filename)."*).
- `ThreadId` (`codex-rs/protocol/src/thread_id.rs:10-18`) wraps a `uuid::Uuid`, and its
  doc comment states *"Codex-generated thread IDs are UUIDv7"* — consistent with the
  observed filenames and with `019f9006-...` being a v7 UUID (time-ordered, hence also
  usable as a sortable/monotonic id, though not needed for the pin).
- `Display`/`to_string()` of `ThreadId` is exactly the UUID string, and that same
  `conversation_id`/`ThreadId` value is what `create_env`/`populate_env` stringifies
  into `CODEX_THREAD_ID` (`codex-rs/core/src/exec_env.rs:29`, `shell_environment.rs:106`).
  So **`CODEX_THREAD_ID` (env var seen by exec'd shells) == the UUID suffix of the
  rollout filename == `session_meta.payload.id` in the rollout file** — the same value
  surfaces in three independent places, matching the local live-probe observation.

**(c) `session_meta` record fields.** Confirmed directly from a real rollout file
(section 1 above) rather than only from source: `id` (UUID, matches filename/env var),
`cwd`, `timestamp`, `originator`, `cli_version`, `source`, `model_provider`,
`base_instructions`. The struct that serializes to this is defined in
`codex-rs/protocol` (session-meta payload type feeding `SessionMeta`/`RolloutItem`
serialization referenced from `codex-rs/rollout/src/recorder.rs`); field names were
verified empirically against the shipped 0.142.4 binary's own output, which is the
authoritative shape for the currently-installed version regardless of exact struct
location in the `main`-branch source (versions can drift; the on-disk JSON is ground
truth).

## 4. Recommendation

**Pin `codex_discover()` on `$CODEX_THREAD_ID` when set, falling back to the existing
cwd-filtered newest-mtime scan when unset.**

Rationale: `context-budget.sh` runs inside shell commands that the Codex agent itself
executes — exactly the population that `create_env`/`populate_env` injects
`CODEX_THREAD_ID` into, unconditionally, on every shell-tool invocation (`shell`,
`user_shell`, and unified-exec paths). The live probe reproduces this in this exact
environment/version and shows the value is identical to the rollout filename's UUID.
This closes the same race the Claude/Copilot fixes closed: two concurrent Codex
sessions in the same workspace no longer collide on newest-mtime, because the live
session's own rollout path is computed directly from its own thread id instead of
inferred from file mtimes.

Suggested patch shape (mirrors the existing `claude_discover` pattern):

```sh
codex_discover() {
  local base f
  base="$HOME/.codex/sessions"
  [ -d "$base" ] || return 1

  # Deterministic pin: CODEX_THREAD_ID (exported to every shell command Codex
  # spawns — codex-rs/protocol/src/shell_environment.rs) is the same UUID
  # embedded in this session's own rollout filename
  # (codex-rs/rollout/src/recorder.rs: `rollout-{date}-{conversation_id}.jsonl`).
  if [ -n "${CODEX_THREAD_ID:-}" ]; then
    f="$(find "$base" -name "rollout-*-${CODEX_THREAD_ID}.jsonl" 2>/dev/null | head -1)"
    [ -n "$f" ] && [ -f "$f" ] && { echo "$f"; return 0; }
  fi

  # Fallback: no thread id in env (e.g. running outside a Codex-spawned shell,
  # or an older Codex build without this var) — cwd-filtered newest-mtime, as
  # before. Document that this path still races two concurrent sessions in the
  # same workspace.
  while IFS= read -r f; do
    if head -c 8192 "$f" 2>/dev/null | grep -qF "$(pwd)"; then echo "$f"; return 0; fi
  done < <(find "$base" -name 'rollout-*.jsonl' -mtime -7 2>/dev/null | xargs ls -t 2>/dev/null)
  return 1
}
```

Notes:
- No need to `grep` for cwd once `CODEX_THREAD_ID` matches — the id already
  uniquely identifies the live session's own rollout file; the cwd check is only
  needed for the mtime-based fallback path.
- `CODEX_THREAD_ID` is confirmed present in `codex exec` (non-interactive/scripted)
  sessions, which is the mode our own scripts and agent-issued commands run under;
  it is also wired into the interactive TUI's shell-tool and unified-exec paths per
  the source citations above, so the same pin should hold for interactive `codex`
  sessions too (not independently live-probed here, since `codex exec` was the
  cheaper/safe non-interactive check requested).
- Minimum Codex CLI version for this var was not bisected; it is present in the
  currently-installed `codex-cli 0.142.4` and unconditionally set in the `main`
  branch source at the commit checked. If an org runs a materially older Codex
  build, the `${CODEX_THREAD_ID:-}` unset-check already degrades gracefully to the
  documented fallback.
