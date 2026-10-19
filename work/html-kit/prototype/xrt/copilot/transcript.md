# Copilot CLI Session

> [!NOTE]
> - **Session ID:** `eb1b397c-0e3c-466f-9091-6e6757d9ff36`  
> - **Started:** 10/18/2026, 10:48:37 PM  
> - **Duration:** 1m 23s  
> - **Exported:** 10/18/2026, 10:50:01 PM  

---

<sub>1s</sub>

### User

Your runtime name (RT) is copilot. Read work/html-kit/prototype/xrt/brief.md and carry it out fully, without asking questions; no human is present. (The brief names codex or gemini as examples; your RT is copilot.)

---

<sub>4s</sub>

### `view`

**view the file at /Users/kashif/Developer/experiments/ai-workspace-template/work/html-kit/prototype/xrt/brief.md.**

/Users/kashif/Developer/experiments/ai-workspace-template/work/html-kit/prototype/xrt/brief.md

<details>
<summary>40 lines</summary>

```
# Brief — rebuild the setup guide on the HTML kit

You are run from the repository root. `RT` below is your runtime name
(`codex` or `gemini`); your output folder is
`work/html-kit/prototype/xrt/RT/`.

## Task

Rebuild `docs/setup-guide.html` as a page on the HTML kit, at
`work/html-kit/prototype/xrt/RT/setup-guide.html`. Keep all of its content
(every section, step, command, table, link and diagram); change only how it
is written, so it follows the kit rules.

## Read only these

1. `work/html-kit/prototype/AUTHORING.md` — the rules. Read it first.
2. `work/html-kit/prototype/DIAGRAMS.md` — the source page has diagrams, so
   read this too.
3. `docs/setup-guide.html` — the source content.

Do **not** open anything else under `work/html-kit/` (no other pages, no
`kit/` files, no `RESULTS.md`, no other runtime's folder). The rules are the
test: if they leave you unsure, decide, and note it in your summary.

## Paths

- The kit is at `work/html-kit/prototype/kit/`, so from your page the kit path
  is `../../kit/`.
- Re-point every relative link of the source to work from your folder (the
  repository root is `../../../../../` from it).

## Checks — run them, fix, re-run until they pass

From `work/html-kit/prototype/`:

1. `grep -cE '<style|style=|fill=|stroke=|font-[a-z]+=|<defs' xrt/RT/setup-guide.html` prints `0`.
2. `grep '<svg' xrt/RT/setup-guide.html | grep -vc 'class="diagram"'` prints `0`.
3. `./check-links.sh xrt/RT/setup-guide.html` passes.
4. `./render-check.sh xrt/RT/setup-guide.html xrt/RT/shots` — then **open and
   look at every PNG** it writes. Fix any figure that is cut off, overlapping,
   unreadable or wrong in either theme, and re-run.

## Limits

- Write only inside `work/html-kit/prototype/xrt/RT/`. Do not edit the rule
  files, the kit, the scripts or the source page.
- No git commands.

## When done

Write `work/html-kit/prototype/xrt/RT/summary.md` (short):
- each check's final result;
- what you got wrong first and fixed after a check or a look at the shots;
- any place the rules were unclear or missing something, and what you chose;
- any element or class you used that is not in the rule files.
```

</details>


---

<sub>6s</sub>

### `view`

**view the file at /Users/kashif/Developer/experiments/ai-workspace-template/work/html-kit/prototype/AUTHORING.md.**

/Users/kashif/Developer/experiments/ai-workspace-template/work/html-kit/prototype/AUTHORING.md

<details>
<summary>141 lines</summary>

````
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
| `<div class="callout">` | a ruled box with an `<h3>` then `<p>`s or a `<ul>` (key steps, warnings) |
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
To caption a grid (cards that are a figure, e.g. two layers side by side),
wrap it like a table: `<figure><div class="grid">…</div><figcaption>…</figcaption></figure>`.

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

**Diagram** — a hand-drawn `<svg class="diagram">` or a `<pre class="mermaid">`,
inside a `<figure>` with a `<figcaption>`. Page has a diagram: read
`DIAGRAMS.md` first (choosing, drawing, sizing, the render check).

**Links** — plain `<a href>`. Quotes and dashes as characters or entities.
A list of links (further reading, related pages) is a plain `<ul>`, one link per
`<li>` with a few words on what it covers; not a `.note` with `·` between links.
Relative links resolve from where the page *now* lives: if you moved or
rebuilt a page in another folder, re-point every relative `href` and the
`kit/` path (e.g. `../README.md` from `docs/`); `check-links.sh` confirms.

## Check before handing back

- `grep -cE '<style|style=|fill=|stroke=|font-[a-z]+=|<defs' page.html` prints `0`.
- `grep '<svg' page.html | grep -vc 'class="diagram"'` prints `0`.
- The only `<script>` is the kit line in `<head>`.
- Every class you used appears on this sheet or in `DIAGRAMS.md`.
- `check-links.sh page.html` (next to `kit/`) passes: the kit path and every
  relative `href`/`src` resolve.
- Page has any figure: run `render-check.sh page.html` and open every shot
  (`DIAGRAMS.md` → "Render check"). Passing the greps says nothing about how a
  figure looks.
- Can't run `render-check.sh` where you are (a sandbox with no Chrome, no
  shell)? Say so plainly in your hand-back and leave it for someone who can;
  the page isn't done until its shots have been viewed.
````

</details>


---

<sub>6s</sub>

### `view`

**view the file at /Users/kashif/Developer/experiments/ai-workspace-template/work/html-kit/prototype/DIAGRAMS.md.**

/Users/kashif/Developer/experiments/ai-workspace-template/work/html-kit/prototype/DIAGRAMS.md

<details>
<summary>71 lines</summary>

````
# Diagrams on the HTML kit

Read this only when a page has a diagram. `AUTHORING.md` holds everything
else; its hard rules still apply (no colour or font attributes in an SVG,
no `<defs>`).

## Choosing

Default to hand-drawn SVG. Mermaid only for a short chain or sequence (about
five boxes or fewer, few branches) that the render check shows readable at both
widths; Mermaid lays itself out and often renders tiny on a wide doc page. Draw
SVG whenever the layout carries the meaning (a ring, a centre, a timeline,
feedback arcs), and switch to SVG the moment a Mermaid diagram renders small or
tangled. Good diagrams beat small files.

