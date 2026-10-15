<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

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
