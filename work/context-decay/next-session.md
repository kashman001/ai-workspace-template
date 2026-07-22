# Next Session — context-decay

## Mission

The context-budget system is **implemented, verified, and shipped** (see
`handoff.md`). What remains is the spec's follow-up list plus living with the
system: verify the unverified adapters, and start using the ledger as research data.

## Read these, in order

1. This file.
2. `handoff.md` — what shipped and its verification status.
3. `docs/context-budget.md` — only if you need command/adapter details.

## Do NOT reload

- `context-decay-spec.md` — fully implemented; re-reading it will tempt re-implementation. Only §12 (follow-ups) still matters, and it's restated below.
- `design.html` — reference for humans; content duplicated in docs/context-budget.md.
- The workspace-structure/template-usage/backlog diffs — settled, committed, pushed.
- The `<username>_` work-dir rename (D3) — done and pushed; not part of this project.

## State snapshot

- Branch `main`, clean, pushed through the rollover-docs commit (after `3c7b44a`).
- Hook is live in this machine's `.claude/settings.json` and firing.
- Ledger: `work/context-decay/context-ledger.jsonl` (5 entries from the build session).
- No running processes; nothing uncommitted.

## First actions

1. `scripts/context-budget.sh register`
2. Pick up the follow-ups (spec §12, restated — the only open work):
   - Verify/fix the **Copilot CLI** adapter against a real `~/.copilot` session; check whether its hooks dir supports an in-band warning.
   - Enable **Gemini CLI local telemetry** for exact counts (currently bytes÷4 estimate).
   - Periodically analyze the ledger (token growth per phase, estimate accuracy).
3. Or, if the user brings new work: the system is done — just follow the
   Context Budget section in `CONTEXT.md` like any other session.
