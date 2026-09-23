<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

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
