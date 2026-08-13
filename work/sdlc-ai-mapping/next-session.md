# Catchup prompt — sdlc-ai-mapping (paste into a new agent session)

We're resuming sdlc-ai-mapping. Works in any runtime (Claude Code, Codex,
Gemini, OpenCode) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in
> `handoff.md` (the append-only ledger). Convention:
> docs/work-directory-conventions.md.

## Mission

The work item is **effectively done**: PR #7 (round-2 fix pass, F1–F11)
merged to main on 2026-08-13; all sdlc-ai-mapping worktrees and branches
cleaned up. One decision remains before formal close, and it's the user's:
**do the leftover round-2 Minors, or close them as won't-do.**

## First actions

1. `scripts/context-budget.sh register --project sdlc-ai-mapping`
2. Get the user's Minors decision (see the session-6 handoff block for the
   full leftover list — session-5 Minors plus two advisory Sourcery comments
   on PR #7: preamble routing-paragraph density, GAP cross-ref wording
   consistency).
   - **Won't-do** → close the item: final ledger block, launcher notes the
     item is closed, done. Consider `/checkpoint`.
   - **Do the Minors** → work `review2-findings.md` §3 "Minor (grouped)"
     (undone items listed in the session-5 handoff block) in a fresh
     worktree; small single-PR pass.

## Constraints already decided (do not re-litigate)

- **The map must be consumable independent of the workspace** — governs
  every edit (decision note, `decisions.md` 2026-08-13).
- No document split; F1–F11 are applied and merged — don't re-audit them.
- All session-1/2 structural constraints stand (N5/N8 nodehood, per-node
  overlay, two views, tier rubric, gap dispositions incl. G7 out of scope).
- Tag discipline: tier tags only on AI-capability items; caveats get plain
  parentheses.
- Gap **G9** → backlog card **L39** is a template-backlog item, not this
  work item's job to fix.

## Read these, in order

1. `handoff.md` (top two blocks) — session 6 close-out + session 5's list of
   undone Minors.
2. `review2-findings.md` §3 Minors — only if doing the minor pass.
3. `sdlc-map.md` — targeted reads only (~640 lines).

## Do NOT reload

- `review-findings.md` (round 1) and `review2-findings.md` §1–§2/§4–§6 —
  applied/settled; audit-only reference.
- `research-modern-qa.md` — consult only to verify a specific tier claim.
- `doc-review-orchestrator.md` — not needed.

## State snapshot

- **Main holds everything**: map fix pass (PR #7), diagnosis artifacts
  (PR #4, #6), backlog L39 + scorecard 6/66/4/0/6. No open PRs, no
  sdlc-ai-mapping branches or worktrees remain (local or origin).
- Follow-on gap work lives in `work/feedback-intake/`, `work/quality-gates/`,
  backlog cards M27–M29 + L38/L39 — separate efforts, not this item.
- `work/kimi-k3-agent-integration/` is another effort's untracked dir — leave it.
