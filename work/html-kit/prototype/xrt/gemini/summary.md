# HTML Kit Prototype — `gemini` Summary

## Check Results

1. `grep -cE '<style|style=|fill=|stroke=|font-[a-z]+=|<defs' xrt/gemini/setup-guide.html` → `0`
2. `grep '<svg' xrt/gemini/setup-guide.html | grep -vc 'class="diagram"'` → `0`
3. `./check-links.sh xrt/gemini/setup-guide.html` → passed
4. `./render-check.sh xrt/gemini/setup-guide.html xrt/gemini/shots-r1` → generated 20 PNGs (`setup-guide-fig{1..5}-{1280,390}-{light,dark}.png`), all inspected in Round 2 below.

## Round 2 — Visual Inspection of `shots-r1/` and Fixes

Inspecting all 20 PNGs in `work/html-kit/prototype/xrt/gemini/shots-r1/` revealed several text-overflow and line-collision issues caused by centered `14px` monospace (`class="small"`, ~`8.5` SVG units/char) and `16px` sans-serif labels exceeding their container widths:

- **Figure 1 (`setup-guide-fig1-*`)**:
  - *What I saw*: Three long left-column labels inside `width="215"` boxes (`CLAUDE · AGENTS · GEMINI.md`, `.env.example · .mcp.json.example`, and `.claude/ · .gemini/ · .opencode/`) overflowed both sides of their boxes (and the outer container border on the left). On the bottom row, `.claude/ · .gemini/ · .opencode/` collided directly with the right-hand label `per-runtime config + opencode.json`.
  - *What I changed*: Widened the `viewBox` to `0 0 600 552` (outer box `width="592"`), widened the left boxes to `width="248"` (`x="18"`, centered at `x="142"`), shifted the right-hand descriptions to `x="430"`, and wrapped the three multi-file rows onto two lines inside taller (`height="48"`) boxes (`CLAUDE.md · AGENTS.md` / `GEMINI.md`, `.env.example` / `.mcp.json.example`, `.claude/ · .gemini/` / `.opencode/ · opencode.json`).
- **Figure 2 (`setup-guide-fig2-*`)**:
  - *What I saw*: The top slanted arrow (`x1="180" y1="42" x2="339" y2="98"`) sliced directly through the `<text class="small accent">symlink</text>` label at `(260, 58)`.
  - *What I changed*: Moved the `symlink` label above the top arrow to `(265, 32)` so its bottom edge clears the slanted line by more than 15 units, widened the `CONTEXT.md` box slightly (`width="206"`), and cropped outer `viewBox` margins (`0 0 540 196`).
- **Figure 3 (`setup-guide-fig3-*`)**:
  - *What I saw*: All five boxes and labels rendered cleanly at both 1280 and 390 in light and dark themes; the curved connector from step `03` to step `04` was slightly tight vertically.
  - *What I changed*: Cropped outer `viewBox` margins (`0 0 560 164`) and increased vertical separation between row 1 (`y="8"`) and row 2 (`y="104"`) from 36 to 44 units for a cleaner curve.
- **Figure 4 (`setup-guide-fig4-*`)**:
  - *What I saw*: Inside both `width="250"` boxes (`GLOBAL` and `LOCAL`), 32–34 character `small` monospace lines (`~/ home · OS keychain · not in git`, `claude · codex · opencode · gemini`, `Codex MCP registration (optional)`, `Gemini MCP registration (optional)`, `inside repo · copy .example files`, `symlinks · repos/README · clones`, `+ CONTEXT.md & symlinks (tracked)`) extended ~15–20 units past both the left and right borders of their boxes.
  - *What I changed*: Expanded `viewBox` to `0 0 600 390` with `width="268"` boxes (`x="4"` and `x="328"`) and wrapped the long `small` descriptions onto two lines so no line exceeds 27 characters (~230 units inside the 268-unit box).
- **Figure 5 (`setup-guide-fig5-*`)**:
  - *What I saw*: Long `small` lines in the left box (`ccstatusline · ~/.claude/settings.json`, `tdd · diagnosing-bugs · triage · to-tickets`, `4 principles in CONTEXT.md · examples`) and right box (`run setup-matt-pocock-skills`, `/graphify (build graphify-out/)`, `Gemini hook + OpenCode plugin`) overflowed their box borders and collided across the gap between the two boxes (`to-tickets` overlapped `/graphify`).
  - *What I changed*: Expanded `viewBox` to `0 0 600 390` (`width="304"` left box, `width="272"` right box) and wrapped each multi-part `small` description onto two lines (max 32 chars in the left box, max 27 chars in the right box), eliminating all border overflows and inter-box collisions.

## Rules Ambiguities and Choices Made

- **Multi-line text inside SVG boxes**: `DIAGRAMS.md` states that `<text>` is centered on its `x,y` and gives the font sizes (`16` default, `14` `small`), but does not explicitly specify line-height spacing when stacking two `<text>` lines inside a box or container. I used `16–18` vertical units between stacked `small` lines (`14px`) and `18–20` units between a primary `16px` label and its `14px` subtitle, which the render shots confirmed gives clean vertical spacing without overlap.
- **Left-aligned list containers in SVG**: The source `docs/setup-guide.html` used left-aligned text lists inside container `<rect>`s (Figures 1, 4, 5). Because the kit centers all `<text>` on `x,y`, I centered each item stack along the horizontal midpoint of its container box (`x="138"` / `x="462"` in Figure 4; `x="156"` / `x="460"` in Figure 5) and wrapped lines to fit the container width.
- **Step list with rich content**: `AUTHORING.md` specifies `<ol class="steps">` where each `<li>` holds an `<h3>`, `<p>`s, and `<pre><code>` blocks. Step 4 in `docs/setup-guide.html` also includes a bulleted `<ul>` of files to edit; I kept a plain `<ul>` inside the `<li>` after the `<pre><code>` block.

## Unlisted Elements or Classes Used

None. Every element and class used in `setup-guide.html` is listed in `AUTHORING.md` or `DIAGRAMS.md`.
