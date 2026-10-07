# Catchup prompt — context-memory-eval (paste into a new agent session)

We're resuming context-memory-eval. Works in any runtime (Claude Code, Codex,
Gemini, OpenCode) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in
> `handoff.md` (the append-only ledger). Convention:
> docs/work-directory-conventions.md.

## >>> START HERE <<<

Position: **item complete.** The user accepted recommendations 1–4 and 6.
They're carded as L49, L50, M43, L51, D5 and are being built in
`work/context-memory-hardening/`. Recommendation 5 is deferred
(`decisions.md`). Nothing to do here unless the evaluation is reopened. This
item stays as the research reference that `context-memory-hardening` points to.

## Constraints already decided (do not re-litigate)

- The article's numbers are unsourced claims, not benchmarks (`source-notes.md` caveat).
- Any recommendation has to stay plain-files and agent-agnostic. A
  Claude-only mechanism doesn't qualify.

## Read these first, in order

1. `work/context-memory-eval/README.md`
2. `work/context-memory-eval/eval.md` (summary + recommendations)
3. `work/context-memory-eval/handoff.md` (top block)
