# L98 pilot results

Score = rubric criteria passed (of 5), one blinded judge call per task (`pilot/judge.py`, arms shuffled to X/Y/Z, key in `runs/judge-*.key`). One sample per cell.

| Skill | Task | none | dummy | skill |
|---|---|---|---|---|
| unslop | t1 | 4 | 4 | 4 |
| unslop | t2 | 5 | 4 | 5 |
| unslop | t3 | 5 | 5 | 5 |
| **unslop total** | | 14 | 13 | 14 |
| code-simplification | t1 | 4 | 3 | 5 |
| code-simplification | t2 | 5 | 5 | 3 |
| code-simplification | t3 | 4 | 5 | 3 |
| **code-simplification total** | | 13 | 13 | 11 |
| technical-writing | t1 | 1 | 1 | 4 |
| technical-writing | t2 | 5 | 4 | 2 |
| technical-writing | t3 | 4 | 2 | 4 |
| **technical-writing total** | | 10 | 7 | 10 |

## Verdicts (decision rule: skill beats both by >= 1 criterion mean and wins/ties 2 of 3 tasks)

- `unslop`: does not earn its place on this evidence. Ties no-skill (14 v 14); dummy 13. Candidate to prune, but gap is within noise.
- `code-simplification`: candidate to prune. Skill scored lowest (11 v 13 v 13); lost 2 of 3 tasks. Judge flagged float-rounding and negative-n behaviour changes in skill outputs. Still n=3, one sample per cell.
- `technical-writing`: inconclusive. Ties no-skill (10 v 10), beats dummy (7). Skill won t1 big (no-skill invented a URL, no numbering) but lost t2 (invented steps). Does not meet the keep rule.

## Caveats

- Pilot signal, not proof: 3 tasks, 1 sample per cell; a one-criterion flip changes the ordering. Judge is the same model family, ran once, and some calls were debatable (e.g. unslop t2 dummy fails on "robustly"). No reruns spent on close cells.
- Measures skill content appended to the system prompt, not whether the model would trigger the skill.
- Nothing deleted; recommend only.

## Runs and spend

36 headless runs of the 45 cap (27 answer incl. the reused smoke run + 9 judge); 9 unused. Measured spend about $0.88 (sum of total_cost_usd in `runs/*.json`). Count also in `runs/COUNT`.
