> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in `handoff.md`
> (the append-only ledger). Convention: docs/work-directory-conventions.md.

## Mission

**None queued.** The house-sale mission (M26 → L36 → L37) completed in
session #5. The work item is standing template upkeep — pick up whatever
the user queues, or new backlog findings.

The only open backlog card is **M16** (EnterWorktree mid-session stales the
registry artifact path — grep `id">M16` in
`docs/template-workspace-backlog.html`). It was explicitly out of the prior
mission's scope; take it only if the user asks.

## Read these, in order

1. `work/template-maintenance/handoff.md` (top block) — what session #5 shipped.
2. Whatever the queued task points at — nothing else up front.

## Do NOT reload

- M26/L36/L37 details — resolved cards in the backlog archive; don't re-open.
- The 2026-08-06 context-audit thread (optional empty-session-floor trim) —
  parked, awaiting user appetite; numbers in `handoff-archive.md`.
- `docs/context-budget.md` whole-file — grep the section header you need.

## State snapshot

- Session #5 work sits on branch `worktree-template-maintenance-s5-l37`
  (worktree, NOT merged to main — user merges). Local main is also **ahead
  of origin** (M26/L36 commits + session-4 rollover) — push when the user
  wants.
- Untracked `work/kimi-k3-agent-integration/` on main is another session's
  item — leave it.
- Backlog: 1 Open (M16) / 66 Resolved.
- Vendored skill pins unchanged: `wayfinder`/`writing-for-agents` at
  upstream `8b36d4f`.

## First actions

1. `scripts/context-budget.sh register` (skip if the Claude Code
   SessionStart hook already ran it).
2. Await/execute the user's queued task.
