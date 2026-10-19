# Catchup prompt — Backlog sweep (L101)

> **This file is the LAUNCHER.** Forward-only, REPLACED at each rollover.
> Provenance lives in `handoff.md`. Convention: docs/work-directory-conventions.md.

## Mission

Fix template card **L101**: manual `register` fails in the Antigravity IDE agent shell. The
IDE shell has no `ANTIGRAVITY_APP_DATA_DIR`, so `antigravity_discover`
(`scripts/context-budget.sh:352`) looks only under the CLI data root and misses
`~/.gemini/antigravity-ide/`. Fix per the card: when the var is unset, try each data root
(`antigravity-cli/`, `antigravity-ide/`, `antigravity/`) for `brain/<id>/`; the id is unique,
so the first hit is not a guess. Plan `01-open-cards` is closed; this is a single card, no plan.

## Read these, in order

1. The L101 card: `grep -n 'L101' docs/template-workspace-backlog.html` (read that card only)
2. `work/runtime-session-identity/probes/antigravity-ide.md` → Q3 and Gaps
3. `scripts/context-budget.sh` around `antigravity_discover` (:352) and its call site (:431)
4. The suite that covers antigravity discovery: `grep -ln antigravity scripts/tests/*.sh`

## Constraints already decided (do not re-litigate)

- Test first (`tdd`): a fixture case with the id under `antigravity-ide/brain/<id>/` and the
  var unset, seen failing, then the fix.
- Other sessions share this checkout: stage only your own paths; re-read the backlog files
  right before writing them. Pushing is the user's call; ask, don't push.

## Do NOT reload

- L99/L100 pilot (`pilot/`): settled — L99 pruned, L100 kept (`decisions.md`).
- The hook allowlist (`cc1173e`): shipped; don't redesign it.

## State snapshot

main == origin/main at `6832cce` plus this rollover commit; tree clean otherwise.

## First actions

1. `scripts/context-budget.sh register --project backlog-sweep`
2. Write the failing fixture test, then fix `antigravity_discover`; run the suite, then
   `scripts/run-checks.sh`.
3. Archive L101 with a `Fixed:` line (scorecard + change-log row), commit as `Fix L101: …`.
4. End with `checkpoint` (item closed again; ask the user before pushing).
