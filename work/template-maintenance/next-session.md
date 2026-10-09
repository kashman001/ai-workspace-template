# Catchup prompt — template-maintenance (paste into a new agent session)

> **This file is the LAUNCHER.** Forward-only, REPLACED at each rollover.
> Provenance lives in `handoff.md`. Convention: docs/work-directory-conventions.md.

## >>> START HERE <<<

**Mission.** Two jobs the user asked for:
1. **Refresh the Matt Pocock skills.** Update the vendored skills to the
   latest `mattpocock/skills`, and integrate every new skill upstream has
   released since `068b6e0`.
2. **Resolve L70 locally with a new "patched" class.** The user chose this
   (`decisions.md`, 2026-10-09); do not wait on upstream #1242. Do it after the
   refresh, so the patch is written against the new upstream text.

**Read these, in order:**
- `skills/vendored-skills.md` covers the classes, the list, and how to refresh.
- `scripts/sync-vendored-skills.sh` has its own header comment explaining the
  pristine and adapted classes.
- `docs/template-workspace-backlog.html`: grep `L70` for the card, which
  includes the corrected evidence.
- `work/template-maintenance/upstream-issue-code-review.md` is the exact
  change for code-review steps 4–5.
- `docs/workspace-structure.md` → "Authoring a Team Capability" lists the
  wiring every new skill needs.

**Do NOT reload:**
- The DeepSeek cards M46, M47 and L66–L69 are done (ledger block 20).
- The eval in `work/deep-seek-harness-eval/` is closed.

**State:** `main` is clean and pushed apart from the session-20 rollover
commit. CI run 37987347172 passed 40/0/0. The backlog has 1 open card (L70).

## First actions

1. `scripts/context-budget.sh register --project template-maintenance`.
2. **Refresh.** Run `git -C ~/Developer/references/mattpocock-skills pull`
   (the clone is at `068b6e0`). List the skills upstream has released that
   are new since that commit; renamed or removed ones count too. Then run
   `scripts/sync-vendored-skills.sh`, and review the diff for each existing
   vendored skill.
3. **Integrate each new skill** the same way earlier syncs did (backlog
   archive, 2026-08-05 sync row, as the pattern):
   - copy it into `skills/` and add it to the sync script's list
   - add `.claude/commands/<name>.md` if it is user-invoked
   - add a line to `skills/vendored-skills.md`
   - add a row to `docs/recommended-tooling.md` §3
   - add `agents/openai.yaml`; the E6 check requires
     `allow_implicit_invocation: false` when `disable-model-invocation: true`
   - add a line to `CONTEXT.md` only if it is worth the bytes (15.5K of 16K)
   - update the global symlinks if they exist
   If a new skill's purpose overlaps a workspace skill, ask the user before
   wiring it.
4. **L70: patched class.** TDD in the sync script's test: after the re-copy,
   apply `skills/<name>/workspace.patch`. If the patch fails to apply, the
   sync must fail. Write the code-review patch from the issue draft. Document
   the class in `skills/vendored-skills.md`, then resolve L70 in the backlog.
5. Run `scripts/run-checks.sh` and record a backlog changelog row. Bump
   `TEMPLATE_VERSION` before any push, which is the user's call.
