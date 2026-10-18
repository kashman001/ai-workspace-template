# Writing a page on the HTML kit

You write content. The kit (`kit/kit.css`, `kit/kit.js`) does all design and
behaviour. You never need to open the kit files.

## Hard rules

1. No `<style>` element and no `style="…"` attribute.
2. No `<script>` other than the kit's one line below.
3. Diagrams are Mermaid (`<pre class="mermaid">`) or a hand-drawn
   `<svg class="diagram">`. In the SVG, no colour or font attributes
   (`fill=`, `stroke=`, `font-*=`) and no `<defs>`: the kit colours it.
4. Use only the elements and classes listed here. If the content needs
   something not listed, use plain semantic HTML (`<p>`, `<ul>`, `<table>`, …)
   and say so when you hand the page back.

## Skeleton

```html
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Page title</title>
<link rel="stylesheet" href="kit/kit.css">
<script src="kit/kit.js" defer></script>
</head>
<body class="doc">   <!-- or class="deck" -->
<main>
  …content…
</main>
</body>
</html>
```

Adjust the `kit/` path so it points at the kit folder from where the page lives.

**Doc** (`body.doc`): a scrolling page. Inside `<main>`: an `<h1>`, an optional
`.lede`, then one `<section>` per topic, each starting with an `<h2>`.
Use `<h3>` for sub-topics inside a section.

**Deck** (`body.deck`): slides. Inside `<main>`: one `<section class="slide">`
per slide. Appendix slides get `class="slide backup"`; they come last and sit
outside the slide count. The kit adds the progress bar, footer, and keyboard
navigation; don't write them. Use `<h1>` on the title slide, `<h2>` elsewhere;
a subtitle under the title is a `.lede`. Everything on this sheet works on
slides too (eyebrow, tags, tables, figures, cards). Keep one idea per slide:
if it doesn't fit 1280×800, split it.

## Text roles

| Write | For |
|---|---|
| `<p class="eyebrow">` | small label above a heading |
| `<p class="lede">` | the opening paragraph; larger text |
| `<p class="note">` | small grey aside, sources, caveats |
| `<p class="callout">` | one key sentence, ruled on the left; open with `<b>` |
| `<div class="statement"><p>…</p><p>…</p></div>` | a few very large lines (closing slide); every second line is coloured |
| `<p class="meta">` | small monospace line, e.g. a source under a card |
| `<b>` | a bold lead-in at the start of a point |
| `<em>`, `<strong>` | emphasis in running text |
| `<code>` | file names, commands, identifiers |

## Components

**Tag** — short inline label: `<span class="tag ok">[measured]</span>`.
Tones: `ok` (green), `info` (blue), `warn` (amber), `bad` (red); no tone = grey.
Pick tones by meaning and keep the mapping the same across the page.

**Numbered points** — `<ol class="points"><li><b>Lead.</b> Rest of the point.</li>…</ol>`.

**Big numbers** —
```html
<div class="stats">
  <div class="stat"><b>−1.5%</b><p>what the number measures</p></div>
</div>
```

**Cards in a grid** — the grid picks the column count from the width.
```html
<div class="grid">
  <div class="card ok">
    <h3>Title <small>optional subtitle</small></h3>
    <p>Body text.</p>          <!-- or a <ul> of short items -->
    <p class="meta">Source · figure</p>
  </div>
</div>
```
Card accents (coloured top edge): `accent`, `ink`, `ok`, `info`, `warn`, `bad`,
or none. Use `<div class="grid small">` for four or more short cards
(a heading and one sentence each); three or fewer cards, or cards with
several sentences, use the plain `grid`.

**Rows** — a coloured ladder (tiers, levels, verdicts). Each row has exactly
three parts: a label, a description, and a `<b>` verdict coloured by the row's tone.
```html
<ul class="rows">
  <li class="ok"><span class="tag ok">[measured]</span> <span>What it means</span> <b>What to do</b></li>
  <li class="bad"><span class="tag bad">[hype]</span> <span>What it means</span> <b>What to do</b></li>
</ul>
```
Tones as for tags, plus `accent`.

**Table** — a plain `<table>` with `<thead>`/`<tbody>`. The first column is
bold. The kit adds the scroll box; don't wrap it.

**Diagram** — Mermaid inside a figure:
```html
<figure>
  <pre class="mermaid">
flowchart LR
  A[Plan] --> B[Build] --> C[Verify]
  C -. failures .-> B
  </pre>
  <figcaption>What the diagram shows, in one or two sentences.</figcaption>
</figure>
```
Keep labels short. Don't set colours or styles in the Mermaid source; the kit
themes it for light and dark. Escape `<`, `>` and `&` inside diagram text.

**Choosing:** Mermaid for a plain flowchart or sequence (a chain with a few
branches). Draw SVG when the layout carries the meaning (a ring, a centre, a
timeline, a long chain with feedback arcs) or when Mermaid comes out small or
tangled. Good diagrams beat small files.

**Hand-drawn diagram** — you place the shapes; the kit colours them, in light and dark.
```html
<figure>
  <svg class="diagram" viewBox="0 0 520 120" role="img" aria-label="Full description of the diagram">
    <rect x="20"  y="40" width="120" height="40" rx="5"/><text x="80"  y="60">Plan</text>
    <rect x="200" y="40" width="120" height="40" rx="5"/><text x="260" y="60">Build</text>
    <rect class="solid" x="380" y="40" width="120" height="40" rx="20"/><text class="inverse" x="440" y="60">Ship</text>
    <line class="arrow" x1="140" y1="60" x2="199" y2="60"/>
    <line class="arrow" x1="320" y1="60" x2="379" y2="60"/>
    <path class="arrow dash accent" d="M 260 80 C 260 115, 80 115, 80 81"/>
    <text class="small accent" x="170" y="108">rework</text>
  </svg>
  <figcaption>What the diagram shows.</figcaption>
</figure>
```
- Shapes (`rect`, `circle`, `ellipse`, `polygon`) are outlined boxes; lines
  (`line`, `path`, `polyline`) are plain strokes. `<text>` is centred on its
  `x`,`y`, both across and up-down, so put it at the middle of its box.
- Classes: `arrow` (arrowhead at the line's end; it takes the line's colour),
  `dash`, a tone (`accent`, `ok`, `info`, `warn`, `bad`) to colour a line, shape
  or text, `solid` (shape filled with its tone; accent if none), and on text,
  `small` (monospace edge label) and `inverse` (text on a `solid` shape).
- Pick a `viewBox` around 700–960 wide; the kit scales it to fit. Default text
  is 16 units, `small` is 14; size boxes for that. Leave about 10 units of
  clearance between labels and lines.
- Always give `role="img"` and an `aria-label` that says what the picture says.

**Links** — plain `<a href>`. Quotes and dashes as characters or entities.

## Check before handing back

- `grep -cE '<style|style=|fill=|stroke=|font-[a-z]+=|<defs' page.html` prints `0`.
- `grep '<svg' page.html | grep -vc 'class="diagram"'` prints `0`.
- The only `<script>` is the kit line in `<head>`.
- Every class you used appears on this sheet.
