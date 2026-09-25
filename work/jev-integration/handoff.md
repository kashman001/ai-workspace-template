<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 6 (2026-09-24/25): fit question posed; user supplied a Jev key mid-session; live spike run and recorded (research/spike.md); fit decision NOT made — user exited; closed through the checkpoint door

1. Registered `seq=6` (interactive session, staged by session 5). Re-posed the fit question verbatim and opened `grill-with-docs` with a four-question first round (axis of "serves better", candidate scope, terms risk appetite, then Q3 on deciding without live evidence).
2. The user opened a Jev account and stored the key in the keychain as `jev-api-key`, which settled Q3 by action. The orchestrator ran four probes (`research/spike.py`): key authenticates (O29 closed); rlm-shaped batch of 5 records with `other` → same 5 labels as `claude -p haiku`, each with `confidence`, 0.64s vs 4.83s; 256 options → 400 "at most 255 choices" (O21 cap enforced); `instructions` omitted → 200 (server follows the OpenAPI spec, resolving 5.12-spec-spread at runtime). Written to `research/spike.md`; raw records untouched. Tier-2 note for the R0.4 lift in `decisions.md` (created this session; the fit decision is NOT in it).
3. Round 1 re-issued with Q3 closed and a new Q5 (scope of the R0.4 lift). The user asked to checkpoint and exit without answering. Per the launcher's rule 3, nothing was decided on their behalf; the four open questions and the orchestrator's recommendations are carried in `next-session.md`.
4. Close: README status line; `work/README.md` row; `record --label "checkpoint: fit still open"`; committed (not pushed).

Suggested skills for session 7: `grill-with-docs` (resume at the four open questions — the frontier is unchanged), `decision-log` / `/decision` for the fit note, then `to-spec` only if "integrate"; `checkpoint` again if the human defers.

Learnings:
- A user can settle a grill question by *action* (supplying a key) rather than by answer; treat that as the answer, close the facts yourself, and re-issue the round with the frontier recomputed rather than waiting on the original wording.
- The spike was ~6K tokens of orchestrator budget end to end (record greps + 4 probes + baseline); cheaper than a dispatched agent for anything under ten probes.

# Session Handoff — 6→7 bridge (2026-09-25): written by the `plans` item's session 15 under its ticket 11 — the user chose this item for the first real plan and set the direction (integrate, gated on Jev access); plan `01-gated-integration` opened; session 6's four open grill questions folded into nodes 01 and 03

1. Session 6 closed through the checkpoint door at 22:23Z (commit 524bb2a; supervisor verdict `quit_plain`, chain closed). Its launcher carried the four open round-1 grill questions (Q1 axis, Q2 scope, Q4 terms risk, Q5 lift scope) with recommendations; `decisions.md` holds the R0.4-lift note and "fit decision STILL OPEN".
2. In the `plans` session, answering ticket 11's "which item?", the user chose this one and added: integrate Jev **only where a person has Jev access**. That answers Q4 as (a) — optional path, current runtime as the default and fallback. Q1, Q2, Q5 stay open: node 01 drafts the fit note taking the recommendations as proposals, node 03 (`hitl`) is where the person confirms or amends them. Direction recorded in `plans/01-gated-integration/plan.md` → Goal.
3. Plan opened with `scripts/plan.sh new gated-integration`: six nodes in three waves (01 decision-note → 02 join; 03 approve-decision [hitl] → 04 join; 05 spec-and-tickets → 06 join + structural replan adding the implementation waves from the tickets). `check` silent; launcher rewritten with the Position block; `sync` run; README status line and `work/README.md` row updated.
4. Noticed while doing it: session 6's commit landed ten minutes after the plans session started, so a first pass here was written against a stale snapshot (spike thought untracked, `decisions.md` thought absent, the grill questions dropped) and redone against 524bb2a. Recorded as a dogfood finding in `work/plans/decisions.md`.

