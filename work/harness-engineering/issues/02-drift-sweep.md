# 02 — A drift sweep that finds what the doc gap review found by hand (M45)

**What to build:** `scripts/check-drift.sh`, a workspace-wide staleness
check, read-only, one line per finding, exit 1 if any. Checks:

1. **Dead path references** — every backticked `docs/…`, `skills/…`,
   `scripts/…` in tracked `.md` files (excluding `work/`,
   `docs/archive/`, `docs/superpowers/` and the backlog HTML) must exist.
   Allow-list, kept in one place with a reason per entry: upstream
   provenance paths (`skills/engineering/…`, `skills/in-progress/`,
   `skills/typesafe-ai/…`), files a setup skill generates
   (`docs/agents/domain.md`, `docs/agents/triage-labels.md`), paths
   relative to a skill's own folder (`scripts/rlm_repl.py`,
   `scripts/hitl-loop.template.sh`), placeholders (`<…>`, `NN`).
   ADRs are history: report their dead paths as warnings, not failures.
2. **Gotchas past review age** — reuse the awk in
   `skills/checkpoint/SKILL.md` step 1 (don't fork it: have checkpoint call
   this script for that step instead).
3. **`CONTEXT.md` over its byte budget** — find the budget L51 trimmed
   toward (`docs/zoom-model.md` Z0, or the L51 card in the archive).
4. **Docs missing from `docs/README.md`** — every file/folder under
   `docs/` is linked from the index.

Wire it: checkpoint step 1 runs it; ticket 01's CI gets a weekly
`schedule:` job for it (if 01's workflow exists). The prototype for check 1
is the shell loop in `work/context-memory-hardening/doc-gap-review.md` →
finding 9 (this session's run: 12 hits, most of them false alarms). Today the
open cards L58 and L59 are real hits: the sweep must report them until
`template-maintenance` fixes them — that's expected, not a reason to
allow-list them.

**Blocked by:** 01 (for the CI hook-up only; the script itself can land first).

**Status:** done

- [x] Failing test first: fixture tree with one dead path, one allow-listed
      path, one stale gotcha, an oversize `CONTEXT.md`, an unindexed doc →
      exactly those findings
- [x] Script green on the fixtures; run on `main` and list its real
      findings in the ticket
- [x] Checkpoint step 1 calls it; documented in `docs/workspace-structure.md`
- [x] Backlog card resolved in the same commit: badge → Resolved, `Fixed:`
      line with the commit, card moved to the matching section of
      `docs/template-workspace-backlog-archive.html`, scorecard and "Last
      updated" changed, change-log row added
- [x] All `scripts/tests/test-*` suites green (after ticket 01:
      `scripts/run-checks.sh` exits 0); `scripts/check-workspace-structure.sh` exit 0
- [x] One commit, `Fix <ID>: …`, with a `Decision:` trailer

**Done (2026-10-08, session 2).** `scripts/check-drift.sh` + suite
`scripts/tests/test-check-drift.sh` (D1–D4, 19 asserts, red first).
Checkpoint step 1 runs it; CI runs it on push and weekly; full run-checks
35/0/0. Two Tier-2 notes in `decisions.md`.

Real findings on `main` at commit time:
- `WARN docs/adr/0009-clear-based-rollover-relaunch.md:
  scripts/hooks/rollover-clear-seed.sh` — ADR history, a warning by design.
- L58 and L59 were already fixed by `template-maintenance` before this ran;
  `scripts/rollover-prep.sh` (named as history by L58's fix) is allow-listed.
- The first run flagged `docs/.nojekyll` as unindexed; dotfiles are now
  skipped (fixture covers it).
- Outside the sweep's reach: the `scripts/` tree block in
  `docs/workspace-structure.md` lists two removed scripts. Filed as **L63**.
