---
id: 06-apply-trigger-verdicts
title: Apply the trigger verdicts to workspace skills; set the description budget
status: done
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

- [x] Every verdict in the review file applied; `git diff --stat` matches the table
- [x] Each new user-invoked skill has the three pieces (frontmatter flag, openai.yaml, command)
- [x] `SKILL_DESC_MAX_BYTES` set with its reason; `scripts/check-skill-descriptions.sh` and its test pass
- [x] Wiring lines for the shared files listed in the Log

## Log
- s24 · started, tier standard
- s24-e · applied tighten rows: skills/decision-log/SKILL.md (910 -> 305 B), skills/jev/SKILL.md (482 -> 303 B), folded form and allowed-tools kept; SKILL.md diffs are frontmatter-only (git diff --stat).
- s24-e · user-invoked checkpoint, session-rollover, design-for-testability: description + `disable-model-invocation: true` in their SKILL.md; new skills/{checkpoint,session-rollover,design-for-testability}/agents/openai.yaml (allow_implicit_invocation: false); .claude/commands/{checkpoint,session-rollover,design-for-testability}.md verified present, untouched.
- s24-e · scripts/check-skill-descriptions.sh: SKILL_DESC_MAX_BYTES default 7500, comment carries the ratchet rationale. Check output: total 7303 bytes over 29 model-invoked skills (budget 7500), exit 0. test-check-skill-descriptions 11/0, test-agent-entrypoints 14/0 (incl. E6b manual-only agreement), check-workspace-structure all passed.
- s24-e · wiring for orchestrator (grep of the six shared files; "Must always apply", "whenever prose" "commit messages" hits listed):
- s24-e ·   skills/vendored-skills.md:182 · unslop line says "Model-invoked so it applies whenever prose is produced": reword to "final editing pass on human-facing prose; not code, commit messages or skill text".
- s24-e ·   skills/vendored-skills.md:56 · "the rest are model-invoked": still true for the pack list; check that checkpoint/session-rollover/design-for-testability are not claimed as model-invoked anywhere nearby; add technical-writing note (trigger now doc/README/RFC/PR description, no /technical-writing, no commit messages) to its catalog line.
- s24-e ·   skills/vendored-skills.md:125 · "All model-invoked" for the Addy pack: verify against the constraint-driven / doubt-driven patch wording (descriptions tightened, still model-invoked); likely no change.
- s24-e ·   skills/vendored-skills.md:40 · generic user/model-invoked note: no change needed.
- s24-e ·   docs/recommended-tooling.md:215 · "model-invoked `grilling`": unrelated to these three; no change.
- s24-e ·   CONTEXT.md, docs/workspace-structure.md, README.md, docs/for-non-engineers.md · no matching lines; if a "(slash)" or user-invoked marker list exists for workspace skills, add checkpoint, session-rollover, design-for-testability (review file says the (slash) markers are already right).
- s24-e · on disk: five frontmatter edits, three openai.yaml, budget 7500 + comment, all checks green. Not on disk: shared-file wiring above, Tier-2 notes copy, any commit.
- s24 · done