Learnings:
- Two sessions on one checkout: re-read `git log -1` and the target files immediately before rewriting another item's launcher, not at session start — a concurrent interactive session can commit in between.

# Session Handoff — 6 (2026-09-24/25): fit question posed; user supplied a Jev key mid-session; live spike run and recorded (research/spike.md); fit decision NOT made — user exited; closed through the checkpoint door

1. Registered `seq=6` (interactive session, staged by session 5). Re-posed the fit question verbatim and opened `grill-with-docs` with a four-question first round (axis of "serves better", candidate scope, terms risk appetite, then Q3 on deciding without live evidence).
2. The user opened a Jev account and stored the key in the keychain as `jev-api-key`, which settled Q3 by action. The orchestrator ran four probes (`research/spike.py`): key authenticates (O29 closed); rlm-shaped batch of 5 records with `other` → same 5 labels as `claude -p haiku`, each with `confidence`, 0.64s vs 4.83s; 256 options → 400 "at most 255 choices" (O21 cap enforced); `instructions` omitted → 200 (server follows the OpenAPI spec, resolving 5.12-spec-spread at runtime). Written to `research/spike.md`; raw records untouched. Tier-2 note for the R0.4 lift in `decisions.md` (created this session; the fit decision is NOT in it).
3. Round 1 re-issued with Q3 closed and a new Q5 (scope of the R0.4 lift). The user asked to checkpoint and exit without answering. Per the launcher's rule 3, nothing was decided on their behalf; the four open questions and the orchestrator's recommendations are carried in `next-session.md`.
4. Close: README status line; `work/README.md` row; `record --label "checkpoint: fit still open"`; committed (not pushed).

Suggested skills for session 7: `grill-with-docs` (resume at the four open questions — the frontier is unchanged), `decision-log` / `/decision` for the fit note, then `to-spec` only if "integrate"; `checkpoint` again if the human defers.

Learnings:
- A user can settle a grill question by *action* (supplying a key) rather than by answer; treat that as the answer, close the facts yourself, and re-issue the round with the frontier recomputed rather than waiting on the original wording.
- The spike was ~6K tokens of orchestrator budget end to end (record greps + 4 probes + baseline); cheaper than a dispatched agent for anything under ten probes.

# Session Handoff — 6→7 bridge (2026-09-25): written by the `plans` item's session 15 under its ticket 11 — session 6 ran a live spike but never closed; the user chose this item for the first real plan; plan `01-gated-integration` opened

1. Session 6 (2026-09-23, staged `interactive`; claude pid 42999) is still an open process on 2026-09-25 — it wrote `research/spike.{md,py}` on 2026-09-24 (four live probes with the user's new key: O29 closed, O21 partly, 0.64s vs 4.83s on five records) but no ledger block and no commit. This block records that on its behalf; the files are committed here as provenance, unedited.
2. The user's direction, given in the plans session in answer to ticket 11's question: dogfood on this item, and integrate Jev **only where a person has Jev access**. Recorded in `plans/01-gated-integration/plan.md` → Goal; the Tier-2 note itself is node 01's work, approved by a person in node 03.
3. Plan opened with `scripts/plan.sh new gated-integration`: six nodes in three waves (01 decision-note → 02 join; 03 approve-decision [hitl] → 04 join; 05 spec-and-tickets → 06 join + structural replan). `check` silent; launcher rewritten with the Position block; `sync` run.
4. Supervisor state found: two `session-loop.sh jev-integration` processes (pids 99717 from 2026-09-23 10:04 local, 42998 from 13:05) paging `staged_alive seq=6` every 15 min since 2026-09-23 18:20Z, while `session-state.json` says `staged: null`. Left running — closing the user's terminal processes is their call. Recorded as a dogfood finding in `work/plans/decisions.md`.

Learnings:
- An `interactive` staging that a person never returns to holds the chain open indefinitely; the supervisor has no idle policy for it, and its page text claims a staging the record does not hold.

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
