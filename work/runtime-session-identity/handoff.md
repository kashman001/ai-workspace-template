<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 2026-10-12 (session 4: VS Code probes; plan 01 created)

The user ran the Codex and Copilot VS Code probes in `~/Developer/experiments/ws-identity-probe`.
Written up in `probes/codex-vscode.md` and `probes/copilot-vscode.md`, folded into
`findings.md` (summary + nodes 5, 8a–8d). Then created plan
`plans/01-session-identity-fixes` (16 nodes, 5 waves); `check` is silent. Commit `1d51030`.

- **Codex VS Code:** like the CLI. Trust prompt comes after the turn, then applies to
  open chats; sandbox blocks `ps` (`pid: null`).
- **Copilot VS Code:** runs on the Copilot CLI runtime now; the copilot-vscode adapter
  registers a nonexistent `~/.copilot/chatSessions/<sid>.jsonl` and never measures; three
  hook configs fire per event (VS Code, CLI, Claude Stop).
- **Claude Code extension:** pre-spawns two idle sessions → phantom records.
- `make-ide-probe-clone.sh` now also wraps the Stop hook (it was missing).
- Decision (`decisions.md`): the remaining-probes hitl node sits in wave 3.
- Not run: Antigravity IDE/app and Codex desktop app probes (now node 11).

Suggested skills: `plan` (reconcile nodes), `tdd` (each node's suite cases).

# Session Handoff — 2026-10-12 (session 3: Antigravity CLI probe)

Probed `agy` 1.3.3 in a scratch clone → `probes/antigravity-cli.md`. Hooks
live in `.agents/hooks.json` (spec found embedded in the binary), fire with no
trust step, and every payload carries `conversationId` + `transcriptPath`; hook
processes also get `ANTIGRAVITY_CONVERSATION_ID`. No SessionStart event: the
first `PreInvocation` (`invocationNum: 0`) stands in. Two concurrent runs each
got their own id on the hook side. `register` auto-detects Antigravity as
gemini and binds a stale `logs.json` while reporting OK. Q1 (agent's shell) is
blocked: headless `agy` auto-denies `run_command`, hook `permissionOverrides`
don't lift it, and the Claude Code classifier denied
`--dangerously-skip-permissions`. Rewrote draft node 6 as "Antigravity: add as
a runtime" and added the Antigravity column to `findings.md`. Then the user
ran the skip-permissions command: Q1 = YES (`ANTIGRAVITY_CONVERSATION_ID`,
`ANTIGRAVITY_APP_DATA_DIR` in the agent's shell). Because `agy` was launched
from Claude Code, `register` inside it bound the parent Claude session:
`detect_runtime` lets an inherited `CLAUDECODE` win. That is now part of node 6
and node 4's check. IDE probes still waiting on the user.

Suggested skills: `plans` (once IDE probes land), `diagnosing-bugs` for probes.
Committed: `46666f6`, `b32ecac`, `97e2f93` (main, 3 ahead of origin, unpushed).

Learnings:
- `agy` headless (`-p`) auto-denies `run_command` unless the global settings
  allow-list or `--dangerously-skip-permissions` permits it; hook
  `permissionOverrides` don't help. The Claude Code classifier blocks the skip
  flag, so the user has to run that command.
- Its hook spec is only in the binary (`strings agy` → "Lifecycle Hooks").

