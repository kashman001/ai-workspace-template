# Catchup prompt — sdlc-ai-mapping (paste into a new agent session)

We're resuming sdlc-ai-mapping. Works in any runtime (Claude Code, Codex,
Gemini, OpenCode) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in
> `handoff.md` (the append-only ledger). Convention:
> docs/work-directory-conventions.md.

## Mission

Execute the round-2 fix pass on `sdlc-map.md`: **Blocker + Majors first**
(F1–F11 in `review2-findings.md` §3) — user-approved 2026-08-13, don't
re-ask scope. Minors are in-scope afterwards only if budget allows; the
restructure outline (§5) sequences the edits, the do-not-break list (§6) is
the regression fence.

## First actions

1. `scripts/context-budget.sh register --project sdlc-ai-mapping`
2. Continue on branch `worktree-sdlc-ai-mapping-s4-review` (its worktree at
   `.claude/worktrees/sdlc-ai-mapping-s4-review` if it still exists,
   otherwise re-enter/recreate from the branch) — draft PR #6 is open and
   the fix pass lands on it. Do not branch off main; main lacks the
   session-4 artifacts.
3. Work the fix list from `review2-findings.md` §3 in order: F1 (Blocker),
   then F2–F11; commit per cluster like the round-1 pass. Mark PR #6 ready
   when done.

## Constraints already decided (do not re-litigate)

- **The map must be consumable independent of the workspace** (decision
  note, `decisions.md` 2026-08-13) — governs every edit.
- No document split — self-identification preamble + glosses instead
  (rationale: `review2-findings.md` §5).
- All session-1/2 structural constraints stand (N5/N8 nodehood, per-node
  overlay, two views, tier rubric, gap dispositions incl. G7 out of scope).
- Tag discipline for the pass: tier tags only on AI-capability items;
  caveats get plain parentheses (C's rule, adopted in synthesis §3 Minors).
- P1–P3 (round 1) fixes are applied and merged; don't re-audit.

## Read these, in order

1. `review2-findings.md` — §3 is the fix list; §5 the edit sequence; §6 the
   do-not-break fence.
2. `sdlc-map.md` — targeted reads per finding being fixed (~570 lines).
3. `handoff.md` (top block) — only if provenance questions come up.

## Do NOT reload

- `review-findings.md` (round 1) — fully applied; audit-only reference.
- `research-modern-qa.md` — consult only to verify a specific tier claim.
- `doc-review-orchestrator.md` — the round-2 method; not needed to fix.
- Raw round-2 per-agent reports (session-4 transcript) — the synthesis is
  the durable record.

## State snapshot

- Branch `worktree-sdlc-ai-mapping-s4-review` pushed; draft PR #6 open
  (diagnosis artifacts). Main holds the map as merged by PR #4
  (pre-round-2, stable). No uncommitted work, no running processes.
- F10's fix may spawn a backlog card (generic backlog convention) — if so,
  update `docs/template-workspace-backlog.html` per its maintenance rules.
- Follow-on gap work lives in `work/feedback-intake/`, `work/quality-gates/`,
  backlog cards M27–M29 + L38 — separate efforts, not this item.
- `work/kimi-k3-agent-integration/` is another effort's untracked dir — leave it.
