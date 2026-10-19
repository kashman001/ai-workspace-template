<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 6 (2026-10-18): desktop SVG cap, last rule gaps; verdict question open

**Summary.** Plan `plans/02-desktop-cap-and-gaps` (1 wave, 3 nodes, done in the
main session; no subagents, the work ran in sequence). Kit: doc SVG sized from its
viewBox so labels land at body size on desktop (`--vbw` set by kit.js); `div.callout`
box. AUTHORING.md: captioned card grid, callout box, link lists as plain `<ul>`.
Setup guide link line became a list; deck backup caption says phone is too small.
Render check re-run on both pages, shots viewed: all pass. Numbers: RESULTS.md
"Session 6". Verdict discussion with the user: measured real tokens with tiktoken
(o200k: deck 10,631 → 5,043, guide 9,150 → 5,951, AUTHORING.md 2,812; ~3.4 B/tok,
so bytes/4 under-counted ~17%; Claude tokenizer unmeasured — no API key). I
recommended adopt into `docs/kit/` and listed fixes for the concerns; the user
said: run that fix plan first, then decide. Made plan `03-adoption-readiness`
(8 nodes, 2 waves, not started); closed plan 02 (`status: closed` by hand).

**Learnings:**
- A margin of `calc((100% - W) / 2)` on a grid item centres it when W is narrower
  than the column and bleeds it evenly when wider — one rule for both.
- `plan.sh` node checks run from `work/<item>/`; write paths relative to it.

**Suggested skills next:** none for the verdict; on adopt, `to-tickets` or `plans`.

# Session Handoff — 5 (2026-10-18): gaps closed, every diagram render-checked; verdict question open

**Summary.** Made plan `plans/01-kit-gap-fixes` (2 waves, 8 nodes, closed) and ran
it with parallel subagents. Kit: code blocks, doc Mermaid min size, figure
layout, steps/toc/footer. New `prototype/render-check.sh` (4 shots per figure).
AUTHORING.md gaps closed, render check in the checklist, SVG default, viewBox
520–600. A fresh agent rebuilt the setup guide from the rule alone and fixed its
own diagrams after the render check. The deck ring was re-cropped. All shots
viewed by the main session: every diagram passes except deck backup graph at 390
(slide-format limit). Numbers: RESULTS.md "Session 5". User reply to the verdict
question: roll over, fix the open items first, then come back to it.

**Learnings:**
- Headless Chrome won't lay out narrower than 500px; `--window-size=390` gives a
  cropped 500 layout. Use an iframe of the exact width (render-check.sh does).
- An SVG scaled to the column can't be sized right for both 1280 and 390;
  the rule now favours phone, so desktop labels are large.

**Suggested skills next:** none for the verdict; on adopt, `to-tickets` or `plans`.
