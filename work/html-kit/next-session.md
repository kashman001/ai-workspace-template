# Catchup prompt — html-kit (paste into a new agent session)

We're resuming html-kit. Works in any runtime (Claude Code, Codex, Gemini,
OpenCode) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover. Past-tense provenance lives in `handoff.md`.
> Convention: docs/work-directory-conventions.md.

<!-- plan:begin position -->
Position: plan 02-desktop-cap-and-gaps, open, wave 1 of 1, done 3/3, doing 0, todo 0, blocked 0, dropped 0, sessions 1.
Frontier: none. Remaining: 0 of 3.
<!-- plan:end position -->

## Mission

Get the verdict on the HTML kit from the user. All fix rounds are done
(sessions 4–6); results in `prototype/RESULTS.md` → "Session 6".

## First actions

1. `scripts/context-budget.sh register --project html-kit`
2. If the user has already answered in the session that wrote this, act on it.
   Otherwise ask, one question, plain terms: **adopt** the kit or **drop** it?
   If adopt: does it land in `docs/kit/` (plain files) or as a workspace skill?
3. On adopt: record the decision (`decision-log`), then plan the move
   (`plans` skill): kit files, AUTHORING.md, render-check.sh, the two
   "Promote?: maybe" notes in `decisions.md` become ADR candidates.
   On drop: record why, close the item.

**No human present:** stop with step 2's question open.

## Read these first, in order

1. `work/html-kit/decisions.md`
2. `work/html-kit/prototype/RESULTS.md` — "Session 6" only

## Constraints already decided (do not re-litigate)

- HTML stays the source of truth for human-facing pages; Markdown-plus-renderer
  only for long prose docs.
- Agent-agnostic: plain CSS/JS files plus a doc, no runtime-specific skill.
- Diagrams accepted only after the render check, viewed by eye.
- Throwaway until a verdict: everything stays in `work/html-kit/prototype/`.

## State snapshot

- Branch `main`, ahead of origin (push is the user's call). Stage only
  `work/html-kit/` paths when committing; other sessions share this checkout.
