# Next Session — template-improvement-review (session 2)

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, REPLACED at
> each rollover. Past-tense provenance lives in `handoff.md`.
> Convention: docs/work-directory-conventions.md.

## Mission

Drain the remaining `review.md` items, in this order, each verified green:
1. **Backlog card moves** — M27, M28, M29, L38, L39 are built (files listed
   in `handoff.md` top block) but still Open in
   `docs/template-workspace-backlog.html`. Per its "Maintaining this backlog"
   rules: flip badge → Resolved, add a `Fixed:` line naming the files/commit,
   add `class="resolved"`, move each card to the matching section of
   `docs/template-workspace-backlog-archive.html`, update scorecard (0 open /
   85 resolved) + "Last updated", append a change-log row. Grep the ID; never
   load the files whole. L38's Fixed line says "routed into work/quality-gates".
2. **New card A10** (Low): gitignored work dirs don't survive worktree-forced
   background sessions (`work/learn-agentic-workflows/NOTES.md:26-28`).
3. **Fresh-eyes fixes C2–C12** (`review.md` §C) — one subagent pass is fine;
   C3 must also add `adr/` + `postmortems/` to the docs tree and rerun
   `scripts/build-guide-html.sh`. C2(c): locate the real home of
   `probe-results.md` via `git log --all -S probe-results` before repointing.
4. Run all `scripts/tests/test-*.sh` + `scripts/check-workspace-structure.sh`
   + `scripts/check-ledger.py`; commit on the same branch; mark items done in
   `review.md`; update `work/README.md` row; then `checkpoint`.

Unattended is fine — the user authorised autonomous improvement
(2026-09-10). Do not re-open the 5 design choices (`decisions.md`).

## Read these, in order

1. `work/template-improvement-review/review.md` (the list; statuses inline)
2. `work/template-improvement-review/handoff.md` — top block only
3. `work/template-improvement-review/decisions.md`

## Do NOT reload

- The other work items' launchers/ledgers — surveyed in s1; conclusions are in `review.md`.
- `work/template-maintenance/open-cards-options-brief.md` — choices made.
- `work/context-decay/*` — validation done; its follow-up belongs to that item.

## State snapshot

- Branch `review/template-improvement-review-s1` (1 commit `dc1f334` ahead of
  main; main itself is 3 ahead of origin/main, unpushed). Nothing merged.
- Suites: 21/21 green post-change; structure + ledger checks clean.
- User-only items to surface at checkpoint: `review.md` §E.

## First actions

1. `scripts/context-budget.sh register --project template-improvement-review`
2. `git status --short && git log --oneline -3` — expect the branch above, clean tree.
3. Continue per Mission.
