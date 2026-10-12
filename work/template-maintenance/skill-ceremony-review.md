# Code review — plan 01-skill-ceremony (node 11)

Range: `8e16d66..HEAD` (5e92f27, e86b89f, e76ad8b, e5bed63). Reviewer s24-g,
both axes run sequentially by one agent. Plan state files under
`work/template-maintenance/plans/` and the brief/report excluded except as spec.

Commands run:

- `bash scripts/tests/test-check-skill-descriptions.sh` → `11 passed, 0 failed`
- `bash scripts/check-skill-descriptions.sh` → `total: 7303 bytes over 29 model-invoked skills (budget 7500)`, exit 0
- `bash scripts/tests/test-agent-entrypoints.sh` → `pass=14 fail=0` (E6b covers the three new user-invoked skills generically)
- `cd skills/<name> && patch -p1 -R -F0 -N --dry-run -i workspace.patch` for constraint-driven-development and doubt-driven-development → both exit 0
- Forward check in scratch: reverse-apply each patch onto a copy, forward-apply it again, `cmp` with the on-disk file → both identical; both patches still open with `Upstream: none filed`
- Edge probe of the budget check in scratch (CRLF frontmatter, `>-` with a blank line, `disable-model-invocation: true # comment`, `description:` in the body) → all handled as intended
- `bash scripts/run-checks.sh` → `44 passed, 0 failed, 0 skipped (151s)`
- Spot-checked trigger-review verdicts against on-disk frontmatter: decision-log 305, jev 303, technical-writing 197, unslop 156, constraint-driven-development 335 → all match; checkpoint, session-rollover, design-for-testability absent from the count
- Three new `agents/openai.yaml` compared with plans, create-work-item, wayfinder → same shape; `.claude/commands/` shortcuts exist for all three
- Stale-claim greps (`Must always apply`, `whenever prose`, `model-invoked` in CONTEXT/docs/vendored-skills/README) → no false sentence left outside the backlog
- `wc -c CONTEXT.md` → 14,260 (under 16K)

## Standards

### Blockers

None.

### Suggestions

- scripts/tests/test-check-skill-descriptions.sh:36 — `run()` is defined and never called (and would pass the fixture dir to `env` as a command) — an orphan the change created (CONTEXT.md, surgical changes) — delete the line.
- scripts/tests/test-check-skill-descriptions.sh:32 — fixtures cover `>` only; the CRLF strip (check line 29) and `>-` (the form decision-log, jev and design-for-testability use) have no case that would go red if broken — add one CRLF fixture and switch the folded fixture to `>-`.
- scripts/check-skill-descriptions.sh:35 — detects user-invoked with a prefix match (`true` followed by anything), while scripts/tests/test-agent-entrypoints.sh:106 requires `true` then end of line; the two detectors can disagree on `true # note` — possible Duplicated Code — anchor line 35 to `[ \t]*$` like E6.
- docs/workspace-structure.md:416, :649, :716 and skills/vendored-skills.md:58 — the number 7,500 is restated in four places though the script calls it a ratchet that moves — a cache of the environment (writing-for-agents, Pruning) that goes stale on the next change — name the check and drop the number outside workspace-structure.md:649.
- docs/workspace-structure.md:363 and :417 — the same stakes-to-ceremony pointer twice in one file — duplication (writing-for-agents, single source of truth) — keep one.
- docs/recommended-tooling.md:263 and skills/vendored-skills.md:142 — the `/build auto` → `implement-spec` mapping is stated twice — duplication — keep it in vendored-skills.md beside the other pack mappings.
- CONTEXT.md:117-118, :121 — research-wave and wayfinder carry "user-invoked only" but the three newly user-invoked skills do not; for session-rollover the label would mislead, since agents must still run it on STOP by reading the file — leave as is, or add "(run by path)" to session-rollover only if a session is seen trying the skill tool and stopping.

## Spec

### Blockers

None.

### Suggestions

- skills/unslop/SKILL.md:3 — brief item 2 asked for `unslop` to be narrowed "through a `workspace.patch`"; it was edited in the adapted frontmatter instead — correct per the adapted class and recorded in decisions.md — no change; state the deviation in the report to the user.
- work/template-maintenance/skill-packs-analysis.md:181-186 — the addendum lists the user-invokes and vendored tightenings but omits the `decision-log` (910 → 305) and `jev` (482 → 303) tightenings — the record of what was applied is incomplete — add one bullet.
- docs/template-workspace-backlog.html:146 — M51 evidence says "34 model-invoked descriptions total about 8.7 KB"; the measured baseline is 10,174 bytes over 32 — false once M51 is resolved — correct the numbers when writing the `Fixed:` note.
