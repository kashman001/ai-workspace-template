# Catchup prompt — html-kit (paste into a new agent session)

We're resuming html-kit. Works in any runtime (Claude Code, Codex, Gemini,
OpenCode) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover. Past-tense provenance lives in `handoff.md`.
> Convention: docs/work-directory-conventions.md.

## Mission

Close the gaps the session-4 adjust round found, so the kit can get a final
adopt/drop verdict. The user asked for: **make a plan, run the work with
parallel subagents where possible, then come back to the question.** Hard
requirements (`decisions.md`): good diagrams for human readers, and every
diagram accepted only after it is seen rendered in HTML — desktop 1280 and
phone 390 wide, light and dark, labels readable, nothing clipped or
overlapping, sized in proportion to the page.

<!-- plan:begin position -->
Position: plan 01-kit-gap-fixes, open, wave 1 of 2, done 0/7, doing 0, todo 7, blocked 0, dropped 0, sessions 0.
Frontier: 01-kit-fixes, 02-render-check-script, 03-authoring-draft. Remaining: 7 of 7 — wave 1: 01-kit-fixes todo, 02-render-check-script todo, 03-authoring-draft todo, 04-reconcile-w1 todo.
<!-- plan:end position -->

## First actions

1. `scripts/context-budget.sh register --project html-kit`
2. Create the plan with the `plans` skill (`skills/plans/SKILL.md`; Claude Code
   `/plan`). Suggested shape — refine, don't re-litigate:
   - **Wave 1 (parallel):**
     (a) kit owner — code blocks (`<pre><code>`, wrap/scroll), Mermaid minimum
     readable size on doc pages, figure layout (table in `<figure>` clipped;
     captions offset from the text column). **Only this node edits
     `kit/kit.css`/`kit.js`** — one owner avoids edit clashes.
     (b) render-check script in `prototype/` — screenshots every
     `figure`/diagram of a page at 1280 and 390, light and dark, using headless
     Chrome (flags: `handoff.md` s3 Learnings; `sips` for resizing).
     (c) AUTHORING.md draft — the small gaps (non-diagram caption, footer, TOC,
     steps holding code, links from moved pages), a render-check step in the
     checklist, steering toward hand-drawn SVG when readability is at stake.
   - **Wave 2 (parallel):** fresh subagent rebuilds `docs/setup-guide.html` from
     AUTHORING.md alone (kit unseen); re-render the deck
     `where-ai-actually-helps.html` through the render check.
   - **Reconcile:** main session looks at every diagram screenshot itself,
     updates RESULTS.md (sizes in bytes, tokens = bytes/4 labelled estimate).
3. Execute the plan (`superpowers:dispatching-parallel-agents`; verify
   subagent outputs on disk — summaries are hints).
4. Pose the verdict question, one question, plain terms: **adopt** (then ask
   where it lands: `docs/kit/`? a skill?) or **drop**.

**No human present:** do steps 1–3, commit, then stop with step 4's question
open.

## Read these first, in order

1. `work/html-kit/decisions.md`
2. `work/html-kit/prototype/RESULTS.md` — the "Session 4" section
3. `work/html-kit/prototype/AUTHORING.md`

## Do NOT reload

- The original deck source under `work/sdlc-ai-mapping/slides/` — its diagrams
  are already ported to kit SVG; numbers are in RESULTS.md.
- The session-3 Mermaid-vs-original comparison — superseded by session 4.

## Constraints already decided (do not re-litigate)

- HTML stays the source of truth for human-facing pages; Markdown-plus-renderer
  only for long prose docs.
- Agent-agnostic: plain CSS/JS files plus a doc, no runtime-specific skill.
- Throwaway until a verdict: everything stays in `work/html-kit/prototype/`.
- Hand-drawn SVG is allowed, kit-coloured (no `fill=`/`stroke=`/`font-*=`/`<defs>`).

## State snapshot

- Branch `main`, ahead of origin (push is the user's call). html-kit work is all
  committed. Uncommitted `docs/`, `scripts/`, `skills/`, and
  `work/runtime-session-identity/` changes belong to other sessions — leave them,
  and stage only `work/html-kit/` paths when committing (a concurrent session
  has swept files into its commit before).
