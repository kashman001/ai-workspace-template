<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

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

# Session Handoff — 5 (2026-10-12) (session 5: wave 1 closed)

Wave 1 of plan `plans/01-session-identity-fixes` is done (2/16 nodes). Rolled over before
wave 2: five parallel nodes on shared files don't fit in the headroom left.

- **Node 01 (refuse-instead-of-guess):** commit `3828bf2`. `scripts/context-budget.sh`:
  `pick_unambiguous` (codex and copilot-cli fallbacks), copilot-vscode rc 2, and
  `resolve_session` refuses `reason=ambiguous_artifact` (exit 4) on every command;
  `detect_runtime` checks id vars before `CLAUDECODE`. Suite sections D1/D2 in
  `scripts/tests/test-context-budget-registry.sh` (211/0); doc row in
  `docs/context-budget.md` → Reason codes.
- **Found:** the old copilot-vscode register guard was dead code (flag set in a `$(...)`
  subshell). Decision note in `decisions.md`.
- **Node 02 (reconcile w1):** commit `95ddf21`. No replan; two `plan.sh note` lines in
  `plan.md` for nodes 05–07.
- All other context-budget suites pass.

Suggested skills: `plans` (dispatch template, reconcile), `tdd`.

Learnings:
- A discover function's globals never reach the caller (`ARTIFACT=$(discover_for …)` is a
  subshell); signal through the exit code.
