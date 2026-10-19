# Catchup prompt — Backlog sweep (paste into a new agent session)

> **This file is the LAUNCHER.** Forward-only, REPLACED at each rollover.
> Provenance lives in `handoff.md`. Convention: docs/work-directory-conventions.md.

## Mission

Execute plan `01-open-cards` (`work/backlog-sweep/plans/01-open-cards/`):
close backlog cards L85, L95, L96, L98 with parallel subagents at each
node's tier, then carry L86 (user-run probes) to the end.

## Position

<!-- plan:begin position -->
Position: plan 01-open-cards, open, wave 1 of 5, done 2/13, doing 2, todo 9, blocked 0, dropped 0, sessions 1.
Frontier: none (01-l85-skip-template-only-suites doing, 03-l96-usage-limit-watchdog doing). Remaining: 11 of 13 — wave 1: 01-l85-skip-template-only-suites doing, 03-l96-usage-limit-watchdog doing, 05-reconcile-w1 todo.
<!-- plan:end position -->

## Read these, in order

1. `work/backlog-sweep/README.md` (success criteria)
2. `work/backlog-sweep/decisions.md`
3. `skills/plans/SKILL.md` → "Subagent prompt template" and "Run a reconcile node"
4. The frontier node files only (`scripts/plan.sh frontier --project=backlog-sweep`)

## Constraints already decided (do not re-litigate)

- Tiers: `cheap` → Agent `model: haiku`, `standard` → `sonnet`, `frontier`
  → `opus` (`plan-tiers.env`). Reconcile nodes run in this session, never a child.
- `isolated: yes` nodes → Agent `isolation: "worktree"`; commit plan state
  (`start`) first so the worktree branch contains it; merge back at reconcile.
- Children never touch `docs/template-workspace-backlog*.html`; reconcile
  nodes move cards, re-reading both files right before writing.
- L98 spend authorized, cap 45 headless runs (`decisions.md`).
- Other sessions share this checkout: stage only your own paths; never push.

## Do NOT reload

- `work/external-tools-review/` beyond the R-number a node cites — closed.
- L94/L93 — done in `b16325e`.

## First actions

1. `scripts/context-budget.sh register --project backlog-sweep`
2. `scripts/plan.sh start <id> --session <n> --project=backlog-sweep` for each of
   01–04, then commit the plan state (`work/backlog-sweep/` only).
3. Dispatch 01–04 **in one message** with the plans-skill subagent prompt:
   01 haiku + worktree, 02 sonnet + worktree, 03 sonnet + worktree, 04 sonnet
   (shared checkout; writes only `work/backlog-sweep/pilot/`).
4. As they return: verify on disk, `plan.sh done <id>`, then run
   `05-reconcile-w1` here; continue wave by wave. Record budget at each
   node boundary (`scripts/context-budget.sh record --label …`).
5. When the frontier is `10-l86-user-probes` (hitl): stop and leave the
   question for the user — run steps 3–4 of
   `work/runtime-session-identity/probes/user-checklist.md`, then
   `scripts/plan.sh done 10-l86-user-probes --by human --project=backlog-sweep`.
