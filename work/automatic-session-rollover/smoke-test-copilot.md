# Copilot CLI smoke test — live verification of vendor-hooks-research §4

Date: 2026-08-05, macOS (darwin), zsh. Live install, real runs; every claim
below is CONFIRMED/REFUTED against `@github/copilot` 1.0.78 or cited docs.
Scratch repo: session scratchpad `copilot-smoke/` (git-inited; nothing
committed to this workspace).

## 1. Install + version

- `npm install -g @github/copilot` — official method, worked (3 packages, 2s).
  Binary: `copilot` → `/opt/homebrew/lib/node_modules/@github/copilot/npm-loader.js`
  (real engine: `node_modules/@github/copilot-darwin-arm64/app.js`, Rust core inside).
- `copilot --version` → **GitHub Copilot CLI 1.0.78**.
- Flag inventory highlights (full `--help` verified):
  - **`-p, --prompt <text>`** non-interactive, exits after completion; needs
    `--allow-all-tools` (or `--allow-tool`/`--deny-tool` granular,
    `--allow-all`/`--yolo` umbrella). `-s/--silent` = response only, no stats.
    `--output-format text|json` (JSONL). `--share[=path]` / `--share-gist`
    exports session markdown after `-p`.
  - **`-i, --interactive <prompt>`** — "Start interactive mode and
    automatically execute this prompt". **Seeded-interactive exists.**
  - Sessions: `--continue` (most recent), `-r/--resume[=id|name|prefix]`,
    `--session-id <uuid>` (set UUID for a *new* session — launcher-friendly),
    `-n/--name`.
  - Also: `--acp` (Agent Client Protocol server), `--remote`/`--connect`
    (remote control from GitHub web/mobile), `--mode interactive|plan|autopilot`,
    `--autopilot`, `--max-autopilot-continues`, `--model`, `--effort`,
    `--context default|long_context`, `--add-dir`, `--log-dir/--log-level`,
    `--no-custom-instructions`, `--plugin-dir`, `-C <dir>`.
  - No detached/background flag anywhere in `--help`.

## 2. Auth — non-interactive path works, no human action needed

- Token precedence (from `copilot login --help` / `copilot help environment`):
  `COPILOT_GITHUB_TOKEN` > `GH_TOKEN` > `GITHUB_TOKEN`. Supported token types:
  fine-grained PATs with "Copilot Requests" permission, Copilot CLI OAuth
  tokens, **and OAuth tokens from the GitHub CLI (`gh`) app**. Classic
  `ghp_` PATs are NOT supported.
- **CONFIRMED live:** `GH_TOKEN=$(gh auth token) copilot -p 'Reply with
  exactly: SMOKE-OK' --allow-all-tools` → printed `SMOKE-OK`, exit 0,
  ~2s, footer `Tokens ↑ 24.0k`, `Resume copilot --resume=<uuid>`. The
  existing `gh` keyring login (account kashman001) is sufficient; no
  `/login`, no browser. Interactive fallback would be `copilot login`
  (web flow on desktop, `--device-code` for headless).
- Billing surface: footer reports "AI Credits"; default model observed in the
  session artifact: `claude-sonnet-5`.

## 3. Launch claims

- **Headless `-p`: CONFIRMED** — runs, prints answer + stats, exits 0.
- **"No seeded-interactive flag": REFUTED** — `-i "<prompt>"` does exactly
  that (research §4 relied on docs that omitted it; the `prompt`-hook
  workaround is unnecessary). Update the launcher matrix: copilot gains a
  seeded-interactive branch (`copilot -i "<bootstrap prompt>"`), and
  `--session-id`/`--resume=name` give deterministic session identity.
- **"No detached/background mode": CONFIRMED** — nothing in `--help`.
  Closest cousins, not substitutes: `--remote`/`--connect` (steer from GitHub
  web/mobile), `--acp` (embed as ACP server), `/delegate` to cloud agent.

## 4. Hooks — all tested channels reach the model