Not every picture is a diagram. A folder tree is a code block; a two-column
inventory (what lives where, global vs local) is a list, table or card grid.
Draw an SVG only when position or arrows carry meaning.

## Hand-drawn diagram

You place the shapes; the kit colours them, in light and dark.
```html
<figure>
  <svg class="diagram" viewBox="0 0 520 120" role="img" aria-label="Full description of the diagram">
    <rect x="20"  y="40" width="120" height="40" rx="5"/><text x="80"  y="60">Plan</text>
    <rect x="200" y="40" width="120" height="40" rx="5"/><text x="260" y="60">Build</text>
    <rect class="solid" x="380" y="40" width="120" height="40" rx="20"/><text class="inverse" x="440" y="60">Ship</text>
    <line class="arrow" x1="140" y1="60" x2="199" y2="60"/>
    <line class="arrow" x1="320" y1="60" x2="379" y2="60"/>
    <path class="arrow dash accent" d="M 260 80 C 260 115, 80 115, 80 81"/>
    <text class="small accent" x="170" y="93">rework</text>
  </svg>
  <figcaption>What the diagram shows.</figcaption>
</figure>
```
- Shapes (`rect`, `circle`, `ellipse`, `polygon`) are outlined boxes; lines
  (`line`, `path`, `polyline`) are plain strokes. `<text>` is centred on its
  `x`,`y`, both across and up-down, so put it at the middle of its box.
  Never copy coordinates from an existing SVG (its text may be left-aligned
  at `x`): redraw every figure for the kit.
- Classes: `arrow` (arrowhead at the line's end; it takes the line's colour),
  `dash`, a tone (`accent`, `ok`, `info`, `warn`, `bad`) to colour a line, shape
  or text, `solid` (shape filled with its tone; accent if none), and on text,
  `small` (monospace edge label) and `inverse` (text on a `solid` shape).
- On a doc page the kit sizes the diagram from its `viewBox` width: on a wide
  screen text lands at body size, on a phone the diagram fills the column
  (about 340px), so text shrinks by 340 ÷ viewBox width. Keep the `viewBox`
  about 520–600 wide (stack or wrap the layout to fit) and crop it to the
  drawing, with no empty margins. Default text is 16 units, `small` is 14;
  size boxes for that: allow about 8.5 units per character of default text
  and 9 per character of `small` (monospace), plus 10 each side. A label
  that won't fit goes on two lines (two `<text>` elements 18 units apart).
  Leave about 10 units of clearance between labels and lines.
  A layout that can't fit 600 wide keeps its labels at 12px on a phone and
  scrolls sideways inside its figure; say so in the caption, or split it into
  smaller diagrams.
- Always give `role="img"` and an `aria-label` that says what the picture says.

## Mermaid

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

## Render check

Run `render-check.sh page.html` (it sits next to the `kit/` folder; four shots
per figure: 1280 and 390 wide, light and dark) and open every shot. Each must
show labels readable at real size, nothing clipped or overlapping, and the
figure sized in proportion to the page. Fix and re-run until all pass; passing
the greps says nothing about how a diagram looks.
````

</details>


---

<sub>6s</sub>

### `bash`

**cd /Users/kashif/Developer/experiments/ai-workspace-template; wc -c docs/setup-guide.html**

$ cd /Users/kashif/Developer/experiments/ai-workspace-template; wc -c docs/setup-guide.html

```
29079 docs/setup-guide.html
<shellId: 0 completed with exit code 0>
```


---

<sub>7s</sub>

### `view`

**view the file at /Users/kashif/Developer/experiments/ai-workspace-template/docs/setup-guide.html.**

/Users/kashif/Developer/experiments/ai-workspace-template/docs/setup-guide.html (lines 1-200)

<details>
<summary>185 lines</summary>

