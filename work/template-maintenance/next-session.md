> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in `handoff.md`
> (the append-only ledger). Convention: docs/work-directory-conventions.md.

## Mission

Execute the user-approved **skill-hardening plan**: 8 improvements to the
workspace skills learned from comparing them against `mattpocock/skills`
(clone `8b36d4f`), including vendoring `writing-for-agents`. The analysis is
done and fully persisted; this session only executes.

## Read these, in order

1. `work/template-maintenance/skill-hardening-plan.md` — the execution spec.
   **This is the authority**; every finding it depends on is restated in it.
2. Each target SKILL.md only when its item comes up (plan lists files
   per item). Vendor source: `~/Developer/references/mattpocock-skills`
   (already at `8b36d4f` — do not pull).
3. Optional style guide while editing: the newly linked global
   `writing-for-agents` skill (or upstream
   `skills/productivity/writing-for-agents/SKILL.md` in the clone).

## Do NOT reload

- The two skill-comparison subagent reports — superseded by the plan file;
  re-running those agents would waste ~120K subagent tokens for nothing.
- `work/template-maintenance/handoff-archive.md` — sync/recon/wayfinder
  history, all shipped.
- The upstream-sync work (`823f8c2`, `19aeb23`) — done and pushed; only the
  wayfinder provenance-comment *pattern* matters (mirrored in plan item 8).
- Items 5 and 8 are **decided** (inline handoff rules; vendor as skill) —
  don't re-litigate; item 5's Tier-2 note still needs writing at execution.

## State snapshot

- Branch `main`, synced with origin through `19aeb23`; uncommitted at
  rollover: this work dir's plan/ledger/launcher/decisions files (committed
  by the rollover commit if present) and `work/context-decay/
  context-ledger.jsonl` (budget telemetry churn — commit or leave per
  convention).
- No skill/doc files touched yet. User has standing push-to-main approval
  for this work.

## First actions

1. `scripts/context-budget.sh register`
2. Work `skill-hardening-plan.md` items 1→9 in order; verify per item;
   commit in 2–3 logical commits with `Decision:` trailers; push.
