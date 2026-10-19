<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 4 (2026-10-18)

**Summary.** Node 08 code-review (Standards + Spec, two opus children) over
`4b65f8c...HEAD` scoped to this plan's paths — 0 blockers; fixed the L96 "(default 4h)"
wording in `docs/context-budget.md` and promoted the `plan.sh verify` / `WORKSPACE_ROOT`
gotcha to `docs/operational-knowledge.md`; rest logged in `nodes/08-review.md`. Reconciled
wave 3 (`40634a6`). Then guided the user through the L86 probes in the clone
`~/Developer/experiments/ws-identity-probe-s9`: Antigravity IDE and Codex inside
ChatGPT.app both **pass** (own transcript per chat, one record each, hooks per chat).
Node 10 done `--by human`, wave 4 reconciled (11). Rolled over at WARN (122K).

**Decisions.** `decisions.md`: Codex desktop probe ran on Codex in ChatGPT.app — the
standalone `codex-app` cask is discontinued upstream.

**State.** Plan open, wave 5; frontier `12-l86-probe-writeup`, then `13-reconcile-w5`.
Raw evidence for node 12 is in `nodes/10-l86-user-probes.md` Log (IDs, timestamps, log
paths in the clone). New gap to file at 13: Codex Desktop also runs the
`.claude/settings.json` Stop hook (`context-budget-stop-hook.sh claude` with a Codex
payload). Main ahead of origin (push is the user's call).

**Learnings:**
- Scope a review's diff to the plan's own paths when other sessions committed on shared
  files in the range; name the foreign commits for the reviewers.
- The checklist's "steps 3–4" label in L86/node 10 was wrong (rows 3–4 are the VS Code
  extensions); the L86 surfaces are the checklist's "Optional" line.

**Suggested skills:** `plans` (reconcile 13), `decision-log`.

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
