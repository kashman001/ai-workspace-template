---
plan: 01-gated-integration
status: open
replan: structural
default_tier: standard
---

# Plan 01 — Gated Jev integration: fit note → approval → spec + tickets → (replanned) implementation

## Goal

Take `jev-integration` from "research closed, fit decision open" to a shipped,
gated integration. Direction from the user (2026-09-25, answering the `plans`
item's ticket 11): integrate — but Jev is active **only where a person has Jev
access** (a key in the OS keychain as `jev-api-key`); without one every seam
behaves exactly as today — session 6's grill question Q4, answered (a); its
Q1, Q2 and Q5 are proposed by node 01 and confirmed in node 03. Proposed seam: the `rlm` leaf classifier first
(`research/synthesis.md` §5's strongest fit; `research/spike.md` measured
0.64s vs 4.83s on five records). Wave 1 drafts the Tier-2 fit note, wave 2 a
person approves or amends it, wave 3 writes the spec and tickets; the wave-3
reconcile node replans structurally, adding the implementation waves from
those tickets (`skills/plans/SKILL.md` → "Create a plan", steps 2–4). This
plan is also the `plans` item's dogfood (`work/plans/issues/11-dogfood.md`):
what breaks, what is slow, and the L48 question go to
`work/plans/decisions.md` as they appear.

## Not yet specified
- s7 · wave 1: the fit note proposes a confidence threshold with per-record fallback to the current path; the threshold value and the per-OS keychain read are left to node 05's spec, not the note
- s7 · user question (s7, 2026-09-27): TypeSafe ships a Claude Code plugin — research integration-paths 1.7/3.7 (2026-09-23) records it as one SKILL.md with no code (claude plugin marketplace add typesafe-ai/skills; npx skills add typesafe-ai/skills for Codex and others), and coding-agents docs say Jev is not a drop-in for the agent's LLM. For node 03/05: the plugin is agent knowledge, not the integration; the seam stays a CLI-first script every runtime can call; the SKILL.md can be vendored with provenance. Re-check the marketplace for anything newer than 2026-09-23 in node 05.
- s7 · wave 2 (s7): the user approved the fit note in chat; tier routing for subagent dispatch, a relevance filter, and a jev CLI + one always-on context rule + a demand-loaded skill were discussed as slices — node 05 scopes the CLI/rule/skill into the rlm slice's spec and lists tier routing and the relevance filter as later plans
- s8 · s8 · TypeSafe skills repo re-checked 2026-09-27: last push 2026-09-12 (65a39f3, v0.5.7); nothing newer than the 2026-09-23 research — ticket 04 vendors that commit
- s9 · s9: a post-green sanity run of jev.sh with no JEV_ENDPOINT override and the real keychain on PATH made one live request with the user's key (typed answer returned, exit 0; the key was not printed). Not a UAT claim (S20 is the user's); guard: run ad-hoc checks with JEV_ENDPOINT set or PATH stripped.
- s11 · s11 · 12-reconcile-w5: node 11 check used a relative script path; checks run from the item dir — fixed with $WORKSPACE_ROOT; finding in work/plans/decisions.md
- s12 · UAT 13 (session 12, user): ran --check, --help, check-service-access on the keyed machine; --help judged not user-friendly — sent to a CLI text-UX reviewer; verdict pending, fix to be a new wave-6 work node. rlm keyed/keyless legs not yet run.
- s12 · UAT 13 keyless leg (session 12, user): --check exit 3 + one stderr line PASS; check-service-access shows '– jev key absent (optional)' PASS; rlm run not reached: skills/rlm/SKILL.md says 'python' (5 places) but this Mac has only python3 (shebang is python3) — docs finding, pre-existing in the rlm skill, inherited by the classify recipe. Also the UAT recipe given in chat omitted the 'init <context>' step (session error, not a product finding).
- s13 · s13: lint fix — node 17-13b-uat-fixes → 13b-uat-fixes per plans skill Replan rule 1 (mv file + set id: + add to reconcile 14 blocked_by); the node's own ordering note said 'do not hand-edit ids' but docs/plans.md and the skill prescribe exactly that rename for a follow-up in a wave that already has its reconcile; no plan.sh verb renames a node
- s13 · s13 · UAT 13 recipe finding (not a product bug): a fake 'security' that fails every call also logs the claude CLI out (Claude Code reads its OAuth token via the same keychain command), so the leaf returns 'Not logged in' and classify() yields label None for every record in ~1s. The keyless leg needs a pass-through stub that fails only the jev-api-key lookup (/tmp/nokey/security now does: case "$*" in *jev-api-key*) exit 44; else exec /usr/bin/security). The user's keyed run reached the leaf fallback (some Jev answers below threshold 0.9) and was interrupted as 'stuck' — leaf batches of 50 via claude -p haiku take tens of seconds; timing measured this session.

