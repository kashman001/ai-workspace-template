# Backlog sweep — close the open template backlog cards that an agent can close

Governing skill(s): `plans` (`skills/plans/SKILL.md`).

**Start here:** `next-session.md` (catch-up launcher) → `handoff.md`
(session ledger, top block).

## What this is

After the external-tools-review doc pass (L94, commit `b16325e`), six cards
stayed open in `docs/template-workspace-backlog.html`. This item works the
ones an agent can do — L85, L95, L96, L98 — as one plan with parallel
subagents on model tiers sized to each node, and carries L86 (needs the user
to run two apps) as a `hitl` node at the end. L97 is out of scope: its card
says to revisit after `work/concurrent-sessions/` settles R1.

## Success criteria

- L85: the four template-only suites exit 77 (SKIP) with a reason in an
  instance clone, and still pass in the template.
- L95: `fleet.sh dispatch-contract` carries the read-first list, the
  `Remember:` section, WIP commits for worktree children and a proved `DONE`
  (R2–R4, R19); `test-fleet-dispatch-contract.sh` covers each, seen failing
  first; `docs/plans.md` example no longer says "Done when the orchestrator
  says so".
- L96: a findings note says whether chain sessions can hit the usage-limit
  wait, and the doc line or test-first fix it calls for is in.
- L98: 3–5 skills run through the three-arm test within the spend cap set in
  node 04; results and keep/prune recommendations logged; nothing deleted
  without the user.
- L86: probe notes written once the user has run checklist steps 3–4.
- Each closed card moved to the backlog archive with a `Fixed:` line;
  `scripts/run-checks.sh` passes; a code-review pass over the diff is done.

## Files

- `next-session.md` — forward launcher (what to do next). REPLACED each rollover.
- `handoff.md` — session ledger (what happened). APPEND newest-on-top; archive
  to `handoff-archive.md` when it exceeds the two most recent sessions.
- `decisions.md` — Tier-2 decision notes.
- `plans/01-open-cards/` — the plan (`scripts/plan.sh status --project backlog-sweep`).
- `context-budget.env` — `ROLLOVER_RELAUNCH=auto` for this item.
