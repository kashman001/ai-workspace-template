# Next Session — template-improvement-review (session 3)

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, REPLACED at
> each rollover. Past-tense provenance lives in `handoff.md`.
> Convention: docs/work-directory-conventions.md.

## Mission

Build backlog card **L45** (user-approved 2026-09-10): gitignored `work/`
directories are absent from the worktree the repo guard forces background
sessions into, and the worktree is deleted at session end, so local-only work
items lose a background session's output unless someone copies it back by
hand. Deliver: (1) find the guard that redirects background/worktree sessions
(grep `worktree` in `.claude/settings.json`, `scripts/hooks/`, `.claude/`);
(2) pick the smallest fix — exempt gitignored `work/<item>/` dirs from the
redirect, or copy them back on worktree exit / in `rollover-prep.sh` — and
record the choice + rejected alternative in `decisions.md`; (3) implement it
test-first (extend the matching `scripts/tests/test-*.sh`, or add one);
(4) document the trap and the fix in `docs/work-directory-conventions.md`
(local-only items) and `docs/operational-knowledge.md`; (5) resolve card L45
in `docs/template-workspace-backlog.html` per its "Maintaining" rules (grep
the ID; archive the card; scorecard 0 open / 87 resolved; change-log row);
(6) run all suites + `scripts/check-workspace-structure.sh` +
`scripts/check-ledger.py`; commit on the branch; then `checkpoint`.

Work on a branch: `git checkout -b fix/l45-gitignored-work-dirs main`.
Do not push. Unattended is fine (standing authorisation 2026-09-10).

## Read these, in order

1. The L45 card: `grep -n -A16 'id">L45' docs/template-workspace-backlog.html`
2. `work/learn-agentic-workflows/NOTES.md` lines 26-28 (the evidence; local-only file — skip if absent)
3. `work/template-improvement-review/handoff.md` — top block only
4. `work/template-improvement-review/decisions.md` — top note only

## Do NOT reload

- `review.md` — drained; only §E (user-only items) remains and needs no agent.
- The options brief, other items' launchers, `work/context-decay/*` — settled.
- Either backlog HTML file whole — grep the ID.

## State snapshot

- Checkout on `main` (`0cba137`), clean tree; main is 7 ahead of
  `origin/main` (`ccbb27a`), unpushed by design.
- Suites 21/21 green + ledger-checker suite; structure + ledger checks clean.
- Backlog: 1 open (L45) / 86 resolved.

## First actions

1. `scripts/context-budget.sh register --project template-improvement-review`
2. `git fetch && git status --short && git log --oneline -3` — expect main at
   `0cba137`, clean; if origin moved, merge it before branching.
3. `git checkout -b fix/l45-gitignored-work-dirs main`, then continue per Mission.
