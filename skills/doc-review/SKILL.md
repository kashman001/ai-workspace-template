---
name: doc-review
description: >-
  Multi-perspective review of a technical document: audience gate first, six
  independent reviewer subagents, findings synthesized into prioritized
  recommendations.
disable-model-invocation: true
---

# doc-review — Documentation Review Orchestrator

Orchestrate a multi-perspective review of a technical document: run several
specialist reviewers as subagents, then synthesize their findings into one
prioritized set of recommendations.

**Document under review:** the path given as the argument, or content the user
pastes. If neither is given, ask for it before anything else.

If your runtime cannot dispatch parallel subagents, run each reviewer
sequentially in an isolated context — reviewers must never see each other's
findings.

---

## PHASE 0 — Gate: establish audience before reviewing anything

**Do not read the document for review purposes and do not dispatch any subagent
until the user has answered the questions below.** You may skim the document
only to make your questions concrete.

Ask the user, in one message, as a short numbered list:

1. **Audience segments** — who will read this? Name each segment, their role,
   and their technical depth. Push them to be specific: "engineers" is not a
   segment; "platform engineers authoring Rego policies, 2+ years cloud IAM" is.
2. **Job to be done, per segment** — what is each segment trying to accomplish
   *after* reading? What decision or task does this unblock?
3. **Reading context** — will they read it start to finish, skim to find one
   answer, follow it step by step with a terminal open, or forward it to
   someone else?
4. **Prior knowledge and vocabulary** — what can be assumed as already known?
   What terms are house jargon that won't land outside the team?
5. **Document intent** — is this meant to be a tutorial, a how-to guide,
   reference material, or conceptual explanation? (If the answer is "all of
   them," flag that as the likely root problem and ask the user to pick a
   primary.)
6. **Constraints** — length ceiling, publishing venue, house style guide,
   whether the doc must survive being read without the author present to
   explain it.
7. **Success criteria** — how would the user know this document worked?

If the answers are vague on any point, ask one round of follow-ups. Then
restate the audience model back in a compact table and get the user's
confirmation before proceeding.

---

## PHASE 1 — Dispatch subagents

Run these in parallel. Give each subagent **only** its own mandate plus the
confirmed audience model — do not let them see each other's findings, so their
perspectives stay independent.

### Agent A — Structure & mode integrity

Audit against the Diátaxis framework (tutorial / how-to / reference /
explanation). Identify where the document mixes modes — architecture rationale
wedged into a step-by-step, exhaustive parameter tables inside a narrative
walkthrough, and so on. Mode-mixing is the most common cause of "too much
detail" and "not enough detail" appearing in the same document. Propose a split
or a reordering. Assess whether headings form a scannable, self-describing
outline that stands alone.

### Agent B — Audience fit (one instance per segment)

Spawn one instance per audience segment the user named. Each instance reads
*as* that reader and reports:

- Where this reader stops caring, and why
- Content that is over-explained for them (their time wasted)
- Content that is under-explained or assumes knowledge they lack (their blocker)
- Undefined terms, unexpanded acronyms, unexplained internal references
- Whether the first 100 words tell them this document is for them

Rate: would this reader finish it? Would they get their answer?

### Agent C — Task completion walkthrough

Attempt to actually complete the document's primary task using only the
document. Narrate each step and flag every point where you must guess, infer,
look elsewhere, or backtrack. Report missing prerequisites, unstated
assumptions, ordering errors, steps that silently require elevated access or
unnamed tooling, and any place where success or failure is not verifiable by
the reader. This is the empirical check — do not be charitable.

### Agent D — Language, clarity & consistency

Flag passive voice that hides the actor, nominalizations, buried subjects,
sentences over ~30 words, ambiguous pronouns, and inconsistent terminology for
the same concept (list every variant). Check that code samples, commands, and
outputs are complete, copy-pasteable, and consistently formatted.
**Do not report Flesch-Kincaid or grade-level scores** — they penalize
necessary domain vocabulary and measure nothing that matters here. Report
specific sentences instead.

### Agent E — Accuracy & completeness

Check internal consistency: do stated values, names, versions, and flags match
across the document? Flag claims that look stale, unverifiable, or contradicted
elsewhere in the doc. If you have access to the underlying code, config, or
repo, verify against it and report drift. Flag anything that reads as
accurate-sounding but unsupported.

### Agent F — Skim and forward test

Read only headings, first sentences of paragraphs, bold text, tables, and
callouts — nothing else. Report what a skimming reader walks away believing.
Then assess: if this document were forwarded to a decision-maker who reads the
first screen and nothing more, what would they conclude, and is that the
intended conclusion?

**Output contract for every subagent** — so findings are comparable and
de-dupable:

| Field | Requirement |
|---|---|
| Location | Section heading and quoted anchor phrase |
| Finding | What is wrong, in one sentence |
| Affected segment(s) | From the confirmed audience model |
| Severity | Blocker / Major / Minor / Polish |
| Recommendation | Specific and actionable — not "clarify this" |
| Confidence | High / Medium / Low |

Severity definitions: **Blocker** — a target reader cannot complete their job.
**Major** — they can, but with wasted effort or a real chance of error.
**Minor** — friction or inconsistency. **Polish** — style preference.

---

## PHASE 2 — Synthesize

You (the orchestrator) then produce:

1. **Verdict** — 3 sentences: does this document serve its named audiences,
   and what is the single highest-leverage change?
2. **Root cause** — is the core issue structural (wrong document shape,
   mode-mixing, serving too many audiences at once), a content gap, or
   surface-level writing? Say which. Do not hand the user a list of line edits
   if the real problem is that this is three documents.
3. **Prioritized findings** — merged and de-duplicated across agents, ordered
   by severity then by number of segments affected. Note explicitly where
   agents disagreed, and which view you find more credible.
4. **Audience coverage matrix** — segments as rows, sections as columns; mark
   each cell essential / useful / noise. This is where over- and under-detail
   becomes visible as a pattern rather than a complaint.
5. **Recommended restructure** — a proposed heading outline, including any
   split into separate documents, with a one-line rationale per document and
   its intended reader.
6. **What is already working** — be specific; the user needs to know what not
   to break.

## Rules

- Do not rewrite the document unless the user asks. Diagnose first, then wait.
- Judge the document against the user's stated audience, not against your own
  preferences.
- "Add more detail" is only a valid recommendation if you name the specific
  missing fact and the segment that needs it.
- If a subagent has nothing substantive to report, it should say so plainly
  rather than manufacture findings to fill its section.
- Flag anything the user asked for that you could not assess, and say why.
