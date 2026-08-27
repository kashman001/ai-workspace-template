---
name: research-wave
description: >-
  Research several subjects in parallel and verify the results with independent
  fact-checkers before the claims reach anyone.
disable-model-invocation: true
---

# research-wave — Parallel Research with an Independent Check

Research **N subjects at once**, then have each result checked by an agent
that did none of the original research, then apply corrections under your
rulings. Three layers, because the middle one is where the value is: a
pass that verifies itself re-reads its own reasoning and certifies its own
errors.

**Use this when the claims will be published, presented, or defended** —
a vendor comparison, a competitive landscape, a technology evaluation, a
due-diligence sweep. For a lookup nobody will contest, research it
directly; this pipeline costs roughly five to eight agents per subject.

**Reference files, handed to agents rather than read by you:**
`references/method-rules.md` (all three agent types),
`references/pass-brief.md` (Phase 1), `references/fact-check-brief.md`
(Phase 2).

---

## Your job: rule, do not research

You are the orchestrator. Your context is the binding constraint on the
whole wave — not the agent count, not the token spend. Every agent reports
to a **file** and returns **at most ~12 lines**; you read the returns and
rule on them. Pull a full record into chat and the wave ends early with
subjects unfinished.

Three rules hold for the entire run:

- **Read summaries, rule on findings.** Detail lives in files you can grep
  later.
- **Fact-checkers recommend; you rule; a corrections agent applies.**
  Keeping those three separate is what caught a wrong orchestrator ruling
  in the run this skill came from.
- **Record every ruling in a durable file** as you make it. Rulings are
  the one artifact that exists nowhere else.

---

## PHASE 0 — Gate: agree the shape before spending anything

Get these from the user in one message. A wave launched on a vague schema
produces N incomparable results, which is worse than N incomplete ones.

1. **The subjects** — the exact list, and their priority order. Priority
   is what you trim by if the budget tightens.
2. **The schema** — the questions every subject is answered against.
   Identical for all of them; comparability comes from sameness, not from
   agents cross-referencing each other.
3. **What counts as verified** — which sources are admissible, what
   "unknown" means, and whether anything is off-limits (accounts, spend,
   tools that do not work in this environment).
4. **Standing claims this wave might contradict** — anything already
   published that these subjects bear on. Name them now; an overturn found
   in Phase 1 is the highest-value output of the whole wave, and it is
   only recognizable if you knew the claim existed.
5. **Budget** — agent count, and any shared tool quota. Shared search
   quotas are wave-level resources that run out mid-run.

**Done when:** the schema is written to a file both you and every agent
can read, and the subject list is fixed.

---

## PHASE 1 — Launch every pass before reading any

1. **Create one directory per subject.** Per-item write isolation is what
   makes concurrency safe.
2. **Open one dispatch record per subject** if your environment tracks
   them. N records means N independent resume points: if you run out of
   context mid-wave, finished subjects stay finished.
3. **Fill `references/pass-brief.md`** per subject — same brief, different
   placeholders — and add each subject's specific risks: the standing
   claims it might contradict, the known landmines, where its
   documentation actually lives.
4. **Launch all of them in one message.** Reading a return between
   launches serializes exactly what should overlap.

**Done when:** every subject has an agent running and you have read none
of their output.

---

## PHASE 2 — Check each result with an agent that did not produce it

As each pass returns, launch its fact-check immediately — do not wait for
the wave to finish.

Fill `references/fact-check-brief.md`, and set its **priority targets**
from what the pass just told you: every claim that contradicts something
already published, every claim a reader would act on, every number a
decision turns on. Phrase each as a claim to rule on, and say explicitly
that **it cuts both ways** — the pass may be right, or it may have
over-corrected. Roughly half of real findings are over-corrections
*against* the subject.

**Propagate patterns as they emerge.** A defect found on subject 2 is
usually latent in subjects 3, 4 and 5. Fold each new pattern into every
brief you write afterward; that compounding is why the fact-checks get
sharper as the wave proceeds.

**Done when:** every subject has a fact-check recording a verdict per
checked claim, a patterns section, and an explicit coverage figure —
"36 of 68 claims re-checked", so no reader assumes uniform verification.

---

## PHASE 3 — Rule, then have the rulings applied

Rule on every finding. For each: apply, apply-reworded, or reject —
with the reason. Where a finding rests on judgement rather than evidence,
**rule it yourself**; that is the one thing that cannot be delegated
downward.

Then dispatch a **corrections agent** per subject carrying your rulings
explicitly. Require it to:

- **Re-derive every number while applying it** rather than trusting your
  summary. This is the step that catches *your* errors, and it does.
- **Grep the whole item directory before closing a finding** — method
  rule 7. A count of N instances is a lower bound.
- **Mark each corrected claim** with what it previously said, so the
  record shows a claim was made, checked, and changed.
- **Report back anything it could not apply**, and **refuse** any ruling
  the evidence contradicts. An agent telling you a ruling was wrong is the
  pipeline working.
- **Leave the raw research files untouched** — they are the provenance
  record.

Expect a second round. Findings arrive that no ruling covered; rule on
those too rather than letting an agent resolve them at the wrong level.

**Done when:** every finding is applied or explicitly deferred with a
reason, and every subject holds a corrections record naming what changed.

---

## PHASE 4 — Sweep across subjects, then synthesize

Defects that no per-subject check can see:

- **Consistency of standard.** The same evidence pattern scored two ways
  across subjects is invisible from inside either one. This is also where
  a scoring scale and a published summary can be found to have diverged —
  when they have, **define the scale before re-scoring anyone**, and
  re-score every affected subject together rather than one at a time.
- **Formatting integrity.** Check every table renders: literal `|` inside
  regexes, enums, config snippets and CLI examples silently splits cells.
  One wave found eight broken rows across three subjects this way, all
  pre-existing and all invisible until someone counted columns.
- **Evidence-appendix spot-check.** Sample quotes against their sources.
  At least one wave has found a fabricated quote sitting in an appendix.
- **Stale summary counts.** Progress logs preserving pre-correction
  figures read as current to a skimmer. Mark them historical.

Include subjects researched **before** this wave in all four sweeps —
they were never checked to this standard.

**Done when:** the sweeps have run across every subject, old and new, and
the synthesis draws on the corrected records.

---

## Handing the wave off

Write down, where the next session will read it: the corrected errors and
what each was, the findings that change something already published, the
patterns the fact-checks found, and the sweeps still outstanding. **The
patterns are the most valuable output** — they are what makes the next
wave cheaper, and they are invisible in any individual subject's files.
