<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->


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

# Session Handoff — 2026-08-05 (session 6: implementation item #2 shipped — launch-next-session.sh; WARN rollover)

**What shipped (all committed + pushed, `b6d245a`, `d468f7c`, `ef42a12`):**

- **Item #2 complete.** `scripts/launch-next-session.sh` per ADR-0003/0004:
  verbatim bootstrap prompt (single source of truth in the script); runtime
  resolution --runtime flag > dying session's own registry record (D6,
  env-first identity mirroring `context-budget.sh session_id_for()`) > newest
  record for the project > `ROLLOVER_RUNTIME` > claude; 5 runtimes
  seeded-interactive (`claude` [+`--bg`], `codex` positional, `gemini -i`,
  `opencode --prompt`, `copilot -i` — all flags re-verified against live
  `--help` this session); modes off/manual/auto honored (auto+claude implies
  --bg); --bg claude-only (die otherwise); D8 successor confirmation poll
  after --bg (`ROLLOVER_CONFIRM_SECS`, default 120s, non-fatal); non-tty
  manual prints `run: <cmd>` instead of exec'ing a TUI; copilot-vscode
  degrades to prompt-only.
- **Tests:** `scripts/tests/test-launch-next-session.sh` — 13 cases /
  28 asserts, all green (dry-run flag assembly + stub-binary --bg/D8/timeout/
  non-tty paths). Registry suite still green (13/13).
- **Docs:** `docs/context-budget.md` §Rollover trigger policy status note
  flipped to implemented; backlog changelog row appended; four Tier-2 notes
  in `decisions.md` (tty guard, copilot-vscode degradation, --bg-only D8
  confirmation, always-print prompt); plan committed at
  `plans/2026-08-05-launch-next-session.md`; stale `workspace-structure.html`
  rebuilt.

**Where things stand:** items #1+#2 done; item #3 (four vendor hook
deployments) not started — next session's mission. Working tree clean apart
from the live `.active-session` lock (untracked by design).

**Suggested skills for next session:** superpowers:writing-plans →
executing-plans (the pattern items #1 and #2 both used successfully);
session-rollover at WARN/STOP.