## Out of scope

- Seams other than `rlm` in the first implementation (research-wave verdicts,
  triage, doc-review, decision-log, checkpoint routing) — a later plan.
- Anything ADR-0011 rules out: session-loop verdicts, budget gates, ledger checks.
- Pushing `main`; changing `plan.sh`, `session-loop.sh`, or the plans skill
  from this item (a dogfood bug is a note in `work/plans/decisions.md` first,
  a fix under the plans item second).

## Replans

- s8 · 06-reconcile-w3 (structural): added wave 4 — 07-gate-cli-test ← ticket 01; 08-reconcile-w4
- s8 · 06-reconcile-w3 (structural): added wave 5 — 09-rlm-classify ← ticket 02; 10-credentials-docs ← ticket 03 (tier cheap); 11-cli-skill-rule ← ticket 04; 12-reconcile-w5
- s8 · 06-reconcile-w3 (structural): added wave 6 — 13-uat-gated (hitl) ← ticket 05; 14-reconcile-w6
- s8 · 06-reconcile-w3 (structural): added wave 7 — 15-tune-and-pin ← ticket 06; 16-reconcile-w7
- s8 · waves = 3 + (1 + longest blocker chain) per ticket; checks name `scripts/tests/test-jev.sh` (ticket 01 builds it); no model name in any node (tiers only)
- s13 · 14-reconcile-w6 (local, applied by the session before the join): 17-13b-uat-fixes renamed to 13b-uat-fixes (number of the node it follows + suffix) and added to 14-reconcile-w6 blocked_by — `add` had numbered it after the join, tripping `reconcile-last`. Local replan.
- s14 · 14-reconcile-w6 (structural): added 15a-authorize-live-runs (hitl, wave 7) in front of 15-tune-and-pin — node 15's acceptance needs two paid live Jev calls only the user may trigger, but it was a `work` node, so a hands-off chain would have dispatched it (or a subagent would have spent). `add` numbered it 17, after the join → renamed to 15a (Replan rule 1); 15 now `blocked_by: [13-uat-gated, 15a-authorize-live-runs]`. Structural replan.

<!-- plan:begin board -->
| Wave | Node | Kind | Tier | Status |
|---|---|---|---|---|
| 1 | 01-decision-note | work | auto | done |
| 1 | 02-reconcile-w1 | reconcile | frontier | done |
| 2 | 03-approve-decision | hitl | frontier | done |
| 2 | 04-reconcile-w2 | reconcile | frontier | done |
| 3 | 05-spec-and-tickets | work | auto | done |
| 3 | 06-reconcile-w3 | reconcile | frontier | done |
| 4 | 07-gate-cli-test | work | standard | done |
| 4 | 08-reconcile-w4 | reconcile | frontier | done |
| 5 | 09-rlm-classify | work | standard | done |
| 5 | 10-credentials-docs | work | cheap | done |
| 5 | 11-cli-skill-rule | work | standard | done |
| 5 | 12-reconcile-w5 | reconcile | frontier | done |
| 6 | 13-uat-gated | hitl | frontier | done |
| 6 | 13b-uat-fixes | work | standard | done |
| 6 | 14-reconcile-w6 | reconcile | frontier | done |
| 7 | 15-tune-and-pin | work | standard | todo |
| 7 | 15a-authorize-live-runs | hitl | frontier | todo |
| 7 | 16-reconcile-w7 | reconcile | frontier | todo |
Frontier: 15a-authorize-live-runs. Remaining: 3 of 18. Sessions used: 7.
<!-- plan:end board -->
