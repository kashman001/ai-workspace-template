# Catchup prompt — deep-seek-harness-eval (paste into a new agent session)

We're resuming deep-seek-harness-eval. Works in any runtime (Claude Code,
Codex, Gemini, OpenCode) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in
> `handoff.md` (the append-only ledger). Convention:
> docs/work-directory-conventions.md.

## Mission

Find what this template can learn from DeepSeek Harness. Reading is done
(`source-notes.md`); this session writes `eval.md` and hands it to the user
for review.

## Position

Step 4 of 5 in the README's success criteria: `source-notes.md` done
(session 1); `eval.md` not started; user review pending after that.

## Read these, in order

1. `work/deep-seek-harness-eval/source-notes.md` (whole; it is the input)
2. `work/deep-seek-harness-eval/handoff.md` — top block ("Candidate themes")
3. `docs/workspace-structure.md` → "Guides and Checks — One Map" (line ~642)
4. Format model: the top ~40 lines of `work/context-memory-eval/eval.md`

## Do NOT reload

- The upstream repo: don't re-clone or re-read it for the eval; the notes
  carry paths. Re-open a single upstream file only to settle a specific
  doubt — the clone may be gone; if so, shallow-clone again outside the repo
  (`git clone --depth 1 --filter=blob:limit=1m https://github.com/deepseek-ai/deepseek-harness.git <scratch>/deepseek-harness`)
  and note if the SHA moved from `5badb15`.

## First actions

1. `scripts/context-budget.sh register --project deep-seek-harness-eval`
2. Read the files above.
3. Write `work/deep-seek-harness-eval/eval.md`: scorecard, one row per
   upstream practice — verdict **Already have / Partial / Worth adopting /
   Not for us**, evidence paths on both sides (upstream path; template path
   found with targeted greps). Check template evidence on disk, not from
   memory.
4. Put a one-page plain-language summary at the top (short, no workspace
   jargon, glossary for any term it must use), then ranked recommendations;
   each says doc change / script change / deliberate non-goal.
5. Update `README.md` Files list (source-notes and eval no longer planned),
   commit `work/deep-seek-harness-eval/` only.
6. Tell the user `eval.md` is ready for review, and end through
   `skills/checkpoint/SKILL.md` (the review needs a person).
7. At every work-unit boundary: `scripts/context-budget.sh record --label "<what finished>"`;
   WARN (exit 1) → finish the unit and roll over without asking; STOP
   (exit 2) → roll over at once.

**No human in the loop:** if nobody answers, leave `eval.md` committed and
the review question open in the checkpoint; don't card or reject anything.

## Constraints already decided (do not re-litigate)

- Never run upstream code; never copy upstream files into this repo
  (paraphrase, cite paths; short quotes fine — MIT).
- Don't file or build anything. Recommendations become backlog cards only
  after the user accepts them; rejections go in `decisions.md`.
- `ROLLOVER_RELAUNCH=auto` for this item.
- Pushing `main` is the user's call; commit locally only, and commit only
  this work item's files — other sessions may have uncommitted edits in the
  checkout.

## State snapshot

Branch `main`, local commits only. Unrelated uncommitted edits under
`scripts/` (session-loop, test-plan, test-session-loop) belong to another
session — leave them.
