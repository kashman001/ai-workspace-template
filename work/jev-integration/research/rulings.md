# Orchestrator rulings — jev-integration research wave 1

Append-only. Every ruling the orchestrator makes lands here as it is made
(research-wave skill: "record every ruling in a durable file").

## Phase 0 (2026-09-23)

- R0.1 Subjects fixed at the launcher's three (`what-jev-is`, `terms`,
  `integration-paths`); no fourth. Reason: each costs 5–8 agents and the
  launcher capped at four; a fourth (e.g. "competitors") is not needed for
  the fit decision.
- R0.2 Schema written to `research/schema.md`; standing claims S1–S6
  listed there.
- R0.3 No finished item exists as a shape reference (first wave in this
  workspace); briefs point at the schema's claim format instead.
- R0.4 Off-limits: accounts, keys, API calls, spend. Public pages only.

## Phase 1/2 log

- 2026-09-23 pass `what-jev-is` returned DONE_WITH_CONCERNS (62 claims; 48 documented / 1 implied / 7 unknown / 5 contradicted). Reported overturns: S2 partial (Noul has no `confidence` field), S3 partial ("no human in the loop" not found; docs route low confidence to a human; "zero hallucinations" is a schema guarantee by TypeSafe's own definition). Fact-check launched with 9 priority targets (`what-jev-is/fc-targets.md`). Patterns to propagate to later checks: README overstated marketing claims; funding sources 403 on re-fetch; docs vs OpenAPI disagreements.
- 2026-09-23 pass `terms` returned DONE_WITH_CONCERNS (66 claims; 51 documented / 4 implied / 9 unknown / 2 contradicted; 28 open items). Reported overturns: S4's qualifier "production prices" is the launcher's wording, not the site's (the $42/Btok figure itself confirmed on docs /models; output tokens free; no /pricing page). Access may not be self-serve (waitlist, console 500s). Governed by a Master Customer Agreement, not a ToS. Fact-check launched with 8 targets + the docs-vs-OpenAPI pattern from `what-jev-is`.
- 2026-09-23 pass `integration-paths` returned DONE_WITH_CONCERNS (63 claims; 52 documented / 2 implied / 6 unknown / 6 split; 20 open items). Reported: S3 qualified by vendor docs (route low confidence to a human; nine failure modes; "guarantees the interface, not truth"); S6 holds for the homepage only. Key finding: the API never abstains — always returns a declared option plus a distribution; escape hatches are caller-side. No first-party MCP/CLI/batch/streaming. Fact-check launched with 8 targets + two sibling patterns.

## Phase 3 — rulings on `what-jev-is` (2026-09-23)

Fact-check: 57 of 62 claims re-checked; 50 confirmed / 6 overstated / 2 wrong / 4 unverifiable; no fabricated quotes; OpenAPI/docs core accurate. Rulings R1–R11 are written in full in `what-jev-is/corrections-brief.md`. Summary: R1 S3 human-in-loop half → `implied` (over-correction by the pass; "without a human co-pilot" / "acts autonomously" exist), hallucination half unchanged; R2 fix HN story/comment ids; R3 re-count cookbooks (checker says 16, not 14); R4 strip or derive the 75x/171x widget figure; R5 UTC-normalise SDK dates; R6 re-attribute founder facts to /team; R7 close O11 (Framer publish comment); R8 downgrade n-count/token/path verification notes; R9 restore FinSMEs as secondary; R10 name third-party MCP packages; R11 carry patterns into verification.md. Corrections agent dispatched as `corr-what-jev-is`.

## Phase 3 — rulings on `terms` (2026-09-23)

Fact-check: 66 of 66 claims re-checked; 62 confirmed / 1 overstated / 3 wrong / 0 unverifiable; all legal/pricing/limits/privacy quotes verbatim; "production prices" confirmed absent everywhere including the recovered homepage FAQ. Rulings R1–R8 in full in `terms/corrections-brief.md`. Summary: R1 overturn the pass's "not self-serve" — TypeSafe's X post of 2026-09-20 ("available to everyone. No waitlist.") and a homepage "NO MORE WAITLIST" banner supersede the launch post; sign-up 500 reports (skills#10) stay documented; R2 free credit is $5 (~120M tokens) per the same thread; R3 "Join Waitlist" is a Framer layer name, visible label "Open roles"; R4 console-JS strings are 403 handlers, not an active gate, chunk counts to be re-counted; R5 close O1/O7, add live-sign-up and 401-vs-403 items; R6 use the FAQ's own pricing qualifier and its "guarantees the shape of its answers, not that every decision is correct" as the first-party S3 temper; R7 prose fixes; R8 patterns. Corrections agent dispatched as `corr-terms`.
- Wave pattern (from both checks so far): passes over-correct on **absence claims** (grep for one spelling, then say "nowhere"/"anywhere") and on **access/state** (never consult the vendor's X channel for state newer than the launch post; JS-rendered copy is one curl of the Framer module scripts away). Carry into the `integration-paths` corrections and the Phase 4 sweep.

## Phase 3 — rulings on `integration-paths` (2026-09-23)

Fact-check: 48 of 63 claims re-checked (+25 appendix quotes, S1–S6, targets); 41 confirmed / 5 overstated / 1 wrong / 1 unverifiable; T1 (API never abstains; escape hatches caller-side) stands on the OpenAPI response schema. Rulings R1–R8 in full in `integration-paths/corrections-brief.md`. Summary: R1 error body IS documented (`HTTPValidationError`), close O2; R2 record the docs-vs-spec spread as a `contradicted` claim (`instructions` required vs optional; Score 2–10 vs minItems 1; Choice 255 cap vs none; probabilities "approximately 1"); R3 launch-post comparison table cited as `implied` for S3, consistent with `what-jev-is` R1; R4 slug/tilde and Vercel README wording; R5 pinning is conditional (alias is the docs' default); R6 3.8 evals pages carry no request JSON (close O14), 4.6 drop the phantom "planned" quote; R7 five overstated per fact-check; R8 patterns. Corrections agent dispatched as `corr-integration-paths`.
- New wave pattern: diff the machine-readable spec against the prose docs and record the spread; absence claims built from the reference survived, absence claims built from grep did not.
- 2026-09-23 `corr-terms` gen 1 returned ROLLOVER_NEEDED (child WARN): evidence for all eight rulings re-derived and persisted in `terms/corrections.md` (evidence block, 29-site rule-7 sweep, per-ruling edit plan); no deliverable edited; no ruling contradicted. Gen 2 (next session) applies the plan after re-fetching per the hard rules. New finding, ruled now: **R9 (terms)** — the S3 FAQ answer has two in-module variants ("acts automatically" / "acts autonomously"); gen 2 quotes both and names the spread rather than picking one.
- 2026-09-23 `corr-integration-paths` gen 1 DONE: 6 applied, 2 reworded, 0 refused; all figures re-derived and matched; new claim 5.12-spec-spread; O2/O14 closed; O21 added (which limits the server enforces). Second-round rulings, made now: **R9 (integration-paths)** the ValidationError example hint (`min_length: 1` at score.criteria) stays a hint inside O21, not a claim — APPLY as is (already done). **R10** the Vercel README restating the docs' 255 / 2–10 caps — ADD to 5.12-spec-spread's notes as a third source on the docs side (next session's sweep or a gen-2 corrections pass). **R11** the fact-check's optional strengthenings listed under "Not applied" — DEFER to the Phase 4 sweep; not applied by default (they are strengthenings, not corrections).
- 2026-09-23 `corr-what-jev-is` gen 1 DONE_WITH_CONCERNS: 7 applied, 3 reworded, 1 refused (R8 — the fact-check's "not discoverable" premise was wrong: C28 example is on /primitives, C49 n-counts are in the linked `<workflow>-cases.js` files; the re-cite alternative was applied instead). R4's premise was also wrong: the 75x/171x derivation existed in `pass/performance.md`; arithmetic now shown in C47. Totals re-counted 49/2/7/4. Second-round rulings, made now: **R12** the two fact-check premise errors — leave `fact-check.md` untouched (provenance); `verification.md`'s note is the record. **R13** V15 reversal → restate the lead scorecard as 33 survived with a corrected marker (gen 2 or sweep). **R14** C14 "optional" vs "nullable" — record the spec's exact keyword and the docs' word side by side; sweep. **R15** C50 low-end minima (7.2x/20.3x) come from a "clean round trip" row not under 16-way contention — qualify the claim so "measured under 16-way contention" applies to the high end only.

## Phase 3 status at session-1 rollover (2026-09-23)

- `what-jev-is`: corrections gen 1 DONE (R1–R11 applied/reworded/refused as above); second-round R12–R15 pending.
- `terms`: corrections gen 1 ROLLOVER_NEEDED — nothing applied; evidence + edit plan in `terms/corrections.md`; gen 2 applies R1–R9.
- `integration-paths`: corrections gen 1 DONE; second-round R9–R11 recorded (R10 needs an edit; R11 deferred to sweep).
- Phase 4 sweep and synthesis: not started.
