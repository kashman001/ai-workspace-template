# Session Handoff — 2 (2026-09-23): Phase 3 closed — all three subjects corrected in two rounds; sweep brief and seam inventory written; rolled at WARN before the sweep

1. Registered as session 2 (`seq=2`, launched hands-off by session 1). Read the launcher, `rulings.md`, `schema.md`, the dispatch records (all gen-1 generations were closed, none stranded).
2. Phase 3 finished. Three corrections agents ran in parallel: `corr-terms` gen 2 (R1–R9, DONE: 8 applied / 1 reworded; tally 51/4/9/2 → 54/3/7/2; O1/O7 closed, O29/O30 added), `corr-what-jev-is` gen 2 (R12–R16, DONE_WITH_CONCERNS: scorecard restated 33 survived; C14 spec-vs-docs keywords side by side; **R15 refused** — gen 2 reads the choice cookbook's "clean round trip" line opposite to gen 1; C50 unchanged), `corr-integration-paths` gen 2 (R9–R11, DONE: Vercel README lines 49–51 added to 5.12-spec-spread as a docs-side third source). Every dispatch closed; briefs `*/corrections-brief-2.md`.
3. Rulings this session: R16 (what-jev-is), R12 (integration-paths), R17–R20 (what-jev-is), R21–R23 (terms/cross-item), all in `research/rulings.md` under "Phase 3 — second round, session 2" and "Phase 3 closed". Queued for ONE post-sweep corrections pass per subject: R18 (C50 denominator caveat, if the sweep confirms gen 2's reading), R20 (api.md `instructions` type list omits `null` → C14 + mirror in 5.12-spec-spread), R21 (terms 6.6/V10 chunk counts halved), R22 (server-rendered homepage S3 line "Set the thresholds for when it acts autonomously and when it asks for review." → what-jev-is S3 evidence). Deferred to the sweep's judgement: R11, R16 (strengthenings/cosmetic).
4. Written for Phase 4/synthesis: `research/sweep-brief.md` (four sweeps + the R17/R20 disputes the sweep must settle) and `research/seam-inventory.md` (read-only Explore agent's inventory of the template's closed-set decision seams with file:line pointers; two pointers spot-checked: `rlm_repl.py` `_claude_exe()`/`claude -p --model` at L112/L193, ADR-0011 mechanical gates). Headline of the inventory: `rlm` leaf labelling and the research-wave per-claim verdict are the closed-set seams; every session-lifecycle gate is deterministic by ADR-0011 and off the table.
5. Not started: the sweep itself, the post-sweep corrections pass, `synthesis.md`, the README status flip. No fit decision (research before design still binds).
6. Context: WARN at ~126K after the seam inventory landed; waited for the three children (they die with the session), closed Phase 3, rolled hands-off. main not pushed.

Learnings:
- Two corrections generations read one source line (cookbook L557–558) in opposite ways; the orchestrator cannot settle that from two summaries — route such disputes to the sweep's evidence spot-check with the exact line range (R17), never rule on a summary.
- Launching the per-subject second-round passes in parallel with the stranded gen 2 cost one message and finished Phase 3 in one session; write the tiny briefs rather than folding second-round rulings into the sweep.
- A pre-written sweep brief + a read-only seam inventory are cheap to produce while children run and make the successor's session start at Phase 4 with nothing to prepare.

Suggested skills for session 3: `research-wave` (Phase 4, then handing the wave off), `decision-log` only if a real decision with a rejected alternative appears (none did here), `session-rollover` at the end (`--loop-mode interactive` once the synthesis is written — the fit decision needs the human).

# Session Handoff — 1 (2026-09-23): research wave launched; all three passes and their fact-checks done; corrections in flight

1. Registered as session 1 (`seq=1`). Ran `research-wave` as orchestrator over three subjects: `what-jev-is`, `terms`, `integration-paths` (ruling R0.1: no fourth subject). Schema, standing claims S1–S6, landmines, and budget are in `research/schema.md`; every ruling is in `research/rulings.md` (append-only).
2. Phase 1: three pass leads launched in one message (each fanned out five cluster sub-agents). All returned DONE_WITH_CONCERNS: 62 / 66 / 63 claims. Deliverables per subject: `record.md`, `profile.md`, `verification.md`, `open-verification.md`, `pass/*.md` (raw, untouched provenance).
3. Phase 2: independent fact-checks per subject (`fact-check.md`, agents that did none of the research). `what-jev-is`: 57 of 62 re-checked, 50 confirmed / 6 overstated / 2 wrong / 4 unverifiable. `terms`: 66 of 66, 62 / 1 / 3 / 0. `integration-paths`: 48 of 63, 41 / 5 / 1 / 1; the load-bearing finding (API never abstains) stands on the OpenAPI response schema.
4. Phase 3: rulings written to `rulings.md` and per-subject `corrections-brief.md`; corrections agents dispatched for `what-jev-is` (R1–R11) and `terms` (R1–R8). Then for `integration-paths` (R1–R8). Outcome: `what-jev-is` DONE_WITH_CONCERNS (7 applied, 3 reworded, 1 refused — the refusal was right, the fact-check's premise was wrong); `integration-paths` DONE (6 applied, 2 reworded); `terms` ROLLOVER_NEEDED at child WARN — evidence and edit plan persisted in `terms/corrections.md`, nothing applied yet. Second-round rulings for all three are at the end of `rulings.md`.
5. Headline findings so far (corrected, not yet swept): (a) the API always returns one of the caller's declared options plus a probability distribution — it never abstains or errors on a non-fitting input; escape hatches are caller-side (an `other` option, a `confidence` gate on Choice/Score only — Noul has no confidence field). (b) Standing claim S3 was overstated by our README: "no human in the loop" is `implied` ("without a human co-pilot", "acts autonomously") and conditioned on caller-side confidence gating; the docs route low confidence to a human; "zero hallucinations" is, by TypeSafe's own definition, a schema guarantee ("guarantees the shape of its answers, not that every decision is correct"). (c) S4: $42 per billion input tokens confirmed (docs /models; output tokens free; no /pricing page); "production prices" was our wording, not the site's — the vendor's qualifier is the homepage FAQ ("We can serve Jev profitably at our current prices…"). (d) Access is self-serve since 2026-09-20 ("No waitlist", $5 starting credit) though sign-up 500s were reported Sep 21–22 (typesafe-ai/skills#10). (e) One endpoint (POST api.typesafe.ai/v1/systemone) + GET /v1/models, bearer key, public OpenAPI 3.1, one model jev-1.13.0 behind moving aliases; no first-party MCP/CLI/batch/streaming; third-party MCP packages exist on npm. (f) Governed by a Master Customer Agreement (2026-09-19): no-training commitment, perpetual telemetry licence, no SLA, prepaid credits, rate limits 250k tok/s / 1,200 rpm "can change without notice".
6. Wave patterns (the most valuable output — carry into every later check): passes over-correct on **absence claims** (grep one spelling, then say "nowhere"); passes miss **vendor state newer than the launch post** (X channel, JS-rendered FAQ/banners recoverable by curling the Framer module scripts); **quotes are real but URLs/ids drift** (HN story ids); **self-computed numbers** without a recorded derivation; UTC-vs-local date "spreads"; docs and OpenAPI disagree in places (`instructions` required?).
7. Context budget: WARN reached after the fact-checks; rolled over hands-off mid-Phase-3. Dispatch records under `.agent-dispatch/` (one per task, generation-fenced) say exactly which tasks are closed. main not pushed.

<!-- ARCHIVE of work/jev-integration/handoff.md — older ledger blocks, newest on top. Convention: docs/work-directory-conventions.md -->

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