```
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>AI Workspace Template — Setup Guide</title>
<style>
  :root{
    --bg:#0f1222; --panel:#171a2e; --panel-2:#1d2138; --ink:#e7e9f3; --muted:#a3a8c3;
    --line:#2b3052; --accent:#7c83ff; --accent-2:#22d3ee; --green:#34d399; --amber:#fbbf24;
    --code:#0b0e1a; --radius:14px; --maxw:980px;
    --mono:ui-monospace,SFMono-Regular,Menlo,Consolas,"Liberation Mono",monospace;
    --sans:ui-sans-serif,system-ui,-apple-system,"Segoe UI",Roboto,Helvetica,Arial,sans-serif;
  }
  *{box-sizing:border-box}
  html{scroll-behavior:smooth}
  body{margin:0;background:linear-gradient(180deg,#0c0f1d,#0f1222 240px);color:var(--ink);
    font-family:var(--sans);line-height:1.6;font-size:16px}
  a{color:var(--accent);text-decoration:none}
  a:hover{text-decoration:underline}
  .wrap{max-width:var(--maxw);margin:0 auto;padding:0 22px}
  header.hero{padding:64px 0 28px;border-bottom:1px solid var(--line)}
  .badge{display:inline-block;font-family:var(--mono);font-size:12px;letter-spacing:.12em;
    text-transform:uppercase;color:var(--accent-2);border:1px solid var(--line);
    padding:5px 11px;border-radius:999px;background:var(--panel)}
  h1{font-size:42px;line-height:1.1;margin:18px 0 10px;letter-spacing:-.02em}
  h2{font-size:26px;margin:46px 0 14px;letter-spacing:-.01em;scroll-margin-top:20px}
  h3{font-size:18px;margin:26px 0 8px}
  .lede{font-size:19px;color:var(--muted);max-width:70ch}
  .grid-toc{display:grid;grid-template-columns:repeat(auto-fit,minmax(210px,1fr));gap:12px;margin:26px 0 6px}
  .toc-card{background:var(--panel);border:1px solid var(--line);border-radius:var(--radius);
    padding:14px 16px;display:block}
  .toc-card:hover{border-color:var(--accent);text-decoration:none}
  .toc-card .n{font-family:var(--mono);color:var(--accent-2);font-size:12px}
  .toc-card .t{display:block;color:var(--ink);font-weight:600;margin-top:3px}
  .panel{background:var(--panel);border:1px solid var(--line);border-radius:var(--radius);
    padding:20px 22px;margin:18px 0}
  .fig{background:var(--panel-2);border:1px solid var(--line);border-radius:var(--radius);
    padding:18px;margin:20px 0;overflow-x:auto}
  .fig svg{display:block;margin:0 auto;max-width:100%;height:auto}
  .figcap{color:var(--muted);font-size:13.5px;text-align:center;margin-top:10px;font-family:var(--mono)}
  pre{background:var(--code);border:1px solid var(--line);border-radius:12px;padding:16px 18px;
    overflow-x:auto;font-family:var(--mono);font-size:13.5px;line-height:1.55;color:#d7dcff}
  code{font-family:var(--mono);font-size:.92em;background:#20243f;padding:1px 6px;border-radius:6px;color:#cfd4ff}
  pre code{background:none;padding:0;color:inherit}
  .step{display:flex;gap:16px;align-items:flex-start;margin:16px 0}
  .step .num{flex:0 0 38px;height:38px;width:38px;border-radius:50%;display:grid;place-items:center;
    background:linear-gradient(135deg,var(--accent),#5b62e0);color:#fff;font-weight:700;font-family:var(--mono)}
  .step .body{flex:1;min-width:0}
  .step h3{margin:4px 0 6px}
  table{border-collapse:collapse;width:100%;margin:14px 0;font-size:14.5px}
  th,td{border:1px solid var(--line);padding:9px 12px;text-align:left;vertical-align:top}
  th{background:var(--panel-2);color:var(--ink);font-weight:600}
  td code{white-space:nowrap}
  .yes{color:var(--green);font-weight:700}
  .no{color:var(--amber);font-weight:700}
  .callout{border-left:4px solid var(--accent);background:var(--panel);border-radius:0 12px 12px 0;
    padding:16px 20px;margin:20px 0}
  .callout.ai{border-left-color:var(--accent-2)}
  .callout h3{margin-top:0}
  .tag{font-family:var(--mono);font-size:11px;padding:2px 8px;border-radius:6px;border:1px solid var(--line)}
  .tag.g{color:var(--amber);border-color:#5a4a1e;background:#241d0c}
  .tag.l{color:var(--accent-2);border-color:#194a52;background:#0c2025}
  footer{border-top:1px solid var(--line);margin-top:56px;padding:26px 0 60px;color:var(--muted);font-size:14px}
  ul.tight{margin:8px 0;padding-left:22px}
  ul.tight li{margin:4px 0}
  .pill-row{display:flex;flex-wrap:wrap;gap:8px;margin:12px 0}
  .pill{font-family:var(--mono);font-size:12.5px;background:var(--panel-2);border:1px solid var(--line);
    border-radius:999px;padding:5px 12px;color:var(--muted)}
  hr{border:none;border-top:1px solid var(--line);margin:40px 0}
</style>
</head>
<body>
<header class="hero"><div class="wrap">
  <span class="badge">AI Workspace Template</span>
  <h1>Set up your project workspace</h1>
  <p class="lede">A reusable, agent-aware development workspace — one shared context for
  Claude&nbsp;Code, Codex, OpenCode, and Gemini. This guide takes you from a fresh clone to a
  working project, whether you're a human or an AI agent.</p>
  <div class="pill-row">
    <span class="pill">Claude Code</span><span class="pill">Codex</span>
    <span class="pill">OpenCode</span><span class="pill">Gemini</span>
    <span class="pill">graphify MCP (core)</span><span class="pill">gh CLI (required)</span><span class="pill">MCP fragments: YouTube (opt-in)</span>
  </div>
</div></header>

<main class="wrap">

  <div class="grid-toc">
    <a class="toc-card" href="#what"><span class="n">01</span><span class="t">What you get</span></a>
    <a class="toc-card" href="#model"><span class="n">02</span><span class="t">The mental model</span></a>
    <a class="toc-card" href="#quickstart"><span class="n">03</span><span class="t">Quick start</span></a>
    <a class="toc-card" href="#global"><span class="n">04</span><span class="t">Global vs local</span></a>
    <a class="toc-card" href="#tracked"><span class="n">05</span><span class="t">Tracked vs ignored</span></a>
    <a class="toc-card" href="#toolchain"><span class="n">06</span><span class="t">Recommended toolchain</span></a>
    <a class="toc-card" href="#agents"><span class="n">07</span><span class="t">For AI agents</span></a>
  </div>

  <!-- ============================================= -->
  <h2 id="what">01 · What you get</h2>
  <p>The template is a coordination layer — not product code. It gives every agent and human a single
  known place to find context, conventions, and active work. Everything project-specific is a
  <code>&lt;…&gt;</code> placeholder or a stub with a header comment, so you fill in, you don't reverse-engineer.</p>

  <div class="fig">
    <svg viewBox="0 0 900 470" role="img" aria-label="Workspace directory structure">
      <style>
        .lbl{font:13px var(--mono,monospace);fill:#cfd4ff}
        .dir{font:13px var(--mono,monospace);fill:#7c83ff;font-weight:700}
        .note{font:11.5px var(--mono,monospace);fill:#a3a8c3}
        .box{fill:#1d2138;stroke:#2b3052;rx:10}
      </style>
      <rect x="20" y="20" width="860" height="430" rx="14" fill="#171a2e" stroke="#2b3052"/>
      <text x="44" y="56" class="dir">&lt;workspace&gt;/</text>

      <text x="64" y="86"  class="lbl">CONTEXT.md</text>
      <text x="300" y="86" class="note">← master context, the front door (read first)</text>
      <text x="64" y="110" class="lbl">CLAUDE.md · AGENTS.md · GEMINI.md</text>
      <text x="420" y="110" class="note">→ symlinks to CONTEXT.md</text>
      <text x="64" y="134" class="lbl">README.md · SPEC.md</text>
      <text x="300" y="134" class="note">human pitch · product intent</text>

      <text x="64" y="170" class="dir">docs/</text>
      <text x="300" y="170" class="note">workspace docs (structure, setup, registries)</text>
      <text x="64" y="194" class="lbl">repo-context/</text>
      <text x="300" y="194" class="note">per-repo navigation + design docs</text>

      <text x="64" y="230" class="dir">skills/</text>
      <text x="300" y="230" class="note">reusable agent workflows (starts empty)</text>
      <text x="64" y="254" class="dir">work/</text>
      <text x="300" y="254" class="note">active project state — survives compaction</text>
      <text x="64" y="278" class="dir">prompt-library/</text>
      <text x="300" y="278" class="note">prompt contracts for repeatable outputs</text>

      <text x="64" y="314" class="dir">repos/</text>
      <text x="300" y="314" class="note">cloned product repos (gitignored)</text>
      <text x="64" y="338" class="dir">references/</text>
      <text x="300" y="338" class="note">cloned third-party repos (gitignored)</text>
      <text x="64" y="362" class="dir">scripts/</text>
      <text x="300" y="362" class="note">setup + validation scripts</text>

      <text x="64" y="398" class="lbl">.env.example · .mcp.json.example</text>
      <text x="420" y="398" class="note">copy → local, gitignored</text>
      <text x="64" y="422" class="lbl">.claude/ · .gemini/ · .opencode/ · opencode.json</text>
      <text x="540" y="422" class="note">per-runtime config</text>
    </svg>
    <div class="figcap">Figure 1 — Top-level layout. Full detail in docs/workspace-structure.md</div>
  </div>

  <!-- ============================================= -->
  <h2 id="model">02 · The mental model</h2>
  <p>One file is the front door. The three agent entrypoints are <strong>symlinks</strong> to it, so every
  runtime reads the exact same context — edit once, all agents see it.</p>

  <div class="fig">
    <svg viewBox="0 0 760 260" role="img" aria-label="Agent entrypoint symlinks point to CONTEXT.md">
      <style>
        .e{fill:#1d2138;stroke:#2b3052}
        .c{fill:#13243a;stroke:#22d3ee}
        .t{font:14px var(--mono,monospace);fill:#e7e9f3;text-anchor:middle}
        .tc{font:15px var(--mono,monospace);fill:#22d3ee;text-anchor:middle;font-weight:700}
        .sub{font:11px var(--mono,monospace);fill:#a3a8c3;text-anchor:middle}
      </style>
      <defs>
        <marker id="arr" markerWidth="9" markerHeight="9" refX="7" refY="3" orient="auto">
          <path d="M0,0 L7,3 L0,6 Z" fill="#7c83ff"/>
        </marker>
      </defs>
      <rect class="e" x="20"  y="20" width="190" height="50" rx="10"/>
      <text class="t" x="115" y="50">CLAUDE.md</text>
      <rect class="e" x="20"  y="105" width="190" height="50" rx="10"/>
      <text class="t" x="115" y="135">AGENTS.md</text>
      <rect class="e" x="20"  y="190" width="190" height="50" rx="10"/>
      <text class="t" x="115" y="220">GEMINI.md</text>

      <rect class="c" x="470" y="95"  width="270" height="70" rx="12"/>
      <text class="tc" x="605" y="128">CONTEXT.md</text>
      <text class="sub" x="605" y="148">single source of truth</text>

      <line x1="210" y1="45"  x2="470" y2="120" stroke="#7c83ff" stroke-width="2" marker-end="url(#arr)"/>
      <line x1="210" y1="130" x2="470" y2="130" stroke="#7c83ff" stroke-width="2" marker-end="url(#arr)"/>
      <line x1="210" y1="215" x2="470" y2="140" stroke="#7c83ff" stroke-width="2" marker-end="url(#arr)"/>
      <text class="sub" x="340" y="70">symlink</text>
    </svg>
    <div class="figcap">Figure 2 — Claude Code, Codex (AGENTS.md), and Gemini all resolve to one file</div>
  </div>

  <!-- ============================================= -->
  <h2 id="quickstart">03 · Quick start</h2>
  <p>Five steps from clone to a working workspace. Steps 1–3 are mechanical; step 4 is where you make it
  <em>your</em> project.</p>

  <div class="fig">
    <svg viewBox="0 0 920 130" role="img" aria-label="Setup flow: clone, bootstrap, configure, fill in, build">
      <style>
        .fb{fill:#1d2138;stroke:#2b3052}
        .ft{font:13px var(--sans,sans-serif);fill:#e7e9f3;text-anchor:middle;font-weight:600}
        .fn{font:11px var(--mono,monospace);fill:#22d3ee;text-anchor:middle}
      </style>
      <defs>
```

