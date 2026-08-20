# Fact-check brief — template for the independent check

Fill the `<...>` placeholders and hand this to an agent that did **none**
of the original research. Independence is the whole mechanism: an agent
checking its own work re-reads its own reasoning.

---

You did NOT do this research. You are the independent check on someone
else's work. Your value is finding what they got wrong, so read
adversarially: assume at least one claim is wrong until you prove
otherwise.

**Target:** `<item directory>`
**You write exactly one file:** `<item directory>/fact-check.md`.
Leave every other file in that directory as you found it — other items
are being worked on concurrently, and you recommend rather than edit.

**First, read `<path to method-rules.md>` in full.** It is the standing
evidence and process discipline for this wave, and rules 1–4 are your
primary tools.

**Tool budget:** `<state what is available — search quota, fetch-only,
rate limits>`. Plan around it before you start rather than discovering
it mid-run.

## What to check, in priority order

1. **The priority targets below** — the claims that change a decision or
   contradict something already published.
2. Every claim a reader would **act on**, and every claim carrying a
   **number**.
3. Every **absence claim** — these are the weakest evidence class and the
   most frequently wrong. Method rules 1 and 2 govern.
4. A **sample of the rest**, at least ten more.
5. **The prose, not just the structured claims.** Headers, coverage
   lines, summary verdicts and narrative all state facts, and on some
   items every single error lived there while the structured cells stayed
   clean. On others the reverse. Check both.

**Priority targets for this item:**
`<list them, one per line, each phrased as a claim to rule on rather than
a question to explore. Say explicitly that each cuts both ways — the pass
may be right, or it may have over-corrected.>`

## Failure modes — flag each by name

- **Source does not support the claim** — page says something weaker,
  narrower, or different.
- **Dead or redirected source** — 404, or lands somewhere without the
  cited text.
- **Marketing scored as documentation** — a landing-page phrase treated
  as a documented capability.
- **Preview scored as generally available** — real, but beta/waitlisted,
  and the claim does not say so.
- **Someone else's capability** — an upstream provider's or subsidiary's
  feature recorded as the subject's own.
- **Fabricated quote** — quoted string absent from the cited page. Check
  raw HTML; report the occurrence count.
- **Missing configuration** — a performance number without the hardware
  and settings behind it, or without saying they are undisclosed.
- **Over-correction against the subject** — a capability it genuinely
  has, understated or denied. Roughly half of real findings are these.
- **Wrong standard** — "unknown" where the source plainly answers, or a
  confident verdict where "unknown" is honest.
- **Stale date** — checked date not matching what was actually verified.

## Output: `<item directory>/fact-check.md`

Header: who checked, the date, how many claims re-fetched of how many
total. Then one row per claim: **claim | verdict (CONFIRMED /
OVERSTATED / WRONG / UNVERIFIABLE) | what the source actually says |
recommended correction.** Confirmed claims get one line; problems get as
much room as they need.

Close with a **patterns** section: the systematic biases you saw across
the item. These matter more than any single claim — they transfer to
every other item in the wave, and they are what the orchestrator
propagates.

**Recommend; do not edit.** The orchestrator rules on your findings.

## Return: at most 12 lines

First line: `CLEAN` / `CORRECTIONS_NEEDED` / `SERIOUS`. Then counts by
verdict, the worst two or three findings, and any pattern. Detail belongs
in the file — the orchestrator's context is the binding constraint on the
whole wave.
