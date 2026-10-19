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
<footer><p>Owner · last updated · source links</p></footer>   <!-- optional, doc only -->
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

**Caption on a table or code block** — wrap it in a `<figure>`, same as a diagram:
`<figure><table>…</table><figcaption>What it shows.</figcaption></figure>`.
Don't fake a caption with `.note`.

**Code block** — commands, file contents, output. Keep line breaks as written;
escape `<`, `>` and `&`. Never `<p>` + `<br>` for code.
```html
<pre><code>git clone https://example.com/repo.git
cd repo &amp;&amp; ./setup.sh</code></pre>
```

**Steps** — numbered steps where a step holds a code block (plain `<ol>` for
one-line steps). Each `<li>` holds an `<h3>`, then any `<p>` and code blocks.
```html
<ol class="steps">
  <li><h3>Install the tools</h3>
    <pre><code>brew install jq gh</code></pre></li>
  <li><h3>Log in</h3><p>Pick HTTPS when asked.</p>
    <pre><code>gh auth login</code></pre></li>
</ol>
```

**Contents** — a doc with five or more sections gets a list of links after the
lede; give each `<section>` an `id`.
```html
<nav class="toc"><ol><li><a href="#install">Install</a></li>…</ol></nav>
…
<section id="install"><h2>Install</h2>…</section>
```

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

**Choosing:** default to hand-drawn SVG. Mermaid only for a short chain or
sequence (about five boxes or fewer, few branches) that the render check shows
readable at both widths; Mermaid lays itself out and often renders tiny on a
wide doc page. Draw SVG whenever the layout carries the meaning (a ring, a
centre, a timeline, feedback arcs), and switch to SVG the moment a Mermaid
diagram renders small or tangled. Good diagrams beat small files.

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
- The kit scales the `viewBox` to the column, which is about 340px on a phone,
  so text shrinks by 340 ÷ viewBox width. On a doc page keep the `viewBox`
  about 520–600 wide (stack or wrap the layout to fit) and crop it to the
  drawing, with no empty margins. Default text is 16 units, `small` is 14;
  size boxes for that. Leave about 10 units of clearance between labels and lines.
  A layout that can't fit 600 wide stays readable only on desktop: say so in
  the caption, or split it into smaller diagrams.
- Always give `role="img"` and an `aria-label` that says what the picture says.

**Links** — plain `<a href>`. Quotes and dashes as characters or entities.
Relative links resolve from where the page *now* lives: if you moved or
rebuilt a page in another folder, re-point every relative `href` and the
`kit/` path (e.g. `../README.md` from `docs/`), then click one to confirm.

## Check before handing back

- `grep -cE '<style|style=|fill=|stroke=|font-[a-z]+=|<defs' page.html` prints `0`.
- `grep '<svg' page.html | grep -vc 'class="diagram"'` prints `0`.
- The only `<script>` is the kit line in `<head>`.
- Every class you used appears on this sheet.
- Page has any figure: run `render-check.sh page.html` (it sits next to the
  `kit/` folder; four shots per
  figure: 1280 and 390 wide, light and dark) and open every shot. Each must
  show labels readable at real size, nothing clipped or overlapping, and the
  figure sized in proportion to the page. Fix and re-run until all pass;
  passing the greps says nothing about how a diagram looks.