</details>


---

<sub>9s</sub>

### `view`

**view the file at /Users/kashif/Developer/experiments/ai-workspace-template/docs/setup-guide.html.**

/Users/kashif/Developer/experiments/ai-workspace-template/docs/setup-guide.html (lines 200-520)

<details>
<summary>243 lines</summary>

```
      <defs>
        <marker id="fa" markerWidth="10" markerHeight="10" refX="7" refY="3" orient="auto">
          <path d="M0,0 L7,3 L0,6 Z" fill="#7c83ff"/>
        </marker>
      </defs>
      <g>
        <rect class="fb" x="10"  y="35" width="150" height="60" rx="12"/>
        <text class="fn" x="85"  y="58">01</text><text class="ft" x="85"  y="78">Clone &amp; re-init</text>
        <rect class="fb" x="200" y="35" width="150" height="60" rx="12"/>
        <text class="fn" x="275" y="58">02</text><text class="ft" x="275" y="78">Bootstrap</text>
        <rect class="fb" x="390" y="35" width="150" height="60" rx="12"/>
        <text class="fn" x="465" y="58">03</text><text class="ft" x="465" y="78">Wire agents</text>
        <rect class="fb" x="580" y="35" width="150" height="60" rx="12"/>
        <text class="fn" x="655" y="58">04</text><text class="ft" x="655" y="78">Fill placeholders</text>
        <rect class="fb" x="770" y="35" width="140" height="60" rx="12" stroke="#34d399"/>
        <text class="fn" x="840" y="58" fill="#34d399">05</text><text class="ft" x="840" y="78">Build</text>
      </g>
      <line x1="160" y1="65" x2="200" y2="65" stroke="#7c83ff" stroke-width="2" marker-end="url(#fa)"/>
      <line x1="350" y1="65" x2="390" y2="65" stroke="#7c83ff" stroke-width="2" marker-end="url(#fa)"/>
      <line x1="540" y1="65" x2="580" y2="65" stroke="#7c83ff" stroke-width="2" marker-end="url(#fa)"/>
      <line x1="730" y1="65" x2="770" y2="65" stroke="#7c83ff" stroke-width="2" marker-end="url(#fa)"/>
    </svg>
    <div class="figcap">Figure 3 — The setup pipeline</div>
  </div>

  <div class="step"><div class="num">1</div><div class="body">
    <h3>Create your workspace from the template</h3>
    <p>On GitHub, click <strong>“Use this template”</strong>, or clone and reset git history:</p>
    <pre><code>git clone https://github.com/&lt;you&gt;/ai-workspace-template.git &lt;project&gt;-workspace
cd &lt;project&gt;-workspace
rm -rf .git &amp;&amp; git init</code></pre>
  </div></div>

  <div class="step"><div class="num">2</div><div class="body">
    <h3>Bootstrap the local files</h3>
    <p>Run the setup script — it runs a dependency preflight, then creates <code>.env</code>, the agent symlinks,
    <code>repos/README.md</code>, and the per-user config copies (idempotent). Add <code>--clone-repos</code> for
    a multi-repo workspace. Missing tools? Follow <a href="runbooks/dependencies.md">runbooks/dependencies.md</a>.</p>
    <pre><code>./scripts/setup.sh                 # creates .env, symlinks, repos/README.md
./scripts/check-workspace-structure.sh   # verify symlinks resolve, dirs present</code></pre>
  </div></div>

  <div class="step"><div class="num">3</div><div class="body">
    <h3>Wire up agents &amp; MCP</h3>
    <p>Copy the per-user config templates (all gitignored), then authenticate. Run the check, then follow
    <a href="runbooks/authentication.md">runbooks/authentication.md</a> for anything missing; per-runtime MCP
    detail is in <code>docs/mcp-setup.md</code>. The YouTube transcript MCP server is workspace-local and
    credential-free; install <code>yt-dlp</code> if you use it.</p>
    <pre><code>cp -n .env.example .env
cp -n .mcp.json.example .mcp.json
cp -n .claude/settings.json.example .claude/settings.local.json
./scripts/check-service-access.sh                  # reports gaps + fix commands
gh auth login                                      # if not already authenticated</code></pre>
  </div></div>

  <div class="step"><div class="num">4</div><div class="body">
    <h3>Make it your project</h3>
    <p>Replace every <code>&lt;…&gt;</code> placeholder and resolve the <code>TODO</code> / “Fill in” comments —
    start with <code>CONTEXT.md</code> (it loads into every agent session). Find what's left:</p>
    <pre><code>grep -rIn --exclude-dir=.git -e '&lt;[a-z-]\+&gt;' -e 'TODO' -e 'Fill in:' .</code></pre>
    <ul class="tight">
      <li><strong>CONTEXT.md</strong> — name, purpose, single- vs multi-repo model</li>
      <li><strong>docs/repos-registry.md</strong> — one entry per product repo</li>
      <li><strong>docs/service-access.md</strong> — your GitHub username; add a section per service</li>
      <li><strong>SPEC.md</strong> — product intent (or delete for a pure coordination layer)</li>
      <li><strong>work/</strong> — prune the maintainer's shipped work history
        (<code>git rm -r work/*/</code>); it's a worked example, not machinery — see
        <a href="template-usage.md">template-usage.md</a> §5</li>
    </ul>
  </div></div>

  <div class="step"><div class="num">5</div><div class="body">
    <h3>Start building</h3>
    <p>Decide on the optional bits: <strong>graphify</strong> is the core MCP server (wired by default;
    it also adds <code>.gemini/settings.json</code> / <code>.opencode/plugins/graphify.js</code>).
    <strong>YouTube transcript</strong> MCP is an opt-in fragment under
    <code>mcp-fragments/</code>, loaded per session — see <code>docs/mcp-setup.md</code>; GitHub goes
    through the required <code>gh</code> CLI (no MCP server). Delete what you don't use.
    Add reusable workflows under <code>skills/</code> and list them in <code>CONTEXT.md</code>.
    The template ships four: <code>checkpoint</code> (session wrap-up), <code>onboard-repo</code>
    (bring a repo in), <code>rlm</code> (query huge contexts), and <code>decision-log</code> —
    capture the <em>why</em> behind a decision (<code>/decision</code>) as an ephemeral note in
    <code>work/&lt;proj&gt;/decisions.md</code>, promoted to a committed ADR under <code>docs/adr/</code>
    for lasting-weight calls. See the <strong>Decision Records</strong> section of <code>CONTEXT.md</code>.
    <strong>Checks:</strong> <code>scripts/run-checks.sh</code> runs every workspace check; on GitHub,
    <code>.github/workflows/checks.yml</code> runs it on each push (delete the file to opt out), and
    <code>git config core.hooksPath scripts/git-hooks</code> opts you in to a pre-commit run of the fast set.</p>
  </div></div>

  <p style="margin-top:18px">Deeper reference: <a href="template-usage.md">docs/template-usage.md</a> ·
  <a href="workspace-setup.md">docs/workspace-setup.md</a> ·
  <a href="workspace-structure.md">docs/workspace-structure.md</a></p>

  <!-- ============================================= -->
  <h2 id="global">04 · Global vs. workspace-local setup</h2>
  <p>Setup splits into two layers. Do the <span class="tag g">GLOBAL</span> layer once per machine; the
  <span class="tag l">LOCAL</span> layer once per clone. The local layer depends on the global one (the MCP
  token and the <code>gh</code> login).</p>

  <div class="fig">
    <svg viewBox="0 0 820 360" role="img" aria-label="Global machine config versus workspace-local files">
      <style>
        .hd{font:14px var(--sans,sans-serif);font-weight:700;text-anchor:middle}
        .it{font:12.5px var(--mono,monospace);fill:#cfd4ff}
        .ds{font:11px var(--mono,monospace);fill:#a3a8c3}
      </style>
      <rect x="20"  y="20" width="370" height="320" rx="14" fill="#241d0c" stroke="#5a4a1e"/>
      <text class="hd" x="205" y="48" fill="#fbbf24">GLOBAL — once per machine</text>
      <text class="ds" x="40" y="70">~/ home directory · OS keychain · never in git</text>

      <text class="it" x="40" y="104">agent CLIs on PATH</text>
      <text class="ds" x="40" y="120">claude · codex · opencode · gemini</text>
      <text class="it" x="40" y="148">gh CLI login (required)</text>
      <text class="ds" x="40" y="164">all GitHub operations · gh auth status</text>
      <text class="it" x="40" y="236">~/.codex/config.toml</text>
      <text class="ds" x="40" y="252">Codex MCP registration (optional)</text>
      <text class="it" x="40" y="280">~/.gemini/settings.json</text>
      <text class="ds" x="40" y="296">Gemini MCP registration (optional)</text>
      <text class="it" x="40" y="324">OS keychain</text>

      <rect x="430" y="20" width="370" height="320" rx="14" fill="#0c2025" stroke="#194a52"/>
      <text class="hd" x="615" y="48" fill="#22d3ee">LOCAL — once per clone</text>
      <text class="ds" x="450" y="70">inside the repo · copy the .example files</text>

      <text class="it" x="450" y="104">.env.example → .env</text>
      <text class="ds" x="450" y="120">non-secret identifiers only</text>
      <text class="it" x="450" y="148">.mcp.json.example → .mcp.json</text>
      <text class="ds" x="450" y="164">Claude Code project MCP</text>
      <text class="it" x="450" y="192">.claude/settings.json.example</text>
      <text class="ds" x="450" y="208">→ .claude/settings.local.json (permissions)</text>
      <text class="it" x="450" y="236">./scripts/setup.sh</text>
      <text class="ds" x="450" y="252">symlinks · repos/README.md · clones</text>
      <text class="it" x="450" y="280">check-service-access.sh</text>
      <text class="ds" x="450" y="296">→ .service-access.local.json (generated)</text>
      <text class="it" x="450" y="324">CONTEXT.md + symlinks (tracked, ready)</text>

      <path d="M390,180 C410,180 410,180 430,180" stroke="#7c83ff" stroke-width="2" fill="none"/>
      <text class="ds" x="410" y="172" text-anchor="middle" fill="#7c83ff">feeds</text>
    </svg>
    <div class="figcap">Figure 4 — Two setup layers. Authoritative tables: docs/workspace-setup.md</div>
  </div>

  <!-- ============================================= -->
  <h2 id="tracked">05 · What's tracked vs. gitignored</h2>
  <p>Nothing secret ever enters git. Credentials stay in the keychain; the repo holds only templates and
  non-secret identifiers. Full table in <code>docs/workspace-structure.md → “Gitignored vs. Checked In”</code>.</p>

  <table>
    <thead><tr><th>Path</th><th>In git?</th><th>Why</th></tr></thead>
    <tbody>
      <tr><td><code>CONTEXT.md</code> + CLAUDE/AGENTS/GEMINI symlinks</td><td class="yes">Yes</td><td>Agent entrypoints</td></tr>
      <tr><td><code>docs/ skills/ work/ prompt-library/ scripts/</code></td><td class="yes">Yes</td><td>Shared docs, skills, state, tooling</td></tr>
      <tr><td><code>opencode.json .opencode/ .gemini/settings.json .claude/settings.json</code></td><td class="yes">Yes</td><td>Shared per-runtime config + hook wiring</td></tr>
      <tr><td><code>*.example</code> (env, mcp, claude settings)</td><td class="yes">Yes</td><td>Templates to copy locally</td></tr>
      <tr><td><code>repos/README.md references/README.md</code></td><td class="yes">Yes</td><td>Registries (repos/README is a symlink)</td></tr>
      <tr><td><code>.env .mcp.json .claude/settings.local.json</code></td><td class="no">No</td><td>User-specific / may hold paths</td></tr>
      <tr><td><code>repos/* references/*</code> (except READMEs)</td><td class="no">No</td><td>Separate cloned repos</td></tr>
      <tr><td><code>.service-access.local.json</code></td><td class="no">No</td><td>Machine credential cache</td></tr>
      <tr><td><code>graphify-out/ temp/ tmp/ .DS_Store</code></td><td class="no">No</td><td>Locally regenerated / scratch</td></tr>
    </tbody>
  </table>

  <!-- ============================================= -->
  <h2 id="toolchain">06 · Recommended toolchain</h2>
  <p>Optional external tools this workflow assumes. They're <strong>global / per-user</strong> — installed
  once per machine, never committed to the repo — except for two that also need a <strong>per-repo</strong>
  step. Full setup in <a href="recommended-tooling.md">docs/recommended-tooling.md</a>.</p>

  <div class="fig">
    <svg viewBox="0 0 820 300" role="img" aria-label="Global tools versus per-repo setup steps">
      <style>
        .hh{font:13.5px var(--sans,sans-serif);font-weight:700;text-anchor:middle}
        .ii{font:12.5px var(--mono,monospace);fill:#cfd4ff}
        .dd{font:10.5px var(--mono,monospace);fill:#a3a8c3}
      </style>
      <rect x="20" y="20" width="470" height="260" rx="14" fill="#241d0c" stroke="#5a4a1e"/>
      <text class="hh" x="255" y="46" fill="#fbbf24">GLOBAL — once per machine</text>
      <text class="ii" x="40" y="78">Status line</text>
      <text class="dd" x="40" y="94">ccstatusline · ~/.config + ~/.claude/settings.json</text>
      <text class="ii" x="40" y="120">superpowers + plugins</text>
      <text class="dd" x="40" y="136">claude plugin install …@claude-plugins-official</text>
      <text class="ii" x="40" y="162">Matt Pocock skills</text>
      <text class="dd" x="40" y="178">tdd · diagnosing-bugs · triage · to-tickets · … (agent-context)</text>
      <text class="ii" x="40" y="204">Karpathy principles</text>
      <text class="dd" x="40" y="220">4 principles already in CONTEXT.md · karpathy-examples</text>
      <text class="ii" x="40" y="246">graphify CLI</text>
      <text class="dd" x="40" y="262">uv tool install "graphifyy[mcp]" · yt-dlp for YouTube MCP</text>

      <rect x="510" y="20" width="290" height="260" rx="14" fill="#0c2025" stroke="#194a52"/>
      <text class="hh" x="655" y="46" fill="#22d3ee">PER-REPO step</text>
      <text class="ii" x="528" y="84">Matt Pocock config</text>
      <text class="dd" x="528" y="100">run setup-matt-pocock-skills</text>
      <text class="dd" x="528" y="116">→ ## Agent skills block +</text>
      <text class="dd" x="528" y="132">  docs/agents/*.md</text>
      <text class="ii" x="528" y="168">graphify graph</text>
      <text class="dd" x="528" y="184">/graphify   (build graphify-out/)</text>
      <text class="dd" x="528" y="200">graphify update .   (refresh)</text>
      <text class="dd" x="528" y="232">↳ template already ships the</text>
      <text class="dd" x="528" y="248">  Gemini hook + OpenCode plugin</text>
    </svg>
    <div class="figcap">Figure 5 — Global install vs. per-repo setup. Detail in docs/recommended-tooling.md</div>
  </div>

  <p>Quick reference:</p>
  <pre><code># status line
npm install -g ccstatusline           # install once; wire statusLine in ~/.claude/settings.json

# plugins (official marketplace is built in)
claude plugin install superpowers@claude-plugins-official

# graphify
uv tool install "graphifyy[mcp]"
/graphify                             # build the graph for THIS repo → graphify-out/
graphify update .                     # refresh after code changes

# YouTube transcript MCP
yt-dlp --version                      # install via brew / apt / winget if missing
scripts/mcp/youtube-transcript.sh     # workspace-local stdio server

# skill repos — managed via agent-context (clone, then link with agent-context-sync)
git clone https://github.com/mattpocock/skills.git ~/Developer/references/mattpocock-skills
git clone https://github.com/ForrestChang/andrej-karpathy-skills.git ~/Developer/references/karpathy-claude-md
agent-context-sync                    # links new skills into ~/.config/agent-context/skills

# Matt Pocock per-repo config (before to-tickets / triage / to-spec)
# run the setup-matt-pocock-skills skill in the repo</code></pre>

  <!-- ============================================= -->
  <h2 id="agents">07 · For AI agents</h2>
  <div class="callout ai">
    <h3>If you are an AI agent setting this up</h3>
    <ul class="tight">
      <li><strong>Read <code>CONTEXT.md</code> first</strong> — it's the front door and loads the project's
      conventions and the “Agent Coding Principles” / “Agent Context Discipline” rules.</li>
      <li><strong>Treat <code>docs/workspace-structure.md</code> as the spec.</strong> Its
      <em>“Agent Bootstrap Instructions”</em> section is a step-by-step procedure for scaffolding or
      extending a workspace — files to create, stub-header format, and post-scaffold verification checks.</li>
      <li><strong>Confirm preconditions before creating files</strong> — workspace name, repo list,
      editors/runtimes, and external services. Don't invent repo names or clone URLs.</li>
      <li><strong>Persist intermediate state to <code>work/&lt;project&gt;/</code></strong> so it
      survives context compaction — not to conversation memory.</li>
      <li><strong>Disk is the source of truth.</strong> Re-read files before asserting facts; verify
      symlinks resolve and scripts are executable after scaffolding.</li>
    </ul>
  </div>

  <div class="callout">
    <h3>Verify before you call it done</h3>
    <pre><code>gh auth status                                    # global: GitHub auth
claude mcp list                                   # local:  core MCP (graphify) visible
scripts/mcp/youtube-transcript.sh                 # local:  starts YouTube MCP (opt-in fragment)
./scripts/check-workspace-structure.sh            # local:  symlinks + dirs OK</code></pre>
  </div>

</main>

<footer><div class="wrap">
  ai-workspace-template · setup guide · generated for human + agent onboarding.<br>
  Source docs: <a href="workspace-structure.md">workspace-structure.md</a> ·
  <a href="workspace-setup.md">workspace-setup.md</a> ·
  <a href="template-usage.md">template-usage.md</a> ·
  <a href="recommended-tooling.md">recommended-tooling.md</a> ·
  <a href="mcp-setup.md">mcp-setup.md</a> ·
  <a href="service-access.md">service-access.md</a> ·
  <a href="runbooks/README.md">runbooks/</a><br>
  Template maintainers: <a href="template-workspace-backlog.html">template-workspace-backlog.html</a>
  (review findings + how to keep them updated)
</div></footer>

</body>
</html>
```

