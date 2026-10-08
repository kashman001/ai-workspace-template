# 03 — A path for recurring gotchas to become checks (L60)

**What to build:** the article's "steering loop" for this workspace. Doc
and skill edits, no new script:

- `skills/checkpoint/SKILL.md` → "Classify before you write": when the
  item repeats a gotcha already on file (an UPDATE of the same mistake
  happening again), ask whether a script or test could catch it. If yes,
  file a backlog card for the check (or write it now if small) and link it.
- `docs/operational-knowledge.md` header: an optional
  `**Enforced by:** <script or test>` line under an entry. An enforced
  entry stays as the *why*; the check is the guard.
- `skills/decision-log/SKILL.md` only if it repeats the classification
  rules (keep one home for the rule; point, don't copy).
- Back-fill `Enforced by:` for gotchas that already have a check (e.g.
  the ledger-splice entry ↔ `check-ledger.py`). Grep, don't guess.

Follow `skills/writing-for-agents/SKILL.md` for the skill edit.

**Blocked by:** nothing.

**Status:** todo

- [ ] Rule added to checkpoint; `Enforced by:` defined in the doc header
- [ ] Back-fill done; list which entries got the line in the ticket
- [ ] Backlog card resolved in the same commit: badge → Resolved, `Fixed:`
      line with the commit, card moved to the matching section of
      `docs/template-workspace-backlog-archive.html`, scorecard and "Last
      updated" changed, change-log row added
- [ ] All `scripts/tests/test-*` suites green (after ticket 01:
      `scripts/run-checks.sh` exits 0); `scripts/check-workspace-structure.sh` exit 0
- [ ] One commit, `Fix <ID>: …`, with a `Decision:` trailer
