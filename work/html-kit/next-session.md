# Catchup prompt — html-kit (paste into a new agent session)

We're resuming html-kit. Works in any runtime (Claude Code, Codex, Gemini,
OpenCode) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover. Past-tense provenance lives in `handoff.md`.
> Convention: docs/work-directory-conventions.md.

## >>> START HERE — ask the user this, verbatim <<<

> The kit experiment is done (details: `work/html-kit/prototype/RESULTS.md`,
> screenshots in `prototype/shots/`). The rebuilt deck is 63% smaller
> (13.6 KB vs 36.7 KB). Text slides look almost the same, dark mode comes free,
> and a fresh agent wrote valid pages from the rule alone. The cost is diagrams:
> Mermaid can't keep the ring layout, and the eight-stage backup graph comes out
> small and tangled. Which way?
>
> 1. **Adopt** — move the kit and the rule into the template now, fix the small
>    gaps in the rule, and accept Mermaid for diagrams (a page that truly needs a
>    spatial diagram may keep one hand-drawn SVG as an exception).
> 2. **Adjust, then re-measure** *(recommended)* — add an allowed escape hatch
>    for one hand-drawn diagram per figure, a coloured "rows" component for
>    ladders like the evidence tiers, fix the rule gaps, then re-run on a second
>    page (e.g. `docs/setup-guide.html`) before deciding.
> 3. **Drop** — keep writing freeform HTML; the size saving isn't worth the
>    diagram loss.

Ask one question at a time; spell out options in plain terms.

## First actions

1. `scripts/context-budget.sh register --project html-kit`
2. Pose the question above. **No human present:** do nothing else — the
   material is committed; stop with the question open.
3. On an answer: record it with the `decision-log` skill
   (`work/html-kit/decisions.md`), then
   - Adopt → ask where it lands (`docs/kit/`? a skill?) before moving files;
     fix the gaps listed in RESULTS.md "Fresh-agent test".
   - Adjust → do the listed changes in `prototype/`, rebuild, re-measure, update
     RESULTS.md, ask again.
   - Drop → note it in README.md and close the item (`work/README.md` row).

## Constraints already decided (do not re-litigate)

- HTML stays the source of truth for human-facing pages; the
  Markdown-plus-renderer route is kept only for long prose docs.
- Agent-agnostic: plain CSS/JS files plus a doc, no runtime-specific skill.
- Throwaway until a verdict: everything stays in `work/html-kit/prototype/`.
- Sizes in bytes; token figures are estimates (bytes / 4), labelled as such.

## Do NOT reload

- The original deck source (`work/sdlc-ai-mapping/slides/…`) — measured; numbers
  are in RESULTS.md.
- `kit/kit.css` / `kit/kit.js` — only open them if the verdict needs a change.

## State snapshot

- Branch `main`; session 3's work committed. Uncommitted `work/README.md` and
  `work/clear-session-loop/` belong to another item — leave them.
- Headless-Chrome screenshot flags: see `handoff.md` top block, Learnings.

## Read these first, in order

1. `work/html-kit/prototype/RESULTS.md`
2. `work/html-kit/handoff.md` (top block)
