<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 3 (2026-10-18)

**Summary.** Ran waves 1–2 of plan `01-open-cards`. Wave 1 in four parallel
children (haiku/sonnet, three in worktrees): L85, L95, L96 fixed, merged,
verified, cards archived (`987b118`). Wave 2: L98 pilot run (36/45 runs,
~$0.88), L98 archived, prune candidates filed as L99 (`code-simplification`)
and L100 (`unslop`) for the user (`f106a8a`). Rolled over at WARN (122K).
(No session-2 block exists; seq jumped 1→3.)

**Decisions.** `decisions.md`: L96 documented not coded (no verified
transcript signal during the usage-limit wait); L85 doc-consistency keeps
running in instances (card's wording over node box 2).

**State.** Plan open, wave 3 of 5, done 7/13; frontier `08-review`. Main is
ahead of origin (push is the user's call). Uncommitted files under
`work/runtime-session-identity/` and `work/html-kit/` belong to other sessions.

**Learnings:**
- `plan.sh verify` exports `WORKSPACE_ROOT`; the hooks honour it, so a test
  that builds a sandbox workspace must unset it (fixed in `test-probe-twins.sh`).
- All three worktree children found their branch not cut from the base commit
  and reset onto it — keep the merge-base check in the dispatch prompt.

**Suggested skills:** `code-review` (node 08), `plans` (reconcile), `session-rollover`.

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
