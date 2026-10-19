# L98 pilot design: does a skill earn its place?

Test source: `docs/stakes-to-ceremony.md` -> "Make a skill earn its place". Run each task three ways in a fresh headless session: no skill, a same-length dummy, the skill. Keep a skill only if it beats both. A tie with the dummy means length did the work, not content.

## Skills under test (3 in the pilot, 1 reserve)

All three are vendored skills whose steps mostly restate what a current model does when asked for the same job.

| Skill | Words | Why it may just restate default behaviour |
|---|---|---|
| `unslop` | ~980 | Asked to "make this read like a human wrote it", a model already cuts filler openers, "leverage/seamless" words and sign-offs. The skill is a long list of tells. |
| `code-simplification` | ~2050 | Asked to simplify code, a model already flattens nesting, drops redundant comparisons and uses comprehensions. The skill is a process around that (Chesterton's fence, small steps). |
| `technical-writing` | ~1590 | Asked to write a README section or how-to from facts, a model already uses numbered steps, imperative verbs and plain headings. The skill names the standards (Diataxis, Google style, STE). |
| reserve: `doubt-driven-development` (~2560) | | Only run if the pilot finishes under budget; its value is in agentic loops this single-turn harness cannot measure, so it is not in the core set. |

## Tasks (3 per skill)

Prompts live in `pilot/tasks/<skill>/t1.md` to `t3.md`. Each is one self-contained turn with no tool use, so output is comparable and cheap.

- `unslop`: t1 README intro, t2 PR description, t3 status report. All are slop-heavy text to be edited.
- `code-simplification`: t1 nested Python filter/dedupe, t2 JS discount function, t3 Python Counter class.
- `technical-writing`: t1 README install section from facts, t2 key-rotation how-to from facts, t3 messy PR description rewrite.

## Rubric (pass/fail per criterion; score = criteria passed)

A judge scores all three arm outputs for a task in one blinded call (arms shuffled and labelled X/Y/Z). It returns one pass/fail per criterion plus one line of evidence. Criteria are checkable from the text alone.

`unslop` (5): (1) no opener cliche ("in today's", "I'm delighted", "this PR introduces"); (2) none of: leverage, seamless(ly), robust, comprehensive, game-changer, paradigm shift, delve, landscape; (3) no closing filler ("don't hesitate", "in conclusion", "moving forward", "let's dive in"); (4) every fact from the input survives (t2: base 2, 30s cap, 5s old, 20% jitter, tests; t3: 14 of 15, billing-sync, certificate, Thursday); (5) shorter than the input.

`code-simplification` (5): (1) behaviour preserved on the judge's listed edge cases (t1: None user, empty/whitespace email, case-fold dedupe, order kept; t2: 10%/5% tiers at boundaries, member +5%, cap 15%; t3: tie order stable, n larger than size); (2) no `== True`, `.keys()` or manual index loops left; (3) fewer lines than the input; (4) no new features or renamed public names; (5) a note of one sentence or less that matches the change.

`technical-writing` (5): (1) every supplied fact present, none invented (judge lists the facts); (2) steps are numbered and each starts with an imperative verb; (3) warnings/consequences sit next to the step they affect (t2: delete-before-deploy gives 401s; t3: flush cache; t1: exit code 2); (4) no filler or marketing words; (5) uses only the supplied facts (no invented flags, versions or URLs).

Decision rule per skill: skill mean score must exceed both the no-skill mean and the dummy mean by at least 1 criterion over the 3 tasks, and win or tie on at least 2 of 3 tasks. Otherwise report "does not earn its place on this evidence". With one sample per cell this is a pilot signal, not proof; say so in the result.

## How each arm loads

`pilot/run.sh <skill> <task> <arm>` with arm = `none | dummy | skill`. Every run:

- starts in a new temp dir under the scratchpad, so no workspace `CLAUDE.md` is found;
- `claude -p --model claude-sonnet-5-5 --output-format json --tools "" --no-session-persistence --disable-slash-commands --setting-sources "" --max-budget-usd 0.50`;
- reads the task prompt on stdin;
- `skill` arm: appends the skill's `SKILL.md` body (frontmatter stripped, vendoring comment kept) with `--append-system-prompt`;
- `dummy` arm: appends unrelated filler (`pilot/dummy.txt`, a fish-market description repeated) cut to the exact word count of the skill body;
- `none` arm: appends nothing.

Notes: this CLI has no `--max-turns`, so a single turn is enforced by disabling all tools (the tasks need none); `--max-budget-usd` is a second bound. Appending the skill to the system prompt is the closest headless equivalent of the skill being loaded; it skips the real trigger step (whether the model would invoke the skill), so this measures a skill's content, not its discoverability. `--bare` was not used because it blocks keychain auth. `--setting-sources ""` stops project/user settings loading; the user-level `~/.claude/CLAUDE.md` may still be read, and applies equally to all arms.

Output lands in `pilot/runs/<skill>-<task>-<arm>.{txt,json,err}`; `run.sh` prints wall time and cost.

## Cost estimate and cap

Smoke run measured (unslop t1, dummy arm, ~950 extra words): 3 s wall, $0.018. The code and writing prompts are longer and the skills up to ~2050 words, so assume at most $0.03 per run.

- Answer runs: 3 skills x 3 tasks x 3 arms = 27.
- Judge runs: 1 per task = 9 (blinded, 3 outputs each).
- Total planned: 36 headless runs, about $1.10 at the pessimistic rate, about 3-10 s each.
- Reserve for reruns (a failed or empty run): 9, giving the hard cap of **45 headless runs** for the whole pilot (`decisions.md`, 2026-10-18). The smoke run is one of the 27 (unslop t1 dummy) and counts against the cap; node 06 should reuse it, not repeat it. Stop at 45 and report what is unfinished.

## Open caveats

- n=1 per cell; model sampling noise can flip a one-criterion gap. If a result is within 1 criterion on 1-2 tasks, spend reserve runs on repeats of the closest cell rather than declaring a winner.
- The judge is the same model family as the answerer; rubric items are kept mechanical to limit bias.
