---
id: 02-investigate-hook-fanout
title: Investigate the four hook sets per Copilot event; draft decision note
status: done
kind: work
wave: 1
blocked_by: []
sessions: [11]
---

## Goal

Every Copilot VS Code event runs four hook sets: `.github/hooks/context-budget.json`
(CLI config, measures as `copilot-cli`), `.github/hooks/context-budget-vscode.json`, and
Claude Code's `Stop` and `PostToolUse` hooks from `.claude/settings.json`, all with a Copilot
payload (s10 rerun, `probe-out/hook-*.log`). Investigate, without changing code:
what each set does with that payload (writes, stamps, records, `claude` misattribution risk);
whether Copilot CLI in a terminal also reads `.claude/settings.json` and the VS Code config;
which VS Code / Copilot settings control which files load. Then draft a Tier-2 note in
`decisions.md` with options and a recommendation (for example: keep one Copilot config,
make the Claude shims refuse a Copilot payload).

## Acceptance

- [x] Behaviour of each of the four hook sets on a Copilot payload recorded, with evidence paths
- [x] Which hook files Copilot CLI (terminal) and Copilot VS Code each load, verified
- [x] Tier-2 note drafted in `decisions.md`: options, recommendation, rejected alternatives

## Log
- s11 · started, tier standard
- s11-a · four sets per Copilot event confirmed from ~/Developer/experiments/ws-identity-probe-s9/probe-out/hook-*.log + .context-budget/: CLI config acts (hook-copilot-cli-<sid>.stamp/.status=OK, copilot-cli-<sid>.json at sessionStart time); VS Code config, Claude Stop and Claude PostToolUse all exit silent at scripts/hooks/context-budget-hook.sh:62-67 / :110 (no hook-claude-*, hook-copilot-vscode-* stamps, no claude-<sid> record); Claude SessionStart/SessionEnd inline commands (.claude/settings.json:9,:31) unwrapped, inferred no-op (Copilot payloads carry no transcript_path, events.jsonl hook.start inputs)
- s11-a · loading verified: terminal Copilot CLI 1.0.96 interactive (d6716e02, ea38e6fe) and VS Code chats on the CLI agent host (d5d80a4e, 90bc99b7; workspace.yaml client_name vscode-agent-host) both run .github/hooks/*.json (both files) + .claude/settings.json, with CLAUDE_PROJECT_DIR set; `copilot -p` in an untrusted folder (018beebd) ran none. VS Code Local harness: inferred only from VS Code 1.141 source (chat.hookFilesLocations defaults, chat.useClaudeHooks default false, camelCase->PascalCase map), no live log
- s11-a · Tier-2 note drafted in the final report only (decisions.md untouched); Acceptance box 3 left unticked for the orchestrator. On disk: this Log + two ticked boxes. Not on disk: the decisions.md note, any code change
- s11 · verified on disk (`.claude/settings.json` :9/:31 inline commands, CLAUDE_PROJECT_DIR in 21 stop-hook log lines, no `claude-events` record, doc claim present); note appended to `decisions.md` as PROPOSED, box 3 ticked
- s11 · done
