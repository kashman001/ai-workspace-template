# Catchup prompt — Backlog sweep (paste into a new agent session)

> **This file is the LAUNCHER.** Forward-only, REPLACED at each rollover.
> Provenance lives in `handoff.md`. Convention: docs/work-directory-conventions.md.

## Mission

Finish plan `01-open-cards` (`work/backlog-sweep/plans/01-open-cards/`). Blocked
on the user: hitl node 10 (L86 probes), then reconcile 11 and the plan's last wave.

## Position

<!-- plan:begin position -->
Position: plan 01-open-cards, open, wave 4 of 5, done 9/13, doing 0, todo 4, blocked 0, dropped 0, sessions 2.
Frontier: 10-l86-user-probes. Remaining: 4 of 13 — wave 4: 10-l86-user-probes todo, 11-reconcile-w4 todo.
<!-- plan:end position -->

## Waiting on the user (hitl node 10)

Run steps 3–4 of `work/runtime-session-identity/probes/user-checklist.md` in the
probe clone it names (step 3: Antigravity IDE/app; step 4: Codex desktop app; about
5 minutes each), save what its "When done" section asks for, then:

    scripts/plan.sh done 10-l86-user-probes --by human --project=backlog-sweep

Or defer L86 again: `scripts/plan.sh drop 10-l86-user-probes --project=backlog-sweep`.

## Read these, in order (once node 10 is answered)

1. `work/backlog-sweep/README.md` (success criteria — L86 bullet)
2. `work/backlog-sweep/handoff.md` — top block only
3. `skills/plans/SKILL.md` → "Run a reconcile node"
4. `scripts/plan.sh status --project backlog-sweep`, then the frontier node files

## Constraints already decided (do not re-litigate)

- Reconcile nodes run in the orchestrating session; only they write `docs/template-workspace-backlog*.html`, re-reading both right before writing.
- Other sessions share this checkout: stage only your own paths; never push.
- Cards L99/L100 (prune candidates) are the user's call — delete no skills.

## Do NOT reload

- Node 08 code-review — done, 0 blockers; findings in `nodes/08-review.md` Log.
- L85/L95/L96/L98 — closed and archived; `pilot/runs/`; `work/external-tools-review/`.

## First actions

1. `scripts/context-budget.sh register --project backlog-sweep`
2. If node 10 is still `todo`: the user hasn't answered — restate the question above and stop.
3. Otherwise work the frontier in order — 11 reconcile, 12 L86 probe write-up, 13 final
   reconcile (archives L86) — `plan.sh sync`, commit; then `checkpoint` (plan closed).