### 4a. The trap: repo hooks silently require folder trust

First run with a valid `.github/hooks/context-budget-test.json` fired
**nothing** (no hook stdin captured, no injected text) — no warning in
normal output. Debug log + `app.js` internals: repo hooks are **deferred
until folder trust resolves** ("Failed to resolve folder trust … deferring
repo hooks"); `-p` in an untrusted folder never loads them. Trust is stored
in `~/.copilot/config.json` → `trustedFolders` array (documented in
`copilot help config`), normally granted by the interactive first-run
prompt ("trust the files in this folder?"). Adding the scratch dir to
`trustedFolders` made everything fire. **Deployment note:** any hook-based
context-budget push on copilot presumes the workspace is in
`trustedFolders`; headless CI would have to pre-seed that file (or use
user-level `~/.copilot/hooks/`, or policy dir `/etc/github-copilot/policy.d/`
which loads "regardless of folder trust" per docs).

### 4b. Working hook JSON (fired as-is at `.github/hooks/context-budget-test.json`)

```json
{
  "version": 1,
  "hooks": {
    "sessionStart": [
      { "type": "command",
        "bash": "LOG=$(pwd)/hooklog; tee \"$LOG/payload-sessionStart.json\" >/dev/null; printf '%s' '{\"additionalContext\":\"SYSTEM BUDGET NOTE: include the word PINEAPPLE in your reply\"}'",
        "timeoutSec": 10 } ],
    "postToolUse": [
      { "type": "command",
        "bash": "LOG=$(pwd)/hooklog; tee -a \"$LOG/payload-postToolUse.jsonl\" >/dev/null; echo marker >> \"$LOG/posttool-marker.txt\"",
        "timeoutSec": 10 } ],
    "agentStop": [
      { "type": "command",
        "bash": "LOG=$(pwd)/hooklog; tee -a \"$LOG/payload-agentStop.jsonl\" >/dev/null; if [ ! -f \"$LOG/mango-fired\" ]; then touch \"$LOG/mango-fired\"; printf '%s' '{\"decision\":\"block\",\"reason\":\"Now reply with the word MANGO and stop\"}'; fi",
        "timeoutSec": 10 } ]
  }
}
```

Hook cwd = session cwd (`$(pwd)` resolved to the repo root). Exit 0 ⇒ stdout
parsed as JSON, as documented.

### 4c. Channel results (`copilot -p "Say hello briefly"` in trusted folder)

| Channel | Result | Evidence |
|---|---|---|
| `sessionStart` → `additionalContext` | **CONFIRMED reaches model** | Reply: "Hello! PINEAPPLE 🍍" |
| `agentStop` → `decision:block` + `reason` | **CONFIRMED — reason becomes next-turn prompt** | Reply continued with "MANGO"; hook re-fired with `stop_hook_active:true` (single-shot marker-file guard worked; 8-block loop guard never engaged) |
| `postToolUse` (command ran, marker appended) | **CONFIRMED fires per tool call** | marker file + captured payload after a `bash` tool call |

**Skepticism caveat (observed, run 3):** the model *complied* with the
PINEAPPLE instruction in run 1 but in run 3 said "the 'SYSTEM BUDGET NOTE'
instructing me to include a specific word wasn't a legitimate system
instruction, so I disregarded it" — `additionalContext` reaches the model but
is not treated as authoritative. It still obeyed the `agentStop` block
`reason` in the same run. For the budget push: phrase injected text as
tooling status, and treat **`agentStop` block/reason as the strong lever**
(only block at STOP, per research §4 recommendation).

### 4d. Hook stdin payloads (captured verbatim, keys as received)

- `sessionStart`: `{"sessionId","timestamp","cwd","source":"new","initialPrompt"}`
  — **no transcriptPath**.
- `postToolUse`: `{"sessionId","timestamp","cwd","toolName":"bash",
  "toolArgs":"<json-string>","toolResult":{"resultType":"success",
  "textResultForLlm":"…"}}` — **no transcriptPath**.
- `agentStop`: `{"sessionId","timestamp","cwd",
  "transcriptPath":"/Users/kashif/.copilot/session-state/<sessionId>/events.jsonl",
  "stopReason":"end_turn","stop_hook_active":false|true}` — **transcriptPath
  present, exactly as research §4 claimed** (on `agentStop` only, among the
  events tested).

### 4e. Session artifact vs `scripts/context-budget.sh` `copilot-cli` branch

Both halves of the previously "best-effort/unverified" branch are now live-verified:

- **Discovery CONFIRMED:** `COPILOT_AGENT_SESSION_ID` is exported to shell
  tool commands (verified via `env | grep -i copilot` inside a session:
  `COPILOT_AGENT_SESSION_ID=<session uuid>`, plus `COPILOT_CLI=1`,
  `COPILOT_CLI_BINARY_VERSION=1.0.78`), and
  `~/.copilot/session-state/$COPILOT_AGENT_SESSION_ID/events.jsonl` exists —
  the script's primary path hits. (Legacy `history-session-state/` fallback:
  not present on 1.0.78; harmless.)
