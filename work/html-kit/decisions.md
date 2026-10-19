# html-kit — decision notes

## 2026-10-18 — Verdict on the kit experiment: adjust, diagrams are a hard requirement
**Chose:** Adjust and re-measure. Hand-drawn inline SVG becomes a supported diagram path in the kit (themed through kit classes and CSS variables, so dark mode still works); Mermaid stays as the cheap default for simple flowcharts. Also add a coloured `.rows` component for ladders, fix the AUTHORING.md gaps, then rebuild a second page before a final verdict.
**Because:** The user said good diagrams for human consumption are key. The session-3 experiment showed Mermaid loses spatial layouts (the six-stage ring) and renders dense graphs small and tangled (the eight-stage backup graph); that regression is not acceptable for human-facing pages.
**Rejected:** Adopt as-is with Mermaid only — diagram quality loss; Drop — the 63% size saving and free dark mode on text pages are worth keeping, and the diagram problem has a fix inside the kit.
**Blast radius:** work/html-kit/prototype/ (kit.css, AUTHORING.md, the rebuilt deck, a second rebuilt page, RESULTS.md).
**Promote?:** maybe — if the kit is adopted into the template, the "SVG allowed but themed" rule is a lasting authoring convention.

## 2026-10-18 — Diagrams must render well in the browser, checked visually
**Chose:** Every diagram (Mermaid or hand-drawn SVG) is accepted only after it is seen rendered in the HTML page: screenshots at desktop (1280 wide) and phone (390 wide), in light and dark; labels readable at real size (no tiny text), nothing clipped or overlapping, diagram sized in proportion to the page. The kit and AUTHORING.md must make this the default outcome, and the authoring checklist must include the render check.
**Because:** The user asked that diagrams render well in HTML. Passing the grep checks says nothing about how a diagram looks; the setup-guide test passed every check while its Mermaid diagrams rendered tiny.
**Rejected:** Grep-only checks — they missed the tiny-Mermaid problem; checking desktop light only — phone width and dark mode are where hand-placed labels clip or lose contrast.
**Blast radius:** work/html-kit/prototype/kit/kit.css (Mermaid and diagram sizing, figure layout), AUTHORING.md (render check), RESULTS.md (screenshots per diagram).
**Promote?:** maybe — together with the hand-drawn SVG note, if the kit is adopted.
