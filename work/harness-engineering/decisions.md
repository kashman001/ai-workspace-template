# Decisions — harness-engineering

Tier-2 decision notes (newest on top). Promote lasting-weight ones to
`docs/adr/` via the decision-log skill.

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
