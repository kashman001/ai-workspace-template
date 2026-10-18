# external-tools-review — decision notes

## 2026-10-18 — REA's research-discipline ideas land in workspace-owned files, not vendored skills
**Chose:** Route T1's borrowed method (close each question as answered / partly / unresolved; give every "not found" its search bound; copied-behaviour vs design-choice split) to `skills/research-wave/SKILL.md` (workspace-owned) and, for the rebuild split, a workspace convention or the optional `study-feature` skill (synthesis R10–R12).
**Because:** `skills/research/` and `skills/prototype/` are vendored from mattpocock/skills with a keep-unmodified rule so `scripts/sync-vendored-skills.sh` refreshes stay a clean re-copy; T1's note proposed editing them.
**Rejected:** Editing the vendored `research` / `prototype` SKILL.md files — breaks the clean-refresh contract; edits would be lost on the next sync.
**Blast radius:** synthesis.md R10–R12 wording; any future card filed from them.
**Promote?:** no — an application of an existing rule.

## 2026-10-18 — HTML twin built on the html-kit prototype
**Chose:** `summary.html` links `../html-kit/prototype/kit/kit.css` and follows its AUTHORING.md (content-only).
**Because:** Cheapest path to a themed, dark-mode page; doubles as a third real page written to the kit's rule.
**Rejected:** A standalone hand-styled page — repeats the design cost the html-kit item exists to remove.
**Blast radius:** if html-kit moves or drops the kit, `summary.html` renders unstyled (content intact).
**Promote?:** no.
