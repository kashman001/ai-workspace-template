<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff addendum — 4 (2026-10-15): hand-started continuation; chain reopened by hand; probe run 1 launched

**Numbering.** The user started this as "session #5", but #4 staged no successor, so `register` adopted seq 4 (owner dead, number kept). Hence an addendum to #4; the `/clear` successor is seq 5.

**Summary.** Started by hand with plain `claude` (no `session-loop.sh`), per `s14-runbook.md`. Added backlog card L90 to the archive (S13 shipped, S4 retired; Resolved 142→143) and listed `s14-runbook.md` and `probes.md` in README "Files". Then rolled over with `--clear` for probe run 1.

**Blocker hit.** `launch-next-session.sh --clear --check` refused `chain_closed`: the user's `/exit` of #4 under the loop set `.chain.closed` (`quit_plain`, by_seq 4), and the only sanctioned reopen (`session-loop.sh --reopen`) starts a supervisor, which `--clear` refuses. On the user's go-ahead, this session wrote `.chain.closed = null` to `session-state.json` with jq (the same write `--reopen` makes). Filed as open backlog card L91 (Open 2→3) and added a runbook "If something goes wrong" line.

# Session Handoff — 4 (2026-10-15): spec cut to three fixes; S13 shipped; S4 retired

**Summary.** The user reviewed the research and saw little benefit beyond the existing loop; on their call (option b) the spec was cut to three fixes and approved. Shipped S13: opt-in `PreCompact` hook (`scripts/hooks/context-budget-precompact-hook.sh`, knob `CONTEXT_BLOCK_AUTOCOMPACT`, default 0), test `scripts/tests/test-precompact-hook.sh` (failed before the hook, 11/11 after), docs in `context-budget.env` and `docs/context-budget.md`. Retired S4: `--emit` nulls `.session` in the same write as `.staged`, so the owner-check predicate broke six assertions in `test-vendor-budget-hooks.sh` (tried and reverted). `run-checks.sh` 45/45. Commits `933adb1`, `05cf58b` (not pushed).

**Also.** Scaffolded `work/concurrent-sessions/` (user request) with a row in `work/README.md`.

**S14 not run.** This session ran under `session-loop.sh`; the launcher refuses `--clear` there (`supervised_stage_only`, checked with `--check`). The user ends the chain and starts #5 by hand per `s14-runbook.md`. No successor was staged.

**Not done.** Backlog entry for S13/S4 (`docs/template-workspace-backlog.html`); left for #5 at WARN.

# Session Handoff — 3 (2026-10-15)

**Summary.** Spec written. A fable subagent (dispatch `spec`, gen 1, closed DONE) drafted it from `research.md` §7 A + B. This session checked the draft's repo claims and wrote `spec.md` (Status: draft, S1–S17, with a Verification section) and `spec.html`. `research.md` did not change, so `research.html` was not re-rendered. Rolled over interactive so the user can review.

**Corrections made in verification.** The `launch.pending` write is at `launch-next-session.sh:430-435` (the draft said `:418-419`). The launcher's printed `/clear` instruction (`:453`) already says "type nothing", so S15 now names that line.

**Design calls awaiting the user** (spec S5/S7/S8/S10/S13; all are the subagent's proposals): drain refusal at exit 4 `dispatch_open`; new counter `chain.clears` that `register` bumps on a supervised clear binding; `--clear` under a supervisor only in interactive mode; Stop-hook owner check `.session.session_id == $sid`; PreCompact auto-block opt-in, off by default; `sessionTitle` only if probe A2 passes.

**State.** Committed `spec.md` and `spec.html`. The render helper (pandoc + the stylesheet from `build-guide-html.sh`) lived in session scratch only.

**Suggested skills.** `plan` (`/plan`) only after the user approves the spec.

Learnings:
- `dispatch-open` lives in `scripts/fleet.sh` (second time it mattered; the launcher already used the right command). The `docs/context-budget.md` wording is still stale (second strike).

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
