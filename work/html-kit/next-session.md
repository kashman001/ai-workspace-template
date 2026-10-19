# Catchup prompt — html-kit (paste into a new agent session)

We're resuming html-kit. Works in any runtime (Claude Code, Codex, Gemini,
OpenCode) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover. Past-tense provenance lives in `handoff.md`.
> Convention: docs/work-directory-conventions.md.

<!-- plan:begin position -->
Position: plan 01-kit-gap-fixes, closed, wave 2 of 2, done 8/8, doing 0, todo 0, blocked 0, dropped 0, sessions 1.
Frontier: none. Remaining: 0 of 8.
<!-- plan:end position -->

## Mission

Get the user's final verdict on the HTML kit and act on it. The gap-fix plan is
done; numbers and per-diagram verdicts are in `prototype/RESULTS.md` →
"Session 5".

## First actions

1. `scripts/context-budget.sh register --project html-kit`
2. If the user has not answered yet, ask one question, plain terms:
   **adopt** or **drop**? If adopt, a second question: where does it land —
   `docs/kit/` (CSS/JS + AUTHORING.md + render-check.sh) or a workspace skill?
3. On **adopt**: record the verdict (`decision-log` skill, Tier 2, and promote
   the "SVG allowed but themed" + "render check" notes if asked), then plan the
   move with `to-tickets` or `plans`. Open items to carry: cap SVG width on
   desktop (labels come out large at 1280), and the three rule gaps in
   RESULTS.md "Findings".
   On **drop**: record the verdict and close the work item (`checkpoint`).

**No human present:** stop with the question open; do not pick for the user.

## Read these first, in order

1. `work/html-kit/decisions.md`
2. `work/html-kit/prototype/RESULTS.md` — "Session 5" only

## Constraints already decided (do not re-litigate)

- HTML stays the source of truth for human-facing pages; Markdown-plus-renderer
  only for long prose docs.
- Agent-agnostic: plain CSS/JS files plus a doc, no runtime-specific skill.
- Diagrams accepted only after the render check, viewed by eye.
- Throwaway until a verdict: everything stays in `work/html-kit/prototype/`.

## State snapshot

- Branch `main`, ahead of origin (push is the user's call). Stage only
  `work/html-kit/` paths when committing; other sessions share this checkout.
