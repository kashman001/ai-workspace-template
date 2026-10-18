# Catchup prompt — External Tools Review (paste into a new agent session)

We're resuming external-tools-review. Works in any runtime (Claude Code, Codex,
Gemini, OpenCode) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in
> `handoff.md` (the append-only ledger). Convention:
> docs/work-directory-conventions.md.

## >>> START HERE <<<

1. Run tracks T1–T4 (README table) in parallel; each writes
   `research/tN-<slug>.md` to the shape in README success criterion 1.
2. Spot-check the key claims of each track note on disk / at the source.
3. Write `synthesis.md` — recommendations by theme, ranked.
4. Write the plain-language summary + HTML twin, then roll over with
   `--loop-mode interactive` — dispositioning the recommendations is the
   user's call (README success criterion 4), not the chain's.

## Constraints already decided (do not re-litigate)

- One work item for all four tracks, not four (user-agreed, s1) — synthesis
  is the deliverable; integration work spins out to its own item.
- T3 subject is redesigned Projects (the article), not Agent Teams / Agent
  View — those may be cited only as context.
- Run tracks as parallel subagents (one per track; shared files stay in the
  main session). `research-wave` is user-invoked only — don't self-start it.
- Primary sources first (the GitHub repo itself, the article, the video
  transcript); mark anything single-sourced as unverified.
- Integrations must be agent-agnostic (Codex/Gemini/Copilot + downloaders).

## Read these first, in order

1. `work/external-tools-review/README.md`
2. `work/external-tools-review/handoff.md` (top block)
