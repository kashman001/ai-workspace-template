# Catchup prompt — html-kit (paste into a new agent session)

We're resuming html-kit. Works in any runtime (Claude Code, Codex, Gemini,
OpenCode) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in
> `handoff.md` (the append-only ledger). Convention:
> docs/work-directory-conventions.md.

## >>> START HERE <<<

Build and measure the prototype kit.

1. Write `prototype/kit/kit.css` + `kit.js` (doc and deck layouts, light/dark,
   Mermaid loader, deck navigation).
2. Write `prototype/AUTHORING.md` — the per-page rule an agent loads.
3. Rebuild `work/sdlc-ai-mapping/slides/where-ai-actually-helps.html` on the kit
   as `prototype/where-ai-actually-helps.html`; measure size, screenshot both.
4. Give a fresh subagent only `AUTHORING.md` and some content; check its page.
5. Record results in `prototype/RESULTS.md` and a verdict for the user.

Steps 1–4 need no human. Step 5's verdict is the user's call: when you reach it,
roll over with `--loop-mode interactive` and put the verdict question, with the
options spelled out, verbatim at the top of the new launcher.

Measure in bytes and say so; there is no local Claude tokenizer, so any token
figure is an estimate (bytes / 4) and must be labelled that way. Screenshot with
headless Chrome (`--headless --screenshot`) and read the PNGs to compare.

## Constraints already decided (do not re-litigate)

- HTML stays the source of truth for human-facing pages (user preference); the
  Markdown-plus-renderer route is kept only for long prose docs.
- Agent-agnostic: plain CSS/JS files plus a doc, no runtime-specific skill.
- Throwaway: the prototype lives in `work/html-kit/prototype/`, not in `docs/`
  or `skills/`, until the user accepts a verdict.

## Read these first, in order

1. `work/html-kit/README.md`
2. `work/html-kit/handoff.md` (top block)
