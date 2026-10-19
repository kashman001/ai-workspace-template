<!-- Archived handoff blocks for html-kit, newest on top. -->

# Session Handoff — 7 (2026-10-18): plan 03 wave 1 done; cross-runtime test next

**Summary.** Plan `plans/03-adoption-readiness` wave 1 closed (nodes 01–06),
commit `61e8474`. Nodes 03 (check-links) and 04 (portable render-check, Linux
run in a Debian container) ran in parallel subagents; the main session did
01, 02, 05 and viewed every sample shot itself (contact sheets
`prototype/shots/s7/sheet-a.png`, `sheet-b.png`). Rolled over at the wave
boundary near WARN; node 07 needs a fresh budget.

**Shipped** (all under `prototype/`): `DIAGRAMS.md` split out of `AUTHORING.md`
(o200k: 2,812 → 1,999 up front; 3,010 with diagrams); wide-SVG phone scroll
(`kit.js` `data-wide` flag, `kit.css` media rule); `check-links.sh`;
`render-check.sh` Chrome/cropper lookup for macOS + Linux; `kit-sample.html`
regression page; the example's `rework` label moved off its arc (y=93).
Detail and numbers: `prototype/RESULTS.md` → "Session 7".

**Decisions.** In the commit trailer (data-wide flag over a CSS clamp hack;
diagram rules read only when a page has a figure). No new decisions.md entry.

**Open.** Mac-only: setup-guide figs 1, 4 come out 500px wide in 390 shots
(also with the HEAD script; Linux and sample fine) — cause unknown. Mermaid
on Linux not exercised. Sample omits deck-only classes by design.

**Suggested skills.** `plan` (node 08 reconcile), `diagnosing-bugs` only if the
500px crop matters to node 07.

Learnings:
- `git add work/html-kit` fails when cwd is already work/html-kit (Bash cwd
  persists across calls); stage with paths relative to cwd.

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

# Session Handoff — 2026-10-15 (session 2: wired for session-loop)

Same conversation as session 1; the record numbered it 2 because it registered
after the s1 block existed (register opens at ledger top + 1). Added the
`work/README.md` row and a per-item `context-budget.env` (`ROLLOVER_RELAUNCH=auto`,
same precedent as jev-integration) so `scripts/session-loop.sh html-kit` can chain
sessions. No kit code written yet; the launcher's START HERE is unchanged in
substance. Staged the successor (s3) for the supervisor, hands-off.

# Session Handoff — 2026-10-15 (session 1: scaffold + prototype kit)

Scaffolded the work item after reviewing the HTML-vs-Markdown benchmark video
and measuring the design share of the repo's HTML files (see README). Test page
chosen: `where-ai-actually-helps.html` (14 slides, 9.8 KB of CSS, one
hand-drawn SVG ring diagram). `sdlc-three-zooms.html` was rejected as the test
case: it is an interactive radial map, the one kind of page where freeform
design earns its cost.
