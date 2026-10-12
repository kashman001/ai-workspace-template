---
id: 06-apply-trigger-verdicts
title: Apply the trigger verdicts to workspace skills; set the description budget
status: doing
kind: work
wave: 2
blocked_by: [02-trigger-review, 03-budget-check, 04-anti-rationalization]
sessions: [24]
---

## Goal

Apply `work/template-maintenance/trigger-review.md` to the workspace-authored
skills: tightened descriptions in the frontmatter; for each skill that
becomes user-invoked add `disable-model-invocation: true`, an
`agents/openai.yaml` with `allow_implicit_invocation: false` (copy the shape
of `skills/to-spec/agents/openai.yaml`), and a `.claude/commands/<name>.md`
shortcut if missing (shape of `.claude/commands/checkpoint.md`). Then run
`scripts/check-skill-descriptions.sh`, read the new total, and set
`SKILL_DESC_MAX_BYTES` to the value the review file names (or the new total
rounded up to the next 500 with the reason in the comment). Shared files
(`CONTEXT.md`, `skills/vendored-skills.md`, `docs/*`) stay untouched: list
the wiring lines the orchestrator must add in the Log.

## Acceptance

- [ ] Every verdict in the review file applied; `git diff --stat` matches the table
- [ ] Each new user-invoked skill has the three pieces (frontmatter flag, openai.yaml, command)
- [ ] `SKILL_DESC_MAX_BYTES` set with its reason; `scripts/check-skill-descriptions.sh` and its test pass
- [ ] Wiring lines for the shared files listed in the Log

## Log
- s24 · started, tier standard
