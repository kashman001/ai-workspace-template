# Catchup prompt — template-maintenance (paste into a new agent session)

> **This file is the LAUNCHER.** Forward-only, REPLACED at each rollover.
> Provenance lives in `handoff.md`. Convention: docs/work-directory-conventions.md.

## >>> START HERE <<<

Mission: confirm the `checks` CI workflow is green on GitHub. Session 19
(ledger TOP block = session 19) fixed the three Linux failures and verified
them in an Ubuntu 24.04 container; the user pushes.

## First actions

1. `scripts/context-budget.sh register --project template-maintenance`, then
   `git log --oneline -3`, `git status --short`, `git rev-list --count origin/main..main`.
2. If `main` is still ahead of origin, the user hasn't pushed: report that and stop.
3. Otherwise `gh run list --workflow checks --limit 3`; on a failure, read
   `gh run view <id> --log-failed` and reproduce with the docker recipe in
   `docs/operational-knowledge.md` → "Shell scripts and tests — BSD-only idioms…".
4. Green → nothing open; the backlog has no cards. Watch for the unidentified
   macOS flake noted in ledger block 19.

## Constraints

- Don't push; don't change `TEMPLATE_VERSION` for the CI fix.
