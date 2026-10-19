---
id: 08-review
title: Run code-review on the work since BASE; fix the findings
status: done
kind: work
wave: 3
blocked_by: [07-reconcile-w2]
tier: frontier
sessions: [4]
---

## Goal
Run `skills/code-review/SKILL.md` on the diff since BASE = the commit that opened this plan (`git log --format=%h --diff-filter=A -1 -- work/backlog-sweep/plans/01-open-cards/plan.md`), against the success criteria in `work/backlog-sweep/README.md`. Fix every blocker; fix or log each suggestion.

## Acceptance
- [x] review run
- [x] every blocker fixed, each suggestion fixed or logged
- [x] `scripts/run-checks.sh` passes

## Log
- s4 · started, tier frontier
- s4: code-review (Standards + Spec, two opus children) over `git diff 4b65f8c...HEAD` scoped to this plan's paths (6c5ae3a/34c76b4 belong to runtime-session-identity). **0 blockers** on either axis. Spec child re-ran the touched suites and an instance-like `git archive` copy: probe-twins/template-version/template-instantiation exit 77 with reason, doc-consistency skips work/plans pins 17/0.
- Fixed: `docs/context-budget.md` L96 line said "(default 4h)" — the script default is 0; now "4h as shipped in `context-budget.env`; unset means no limit". `plan.sh verify` exports `WORKSPACE_ROOT` gotcha promoted from the ledger to `docs/operational-knowledge.md`.
- Logged, not fixed (judgement, low stakes): `pilot/judge.py` hardcodes model/budget and duplicates the design.md rubric + CLI flags, and does not check `subprocess.run`'s return code (throwaway pilot code, run complete); new SKIP guards not mentioned in the three suites' header comments; one-line `if/else` in test-doc-consistency.sh; fleet.sh read-first names GLOSSARY.md without a presence guard; probe-twins `WORKSPACE_ROOT` unset is outside L85's wording (kept — disclosed in the Fixed line).
- `scripts/run-checks.sh`: 45 passed, 0 failed, 0 skipped (before the doc fixes); re-run after — see next line.
- `scripts/run-checks.sh` after the doc fixes: 45 passed, 0 failed, 0 skipped.
- s4 · done
