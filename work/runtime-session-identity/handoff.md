<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 14 (2026-10-18) (session 14: node 11 review, node 10 passed, node 12 closed plan 02)

**Summary.** Node 11: ran code-review (standards and spec sub-agents in parallel) on the plan-02 commits
3928a86, 34c76b4 and 6c5ae3a. There were no hard standards violations. F1: the node-08 guard also
fired on a leaked `COPILOT_AGENT_SESSION_ID`, so a VS Code Local chatSessions transcript was re-filed
as copilot-cli. Registry H5 was seen red, then green; the guard is now keyed on the session-state path
only. F7: the doc row's CLI ≥1.0.12 claim now cites its source. F2–F6 accepted with reasons (node 11 Log).
All five suites pass.

**Shipped.** f87afb0 (node 11 fix and Log, decision-note amendment), plus the s14 rollover commit. Not pushed.

**Decisions.** The node-03 note was amended. The guard no longer fires on the env var alone; this
follows from the node-02 note ("env vars leak into nested launches").

**Later in s14.** The user ran node 10 in the probe clone and it passed: two chats, one
`copilot-cli-<sid>` record each, turn 2 `method=exact` (8194288). Node 12 verified 10 and 11 on disk
and found no replan; plan 02 is closed. A backlog changelog row covers plan 02's four fixes.

**State.** Work item finished. The user picked "document" for the turn-1 gap: a ~10K fixed overhead,
noted in docs/context-budget.md (d51b780). `main` was pushed by the user's call (in sync at d51b780,
then the checkpoint commit). The surfaces never probed stay in backlog L86.

**For a person.** `scripts/check-drift.sh` flags a dead path in
`docs/template-adr/0009-clear-based-rollover-relaunch.md` (`scripts/hooks/rollover-clear-seed.sh`).
It is ADR history, not from this item.

**Suggested skills.** None. Reopen only if a new Copilot surface or a registry regression shows up
(`superpowers:brainstorming`, then `plan`).

Learnings:
- Plan-02 code commits in `816a7d9^..HEAD` are interleaved with other items' commits (05cf58b
  PreCompact touches the same files). Scope a review by commit, not by range plus paths.

# Session Handoff — 13 (2026-10-18) (session 13: node 08 shipped, wave 3 reconciled, probe clone staged)

**Summary.** Node 08 done test-first. New registry case H4 (register `--runtime copilot-vscode`, then
the auto register, on one session-state chat) was seen red with `reason=owner_live`. Fix: one guard
at the end of `resolve_session` in `scripts/context-budget.sh`. A copilot-vscode resolution with
`COPILOT_AGENT_SESSION_ID` set, or with a `*/session-state/*/events.jsonl` artifact, files as copilot-cli.
H1a, H2 and Q1a re-keyed. H1d (chatSessions) still files as copilot-vscode. Doc and `probe-env.sh` noted.
Node 09: verified 07 and 08 on disk; cherry-picked both into the probe clone (now 7b18ce1).

**Shipped.** 6c5ae3a (node 08), plus the s13 rollover commit (node 09, ledger, launcher). Not pushed.

**Decisions.** None new. Accepted side effect, logged in node 08: `--runtime copilot-vscode
--session-id <sid>` on the CLI runtime finds no copilot-vscode record (the pinned path returns before the guard).

**State.** Plan 02: 9/12 done. Frontier: node 10 (the user's, hitl) and node 11 (review, agent).
Rolled over at ~110K as a pre-flight before the review.

**Suggested skills.** `code-review` for node 11.

Learnings:
- `plan.sh note <text>` appends to plan.md "Not yet specified", not to a node's Log. Write node Log lines by hand.
- In the probe clone, vendor hooks J1d fails (170/1) only because of the uncommitted probe wrappers' stderr logging; a clean worktree at HEAD passes 171/0.

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


