# Catchup prompt — deep-seek-harness-eval (paste into a new agent session)

We're resuming deep-seek-harness-eval. Works in any runtime (Claude Code,
Codex, Gemini, OpenCode) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in
> `handoff.md` (the append-only ledger). Convention:
> docs/work-directory-conventions.md.

## >>> START HERE <<<

Study <https://github.com/deepseek-ai/deepseek-harness> and find what this
template can learn from it. Session 1 has not started.

1. `scripts/context-budget.sh register --project deep-seek-harness-eval`
2. Get a read-only copy **outside this repo**, in your scratchpad or another
   temp dir (never under this checkout). The repo is ~270 MB, so fetch it
   shallow and skip big blobs:
   `git clone --depth 1 --filter=blob:limit=1m https://github.com/deepseek-ai/deepseek-harness.git <scratch>/deepseek-harness`.
   Record `git -C <scratch>/deepseek-harness rev-parse HEAD` in
   `source-notes.md`. If a later session finds the clone gone, clone again
   and note if the SHA moved.
3. Read the agent-facing files first, with targeted reads: `AGENTS.md`,
   `CLAUDE.md`, `.agents/`, `.claude/`, `README.md`, `CONTRIBUTING.md`,
   `SAFETY.md`, `BENCHMARK.md`, `Makefile`, CI (`.github/`,
   `.gitlab-ci.yml`), lint/dup config (`.oxlintrc*.json`, `.jscpd.json`).
   Go into `apps/` only where those files point.
4. Write `source-notes.md`: each practice, paraphrased, with its upstream
   path. Then write `eval.md`, comparing with this template's guides and
   checks — start from `docs/workspace-structure.md` → "Guides and Checks —
   One Map". Model both on `work/context-memory-eval/` and
   `work/harness-engineering/source-notes.md`.
5. Finish `eval.md` with a one-page plain-language summary at the top
   (short, no workspace jargon, glossary for any term it must use), then
   ranked recommendations. Tell the user it is ready for review.
6. At every work-unit boundary run
   `scripts/context-budget.sh record --label "<what finished>"` and act on
   the exit code (see Constraints).

## Constraints already decided (do not re-litigate)

- **Never run upstream code** — no installs, builds, scripts, tests, or
  hooks from the clone. Read files only.
- **Never copy upstream files into this repo.** Paraphrase in
  `source-notes.md` and cite paths. MIT licensed; a short quote is fine.
- **Don't file or build anything.** Recommendations become backlog cards
  only after the user accepts them; record rejections in `decisions.md`.
- **Runs unattended** (`context-budget.env` has `ROLLOVER_RELAUNCH=auto`).
  Split the study across sessions by budget: at WARN (exit 1) finish the
  current unit and roll over without asking (`skills/session-rollover/SKILL.md`);
  at STOP (exit 2) roll over at once. Only the final user review needs a
  person — end that session through `skills/checkpoint/SKILL.md`.
- Pushing `main` is the user's call; commit locally only.

## Read these first, in order

1. `work/deep-seek-harness-eval/README.md`
2. `work/deep-seek-harness-eval/handoff.md` (top block)
3. `docs/workspace-structure.md` → "Guides and Checks — One Map"

## Facts already checked (don't redo)

Repo exists: MIT, default branch `master`, ~270 MB, pushed 2026-10-03,
tagline "DeepSeek Harness: Everything is a Plugin". Root has `AGENTS.md`,
`CLAUDE.md`, `.agents/`, `.claude/`, `apps/`, `Makefile`, `BENCHMARK.md`,
`SAFETY.md`, `.github/`, `.gitlab-ci.yml`, `.oxlintrc*.json`, `.jscpd.json`.
