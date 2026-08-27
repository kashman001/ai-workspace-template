> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in `handoff.md`
> (the append-only ledger). Convention: docs/work-directory-conventions.md.

## Mission

**None queued.** Session #6 vendored the full Matt Pocock skill set (M30,
PR #23 — merge may still be pending; check `gh pr view 23`). The work item
is standing template upkeep — pick up whatever the user queues, or new
backlog findings.

Open backlog cards: **M16** (EnterWorktree mid-session stales the registry
artifact path) plus the other Open cards — grep `status open` in
`docs/template-workspace-backlog.html`. Take them only if the user asks.

## Read these, in order

1. `work/template-maintenance/handoff.md` (top block) — what session #6 shipped.
2. Whatever the queued task points at — nothing else up front.

## Do NOT reload

- M30 details — resolved card in the backlog archive; the vendoring layout,
  refresh workflow, and license live in `skills/vendored-skills.md`.
- The 2026-08-06 context-audit thread (optional empty-session-floor trim) —
  parked, awaiting user appetite; numbers in `handoff-archive.md`.
- `docs/context-budget.md` whole-file — grep the section header you need.

## State snapshot

- Session #6 work is on branch `vendor-mattpocock-skills` (PR #23). If not
  yet merged, that's the first thing to confirm with the user; once merged,
  the branch is safe to delete.
- All 27 vendored skills pinned at upstream `068b6e0`; refresh via
  `scripts/sync-vendored-skills.sh` (needs the reference clone pulled first).
- Untracked `work/kimi-k3-agent-integration/` on main is another session's
  item — leave it.
- Backlog: 6 Open / 67 Resolved (grep the scorecard for current numbers).

## First actions

1. `scripts/context-budget.sh register` (skip if the Claude Code
   SessionStart hook already ran it).
2. Await/execute the user's queued task.
