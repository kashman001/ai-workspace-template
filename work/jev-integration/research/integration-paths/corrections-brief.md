# Corrections brief — `integration-paths` (jev-integration wave 1, 2026-09-23)

Working directory: `/Users/kashif/Developer/experiments/ai-workspace-template`.
Item directory (the ONLY place you write): `work/jev-integration/research/integration-paths/`.

You apply the orchestrator's rulings below to the item's deliverables. Read
first: `skills/research-wave/references/method-rules.md`, then the item's
`fact-check.md` (the evidence behind each ruling), then `record.md`,
`profile.md`, `verification.md`, `open-verification.md`.

Hard rules:
- **Re-derive every number while applying it** (re-fetch the page or re-count
  the file) rather than trusting the ruling's figure. If your re-derivation
  disagrees with the ruling, do NOT apply it — report the disagreement.
- **Grep the whole item directory** for every claim you correct before
  closing it (method rule 7): a count of N instances is a lower bound.
  Includes `profile.md` prose and the appendix.
- **Mark each corrected claim** in place with `(corrected 2026-09-23; previously: "<old text>")`.
- **Leave `pass/*.md`, `fact-check.md`, `brief.md`, `fc-targets.md`, `fact-check-brief.md` untouched** — provenance.
- **Refuse** any ruling the evidence contradicts, and say so in your report.
- Public sources only; curl/WebFetch; no accounts, keys, API calls, or spend.
- Write `corrections.md` in the item directory: one entry per ruling —
  applied / applied-reworded / refused / could-not-apply, with what changed
  and where (file + claim id). End it with a `## Not applied` section (may
  be empty) and a `## New findings needing a ruling` section (may be empty).

## Rulings (orchestrator, 2026-09-23)

- R1 **5.9 "error body's JSON shape is not shown anywhere" — APPLY (WRONG).** The OpenAPI spec defines `HTTPValidationError` with a worked example. Quote the schema from https://api.typesafe.ai/openapi.json yourself, set the claim to `documented`, and close O2 in `open-verification.md`.
- R2 **Docs-vs-spec spread — APPLY as a new claim.** Add a claim (id `5.x-spec-spread`) recording, side by side with URLs: docs mark `instructions` required, cap Score at 2–10 options and Choice at 255; the OpenAPI spec makes `instructions` optional, Score `minItems` 1, no caps, and describes probabilities as summing to "approximately 1". Verdict `contradicted (docs vs. spec)`; re-derive every number from both sources. Add an open item: which one the server enforces (needs one authenticated call).
- R3 **Standing claim S3 — APPLY-REWORDED.** The launch post's comparison table puts "Human-in-the-loop tasks … requires human oversight" in the LLM column and "AI-Powered Workflows / smart if-statements" in the System One column: cite it (verbatim, URL) as `implied` support for autonomous operation, conditioned on confidence gating. This matches the ruling on the sibling subject; do not reintroduce "no human in the loop" as documented.
- R4 **T6 wording — APPLY.** The jev-1.13 docs slug has no tilde; the Vercel README does state "Boolean maps to TypeSafe's Noul" — fix both, verbatim.
- R5 **T8 pinning — APPLY-REWORDED.** Pinning is *conditional*: the docs' own default is the alias, and pinning is advised once thresholds are tuned. Reword the claim and any profile prose that says pinning is simply recommended.
- R6 **3.8 and 4.6 — APPLY.** 3.8: the four evals pages carry no request JSON — replace `unknown` with that documented absence and close O14. 4.6: the word "planned" does not appear on the cited page — replace the quote with what the page actually says.
- R7 **The five OVERSTATED claims — APPLY** exactly as `fact-check.md` lists them, re-deriving any number involved.
- R8 **Patterns — APPLY as a note.** Append the fact-check's patterns section verbatim to `verification.md` under `## Patterns from the independent check`.

Return at most 12 lines: status line first (DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT | ROLLOVER_NEEDED); rulings applied / reworded / refused counts; any refusal and why; any new finding needing a ruling. Detail in `corrections.md`.
