
## [gen 1] 2026-09-17 — plan written

- Read: ticket 03, fleet-plan contract + hazards, Part 4 phase 2 text, measurer lines 1–120 / 254–262 / 343–505 / 505–562 / 579–590 / 1040–1454, the three fleet suites, caller grep across scripts/skills/docs/.claude/CONTEXT.md.
- Plan file written: `work/template-improvement-review/plans/phase-2.md` (worktree). Four decisions recorded there, each with the rejected alternative; the main one: `fleet.sh children` gets the caller's own session by running `context-budget.sh check` and parsing its line, instead of copying ~250 lines of discovery code.
- Baseline of every suite running in the background against the untouched branch (to tell pre-existing failures from mine).
- Finding: the verbs + helpers + options total ~200 lines of the measurer, not the ~400 the phase text estimated. Reporting the real number.
- Next: write `scripts/fleet.sh`, cut the measurer, `git mv` + re-point the suites, re-point callers, run everything.
- Open items: none.

## [gen 1] 2026-09-17 — move done, fleet suites green, full run in progress

- `scripts/fleet.sh` (309 lines) written: header + copied helpers (~40 lines) + the verb bodies extracted verbatim from the measurer by line range. Only change inside a verb: `cmd_children` calls `resolve_own_session` (runs `context-budget.sh check`, parses `runtime=`/`artifact=`) where it called `resolve_session`.
- Measurer: 1454 → 1265 lines (−189). Fleet verbs, their options (`--all --report --brief --gen --task --agent-type --effort --status`), usage lines and case entries removed; a fleet verb now exits 3 with `error: <verb> moved to scripts/fleet.sh — run: scripts/fleet.sh <verb> [options]`.
- Suites `git mv`'d to `test-fleet-children.sh`, `test-fleet-dispatch-contract.sh`, `test-fleet-dispatch-records.sh`; re-pointed; C10 and L10 added (measurer refuses, names `scripts/fleet.sh <verb>`, writes no record). All three rc=0 (29 / 24 / 55 asserts).
- Old-vs-new diff run in a temp workspace: `dispatch-contract`, `dispatch-open/close/list` stdout, stderr, exit codes and the record JSON (minus timestamps) are byte-identical between `git show HEAD:scripts/context-budget.sh` and `scripts/fleet.sh`.
- Callers re-pointed: `CONTEXT.md` dispatch bullet, `docs/context-budget.md` quickstart line + dispatch bullet, one tree line in `docs/workspace-structure.md`. No hook/skill/settings caller existed.
- Baseline before edits: all 23 suites rc=0. Full run on the modified branch running now.
- Next: evidence into the plan file, commit, final report.
- Open items: none.

## [gen 1] 2026-09-17 — DONE, committed f07f5ea on s4-phase-2

- Full run on the modified branch: all 23 suites rc=0 (the three renamed fleet suites included; 29/24/55 asserts). No FAIL line in any log. Baseline before edits was also all green, so nothing pre-existing is masked.
- Evidence section of `plans/phase-2.md` filled: rc lines, line counts (measurer 1454 → 1265, fleet.sh 309), `grep -c dispatch` = 2 (usage pointer + refusal case), the refusal text, and the byte-identical old-vs-new comparison.
- Commit `f07f5ea` on `s4-phase-2`; `git status` empty. Not merged, not pushed.
- Files: added `scripts/fleet.sh`, `work/template-improvement-review/plans/phase-2.md`; modified `scripts/context-budget.sh`, `CONTEXT.md`, `docs/context-budget.md`, `docs/workspace-structure.md`; renamed `test-children-sweep.sh` → `test-fleet-children.sh`, `test-dispatch-contract.sh` → `test-fleet-dispatch-contract.sh`, `test-dispatch-records.sh` → `test-fleet-dispatch-records.sh`.
- For the parent's Tier-2 log (decisions.md is off-limits to me): the four decisions are in the plan file's "Decisions" section.
- Concerns for the parent: (1) the "~400 lines" estimate in Part 4 was ~190 in practice. (2) `fleet.sh children` now shells out to `context-budget.sh check` for the caller's own session — phase 3 must keep `check`'s `runtime=`/`artifact=` line or update `resolve_own_session` in fleet.sh. (3) Bare-verb mentions in `docs/context-budget.md` sections (lines ~805–880) still read as if the verbs were measurer verbs; left for phase 8 per the "path only" rule.
- Open items: none.
