---
id: 04-anti-rationalization
title: Anti-rationalization tables for the workspace skills
status: done
kind: work
wave: 1
blocked_by: []
sessions: [24]
---

## Goal

Brief item 3. Add a short "Common rationalizations" table (Addy's format:
`| Rationalization | Reality |`, see `skills/code-simplification/SKILL.md`
→ "Common Rationalizations") to the workspace-authored skills where agents
cut corners: `skills/checkpoint/SKILL.md`, `skills/session-rollover/SKILL.md`,
`skills/decision-log/SKILL.md`, `skills/create-work-item/SKILL.md`,
`skills/plans/SKILL.md` (the reconcile step's verification). 3–6 rows each,
each row a failure mode actually recorded in
`work/template-maintenance/handoff.md`, `handoff-archive.md` or
`docs/template-workspace-backlog-archive.html` (cite the session or card in
the Log, not in the table). No tables in vendored skills. Follow
`skills/writing-for-agents/SKILL.md`. Do not touch frontmatter.

## Acceptance

- [x] Five skills carry a `## Common rationalizations` table of 3–6 rows
- [x] Each row traces to a recorded failure (Log lists skill → row → source)
- [x] No vendored skill changed (`git status` shows only the five files)

## Log
- s24 · started, tier standard
- s24-d · checkpoint → 5 rows → (1) backlog not reconciled for outside deliveries: backlog-archive L14 + template-improvement-review ledger s1 (M38's missing change-log row); (2) stale work-index row: jev-integration handoff-archive ("running its plan", fixed 5139560); (3) ledger block redo/splice: memory verify-ledger-after-write (plans s15); (4) clean-tree assumption: memory recheck-head-before-rewriting-other-items (2026-09-25); (5) quit without ledger block: backlog-archive M35 evidence. On disk: skills/checkpoint/SKILL.md
- s24-d · session-rollover → 3 rows → (1) one more unit past WARN: backlog-archive M18 (10–20K rollover cost, STOP rollovers at 170–190K); (2) handoff written ≠ rollover done: backlog-archive M38 (step skipped, chain idle ~5h); (3) launcher appended: docs/work-directory-conventions.md "two-file backbone" (conflation = main cause of accretion). On disk: skills/session-rollover/SKILL.md
- s24-d · decision-log → 3 rows → (1) Promote?: yes left unpromoted: backlog-archive L72; (2) read+edit of decisions.md: backlog-archive L26 (~45KB); (3) inputs left in /tmp: work/jev-integration/decisions.md threshold note Caveats (s13 descriptions never recorded). On disk: skills/decision-log/SKILL.md
- s24-d · create-work-item → 3 rows → (1) ad hoc folder: docs/template-workspace-backlog.html change log 2026-07-23 bd40023 (context-decay migrated, ledger rebuilt from git history); (2) nonstandard ledger heading: backlog-archive M33; (3) gitignored local-only item: backlog-archive L45. On disk: skills/create-work-item/SKILL.md
- s24-d · plans → 4 rows → (1) reconcile ticked on a subagent's word: template-improvement-review handoff-archive s1 Learnings (survey claimed a nonexistent branch); (2) sync before done: work/plans/decisions.md s15 jev bullet (a); (3) skip read as pass: backlog-archive M47; (4) paid/key node created as work: work/plans/decisions.md s14 jev bullet. On disk: skills/plans/SKILL.md
- s24-d · not used, no source found: "backlog is empty" asserted from memory; ROLLOVER_RELAUNCH=auto not launched; hand-editing node status; rollover option capture (L20, now scripted out of the skill); `sync` stale binding (s18, since fixed in plan resolution). git status: only these five files changed under skills/ (other modified paths belong to sibling nodes); check-workspace-structure.sh exit 0. On disk: the five SKILL.md bodies above, frontmatter untouched
- s24 · done
