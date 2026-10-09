# Catchup prompt — context-memory-hardening (paste into a new agent session)

> **This file is the LAUNCHER.** Forward-only, REPLACED at each rollover.
> Provenance lives in `handoff.md`. Convention: docs/work-directory-conventions.md.

## Mission

This item is finished. This session has one job the user asked for: create a
**new work item `deep-seek-harness-eval`** to evaluate
<https://github.com/deepseek-ai/deepseek-harness> and find what this
workspace template can learn from and integrate. Then print the
session-loop command and end this chain.

## First actions

1. `scripts/context-budget.sh register --project context-memory-hardening`
2. Scaffold per `skills/create-work-item/SKILL.md`. Model it on
   `work/context-memory-eval/` and `work/harness-engineering/source-notes.md`:
   `README.md` (success criteria), `next-session.md`, `handoff.md`, and
   planned outputs `source-notes.md`, `eval.md` (ranked recommendations,
   evidence by path), `decisions.md`.
3. The launcher you write for it must say:
   - Read the repo through a shallow clone **outside this repo** (scratch
     dir) or a gitignored path; **never run its code**. It is ~270 MB:
     `git clone --depth 1 --filter=blob:limit=1m` and targeted reads.
   - Start from its `AGENTS.md`, `CLAUDE.md`, `.agents/`, `.claude/`,
     `README.md`, `CONTRIBUTING.md`, CI (`.github/`, `.gitlab-ci.yml`) —
     compare to what this template has (`docs/workspace-structure.md` →
     "Guides and Checks — One Map").
   - End with a plain-language report for the user (one page first,
     `review-docs-plain-language` style). Recommendations become backlog
     cards **only after the user accepts them** — don't file or build.
   - Runs unattended; split into sessions by budget, roll over at WARN.
4. `context-budget.env` with `ROLLOVER_RELAUNCH=auto`; add a row to
   `work/README.md`; `python3 scripts/check-ledger.py work/deep-seek-harness-eval`
   exits 0; commit.
5. Tell the user: `scripts/session-loop.sh deep-seek-harness-eval --max-sessions 4`.
   Then end through the stop door (`skills/checkpoint/SKILL.md`,
   `scripts/context-budget.sh close`) with nothing staged.

## Facts already checked (don't redo)

Repo exists: MIT, default branch `master`, ~270 MB, pushed 2026-10-03,
tagline "DeepSeek Harness: Everything is a Plugin". Root has `AGENTS.md`,
`CLAUDE.md`, `.agents/`, `.claude/`, `apps/`, `Makefile`, `BENCHMARK.md`,
`SAFETY.md`, `.github/`, `.gitlab-ci.yml`, `.oxlintrc*.json`, `.jscpd.json`.

## State snapshot

`main` at `40f4389` + this rollover commit; not pushed (pushing is the
user's call). Backlog: all cards resolved.
