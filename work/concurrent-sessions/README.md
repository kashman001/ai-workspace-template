# Concurrent Sessions — research whether several sessions can be active in one work item at once

Governing skill(s): `research` (research doc), `to-spec` (spec, only if the research says go).

**Start here:** `next-session.md` (catch-up launcher) → `handoff.md`
(session ledger, top block).

## What this is

Today a work item has exactly one owner session (`docs/context-budget.md` →
"Who owns a work item"); parallel work inside an item runs as subagents under
that owner. This effort researches whether two or more sessions could each own
part of one work item at the same time, what that would take (record schema,
ledger and launcher shape, plan-node claims, supervision), and whether it beats
the subagent answer we already have. It came out of `work/clear-session-loop/`
(`research.md` §6, §7 D), which found the question independent of `/clear`.

## Success criteria

1. `research.md` exists and covers: what people actually want from concurrent
   sessions that subagents under one owner do not give them; each part that
   assumes one owner (record, `seq`, ledger, launcher, `plan.sh start`,
   `session-loop.sh`, rollover) and what it would need; a per-runtime note
   where identity matters; and a go / no-go recommendation. Claims not
   verified are marked as such.
2. Key repo claims spot-checked by the orchestrating session and recorded in
   `research.md`.
3. If go: `spec.md` per `docs/agents/issue-tracker.md` → "Spec conventions".
   If no-go: no spec; the reason is in `research.md` and the ledger.
4. Each document has a self-contained HTML twin for the user to read.
5. The user has reviewed the research (and the spec, if any).

## Files

- `next-session.md` — forward launcher (what to do next). REPLACED each rollover.
- `handoff.md` — session ledger (what happened). APPEND newest-on-top; archive
  to `handoff-archive.md` when it exceeds the two most recent sessions.
- `research.md`, `research.html` — research findings and reading copy (to be written).
- `input-external-tools-review.md` — outside input: the "workers own nothing" design (Projects), external-tools-review R1.
- `spec.md`, `spec.html` — only if the research recommends go.
