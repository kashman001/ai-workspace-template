# Probe — GitHub Copilot CLI 1.0.78

- **Date:** 2026-10-12, macOS (darwin). `copilot --version` → `GitHub Copilot CLI 1.0.78.`
- **Where:** fresh scratch clone `$S/ws-copilot` (`$S` = the session scratchpad
  dir). Nothing ran with cwd inside WS; nothing committed.
- **Isolation:** `COPILOT_HOME=$S/cphome`, so session-state stays apart from the
  user's real `~/.copilot`. Its `config.json` has
  `trustedFolders: ["$S/ws-copilot"]`, because repo hooks only load in a
  trusted folder (see smoke-test-copilot.md §4a). Auth: `GH_TOKEN=$(gh auth token)`.
- **Hook capture:** in the clone, both `.github/hooks/context-budget.json`
  (`sessionStart`/`agentStop`) and `.github/hooks/context-budget-vscode.json`
  (`SessionStart`/`Stop`) were wrapped as `tee -a $S/hooklog/<event>.jsonl | <original hook>`.
  The wrapper also logged `${COPILOT_AGENT_SESSION_ID:-unset}` as the hook process saw it.
- **Clean env:** runs 2–4 used `$S/runcp.sh`:
  `env -i HOME USER PATH TERM SHELL GH_TOKEN COPILOT_HOME copilot -p "<prompt>" --allow-all-tools --no-ask-user --log-level debug --log-dir <dir>`
  (cwd = clone). Run 1 inherited the caller's Claude Code env, and that run turned up a
  contamination problem (see Q2).

Commands run (prompts abbreviated):

1. Run 1 (inherited env): `copilot -p '… env | grep -i copilot …; pwd; scripts/context-budget.sh register --runtime copilot-cli; echo rc=$?; cat .context-budget/sessions/copilot-cli-*.json' --allow-all-tools --no-ask-user --log-level debug --log-dir $S/cplogs1`
2. Run 2 (clean env): `runcp.sh $S/cplogs2 '… env | grep -iE "copilot|claude" …; pwd; scripts/context-budget.sh register --runtime copilot-cli; …'`
3. Run 3 (fallback): `runcp.sh $S/cplogs3 '… echo own=$COPILOT_AGENT_SESSION_ID; env -u COPILOT_AGENT_SESSION_ID scripts/context-budget.sh register --runtime copilot-cli; …'`
4. Run 4 (concurrency): two `runcp.sh` processes started 6 s apart, each with
   `echo own=$COPILOT_AGENT_SESSION_ID; sleep 20; env -u COPILOT_AGENT_SESSION_ID scripts/context-budget.sh register --runtime copilot-cli`

## Q1 — env id in the agent's shell

**Verdict: YES.** The agent's shell has `COPILOT_AGENT_SESSION_ID`, and its value
is the session's own id (it matches the `Resume copilot --resume=<id>` footer and the
`session-state/<id>/` dir). Hook processes do **not** get the variable.

