---
id: 06-one-hook-per-copilot-event
title: One hook config per Copilot event (nodes 3 + 8b)
status: doing
kind: work
wave: 2
blocked_by: [02-reconcile-w1]
sessions: [6]
---

## Goal

Findings: `work/runtime-session-identity/findings.md` → "Gaps", node 3 and 8b. Evidence: `probes/copilot-cli.md`, `probes/copilot-vscode.md`.

One Copilot turn fires three hook configs: `.github/hooks/context-budget-vscode.json`,
`.github/hooks/context-budget.json` (CLI) and `.claude/settings.json` `Stop` (as `claude`).
Make exactly one act per event: the claude entry and the duplicate copilot entry refuse a
Copilot payload (e.g. a `.copilot/session-state/` transcript path or the payload shape).

## Acceptance

- [x] Suite case: a Copilot payload into the claude Stop shim writes no claude stamp or record
- [x] Suite case: one Copilot turn's payloads through all three configs leave exactly one stamp
- [x] Existing suites pass

## Log
- s6 · started, tier standard
- s6-d · red: K section appended to scripts/tests/test-vendor-budget-hooks.sh; K1a/K1b (claude Stop shim SIGTERMs as claude on a Copilot payload), K1d (claude SessionStart registers on a Copilot payload), K2a-c (two stamps + a copilot-vscode register per Copilot turn) seen FAILING before the fix (pass=155 fail=6)
- s6-d · green: scripts/hooks/context-budget-hook.sh refuses a payload whose transcript_path is */session-state/<sid>/events.jsonl as claude (always) and as copilot-vscode (while .github/hooks/context-budget.json is installed), so the CLI config (copilot row -> copilot-cli) is the one actor; .claude/settings.json SessionStart now skips register when the payload has no transcript_path (Copilot's SessionStart never carries one; Claude's always does). K1a-f, K2a-e pass; test-vendor-budget-hooks pass=161 fail=0
- s6-d · Copilot CLI inside a VS Code terminal: the hook side is payload-only (hooks never see COPILOT_AGENT_SESSION_ID; the refusal reads only the payload and the CLI config file), so terminal env (TERM_PROGRAM=vscode, VSCODE_TARGET_SESSION_LOG, leaked CLAUDECODE/CLAUDE_CODE_SESSION_ID) cannot change which config acts: the CLI config acts (K1d covers the leaked-Claude-env SessionStart). Agent side checked by hand: COPILOT_AGENT_SESSION_ID + VSCODE_TARGET_SESSION_LOG + CLAUDECODE + TERM_PROGRAM=vscode -> scripts/context-budget.sh check resolves runtime=copilot-cli on session-state/<sid>/events.jsonl, matching the hook's copilot-cli stamp
- s6-d · cross-node: node 05 makes copilot-vscode register session-state transcripts; after this node that path runs only when .github/hooks/context-budget.json is absent (K2e). A node-05 suite case firing copilot-vscode with a session-state payload in a workspace that has the CLI config is refused by design; reconcile 08 should check that
- s6-d · every context-budget suite under scripts/tests/ (18 files) exits 0: registry 211/0, vendor hooks 161/0, session-loop 149/0, launch-next-session 188/0, probe-twins rc 0
- s6-d · merged main (nodes 04 + 05 landed; clean auto-merge of scripts/hooks/context-budget-hook.sh): node 05's H1 (registry suite) still passes only because its workspace carries no .github/hooks/context-budget.json, so with the committed CLI config a CLI-runtime VS Code turn is measured as copilot-cli, never copilot-vscode; this also closes node 05's "two records, one session" side finding at the hook side. All 18 context-budget suites exit 0 after the merge (registry 223/0, vendor hooks 161/0)
- s6-d · done: on disk (branch worktree-agent-a02e079124bd0fd3d) the dispatcher refusal, the Claude SessionStart transcript_path guard, K1a-f/K2a-e. Not on disk: no docs/context-budget.md change (node 13), no live re-probe in Copilot CLI or VS Code, no change to the .github/hooks files (both still fire; the refusal is in the dispatcher)
