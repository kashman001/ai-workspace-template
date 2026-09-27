<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 7 (2026-09-27): wave 1 of plan 01-gated-integration done hands-off — fit note drafted as a proposal (decisions.md), reconcile 02 joined; frontier is 03 (hitl); the user then approved node 03 in chat; wave 2 joined; frontier 05-spec-and-tickets; rolled over hands-off at WARN

1. Registered `seq=7` (hands-off, launched by the supervisor after the chain was reopened bound to the plan; chain used 7 of 15). Frontier `01-decision-note`.
2. Node 01: appended the Tier-2 fit note to `decisions.md` (heading `## 2026-09-27 — Fit decision: …`, five fields) and replaced "STILL OPEN" with a pointer. Chose: `rlm` leaf seam, gated on `jev-api-key` in the keychain; batch-as-state, explicit `other`, confidence threshold with per-record fallback, alias `jev-latest`. Q4 = the user's (a); Q1 (c), Q2 narrow, Q5 (a) carried as proposals. Cites C28, integration-paths 5.1–5.7, 6.2, terms 1.1/1.7/2.1/5.9/7.3 and the spike rows; all 14 ids grep-verified. `verify` passed; `done`.
3. Node 02 (reconcile, this session): verified on disk, one `plan.sh note` (threshold value and per-OS keychain read are node 05's), no replan needed, `check` silent; `done`. Frontier now `03-approve-decision` (hitl).
4. Mid-session the user asked for a status summary (given in chat) and about TypeSafe's Claude Code plugin; answered from integration-paths 1.7/3.7 (one SKILL.md, no code; installable for Codex and others via `npx skills add`), recorded as a `plan.sh note` for nodes 03/05.
5. Dogfood: four findings appended to `work/plans/decisions.md` (harness baseline eats ~40% of the budget before work; `--project` as one word is rejected silently-ish; record step is a no-op when the node is itself a note; hitl launcher prose should be in the skill). No rollover split was needed.
6. Budget 102K at close (68%). Closed through the checkpoint door: the frontier is a `hitl` node — nothing this session may do. The supervisor stages the next session interactive; `research/` untouched; the key never read.
7. The session did not end at item 6: the user asked three follow-up questions (model routing for subagent dispatch, other uses, cost and how agents learn when to use Jev, what `rlm` is) — answered in chat from the research on disk; the design input worth keeping is in the launcher's "Design input for node 05".
8. The user then said "go ahead and build the suggested integration, use the plan concept we have built" — taken as node 03's approval: `done 03 --force --by kashif`, Log quotes the direction; `Promote?` set to `maybe` (the session's choice, flagged to the user). Node 04 (reconcile) run in-session: verified, one `plan.sh note`, no replan; `done`. Frontier `05-spec-and-tickets`.
9. WARN at 120K; ledger blocks 4, 5 and the 6→7 bridge archived; rolled over hands-off (supervised chain, `--emit`) so session 8 works node 05.

# Session Handoff — 6 (2026-09-24/25): fit question posed; user supplied a Jev key mid-session; live spike run and recorded (research/spike.md); fit decision NOT made — user exited; closed through the checkpoint door

1. Registered `seq=6` (interactive session, staged by session 5). Re-posed the fit question verbatim and opened `grill-with-docs` with a four-question first round (axis of "serves better", candidate scope, terms risk appetite, then Q3 on deciding without live evidence).
2. The user opened a Jev account and stored the key in the keychain as `jev-api-key`, which settled Q3 by action. The orchestrator ran four probes (`research/spike.py`): key authenticates (O29 closed); rlm-shaped batch of 5 records with `other` → same 5 labels as `claude -p haiku`, each with `confidence`, 0.64s vs 4.83s; 256 options → 400 "at most 255 choices" (O21 cap enforced); `instructions` omitted → 200 (server follows the OpenAPI spec, resolving 5.12-spec-spread at runtime). Written to `research/spike.md`; raw records untouched. Tier-2 note for the R0.4 lift in `decisions.md` (created this session; the fit decision is NOT in it).
3. Round 1 re-issued with Q3 closed and a new Q5 (scope of the R0.4 lift). The user asked to checkpoint and exit without answering. Per the launcher's rule 3, nothing was decided on their behalf; the four open questions and the orchestrator's recommendations are carried in `next-session.md`.
4. Close: README status line; `work/README.md` row; `record --label "checkpoint: fit still open"`; committed (not pushed).

Suggested skills for session 7: `grill-with-docs` (resume at the four open questions — the frontier is unchanged), `decision-log` / `/decision` for the fit note, then `to-spec` only if "integrate"; `checkpoint` again if the human defers.

Learnings:
- A user can settle a grill question by *action* (supplying a key) rather than by answer; treat that as the answer, close the facts yourself, and re-issue the round with the frontier recomputed rather than waiting on the original wording.
- The spike was ~6K tokens of orchestrator budget end to end (record greps + 4 probes + baseline); cheaper than a dispatched agent for anything under ten probes.

