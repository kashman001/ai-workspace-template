<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 5 (2026-10-18): gaps closed, every diagram render-checked; verdict question open

**Summary.** Made plan `plans/01-kit-gap-fixes` (2 waves, 8 nodes, closed) and ran
it with parallel subagents. Kit: code blocks, doc Mermaid min size, figure
layout, steps/toc/footer. New `prototype/render-check.sh` (4 shots per figure).
AUTHORING.md gaps closed, render check in the checklist, SVG default, viewBox
520–600. A fresh agent rebuilt the setup guide from the rule alone and fixed its
own diagrams after the render check. The deck ring was re-cropped. All shots
viewed by the main session: every diagram passes except deck backup graph at 390
(slide-format limit). Numbers: RESULTS.md "Session 5". Stopped at context WARN
with the adopt/drop question posed to the user.

**Learnings:**
- Headless Chrome won't lay out narrower than 500px; `--window-size=390` gives a
  cropped 500 layout. Use an iframe of the exact width (render-check.sh does).
- An SVG scaled to the column can't be sized right for both 1280 and 390;
  the rule now favours phone, so desktop labels are large.

**Suggested skills next:** none for the verdict; on adopt, `to-tickets` or `plans`.

# Session Handoff — 4 (2026-10-18): adjust round, diagrams restored, second page tested

**Summary.** User verdict: **adjust** — good diagrams for human readers are a hard
requirement, and they must be checked rendered in HTML (both in `decisions.md`).
Kit now supports hand-drawn `<svg class="diagram">` (kit-coloured, dark-safe,
shared arrowhead) and a `.rows` ladder; AUTHORING.md gaps from s3 fixed. Deck
diagrams restored to the original layouts. A fresh subagent rebuilt
`docs/setup-guide.html` from the rule alone and exposed three gaps. Rolled over at
WARN on the user's request: next session makes a plan and runs fixes with parallel
subagents, then returns to the adopt/drop question.

**What shipped (`prototype/`):** kit.css (+diagram SVG classes, `.rows`, text-stroke
fix), kit.js (arrow marker), AUTHORING.md (6,786 B), deck rebuilt 17,074 B (53% <
original), `setup-guide.html` (18,428 B, 37% <), `shots/s4-*.jpg`, RESULTS.md
"Session 4" section (numbers + findings).

**Open findings (RESULTS.md, "Second page"):** no code-block styling (blocks
adoption); Mermaid renders tiny on doc pages; table inside `<figure>` clipped,
captions offset; small rule gaps (non-diagram caption, footer, TOC, steps with code).

**Git note:** most s4 files landed in another session's commit `2f8ec22`
(session-loop L91) — a concurrent session committed while this one worked. Own
commits: `8592c24`, `dc4f94e`. main is ahead of origin; push is the user's call.

Learnings:
- Pillow isn't installed; use `sips` (macOS) to resize/convert screenshots.
- Tone classes on SVG need `text[class]{stroke:none}` or labels go bold.

**Suggested skills next:** `plans` (create the plan), `dispatching-parallel-agents`.

# Session Handoff — 3 (2026-10-15): kit built, measured, verdict pending

**Summary.** Built the prototype kit and ran the experiment end to end; all
results are in `prototype/RESULTS.md`. Rolled over at context WARN because
the next step (the verdict) is the user's call.

**What shipped (all under `work/html-kit/prototype/`):**
- `kit/kit.css` (9,490 B), `kit/kit.js` (4,175 B): doc + deck layouts,
  light/dark, print, Mermaid loader themed from CSS vars, deck nav built by JS.
- `AUTHORING.md` (3,777 B): the per-page rule.
- `where-ai-actually-helps.html` rebuilt: 13,636 B vs 36,687 B original (63%
  smaller; ~5,760 tokens saved, estimate = bytes/4).
- `subagent/doc.html`, `subagent/deck.html`: a fresh subagent's pages from
  `AUTHORING.md` alone; valid on first try.
- `shots/*.jpg`: comparison montages (original left, kit right).

**Findings.** Text slides look near-identical. Diagrams are the cost: Mermaid
loses the ring layout and the 8-stage backup graph is small and tangled. The
coloured tier ladder became a plain table. Three kit bugs were found and fixed
(card `.meta` size, Mermaid label boxes in dark mode, `ol.points` with bare
text). The subagent listed small sheet gaps (`<code>`, `<em>`, slide scope).

**Not done:** the sheet-gap wording fixes are left for after the verdict
(they only matter if the verdict is adopt or adjust).

Learnings:
- Headless Chrome on this Mac renders dark by default (system theme). For
  light use `--blink-settings=preferredColorScheme=1`; add
  `--force-prefers-reduced-motion`, otherwise entry animations get captured
  mid-fade.

**Suggested skills next:** none for the verdict; `plans` or `to-tickets` if adopt.
