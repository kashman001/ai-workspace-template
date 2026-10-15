<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 2 (2026-10-15)

**Summary.** Research done; verdict **PARTIAL**. A fable research subagent (dispatch `research`, gen 1, closed DONE) drafted the research. This session verified the key claims against the repo and primary docs and wrote `research.md` (with a Verification section) and `research.html`. Rolled over at WARN before the spec step.

**Verdict, short.** Go: harden the attended Claude `--clear` path, plus one headless spike (`claude -p` stream-json `/clear` → `conversation_reset`). No-go: an unattended `/clear` chain via pty/tmux/expect injection, and `/clear` chains on Codex/Copilot/Gemini/VS Code (no sanctioned trigger; programmatic resets mean hosting the session in an SDK). Several sessions per work item: an independent change that `/clear` neither helps nor blocks (`research.md` §6).

**Corrections made in verification.** (1) SessionStart `initialUserMessage` is documented for `-p` only, so it cannot make the TUI path keystroke-only. (2) New open question: does a cleared TUI session act on seeded hook context with no typed message? The skill (`skills/session-rollover/SKILL.md:251-252`) and TADR-0009 (`:61`) say "types nothing"; unproven. (3) TADR-0009 citation corrected (`:96-97`). (4) SessionEnd: shared 1.5 s budget, raised by a per-hook `timeout` or `CLAUDE_CODE_SESSIONEND_HOOKS_TIMEOUT_MS`.

**Decisions.** PARTIAL → spec the go half only (§7 A + B): `decisions.md` 2026-10-15.

**State.** Committed with this rollover: the whole work item (session 1's scaffold had never been committed), `research.md`, `research.html`, `decisions.md`, and the `work/README.md` index row. `.agent-dispatch/` is gitignored. Render helper (pandoc + the stylesheet from `scripts/build-guide-html.sh`) was in session scratch only; the successor recreates it (launcher step).

**Suggested skills.** `to-spec` conventions via `docs/agents/issue-tracker.md` → "Spec conventions"; `scripts/fleet.sh dispatch-open` for the spec child.

Learnings:
- `dispatch-open` / `dispatch-close` / `dispatch-list` now live in `scripts/fleet.sh`; `scripts/context-budget.sh dispatch-open` exits 3 with a redirect. `docs/context-budget.md` → "Dispatching long-running children" still reads as if they are `context-budget.sh` subcommands. Possible template backlog finding (first strike).

# Session Handoff — 2026-10-15 (session 1: scaffolded; scope agreed)

Work item scaffolded. Scope agreed with the user: research `/clear` (plus the
linked video) for the session loop across all loop components, subagents, hooks,
and runtimes (Codex, Copilot, Gemini CLI, VS Code chat agents), using a fable
subagent; then a spec via a second fable subagent if the verdict is go. Found
that `/clear` is already used in the attended Claude-only `launch-next-session.sh
--clear` path; the blocker is that an agent cannot press `/clear`. Per-item
`ROLLOVER_RELAUNCH=auto` committed so `session-loop.sh` can run it. Next: the
research step in `next-session.md`.
