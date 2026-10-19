# Setup guide rebuild summary

- Forbidden-style grep: passed (`0`).
- SVG-class grep: passed (`0`).
- Link check: passed (`OK`, 24 `href`/`src` values checked).
- Render check: blocked. `./render-check.sh xrt/codex/setup-guide.html xrt/codex/shots` aborted in Chrome’s `--dump-dom` invocation twice (`Abort trap: 6`), before it wrote any PNGs, so no shots could be opened for visual inspection.

I initially used the source page’s custom visual patterns as a content map; the final page replaces them with the kit’s document, TOC, steps, callouts, tags, table, code block, and figure patterns. I also re-pointed every source-relative link from `xrt/codex/` to `../../../../../docs/`.

The rules do not prescribe a visual equivalent for the source’s pill row or coloured table yes/no cells. I used neutral/semantic kit tags for the runtime/tool labels and plain table text for yes/no values. No unlisted classes or elements were used.

## Round 2

I opened all 20 supplied renders: five figures at 390px and 1280px in both light and dark themes. Figure 2 was generally sound, but its right-hand caption clipped at the wide size. Figures 1, 4, and 5 had severe text overlap because their SVG text was positioned as though SVG coordinates were left-aligned, while the kit centers text. Figure 3’s two-line labels overlapped their boxes. The same failures were present in both themes and widths; figures 4 and 5 were especially unreadable on mobile.

I re-centered and vertically spaced the remaining SVG text, widened Figure 2’s destination box, and made the Figure 3 boxes tall enough for their two-line labels. I replaced the two dense two-column SVG inventories (Figures 4 and 5) with equivalent captioned kit card grids, which reflow on small screens and preserve every listed setup/toolchain item without overlap. I did not run `render-check.sh`, as directed. Final forbidden-style grep: `0`; final SVG-class grep: `0`; final link check: `OK` (24 `href`/`src` values checked).
