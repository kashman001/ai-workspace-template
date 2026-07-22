# Handoff — context-decay (2026-07-22)

Backward-looking record of the implementation session. Forward plan: `next-session.md`.

## What shipped

The full Context Budget & Session Rollover system from
`context-decay-spec.md`, adapted to this workspace and pushed as
`3c7b44a feat: context-budget measurement + session-rollover system (D4)`
(preceded by `b5dd712`, which dropped the `<username>_` prefix from `work/` naming — D3).

- `scripts/context-budget.sh` — per-runtime exact measurement, `check|register|record|watch`, exit 0/1/2.
- `scripts/hooks/context-budget-claude-hook.sh` — PostToolUse WARN/STOP hook; live wiring in gitignored `.claude/settings.json`, shipped block in `.claude/settings.json.example`.
- `context-budget.env` — thresholds 150K STOP / 120K WARN (checked in).
- `skills/session-rollover/SKILL.md` + `/session-rollover` command.
- Measured-checkpoint clauses in `skills/onboard-repo` and `skills/rlm`.
- `docs/context-budget.md`; `CONTEXT.md` "Context Budget" section + skills entry; `workspace-structure.md`(+html) in six places; `template-usage.md`; backlog entry **D4**; `.gitignore` `.context-budget/`.
- `design.html` (design doc), `decisions.md` (4 adaptation notes, all `Promote?: no`).

## Verification

All spec §10 checks passed: syntax, exact measurement of the implementing session,
forced STOP/WARN exit codes, register/record artifacts, all six hook behaviors
(escalation-only, suppression, reset, throttle), `check-workspace-structure.sh` green.
**Live proof:** the hook fired a real WARN at 124,804 tokens mid-implementation —
this rollover is the system's own protocol being followed.

## State at handoff

Working tree clean on `main`, pushed, except the append-only ledger
(`context-ledger.jsonl`) which grows on every `record` — committed with this handoff.
`.claude/settings.json` (hook wiring) and `.context-budget/` are local-only by design.