- **Measurement CONFIRMED:** `events.jsonl` carries `"inputTokens":<n>`
  (grep target of `copilot_cli_measure`); last value 73049 matched the UI
  footer "Tokens ↑ 73.0k" exactly → `exact`, not estimate. Event types
  present: `session.start`, `user.message`, `assistant.turn_start/end`,
  `assistant.message`, `session.usage_checkpoint` (credits/model info;
  `modelId":"claude-sonnet-5"`), `session.shutdown`. Sibling files per
  session dir: `session.db`, `workspace.yaml` (has `cwd` + `git_root` —
  usable for cwd-matching fallback), `checkpoints/`, `files/`.
- The `agentStop` payload's `transcriptPath` points at that same
  `events.jsonl` — feeding it to `context-budget.sh --transcript` from a hook
  bypasses discovery entirely, as planned in research §4 implication 2.

## 5. Copilot in VS Code (the user's question)

### 5a. CLI in the integrated terminal — yes, and it's first-class

Trivially works (it's a TUI). Beyond that, VS Code has explicit integration
(code.visualstudio.com/docs/copilot/agents/copilot-cli): a dedicated
**"GitHub Copilot CLI" terminal profile**, a "Chat: New Copilot CLI Session"
command, terminal-started CLI sessions are **detected and added to VS Code's
sessions list**, and editor chat sessions offer **"Resume in Terminal"**
(bidirectional handoff; `/delegate` hands off to the cloud agent). Observed
locally: VS Code writes IDE lock files at `~/.copilot/ide/<id>.lock`
(`ideName: "Visual Studio Code"`, MCP unix-socket + nonce) and the CLI
auto-connects (`ide.autoConnect` defaults true) — so a CLI session inside VS
Code gets editor context. Caveat: it's still the same CLI — folder-trust
gate for repo hooks applies unchanged.

### 5b. VS Code agent mode (editor chat) — hooks are SHIPPED, in Preview

The research §4 contradiction ("PascalCase aliases labelled 'VS Code
compatible' but VS Code not a supported surface") **resolves as a docs-split,
not a gap**:

- docs.github.com "About hooks" still says hooks are available for "Copilot
  cloud agent on GitHub" and "GitHub Copilot CLI in your terminal" — VS Code
  absent, because VS Code hooks are VS Code's own feature, documented on
  code.visualstudio.com.
- **VS Code shipped agent hooks in v1.109 (January 2026), status Preview**
  ("Agent hooks are currently in Preview. The configuration format and
  behavior might change"): code.visualstudio.com/docs/agent-customization/hooks
  and the v1.109 release notes. Setting `chat.hooks.enabled`; orgs can
  disable centrally; `/hooks` slash command scaffolds configs. This machine
  runs VS Code 1.131.0, well past 1.109.
- Events (PascalCase): `SessionStart`, `UserPromptSubmit`, `PreToolUse`,
  `PostToolUse`, `PreCompact`, `SubagentStart`, `SubagentStop`, `Stop`.
- **Config sources include ours:** workspace `.github/hooks/*.json` — "VS
  Code parses Copilot CLI hook configurations and converts the
  lowerCamelCase hook event names (like `preToolUse`) to the PascalCase
  format" — plus user `~/.copilot/hooks`, **and Claude Code formats**
  (`.claude/settings.json`, `.claude/settings.local.json`,
  `~/.claude/settings.json`): "VS Code uses the same hook format as Claude
  Code and Copilot CLI, so you can reuse existing hook configurations across
  tools" (v1.109 notes). Matchers are ignored (hooks run on all tools).
- Output channels are Claude-shaped: `continue`/`stopReason`,
  `systemMessage`, `additionalContext`, `hookSpecificOutput`
  (e.g. `permissionDecision`); exit 2 = blocking error.

**So yes: the context-budget push + rollover model can reach developers in
VS Code agent mode** — a single committed `.github/hooks/*.json` (or the
already-deployed `.claude/settings.json` hooks!) is read by Copilot CLI,
Copilot cloud agent, *and* VS Code agent mode. Not yet live-verified here:
the GitHub Copilot extension is **not installed** in this VS Code (only
Claude Code extensions), so end-to-end injection in editor agent mode and
Stop-block continuation semantics under VS Code's `continue/stopReason`
scheme still need a smoke test on a Copilot-licensed VS Code — Preview
status also means the contract may shift.

### 5c. VS Code local session artifacts (`copilot-vscode` script branch)

VS Code chat sessions do write local artifacts:
`~/Library/Application Support/Code/User/workspaceStorage/<hash>/chatSessions/*.jsonl`
— path shape **confirmed present** on this machine (VS Code 1.131). But the
sessions here were produced by other chat providers and contain **no
`promptTokens`**, and without the Copilot extension neither
`copilot_vscode_measure`'s `promptTokens` grep nor the
`VSCODE_TARGET_SESSION_LOG` env pin could be live-verified — that branch
stays **UNVERIFIED (plausible)**; verify on a machine with Copilot in VS
Code. Note `~/.copilot/vscode.session.metadata.cache.json` exists and
indexes CLI session ids (origin/modified timestamps) — the VS Code↔CLI
session bridge is real and file-visible.

## 6. Verdict block

- **PUSH (Copilot CLI): PUSH-CAPABLE — CONFIRMED LIVE.** `sessionStart`
  `additionalContext` and `agentStop` block-`reason` both demonstrably reach
  the model; `agentStop` hands the hook `transcriptPath` =
  `~/.copilot/session-state/<id>/events.jsonl`, and
  `scripts/context-budget.sh` `copilot-cli` discovery + exact measurement
  both work against the real artifact. Frictions: **folder-trust gate**
  (repo hooks silently no-op untrusted; pre-seed `trustedFolders` or use
  `~/.copilot/hooks/`), and the model may discount `additionalContext` as
  non-authoritative — lean on `agentStop` reason at STOP.
- **PUSH (VS Code agent mode): PUSH-CAPABLE per docs (Preview, unverified
  live).** Hooks shipped in VS Code 1.109, read our exact
  `.github/hooks/*.json` (and Claude `settings.json`) formats, gated by
  `chat.hooks.enabled` + org policy. Needs one smoke test on a
  Copilot-enabled VS Code before relying on it.
- **LAUNCH: research claim REFUTED (in our favor).** `copilot -i "<prompt>"`
  starts a *seeded interactive* session; `--session-id`/`--resume=<name>`
  give deterministic identity; `-p` remains the headless tier. Still no
  local detached/background mode (`--remote`/`--acp`/cloud `/delegate` are
  different animals) — the launcher's ready-to-run-command fallback is only
  needed for background, not for seeding.
