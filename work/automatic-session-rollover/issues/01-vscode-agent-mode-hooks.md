# 01 — Verify VS Code agent-mode hooks + `copilot_vscode_measure` on a Copilot-licensed machine

Type: task
Status: open — **UNBLOCKED 2026-08-06** (see update below)

## Why spun out

Everything else in the detection scope was verified live on this machine
(smoke tests in `../smoke-test-opencode.md` and `../smoke-test-copilot.md`);
this piece can't be: it needs a VS Code install with a licensed Copilot
extension, which the origin machine doesn't have. VS Code agent-mode hooks
also shipped only in v1.109 as **Preview**, so the contract may shift before
verification. Decision provenance: `../decisions.md` → "Detection + runtime
scope after smoke tests (session 3)"; ADR-0004.

## What to verify

1. **Agent-mode hooks fire.** Wire a minimal hook per the v1.109 agent-mode
   hooks contract (see `../vendor-hooks-research.md` → VS Code section) and
   confirm a WARN/STOP push can reach an agent-mode session in-band —
   the equivalent of the copilot CLI `sessionStart` `additionalContext` /
   `agentStop` block-`reason` channels confirmed in `../smoke-test-copilot.md`.
2. **`copilot_vscode_measure` is exact.** The adapter branch in
   `scripts/context-budget.sh` (chatSessions `promptTokens` grep — see
   `docs/context-budget.md` per-runtime table, "Copilot VS Code" row) is
   plausible but unverified on current builds; compare its output against the
   live session UI the way copilot-cli was verified (73.0k exact match).

## Update 2026-08-06 — blocker lifted; scope grows one item

- **The origin machine now qualifies:** the user confirmed a **Copilot Pro
  license** active in their VS Code Copilot session on this machine
  (VS Code 1.132.0 installed). "Needs a Copilot-licensed machine" no longer
  defers this ticket — schedule it as normal work when wayfinder tickets
  06–08 are done.
- **New third item — copilot-vscode seeded relaunch via `code chat`.**
  VS Code 1.132's CLI ships a `code chat [options] [prompt]` subcommand
  (`-m ask|edit|agent|<custom>`, defaults to `agent`; `-r` reuse last
  window; `-a` add file context; stdin via trailing `-`). CLI presence +
  flag surface verified on this machine 2026-08-06 (`code chat --help`);
  end-to-end (does the seeded agent session actually start and run?) is
  unverified — same live-verification pass as items 1–2. If it works,
  `launch-next-session.sh`'s `copilot-vscode` branch upgrades from
  note-and-punt ("paste the prompt into VS Code agent mode") to seeded
  interactive: `CMD=(code chat -r -m agent "$PROMPT")` — same tier as
  codex/gemini/opencode/copilot-cli. Add a W-test + docs
  (`docs/context-budget.md` relaunch-knobs section, `relaunch-analysis.md`
  table row) with the verification.
