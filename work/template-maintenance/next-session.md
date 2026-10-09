# Catchup prompt — template-maintenance (paste into a new agent session)

> **This file is the LAUNCHER.** Forward-only, REPLACED at each rollover.
> Provenance lives in `handoff.md`. Convention: docs/work-directory-conventions.md.

## >>> START HERE <<<

**Mission.** Resolve **L70** locally with a new third vendored-skill class,
**"patched"** (the user chose this; see `decisions.md`, 2026-10-09 "L70"). The sync
script re-copies upstream, then applies `skills/<name>/workspace.patch`, and
fails loudly if the patch no longer applies. `code-review` is its first user. The Matt
Pocock refresh (job 1) is DONE (ledger block 21).

**Read these, in order:**
- `scripts/sync-vendored-skills.sh` — the pristine and adapted loops; there is no test yet.
- `skills/vendored-skills.md` — the class list ("Two classes:" becomes three).
- `docs/template-workspace-backlog.html` — grep `L70` for the card.
- `skills/code-review/SKILL.md`, steps 3–5 (now at upstream `49dd158`).
- `work/template-maintenance/upstream-issue-code-review.md` — the intent only.
  Upstream rewrote code-review in 3da8c01, so write the patch against the
  current text.

**Do NOT reload:**
- The Matt refresh and the GLOSSARY.md move are done and committed (`08eeee3`).
- M48 and L71 are filed and wait for a later session; don't start them here.
- `implement-spec-vs-plans.md` is a finished comparison, settled.

**State:** `main` is clean and 3+ commits ahead of origin. Pushing is the user's
call. The backlog has 3 open cards (L70, M48, L71).

## First actions

1. `scripts/context-budget.sh register --project template-maintenance`.
2. **TDD the patched class.** Write `scripts/tests/test-sync-vendored-skills.sh`.
   It runs the sync against a throwaway fake upstream clone (git init in a temp dir)
   and a temp copy of the workspace. Run the sync script with `ROOT` overridable,
   or copy it into the temp dir. Write cases that fail first:
   (a) a patch that applies → its edit appears in `skills/<name>/SKILL.md`;
   (b) a patch that does not apply → the sync exits non-zero and names the skill;
   (c) the pristine and adapted classes behave as before.
   Then implement it: a `PATCHED=()` list, or detect `workspace.patch` after the re-copy.
   `rsync --delete` must keep `workspace.patch` (exclude it).
3. Write `skills/code-review/workspace.patch`: the step-5 split into blockers and
   suggestions, dropping findings a passing check enforces, and the same split
   in the Spec brief. Run the sync and confirm it applies cleanly. Update the provenance comment
   wording for patched skills.
4. Document the class in `skills/vendored-skills.md` and the script header. Then
   resolve L70 (move the card to the archive, add a `Fixed:` line, scorecard 2/121/5/0/6,
   a changelog row). Add a comment on mattpocock/skills#1242 only if the user asks.
5. `scripts/run-checks.sh`, then commit. Bump `TEMPLATE_VERSION` only if the user
   wants a push.
