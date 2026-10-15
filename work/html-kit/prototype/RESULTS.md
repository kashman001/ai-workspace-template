# html-kit prototype — results (session 3, 2026-10-15)

All sizes are bytes (`wc -c` / Python `len(bytes)`). Token figures are
**estimates** (bytes / 4); there is no local Claude tokenizer.

## Size

| File | Total | style/script/svg | Est. tokens |
|---|---|---|---|
| Original `where-ai-actually-helps.html` | 36,687 B | 20,129 B (54%) | ~9,170 |
| Kit rebuild `prototype/where-ai-actually-helps.html` | 13,636 B | 40 B (0%) | ~3,410 |
| Subagent `subagent/doc.html` | 5,809 B | 0% | ~1,450 |
| Subagent `subagent/deck.html` | 3,296 B | 1% | ~820 |

The rebuild is **63% smaller** (23,051 B saved, ~5,760 est. tokens) per page written.
Note: `shots/sub-deck.jpg` row 3 shows the `ol.points` bug before the fix.
One-off cost the authoring agent pays instead: `AUTHORING.md` 3,777 B (~940 est. tokens).
The kit itself (`kit.css` 9,490 B + `kit.js` 4,175 B) is never read by the
authoring agent — the subagent test confirmed it wasn't needed.

## Look (screenshots in `shots/`, headless Chrome 1280×800, reduced motion)

- **Text slides: near-identical.** Paradox, three claims, dividing line, measured
  wins, seams, asks, refrain — same fonts, colours, spacing (`shots/pair-a.jpg`,
  `pair-b.jpg`; original left, kit right).
- **Gained:** dark mode (original has none — `shots/dark.jpg`), print stylesheet,
  tables auto-wrapped, consistent look across pages.
- **Lost — diagrams.** Mermaid can't hold the hand-tuned layouts:
  - the six-stage ring becomes a lopsided loop; Discover no longer sits in the
    centre (`shots/pair-a.jpg`, row 2; original left, kit right) — readable but the "loop" message is weaker;
  - the eight-stage backup graph renders small and tangled; labels are hard to read
    (`shots/pair-b.jpg`, row 3). This one is a real regression.
- **Lost — tier ladder.** Rebuilt as a plain table; the coloured "stance" column
  is gone (`shots/pair-a.jpg`, row 3). A small `.rows` component could restore it if wanted.
- Mermaid loads from a CDN (jsdelivr, pinned 10.9.1): diagrams need network.

## Fresh-agent test (subagent given only `AUTHORING.md` + `docs/context-budget.md`)

- Produced a valid doc and a valid 5-slide deck first try; checks printed `0`;
  only sheet classes used. Its Mermaid flowchart (WARN/STOP flow) rendered cleanly
  (`shots/sub-doc-s.jpg`; deck in `shots/sub-deck.jpg`) — Mermaid suits flowcharts, just not spatial layouts.
- **Kit bug it surfaced (fixed):** `ol.points` broke when `<li>` held bare text,
  exactly as the sheet told authors to write it (`shots/points.jpg` after fix).
- Gaps it reported in the sheet: `<code>` and `<em>` not mentioned; deck title
  subtitle (used `.lede`); whether eyebrow/tags/tables/figures are fine on slides;
  when to use `.grid small` for three longer cards. All small wording fixes.

## Other kit fixes made during the run

- Card `.meta` line rendered too large (specificity) — fixed.
- Mermaid edge labels had black boxes in dark mode — fixed (`edgeLabelBackground`).

## Verdict options (the user's call)

1. **Adopt** — move kit + rule into the template (e.g. `docs/kit/` + a skill
   or doc pointer), fix the sheet gaps, and accept Mermaid for diagrams. Pages
   that genuinely need a spatial diagram may keep one hand-drawn SVG as an
   allowed exception.
2. **Adjust, then re-measure** — add an "escape hatch" (one allowed inline
   `<svg>` per figure, or a `<figure class="raw">`) plus a `.rows` component,
   fix the sheet gaps, and re-run on a second page (e.g. `docs/setup-guide.html`)
   before deciding.
3. **Drop** — keep writing freeform HTML; the 63% saving isn't worth the diagram
   quality loss.

Recommendation: **2** — the text-page win is clear and the authoring rule
works cold, but the diagram regression needs an answer before it lands in the
template.
