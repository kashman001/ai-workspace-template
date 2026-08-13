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

| Work item | What it is | Status |
|---|---|---|
| [`automatic-session-rollover`](automatic-session-rollover/README.md) | Hands-free successor relaunch after a context-budget rollover | Dormant — shipped and merged; decision map fully drained |
| [`feedback-intake`](feedback-intake/README.md) | Route production/user signal into discovery (SDLC gap G1) | Scaffolded — design work not started |
| [`context-decay`](context-decay/README.md) | The context-budget system (measure, warn, roll over) | Dormant — all backlog findings resolved; remaining items externally gated |
| [`devex-review`](devex-review/README.md) | Persona-based DevEx review of this template + fix program | Complete — all review findings carded and fixed (final package: M23 + L35) |
| [`per-item-relaunch-override`](per-item-relaunch-override/README.md) | Per-work-item override of `ROLLOVER_RELAUNCH` | Done — one-shot task, shipped |
| [`quality-gates`](quality-gates/README.md) | Quality-enablement lane: gate policy, test infra, AI failure-triage (SDLC gaps G2+G3) | Scaffolded — design work not started |
| [`sdlc-ai-mapping`](sdlc-ai-mapping/README.md) | Map the full SDLC with AI + template overlay | Complete pending user sign-off — map reviewed, gap dispositions executed |
| [`template-maintenance`](template-maintenance/README.md) | Umbrella for ongoing template upkeep (backlog, skill syncs) | Standing — house-sale mission complete (M26+L36+L37); no queued mission |
| [`usage-scenarios`](usage-scenarios/README.md) | Scenario catalog for evaluating the template | Maintenance mode — mission complete; catalog kept accurate |
