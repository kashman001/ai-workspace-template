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
