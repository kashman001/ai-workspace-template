# Catchup prompt — context-memory-hardening (paste into a new agent session)

> **This file is the LAUNCHER.** Forward-only, REPLACED at each rollover.
> Provenance lives in `handoff.md`. Convention: docs/work-directory-conventions.md.

## Mission

The five tickets are done and pushed. The user asked for one follow-up:
**review the workspace documentation and report the gaps** — first, gaps
left by this work item's changes; then any other documentation gaps you find.
This is a review: report findings to the user, don't fix them unless asked.

## First actions

1. `scripts/context-budget.sh register --project context-memory-hardening`
2. List what this item changed: `git log --stat a753c1b..64f8908`.
3. **Gaps from this change.** For each change below, check the docs that
   should mention it but may not. Use `grep`, not whole-file reads.
   - `Last confirmed` dates, 6-month review, ADD/UPDATE/SUPERSEDE/NOOP
     (`docs/operational-knowledge.md` header, `skills/checkpoint/SKILL.md`
     → "Classify before you write") — are `docs/work-directory-conventions.md`,
     `docs/zoom-model.md`, `docs/for-non-engineers.md`, `docs/postmortems/`
     README, and `docs/template-usage.md` consistent with it?
   - `cache_read_share` / `cache=NN%` (`docs/context-budget.md` → Ledger) —
     is it explained wherever the record/check output is shown?
   - "Cache the prefix, vary the tail" and the date-line warning — reflected
     in `docs/workspace-structure.md` / `docs/template-usage.md` guidance on
     editing `CONTEXT.md`?
   - `CONTEXT.md` trim (L51) — does any doc still say a detail "is in
     CONTEXT.md" that now lives elsewhere? (`git show 9d79e6d -- CONTEXT.md`
     for what moved.)
   - ADR-0013 + the "scan headings" rule — referenced from
     `docs/zoom-model.md` / memory docs where retrieval is described?
   - Is the change recorded for downloaders (`TEMPLATE_VERSION`,
     `docs/template-usage.md` / changelog, if the repo keeps one)?
4. **Other gaps.** Sweep `docs/README.md` (the doc index) against `ls docs/`;
   run `bash scripts/tests/test-doc-consistency.sh`; spot-check for dead
   path references (`git grep -oE '`(docs|skills|scripts)/[^` ]+`'` and test
   each path exists). Note other gaps you meet, ranked.
5. Report to the user as one prioritized list (gap · where · suggested fix),
   plain language. Offer to file the real ones as backlog cards.

**No human in the loop:** do steps 1–4, write the findings to
`work/context-memory-hardening/doc-gap-review.md`, commit it, and stop with
the offer from step 5 still open.

## Read these, in order

1. `work/context-memory-hardening/handoff.md` (top block)
2. `work/context-memory-hardening/README.md` (only if you need the scope)

## Do NOT reload

- Vector search / MMR / decay — settled in ADR-0013 (reason corrected after a
  prototype check); don't re-research.
- L52 — fixed and archived.

## State snapshot

`main` clean and pushed (0 ahead of origin at `64f8908`). Backlog: 0 open.
