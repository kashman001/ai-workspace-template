# Catchup prompt — html-kit (paste into a new agent session)

We're resuming html-kit. Works in any runtime (Claude Code, Codex, Gemini,
OpenCode) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover. Past-tense provenance lives in `handoff.md`.
> Convention: docs/work-directory-conventions.md.

<!-- plan:begin position -->
Position: plan 03-adoption-readiness, open, wave 2 of 2, done 6/8, doing 0, todo 2, blocked 0, dropped 0, sessions 1.
Frontier: 07-cross-runtime-test. Remaining: 2 of 8 — wave 2: 07-cross-runtime-test todo, 08-reconcile-2 todo.
<!-- plan:end position -->

## Mission

Finish plan `plans/03-adoption-readiness` (wave 2: nodes 07, 08), then put the
verdict to the user. The user said: **before adopting, run the plan, then make
the decision.** Wave 1 is done; what remains is the most important proof — that
Codex and Gemini can build a good kit page from the rules alone.

## First actions

1. `scripts/context-budget.sh register --project html-kit`
2. Node 07 (`scripts/plan.sh show 07-cross-runtime-test --project html-kit`):
   write one brief at `prototype/xrt/brief.md` — rebuild `docs/setup-guide.html`
   (repo root) into `prototype/xrt/<runtime>/setup-guide.html`, reading only
   `prototype/AUTHORING.md` (+ `DIAGRAMS.md` when it has figures), kit path
   `../../kit/`, then run the rule greps, `check-links.sh` and `render-check.sh`
   (shots to `prototype/xrt/<runtime>/shots/`) and fix until they pass. Run
   `codex exec` and `gemini` (both on PATH) with it, in the background, output
   to `prototype/xrt/<runtime>/transcript.txt`; read only the tails.
3. Node 08: view every cross-runtime shot yourself (contact sheet ok — see how
   `prototype/shots/s7/sheet-a.png` was made: HTML grid + headless Chrome
   `--screenshot`); write RESULTS "Cross-runtime" (per figure per runtime
   pass/fail, rule violations, o200k tokens of each output, what each got wrong
   unaided and whether it self-corrected).
4. Ask the user, one question, plain terms: **adopt** the kit (into
   `docs/kit/` as plain files, my recommendation) or **drop** it? Give the
   measured numbers and the cross-runtime result in two or three lines.

**No human present:** do steps 1–3, commit, stop with step 4's question open.

## Read these first, in order

1. `work/html-kit/handoff.md` — top block (session 7)
2. `work/html-kit/prototype/RESULTS.md` — "Session 7" only
3. `work/html-kit/decisions.md` — skim

## Do NOT reload

- Wave 1 work (rules split, wide-SVG scroll, check-links, Linux render check,
  sample page): done and viewed; see RESULTS Session 7.
- Bytes/4 estimates: superseded. Measure with
  `uvx --quiet --with tiktoken python -I -` (o200k_base).
- Claude token counts: need an API key; none on this machine.
- Mac 500px crop on setup-guide figs 1, 4: known, unexplained; only chase it if
  a cross-runtime shot is unreadable because of it.

## Constraints already decided (do not re-litigate)

- HTML stays the source of truth for human-facing pages.
- Agent-agnostic: plain CSS/JS files plus a doc, no runtime-specific skill.
- Diagrams accepted only after the render check, viewed by eye.
- Throwaway until a verdict: everything stays in `work/html-kit/prototype/`.
- Plan-node checks run from `work/html-kit/`.

## State snapshot

- Branch `main`, ahead of origin (push is the user's call). Stage only
  `work/html-kit/` paths; other sessions share this checkout.
- Plan 03: wave 1 done (6/8), frontier `07-cross-runtime-test`.
