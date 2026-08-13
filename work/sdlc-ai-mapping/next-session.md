# Catchup prompt — sdlc-ai-mapping (paste into a new agent session)

We're resuming sdlc-ai-mapping. Works in any runtime (Claude Code, Codex,
Gemini, OpenCode) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in
> `handoff.md` (the append-only ledger). Convention:
> docs/work-directory-conventions.md.

## Mission

Apply (or triage) the round-2 review findings in `review2-findings.md`
against `sdlc-map.md` — **if the user has approved a fix pass**; the round-2
review was diagnosis-only by rule, and the user had not yet directed fixes
when session 4 closed. If no direction exists yet, ask whether to run the
fix pass (Blocker + Majors first is the natural cut).

## First actions

1. `scripts/context-budget.sh register --project sdlc-ai-mapping`
2. Check whether PR from branch `worktree-sdlc-ai-mapping-s4-review`
   (round-2 findings + decision notes) is merged; if not, that's the base
   to build on.
3. Confirm fix-pass scope with the user, then work in a worktree.

## Constraints already decided (do not re-litigate)

- All session-1/2 structural constraints stand (N5/N8 nodehood, per-node
  overlay, two views, tier rubric, gap dispositions incl. G7 out of scope).
- **NEW (2026-08-13): the map must be consumable independent of the
  workspace** — see the decision note in `decisions.md`. This governs all
  future edits and review fences.
- Round-2 synthesis recommends NO document split — self-identification
  preamble + glosses instead (rationale in `review2-findings.md` §5).
- P1–P3 (round 1) fixes are applied and merged; don't re-audit.

## Read these, in order

1. `handoff.md` (top block) — where things stand.
2. `review2-findings.md` — the fix list, if running the fix pass
   (prioritized §3; restructure outline §5; do-not-break list §6).
3. `sdlc-map.md` — targeted reads per finding being fixed.

## Do NOT reload

- `review-findings.md` (round 1) — fully applied; audit-only reference.
- `research-modern-qa.md` — consult only to verify a specific tier claim.
- `doc-review-orchestrator.md` — the round-2 method, now committed; only
  needed to re-run the method.
- Raw round-2 per-agent reports (session-4 transcript) — the synthesis is
  the durable record.

## State snapshot

- Round-2 review complete (10-agent doc-review-orchestrator run), synthesis
  committed at `review2-findings.md`; **no fixes applied** — awaiting user
  direction.
- Branch `worktree-sdlc-ai-mapping-s4-review` carries: review2-findings.md,
  doc-review-orchestrator.md (now tracked), 2 decision notes, ledger block,
  this launcher.
- Main still holds the map exactly as merged by PR #4 (stable, pre-round-2).
- Follow-on gap work lives in `work/feedback-intake/`, `work/quality-gates/`,
  backlog cards M27–M29 + L38 — separate efforts, not this item. Note:
  round-2 finding F10 (N8 "backlog conventions (native)" claims an unshipped
  capability) may spawn a new backlog card during the fix pass.
- `work/kimi-k3-agent-integration/` is another effort's untracked dir — leave it.
