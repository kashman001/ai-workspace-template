# Corrections brief — `terms` (jev-integration wave 1, 2026-09-23)

Working directory: `/Users/kashif/Developer/experiments/ai-workspace-template`.
Item directory (the ONLY place you write): `work/jev-integration/research/terms/`.

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

- R1 **Access / self-serve (claims 6.2, 6.3, profile "not demonstrably self-serve; expect a gate") — APPLY-REWORDED, overturning the pass.** Per the fact-check, TypeSafe's X account posted on 2026-09-20 "Jev is now available to everyone. No waitlist." and the homepage's Framer module script carries a dated "NO MORE WAITLIST" banner. Re-fetch both yourself (X may refuse curl — if so, cite the homepage banner as primary and mark the X quote "as recorded by the independent check on 2026-09-23, not re-fetched"). New wording: self-serve sign-up is `documented` as of 2026-09-20; the Sep 15 launch post's early-access wording is superseded. Keep, as `documented`, GitHub typesafe-ai/skills#10 (sign-up/login 500s reported Sep 21–22, "still reproducible" Sep 22, no vendor reply). Fix every echo in `profile.md`, `verification.md`, `open-verification.md`.
- R2 **Free credit (6.1, 6.7 "no free-credit amount published anywhere") — APPLY.** The same X thread says "All users start with $5 in credit (~120 million tokens)." Re-derive the token figure from the documented $42 per billion input tokens and state whether it is consistent.
- R3 **"Join Waitlist" button — APPLY.** The string is a `data-framer-name` layer attribute; the visible label is "Open roles" linking to the jobs board. Reword the claim so it says what a visitor sees.
- R4 **Console-JS gating strings — APPLY.** Reword as client-side 403 error-handling branches (`SELF_SERVE_DISABLED`/invite), not evidence that a gate is active; re-count the chunks yourself (the fact-check found the pass's counts exactly doubled) and write the number you get.
- R5 **Open items — APPLY.** Close O1 and O7 with the evidence above; add open items for (a) live sign-up success today and (b) docs say 401 where the reported error was 403.
- R6 **Homepage FAQ (recovered from the Framer module scripts) — APPLY.** (a) Replace the launcher's "production prices" qualifier on the $42/Btok claim with the vendor's own FAQ answer, quoted verbatim from the page (begins "We can serve Jev profitably at our current prices"). (b) Add, as a `documented` first-party temper of standing claim S3, the FAQ line that Jev "guarantees the shape of its answers, not that every decision is correct" (verbatim, with URL). (c) Note that S1's "first public System One Model, optimized for automation" wording originates in the FAQ.
- R7 **Prose findings in `profile.md` and the appendix — APPLY** exactly as `fact-check.md` lists them.
- R8 **Patterns — APPLY as a note.** Append the fact-check's patterns section verbatim to `verification.md` under `## Patterns from the independent check`.

Return at most 12 lines: status line first (DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT | ROLLOVER_NEEDED); rulings applied / reworded / refused counts; any refusal and why; any new finding needing a ruling. Detail in `corrections.md`.
