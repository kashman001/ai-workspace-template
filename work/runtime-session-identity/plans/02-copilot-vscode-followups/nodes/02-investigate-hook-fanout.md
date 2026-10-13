---
id: 02-investigate-hook-fanout
title: Investigate the four hook sets per Copilot event; draft decision note
status: todo
kind: work
wave: 1
blocked_by: []
sessions: []
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

- [ ] Behaviour of each of the four hook sets on a Copilot payload recorded, with evidence paths
- [ ] Which hook files Copilot CLI (terminal) and Copilot VS Code each load, verified
- [ ] Tier-2 note drafted in `decisions.md`: options, recommendation, rejected alternatives

## Log
