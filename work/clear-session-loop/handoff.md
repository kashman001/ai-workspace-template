<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 5 (2026-10-15): bookkeeping; chain reopened by hand; probe run 1 launched

**Summary.** Started by hand with plain `claude` (no `session-loop.sh`), per `s14-runbook.md`. Added backlog card L90 to the archive (S13 shipped, S4 retired; Resolved 142→143) and listed `s14-runbook.md` and `probes.md` in README "Files". Then rolled over with `--clear` for probe run 1.

**Blocker hit.** `launch-next-session.sh --clear --check` refused `chain_closed`: the user's `/exit` of #4 under the loop set `.chain.closed` (`quit_plain`, by_seq 4), and the only sanctioned reopen (`session-loop.sh --reopen`) starts a supervisor, which `--clear` refuses. On the user's go-ahead, this session wrote `.chain.closed = null` to `session-state.json` with jq (the same write `--reopen` makes). Filed as open backlog card L91 (Open 2→3) and added a runbook "If something goes wrong" line.

# Session Handoff — 4 (2026-10-15): spec cut to three fixes; S13 shipped; S4 retired

**Summary.** The user reviewed the research and saw little benefit beyond the existing loop; on their call (option b) the spec was cut to three fixes and approved. Shipped S13: opt-in `PreCompact` hook (`scripts/hooks/context-budget-precompact-hook.sh`, knob `CONTEXT_BLOCK_AUTOCOMPACT`, default 0), test `scripts/tests/test-precompact-hook.sh` (failed before the hook, 11/11 after), docs in `context-budget.env` and `docs/context-budget.md`. Retired S4: `--emit` nulls `.session` in the same write as `.staged`, so the owner-check predicate broke six assertions in `test-vendor-budget-hooks.sh` (tried and reverted). `run-checks.sh` 45/45. Commits `933adb1`, `05cf58b` (not pushed).

**Also.** Scaffolded `work/concurrent-sessions/` (user request) with a row in `work/README.md`.

**S14 not run.** This session ran under `session-loop.sh`; the launcher refuses `--clear` there (`supervised_stage_only`, checked with `--check`). The user ends the chain and starts #5 by hand per `s14-runbook.md`. No successor was staged.

**Not done.** Backlog entry for S13/S4 (`docs/template-workspace-backlog.html`); left for #5 at WARN.
