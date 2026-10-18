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

## 2026-10-18 — Disposition of R1–R24
**Chose:** Accept the synthesis as recommended (user: "I agree with your recommendations"). Defaults for the three user's-call items, confirmed by the user: R6 = reword the doc (not a CLI mode); R12 = no (so R11 drops with it); R18 = later. R5 = later. Filed: L94 (doc pass: R6–R10, R13–R17, R20, R22–R24), L95 (dispatch contract: R2–R4, R19), L96 (R21 overnight-chain risk), L97 (R5), L98 (R18); R1 = `work/concurrent-sessions/input-external-tools-review.md`.
**Because:** Most items are a few lines each in distinct files — one doc pass beats a card per item; R2–R4 + R19 change `scripts/fleet.sh`, which every dispatched child depends on, so they get a test-first work item.
**Rejected:** R11 + R12 (a `study-feature` skill for rebuilding outside apps' features, and its copied-vs-chosen split) — no current need to study outside apps; R11 only mattered with R12. Adding a CLI mode to `youtube_transcript_mcp.py` (R6 alt) — rewording removes the inaccuracy at near-zero cost.
**Blast radius:** backlog L93–L98; `work/concurrent-sessions/` README Files list.
**Promote?:** no.
