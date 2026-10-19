---
id: 03-investigate-duplicate-records
title: Investigate copilot-cli + copilot-vscode duplicate records; draft decision note
status: done
kind: work
wave: 1
blocked_by: []
sessions: [11]
---

## Goal

Each Copilot VS Code chat has two registry records with the same artifact:
`copilot-cli-<sid>.json` (written by the CLI hook config) and `copilot-vscode-<sid>.json`
(written by `register --runtime copilot-vscode`). Investigate, without changing code:
which path writes each; whether duplicates affect the ambiguity refusal (two chats, no id
var), `prune_phantoms`, `check` auto-detection or the status line; whether the hook payload
or env can tell VS Code from the terminal (`AI_AGENT`?). Draft a Tier-2 note with options
and a recommendation (for example: accept, canonicalise to one runtime name, or dedupe by
session id). The answer may depend on node 02.

## Acceptance

- [x] Writer of each record identified, with evidence
- [x] Effect on ambiguity refusal, pruning, `check` and status line tested or reasoned from code (cite lines)
- [x] Tier-2 note drafted in `decisions.md`: options, recommendation, rejected alternatives

## Log
- s11 · started, tier standard
- s11-b · writers: `copilot-cli-<sid>.json` = CLI hook config row `copilot` auto-register (scripts/hooks/context-budget-hook.sh:139-143, measure_as copilot-cli); `copilot-vscode-<sid>.json` = the agent's explicit `register --runtime copilot-vscode` in ~/Developer/experiments/ws-identity-probe-s9/probe-env.sh. The VS Code hook row writes nothing: SessionStart has no transcript_path (hook.sh:121-122), Stop's session-state path stands down (hook.sh:62-66); no hook-copilot-vscode-* state in the probe registry. Plain `register`/`check` auto-detect copilot-cli (context-budget.sh:402), so without `--runtime copilot-vscode` there is no twin
- s11-b · effects, sandbox run /private/tmp/claude-501/-Users-kashif-Developer-experiments-ai-workspace-template/248ccae3-ed62-4550-b490-bd51505eb29c/scratchpad/n03/sandbox.sh: ambiguity refusal unaffected (glob is runtime-prefixed, context-budget.sh:561; one chat → rc 0, two chats → rc 4 on both names); prune drops twins together, only when the artifact is gone (:895-902); auto `check` reads only the copilot-cli twin (:402, :535); status line is claude-only (statusline-context-budget.sh:34). Real harm found: work-item ownership splits: `register --runtime copilot-vscode --project P`, then auto `register --project P` of the same chat → `reason=owner_live`, not bound (:846, :854). Also `record` touches only its own twin (:983), so the other ages out at 7 days (:935)
- s11-b · VS Code vs terminal: only env `AI_AGENT=github_copilot_vscode_agent` tells them apart (in VS Code chat hook and tool shells; absent in terminal CLI even in the VS Code integrated terminal). Payload keys are the same on both surfaces; TERM_PROGRAM/VSCODE_*/__CFBundleIdentifier are not reliable
- s11-b · on disk: this Log, Acceptance boxes 1-2 ticked, sandbox script in scratchpad. Not on disk: the Tier-2 note (draft returned to the orchestrator to append to decisions.md; box 3 left unticked on purpose). No code or other file changed
- s11 · verified on disk (records in probe clone, no hook-copilot-vscode stamps, hook guard, detect_runtime); note appended to `decisions.md` as PROPOSED, box 3 ticked
- s11 · done
