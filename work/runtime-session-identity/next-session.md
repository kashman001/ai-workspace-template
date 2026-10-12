# Catchup prompt — Runtime Session Identity (paste into a new agent session)

We're resuming runtime-session-identity. Works in any runtime (Claude Code, Codex, Gemini,
OpenCode) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in
> `handoff.md` (the append-only ledger). Convention:
> docs/work-directory-conventions.md.

## Mission

Finish plan `plans/01-session-identity-fixes`: node `15-review` (review the whole plan's work
and fix findings), then `16-reconcile-w5` closes the plan.

## >>> START HERE <<<

**First actions:**

1. `scripts/context-budget.sh register --project runtime-session-identity`
2. `scripts/plan.sh status --project=runtime-session-identity` and `… frontier …` (expect `15-review`).
3. `scripts/plan.sh start 15-review --project=runtime-session-identity`, commit.
4. Run the `code-review` skill (`skills/code-review/SKILL.md`) on `bc1cce4..main` with
   `work/runtime-session-identity/findings.md` → "Gaps" as the spec. Its reviewers run as
   sub-agents — keep their output out of this context. Fix each blocker test-first (a suite
   case seen failing first; unused suite prefixes: **C, G, M**); fix or Log each suggestion.
   Run the item's checks (below), tick Acceptance, `done 15-review`.
5. Reconcile `16-reconcile-w5` per `skills/plans/SKILL.md` → "Run a reconcile node". If the plan
   then closes, end via `checkpoint` (the stop door), not another rollover.

**No human in the loop:** all of the above runs unattended. Only stop for the user if a review
finding needs a product decision — write it into the node Log and `decisions.md` and roll over
with the question verbatim.

**The item's checks:** `scripts/tests/test-context-budget-registry.sh`,
`test-statusline-context-budget.sh`, `test-vendor-budget-hooks.sh`, `test-attach-session.sh`,
`test-doc-consistency.sh` (all green at s7 end: 269/20/165/27/17).

## Read these, in order

1. `plans/01-session-identity-fixes/plan.md` (notes + Replans)
2. `plans/01-session-identity-fixes/nodes/15-review.md`, then `16-reconcile-w5.md`
3. `decisions.md` — settled forks the review must not flag as defects

## Do NOT reload

- Wave 1–4 diffs one by one: done and reconciled; the review reads them as one range.
- `probes/*`: probing is finished or deferred (backlog L86).
- `findings.md` beyond "Gaps": the rest is evidence for settled nodes.

## Constraints already decided (do not re-litigate)

- Fixes must be agent-agnostic, proven by a suite case that fails before the fix.
- Pid-walk is out for identifying a session; liveness never relies on pid.
- Ambiguous discovery refuses on every command; the Copilot CLI hook config owns every Copilot payload.
- No session-id field in hook payloads; phantom grace is a fixed 60 min (`decisions.md`).
- Pushing `main` is the user's call; never push.
- Probe cleanup (`findings.md` → "Cleanup owed") waits for L86 and the user's say-so.

## Plan position

<!-- plan:begin position -->
Position: plan 01-session-identity-fixes, closed, wave 5 of 5, done 16/17, doing 0, todo 0, blocked 0, dropped 1, sessions 4.
Frontier: none. Remaining: 0 of 17.
<!-- plan:end position -->

## State snapshot

- Branch `main`, clean after the rollover commit; many commits ahead of origin (not pushed).
- Unrelated pre-existing worktrees (doc-review-skill, stage4, tir-s2) — leave them.
- Probe clone `~/Developer/experiments/ws-identity-probe` kept for backlog L86.
