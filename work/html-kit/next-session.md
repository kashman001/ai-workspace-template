# Catchup prompt — html-kit (paste into a new agent session)

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover. Past-tense provenance lives in `handoff.md`.
> Convention: docs/work-directory-conventions.md.

## Mission

**Reopened (s10b, 2026-10-21) for backlog card L103** — one-session fix, no plan.
Move `scripts/build-guide-html.sh` onto the kit: emit the kit skeleton
(`kit/kit.css` + `kit/kit.js`, `body.doc`, `<main>`, one `<section>` per `##`),
drop the inline `<style>`, keep the `source-md-sha1` head comment (read by
`check-workspace-structure.sh`). Test first: a `scripts/tests/` case that fails on
today's output (has `<style`, no kit link). Done = output passes AUTHORING.md's
greps, `docs/kit/check-links.sh`, and a viewed `render-check.sh` shot; L103 resolved
to the archive. The kit lives in `docs/kit/`; decision TADR-0015.

**Already done (s10b, uncommitted session, committed at hand-off):** red→green test
`scripts/tests/test-build-guide-html.sh` (11/11); builder rewritten to a pandoc
template on the kit (`--section-divs`, highlighting off with a pre-3.8 fallback,
`style=` stripped). **Remaining, in order:**
1. `bash scripts/tests/test-build-guide-html.sh` → expect `PASS=11 FAIL=0`.
2. `scripts/build-guide-html.sh` on the real doc; run AUTHORING.md's "Check before
   handing back" greps on `docs/workspace-structure.html`; `docs/kit/check-links.sh`.
3. Pandoc's own markup may use elements the kit doesn't list (e.g. the Markdown's
   `## Contents` list is a plain `<ul>` now, not `nav.toc`). Plain semantic HTML is
   allowed (rule 4); note what you saw.
4. `docs/kit/render-check.sh docs/workspace-structure.html`; open the shots, light and dark.
5. `bash scripts/check-workspace-structure.sh` (hash freshness) and `scripts/run-checks.sh`.
6. Resolve L103 (`Fixed:` note, card to the archive — targeted grep edits); ledger
   block 11 in `handoff.md`; checkpoint. Never push `main`.

<!-- plan:begin position -->
Position: plan 04-adopt, closed, wave 3 of 3, done 7/7, doing 0, todo 0, blocked 0, dropped 0, sessions 2.
Frontier: none. Remaining: 0 of 7.
<!-- plan:end position -->

## Read first

- Read `handoff.md` top block (session 10) first.

## Constraints already decided (do not re-litigate)

- HTML stays the source of truth for human-facing pages; agent-agnostic plain files.
- Pages with figures need a render check viewed by a runtime with Chrome.
- Backlog HTML pages are not converted.
