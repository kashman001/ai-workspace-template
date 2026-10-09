# Catchup prompt — deep-seek-harness-eval (paste into a new agent session)

We're resuming deep-seek-harness-eval. Works in any runtime (Claude Code,
Codex, Gemini, OpenCode) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in
> `handoff.md` (the append-only ledger). Convention:
> docs/work-directory-conventions.md.

## Mission

Find what this template can learn from DeepSeek Harness. The user has
**accepted all seven recommendations R1–R7** in `eval.md` (session 2,
verbatim: "I accept all of them"). This session files them as backlog cards
and closes the item.

## Position

Step 5 of 5 in the README's success criteria: verdicts are in, cards not
filed. No rejections, so `decisions.md` stays absent.

## Read these, in order

1. `work/deep-seek-harness-eval/eval.md` → "Ranked recommendations" (R1–R7;
   the scorecard only for the rows each R cites)
2. `docs/template-workspace-backlog.html` → `id="maintaining"` section
   (~line 102; grep it, never load the file whole), and one existing open
   card as a format model

## Do NOT reload

- `source-notes.md` or the upstream repo; `eval.md` carries the paths.

## First actions

1. `scripts/context-budget.sh register --project deep-seek-harness-eval`
2. File seven backlog cards, one per R1–R7, following the backlog's
   maintenance rules (next free ID, status, scorecard). Each card cites
   `work/deep-seek-harness-eval/eval.md` with its R-number and row(s), and
   its change type (doc / script / config). Keep R1's evidence: the six
   manual-only skills with no `agents/openai.yaml`.
3. Tick the README's review criterion. Close the item's row in
   `work/README.md`. Commit only this work item, the backlog and
   `work/README.md`.
4. Don't build any card here. Report the card IDs to the user, then end
   through `skills/checkpoint/SKILL.md`.
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
