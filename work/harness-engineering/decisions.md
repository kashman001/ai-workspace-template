# Decisions — harness-engineering

Tier-2 decision notes (newest on top). Promote lasting-weight ones to
`docs/adr/` via the decision-log skill.

## 2026-10-08 — check-drift.sh is a full-tier check, not pre-commit (ticket 02)

- **Decision:** the drift sweep is a `check-*` script, so run-checks and CI
  run it, but it carries `# run-checks: slow` (it takes 0.5s) and CI gains a
  weekly `schedule:` on the existing workflow rather than a separate job.
- **Why:** a gotcha can age past review with no commit, and only a person
  can re-confirm one. In pre-commit that would block unrelated commits and
  unattended agents. The weekly run surfaces aging nobody committed.
- **Rejected:** keeping it out of run-checks (CI only) — dead paths a commit
  adds would land unnoticed; a separate scheduled job for drift alone — a
  second workflow for a 0.5s check, when the weekly full run also catches
  runner and environment rot.

## 2026-10-08 — drift allow-list lives in the script, prefix-matched (ticket 02)

- **Decision:** one `ALLOW` heredoc in `scripts/check-drift.sh`, one path
  prefix per line with a `#` reason. CONTEXT.md budget 16,000 bytes
  (~4K tokens, the L51 target). `docs/` dotfiles need no index entry.
- **Why:** the ticket asks for one place with a reason per entry; a
  prefix covers a whole vendored upstream tree in one line.
- **Rejected:** a separate allow-list file — a second file to keep in step
  for eight lines; matching by (file, path) pair — precise but every
  vendored refresh would churn it.

## 2026-10-08 — run-checks.sh tiers by a marker in each script, not a list (ticket 01)

- **Decision:** a check opts out of `--fast` with a `# run-checks: slow` line;
  everything else is fast. Exit 77 means skip with a reason.
- **Why:** new suites are picked up with no list to update, and the default
  (fast) keeps them in pre-commit until someone measures them as slow. The
  marker sits next to the code that makes the check slow.
- **Rejected:** a slow/fast list inside `run-checks.sh` — goes stale the
  moment a suite is added or speeds up; a time budget measured at run time —
  non-deterministic tiers.

## 2026-10-08 — pre-commit via core.hooksPath, CI on by default (ticket 01)

- **Decision:** `scripts/git-hooks/pre-commit`, enabled per clone with
  `git config core.hooksPath scripts/git-hooks`; the GitHub workflow ships
  enabled and adopters delete it to opt out.
- **Why:** hooksPath needs no install script and does nothing until a person
  opts in, which the ticket requires. CI costs adopters nothing until they
  push to GitHub, and deleting one file is a clear opt-out.
- **Rejected:** a `setup.sh` step that copies into `.git/hooks` — silently
  turns hooks on for adopters and drifts from the checked-in copy;
  Husky/npm — the template is bash.
