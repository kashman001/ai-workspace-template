# html-kit — A shared HTML kit so agents write content-only pages

Governing skill(s): `prototype` (loosely: the question is "can a shared kit make
agent-generated HTML cheap without losing what makes it worth reading?").

**Start here:** `next-session.md` (catch-up launcher) → `handoff.md`
(session ledger, top block).

## What this is

We prefer HTML for anything humans read. When an agent writes HTML from scratch,
most of its output is design (CSS, hand-drawn SVG, script) rather than content.
That costs tokens on every page and makes pages look slightly different each time.
The idea, from a 72-run benchmark (DIY Smart Code, "I Tested HTML vs Markdown for
AI Coding Agents!", https://youtu.be/iLDkDIgqQM4; kit:
https://github.com/leex279/agent-html-kit): keep all design in one shared kit.
Agents then write only semantic HTML plus kit class names. This effort prototypes
that kit for the template and measures it on one of our real pages.

Baseline (bytes in `<style>`/`<script>`/`<svg>` as a share of each file, measured
2026-10-13): long-lived docs are already lean (backlog 3%, archive 1%), but
one-off generated pages are not (setup-guide 51%, slides 55% and 95%, research
page 30%).

## Success criteria

- A prototype kit (`prototype/kit/kit.css` + `kit.js`) covering docs and slide
  decks, with light and dark themes and Mermaid for diagrams.
- An authoring rule short enough to load per page (`prototype/AUTHORING.md`):
  no `<style>`, no inline styles, no hand-drawn SVG.
- `where-ai-actually-helps.html` rebuilt on the kit, with measured size versus
  the original and screenshots of both for a side-by-side look.
- A fresh agent, given only `AUTHORING.md`, produces a valid content-only page
  (the rule can be followed without seeing the kit source).
- A verdict: adopt (and where it lands in the template), adjust, or drop.

## Related

- `scripts/build-guide-html.sh` already renders `docs/workspace-structure.md` to
  HTML with pandoc and a stylesheet copied from `docs/setup-guide.html`. If the
  kit is adopted, that renderer can use the kit's stylesheet too.
- `skills/improve-codebase-architecture/HTML-REPORT.md` (vendored) is half a kit
  already (Tailwind + Mermaid) but asks for hand-drawn SVG diagrams. Local
  patches can only touch `SKILL.md`, so any change there goes upstream.

## Files

- `next-session.md` — forward launcher (what to do next). REPLACED each rollover.
- `handoff.md` — session ledger (what happened). APPEND newest-on-top; archive
  to `handoff-archive.md` when it exceeds the two most recent sessions.
- `prototype/` — throwaway kit, authoring rule, rebuilt test page, and results.
