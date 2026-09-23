# Catchup prompt — plans (paste into a new agent session)

We're resuming `plans`. Works in any runtime (Claude Code, Codex, Gemini,
OpenCode) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in
> `handoff.md` (the append-only ledger). Convention:
> docs/work-directory-conventions.md.

## >>> START HERE <<<

Position: item scaffolded, nothing explored yet. Objective for this session:
turn the loose idea of a **plan** (graph of steps + loops + sessions,
parallelism-aware and LLM-tier-aware) into a sharp concept the user has
agreed to, grounded in what the workspace already does. Exploration only —
no runner, no format spec until the concept is settled.

1. `scripts/context-budget.sh register --project plans` (first registered
   session of this item; expect `seq=1`).
2. Read `README.md` here ("What this is" + success criteria).
3. Build the seam inventory **before** interviewing the user (facts are the
   agent's job): for each of `skills/to-tickets/SKILL.md` (blocking edges),
   `skills/wayfinder/SKILL.md` (map + frontier), the Workflow tool and
   `skills/workflow-authoring` reference (agent graphs, `pipeline`,
   `parallel`), `skills/research-wave/SKILL.md`, the `loop` skill,
   `scripts/session-loop.sh` + `scripts/launch-next-session.sh` (session
   chaining), `scripts/fleet.sh` (dispatch records), `skills/rlm/SKILL.md`
   (root/leaf tiers), and `docs/work-directory-conventions.md`
   (launcher/ledger), note: what plan property it covers, what it lacks.
   Write `seams.md`. Delegate the reading to a subagent if it is heavy;
   verify on disk before recording.
4. Run `grill-with-docs` on the concept with `seams.md` in hand. Frontier
   questions to open with (recommended answers in the round): what a plan
   *is* (a file? a map of tickets? a Workflow script?); one plan per work
   item or many; how a step declares its tier and its parallel group; what a
   loop's exit check looks like; how a plan resumes from a rollover; whether
   a plan wraps existing skills or replaces them; what is out of scope.
   Every settled answer lands as a `/decision` note in `decisions.md`.
5. Write `concept.md`: the one-page definition, glossary, and one worked
   example written in the proposed form. If the open questions clearly
   exceed this session, chart them as a `wayfinder` map instead of
   guessing.
6. `scripts/context-budget.sh record --label "<unit done>"` at each step
   boundary. At the end or at WARN/STOP: ledger block on `handoff.md`
   (`# Session Handoff — 1 (<date>): …`), rewrite this launcher, update the
   `work/README.md` row, commit. Do not push main; report how far ahead it is.

## Constraints already decided (do not re-litigate)

- Exploration before build: no runner, no format implementation until
  `decisions.md` records a build verdict.
- Whatever ships is agent-agnostic (Codex, Gemini, OpenCode, downloaders) and
  plain files on disk — a plan must be readable without any one runtime.
- Reuse over reinvention: the seam inventory decides what a plan wraps versus
  replaces; do not design a plan format that ignores `to-tickets` edges,
  `wayfinder` maps, or the launcher/ledger.

## Read these first, in order

1. `work/plans/README.md`
2. `work/plans/handoff.md` (top block)
3. `skills/grill-with-docs/SKILL.md` (when step 4 reaches it)