</details>


---

<sub>1m 4s</sub>

### `create`

**create a new file at /Users/kashif/Developer/experiments/ai-workspace-template/work/html-kit/prototype/xrt/copilot/setup-guide.html.**

/Users/kashif/Developer/experiments/ai-workspace-template/work/html-kit/prototype/xrt/copilot/setup-guide.html

```
Created file /Users/kashif/Developer/experiments/ai-workspace-template/work/html-kit/prototype/xrt/copilot/setup-guide.html with 20100 characters
```


---

<sub>1m 4s</sub>

### `bash`

**cd /Users/kashif/Developer/experiments/ai-workspace-template/work/html-kit/prototype; grep -cE '<style|style=|fill=|stroke=|font-[a-z]+=|<defs' xrt/copilot/setup-guide.html; grep '<svg' xrt/copilot/setup-guide.html | grep -vc 'class="diagram"'; ./check-links.sh xrt/copilot/setup-guide.html; ./render-check.sh xrt/copilot/setup-guide.html xrt/copilot/shots 2>&1 | tail -15; ls xrt/copilot/shots**

$ cd /Users/kashif/Developer/experiments/ai-workspace-template/work/html-kit/prototype; grep -cE '<style|style=|fill=|stroke=|font-[a-z]+=|<defs' xrt/copilot/setup-guide.html; grep '<svg' xrt/copilot/setup-guide.html | grep -vc 'class="diagram"'; ./check-links.sh xrt/copilot/setup-guide.html; ./render-check.sh xrt/copilot/setup-guide.html xrt/copilot/shots 2>&1 | tail -15; ls xrt/copilot/shots

