# Method rules — hand these to every agent in a wave

Eight rules, each learned from a defect that reached a deliverable. Give
this file to pass agents, fact-check agents, and corrections agents
alike: it is the single source of truth for all three.

## Evidence

1. **A failed lookup is not evidence of absence.** Before recording "the
   API returns nothing" or "no such page exists", show the query that
   *does* return rows. One pass declared a public pricing API empty; it
   had used the wrong service name, and the correct query returned
   20,000+ meters — a claim that blocked a whole economics slide.

2. **Absence claims rest on the reference, never on a silent product
   page.** API reference, CLI reference, OpenAPI schema, SDK surface.
   Three subjects in one wave had absence claims overturned because the
   answer sat in a CLI enum or an admin endpoint while the agent searched
   marketing pages. The one subject whose absence claims all survived was
   the one that started from the schema.

3. **Fetch tables as raw HTML.** Markdown conversion collapses columns.
   It inverted a cached-price finding on one subject and transposed a
   four-column price grid on another, producing three wrong claims from
   one error — and the pass's own skeptic stage certified the
   transposition as verified.

4. **Quote verbatim, and check the quote exists.** The most serious
   defect a wave has produced was a **fabricated quote**: a string with
   zero occurrences on its cited page, propagated to three sites
   including the evidence appendix — the exact place a checking reader
   trusts most. Its own verification stage passed over it three times.

## Numbers

5. **A price is almost never one number.** Every headline rate in one
   wave turned out to be one meter inside a family with a multi-× spread:
   a "flat $1.70/hr" that ran to $5.00 for one model, a "$100/hr" that
   applied to exactly two model families, a cached rate quoted as one
   figure that ranged 8%–50% of input. **Name the meter scope beside any
   number**, or say the scope is undisclosed.

6. **Count spreads are findings, not puzzles.** When a subject publishes
   several different counts of its own catalog, name every figure with
   the page it appears on and adopt none. One subject's open-source
   README carried three contradictory counts on a single page. Resolving
   the spread hides the finding; recording it *is* the finding.

## Process

7. **A defect count is a lower bound, never a total.** Three times in one
   wave, a fix-these-N instruction turned out to be N+1 — and twice the
   extra instance sat inside something already reported fixed
   "everywhere". **Grep the whole item directory for a claim before
   closing it.** Rollups, evidence appendices, sub-tables and profile
   narratives are where the extras hide.

8. **A skeptic stage that only moves toward confidence is not a skeptic
   stage.** On one subject, both worst errors were introduced by its own
   verification pass — it promoted a row from Unknown to Supported on a
   URL that 404s, and certified a transposed table. Check that your
   verification moved claims in both directions; if every move was toward
   confidence, you have not verified, you have ratified.

## Two corollaries worth carrying

- **"JS-rendered" does not mean "unverifiable."** Check the served HTML
  for inlined row objects before logging a human-eyeball item. One
  agent recovered a full 13-row table this way after another had
  written it off.
- **Errors run in both directions.** Roughly half the defects a strong
  fact-check finds are **over-corrections against the subject** —
  understating a capability it genuinely has, or accusing it of an
  inconsistency its own docs disclose. A pass that reads skeptically is
  not thereby reading accurately.
