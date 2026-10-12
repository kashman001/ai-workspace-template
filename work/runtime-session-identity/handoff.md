<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 8 (2026-10-12) (session 8: review, plan 01 closed)

**Summary.** Node 15 ran `code-review` on bc1cce4...HEAD with two sub-agents. Standards: no
hard violations. Spec: no blockers. Three suggestions were fixed test-first, each case seen
failing before its fix. The rest are logged in the node. Reconcile 16 closed the wave, and
plan 01 is closed (`status: closed`).

**Shipped (main, not pushed).**
- 0b4dd7c: the Claude SessionEnd hook needs `transcript_path`, like SessionStart, so a
  payload without one releases nothing (hooks K1g/K1h).
- 0d581ce: agent-shell Copilot discovery honours `COPILOT_STATE_DIR` (registry U1).
- 0964a23: copilot-cli discovery no longer takes newest-mtime across `session-state/`. Only
  the legacy dir keeps it (registry U2).
- Backlog L87 (Open): cwd substring match in discovery, from the review.

**Decisions.** `decisions.md` has two new notes: the SessionEnd guard, and no guessing among
current-format Copilot transcripts.

**State.** Plan 01 closed, 16/17 done and 1 dropped. Checks on main: registry 272/0, hooks
167/0, statusline 20/0, attach-session 27/0, doc-consistency 17/0. `check-drift.sh` has one
WARN that predates this session (TADR-0009 cites a retired script as history). The probe
clone is kept for L86.

**Suggested skills.** None needed to finish this item. Open follow-ups: L86 (user-run
probes), L87 (`tdd`). Push `main` and the probe cleanup are the user's call.

Learnings: the launcher's "unused test prefixes" claim was stale. Grep the suite's labels
before you trust it.

# Session Handoff — 7 (2026-10-12) (session 7: waves 3 and 4 closed)

**Summary.** Wave 3 ran as three parallel worktree children (s7-a/b/c, suite prefixes A/B/Q),
each test-first and each seen red before its fix; all merged to main and verified on disk.
The user deferred the Antigravity IDE/app + Codex desktop probes: node
`11-remaining-surface-probes` dropped → template backlog card **L86**. Reconcile 12 closed.
Node 13 (docs) ran as one in-place child (s7-d); reconcile 14 closed. Rolled over before node
15 (review) — pre-flight: 111K + review cost would cross STOP.

**Shipped (main, not pushed).**
- Node 09 `prune_phantoms` (`scripts/context-budget.sh`): register/record delete non-own records
  whose artifact is missing >60 min after last write; never the pid. Orchestrator fix 769f54b:
  the loop word-split paths with spaces (repro shown; suite's mktemp can't build a spaced path).
- Node 10: no id var + >1 live registered session in cwd → every command refuses
  `ambiguous_artifact` naming `--session-id`; `record --session-id` now allowed. Hook-message
  id half NOT built (decision note).
- Node 11-copilot-vscode: `copilot_vscode_measure` delegates to `copilot_cli_measure` →
  `inputTokens` exact.
- Node 13: `docs/context-budget.md` — hook trust, support matrix, antigravity adapter, nodes
  09/10/11 behaviour (3c7b555).
- Backlog L86 added (220279c).

**Decisions.** `decisions.md`: 60-min phantom grace; no session-id field in hook payloads;
probes deferred to L86.

**State.** Plan wave 5 of 5; frontier `15-review`. Checks on main at s7 end: registry 269/0,
statusline 20/0, vendor-budget-hooks 165/0, attach-session 27/0, doc-consistency 17/0. All
s7 worktrees removed. Probe clone kept (needed for L86).

**Suggested skills.** `code-review` (node 15), `plan` reconcile (node 16).

Learnings:
- Worktree children were again cut without the base SHA; the reset instruction in the prompt worked every time.

# Session Handoff — 6 (2026-10-12) (session 6: wave 2 closed)

**Summary.** Ran wave 2 of plan `01-session-identity-fixes`: nodes 03–07 dispatched to five
parallel worktree children (actors s6-a…e, suite prefixes E/F/H/K/L), each test-first; all
merged into `main`, verified on disk, `done`. Reconcile `08-reconcile-w2` done. Wave 3 is
now the frontier, including hitl node `11-remaining-surface-probes`.

**Shipped (main, not pushed).**
- 03 Codex: `[[hooks.SessionStart]]` in `.codex/config.toml`; codex row `register=hook`, pin `CODEX_THREAD_ID=sid`.
- 04 Copilot CLI: `copilot` row `register=hook`; transcript root honours `COPILOT_HOME`.
- 05 Copilot VS Code: hook keeps a `session-state/<sid>/events.jsonl` transcript as is; discovery uses `COPILOT_AGENT_SESSION_ID` first.
- 06 One hook per Copilot event: dispatcher ignores session-state payloads as `claude` (always) and `copilot-vscode` (while the CLI config is installed); `.claude/settings.json` SessionStart now requires `transcript_path`.
- 07 Antigravity: new adapter row, `.agents/hooks.json` (PreInvocation), `scripts/hooks/context-budget-antigravity-hook.sh`, `inject-json-only` envelope.
- Suites: registry 237/0, vendor-budget-hooks 165/0, all 18 context-budget suites + structure check pass.

**Decisions.** Three Tier-2 notes appended to `decisions.md` (CLI config owns Copilot payloads; hook rows register on any non-check event; `COPILOT_STATE_DIR` kept above `COPILOT_HOME`).

**Replan.** Added `11-copilot-vscode-measure-inputtokens` to wave 3 (copilot-vscode measure reads only `promptTokens`; session-state transcripts carry `inputTokens`). Corrected s6-c's over-broad claim: copilot-cli measure is already exact.

**Open question (unanswered, carried forward).** User asked to roll over before answering: "Do you want to run the Antigravity IDE/app and Codex desktop app probes now (`probes/user-checklist.md` steps 3–4), or skip them?"

**Not verified.** No live Codex/Copilot/agy run against the committed hook configs — fixture-tested only. Codex will re-prompt for hook trust (config changed).

**Key files.** `plans/01-session-identity-fixes/plan.md` (notes + Replans), node files 03–08, `decisions.md`.

**Suggested skills.** `plans` (subagent template, reconcile), `tdd`.

Learnings:
- Agent-tool worktrees (isolation: worktree) were cut without the local base commit 5/5 times; the template's "confirm base, else reset" line saved every child.
- Parallel children appending to the same suite tail conflict on every merge; append-vs-append, resolved by keeping both. A per-child section anchor would avoid it.
