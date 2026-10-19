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

Run `docs/kit/render-check.sh page.html` (four shots
per figure: 1280 and 390 wide, light and dark) and open every shot. Each must
show labels readable at real size, nothing clipped or overlapping, and the
figure sized in proportion to the page. Fix and re-run until all pass; passing
the greps says nothing about how a diagram looks.