- A live copilot-vscode agent-mode session on this work item doubles as the
  item-2 verification vehicle: its `register`/`check` output line is exactly
  the `copilot_vscode_measure` evidence needed (compare tokens against the
  session UI, like copilot-cli's 73.0k match).

## Update 2026-08-06 (session 26) — item 2 first live attempt: NEGATIVE result

First run of the item-2 verification in a live Copilot Chat agent-mode
session (Copilot Pro, Sonnet 5, this machine, relayed by the user):

- `check --runtime copilot-vscode` found **no session artifact** —
  `copilot_vscode_discover` came up empty in a live agent session. Not yet
  diagnosed: whether `VSCODE_TARGET_SESSION_LOG` was unset in the agent's
  terminal, or no `workspaceStorage/*/chatSessions/*.jsonl` matched the cwd
  (current builds may have moved/renamed the store, or the session hadn't
  flushed). Note the copilot agent itself mis-attributed the miss to "a
  usage-tracking hook not having written its file" — discovery reads
  VS Code's own chatSessions logs, no hook involved.
- Independent constraint confirmed by the agent: it cannot introspect its
  own token/context usage (no tool or readable UI surface) — so the
  UI-comparison leg needs the USER to read the number visually, as with
  the copilot-cli 73.0k match.
- Diagnostic ran (user relay + claude-side probe), and the story flipped:
  **the measure branch WORKS on current builds; only the in-copilot
  environment is broken.** From the copilot agent's terminal:
  `VSCODE_TARGET_SESSION_LOG` UNSET, and `ls` of
  `workspaceStorage/*/chatSessions/` returned NOTHING. From a normal shell
  (claude session, same user): the store exists exactly where
  `copilot_vscode_discover` expects — workspace `d939e947…` with
  `workspace.json` matching this workspace root, live session log
  `chatSessions/89e4a886-….jsonl` carrying `promptTokens`. So the copilot
  agent's shell either sandboxes `~/Library` reads or runs with a different
  HOME — the discovery failure is scoped to *checks run from inside the
  copilot session*, not to the adapter.
- **Item-2 measure verification (2026-08-06, VS Code 1.132.0, Copilot Chat
  agent mode, Sonnet 5):** `check --runtime copilot-vscode --transcript
  <live chatSessions jsonl>` → `method=exact tokens=38680` while the
  session was live and mid-conversation. Remaining leg: compare against a
  UI-visible number (the agent cannot introspect its own usage — the user
  must read the UI meter, if any). Consequence for the vendor-hook wiring:
  a copilot-vscode session CANNOT self-measure from its own terminal
  (env + `~/Library` visibility) — measurement must run from outside
  (another session/watcher), or the hook contract must deliver the
  artifact path in-band (item 1 territory).

## Update 2026-08-06 (session 27) — sandbox discovery fix implemented

The user-approved fix spec (`work/context-decay/
copilot-vscode-sandbox-discovery-fix.md`) is implemented in
`copilot_vscode_discover()`: the workspaceStorage hash is now derived from
`$VSCODE_TARGET_SESSION_LOG` by parameter expansion and the token file
probed directly (`workspaceStorage/<hash>/chatSessions/<sid>.jsonl`), no
`readdir` on `workspaceStorage/` — the glob-and-grep scan remains as the
fallback for older builds. Verified with a fake-HOME harness including a
`chmod 311` readdir-blocked parent (sandbox simulation, 7/7 checks) and
the full `scripts/tests/` suite (326 asserts green).

**In-copilot live verification (2026-08-06, same VS Code instance,
user-relayed): PASS.** The copilot agent exported
`VSCODE_TARGET_SESSION_LOG` (value taken from its session context —
confirmed visible there but not exported to its shell) and ran
`register`/`check --runtime copilot-vscode` from its sandboxed terminal:
discovery pinned the correct artifact
(`workspaceStorage/d939e947…/chatSessions/53e98f5e-….jsonl`, basename =
session id) with no `workspaceStorage/` listing. It reported
`method=estimate tokens=530` — not a defect: the check ran mid-first-turn
before copilot's usage flush (file was ~2.1 KB, size/4 fallback); after
the turn flushed, the same file carries `promptTokens:38152` and
`copilot_vscode_measure` returns `38152 exact`. Estimate-until-first-flush
is the designed degrade. Only optional leg left: comparing tokens against
a UI-visible meter (none reported so far).

## Update 2026-08-06 (session 28) — items 1 + 3 VERIFIED live; build spec

Verified on VS Code 1.132.0 (Copilot Chat built in — `code --list-extensions`
lists no copilot extension), macOS, Copilot Pro, model claude-sonnet-5.
Method: temporary probe hook (`.github/hooks/vscode-probe.json` +
`scripts/hooks/vscode-hook-probe.sh`, both since deleted) logging every
invocation to `.vscode-hook-probe.jsonl`, driven by three `code chat`
seeded sessions launched from a claude agent shell.

**Item 3 — `code chat` seeded launch: WORKS.**
`code chat -r -m agent "<prompt>"` from a non-interactive agent shell exits
0 immediately and opens a NEW agent session in the last-active window that
runs the prompt (sids `265779c4`, `b38a7f09`, `e901add4`). Note: returns
before the session responds — launcher BG confirm-loop pattern applies.

**Item 1 — agent-mode hooks: FIRE, with this verified contract:**
- Config: `.github/hooks/*.json`, **PascalCase** events, `{"type":"command",
  "command":…, "timeout":…}` (docs: also cwd/env + windows/linux/osx
  overrides). Probe used absolute command paths; relative-path resolution
  (repo-relative like the CLI json?) NOT yet verified.
- Events seen firing: `SessionStart`, `UserPromptSubmit`, `PostToolUse`,
  `Stop` (incl. chained Stop with `stop_hook_active:true`).
- Payload: **snake_case Claude-style** — `session_id`, `transcript_path`,
  `cwd`, `hook_event_name`, `timestamp`; + `model`/`source` (SessionStart),
  `prompt` (UserPromptSubmit), `tool_name` (PostToolUse),
  `stop_hook_active` (Stop). CLI payloads are camelCase (`sessionId`) —
  clean runtime discriminator for shared hook files.
- `transcript_path` → `…/workspaceStorage/<hash>/GitHub.copilot-chat/
  transcripts/<sid>.jsonl` — message log, NO token counts. The measurable
  artifact is derivable: `<3×dirname>/chatSessions/<sid>.jsonl` (confirmed
  live: promptTokens=36699 for sid 265779c4). **This dissolves the
  self-measure blocker from item 2** — no env export, no sandbox issue:
  the hook process reads `~/Library` fine.
- In-band channels verified:
  - `SessionStart` stdout `{"hookSpecificOutput":{"additionalContext":…}}`
    → model-visible (run 1 ACKed the marker verbatim).
  - `Stop` + **exit code 2 + stderr** → forces one continuation turn whose
    instruction is the stderr text (run 3 ACKed; chained Stop arrives with
    `stop_hook_active:true`). **JSON `{"decision":"block","reason":…}` on
    Stop is IGNORED** (run 2) — exit-2 is the only working block channel.
  - `PostToolUse` `hookSpecificOutput.additionalContext`: fires but marker
    NOT visible to the model — do not rely on it.
- Behavioral caveat: in run 3 the model saw the SessionStart marker and
  **refused it as prompt injection** ("a fake hook… I ignored it"). The
  canonical WARN/STOP text should read as tooling status (it does), but
  expect occasional discounting; the Stop exit-2 channel proved more
  authoritative (obeyed in the same run).
- `$CLAUDE_PROJECT_DIR` is UNSET in VS Code hook processes — the repo's
  `.claude/settings.json` claude hooks no-op harmlessly if VS Code loads
  them (default `chat.hookFilesLocations` includes `.claude/settings.json`).

**Build spec (agreed, session 28):**
1. `scripts/hooks/context-budget-copilot-vscode-hook.sh` — mirrors the
   copilot-cli wrapper: guard `session_id` snake_case non-empty (excludes
   CLI); derive chatSessions path from `transcript_path`+`session_id`, exit
   0 if absent (fail-open); `budget_hook_check copilot-vscode <sid> <cs>`;
   `SessionStart` → `hookSpecificOutput.additionalContext` WARN/STOP;
   `Stop` → guard `stop_hook_active`, then ONLY at STOP: message to stderr
   + exit 2.
2. `.github/hooks/context-budget-vscode.json` — PascalCase `SessionStart` +
   `Stop` → that script. Use absolute-vs-relative command per the cwd
   verification below.
3. OPEN: verify hook-process cwd / relative command resolution (probe v4:
   log `pwd`, wire one relative-path entry) before choosing the command
   form in (2).
4. `launch-next-session.sh` copilot-vscode branch → `CMD=(code chat
   ${OPT_ARGS[@]+"${OPT_ARGS[@]}"} -r -m agent "$PROMPT")`, replacing
   note-and-punt.
5. Tests: W-test (dry-run argv for `--runtime copilot-vscode`) + vendor
   T9 block (SessionStart WARN envelope; Stop WARN silent; Stop STOP rc=2
   + stderr text; `stop_hook_active` guard; camelCase-payload guard;
   missing-chatSessions fail-open) using the fake workspaceStorage tree.
6. Docs: `docs/context-budget.md` (per-runtime table Copilot VS Code row —
   hook-provided path route; vendor hook deployments section; relaunch
   knobs), `relaunch-analysis.md` seeded-launch row, backlog card.

## Update 2026-08-06 (session 29) — probe v4 verified; build SHIPPED. DONE.

**Spec step 3 (probe v4, the one open leg) — verified live:** wired one
repo-relative command entry (`scripts/hooks/vscode-hook-probe.sh
UserPromptSubmit-REL`) alongside the absolute SessionStart control, drove one
`code chat -r -m agent` seeded session (sid `c9efe334`). Results:
- **Relative command resolution WORKS** (the `-REL` entry fired).
- **Hook-process cwd = workspace root** (`pwd` logged as the repo root,
  matching the payload's `cwd`).
- VS Code re-read the hook JSON with **no window reload** (config change took
  effect on the next `code chat` session).
- `$CLAUDE_PROJECT_DIR` still UNSET (consistent with session 28).

**Build (steps 1–2, 4–6) shipped:**
- `scripts/hooks/context-budget-copilot-vscode-hook.sh` — snake_case
  `session_id` guard (CLI camelCase exits harmlessly); chatSessions path
  derived from `transcript_path` (3×dirname); fail-open when absent;
  SessionStart → `hookSpecificOutput.additionalContext` WARN/STOP; Stop →
  `stop_hook_active` guard, STOP-only stderr + exit 2.
- `.github/hooks/context-budget-vscode.json` — PascalCase `SessionStart` +
  `Stop`, **repo-relative** commands (per probe v4).
- `launch-next-session.sh` — copilot-vscode `CMD=(code chat … -r -m agent
  "$PROMPT")`, always routed through the BG confirm loop (detached by
  nature); the `--bg` claude-only guard exempts copilot-vscode.
- Tests: vendor T11 block (12 asserts, fake workspaceStorage tree) and
  launcher T22 (dry-run argv + implied bg) — full suites green.
- Docs: `docs/context-budget.md` (runtime-table hook route, vendor
  deployments row, relaunch knobs, known-limitations), CONTEXT.md
  (five→six runtimes), `relaunch-analysis.md`, backlog changelog row.

**Versions (per Done-when):** VS Code 1.132.0 (Copilot Chat built in —
`code --list-extensions` lists no separate copilot extension), macOS,
Copilot Pro, model claude-sonnet-5. Probe files
(`scripts/hooks/vscode-hook-probe.sh`, `.github/hooks/vscode-probe.json`,
`.vscode-hook-probe.jsonl`) are disposable — delete from the main checkout.

## Done when

- All three checks pass on a Copilot-licensed machine (note VS Code +
  extension versions in this file), or findings recorded here and the
  adapter/docs/launcher amended to match reality.
  **→ MET (sessions 28–29, versions above). Ticket CLOSED.**
