<!--
File: work/README.md
Purpose: Status index over all work items — one line + status each, so
"what's the team working on?" is one glance, not a directory dig.
Maintenance: refresh the relevant row at checkpoint / session-rollover (the
moments those skills already touch these directories). New work items add
their row when first committed.
-->

# Work Items — Status Index

**Reading a work directory in 60 seconds:** `README.md` = what the effort is
and its current status · `next-session.md` = what happens next (launcher) ·
`handoff.md` = what already happened, newest block on top (ledger). Full
convention: [`docs/work-directory-conventions.md`](../docs/work-directory-conventions.md).

Only committed work items are listed; local-only (gitignored) items are
excluded by rule, not by oversight.

| Work item | What it is | Status |
|---|---|---|
| [`automatic-session-rollover`](automatic-session-rollover/README.md) | Hands-free successor relaunch after a context-budget rollover | Dormant — shipped and merged; decision map fully drained |
| [`kimi-k3-agent-integration`](kimi-k3-agent-integration/README.md) | Bring Kimi K3 (Moonshot) in as an agent runtime | Stalled since 2026-08-10 — waiting on the user's runtime choice (4 options in its launcher) |
| [`feedback-intake`](feedback-intake/README.md) | Route production/user signal into discovery (SDLC gap G1) | Scaffolded — design work not started |
| [`context-decay`](context-decay/README.md) | The context-budget system (measure, warn, roll over) | Dormant — all backlog findings resolved; remaining items externally gated |
| [`devex-review`](devex-review/README.md) | Persona-based DevEx review of this template + fix program | Complete — all review findings carded and fixed (final package: M23 + L35) |
| [`per-item-relaunch-override`](per-item-relaunch-override/README.md) | Per-work-item override of `ROLLOVER_RELAUNCH` | Done — one-shot task, shipped |
| [`quality-gates`](quality-gates/README.md) | Quality-enablement lane: gate policy, test infra, AI failure-triage (SDLC gaps G2+G3) | Scaffolded — design work not started |
| [`sdlc-ai-mapping`](sdlc-ai-mapping/README.md) | Map the full SDLC with AI + template overlay | Closed (2026-08-13) — map signed off, gap dispositions executed; its open gaps live as backlog cards M27–M29/L38/L39 |
| [`template-improvement-review`](template-improvement-review/README.md) | Fresh-eyes review of the template + pooled improvement program over every open thread | Complete (session 4, 2026-09-10): cards M27/M28/M29/L38/L39 + L45 archived, fresh-eyes fixes C2–C12 on main, L45 fix merged (`5fd5480`) after a live worktree probe; main unpushed — user's call; user-only items in its `review.md` §E |
| [`template-maintenance`](template-maintenance/README.md) | Umbrella for ongoing template upkeep (backlog, skill syncs) | Standing — the 5 options-brief cards were built by `template-improvement-review` under stated assumptions (2026-09-10); awaiting the user's review of those choices |
| [`usage-scenarios`](usage-scenarios/README.md) | Scenario catalog for evaluating the template | Maintenance mode — mission complete; catalog kept accurate |
