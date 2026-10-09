# Catchup prompt — deep-seek-harness-eval (paste into a new agent session)

We're resuming deep-seek-harness-eval. Works in any runtime (Claude Code,
Codex, Gemini, OpenCode) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in
> `handoff.md` (the append-only ledger). Convention:
> docs/work-directory-conventions.md.

## Mission

Find what this template can learn from DeepSeek Harness. `eval.md` is
written; this session acts on the user's verdicts on its recommendations.

## Position

Step 5 of 5 in the README's success criteria. Blocked on the user: they
review `eval.md` → "Ranked recommendations" (R1–R7) and the non-goals list.

## Read these, in order

1. `work/deep-seek-harness-eval/eval.md` — summary + "Ranked recommendations"
   (the scorecard only for rows a verdict touches)
2. `work/deep-seek-harness-eval/handoff.md` — top block
3. `docs/template-workspace-backlog.html` → "Maintaining this backlog"
   (grep the heading; never load the file whole)

## Do NOT reload

- `source-notes.md` or the upstream repo; `eval.md` carries the paths.

## First actions

1. `scripts/context-budget.sh register --project deep-seek-harness-eval`
2. Ask the user which of R1–R7 they accept (one question at a time, plain
   terms). If no one answers, end through `skills/checkpoint/SKILL.md` and
   leave the question open; don't card or reject anything.
3. Each accepted one → one backlog card per the backlog's maintenance rules
   (cite `eval.md` row and R-number). Each rejected one, and any non-goal the
   user disputes → `decisions.md` via `skills/decision-log/SKILL.md`.
4. Mark the README success criterion done, commit this work item plus the
   backlog only, and close the item in `work/README.md`.
5. At every work-unit boundary: `scripts/context-budget.sh record --label "<what finished>"`.

## Constraints already decided (do not re-litigate)

- Don't build anything here: accepted items become cards, built later.
- Never copy upstream files into this repo (paraphrase, cite paths).
- Pushing `main` is the user's call; commit locally only, and only this
  item's files (+ backlog). Other sessions may have uncommitted edits.
- `ROLLOVER_RELAUNCH=auto` for this item, but step 2 needs a person.

## State snapshot

Branch `main`, local commits only. Unrelated uncommitted edits under
`scripts/` belong to another session — leave them.
