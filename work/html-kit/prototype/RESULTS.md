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

# Session 5 — gaps closed, every diagram render-checked

Plan `plans/01-kit-gap-fixes` (2 waves, parallel subagents). Tokens = bytes/4,
an estimate.

## What changed

- **Kit** (sole owner, one subagent): `<pre><code>` styled, scrolls inside its
  box (no page scroll at a real 390); doc-page Mermaid kept at ≥14px labels
  (scrolls if wide); table-in-figure no longer clipped, captions on the text
  column; new `ol.steps`, `nav.toc`, `body.doc > footer`.
- **`render-check.sh <page> [out]`** — isolates each figure, 4 shots
  (1280/390 × light/dark). Phone width goes through an iframe because headless
  Chrome won't lay out narrower than 500px (first version's "390" was fake).
- **AUTHORING.md** — code blocks, steps, contents, footer, captions on
  tables/code, moved-page links, render check in the checklist, SVG is the
  default diagram, viewBox ~520–600 wide and cropped (was 700–960).

## Size

| File | Session 4 | Session 5 | Est. tokens |
|---|---|---|---|
| `kit.css` | 12,284 B | 14,468 B | ~3,620 |
| `kit.js` | 4,742 B | 5,204 B | ~1,300 |
| `AUTHORING.md` (read per authoring agent) | 6,786 B | 9,071 B | ~2,270 |
| `render-check.sh` | — | 5,846 B | ~1,460 |
| Deck (original 36,687 B) | 17,074 B | 17,079 B (53% smaller) | ~4,270 |
| Setup guide (original 29,079 B) | 18,428 B | 19,667 B (32% smaller) | ~4,920 |

The setup guide grew 1.2 KB over session 4 because its fake code lines became
real code blocks and two Mermaid diagrams became hand-drawn SVG.

## Look — every diagram viewed by the main session (`shots/s5/`)

| Figure | 1280 light/dark | 390 light/dark | Verdict |
|---|---|---|---|
| Setup 1 — layout table in a figure | ✓ | ✓ wraps cleanly | pass |
| Setup 2 — symlinks → CONTEXT.md (SVG, vertical) | ✓ labels large (~25px) | ✓ | pass |
| Setup 3 — setup pipeline (SVG, two rows; Mermaid was cut off at 390) | ✓ labels large | ✓ | pass |
| Setup 4 — global vs local (cards in a figure; 900-wide SVG unreadable at 390) | ✓ | ✓ stacks | pass |
| Setup 5 — toolchain (cards) | ✓ | ✓ stacks | pass |
| Deck 1 — six-stage ring (viewBox cropped, label moved) | ✓ | ✓ ~14px | pass |
| Deck 2 — eight-stage backup graph (label overlaps fixed) | ✓ | ✗ ~5px text | pass on desktop; phone is a format limit (1280×800 slide, backup slide) |

## Findings

- The rule worked: a fresh agent rebuilt the guide from AUTHORING.md alone,
  ran the render check, saw Mermaid cut off and 900-wide SVG unreadable at
  390, and fixed both on its own. Without the render check it would have
  shipped both.
- One SVG can't be right at both widths: text at 1280 is ~2.5× its 390 size.
  The rule now favours phone (520–600 wide), so desktop labels come out big.
  A kit fix (cap SVG width on desktop) would balance it; not done.
- Rule gaps still open: a captioned card grid in a figure, a heading-plus-list
  callout box, a list of links (used `.note`).

# Session 6 — desktop SVG cap, last rule gaps

Plan `plans/02-desktop-cap-and-gaps` (one wave, done in the main session).
Tokens = bytes/4, an estimate.

## What changed

- **Desktop SVG cap** — on a doc page `kit.js` records each diagram's viewBox
  width (`--vbw`) and `kit.css` sizes the SVG so 16-unit labels land at body
  text size (`width: min(100vw − 40px, vbw × 0.0625em)`, centred; a wide
  viewBox still bleeds past the column). Phones are unchanged (full column).
  Decks are unchanged.
- **Rule gaps closed** in AUTHORING.md: captioned card grid
  (`<figure><div class="grid">…<figcaption>`, already rendered fine — rule
  only); `div.callout` box with an `<h3>` and `<p>`s or a `<ul>` (one CSS
  line); a list of links is a plain `<ul>`, not a `.note` with `·`.
- **Pages** — the setup guide's `.note` link line is now a list; the deck's
  eight-stage backup caption says it is too dense for a phone.

## Size

