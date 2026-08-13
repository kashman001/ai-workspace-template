---
description: Multi-perspective review of a technical document — audience gate, parallel reviewers, prioritized synthesis
argument-hint: "<path to document>   (or paste the content after invoking)"
---

Doc review request: **$ARGUMENTS**

Execute the **doc-review** skill defined in `skills/doc-review/SKILL.md` —
follow its phases in order (Phase 0 audience gate → Phase 1 parallel reviewer
subagents → Phase 2 synthesis) on the document above. If no path or content
was given, ask for it first.

Hard rules from the skill: no reviewing and no subagent dispatch until the
user has confirmed the audience model; reviewers never see each other's
findings; diagnose — do not rewrite unless asked.
