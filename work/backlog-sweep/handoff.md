<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 4 (2026-10-18)

**Summary.** Ran node 08: code-review (Standards + Spec, two opus children) over
`4b65f8c...HEAD` scoped to this plan's paths — 0 blockers either axis. Fixed two
suggestions: `docs/context-budget.md` L96 "(default 4h)" wording (script default is 0)
and promoted the `plan.sh verify` / `WORKSPACE_ROOT` gotcha to
`docs/operational-knowledge.md`; the rest logged in `nodes/08-review.md`. Reconciled
wave 3 (09). `run-checks.sh` 45/0/0. Stopped at hitl node 10 (L86 user probes) —
checkpoint, no relaunch.

**Decisions.** None new (logged-not-fixed suggestions are low-stakes judgement calls).

**State.** Plan open, wave 4 of 5, done 9/13; frontier `10-l86-user-probes` (hitl) —
the question for the user is in `next-session.md`. Main ahead of origin (push is the
user's call). Uncommitted `work/runtime-session-identity/` and `work/html-kit/` files
belong to other sessions.

**Learnings:**
- The review range includes other sessions' commits on shared files
  (`docs/context-budget.md`); scope reviewer diffs to the plan's paths and name the
  foreign commits to ignore.

**Suggested skills:** `plans` (reconcile 11/13), `checkpoint`.

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
