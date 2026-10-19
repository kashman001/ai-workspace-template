# Catchup prompt — html-kit (paste into a new agent session)

We're resuming html-kit. Works in any runtime (Claude Code, Codex, Gemini,
OpenCode) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover. Past-tense provenance lives in `handoff.md`.
> Convention: docs/work-directory-conventions.md.

## Mission

The user chose **adopt** (`decisions.md` → "Adopt the HTML kit, small first
step" — the scope is there; follow it exactly). Carry it out: Copilot CLI
cross-runtime test, four rule fixes, kit into `docs/kit/`, setup guide
converted, docs/backlog/ADR updated. Plans 01–03 are closed; no plan is open.

## First actions

1. `scripts/context-budget.sh register --project html-kit`
2. Make plan `04-adopt` with the `plans` skill (`skills/plans/SKILL.md`), nodes
   roughly:
   - **Copilot CLI test** — same brief `prototype/xrt/brief.md`, RT=`copilot`,
     sandboxed/approval-limited like Codex was (unsandboxed or
     `--allow-all`-style launches are denied by Claude Code auto mode — if
     denied, stop that node and leave the question for the user). Two rounds:
     you run `render-check.sh` and view every shot (contact sheet: see the
     Session 8 learning in `handoff.md`), then give it the shots. Add a
     Copilot column to RESULTS "Session 8"-style.
   - **Four rule fixes** in `AUTHORING.md`/`DIAGRAMS.md` (list:
     `prototype/RESULTS.md` → "Rule changes this suggests"). Re-run greps on
     `kit-sample.html`.
   - **Move to `docs/kit/`**: `kit/kit.css`, `kit/kit.js`, `AUTHORING.md`,
     `DIAGRAMS.md`, `check-links.sh`, `render-check.sh`, `kit-sample.html`;
     fix paths inside them (render-check default out-dir, sample's kit path).
   - **Convert `docs/setup-guide.html`** from `prototype/setup-guide.html`
     (kit path `kit/`, links re-pointed); greps, check-links, render-check,
     view every shot.
   - **Document**: `docs/README.md` index, `docs/workspace-structure.md`,
     CONTEXT.md one-liner only if needed; template backlog card per CONTEXT.md
     "Template Backlog"; promote the decision to an ADR (`decision-log`
     promote, with the "SVG allowed but themed" + render-check notes).
   - reconcile.
3. Work the plan; commit per node, staging only paths you touched (other
   sessions share this checkout).

**No human present:** do everything; if the Copilot node is blocked by a
permission denial, mark it blocked and carry on with the rest.

## Read these first, in order

1. `work/html-kit/handoff.md` — top block (session 8)
2. `work/html-kit/decisions.md` — the last entry
3. `work/html-kit/prototype/RESULTS.md` — "Session 8" only

## Do NOT reload

- Codex/Gemini runs: done, results in RESULTS Session 8.
- Gemini CLI: free tier refused; Antigravity `agy` works (edit-only, no shell).
- The adopt/drop question: settled — adopt.
- Mac 500px crop on some 390 shots: known, harmless; ignore.

## Constraints already decided (do not re-litigate)

- HTML stays the source of truth for human-facing pages.
- Agent-agnostic: plain CSS/JS files plus docs, no runtime-specific skill.
- Diagram pages are reviewed by Claude Code (render check + viewing shots).
- Backlog HTML pages are NOT converted.

## State snapshot

- Branch `main`, ahead of origin (push is the user's call).
- No plan open; prototype under `work/html-kit/prototype/` is the source to move.
