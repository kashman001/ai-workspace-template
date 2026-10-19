---
id: 05-approve-decisions
title: User picks options for hook fan-out and duplicate records
status: done
kind: hitl
wave: 2
blocked_by: [04-reconcile-w1]
sessions: [12]
---

## Goal

The user reads the two Tier-2 notes from nodes 02 and 03 and picks an option for each
(one question at a time, plain terms). Answer: `plan.sh done 05-approve-decisions --by human`
with the choices in the Log, or `drop` to stop after fix 1.

## Acceptance

- [x] Hook fan-out option chosen
- [x] Duplicate-records option chosen
- [x] Live (moved from node 01): user opens a new Copilot VS Code chat in `~/Developer/experiments/ws-identity-probe-s9` (has the fix, d93e71a); its `check` reports `method=exact`

## Log

- s12: Q1 hook fan-out → **A + both hardenings** (keep all four hook files; route the Claude
  `SessionStart`/`SessionEnd` inline commands through the session-state check; hooks-suite case for
  Claude `PostToolUse` with a Copilot payload; fix the `CLAUDE_PROJECT_DIR` sentence in
  `docs/context-budget.md`). User asked for an explanation first, then chose it.
- s12: Q2 duplicate records → **(b) canonicalise to copilot-cli**; update `probe-env.sh` and test H2.
- s12: Q3 live — new VS Code Copilot chat in the probe clone (d93e71a), session
  `bec02542-7ce7-47fd-9d02-cc42de4edbcc`. Turn 1 `check`: `method=estimate tokens=29783` — its
  `events.jsonl` had no `prompt_tokens` yet (the only `session.usage_checkpoint` was line 29, written
  at turn end; the check ran at line 20). Turn 2 `check`: `method=exact tokens=42654`; a new
  checkpoint (`prompt_tokens` 42838) followed at turn end, so it refreshes per turn. PASS from turn 2.
  New gap: turn 1 of every Copilot VS Code chat is an estimate, ~30% low (29,783 vs 42,654).
- s12 · started, tier frontier
- human · done
