<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 11 (2026-10-18) (session 11: plan 02 wave 1 — exact Copilot count, two notes proposed)

**Summary.** Ran plan 02 wave 1. Node 01 in the main session, test-first: `copilot_cli_measure`
now reads `prompt_tokens` (Copilot VS Code writes only that), and cuts each line at its first
`"…Metrics":` key — Copilot CLI checkpoint/shutdown lines carry session-cumulative `inputTokens`
there, so the CLI had been overcounting mid-session (real 018beebd: 102,610 vs live 34,944).
Nodes 02 and 03 ran as read-only subagents (s11-a, s11-b); I verified their key claims on disk
and appended both notes to `decisions.md`, marked PROPOSED. Reconcile 04 done.

**Shipped.** 3928a86 (fix + Q3a–c + `docs/context-budget.md` Copilot rows), c54c478, 4bc3579.
Probe clone `~/Developer/experiments/ws-identity-probe-s9` has the fix as d93e71a. Not pushed.

**Decisions.** `prompt_tokens` over `frontier_tokens` (3928a86 trailer). Node 01's live VS Code
check moved to hitl node 05 rather than ticked unproven (4bc3579 trailer). Notes for node 02
(keep all hook files; harden Claude SessionStart/End inline commands) and node 03 (one registry
name, copilot-cli) are proposals only.

**State.** Plan 02: 4/6 done, frontier = node 05 (the user's). User chose to roll over at WARN
(139K) so a fresh session walks them through node 05.

**Suggested skills.** `grill-one-question-at-a-time` style for node 05 (memory); `tdd` for wave-2 delivery.

Learnings:
- Cherry-picking a work-item commit into the probe clone conflicts on `work/` files the clone
  lacks; `git rm` them and `--continue` — only the code needs to land.
- A grep over Copilot `events.jsonl` must ignore `*Metrics` rollups; they are cumulative.


# Session Handoff — 10 (2026-10-18) (session 10: Copilot VS Code re-probe; plan 02 opened)

**Summary.** Explained Copilot-in-VS-Code to the user, then re-read the s9 row-5 logs and ran
a fresh two-chat re-probe (labels `copilot-vscode-C`/`-D`). Binding PASS again. The s9
"hooks silent" finding was a misread: hooks fired in s9 and s10, four hook sets per Copilot
event (CLI config, VS Code config, Claude `Stop` and `PostToolUse`). Duplicate records
explained (CLI hook writes `copilot-cli-*`, agent `register` writes `copilot-vscode-*`). New
gap: VS Code transcripts carry `prompt_tokens`, not `inputTokens`, so measurement falls back
to a ~30%-low estimate. Write-up: `probes/copilot-vscode.md` → "Re-probe (s10)".

**Shipped.** 816a7d9 — probe write-up + plan `02-copilot-vscode-followups` (6 nodes, 0 done,
`replan: structural`). Not pushed (pushing main is the user's call).

**Decisions.** Fix the undercount directly; hook fan-out and duplicate records go through a
user decision (hitl node 05) before any build (commit trailer of 816a7d9).

**State.** User said "roll over, then start wave 1". Other sessions have uncommitted edits in
the shared checkout (docs/context-budget.md, launch-next-session.sh, session-loop.sh, their
tests, backlog html, work/html-kit, work/clear-session-loop): not ours, untouched.

**Suggested skills.** `tdd` for node 01; subagents (read-only) for nodes 02 and 03.

Learnings:
- Before writing "hooks did not fire", grep each hook log for the session id; s9 misread
  non-empty logs as empty.
