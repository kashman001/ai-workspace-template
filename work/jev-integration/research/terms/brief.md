# Pass brief — `terms` (jev-integration research wave 1, 2026-09-23)

You are the **lead** for one item in a research wave: `terms`.

**Working directory:** `/Users/kashif/Developer/experiments/ai-workspace-template`
**Your item directory — the ONLY place you write:** `work/jev-integration/research/terms/`

Other items in this wave are being researched concurrently in their own
directories. Read anything; write only there.

**First, read `skills/research-wave/references/method-rules.md` in full**, then
`work/jev-integration/research/schema.md` (your questions are the
`### terms` list; your claim format is the table there). No finished item
exists yet as a shape reference — this is the first wave — so match the
schema's claim format exactly.

## Scope rules

- **Public sources only** — no accounts, no logins, no API keys, no API
  calls, no spend. Do not open `console.typesafe.ai` beyond its logged-out pages.
- **Tools:** WebFetch, WebSearch, and `curl` via Bash. Load deferred tools
  with ToolSearch (`select:WebFetch,WebSearch`). Do not use the Chrome
  browser tools.
- **Tool budget:** search is shared across three concurrent subjects. Start
  from `https://docs.typesafe.ai/` (crawl its nav/index), `https://typesafe.ai`,
  and `https://typesafe.ai/blog/introducing-system-one-models-and-jev`;
  spend search only on what those cannot answer (third-party use, SDK
  packages on npm/PyPI/GitHub).
- **Landmines:** the site is marketing copy — every number traces to a docs
  or pricing page or is `unknown`. "No hallucinations" is a claim, not a
  finding. Do not confuse Jev with Japanese encephalitis virus (JEV) or
  unrelated packages/users named jev.
- **Subject-specific risk:** S4 — the pricing figure and its qualifier. Check the pricing page, the docs, and the console's public pages; a homepage number without a pricing page behind it is `implied`, not `documented`.

## The standard of proof

**"Unknown" is the honest answer** when public sources do not say. Every
claim carries the verdict, the specific source URL (the page, not the
site), the date checked, how it was verified, and documented-vs-implied.
Any performance or price number carries its full configuration or says
the configuration is undisclosed.

## Your agent graph

Fan out five sub-agents (Agent tool, `general-purpose`), launched in one
message so they run concurrently, across these clusters: `pricing` (Q1, Q6), `limits-and-auth` (Q2, Q3), `data-and-privacy` (Q4), `legal` (Q5), `support-and-status` (Q7).
Each writes its raw findings with verbatim evidence quotes into
`work/jev-integration/research/terms/pass/<cluster>.md` and returns at
most 10 lines to you. Give each the scope rules and landmines above verbatim.

Then **verify**: re-check every uncertain positive claim against its
cited source. Method rule 8 is the bar — say which claims moved *down*.

Then **synthesize** into the deliverables.

## Deliverables, in `work/jev-integration/research/terms/`

- `record.md` — every question in the schema answered as claims in the
  claim format, with evidence, closing with a verbatim-quote appendix.
- `profile.md` — the one-page narrative.
- `verification.md` — the adversarial re-check: each uncertain claim,
  what the source actually says, survived / downgraded / overturned.
- `open-verification.md` — what public sources could not settle, each
  tagged with the access that would settle it (account, key, email).

Append a progress block to `record.md` at each work-unit boundary.

**Return at most 15 lines.** First line: status. Then: claims filled and
unknown count; anything that **contradicts a standing claim S1–S6 in the
schema** (say this loudly and first); the one or two most consequential
findings; anything unsettled that matters. Detail belongs in the files.
