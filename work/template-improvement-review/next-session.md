# Next Session — template-improvement-review (session 4)

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, REPLACED at
> each rollover. Past-tense provenance lives in `handoff.md`.
> Convention: docs/work-directory-conventions.md.

## Mission

Finish **L45** (built and committed on `fix/l45-gitignored-work-dirs` as
`5f51898`, unmerged): (1) live end-to-end probe — spawn an `Agent` with
`isolation: "worktree"` and have it run `git -C "$PWD" rev-parse --show-toplevel`,
`ls -la work/ | grep learn`, and append one line to
`work/learn-agentic-workflows/.l45-probe` — then confirm from the main
checkout that `work/learn-agentic-workflows/.l45-probe` exists and that
`.git/info/exclude` gained an exact `work/learn-agentic-workflows` line;
delete the probe file after. If the link did not appear, check which copy of
the hook lib the subagent's hooks ran (`$CLAUDE_PROJECT_DIR` vs the
worktree) and note it in `operational-knowledge.md`'s L45 entry; fix only if
small. (2) Merge the branch into main (`--no-ff`), run all suites +
`scripts/check-workspace-structure.sh` + `scripts/check-ledger.py`.
(3) `checkpoint` — item state becomes **complete**; push stays the user's call.

Unattended is fine (standing authorisation 2026-09-10). Do not push.

## Read these, in order

1. `work/template-improvement-review/handoff.md` — top block only
2. `work/template-improvement-review/decisions.md` — top note only
3. `scripts/link-local-work.sh` header comment (18 lines)

## Do NOT reload

- `review.md`, the backlog HTML files whole, other items' launchers.
- `docs/operational-knowledge.md` whole — grep "Local-only work items".

## State snapshot

- Checkout on `fix/l45-gitignored-work-dirs` (`5f51898`), clean; main at
  `6f8c6c2`, 8 ahead of `origin/main` (`ccbb27a`), unpushed by design.
- 22 suites green (incl. new `test-link-local-work.sh`, 30 asserts);
  structure + ledger checks clean. Backlog 0 open / 87 resolved.

## First actions

1. `scripts/context-budget.sh register --project template-improvement-review`
2. `git status --short && git log --oneline -2 && git branch --show-current`
   — expect `5f51898` on the fix branch, clean.
3. Continue per Mission step (1).
