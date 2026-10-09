# code-review: group each axis's findings into blockers and suggestions

**Skill:** `skills/engineering/code-review/SKILL.md`, steps 4–5 (as of `068b6e0`).

**What happens now.** The Standards sub-agent is already told to "distinguish hard violations from judgement calls" (step 4), but the Spec sub-agent has no equivalent, and step 5 presents each axis "verbatim or lightly cleaned". So whether must-fix items are visibly separated from nice-to-haves depends on how each sub-agent happens to format its report. For Spec it often isn't separated at all, and the reader sorts the findings by hand.

**Proposal.** Two small edits. The two-axis separation stays as it is:

1. **Spec brief (step 4):** also mark each finding as a blocker (a missing or wrong requirement) or a suggestion (for example, minor scope creep the author may want to keep).
2. **Aggregate (step 5):** inside each axis, present findings under **Blockers** and **Suggestions**. Standards hard violations go under Blockers. Judgement calls, including every smell-baseline hit, go under Suggestions. The one-line summary becomes: blockers and suggestions per axis, plus the worst blocker within each axis. There is still no merging and no single winner across axes.

**Why.** The reader's first question is "what must I fix before merging?" The Standards brief already collects the information needed to answer it; the report just doesn't use it consistently.

Found while comparing a downstream workspace template (which vendors this skill unmodified) against another harness's review practices. We would rather send it upstream than carry a local patch.
