# Catchup prompt — sdlc-ai-mapping (paste into a new agent session)

We're resuming sdlc-ai-mapping. Works in any runtime (Claude Code, Codex,
Gemini, OpenCode) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in
> `handoff.md` (the append-only ledger). Convention:
> docs/work-directory-conventions.md.

## Mission

Run further review rounds on `sdlc-map.md`, at the user's direction. The
seven-persona review fix pass (P1–P3) is fully applied and **merged to main
via PR #4** (2026-08-13); the map is stable. The user explicitly kept this
item open because they want more reviews — but did not yet specify which
kind (different personas? deeper single-lens? external-source validation?).
**First substantive step is asking the user what review they want.**

## First actions

1. `scripts/context-budget.sh register --project sdlc-ai-mapping`
2. Work in a worktree based on current main (which now contains the full
   fix pass). Branch `worktree-sdlc-ai-mapping-s2` is merged — start fresh
   rather than reusing it.
3. Ask the user which reviews to run, then follow the review-method
   precedent in `decisions.md` (2026-08-13 note) for roster/synthesis shape.

## Constraints already decided (do not re-litigate)

- All session-1/2 structural constraints stand (N5/N8 nodehood, per-node
  overlay, two views, tier rubric, gap dispositions incl. G7 out of scope).
- The P1–P3 fix list from `review-findings.md` is fully applied — don't
  re-audit it unless the user asks; new reviews start from the current map.
- Closure is deferred by user choice, not blocked by unmet criteria (all
  README success criteria verified met in session 3).

## Read these, in order

1. `work/sdlc-ai-mapping/handoff.md` (top block) — where things stand.
2. `sdlc-map.md` — only once the review scope is known; targeted reads
   (~570 lines now; artifacts table is a trailing appendix).

## Do NOT reload

- `review-findings.md` — fully applied; audit-only reference.
- `research-modern-qa.md` — consult only to verify a specific tier claim.
- Raw persona reports from round 1, backlog HTML.

## State snapshot

- Main contains the fixed map (PR #4 merged 2026-08-13). Branch
  `worktree-sdlc-ai-mapping-s2` merged; safe to delete with its worktree.
- No uncommitted work, no running processes, no external tickets.
- Follow-on gap work lives in `work/feedback-intake/`, `work/quality-gates/`,
  backlog cards M27–M29 + L38 — separate efforts, not this item.
- `work/kimi-k3-agent-integration/` is another effort's untracked dir — leave it.
