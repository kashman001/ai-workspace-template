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

---

# Session 4 (2026-10-18) — adjust round: diagrams restored

Verdict taken: **adjust** — good diagrams for human readers are a hard
requirement (`../decisions.md`). Changes made:

- **Hand-drawn SVG is now a supported path**, not banned: `<svg class="diagram">`
  with no colour/font attributes and no `<defs>`. The kit colours shapes, lines
  and text from its CSS variables (so dark mode works), and `kit.js` injects one
  shared arrowhead that takes the colour of the line it ends (`context-stroke`,
  ink fallback). Classes: `arrow`, `dash`, tones, `solid`, text `small`/`inverse`.
- **`.rows`** component for coloured ladders (the evidence tiers).
- **Sheet gaps fixed**: `<code>`/`<em>`/`<strong>`, `<h3>` in docs, deck subtitle
  (`.lede`), "everything works on slides", when to use `grid small`, Mermaid vs
  SVG choice, new grep checks.
- Kit bug found and fixed: tone classes put a stroke on SVG text (bold, blurry
  labels) — `text[class]` now always drops the stroke.

## Size (deck, re-measured)

| File | Total | Est. tokens |
|---|---|---|
| Original | 36,687 B | ~9,170 |
| Kit rebuild, session 3 (Mermaid) | 13,636 B | ~3,410 |
| Kit rebuild, session 4 (hand-drawn SVG + rows) | 17,074 B | ~4,270 |

Still **53% smaller** than the original (19,613 B saved). The two diagrams cost
~3.4 KB back, but their markup is about half the original's (4,080 B vs
8,631 B; no colour, font or marker boilerplate), and the page no longer needs Mermaid
from a CDN. `kit.css` 12,284 B, `kit.js` 4,742 B, `AUTHORING.md` 6,786 B
(~1,700 est. tokens, read once per authoring agent).

## Look (`shots/s4-*.jpg`)

- Ring slide: matches the original layout; Discover back in the centre
  (`s4-k4-light.jpg`), and now has a dark version (`s4-k4-dark.jpg`).
- Eight-stage backup graph: matches the original (`s4-k14-light.jpg`), dark
  version `s4-k14-dark2.jpg`. The session-3 regression is gone.
- Tier ladder: coloured rows match the original (`s4-k5-light.jpg`).

## Second page: `docs/setup-guide.html` by a fresh agent (rule only, kit unseen)

`prototype/setup-guide.html`: **18,428 B vs 29,079 B original (37% smaller)**;
checks print `0`; all content kept. Screenshots: `shots/s4-setup-kit.jpg` vs
`shots/s4-setup-orig.jpg` (full page, light).

What it did with the original's 5 SVGs: 2 were real diagrams → Mermaid
(symlink fan-in; 5-step pipeline, losing the green Build highlight); 3 were
boxed lists drawn as SVG → a table and two card pairs (a fair call).

**Findings (to fix next):**
- **Code blocks are missing from the kit** — the biggest gap. `<pre>` renders
  unstyled and overflows; the agent fell back to `<p>` + `<code>` + `<br>`,
  losing alignment. A setup guide is mostly commands, so this blocks adoption.
- **Mermaid comes out small in docs** — both Mermaid diagrams render tiny on
  the full-width page. The agent chose Mermaid, as the rule allows for simple
  flows, so either Mermaid needs a minimum size in docs or the rule should push
  harder toward SVG.
- **Table inside `<figure>` is clipped on the left** (doc figure bleed); figure
  captions also sit offset from body text.
- Smaller rule gaps: caption for a non-diagram (used `.note`), footer slot,
  table of contents (used `grid small`), steps that hold code (used `<h3>`),
  relative links from a moved page.
