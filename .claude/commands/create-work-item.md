---
description: Scaffold a new work/<project>/ directory following the work-directory conventions (README + launcher + ledger)
argument-hint: "<project-name> [one-line description]"
---

New work item: **$ARGUMENTS**

Execute the **create-work-item** workflow defined in `skills/create-work-item/SKILL.md` —
follow its procedure to scaffold `work/<project-name>/` with the standard backbone
(`README.md` + forward launcher `next-session.md` + append-only ledger `handoff.md`),
per `docs/work-directory-conventions.md`.

Confirm the hyphenated project name and governing skill(s) first if unclear. Keep
project-specific detail out of global files — the work directory is
developer-scoped.
