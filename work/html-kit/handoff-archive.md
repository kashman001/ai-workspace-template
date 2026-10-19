<!-- Archived handoff blocks for html-kit, newest on top. -->

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
