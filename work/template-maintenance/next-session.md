# Catchup prompt — template-maintenance (paste into a new agent session)

> **This file is the LAUNCHER.** Forward-only, REPLACED at each rollover.
> Provenance lives in `handoff.md`. Convention: docs/work-directory-conventions.md.

## >>> START HERE <<<

Mission: make the `checks` CI workflow (`.github/workflows/checks.yml`,
ubuntu-24.04) pass. Its first run, 37884567606 on `40f4389`, failed three
suites that pass on macOS — Linux portability bugs in the scripts or tests:

- `scripts/tests/test-plan.sh` T20c–e — a `tier_<label>: auto` line in
  plan.md is not refused by `plan.sh check` on Linux.
- `scripts/tests/test-session-loop.sh` A2a, A2b, A3b — a killed child is not
  reported `rc_nonzero`; a writing child is not paged.
- `scripts/tests/test-context-budget-registry.sh` — 3 of 198 fail; which
  ones is unknown (the CI log was cut to the last 15 lines).

## First actions

1. `scripts/context-budget.sh register --project template-maintenance`, then
   `git log --oneline -3`, `git status --short`.
2. Use `diagnosing-bugs` (`skills/` vendored set). Reproduce on Linux:
   `docker run --rm -v "$PWD":/w -w /w ubuntu:24.04 bash -c 'apt-get update -qq && apt-get install -y -qq jq git python3 >/dev/null && bash scripts/tests/<suite>'`
   (mirror the packages `checks.yml` installs). If Docker is not available,
   read the full CI log with `gh run view 37884567606 --log` and reason from
   GNU vs BSD differences (sed -i, date, stat, ps, awk, grep -P).
3. Fix one suite at a time; one commit each, `Fix CI: <suite> on Linux`, with
   a `Decision:` trailer. Keep macOS green: `scripts/run-checks.sh` exit 0.
4. If a fix is a gotcha worth keeping, add it to
   `docs/operational-knowledge.md` (classify first, per
   `skills/checkpoint/SKILL.md`). Consider a backlog card only if the fix
   leaves something open.
5. Done = all three suites pass in the Ubuntu container (or CI) and on macOS.
   Do NOT change the `TEMPLATE_VERSION` date. Don't push — report how far
   ahead of origin `main` is; the user pushes and checks CI.

## Do NOT reload

- L63–L65, L54: done and pushed (ledger block 18). Backlog has no open cards.

## Constraints

- Surgical: fix the portability bug, don't rewrite the suites.
- Bump `TEMPLATE_VERSION` on each push of template-facing changes — but
  not for this CI fix (user: fix CI without changing the date).
