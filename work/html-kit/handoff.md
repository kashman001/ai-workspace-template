<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

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
