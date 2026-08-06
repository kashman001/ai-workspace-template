# Decisions — per-item-relaunch-override

Tier-2 decision notes (see `skills/decision-log/SKILL.md`). Newest on top.

## 2026-08-06 — Per-item relaunch policy lives in a committed work/<project>/context-budget.env

**Decision:** a work item overrides the workspace-global `ROLLOVER_RELAUNCH`
(and `ROLLOVER_RUNTIME`) via an optional, **committed**
`work/<project>/context-budget.env`, sourced by
`scripts/launch-next-session.sh` after the global file. Precedence: explicit
environment variable > per-item file > global `context-budget.env` >
built-in default (`off`). Design settled in discussion 2026-08-06; task brief
at `work/per-item-relaunch-override/README.md`.
**Why:** the motivating item (`work/automatic-session-rollover/`) wants
hands-free `auto` STOP→successor chaining while the workspace default stays
`manual`. Same file name/shape as the global env so per-item WARN/STOP
thresholds could ride in later without a rename (not wired now — YAGNI).
Committed because it is standing policy that should apply to workspace
clones, unlike the per-launch state files.
**Rejected:** carrying the knob in `work/<project>/.rollover-options`. That
file is a *record of how the last session was launched* — written from
knowledge at rollover, possibly absent, replaced over time. A standing policy
knob there would be clobbered or lost by the session-rollover skill's normal
write behavior. Policy and provenance stay in separate files.
**Blast radius:** `scripts/launch-next-session.sh` sourcing block (moved
below arg parsing), its test suite, `docs/context-budget.md`, `CONTEXT.md`,
`skills/session-rollover/SKILL.md`, plus the motivating
`work/automatic-session-rollover/context-budget.env`.
**Promote?:** no.