```
0
0
OK xrt/copilot/setup-guide.html: 24 href/src checked
./render-check.sh: line 101: 96617 Abort trap: 6           "$CHROME" "${flags[@]}" --dump-dom "file://$frame" 2> /dev/null
<shellId: 1 completed with exit code 0>
```


---

<sub>1m 6s</sub>

### `bash`

**cd /Users/kashif/Developer/experiments/ai-workspace-template/work/html-kit/prototype; ./render-check.sh xrt/copilot/setup-guide.html xrt/copilot/shots; echo rc=$?; ls xrt/copilot/shots; sed -n 85,105p render-check.sh**

$ cd /Users/kashif/Developer/experiments/ai-workspace-template/work/html-kit/prototype; ./render-check.sh xrt/copilot/setup-guide.html xrt/copilot/shots; echo rc=$?; ls xrt/copilot/shots; sed -n 85,105p render-check.sh

<details>
<summary>23 lines</summary>

```
./render-check.sh: line 101: 98576 Abort trap: 6           "$CHROME" "${flags[@]}" --dump-dom "file://$frame" 2> /dev/null
rc=1
    end = src.index('>', pos)
    tag = src[pos:end]
    close = {'<f': '</figure>', '<p': '</pre>', '<s': '</svg>'}[tag[:2]]
    stop = src.index(close, pos)
    # keep only the target's mermaid block live, so a hidden one cannot break the run
    off = lambda t: re.sub(r'(<pre\b[^>]*class="[^"]*)\bmermaid\b', r'\1mermaid-off', t)
    s = off(src[:pos]) + tag + ' data-rc' + src[end:stop] + off(src[stop:])
    s = s.replace('</head>', css + '</head>', 1).replace('</body>', js + '</body>', 1)
    slide = len(re.findall(r'<section\b[^>]*class="[^"]*\bslide\b', src[:pos]))
    f = os.path.join(tmp, f'.rc-{stem}-fig{n}.html')
    open(f, 'w', encoding='utf-8').write(s)
    print(f'{n}\t{f}\t{"#%d" % slide if slide else ""}')
PY
[ -s "$list" ] || { echo "no figures found in $page" >&2; exit 1; }

frame="$dir/.rc-$stem-frame.html"
shot() { # <file-url> <width> <height> <scheme> [screenshot-path]
  printf '<!doctype html><body style="margin:0"><iframe src="%s" width="%s" height="%s" style="border:0;display:block"></iframe><script>addEventListener("message",e=>document.body.dataset.rch=e.data)</script>' \
    "$1" "$2" "$3" > "$frame"
  local win=$(( $2 > 500 ? $2 : 500 ))
  local flags=(--headless=new --disable-gpu --hide-scrollbars --force-prefers-reduced-motion
<shellId: 2 completed with exit code 0>
```

