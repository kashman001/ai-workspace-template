# 09 — The `plans` skill and `/plan` shortcut

**What to build:** `skills/plans/SKILL.md` (vendor-neutral) with three procedures — create a plan from a spec or from tickets (a ticket becomes a node by gaining frontmatter), run a reconcile node (join, verify on disk, record decisions, replan within the authority tiers), replan — plus the subagent prompt template that allows a subagent to write only its node's Log and Acceptance ticks. `.claude/commands/plan.md` wraps it.

**Blocked by:** 04, 05, 06

**Status:** done (2026-09-24, session 13)

**Spec:** S30, S31

- [x] Worked through once by converting this item's own `issues/` into a plan on the fixture
- [x] Subagent prompt template forbids writing `status` and names the Log line format
- [x] Listed in the CONTEXT.md Workspace Skills section (one line) and `skills/vendored-skills.md` untouched
