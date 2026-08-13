# Catchup prompt — sdlc-ai-mapping (paste into a new agent session)

We're resuming sdlc-ai-mapping. Works in any runtime (Claude Code, Codex,
Gemini, OpenCode) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in
> `handoff.md` (the append-only ledger). Convention:
> docs/work-directory-conventions.md.

## Mission

The round-2 fix pass is **complete**: F1–F11 (Blocker + all Majors) applied
in five commits; PR #6 is marked ready for review. Next session's job is
small: (a) get PR #6 merged (user review/merge, or address review
comments), and (b) decide whether the leftover round-2 **Minors** are worth
a short pass or should be closed as won't-do.

## First actions

1. `scripts/context-budget.sh register --project sdlc-ai-mapping`
2. Check PR #6 state (`gh pr view 6`). If merged: delete/clean the
   `sdlc-ai-mapping-s4-review` worktree+branch and consider the item
   closeable. If review comments exist: address them on the same branch.
3. If (and only if) the user wants the Minors: work
   `review2-findings.md` §3 "Minor (grouped)" — the undone ones are listed
   in the session-5 handoff block (top of `handoff.md`).

## Constraints already decided (do not re-litigate)

- **The map must be consumable independent of the workspace** — governs
  every edit (decision note, `decisions.md` 2026-08-13).
- No document split; F1–F11 are applied — don't re-audit them.
- All session-1/2 structural constraints stand (N5/N8 nodehood, per-node
  overlay, two views, tier rubric, gap dispositions incl. G7 out of scope).
- Tag discipline: tier tags only on AI-capability items; caveats get plain
  parentheses.
- New since session 5: gap **G9** (no generic backlog convention) is in the
  register → backlog card **L39** — a template-backlog item, not this
  work item's job to fix.

## Read these, in order

1. `handoff.md` (top block) — what session 5 shipped and which Minors remain.
2. `review2-findings.md` §3 Minors — only if doing the minor pass.
3. `sdlc-map.md` — targeted reads only (~640 lines now).

## Do NOT reload

- `review-findings.md` (round 1) and `review2-findings.md` §1–§2/§4–§6 —
  applied/settled; audit-only reference.
- `research-modern-qa.md` — consult only to verify a specific tier claim.
- `doc-review-orchestrator.md` — not needed.

## State snapshot

- Branch `worktree-sdlc-ai-mapping-s4-review` pushed; **PR #6 ready for
  review** (diagnosis artifacts + the full fix pass). Main still holds the
  pre-round-2 map (PR #4).
- Backlog `docs/template-workspace-backlog.html` updated on this branch
  (L39 filed, scorecard 6/66/4/0/6) — lands with the PR merge.
- Follow-on gap work lives in `work/feedback-intake/`, `work/quality-gates/`,
  backlog cards M27–M29 + L38/L39 — separate efforts, not this item.
- `work/kimi-k3-agent-integration/` is another effort's untracked dir — leave it.
