# Sweep brief — cross-subject sweep, jev-integration wave 1 (2026-09-23, Phase 4)

Working directory: `/Users/kashif/Developer/experiments/ai-workspace-template`.
You may READ everything under `work/jev-integration/research/`. You WRITE
exactly one file: `work/jev-integration/research/sweep.md`. You edit nothing
else — findings go to the orchestrator, who rules, and corrections agents
apply them. Read first: `skills/research-wave/references/method-rules.md`,
`work/jev-integration/research/schema.md`, `work/jev-integration/research/rulings.md`
(every ruling; the wave patterns are the lines beginning "Wave pattern" /
"New wave pattern" and the pattern lists in the Phase 3 sections).

Subjects: `what-jev-is`, `terms`, `integration-paths`. Deliverables per
subject: `record.md` (claims table + verbatim appendix), `profile.md`
(prose summary), `verification.md`, `open-verification.md`, `corrections.md`
(what changed, two rounds). Provenance, never edited and not sweep targets
except as the source of a quote: `pass/*.md`, `fact-check.md`, `*brief*.md`,
`fc-targets.md`.

Public sources only (curl/WebFetch); no accounts, keys, API calls, spend.

## The four sweeps (run all four across all three subjects)

1. **Consistency of standard.** Find the same evidence pattern scored two
   ways. Check at least: (a) standing claim S3 — `what-jev-is` R1 and
   `integration-paths` R3 ruled the human-in-the-loop half `implied`; `terms`
   R6 added the FAQ "guarantees the shape of its answers" temper as
   `documented` — are the three subjects' S3 verdict sentences and quotes
   mutually consistent? (b) Noul-has-no-confidence: every subject that says
   it, same verdict, same source? (c) the docs-vs-OpenAPI spread on
   `instructions` (`what-jev-is` C14 after R14; `integration-paths`
   5.12-spec-spread after R2/R10) — same facts, same keywords, same verdict?
   (d) access state: `terms` R1 overturned "not self-serve" (X post 2026-09-20,
   "NO MORE WAITLIST" banner) — does any other subject still say "waitlist" /
   "early access" as current? (e) the $42/Btok price and its qualifier —
   identical wording and source across subjects? (f) verification-level
   vocabulary (`survived`/`downgraded`/`overturned`; "cluster-verified" vs
   "verified") — is one scale used, and does each subject's scorecard line
   match its own table when you re-count the status column? If a scale and a
   summary diverge, say so and DEFINE the scale in your report; do not
   re-score anyone (the orchestrator rules; re-scoring is done for all
   subjects together). Deferred strengthenings named in rulings R11
   (`integration-paths`) and R16 (`what-jev-is`, apostrophe + N1 promotion):
   report a recommendation, apply nothing.
2. **Formatting integrity.** Every Markdown table must render: count the
   cells of every row of every table in the five deliverables per subject
   against its header; find literal unescaped `|` inside code spans, regexes,
   enums, JSON and CLI snippets; find rows split by a stray newline;
   find `(corrected …; previously: "…")` markers that broke a cell (an
   unbalanced quote or backtick). Report every broken row by file:line with
   the cell count found vs expected. A count of N is a lower bound (rule 7):
   sweep with a script over all tables, then eyeball the rows the script
   flags.
3. **Evidence-appendix spot-check.** Per subject, sample at least six
   verbatim appendix quotes (weight toward the load-bearing ones: price,
   "guarantees the shape of its answers", "never abstains"/always returns a
   declared option, the OpenAPI `required` arrays, the X posts, the MCA
   no-training/telemetry clauses, the HN quotes with their story ids) and
   re-fetch each source today. Report for each: found verbatim / found with
   drift (quote the drift) / not found. A not-found quote is the highest
   severity finding this sweep can produce — report it first.
4. **Stale summary counts.** Find every count or tally that pre-dates a
   correction and still reads as current: claim totals (documented /
   implied / unknown / contradicted) in `record.md` headers, tally lines,
   progress blocks, `profile.md` prose, `verification.md` scorecards,
   `open-verification.md` open/closed counts, the "N of M re-checked"
   figures. For each, re-count from the table today and report file:line,
   the figure printed, the figure counted, and whether it is already marked
   historical. Note `rulings.md` Phase 1/2 log figures are deliberately
   historical (they say what the passes reported) — do not flag them.

## Two disputes the sweep must settle (rulings R17 and R20, `rulings.md`)

- **R17 — C50 (`what-jev-is`) "16-way contention".** Gen 1 and gen 2 of the
  corrections read the choice cookbook's "clean round trip" line (≈L557–558)
  in opposite ways: gen 1 says it describes the gpt-5.4-mini single-pick row
  (so the 7.2x/20.3x minima were NOT measured under contention); gen 2 says
  it describes the TypeSafe denominator, and that row runs in the same
  16-way pool as every LLM condition (≈L512–550, L590–591). Re-fetch the
  cookbook (URL in `what-jev-is/record.md` C50 / appendix), read L500–600,
  and state which reading is right with the quoted lines. Put it in sweep 3
  as its own finding, severity high.
- **R20 — the `instructions` spread.** `what-jev-is` C14 now records the
  spec (`anyOf` string/object/array/null; not in `required`) vs docs
  (api.md "required"; `/primitives/advanced` "`string`, `object`, `array`,
  or `null`"; api.md's type list omits `null`). Check `integration-paths`
  5.12-spec-spread carries the same three facts; report any element missing
  on either side (sweep 1(c)).

## Report — `research/sweep.md`

Structure: `## Summary` (≤10 lines: the number of findings per sweep, the
worst one first); `## Findings` as one table per sweep with columns
`| id | subject | file:line | what | evidence (re-derived today) | recommended fix | severity (high/med/low) |`
(ids `SW1-1`, `SW2-3` … = sweep-number–finding-number); `## Scale
definition` (only if sweep 1(f) found a divergence); `## Patterns` — any new
wave pattern beyond those in `rulings.md`, and which recorded patterns this
sweep confirmed; `## Method` — the scripts/greps you ran (so a later wave
can rerun them). Append `[gen N]` progress blocks under `## Progress` at
every work-unit boundary (after each sweep at minimum).

Return at most 12 lines: status word first (DONE | DONE_WITH_CONCERNS |
BLOCKED | NEEDS_CONTEXT | ROLLOVER_NEEDED), then findings per sweep with
the high-severity ones named, then anything you could not check.
