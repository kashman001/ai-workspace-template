# Catchup prompt — Automatic Session Rollover (paste into a new agent session)

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, REPLACED at
> each rollover. Past-tense provenance lives in `handoff.md` (append-only
> ledger, newest block on top). Convention: docs/work-directory-conventions.md.

## Status: vendor-hook-deployments plan COMPLETE (2026-08-06)

All 9 tasks shipped, task-reviewed, final-whole-branch-reviewed, and pushed
on `main` through `064641a`. No active mission remains in this work item.

## First actions (only if resuming work here)

1. `git pull --ff-only` if the checkout lags origin/main.
2. `scripts/context-budget.sh register --project automatic-session-rollover`.
3. Read the TOP block of `handoff.md` (session 11) for what shipped last.

## Open follow-up (the only known remaining work)

Backlog card **L17** in `docs/template-workspace-backlog.html` bundles the
deferred minors from the final review: attach-session unlocked-case wording;
space-unsafe `ls -t` loops in `attach-session.sh` + `launch-next-session.sh`
(fix both together); unquoted `$PWD`/`$sid` SQL interp in
`context-budget.sh` `opencode_measure`; registry-suite filename drift in
`docs/context-budget.md`; plus a scorecard recount (Open/Resolved counts and
the prose status panel drifted). All cosmetic/hardening — no urgency.

## Do NOT reload

- `handoff-archive.md` and pre-session-11 `handoff.md` blocks — superseded.
- The plan file and `.superpowers/sdd/…` — plan done; SDD workspace deleted
  (git history is the record).
- Machine gotchas stay in `docs/operational-knowledge.md` (codex model pin,
  no gemini auth, opencode `$schema` rewrite) — don't re-diagnose.

## At session end

Release the lock: `scripts/context-budget.sh release --project automatic-session-rollover`.
