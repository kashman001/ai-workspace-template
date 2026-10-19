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
| [`jev-integration`](jev-integration/README.md) | Evaluate and, if it fits, integrate TypeSafe's Jev typed-decision model into the template | Finished (2026-09-27, s16) — shipped gated on a key, plan closed 18/18, spec approved, tickets 01–07 resolved |
| [`kimi-k3-agent-integration`](kimi-k3-agent-integration/README.md) | Bring Kimi K3 (Moonshot) in as an agent runtime | Stalled since 2026-08-10 — waiting on the user's runtime choice (4 options in its launcher) |
| [`feedback-intake`](feedback-intake/README.md) | Route production/user signal into discovery (SDLC gap G1) | Scaffolded — design work not started |
| [`runtime-session-identity`](runtime-session-identity/README.md) | Probe and fix session-id pinning for Codex, Copilot and Antigravity (CLI + IDE) | Finished (2026-10-18, s14) — plans 01 and 02 closed; Antigravity IDE/app and Codex desktop probes deferred to backlog L86 |
| [`context-memory-hardening`](context-memory-hardening/README.md) | Ship the accepted context/memory-engineering recommendations (L49, L50, M43, L51, D5) | Finished — tickets 01–05 done (L49, L50, M43, L51 resolved; D5 decided as ADR-0013); follow-up L52 on the backlog |
| [`backlog-sweep`](backlog-sweep/README.md) | Close the open template backlog cards an agent can close (L85, L95, L96, L98; L86 via the user) as one parallel plan | Active — plan 01-open-cards, wave 1 |
| [`clear-session-loop`](clear-session-loop/README.md) | Research whether `/clear` can drive the session loop across runtimes; spec it if so | Finished (2026-10-15, s6) — S13 shipped (L90), S4 retired, `/clear` probe FAIL ×2 → docs say "press `/clear`, then type `go`" (L92); follow-up L91 open |
| [`concurrent-sessions`](concurrent-sessions/README.md) | Research whether several sessions can own parts of one work item at once | Scaffolded — research not started |
| [`html-kit`](html-kit/README.md) | Prototype a shared HTML kit so agents write content-only pages | Scaffolded — prototype kit next (s2) |
| [`external-tools-review`](external-tools-review/README.md) | Evaluate REA, CLI-Anything, Claude Code redesigned Projects and Phonon-2 for what the template could adopt; one holistic synthesis | Scaffolded — research tracks T1–T4 next (s1) |
| [`deep-seek-harness-eval`](deep-seek-harness-eval/README.md) | Study DeepSeek Harness (`deepseek-ai/deepseek-harness`) for practices this template could adopt | Finished (2026-10-08, s3) — all seven recommendations accepted, filed as backlog cards M46, M47, L66–L70 |
| [`context-memory-eval`](context-memory-eval/README.md) | Evaluate the workspace against an outside context/memory-engineering framework (@marfinxx article) | Closed — recs 1–4, 6 shipped via `context-memory-hardening`; 5 deferred (`decisions.md`) |
| [`context-decay`](context-decay/README.md) | The context-budget system (measure, warn, roll over) | Dormant — all backlog findings resolved; remaining items externally gated |
| [`devex-review`](devex-review/README.md) | Persona-based DevEx review of this template + fix program | Complete — all review findings carded and fixed (final package: M23 + L35) |
| [`per-item-relaunch-override`](per-item-relaunch-override/README.md) | Per-work-item override of `ROLLOVER_RELAUNCH` | Done — one-shot task, shipped |
| [`plans`](plans/README.md) | Explore "plans": graph + loops + sessions for dependency-, parallelism-, and LLM-tier-aware work | Finished (2026-09-30, s19) — tickets 01–15 done: `plan.sh`, the `session-loop.sh` plan hook, skill hooks, the `plans` skill + `/plan`, front door; first real plan `jev-integration/plans/01-gated-integration` closed 18/18; dogfood fixes (ledger lint, open-plan default, ergonomics, wording) landed |
| [`harness-engineering`](harness-engineering/README.md) | Make the template's own checks run themselves and catch drift (cards M44, M45, L60–L62; Böckeler harness-engineering article) | Finished 2026-10-08 — all 5 tickets done; follow-ups L64, L65 |
| [`quality-gates`](quality-gates/README.md) | Quality-enablement lane: gate policy, test infra, AI failure-triage (SDLC gaps G2+G3) | Scaffolded — design work not started |
| [`sdlc-ai-mapping`](sdlc-ai-mapping/README.md) | Map the full SDLC with AI + template overlay | Closed (2026-08-13) — map signed off, gap dispositions executed; its open gaps live as backlog cards M27–M29/L38/L39 |
| [`template-improvement-review`](template-improvement-review/README.md) | Fresh-eyes review of the template + pooled improvement program over every open thread, then the session-management redesign (Stage 4) | Closed (session 23, 2026-09-22): review list drained, Stage 4 cut over to main (`37d4100`), L47/M39 fixed; open engineering threads handed to `session-management-followups` |
| [`session-management-followups`](session-management-followups/README.md) | Close the three engineering threads left open after the Stage 4 cutover (`.active-session` readers, one ledger-heading rule, template version marker) | Closed (session 4, 2026-09-22) — all three tickets done: M40, M41, M42 |
| [`template-maintenance`](template-maintenance/README.md) | Umbrella for ongoing template upkeep (backlog, skill syncs) | Standing — backlog empty after s22 (L70, M48, L71 resolved); nothing queued |
| [`usage-scenarios`](usage-scenarios/README.md) | Scenario catalog for evaluating the template | Maintenance mode — mission complete; catalog kept accurate |
