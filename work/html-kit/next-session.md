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

Run plan `plans/03-adoption-readiness` to completion, then put the verdict to
the user. The user said: **before adopting, run the plan, then make the
decision.** The plan fixes the concerns raised at the end of session 6: rules
doc too costly up front, moved pages break silently, render check Mac-only,
no regression page, wide SVG unreadable on phones, and, most important,
no proof the kit works for Codex and Gemini.

## First actions

1. `scripts/context-budget.sh register --project html-kit`
2. `scripts/plan.sh frontier --project=html-kit`, then work the nodes; each
   node file has its Goal and Acceptance. Wave 1 nodes `01`→`02`→`05` touch the
   kit and rules doc (one owner); `03` and `04` are separate files and can run
   in parallel subagents. The main session views every shot itself.
3. Node `07`: run `codex exec` and `gemini` (both on PATH) with the same
   brief; save the brief and each output under `prototype/xrt/`.
4. After `08-reconcile-2`, ask the user, one question, plain terms:
   **adopt** the kit (into `docs/kit/` as plain files, my recommendation) or
   **drop** it? Give the measured numbers (tiktoken o200k) and the cross-runtime
   result in two or three lines.

**No human present:** do steps 1–3 and node 08, commit, stop with step 4's
question open.

## Read these first, in order

1. `work/html-kit/decisions.md`
2. `work/html-kit/prototype/RESULTS.md` — "Session 6" only
3. `work/html-kit/prototype/AUTHORING.md` (node 01 rewrites it)

## Do NOT reload

- Bytes/4 estimates: superseded. Measure with
  `uvx --quiet --with tiktoken python -I -` (o200k_base); HTML is ~3.4 bytes/token.
- Claude token counts: need an API key; none on this machine. Don't hunt for one.
- Desktop SVG sizing: done in session 6 (`--vbw`, labels at body size); don't redo it.

## Constraints already decided (do not re-litigate)

- HTML stays the source of truth for human-facing pages; Markdown-plus-renderer
  only for long prose docs.
- Agent-agnostic: plain CSS/JS files plus a doc, no runtime-specific skill.
- Diagrams accepted only after the render check, viewed by eye.
- Throwaway until a verdict: everything stays in `work/html-kit/prototype/`.
- Plan-node checks run from `work/html-kit/`; write paths relative to it.

## State snapshot

- Branch `main`, ahead of origin (push is the user's call). Stage only
  `work/html-kit/` paths when committing; other sessions share this checkout.
- Plan 03 open, nothing started. Plan 02 closed.