</details>


---

<sub>1m 9s</sub>

### `bash`

**cd /Users/kashif/Developer/experiments/ai-workspace-template/work/html-kit/prototype; grep -n 'CHROME' render-check.sh | head; sed -n 105,115p render-check.sh**

$ cd /Users/kashif/Developer/experiments/ai-workspace-template/work/html-kit/prototype; grep -n 'CHROME' render-check.sh | head; sed -n 105,115p render-check.sh

<details>
<summary>20 lines</summary>

```
27:# Chrome lookup: $CHROME if set (must be executable), else the macOS Google Chrome app, else the
34:if [ -n "${CHROME:-}" ]; then
35:  [ -x "$CHROME" ] || command -v "$CHROME" >/dev/null || { echo "CHROME=$CHROME is not an executable" >&2; exit 2; }
36:elif [ -x "$mac_chrome" ]; then CHROME=$mac_chrome
38:  for c in $names; do command -v "$c" >/dev/null && { CHROME=$c; break; }; done
39:  [ -n "${CHROME:-}" ] || { echo "Chrome not found: tried \$CHROME, $mac_chrome, and $names on PATH." \
40:    "Install one (e.g. apt install chromium) or set CHROME=/path/to/chrome." >&2; exit 2; }
109:  if [ -n "${5:-}" ]; then "$CHROME" "${flags[@]}" --screenshot="$5" "file://$frame" >/dev/null 2>&1
110:  else "$CHROME" "${flags[@]}" --dump-dom "file://$frame" 2>/dev/null; fi
  local flags=(--headless=new --disable-gpu --hide-scrollbars --force-prefers-reduced-motion
    --allow-file-access-from-files
    --blink-settings=preferredColorScheme="$4" --window-size="$win,$3" --virtual-time-budget=15000)
  [ "$(id -u)" = 0 ] && flags+=(--no-sandbox)
  if [ -n "${5:-}" ]; then "$CHROME" "${flags[@]}" --screenshot="$5" "file://$frame" >/dev/null 2>&1
  else "$CHROME" "${flags[@]}" --dump-dom "file://$frame" 2>/dev/null; fi
}

while IFS=$'\t' read -r n file hash; do
  url="file://$file$hash"
  for w in 1280 390; do
<shellId: 3 completed with exit code 0>
```

