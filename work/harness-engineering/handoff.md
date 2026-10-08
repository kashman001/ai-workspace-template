<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 4 (2026-10-08)

1. Ticket 04 (L61) done, commit `67c5455`: `docs/workspace-structure.md` →
   "Guides and Checks — One Map" (under `scripts/`), one table of every
   guide and check with what it guards and when it runs. Guide HTML
   regenerated. run-checks 38/0/0.
2. Gaps the table showed, filed as open cards: **L64** (`plan.sh check`
   not in the gate, committed plans unlinted) and **L65** (no check for
   `SKILL.md` frontmatter). Scorecard 4/110/5/0/6. One Tier-2 note.
3. All five tickets done; item finished. CI still unverified until the
   user pushes.

Learnings:
- Mapping controls against their triggers finds gaps a per-script audit
  misses: `plan.sh check` had a suite, but nothing ran it on commit.

# Session Handoff — 3 (2026-10-08)

1. Ticket 03 (L60) done, commit `21d03a6`: checkpoint → "Classify before
   you write" gains "Promote a repeat to a check"; gotchas may carry an
   `**Enforced by:**` line (defined in the `operational-knowledge.md`
   header), back-filled on three entries. decision-log unchanged (it
   already points to checkpoint).
2. Ticket 05 (L62) done, commit `ca43dec`: the fail-test rule lives in
   `docs/workspace-structure.md` → "Authoring a Team Capability". Audit
   table in the ticket. Three new suites: `test-check-repo-context.sh`,
   `test-check-service-access.sh`, `test-check-workspace-structure.sh`.
   Guide HTML regenerated. run-checks 38/0/0. Scorecard 3/109/5/0/6.
3. Two Tier-2 notes added to `decisions.md`.
4. Rolled over at WARN (121K) after ticket 05. Next: ticket 04 (L61), the
   last one.

Learnings:
- "Has a suite" is not "has a suite that makes it fail": the structure
  check's only suite asserted a warning, never exit 1.
