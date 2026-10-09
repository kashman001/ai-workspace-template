# Catchup prompt — template-maintenance (paste into a new agent session)

> **This file is the LAUNCHER.** Forward-only, REPLACED at each rollover.
> Provenance lives in `handoff.md`. Convention: docs/work-directory-conventions.md.

## >>> START HERE <<<

**Mission.** The user queued three jobs at the end of session 22. Do them in this
order. File each one as a backlog card first, then resolve it (backlog rules: grep
`Maintaining this backlog` in `docs/template-workspace-backlog.html`; the scorecard
is 0/123/5/0/6). Use parallel subagents for jobs that touch different files (user
preference); keep backlog, ledger and launcher edits in the main session.

1. **ADR for GLOSSARY.md.** Promote the `decisions.md` note "2026-10-09 — Adopt
   upstream's GLOSSARY.md" to `docs/adr/` (`skills/decision-log/SKILL.md`, the
   promote procedure; `docs/adr/README.md` for numbering and format).
2. **Migration runbook + script.** Older projects made with the old
   `init-project-ai-infra` still keep their glossary as `## Language` inside
   `CONTEXT.md`; `~/Developer/experiments/NeogeoEmu` is one. Write a runbook (under
   `docs/runbooks/`) plus an idempotent script that an agent in any runtime can run in such a
   repo. The script moves the `## Language` section into a root `GLOSSARY.md`,
   leaves a pointer in CONTEXT.md, and fixes references. TDD it with a
   `scripts/tests/` suite. Ship it with the template (memory: template additions are
   first-class). The script refuses a dirty tree and works on a new
   branch in the target repo (`migrate/glossary`), so the user reviews, merges
   or deletes it. Template work stays on `main` (recommended in s22; the user asked, so confirm). Ask the
   user before running it on any real project.
3. **Track patched vendored skills.** Proposed to the user; they have not yet confirmed the design:
   (a) an `Upstream: mattpocock/skills#1242` header line in each `workspace.patch`.
   The sync checks it with `gh issue view --json state` and prints "upstream may
   have landed this; delete the patch" when the issue is closed, and stays quiet
   without `gh`. (b) `check-drift.sh` warns when the vendored skills' provenance
   date is more than ~60 days old. Confirm with the user in plain terms first, then TDD
   in `test-sync-vendored-skills.sh` / `test-check-drift.sh` and document it in
   `skills/vendored-skills.md`.

**State:** `main` is pushed, clean, and CI is green. Pushing again is the user's call.
On a push after today, bump `TEMPLATE_VERSION` to that day.

**Do NOT reload:** L70/M48/L71 are done (ledger block 22).

## First actions

1. `scripts/context-budget.sh register --project template-maintenance`.
2. Job 3's design question to the user (one question, plain terms), and in parallel,
   job 1 (ADR) yourself.
3. Job 2, then job 3, then `scripts/run-checks.sh`, commit, and report.
