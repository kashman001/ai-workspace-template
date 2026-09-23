# Corrections brief — `what-jev-is` (jev-integration wave 1, 2026-09-23)

Working directory: `/Users/kashif/Developer/experiments/ai-workspace-template`.
Item directory (the ONLY place you write): `work/jev-integration/research/what-jev-is/`.

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

- R1 **S3 / C34 / T2 / profile prose — APPLY-REWORDED.** The human-in-the-loop half of S3 moves from `contradicted` to `implied`: the literal phrase is absent, but the docs say "without a human co-pilot" and "proceed without human involvement", and the homepage says "acts autonomously" (quote each with its URL). Keep, as `documented`, that the confidence docs prescribe routing low-confidence answers to a human. Net wording: "autonomous operation is implied, conditioned on confidence gating that the caller implements". The hallucination half stays as the pass had it (0% is a schema guarantee by TypeSafe's own definition). Fix every echo of the old wording in `profile.md`, `verification.md`, and the S-table.
- R2 **Appendix HN citations — APPLY.** Re-cite each HN quote to the story and comment id the fact-check found; verify each id yourself via `https://hn.algolia.com/api/v1/items/<id>` before writing it. Do not delete the quotes.
- R3 **C55 "14 cookbooks cite jev-1.12" — APPLY after re-count.** Re-count from the source the fact-check names (llms-full Source lines) and write the number you get, with the method in the notes.
- R4 **C47 "widget implies 75x/171x" — APPLY.** No derivation exists in the item. Either derive it from the homepage widget's own inputs and show the arithmetic, or remove the figure and mark that half `unknown` with "derivation not recorded by the pass". The 193.6x/444.6x/238x figures stay as confirmed.
- R5 **C39 / T9 release-date spread — APPLY.** Normalise all timestamps to UTC; the JS SDK "spread" collapses to one instant and is removed; the Python spread stays if it survives normalisation (show the UTC values).
- R6 **C59 founder attributions — APPLY.** Re-attribute the "Google Brain" and "Embarcadero" facts to the /team page per the fact-check; check no other page-level attribution in C59 is misassigned.
- R7 **C61 / O11 "Published Sep 22" — APPLY.** Close O11 in `open-verification.md`: the string is Framer's site-publish HTML comment, not a launch date; launch date stays 2026-09-15.
- R8 **C49 n-counts, C50 "three tokens", C28 example path — APPLY-REWORDED.** Keep the figures; downgrade the verification note to "not discoverable from the public pages" (n-counts: no linked data file) or `implied`, exactly as the fact-check describes, and tag each in `open-verification.md` with the access that would settle it.
- R9 **Funding sources — APPLY.** FinSMEs serves 200 to a browser user-agent; restore it as a secondary citation alongside The New Stack (primary). Verify with `curl -A "Mozilla/5.0"` yourself.
- R10 **T7 MCP packages — APPLY.** In the SDK/MCP claim, name the third-party npm packages and authors and licences the fact-check found (at least `@jkudish/jev-mcp`, `jevcore-mcp`; "at least four more" stays as a lower bound with the search you ran). First-party absence stands.
- R11 **Patterns — APPLY as a note.** Add the fact-check's patterns section verbatim to the end of `verification.md` under `## Patterns from the independent check`.

Return at most 12 lines: status line first (DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT | ROLLOVER_NEEDED); rulings applied / reworded / refused counts; any refusal and why; any new finding needing a ruling. Detail in `corrections.md`.
