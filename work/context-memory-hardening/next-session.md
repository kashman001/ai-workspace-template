# Catchup prompt — context-memory-hardening (paste into a new agent session)

We're resuming `context-memory-hardening`. Works in any runtime (Claude Code,
Codex, Gemini, OpenCode) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in
> `handoff.md` (the append-only ledger). Convention:
> docs/work-directory-conventions.md.

## >>> START HERE <<<

Position: **no ticket started.** Five tickets under `issues/`, worked in
number order: 01 (L49) → 02 (L50) → 03 (M43) → 04 (L51, blocked by 01) →
05 (D5, blocked by 03). Expect this to run unattended under
`scripts/session-loop.sh context-memory-hardening`. Proceed without asking;
only stop for something only a person can decide.

1. Take the lowest-numbered ticket whose `**Status:**` is `todo` and whose
   blockers are `done`. Set it to `in-progress` and save.
2. Work it per the ticket, test-first where the ticket says so. Land it as
   one commit with its backlog card resolved in the same commit. The ticket
   has the checklist. Set `**Status:** done`, tick the boxes, and add a
   short `**Done (date, session N).**` note.
3. Run `scripts/context-budget.sh record --label "ticket NN done"` and act
   on the exit code. On 0, take the next ticket. On 1 or 2, roll over
   (`skills/session-rollover/SKILL.md`) with this launcher rewritten to the
   new position.
4. When all five are `done`: write the ledger block, mark the item finished
   here and in `work/README.md`, and set the `context-memory-eval` row to
   closed. Then end through the stop door (`skills/checkpoint/SKILL.md`,
   `scripts/context-budget.sh close`).

Every session: one ledger block on top of `handoff.md` in plain numbered
form. Keep two blocks and archive the third. Then run
`python3 scripts/check-ledger.py work/context-memory-hardening`, which must
exit 0.

## Constraints already decided (do not re-litigate)

- Scope is cards L49, L50, M43, L51, D5 only. Recommendation 5 (async
  consolidation loop) is deferred: `work/context-memory-eval/decisions.md`.
- Everything stays plain-files and agent-agnostic. No Claude-only mechanism,
  no database or embedding service.
- Never auto-delete knowledge entries. Retire and link forward instead.
- `CONTEXT.md` is edited directly, never through a symlink path. Use
  targeted reads on the backlog HTML files and long docs.
- Don't push main. At the end, report how far ahead of origin it is.

## Read these first, in order

1. `work/context-memory-hardening/README.md`
2. `work/context-memory-hardening/handoff.md` (top block)
3. The current ticket under `work/context-memory-hardening/issues/`
4. On demand only: `work/context-memory-eval/eval.md` (research; the ticket
   names the section)
