<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 1 (2026-09-23): research wave launched; all three passes and their fact-checks done; corrections in flight

1. Registered as session 1 (`seq=1`). Ran `research-wave` as orchestrator over three subjects: `what-jev-is`, `terms`, `integration-paths` (ruling R0.1: no fourth subject). Schema, standing claims S1–S6, landmines, and budget are in `research/schema.md`; every ruling is in `research/rulings.md` (append-only).
2. Phase 1: three pass leads launched in one message (each fanned out five cluster sub-agents). All returned DONE_WITH_CONCERNS: 62 / 66 / 63 claims. Deliverables per subject: `record.md`, `profile.md`, `verification.md`, `open-verification.md`, `pass/*.md` (raw, untouched provenance).
3. Phase 2: independent fact-checks per subject (`fact-check.md`, agents that did none of the research). `what-jev-is`: 57 of 62 re-checked, 50 confirmed / 6 overstated / 2 wrong / 4 unverifiable. `terms`: 66 of 66, 62 / 1 / 3 / 0. `integration-paths`: 48 of 63, 41 / 5 / 1 / 1; the load-bearing finding (API never abstains) stands on the OpenAPI response schema.
4. Phase 3: rulings written to `rulings.md` and per-subject `corrections-brief.md`; corrections agents dispatched for `what-jev-is` (R1–R11) and `terms` (R1–R8). Then for `integration-paths` (R1–R8). Outcome: `what-jev-is` DONE_WITH_CONCERNS (7 applied, 3 reworded, 1 refused — the refusal was right, the fact-check's premise was wrong); `integration-paths` DONE (6 applied, 2 reworded); `terms` ROLLOVER_NEEDED at child WARN — evidence and edit plan persisted in `terms/corrections.md`, nothing applied yet. Second-round rulings for all three are at the end of `rulings.md`.
5. Headline findings so far (corrected, not yet swept): (a) the API always returns one of the caller's declared options plus a probability distribution — it never abstains or errors on a non-fitting input; escape hatches are caller-side (an `other` option, a `confidence` gate on Choice/Score only — Noul has no confidence field). (b) Standing claim S3 was overstated by our README: "no human in the loop" is `implied` ("without a human co-pilot", "acts autonomously") and conditioned on caller-side confidence gating; the docs route low confidence to a human; "zero hallucinations" is, by TypeSafe's own definition, a schema guarantee ("guarantees the shape of its answers, not that every decision is correct"). (c) S4: $42 per billion input tokens confirmed (docs /models; output tokens free; no /pricing page); "production prices" was our wording, not the site's — the vendor's qualifier is the homepage FAQ ("We can serve Jev profitably at our current prices…"). (d) Access is self-serve since 2026-09-20 ("No waitlist", $5 starting credit) though sign-up 500s were reported Sep 21–22 (typesafe-ai/skills#10). (e) One endpoint (POST api.typesafe.ai/v1/systemone) + GET /v1/models, bearer key, public OpenAPI 3.1, one model jev-1.13.0 behind moving aliases; no first-party MCP/CLI/batch/streaming; third-party MCP packages exist on npm. (f) Governed by a Master Customer Agreement (2026-09-19): no-training commitment, perpetual telemetry licence, no SLA, prepaid credits, rate limits 250k tok/s / 1,200 rpm "can change without notice".
6. Wave patterns (the most valuable output — carry into every later check): passes over-correct on **absence claims** (grep one spelling, then say "nowhere"); passes miss **vendor state newer than the launch post** (X channel, JS-rendered FAQ/banners recoverable by curling the Framer module scripts); **quotes are real but URLs/ids drift** (HN story ids); **self-computed numbers** without a recorded derivation; UTC-vs-local date "spreads"; docs and OpenAPI disagree in places (`instructions` required?).
7. Context budget: WARN reached after the fact-checks; rolled over hands-off mid-Phase-3. Dispatch records under `.agent-dispatch/` (one per task, generation-fenced) say exactly which tasks are closed. main not pushed.

# Session Handoff — 2026-09-22 (scaffold): item created; the research wave comes next

**Summary.** Scaffolded by a session bound to `session-management-followups`
(so this block carries no session number; the item's counter starts at the
first `register --project jev-integration`). The user asked for a work item
to integrate Jev into the template, with the first session doing research;
they pointed at <https://typesafe.ai> for what Jev is and chose
`research-wave` over `research`. The homepage says Jev is TypeSafe's "first
public System One Model, optimized for automation" — typed decisions with
confidence estimates rather than text, priced per token, docs at
<https://docs.typesafe.ai/>; nothing on the page says how it is called
(SDK/HTTP/MCP), which is why the launcher's subject list starts there.

**State.** README (goal, success criteria pending a fit decision), launcher
(subject list proposed for the wave), this ledger; row added to
`work/README.md`. No `research/`, `decisions.md`, or `spec.md` yet.

**Next.** `next-session.md` → run the research wave.
