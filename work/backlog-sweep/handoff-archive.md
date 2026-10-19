<!-- Archived session blocks from handoff.md, newest on top. -->

# Session Handoff — 1 (2026-10-18)

**Summary.** Finished L94 (external-tools-review doc pass, R6–R24 doc items)
and L93, commit `b16325e`, cards archived. Then, at the user's request,
scaffolded this item and plan `01-open-cards` (13 nodes, 5 waves) for the
remaining open cards L85, L95, L96, L98 and L86 (hitl); L97 out of scope.
Rolled over at context WARN (146K) to start execution in a fresh session.

**Decisions.** `decisions.md`: one item/plan for all cards; L98 spend
authorized with a 45-run cap; only reconcile nodes write the backlog files.

**State.** Plan open, nothing started. `ROLLOVER_RELAUNCH=auto` for this
item. Other sessions (html-kit, runtime-session-identity) have uncommitted
work in this checkout — never stage their files. Main is ahead of origin;
pushing is the user's call.

**Learnings:**
- `test-context-budget-registry.sh` failed once in `run-checks.sh` while
  another session edited `scripts/context-budget.sh`; passed on rerun (279/0).
- `plan.sh` refuses `"--project x"` held in one variable — use `--project=x`.

**Suggested skills:** `plans` (dispatch template, reconcile), `code-review`
(node 08), `session-rollover`.
