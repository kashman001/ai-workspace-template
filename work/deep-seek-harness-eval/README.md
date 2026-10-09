# deep-seek-harness-eval — What this template can learn from DeepSeek Harness

Governing skill(s): none.

**Start here:** `next-session.md` (catch-up launcher) → `handoff.md`
(session ledger, top block).

## What this is

A read-only study of <https://github.com/deepseek-ai/deepseek-harness>
("DeepSeek Harness: Everything is a Plugin", MIT). It looks at the repo's
agent guidance (`AGENTS.md`, `CLAUDE.md`, `.agents/`, `.claude/`), its
contributor docs, and its CI and lint checks. It then compares them with this
template's guides and checks. The deliverable is an assessment with ranked
recommendations. Any template change it suggests goes through the backlog
only after the user accepts it.

## Success criteria

- `source-notes.md` sums up the repo's agent-facing practices, each with a
  path in the upstream repo and the commit SHA that was read.
- `eval.md` compares each practice with this template (Already have /
  Partial / Worth adopting / Not for us), with evidence paths on both sides.
- `eval.md` opens with a one-page plain-language summary and ranked
  recommendations. Each one says whether it is a doc change, a script
  change, or a deliberate non-goal.
- The user has reviewed the recommendations. Each accepted one is carded in
  `docs/template-workspace-backlog.html`, and each rejected one is noted in
  `decisions.md`.
- No upstream code was run, and no upstream files were committed here.

## Files

- `next-session.md` — forward launcher (what to do next). REPLACED each rollover.
- `handoff.md` — session ledger (what happened). APPEND newest-on-top; archive
  to `handoff-archive.md` when it exceeds the two most recent sessions.
- `context-budget.env` — `ROLLOVER_RELAUNCH=auto` for this item, so the
  study chains unattended.
- `source-notes.md` — the upstream repo's practices, paraphrased,
  with paths and the SHA read.
- `eval.md` — side-by-side scorecard, one-page summary, ranked
  recommendations (awaiting user review).
- `decisions.md` — *(planned)* which recommendations were accepted or
  rejected, and why.
