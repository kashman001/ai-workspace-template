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

Fix the open items session 5 found, then put the verdict question to the user
again. The user said: **roll over, make the fixes, then get back to the
question.** Items (from `prototype/RESULTS.md` → "Session 5" → Findings):

1. **SVG too large on desktop** — a diagram sized for phones (viewBox 520–600)
   renders labels ~25px at 1280. Kit fix: cap `svg.diagram` width on wide
   screens so its text lands near body size (e.g. max-width ≈ viewBox width ×
   ~1.1px, or a fixed cap), keeping it full-width on phones.
2. **Three rule gaps** in AUTHORING.md (+ kit CSS if needed): a captioned card
   grid inside a `<figure>`; a callout box with a heading and a list; a list of
   links (the setup guide used `.note`).
3. Optional, if cheap: deck backup eight-stage graph is unreadable at 390 —
   a slide-format limit; only act if a simple caption or kit change helps.

## First actions

1. `scripts/context-budget.sh register --project html-kit`
2. Small plan (`plans` skill, `/plan`): wave 1 — one kit owner (kit.css/kit.js +
   AUTHORING.md for items 1–2; one owner avoids edit clashes); wave 2 — re-run
   `prototype/render-check.sh` on `prototype/setup-guide.html` and
   `prototype/where-ai-actually-helps.html` and update the two pages for the
   new classes; reconcile: the main session views every shot itself (contact
   sheets save context: an HTML page of `<img>`s shot by headless Chrome) and
   adds a "Session 6" section to RESULTS.md (bytes, tokens = bytes/4 estimate).
3. Then ask the user, one question, plain terms: **adopt** the kit or **drop**
   it? If adopt: does it land in `docs/kit/` (plain files) or as a workspace
   skill?

**No human present:** do steps 1–2, commit, stop with step 3's question open.

## Read these first, in order

1. `work/html-kit/decisions.md`
2. `work/html-kit/prototype/RESULTS.md` — "Session 5" only
3. `work/html-kit/prototype/AUTHORING.md`

## Constraints already decided (do not re-litigate)

- HTML stays the source of truth for human-facing pages; Markdown-plus-renderer
  only for long prose docs.
- Agent-agnostic: plain CSS/JS files plus a doc, no runtime-specific skill.
- Diagrams accepted only after the render check, viewed by eye.
- Throwaway until a verdict: everything stays in `work/html-kit/prototype/`.

## State snapshot

- Branch `main`, ahead of origin (push is the user's call). Stage only
  `work/html-kit/` paths when committing; other sessions share this checkout.
