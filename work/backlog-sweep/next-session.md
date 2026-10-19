# Catchup prompt — Backlog sweep (paste into a new agent session)

> **This file is the LAUNCHER.** Forward-only, REPLACED at each rollover.
> Provenance lives in `handoff.md`. Convention: docs/work-directory-conventions.md.

## Mission

Close plan `01-open-cards` (node 13), then carry out the user's L99/L100 decisions.

## Position

<!-- plan:begin position -->
Position: plan 01-open-cards, closed, wave 5 of 5, done 13/13, doing 0, todo 0, blocked 0, dropped 0, sessions 4.
Frontier: none. Remaining: 0 of 13.
<!-- plan:end position -->

## Read these, in order

1. `work/backlog-sweep/handoff.md` — top block only
2. `work/backlog-sweep/decisions.md` — last two entries (hook allowlist; L99/L100)
3. `nodes/13-reconcile-w5.md`; `skills/plans/SKILL.md` → "Run a reconcile node"

## Constraints already decided (do not re-litigate)

- The Claude-hook allowlist is shipped (`cc1173e`); don't redesign it.
- L99: prune `code-simplification`. L100: re-test `unslop` first (user's call, s5).
- Only node 13 writes `docs/template-workspace-backlog*.html`; re-read both right before writing.
- Other sessions share this checkout: stage only your own paths (the staged `docs/kit/`
  renames are html-kit's); never push.

## Do NOT reload

- Probe logs and clone (written up in `work/runtime-session-identity/probes/`); node 08 review.

## First actions

1. `scripts/context-budget.sh register --project backlog-sweep`
2. Node 13 (`plan.sh start 13-reconcile-w5 --session 6 --project=backlog-sweep`): archive L86
   with a `Fixed:` line (probe notes + `cc1173e` allowlist fix); file a new card for the
   Antigravity IDE shell `register` gap (`probes/antigravity-ide.md` → Gaps). Add one line
   on the allowlist to `docs/context-budget.md` (hooks section) and an "amended by" pointer
   on the Copilot decision in `work/runtime-session-identity/decisions.md`. `plan.sh verify`,
   close the plan, mark the item closed in `work/README.md`; `scripts/run-checks.sh`; commit.
3. L99: remove `skills/code-simplification/` and its entries in `skills/vendored-skills.md`
   (and any sync/vendor manifest that lists it); archive L99 with `Fixed:`; run-checks; commit.
4. L100: rerun `work/backlog-sweep/pilot/run.sh` for `unslop` only on 2–3 harder, longer
   prose tasks, 2–3 samples each (last run ~$0.88 for 36 runs). Prune if it ties again;
   otherwise keep and archive L100 with the result.
5. End with `checkpoint` (item closed).
