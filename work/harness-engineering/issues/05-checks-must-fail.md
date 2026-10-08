# 05 — Every new check ships with a test that makes it fail (L62)

**What to build:** the rule against "silent sensors" — a check that has
never failed may be broken. Edits:

- `docs/workspace-structure.md` → "Authoring a Team Capability": a new
  check (script, hook, lint) ships with a suite under `scripts/tests/`
  that feeds it bad input and asserts it fails, with the reason line.
- Ticket 01's `run-checks.sh` docs say the same.
- Audit: for each `scripts/check-*` and `plan.sh check`, name the suite
  that makes it fail. Any without one → write the missing failing case
  (small) or file a card (large).

**Blocked by:** 01.

**Status:** todo

- [ ] Rule written in both places
- [ ] Audit table in the ticket: check → suite that makes it fail
- [ ] Missing cases written or carded
- [ ] Backlog card resolved in the same commit: badge → Resolved, `Fixed:`
      line with the commit, card moved to the matching section of
      `docs/template-workspace-backlog-archive.html`, scorecard and "Last
      updated" changed, change-log row added
- [ ] All `scripts/tests/test-*` suites green (after ticket 01:
      `scripts/run-checks.sh` exits 0); `scripts/check-workspace-structure.sh` exit 0
- [ ] One commit, `Fix <ID>: …`, with a `Decision:` trailer
