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

## L100 re-test: `unslop` on harder prose (s6)

Six tasks of 260–290 words, each loaded with subtler tells than t1–t3 (em dashes, tacked-on
"-ing" phrases, bold-label bullets, title-case headings, emojis, "serves as", "not just X but Y",
vague attributions): h1 PR description, h2 incident email, h3 release announcement, and, after
the user said unslop is for coding work, h4 README section, h5 code comment block (code must stay
unchanged), h6 design-doc section. Two samples per task (`h1a`/`h1b` = two runs of `h1.md`),
three arms each, same harness; judged with a hard-task rubric in `judge.py` (no em dashes or
mid-sentence colons · AI vocabulary · -ing tails, vague attributions, closing filler · every
fact kept · no emojis, sentence-case headings, no bold-label bullets).

| Task | none | dummy | skill |
|---|---|---|---|
| h1a / h1b | 3 / 2 | 2 / 3 | 3 / 5 |
| h2a / h2b | 3 / 2 | 3 / 2 | 4 / 5 |
| h3a / h3b | 3 / 3 | 3 / 3 | 3 / 4 |
| h4a / h4b | 4 / 3 | 3 / 3 | 4 / 4 |
| h5a / h5b | 3 / 4 | 4 / 4 | 5 / 5 |
| h6a / h6b | 4 / 3 | 4 / 3 | 5 / 5 |
| **total (of 60)** | **37** | **37** | **52** |

Per criterion (of 12), none/dummy/skill: dashes 7/7/12 · vocabulary 12/12/12 · -ing/filler
4/4/8 · facts 12/12/11 · formatting 2/2/9. The skill won or tied every cell and lost none; its
one dropped fact (h1a) was "single source of truth" reduced to "records every incoming event".

**Verdict: keep `unslop`.** On short, buzzword-heavy input the model already strips the obvious
words unaided (t1–t3 tie, and here vocabulary is 12/12 for every arm); the skill's gain is the
structural tells (dashes, bold-label lists, emojis, -ing tails) the model leaves alone by
default. Same caveats as above: one same-family judge pass, two samples per task.

Spend: 48 more runs (36 answer + 12 judge), about $1.24 (one dummy run alone cost $0.20).
Count now 84 in `runs/COUNT`.
