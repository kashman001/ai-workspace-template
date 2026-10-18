# html-kit — decision notes

## 2026-10-18 — Verdict on the kit experiment: adjust, diagrams are a hard requirement
**Chose:** Adjust and re-measure. Hand-drawn inline SVG becomes a supported diagram path in the kit (themed through kit classes and CSS variables, so dark mode still works); Mermaid stays as the cheap default for simple flowcharts. Also add a coloured `.rows` component for ladders, fix the AUTHORING.md gaps, then rebuild a second page before a final verdict.
**Because:** The user said good diagrams for human consumption are key. The session-3 experiment showed Mermaid loses spatial layouts (the six-stage ring) and renders dense graphs small and tangled (the eight-stage backup graph); that regression is not acceptable for human-facing pages.
**Rejected:** Adopt as-is with Mermaid only — diagram quality loss; Drop — the 63% size saving and free dark mode on text pages are worth keeping, and the diagram problem has a fix inside the kit.
**Blast radius:** work/html-kit/prototype/ (kit.css, AUTHORING.md, the rebuilt deck, a second rebuilt page, RESULTS.md).
**Promote?:** maybe — if the kit is adopted into the template, the "SVG allowed but themed" rule is a lasting authoring convention.
