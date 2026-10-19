<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 12 (2026-10-18) (session 12: node 05 decided, waves 3–4 planned, node 07 shipped)

**Summary.** Walked the user through node 05 one question at a time. Q1 hook fan-out: option A +
both hardenings (user asked for an explanation first). Q2 duplicate records: (b), one name,
copilot-cli. Q3 live VS Code check in the probe clone: turn 1 `method=estimate tokens=29783`
(no `prompt_tokens` yet — the first `session.usage_checkpoint` is written at turn end), turn 2
`method=exact tokens=42654`; PASS from turn 2. Node 06 replanned waves 3–4 (nodes 07–12). Node 07
done test-first: Claude `SessionStart`/`SessionEnd` inline commands skip Copilot session-state
transcripts (K1i/K1j seen red), K1k/K1l cover Claude `PostToolUse`, doc rows corrected.

**Shipped.** d308262 (decisions, node 05/06, replan), 34c76b4 (node 07 fix). Not pushed.

**Decisions.** Both node-05 notes flipped to decided in `decisions.md`. Turn-1 estimate gap parked as
a `plan.md` "Not yet specified" note — the user has not picked (document vs accept).

**State.** Plan 02: 7/12 done, frontier = node 08. Rolled over at ~119K as a pre-flight before 08.

**Suggested skills.** `tdd` for node 08.

Learnings:
- A Copilot agent's summary of `check` drops `method=`; read the raw `runtime=` line from the chat's
  `events.jsonl` (`grep -o 'runtime=… method=…'`) instead of trusting the wording.
- Commit-by-path in zsh: `F="a b"; git add $F` is one path (no word splitting) — use an array.


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
