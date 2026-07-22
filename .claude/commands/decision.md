---
description: Capture the why behind a decision (Tier-2 note), or promote a note to an ADR
argument-hint: "<the decision + why, and the alternative you rejected>   (or: promote <note-anchor|slug>)"
---

Decision to log: **$ARGUMENTS**

Execute the **decision-log** skill defined in `skills/decision-log/SKILL.md`.

- Default: append a **Tier-2 note** to `work/<project-name>/decisions.md` in the
  skill's format (Chose / Because / Rejected / Blast radius / Promote?). Get the date from
  `date +%F`. If the decision has no real rejected alternative, say so — it may not need a note.
- If the argument starts with `promote`: run the skill's **promotion** steps — copy
  `docs/adr/0000-template.md` to the next `docs/adr/NNNN-slug.md`, fill it from the note
  (including the Provenance block), update the `docs/adr/README.md` index, flip the note's
  `Promote?:` to `done → ADR-NNNN`, and run `graphify update .` if a graph exists.

Keep it tight — this is a capture step, not an essay. Never write secrets into a note or ADR.
