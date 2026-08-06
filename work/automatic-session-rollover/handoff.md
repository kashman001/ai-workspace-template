<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->


# Session Handoff — 2026-08-06 (session 9: plan Tasks 2–6 shipped via subagent-driven development; WARN rollover)

**What shipped (committed on `main`, pushed at rollover):**

- **Task 2 — `6a78138`:** `opencode` runtime in `scripts/context-budget.sh`
  (sqlite measurement from `message.data` tokens.total, session-column
  fallback; env-only detect). Suite T9.
- **Task 3 — `4543645`:** codex `UserPromptSubmit` hook
  (`scripts/hooks/context-budget-codex-hook.sh` + `.codex/config.toml`). T5.
  Smoke check needed `-m gpt-5.5` (machine's global codex config pins an
  unavailable model — see docs/operational-knowledge.md).
- **Task 4 — `93e9d45`:** gemini `BeforeAgent` hook + `.gemini/settings.json`
  wiring (graphify BeforeTool + telemetry preserved). T6/T10. Live smoke
  blocked by missing gemini auth on this machine (pre-documented gotcha);
  gemini parsed the new config shape cleanly.
- **Task 5 — `f9579fe`:** opencode `chat.message` plugin + wrapper. T7.
  Justified 4th file: plugin registered in `.opencode/opencode.json` `plugin`
  array (plugins do NOT auto-load from `.opencode/plugins/`). Live smoke green.
- **Task 6 — `9fa16b7`:** copilot CLI `sessionStart`/`agentStop` hooks +
  `.github/hooks/context-budget.json`. T8. Live smoke green; this workspace
  added to `~/.copilot/config.json` `trustedFolders` (was absent).

Suite `scripts/tests/test-vendor-budget-hooks.sh`: 37 asserts green.
Per-task review record + deferred minors: `.superpowers/sdd/2026-08-05-vendor-hook-deployments/progress.md`
(SDD ledger — final whole-branch review still pending, do after Task 7).

**What did NOT happen:** Task 7 (option inheritance in launch-next-session.sh
+ SKILL.md step) and Task 8 (docs/backlog/decisions + verification gate +
final review). Two machine gotchas routed to docs/operational-knowledge.md.

**Suggested skills for next session:** `superpowers:subagent-driven-development`
(SDD ledger above is mid-plan); `session-rollover` at WARN/STOP.

# Session Handoff — 2026-08-05 (session 8: plan execution started — Task 1 shipped; WARN rollover)

**What shipped (committed + pushed on `main`):**

- **Task 1 of `plans/2026-08-05-vendor-hook-deployments.md` — commit `4a39bf8`:**
  shared lib `scripts/hooks/context-budget-hook-lib.sh` (throttle /
  escalation-only / fail-open core, canonical WARN/STOP text);
  `context-budget-claude-hook.sh` refactored to a thin wrapper sourcing it
  (byte-identical messages; state files renamed `hook-claude-<sid>.*` — stale
  old files harmless); new suite `scripts/tests/test-vendor-budget-hooks.sh`,
  13 asserts green (T1 escalation, T2 throttle, T3 fail-open, T4 claude
  envelope).

**Session friction (resolved, no action needed):** primary checkout lagged
origin/main — session 7 had pushed its rollover commit from the worktree
branch; `git pull --ff-only` fixed it (the launcher's First-action warning
worked). The live claude hook fired WARN in-band at 121K right after plan
load — the push channel this whole item builds is demonstrably working.

**What did NOT happen:** Tasks 2–8 untouched (opencode runtime, codex/gemini/
opencode/copilot deployments, option inheritance, docs gate). Task 1 was
executed as the final work unit under WARN; rollover began at ~135K.

**Loose ends:** leftover locked worktree
`.claude/worktrees/vendor-hook-deployments` (branch fully merged into main) —
safe to `git worktree remove --force` + `git branch -d` when convenient.

**Suggested skills for next session:** `superpowers:executing-plans` on the
plan (Tasks 2–8); `session-rollover` at WARN/STOP.