Run 2 shell env (pulled from that session's `events.jsonl`, which holds the tool output):

```
COPILOT_AGENT_SESSION_ID=afae4822-417e-4055-a215-8eb8e095578f
COPILOT_CLI=1
COPILOT_CLI_BINARY_VERSION=1.0.78
COPILOT_CLI_RESOLVED_DIST_DIR=…
COPILOT_HOME=$S/cphome
...
Resume     copilot --resume=afae4822-417e-4055-a215-8eb8e095578f
```

Run 1 showed the same: `COPILOT_AGENT_SESSION_ID=67a5b56c-…` and footer
`--resume=67a5b56c-…`. Both hook wrappers logged `sid_env=unset`
(`$S/hooklog/sessionStart.meta`: `exit=0 pid=78714 sid_env=unset`).

## Q2 — repo hooks fire; payload fields

**Verdict: YES, in a trusted folder.** In `-p` mode both `sessionStart` and
`agentStop` fired. The debug log says
`[WARNING] Loading repo hooks in prompt mode (folder is trusted or opt-in set)`.
If the folder is not trusted, the hooks never load and nothing warns you (smoke test §4a).

Raw payloads from run 2 (only change: `$S` substituted):

```json
// sessionStart (camelCase file .github/hooks/context-budget.json)
{"sessionId":"afae4822-417e-4055-a215-8eb8e095578f","timestamp":1791835552928,
 "cwd":"$S/ws-copilot","source":"new","initialPrompt":"Run this exact shell command …"}

// agentStop
{"sessionId":"afae4822-417e-4055-a215-8eb8e095578f","timestamp":1791835562318,
 "cwd":"$S/ws-copilot",
 "transcriptPath":"$S/cphome/session-state/afae4822-417e-4055-a215-8eb8e095578f/events.jsonl",
 "stopReason":"end_turn","stop_hook_active":false}
```

- `sessionId` is present in both events. `transcriptPath` is present **only on `agentStop`**,
  not on `sessionStart`. It does follow `COPILOT_HOME`.
- **The CLI also fires the VS Code-format file** `.github/hooks/context-budget-vscode.json`
  (`SessionStart`/`Stop`, snake_case payload), so the `copilot-vscode` adapter row runs
  inside a CLI session:

  ```json
  // SessionStart
  {"hook_event_name":"SessionStart","session_id":"afae4822-…","timestamp":"2026-10-12T20:05:52.928Z",
   "cwd":"$S/ws-copilot","source":"new","initial_prompt":"…"}
  // Stop
  {"hook_event_name":"Stop","session_id":"afae4822-…","timestamp":"2026-10-12T20:06:02.318Z","cwd":"$S/ws-copilot",
   "transcript_path":"$S/cphome/session-state/afae4822-…/events.jsonl","stop_reason":"end_turn","stop_hook_active":false}
  ```

  Because `copilot-vscode` is `register=hook`, every CLI session also writes a stray
  `.context-budget/sessions/copilot-vscode-<cli-sid>.json`. Its artifact path is invalid:
  `$S/cphome/chatSessions/<sid>.jsonl`, derived from the CLI's `transcript_path`, so the file does not exist.
  This showed up in runs 1, 2 and 4.
- **The CLI also appears to run the Claude Code hooks in `.claude/settings.json`.** This is inferred, not
  confirmed from the log's hook list. Run 1 inherited `CLAUDE_CODE_SESSION_ID`, and its
  sessionStart produced `[hook stderr] registered claude session 3f0993e9-… artifact:
  ~/.claude/projects/…/3f0993e9-….jsonl`, which **registered the parent Claude session into the
  clone**. Only `.claude/settings.json`'s SessionStart runs `register --runtime claude`. With the
  clean env (run 2), the same hooks logged
  `[hook stderr] error: no session artifact found for runtime=claude` at both start and stop.
- Copilot hook dispatch, `copilot` row: `tx_check = copilot-state` resolves to
  `${COPILOT_STATE_DIR:-$HOME/.copilot/session-state}/<sid>/events.jsonl`. That path **ignores
  `COPILOT_HOME`**. In these runs the sessionStart check found no transcript and stayed silent.

**Could the sessionStart payload alone support hook-side registration?** Yes. `sessionId`
is exact, and the transcript is deterministic: `${COPILOT_HOME:-~/.copilot}/session-state/<sessionId>/events.jsonl`
(`transcriptPath` on agentStop confirms that layout). Two conditions apply: the derivation
has to honour `COPILOT_HOME`, and the file may not exist yet at sessionStart. `register` already
handles a missing file as `method=deferred`. Switching `register=agent → hook` therefore looks viable,
but only for trusted folders.

## Q3 — `register` from the agent's shell binds the right transcript

**Verdict: YES** with the env var. **PARTIAL** without it: the solo run was correct, but only
because no other session was running.

Run 2 (var set):
```
registered copilot-cli session afae4822-417e-4055-a215-8eb8e095578f artifact: $S/cphome/session-state/afae4822-417e-4055-a215-8eb8e095578f/events.jsonl
runtime=copilot-cli method=exact tokens=33001 … status=OK
rc=0
.context-budget/sessions/copilot-cli-afae4822-….json → "artifact": "$S/cphome/session-state/afae4822-…/events.jsonl"
```

Run 3 (`env -u COPILOT_AGENT_SESSION_ID`, so the newest-mtime fallback, single session):
```
own=bd4217a7-3679-443e-99cd-1d67064be6f2
registered copilot-cli session bd4217a7-3679-443e-99cd-1d67064be6f2 artifact: $S/cphome/session-state/bd4217a7-…/events.jsonl
rc=0
```

## Q4 — two concurrent sessions in one clone, var unset

**Verdict: NO.** Each session bound the **other** session's transcript.

```
=== a   own=f4aa08cd-ae94-4c86-ac6a-54d386070d94
        registered copilot-cli session 5394b17a-7248-472a-bea5-ffb6822dbd3b artifact: …/session-state/5394b17a-…/events.jsonl
=== b   own=5394b17a-7248-472a-bea5-ffb6822dbd3b
        registered copilot-cli session f4aa08cd-ae94-4c86-ac6a-54d386070d94 artifact: …/session-state/f4aa08cd-…/events.jsonl
```

Newest-mtime picks whichever sibling wrote its `events.jsonl` most recently. When A
registered, B had just written its tool-start event; when B registered, A had just finished.
The concurrent case with the var **set** was not run. Q3 showed that path resolves by id
(`session-state/$COPILOT_AGENT_SESSION_ID/events.jsonl`), so it is not mtime-dependent.

## Implications for a fix

- Agent-side `register` is exact whenever `COPILOT_AGENT_SESSION_ID` is present, and it always
  was (CLI ≥1.0.29). The mtime fallback is the real hazard (Q4). Make copilot-cli refuse or warn
  instead of binding by mtime, or bind by mtime only when exactly one session-state dir is live.
- Hook-side registration (`copilot` row `register=agent → hook`) is feasible from the sessionStart
  `sessionId`. The `copilot-state` derivation needs to use `${COPILOT_HOME:-$HOME/.copilot}` (it
  currently ignores `COPILOT_HOME`). It only works in trusted folders.
- The CLI fires **both** `.github/hooks/*.json` files. Gate the `copilot-vscode` adapter so it
  ignores CLI sessions, which currently produce a stray `copilot-vscode-<sid>.json` with a bogus
  chatSessions path. Signals available: the payload `transcript_path` sits under `session-state/`,
  or `COPILOT_CLI=1`. Note that `COPILOT_CLI` was confirmed in the agent shell only; it was not
  checked in the hook env.
- The CLI appears to run `.claude/settings.json` hooks too. If the Claude env leaks in (nested
  launch), those hooks register the parent Claude session. Without the leak, they log
  `no session artifact found for runtime=claude`. The Claude hooks should no-op when they are not
  inside Claude Code.
- Hooks never see `COPILOT_AGENT_SESSION_ID`. Identity inside a hook must come from the payload.

## Post-fix (s9)

Copilot CLI 1.0.96, probe clone `ws-identity-probe-s9` at 191944f. `gh copilot` runs the same
binary: its help says it executes the Copilot CLI found on `PATH`. Two pairs of `copilot -p
--allow-all-tools` sessions ran at once from a clean env, each running
`./probe-env.sh copilot-cli <label>` and then `sleep 20`.

- **Agent shell:** `COPILOT_AGENT_SESSION_ID` is each session's own id. `register` and `check`
  bound its own `session-state/<sid>/events.jsonl` (`method=exact`). One `copilot-cli-<sid>.json`
  per session, so four sessions gave four records.
- **Hooks: not exercised.** The clone is not in `~/.copilot/config.json` `trustedFolders`, so no
  repo hook fired (no copilot, copilot-vscode or claude hook log from these runs). Adding the
  folder there was blocked by the agent's permission classifier, so this is on the user
  checklist (accept the trust prompt in an interactive `copilot`).
- Not repeated: the pre-fix stray claude/copilot-vscode records, because hooks did not fire.

**User row 1 (interactive, trusted; sessions `d6716e02`, `ea38e6fe`; Homebrew `copilot` run inside a VS Code integrated terminal, so `VSCODE_*` env was present):** each agent shell
bound its own `events.jsonl` (`method=exact`). Hooks now fired. Each event still triggers
**three** hook configs: Copilot (`sessionId`), VS Code (`SessionStart`/`Stop`) and Claude's
PostToolUse, and every payload carried its own session's id. The guards held: only
`copilot-cli-<sid>.json` records were written, with no stray `copilot-vscode-*` or `claude-*`
record (the pre-fix bug).

**Result: PASS (agent side and hook side).**