</details>


---

<sub>1m 11s</sub>

### `bash` — Failed

**"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless=new --disable-gpu --dump-dom about:blank 2>&1 | tail -5**

$ "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless=new --disable-gpu --dump-dom about:blank 2>&1 | tail -5

```
Permission denied because no interactive user response was available. Retry in an interactive session so the user can approve it, or try an alternative that does not require this permission.
```


---

<sub>1m 19s</sub>

### Copilot

Chrome is blocked here, so no shots. Writing the summary.

---

<sub>1m 19s</sub>

### `create`

**create a new file at /Users/kashif/Developer/experiments/ai-workspace-template/work/html-kit/prototype/xrt/copilot/summary.md.**

/Users/kashif/Developer/experiments/ai-workspace-template/work/html-kit/prototype/xrt/copilot/summary.md

```
Created file /Users/kashif/Developer/experiments/ai-workspace-template/work/html-kit/prototype/xrt/copilot/summary.md with 2182 characters
```


---

<sub>1m 23s</sub>

### Copilot

I rebuilt the setup guide on the kit, but check 4 (the render check) did not run, so I haven't seen how any figure looks. The page isn't done until someone who can run Chrome runs `render-check.sh` and views the shots.

- **Check results:**
  - Check 1 (forbidden-pattern grep) printed 0.
  - Check 2 (non-diagram SVG grep) printed 0.
  - Check 3 (`check-links.sh`) passed: 24 links checked.
  - Check 4 failed: headless Chrome aborted, and the sandbox then refused to launch it directly. No PNGs were written.
- **Figures at risk:** Figures 2 and 3 are hand-drawn SVGs sized by the width rules, not by eye.
- **Figure changes:** Following the diagram rules, Figure 1 (folder layout) became a code block, and Figures 4 and 5 (two-column global/local lists) became card grids. Figure 4's "feeds" arrow is now a short line on each card.
- **Other choices:** The page uses no elements or classes beyond the rule sheet. The other judgement calls (tag tones, Figure 3 wrapped into two rows, the link lists I gave short descriptions) are in `summary.md`.

Files are in `work/html-kit/prototype/xrt/copilot/`:
- `setup-guide.html`
- `summary.md`

---

<sub>Generated by [GitHub Copilot CLI](https://github.com/features/copilot/cli)</sub>
