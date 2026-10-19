# Catchup prompt — Backlog sweep (paste into a new agent session)

> **This file is the LAUNCHER.** Forward-only, REPLACED at each rollover.
> Provenance lives in `handoff.md`. Convention: docs/work-directory-conventions.md.

## Mission

Finish plan `01-open-cards` (`work/backlog-sweep/plans/01-open-cards/`):
code-review the plan's diff (node 08), reconcile, then stop at the L86
user-probe gate (hitl node 10).

## Position

<!-- plan:begin position -->
Position: plan 01-open-cards, open, wave 3 of 5, done 7/13, doing 0, todo 6, blocked 0, dropped 0, sessions 1.
Frontier: 08-review. Remaining: 6 of 13 — wave 3: 08-review todo, 09-reconcile-w3 todo.
<!-- plan:end position -->

## Read these, in order

1. `work/backlog-sweep/README.md` (success criteria)
2. `work/backlog-sweep/handoff.md` — top block only
3. `skills/plans/SKILL.md` → "Run a reconcile node"
4. `work/backlog-sweep/plans/01-open-cards/nodes/08-review.md`, then `skills/code-review/SKILL.md`

## Constraints already decided (do not re-litigate)

- Node 08 tier `frontier` → run it in this session or an `opus` child; reconcile nodes run here.
- Children never touch `docs/template-workspace-backlog*.html`; reconcile re-reads both files right before writing.
- Other sessions share this checkout: stage only your own paths; never push.
- Cards L99/L100 (prune candidates) are the user's call — delete no skills.

## Do NOT reload

- L85/L95/L96/L98 — closed and archived (`987b118`, `f106a8a`); review their diff, don't redo them.
- `work/backlog-sweep/pilot/runs/` — results are summarised in `pilot/results.md`.
- `work/external-tools-review/` — closed.

## State snapshot

Branch `main`, ahead of origin. Nothing of this item uncommitted. Uncommitted
`work/runtime-session-identity/…` and `work/html-kit/prototype/xrt/` belong to other sessions.

## First actions

1. `scripts/context-budget.sh register --project backlog-sweep`
2. `scripts/plan.sh start 08-review --session 4 --project=backlog-sweep`; run the review per
   the node's Goal (BASE = `git log --format=%h --diff-filter=A -1 -- work/backlog-sweep/plans/01-open-cards/plan.md`).
   Fix blockers test-first; `scripts/run-checks.sh`; `plan.sh done 08-review`.
3. Run `09-reconcile-w3` here; `plan.sh sync`; commit.
4. Frontier is then `10-l86-user-probes` (hitl). **No human in the loop:** stop there with
   the question open — do not run probes. The question for the user: run steps 3–4 of
   `work/runtime-session-identity/probes/user-checklist.md` (Antigravity IDE/app, Codex
   desktop app), then `scripts/plan.sh done 10-l86-user-probes --by human --project=backlog-sweep`
   (or `plan.sh drop` to defer L86 again). End with `checkpoint`, not a relaunch.