| File | Session 5 | Session 6 | Est. tokens |
|---|---|---|---|
| `kit.css` | 14,468 B | 14,937 B | ~3,730 |
| `kit.js` | 5,204 B | 5,535 B | ~1,380 |
| `AUTHORING.md` | 9,071 B | 9,584 B | ~2,400 |
| Deck | 17,079 B | 17,125 B (53% smaller than original) | ~4,280 |
| Setup guide | 19,667 B | 19,809 B (32% smaller than original) | ~4,950 |

## Look (`shots/s6/`, viewed by the main session)

| Figure | 1280 | 390 | Verdict |
|---|---|---|---|
| Setup 2 — symlinks (SVG) | labels ~20px = body text (was ~25px), centred | unchanged | pass |
| Setup 3 — pipeline (SVG) | same, light + dark | unchanged | pass |
| Setup 1, 4, 5 — table, card grids | unchanged | unchanged | pass |
| Deck 1, 2 | unchanged; backup caption added | backup still a slide-format limit, now captioned | pass |

Rule greps on both pages print `0`. The new link list sits outside any figure,
so the render check does not shoot it; it is a plain kit `<ul>`.

## Open

The verdict: adopt or drop the kit, and if adopt, `docs/kit/` (plain files)
or a workspace skill.

# Session 7 — adoption readiness, wave 1

Plan `plans/03-adoption-readiness`, wave 1. Tokens measured with tiktoken
o200k_base (not bytes/4).

## What changed

- **Rules split** — `AUTHORING.md` keeps skeleton, hard rules, text roles,
  components, checklist; choosing, drawing, Mermaid and the render check moved
  to `DIAGRAMS.md`, read only when a page has a diagram. No class or rule lost
  (every backticked token and class of the old file is in one of the two).
- **Wide SVG on phones** — on a doc page, `kit.js` marks a diagram whose viewBox
  is wider than 600 (`data-wide`); below 700px `kit.css` gives it
  `min-width: vbw × 0.75px` (16-unit labels at 12px) and the figure scrolls
  sideways. Probe at 390: page `scrollWidth` 390 (no page scroll), figure 350
  showing a 675px diagram.
- **`check-links.sh`** — kit path and every relative `href`/`src` must resolve.
  Passes on both pages and the sample; seen to fail (exit 1, 20 broken) on a
  copy moved one folder down. Wired into the AUTHORING checklist.
- **`render-check.sh` portable** — finds Chrome via `$CHROME`, the macOS app,
  then `google-chrome`, `google-chrome-stable`, `chromium`, `chromium-browser`;
  crops with `sips`, ImageMagick or Pillow; `--no-sandbox` as root; exit 2 with
  an install hint when Chrome or a cropper is missing. Ran on this Mac and in a
  Debian bookworm container (Pillow and ImageMagick paths, 20 shots each).
  Mermaid's CDN path was not exercised on Linux (setup guide has none).
- **`kit-sample.html`** — the regression page: every class in both rule files
  except deck-only `deck`, `slide`, `backup`. Rule greps print 0, links pass.

## Tokens (o200k)

| File | Before | Now |
|---|---|---|
| `AUTHORING.md` (read for every page) | 2,812 | 1,999 (−29%) |
| `AUTHORING.md` + `DIAGRAMS.md` (page with a figure) | 2,812 | 3,010 (+7%) |
| `kit.css` / `kit.js` (never read by the author) | — | 5,059 / 1,472 |
| `kit-sample.html` | — | 2,997 |

## Look (`shots/s7/sample/`, `shots/s7/wide/`, viewed by the main session)

| Figure | 1280 | 390 | Verdict |
|---|---|---|---|
| 1 captioned card grid | fine | stacks | pass |
| 2 captioned table, 3 captioned code | fine | fine | pass |
| 4 hand-drawn example | `rework` label sat on the arc; moved to y=93 in `DIAGRAMS.md` and sample, re-shot | clear | pass after fix |
| 5 every shape and tone | fine, light + dark | fine | pass |
| 6 900-wide SVG | full width | labels 12px, cut at the edge, scrolls | pass |
| 7 short Mermaid | labels small (~11px) | readable | as the "Choosing" rule predicts; kept as the warning case |

## Open

- On this Mac, `render-check.sh` leaves setup-guide figures 1 and 4 at 500px
  wide in the 390 shots (not cropped); same with the HEAD script, fine on Linux
  and on every sample figure. Cause not found.
- Wave 2: the Codex + Gemini rebuild from the rules alone.
