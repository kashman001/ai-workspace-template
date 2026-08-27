# Pass brief — template for one research item

Fill the `<...>` placeholders and hand this to the agent leading one
item. Every item in a wave gets the same brief with different
placeholders — that sameness is what makes the results comparable.

---

You are the **lead** for one item in a research wave: `<item name>`.

**Working directory:** `<repo root>`
**Your item directory — the ONLY place you write:** `<item directory>`

Other items in this wave are being researched concurrently in their own
directories. Read anything; write only there. Per-item write isolation is
what makes the parallelism safe.

**First, read `<path to method-rules.md>` in full**, then
`<path to the schema every item is filled against>`, then **one** finished
item as a shape reference: `<path>`. One, not several — matching the
shape is the goal, and reading three costs context without adding
precision.

## Scope rules

`<State the hard boundaries. Typical ones:>`
- **Public sources only** — no accounts, no logins, no spend, no calls
  that cost the subject or us money.
- `<Any tool that does not work in this environment, named explicitly.>`
- **Tool budget:** `<search quota / fetch-only / rate limits>`. It is
  shared across the wave and it can run out mid-run — start from the
  subject's own documentation index and spend search only on what an
  index cannot answer.

## The standard of proof

**"Unknown" is the honest answer** when public sources do not say, and
under a documents-only rule it is expected to be common. A record full of
honest unknowns is worth more than one full of inferred conclusions.
Stretching a marketing phrase to avoid an unknown is the single most
common way an item becomes unusable.

Every claim carries: the **verdict**, the **specific source URL** (the
page, not the site), the **date checked**, **how it was verified**, and
**notes** that say what is *documented* versus what is *implied*. Any
performance number carries its full configuration, or says explicitly
that the configuration is undisclosed.

## Your agent graph

Fan out roughly five sub-agents across `<clusters>`, launched in one
message so they run concurrently. Each writes its raw findings with
verbatim evidence quotes into `<item directory>/pass/<cluster>.md`.

Then **verify**: re-check every uncertain positive claim against its
cited source. Method rule 8 is the bar — if every claim you moved went
toward confidence, you ratified rather than verified. Say which claims
moved *down*.

Then **synthesize** into the deliverables.

## Deliverables, in your item directory

- `<primary record>` — every claim in the agreed schema, each with
  evidence, closing with a verbatim-quote appendix for anything
  load-bearing or surprising.
- `profile.md` — the one-page narrative: posture, journey, verdicts.
- `verification.md` — the adversarial re-check: each uncertain claim,
  what the source actually says, and whether it survived, was
  downgraded, or was overturned.
- `open-verification.md` — what public sources could not settle, each
  tagged with the kind of access that *would* settle it.

## Progress and return

Append a progress block to your primary record at each work-unit
boundary — that is your heartbeat, and it is what a successor reads if
you run out of context.

**Return at most 15 lines.** First line is your status. Then: claims
filled and unknown count; anything that **contradicts a claim we already
hold** (say this loudly and first); the one or two most consequential
findings; and anything you could not settle that matters.

Detail belongs in the files. The orchestrator's context is the binding
constraint on the whole wave, and a full record pasted into chat is the
most reliable way to end it early.
