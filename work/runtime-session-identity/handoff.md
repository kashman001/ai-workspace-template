<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 9 (2026-10-12) (session 9: CLI surfaces probed live; VS Code rows handed to the user)

**Summary.** New probe clone `~/Developer/experiments/ws-identity-probe-s9` at 191944f. The old
pre-fix clone was left untouched. The probe now wraps the claude and antigravity hooks, runs
`check`, and writes one log per label. Two concurrent sessions per CLI, from a clean env:
Claude CLI PASS; Codex CLI PASS (agent side, and hook side with user-approved trust bypass);
Copilot CLI agent side PASS, hooks not fired (clone not in `trustedFolders`); Antigravity hook
side PASS, agent shell not run. Details are in each `probes/<surface>.md` under "Post-fix (s9)".

**Blocked by the agent permission classifier (user said "you have my permission to trust", but
these were still denied):** editing `~/.copilot/config.json` `trustedFolders`, and
`agy --dangerously-skip-permissions`. Both moved to `probes/user-checklist.md` rows 1–2.

**State.** `probes/user-checklist.md` was rewritten as one post-fix checklist (rows 1–5) and is
waiting on the user. No gaps found yet, so no backlog card. L86 is not yet updated.
doc-consistency 17/0.

Learnings:
- Reusing a probe label across runtimes made `probe-env.sh`'s `tail` show the earlier runtime's
  lines. Use labels that are unique per runtime.
- `codex exec` reports `method=estimate` until the first `token_count` event, then `exact`.

# Session Handoff — 8 (2026-10-12) (session 8: review, plan 01 closed, L87 fixed; rolled over at STOP)

**Summary.** Node 15 ran `code-review` on bc1cce4...HEAD with two sub-agents. Standards: no
hard violations. Spec: no blockers. Three suggestions were fixed test-first, the rest logged in
the node. Reconcile 16 closed plan 01 (`status: closed`). After the checkpoint, the user asked
for L87 and it was fixed test-first. The user then asked for live verification of all seven
surfaces; this session hit STOP before starting it, so it rolled over.

**Shipped (main, pushed: origin/main = 3ed090a includes all of it).**
- 0b4dd7c: the Claude SessionEnd hook needs `transcript_path` (hooks K1g/K1h).
- 0d581ce: agent-shell Copilot discovery honours `COPILOT_STATE_DIR` (registry U1).
- 0964a23: copilot-cli discovery no longer takes newest-mtime across `session-state/` (U2).
- 0ae0eb1: Fix L87. Discovery matches the cwd as a whole value, not a substring (U3/U4).
  Cost: a multi-root `.code-workspace` no longer matches in the no-id fallback. L87 archived.

**Decisions.** `decisions.md` has two s8 notes (SessionEnd guard; no guessing among
current-format Copilot transcripts). The L87 trade-off is in its commit body.

**State.** Plan 01 closed. Checks on main: registry 276/0, hooks 167/0, statusline 20/0,
attach-session 27/0, doc-consistency 17/0. Since bc1cce4, no non-Claude surface has been run
live: every fix is fixture-tested only. The Claude VS Code plugin was never probed.

**Suggested skills.** `create-verification-skill` is optional; otherwise follow
`probes/user-checklist.md` and `make-ide-probe-clone.sh`.

Learnings:
- The launcher's "unused test prefixes" claim was stale. Grep the suite's labels before you trust it.

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
