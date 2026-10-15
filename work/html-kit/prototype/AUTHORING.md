# Writing a page on the HTML kit

You write content. The kit (`kit/kit.css`, `kit/kit.js`) does all design and
behaviour. You never need to open the kit files.

## Hard rules

1. No `<style>` element and no `style="…"` attribute.
2. No `<script>` other than the kit's one line below.
3. No hand-drawn `<svg>`. Diagrams are Mermaid (`<pre class="mermaid">`).
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

**Deck** (`body.deck`): slides. Inside `<main>`: one `<section class="slide">`
per slide. Appendix slides get `class="slide backup"`; they come last and sit
outside the slide count. The kit adds the progress bar, footer, and keyboard
navigation; don't write them. Use `<h1>` on the title slide, `<h2>` elsewhere.

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
(a heading and one sentence each).

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

**Links** — plain `<a href>`. Quotes and dashes as characters or entities.

## Check before handing back

- `grep -c '<style\|style=\|<svg' page.html` prints `0`.
- The only `<script>` is the kit line in `<head>`.
- Every class you used appears on this sheet.
