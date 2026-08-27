---
description: Research several subjects in parallel, then verify each result with an independent fact-checker before the claims go anywhere
argument-hint: "<subjects to research>   (or describe the comparison after invoking)"
---

Research wave request: **$ARGUMENTS**

Execute the **research-wave** skill defined in `skills/research-wave/SKILL.md`
— follow its phases in order (Phase 0 scope gate → Phase 1 launch every pass
→ Phase 2 independent fact-check → Phase 3 rule and apply → Phase 4
cross-subject sweep). If the subjects or the schema were not given, gate on
them first.

Hard rules from the skill: launch every pass before reading any return; each
agent reports to a file and returns ~12 lines, never a full record into chat;
the fact-check for a subject goes to an agent that did none of its research;
fact-checkers recommend, you rule, a corrections agent applies; corrections
agents re-derive numbers rather than trusting your summary. The three
reference briefs under `skills/research-wave/references/` are handed to
agents, not read into your own context.
