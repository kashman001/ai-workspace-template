<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->


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

# Session Handoff — 2026-08-05 (session 7: item #3 planned — vendor hooks + option inheritance; STOP rollover before execution)

**What shipped (committed + pushed from worktree branch
`worktree-vendor-hook-deployments`):**

- **Item #3 implementation plan, complete and self-contained:**
  `plans/2026-08-05-vendor-hook-deployments.md` — 8 tasks, all code inlined
  (no placeholders), TDD steps per task. Covers: shared hook lib extracted
  from the claude hook (Task 1); **new `opencode` runtime for
  context-budget.sh** (Task 2 — gap found this session: the script had no
  opencode branch; sqlite schema live-verified against
  `~/.local/share/opencode/opencode.db` v1.18.14: `message.session_id` +
  `json_extract(data,'$.tokens.total')`, session-column fallback); codex
  `UserPromptSubmit` (Task 3), gemini `BeforeAgent` (Task 4 — envelope pinned
  from bundled v0.46.0 reference.md: `hookSpecificOutput.additionalContext`,
  JSON-only stdout), opencode `chat.message` plugin (Task 5), copilot
  `sessionStart`+`agentStop` STOP-only block (Task 6); **successor option
  inheritance** (Task 7 — user request mid-session: approval mode + model
  replay via `work/<proj>/.rollover-options`, mapped per runtime in
  launch-next-session.sh); docs/backlog/decisions + full verification gate
  (Task 8).
- **Ops finding** routed to `docs/operational-knowledge.md`: EnterWorktree
  re-keys the Claude Code project dir — the live transcript moves, the
  registry artifact goes stale, and discovery misattributes another session's
  usage (a predecessor's 148K WARN read as ours; real reading was 45K then).
  Re-register after entering a worktree.

**What did NOT happen:** no plan task was executed — the session hit STOP
(171K, measured exact against its own worktree-keyed transcript) right after
the plan was written. Execution is entirely the successor's.

**User inputs this session (both folded into the plan, Task 7):** the
successor session must inherit the predecessor's options (approval/auto mode,
model, etc.), for all vendor agent types.

**Loose ends:** main checkout's `work/context-decay/context-ledger.jsonl` has
uncommitted rows (this session's record calls ran there); fold into the next
work commit. Session-5 ledger block moved to `handoff-archive.md` (2-block
rule).

**Suggested skills for next session:** `superpowers:executing-plans` (or
subagent-driven-development) on the committed plan; `session-rollover` at
WARN/STOP.

