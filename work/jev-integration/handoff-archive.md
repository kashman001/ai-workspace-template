# Session Handoff — 6→7 bridge (2026-09-25): written by the `plans` item's session 15 under its ticket 11 — the user chose this item for the first real plan and set the direction (integrate, gated on Jev access); plan `01-gated-integration` opened; session 6's four open grill questions folded into nodes 01 and 03

1. Session 6 closed through the checkpoint door at 22:23Z (commit 524bb2a; supervisor verdict `quit_plain`, chain closed). Its launcher carried the four open round-1 grill questions (Q1 axis, Q2 scope, Q4 terms risk, Q5 lift scope) with recommendations; `decisions.md` holds the R0.4-lift note and "fit decision STILL OPEN".
2. In the `plans` session, answering ticket 11's "which item?", the user chose this one and added: integrate Jev **only where a person has Jev access**. That answers Q4 as (a) — optional path, current runtime as the default and fallback. Q1, Q2, Q5 stay open: node 01 drafts the fit note taking the recommendations as proposals, node 03 (`hitl`) is where the person confirms or amends them. Direction recorded in `plans/01-gated-integration/plan.md` → Goal.
3. Plan opened with `scripts/plan.sh new gated-integration`: six nodes in three waves (01 decision-note → 02 join; 03 approve-decision [hitl] → 04 join; 05 spec-and-tickets → 06 join + structural replan adding the implementation waves from the tickets). `check` silent; launcher rewritten with the Position block; `sync` run; README status line and `work/README.md` row updated.
4. Noticed while doing it: session 6's commit landed ten minutes after the plans session started, so a first pass here was written against a stale snapshot (spike thought untracked, `decisions.md` thought absent, the grill questions dropped) and redone against 524bb2a. Recorded as a dogfood finding in `work/plans/decisions.md`. Also found then: two `session-loop.sh jev-integration` supervisor processes (started 2026-09-23 10:04 and 13:05 local) paging `staged_alive seq=6` every 15 min since 2026-09-23 18:20Z; left running as the user's terminal processes. Both had exited by 2026-09-27.

Learnings:
- Two sessions on one checkout: re-read `git log -1` and the target files immediately before rewriting another item's launcher, not at session start — a concurrent interactive session can commit in between.

# Session Handoff — 5 (2026-09-23): wave 1 closed — §1 re-check clean (no edit), README status line and work-index row committed (c719edd); rolled over interactive at ~80K to pose the fit decision to the human

1. Registered `seq=5`. `dispatch-list`: all ten records closed (DONE / DONE_WITH_CONCERNS), none open.
2. §1 re-check of `research/synthesis.md` against the four gen-3 change sites, by grep only: C50's denominator caveat matches §1's "contended LLM latency (16-way pool) by uncontended TypeSafe latency"; `integration-paths` S2 "contradicted for Noul" matches §1 (Noul carries no `confidence`) and the §2 S2 row; the S4 price-FAQ answer is quoted in §1 Terms with `terms` 1.7 / `what-jev-is` S4; the profile's stale `<meta>` "in early access" does not contradict §1's "open self-serve as of 2026-09-20" (§3 sweep row 1 already records the fix). **No edit to the synthesis** — reason in the `Decision:` trailer of c719edd.
3. Close: status line in `README.md` after "Start here"; `work/README.md` row L23; `record --label "wave close"`; commit c719edd. main is 15 commits ahead of `origin/main`, not pushed (the push is the user's call).
4. Rolled over `--loop-mode interactive` (budget OK at ~80K; the trigger is the human-only step, not WARN). Block 3 moved to `handoff-archive.md`. No `decisions.md` yet — research-before-design still binds.

Suggested skills for session 6: `grill-with-docs` (with the human, on §5–§6 of the synthesis + `seam-inventory.md`); `decision-log` / `/decision` for the Tier-2 note; `to-spec` only after the note exists; `checkpoint` if the human defers.

Learnings:
- A launcher that names grep targets for a re-check (session 4's did) keeps the whole close under ~25K, orientation included; the session never approached WARN.

# Session Handoff — 4 (2026-09-23): rulings R24–R37 verified (R38); scale adopted into schema.md; gen-3 corrections applied on all three subjects; R39–R41; synthesis final as research/synthesis.md; rolled at WARN before the README/work-index close

1. Registered `seq=4`. Verified R24–R37 against `sweep.md` rows: all hold; five amendments as **R38** (IP profile L51/O21 in R26; S4 pointer → O9; IP "six down" restated not marked; R22 reduces to the appendix + SW1-1 cross-pointer; R36 scope). Sweep scale adopted verbatim into `schema.md` § "Verification scale".
2. Briefs `<subject>/corrections-brief-3.md` written; three agents in parallel. terms gen 3 DONE; what-jev-is gen 3 DONE_WITH_CONCERNS (N2 refusal, R40); integration-paths gen 3 hit WARN after re-derivation with no edits (plan left in its `corrections.md`) → closed ROLLOVER_NEEDED, gen 4 launched with the plan, DONE. All verified on disk (markers, third-round sections, provenance untouched), dispatches closed. R39/R40/R41 rule on round-3 findings; the tally 21→22 one-word fix applied by the orchestrator. `rulings.md` § "Phase 4 closed".
3. Synthesis: §3 and §4 (patterns 8–10) filled; `research/synthesis.md` written from the draft (draft file still present — delete it at the close, the `git mv` was not done). §1 NOT yet re-checked against the gen-3 changes (C50 caveat + cookbook-per-figure, IP S2 wording, price-FAQ answer, profile "early access").
4. Not done: README status line, `work/README.md` row L23, delete `synthesis-draft.md`. WARN at 143K right after Phase 4 closed; rolled hands-off.

Learnings:
- A corrections agent with nine rulings and five re-fetches reaches WARN before editing (IP gen 3, ~107K); it wrote its edit plan to the report and gen 4 applied it in one pass — the rollover contract worked as designed. Split a brief with more than ~6 rulings that each need a fetch, or tell the agent to edit as it goes.
- The orchestrator's own budget: ~60K on orientation reads + brief writing before launch. The briefs could be shorter — the sweep rows already carry target text; point at the row ids instead of restating them.

# Session Handoff — 3 (2026-09-23): Phase 4 sweep dispatched and returned DONE (23 findings, no missing quote); rulings R24–R37 recorded; synthesis drafted (sweep section unfilled); rolled at WARN before the post-sweep corrections pass

1. Registered as session 3 (`seq=3`, launched hands-off by session 2). Read the launcher, the session-2 ledger block, `rulings.md`, `sweep-brief.md`, the dispatch records (all nine gen-1/gen-2 records closed, none stranded).
2. Phase 4 sweep: `dispatch-open sweep` gen 1 on `research/sweep-brief.md`; one `general-purpose` agent launched with the brief + the printed contract + tool guidance (public fetches only, write only `sweep.md`, R17 cookbook L500–600 re-read and R20 mirror check mandatory). Outcome: DONE — `sweep.md` 212 lines, 23 findings (sweep 1 = 7, 2 = 4, 3 = 4, 4 = 8), 29 sources re-fetched today all 200, no appendix quote not-found. R17 settled for gen 2's reading (SW3-1, cookbook L512–519/537–551/557–558/590–591 quoted). Dispatch closed DONE.
3. While the sweep ran: read `schema.md`, the three `profile.md` files, `seam-inventory.md`; re-verified on disk the seam pointers the synthesis cites (`skills/rlm/SKILL.md:144-171`, `rlm_repl.py:82,112,193`, `research-wave/references/fact-check-brief.md:69-88`, `triage/SKILL.md:38-59`, `doc-review/SKILL.md:122-136`, `checkpoint/SKILL.md:38-60`, `decision-log/SKILL.md:35-55`, ADR-0011 L17–30, `docs/service-access.md:10-27`, `mcp-fragments/README.md:10-20`); grepped the three `record.md` claim tables for the load-bearing claim ids. Wrote `research/synthesis-draft.md` (209 lines): §1 corrected facts with claim ids, §2 S1–S6 table, §3 sweep section EMPTY, §4 seven wave patterns from `rulings.md` (sweep confirmations to add), §5 provisional seam table with what each needs from the API, §6 the decision question verbatim from `README.md` → Success criteria.
4. Rulings on the sweep made from its summary + quoted lines: R24–R37 in `rulings.md` § "Phase 4 — sweep rulings" (R24 settles R17 → R18 active; R25 S2/Noul one wording; R26 settles R20; R29 adopt the sweep's scale and re-score all three subjects in one round; R30 three `|`-in-code-span rows; R31 terms scorecard; R35 closes R11/R16). Session 4 verifies each against its `sweep.md` row before writing the briefs. Not done this session: the gen-3 corrections pass (`corrections-brief-3.md` per affected subject carrying the sweep rulings + queued R18/R20/R21/R22); filling synthesis §3/§4 and renaming it `synthesis.md`; the README status flip; the `work/README.md` row. No fit decision (research before design still binds).
5. Context: WARN at ~120K right after the synthesis draft landed (the budget hook fired on the `record --label` call); waited for the sweep child, closed its dispatch, rolled hands-off with position only. main not pushed.

Learnings:
- The sweep is the longest single child of the wave (four sweeps × three subjects + live re-fetches); dispatch it as the FIRST action of a fresh session, before any orientation reading beyond the launcher, or the orchestrator reaches WARN while waiting. Session 3 spent ~60K tokens on orientation + synthesis prep before the sweep returned.
- Drafting the synthesis while the sweep runs works — every section except "what the sweep found" is derivable from the profiles, `rulings.md` and the seam inventory — but the claim-id grep over three `record.md` tables is the expensive step (~12K tokens); a successor should not redo it: the ids are in the draft.
- A seam-inventory fact to correct in future reads: the `rlm` seam CAN batch — one array `state` + one question per record referencing `` `records[i]` `` (what-jev-is C28) — so "one call per record" is not forced.

Suggested skills for session 4: `research-wave` (rule on the sweep, the corrections pass, "Handing the wave off"), `session-rollover` with `--loop-mode interactive` once `synthesis.md` is final — the fit decision needs the human.

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

